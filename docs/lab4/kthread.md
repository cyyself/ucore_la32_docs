## 内核线程管理 

### 创建并执行内核线程 

建立进程控制块（proc.c中的alloc\_proc函数）后，现在就可以通过进程控制块来创建具体的进程/线程了。首先，考虑最简单的内核线程，它通常只是内核中的一小段代码或者函数，没有自己的“专属”空间。这是由于在uCore OS启动后，已经对整个内核内存空间进行了管理，通过设置页表建立了内核虚拟空间（即boot\_cr3指向的二级页表描述的空间）。所以uCore OS内核中的所有线程都不需要再建立各自的页表，只需共享这个内核虚拟空间就可以访问整个物理内存了。从这个角度看，内核线程被uCore OS内核这个大“内核进程”所管理。

### 关键数据结构 -- 进程控制块 

在实验四中，进程管理信息用struct
proc\_struct表示，在*kern/process/proc.h*中定义如下：

```
struct proc_struct {
	enum proc_state state;                      // Process state
    int pid;                                    // Process ID
    int runs;                                   // the running times of Proces
    uintptr_t kstack;                           // Process kernel stack
    volatile bool need_resched;                 // bool value: need to be rescheduled to release CPU?
    struct proc_struct *parent;                 // the parent process
    struct mm_struct *mm;                       // Process's memory management field
    struct context context;                     // Switch here to run process
    struct trapframe *tf;                       // Trap frame for current interrupt
    uintptr_t cr3;                              // the base addr of Page Directroy Table(PDT)
    uint32_t flags;                             // Process flag
    char name[PROC_NAME_LEN + 1];               // Process name
    list_entry_t list_link;                     // Process link list 
    list_entry_t hash_link;                     // Process hash list
    int exit_code;                              // exit code (be sent to parent proc)
    uint32_t wait_state;                        // waiting state
    struct proc_struct *cptr, *yptr, *optr;     // relations between processes
    struct run_queue *rq;                       // running queue contains Process
    list_entry_t run_link;                      // the entry linked in run queue
    int time_slice;                             // time slice for occupying the CPU
    struct fs_struct *fs_struct;                // the file related info(pwd, files_count, files_array, fs_semaphore) of process
};
```

下面重点解释一下几个比较重要的成员变量：

- mm：内存管理的信息，包括内存映射列表、页表指针等。mm成员变量在lab3中用于虚存管理。但在实际OS中，内核线程常驻内存，不需要考虑swap page问题，在lab5中涉及到了用户进程，才考虑进程用户内存空间的swap page问题，mm才会发挥作用。所以在lab4中mm对于内核线程就没有用了，这样内核线程的proc\_struct的成员变量\*mm=0是合理的。mm里有个很重要的项pgdir，记录的是该进程使用的一级页表的物理地址。由于\*mm=NULL，所以在proc\_struct数据结构中需要有一个代替pgdir项来记录页表起始地址，这就是proc\_struct数据结构中的cr3成员变量。

- state：进程所处的状态。

- parent：用户进程的父进程（创建它的进程）。在所有进程中，只有一个进程没有父进程，就是内核创建的第一个内核线程idleproc。内核根据这个父子关系建立一个树形结构，用于维护一些特殊的操作，例如确定某个进程是否可以对另外一个进程进行某种操作等等。

- context：进程的上下文，用于进程切换（参见switch.S）。在 uCore中，所有的进程在内核中也是相对独立的（例如独立的内核堆栈以及上下文等等）。使用 context 保存寄存器的目的就在于在内核态中能够进行上下文之间的切换。实际利用context进行上下文切换的函数是在*kern/process/switch.S*中定义switch\_to。

- tf：中断帧的指针，总是指向内核栈的某个位置：当进程从用户空间跳到内核空间时，中断帧记录了进程在被中断前的状态。当内核需要跳回用户空间时，需要调整中断帧以恢复让进程继续执行的各寄存器值。除此之外，uCore内核允许嵌套中断。因此为了保证嵌套中断发生时tf 总是能够指向当前的trapframe，uCore 在内核栈上维护了 tf 的链，可以参考trap.c::trap函数做进一步的了解。

- cr3: cr3是x86指令集中保存页表基地址的CSR，这是因为x86采用硬件遍历页表完成TLB填充。而在LoongArch32版本的uCore中，软件定义页表使得我们不必在硬件上保留该寄存器，但uCore继续保留了该名称并用于指代页表基地址。目的就是进程切换的时候方便直接使用 lcr3 实现页表切换，避免每次都根据 mm 来计算 cr3。mm数据结构是用来实现用户空间的虚存管理的，但是内核线程没有用户空间，它执行的只是内核中的一小段代码（通常是一小段函数），所以它没有mm 结构，也就是NULL。当某个进程是一个普通用户态进程的时候，PCB 中的 cr3 就是 mm 中页表（pgdir）的物理地址；而当它是内核线程的时候，cr3 等于boot\_cr3。而boot\_cr3指向了uCore启动时建立好的饿内核虚拟空间的页目录表首地址。

- kstack: 每个线程都有一个内核栈，并且位于内核地址空间的不同位置。对于内核线程，该栈就是运行时的程序使用的栈；而对于普通进程，该栈是发生特权级改变的时候使保存被打断的硬件信息用的栈。uCore在创建进程时分配了 2 个连续的物理页（参见memlayout.h中KSTACKSIZE的定义）作为内核栈的空间。这个栈很小，所以内核中的代码应该尽可能的紧凑，并且避免在栈上分配大的数据结构，以免栈溢出，导致系统崩溃。kstack记录了分配给该进程/线程的内核栈的位置。主要作用有以下几点。首先，当内核准备从一个进程切换到另一个的时候，需要根据kstack 的值正确的设置好 tss （可以回顾一下在实验一中讲述的 tss 在中断处理过程中的作用），以便在进程切换以后再发生中断时能够使用正确的栈。其次，内核栈位于内核地址空间，并且是不共享的（每个线程都拥有自己的内核栈），因此不受到 mm 的管理，当进程退出的时候，内核能够根据 kstack 的值快速定位栈的位置并进行回收。uCore 的这种内核栈的设计借鉴的是 linux 的方法（但由于内存管理实现的差异，它实现的远不如 linux 的灵活），它使得每个线程的内核栈在不同的位置，这样从某种程度上方便调试，但同时也使得内核对栈溢出变得十分不敏感，因为一旦发生溢出，它极可能污染内核中其它的数据使得内核崩溃。如果能够通过页表，将所有进程的内核栈映射到固定的地址上去，能够避免这种问题，但又会使得进程切换过程中对栈的修改变得相当繁琐。感兴趣的同学可以参考 linux kernel 的代码对此进行尝试。

为了管理系统中所有的进程控制块，uCore维护了如下全局变量（位于*kern/process/proc.c*）：

- static struct proc \*current：当前占用CPU且处于“运行”状态进程控制块指针。通常这个变量是只读的，只有在进程切换的时候才进行修改，并且整个切换和修改过程需要保证操作的原子性，目前至少需要屏蔽中断。可以参考 switch\_to 的实现。

- static struct proc \*initproc：本实验中，指向一个内核线程。本实验以后，此指针将指向第一个用户态进程。

- static list\_entry\_t hash\_list[HASH\_LIST\_SIZE]：所有进程控制块的哈希表，proc\_struct中的成员变量hash\_link将基于pid链接入这个哈希表中。

- list\_entry\_t proc\_list：所有进程控制块的双向线性列表，proc\_struct中的成员变量list\_link将链接入这个链表中。

### 创建第 0 个内核线程 idleproc 

在init.c::kern\_init函数调用了proc.c::proc\_init函数。proc\_init函数启动了创建内核线程的步骤。首先当前的执行上下文（从kern\_init 启动至今）就可以看成是uCore内核（也可看做是内核进程）中的一个内核线程的上下文。为此，uCore通过给当前执行的上下文分配一个进程控制块以及对它进行相应初始化，将其打造成第0个内核线程 -- idleproc。具体步骤如下：

首先调用alloc\_proc函数来通过kmalloc函数获得proc\_struct结构的一块内存块-，作为第0个进程控制块。并把proc进行初步初始化（即把proc\_struct中的各个成员变量清零）。但有些成员变量设置了特殊的值，比如：

```
 proc->state = PROC_UNINIT;  设置进程为“初始”态
 proc->pid = -1;             设置进程pid的未初始化值
 proc->cr3 = boot_cr3;       使用内核页目录表的基址
 ...
```

上述三条语句中,第一条设置了进程的状态为“初始”态，这表示进程已经“出生”了，正在获取资源茁壮成长中；第二条语句设置了进程的pid为-1，这表示进程的“身份证号”还没有办好；第三条语句表明由于该内核线程在内核中运行，故采用为uCore内核已经建立的页表，即设置为在uCore内核页表的起始地址boot\_cr3。后续实验中可进一步看出所有内核线程的内核虚地址空间（也包括物理地址空间）是相同的。既然内核线程共用一个映射内核空间的页表，这表示内核空间对所有内核线程都是“可见”的，所以更精确地说，这些内核线程都应该是从属于同一个唯一的“大内核进程”—uCore内核。



接下来，proc\_init函数对idleproc内核线程进行进一步初始化：

```
idleproc->pid = 0;
idleproc->state = PROC_RUNNABLE;
idleproc->kstack = (uintptr_t)bootstack;
idleproc->need_resched = 1;
set_proc_name(idleproc, "idle");
```

需要注意前4条语句。第一条语句给了idleproc合法的身份证号--0，这名正言顺地表明了idleproc是第0个内核线程。通常可以通过pid的赋值来表示线程的创建和身份确定。“0”是第一个的表示方法是计算机领域所特有的，比如C语言定义的第一个数组元素的小标也是“0”。第二条语句改变了idleproc的状态，使得它从“出生”转到了“准备工作”，就差uCore调度它执行了。第三条语句设置了idleproc所使用的内核栈的起始地址。需要注意以后的其他线程的内核栈都需要通过分配获得，因为uCore启动时设置的内核栈直接分配给idleproc使用了。第四条很重要，因为uCore希望当前CPU应该做更有用的工作，而不是运行idleproc这个“无所事事”的内核线程，所以把idleproc-\>need\_resched设置为“1”，结合idleproc的执行主体--cpu\_idle函数的实现，可以清楚看出如果当前idleproc在执行，则只要此标志为1，马上就调用schedule函数要求调度器切换其他进程执行。

### 创建第 1 个内核线程 initproc 

第0个内核线程主要工作是完成内核中各个子系统的初始化，然后就通过执行cpu\_idle函数开始过退休生活了。所以uCore接下来还需创建其他进程来完成各种工作，但idleproc内核子线程自己不想做，于是就通过调用kernel\_thread函数创建了一个内核线程init\_main。在实验四中，这个子内核线程的工作就是输出一些字符串，然后就返回了（参看init\_main函数）。但在后续的实验中，init\_main的工作就是创建特定的其他内核线程或用户进程（实验五涉及）。下面我们来分析一下创建内核线程的函数kernel\_thread：

```
kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags)
{
	 struct trapframe tf;
    memset(&tf, 0, sizeof(struct trapframe));
    tf.tf_regs.reg_r[LOONGARCH_REG_A0] = (uint32_t)arg;
    tf.tf_regs.reg_r[LOONGARCH_REG_A1] = (uint32_t)fn;
    tf.tf_regs.reg_r[LOONGARCH_REG_A7] = 0;
    tf.tf_estat = read_csr_exst();
    tf.tf_era = (uint32_t)kernel_thread_entry;  
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
}
```

注意，kernel\_thread函数采用了局部变量tf来放置保存内核线程的临时中断帧，并把中断帧的指针传递给do\_fork函数，而do\_fork函数会调用copy\_thread函数来在新创建的进程内核栈上专门给进程的中断帧分配一块空间。给中断帧分配完空间后，就需要构造新进程的中断帧，具体过程是：首先给tf进行清零初始化，并设置tf.tf_regs.reg_r[LOONGARCH_REG_A0],tf.tf_regs.reg_r[LOONGARCH_REG_A1],tf.tf_regs.reg_r[LOONGARCH_REG_V7]，tf.tf_estat寄存器的值。tf.tf\_era的指出了是kernel\_thread\_entry（位于kern/process/entry.S中），kernel\_thread\_entry是entry.S中实现的汇编函数，它做的事情很简单：

```
kernel_thread_entry:
    addi.w  sp, sp,  -16
    //goto kernel_thread
    addi.w  t0, a1, 0
  //  la.abs  t0, a1
    jirl    ra, t0, 0
   // bl a1
    move    v0, a0
    //goto do_exit():see proc.c
    la.abs  t0, do_exit 
    jirl    ra, t0, 0
```

从上可以看出，kernel\_thread\_entry函数主要为内核线程的主体fn函数做了一个准备开始和结束运行的“壳”，并把函数fn的参数arg（保存在a0寄存器中）压栈，然后调用fn函数，把函数返回值a0寄存器内容压栈，调用do\_exit函数退出线程执行。

do\_fork是创建线程的主要函数。kernel\_thread函数通过调用do\_fork函数最终完成了内核线程的创建工作。下面我们来分析一下do\_fork函数的实现（练习2）。do\_fork函数主要做了以下6件事情：

1. 分配并初始化进程控制块（alloc\_proc函数）；
2. 分配并初始化内核栈（setup\_stack函数）；
3. 根据clone\_flag标志复制或共享进程内存管理结构（copy\_mm函数）；
4. 设置进程在内核（将来也包括用户态）正常运行和调度所需的中断帧和执行上下文（copy\_thread函数）；
5. 把设置好的进程控制块放入hash\_list和proc\_list两个全局进程链表中；
6. 自此，进程已经准备好执行了，把进程状态设置为“就绪”态；
7. 设置返回码为子进程的id号。

这里需要注意的是，如果上述前3步执行没有成功，则需要做对应的出错处理，把相关已经占有的内存释放掉。copy\_mm函数目前只是把current-\>mm设置为NULL，这是由于目前在实验四中只能创建内核线程，proc-\>mm描述的是进程用户态空间的情况，所以目前mm还用不上。copy\_thread函数做的事情比较多，代码如下：

```
static void
copy_thread(struct proc_struct *proc, uintptr_t esp, struct trapframe *tf) {
	proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
    *(proc->tf) = *tf;
    proc->tf->tf_regs.reg_r[LOONGARCH_REG_A7] = 0; // use A7 as syscall result register
    if(esp == 0) //a kernel thread
      esp = (uintptr_t)proc->tf - 32;
    proc->tf->tf_regs.reg_r[LOONGARCH_REG_SP] = esp;
    proc->context.sf_ra = (uintptr_t)forkret;
    proc->context.sf_sp = (uintptr_t)(proc->tf) - 32;
}
```
/////////////////////////
此函数首先在内核堆栈的顶部设置中断帧大小的一块栈空间，并在此空间中拷贝在kernel\_thread函数建立的临时中断帧的初始值，并进一步设置中断帧中的栈指针sp，这表示此内核线程在执行过程中，能响应中断，打断当前的执行。执行到这步后，此进程的中断帧就建立好了，对于initproc而言，它的中断帧如下所示：

```
//////////////////////////
//所在地址位置
initproc->tf= (proc->kstack+KSTACKSIZE) – sizeof (struct trapframe);
//具体内容
initproc->tf.tf_regs.reg_r[LOONGARCH_REG_A0] = (uint32_t)init_main;
initproc->tf.tf_regs.reg_r[LOONGARCH_REG_A1] = (uint32_t)fn;
initproc->tf.tf_regs.reg_r[LOONGARCH_REG_A7] = 0;
initproc->tf.tf_era = (uint32_t)kernel_thread_entry; 
initproc->tf->tf_regs.reg_r[LOONGARCH_REG_SP] = esp;
initproc->context.sf_ra = (uintptr_t)forkret;
initproc->context.sf_sp = (uintptr_t)(initproc->tf) - 32;
```

设置好中断帧后，最后就是设置initproc的进程上下文，（process context，也称执行现场）了。只有设置好执行现场后，一旦uCore调度器选择了initproc执行，就需要根据initproc-\>context中保存的执行现场来恢复initproc的执行。这里设置了initproc的执行现场中主要的两个信息：上次停止执行时的下一条指令地址context.sf_ra和上次停止执行时的堆栈地址context.sf_sp。其实initproc还没有执行过，所以这其实就是initproc实际执行的第一条指令地址和堆栈指针。可以看出，由于initproc的中断帧占用了实际给initproc分配的栈空间的顶部，所以initproc就只能把栈顶指针context.sf_sp设置在initproc的中断帧的起始位置。根据context.sf_ra的赋值，可以知道initproc实际开始执行的地方在forkret函数（主要完成do\_fork函数返回的处理工作）处。至此，initproc内核线程已经做好准备执行了。

### 调度并执行内核线程 initproc 

在uCore执行完proc\_init函数后，就创建好了两个内核线程：idleproc和initproc，这时uCore当前的执行现场就是idleproc，等到执行到init函数的最后一个函数cpu\_idle之前，uCore的所有初始化工作就结束了，idleproc将通过执行cpu\_idle函数让出CPU，给其它内核线程执行，具体过程如下：

```
void
cpu_idle(void) {
	while (1) {
		if (current->need_resched) {
			schedule();
			……
```

首先，判断当前内核线程idleproc的need\_resched是否不为0，回顾前面“创建第一个内核线程idleproc”中的描述，proc\_init函数在初始化idleproc中，就把idleproc-\>need\_resched置为1了，所以会马上调用schedule函数找其他处于“就绪”态的进程执行。

uCore在实验四中只实现了一个最简单的FIFO调度器，其核心就是schedule函数。它的执行逻辑很简单：

1．设置当前内核线程current-\>need\_resched为0；
2．在proc\_list队列中查找下一个处于“就绪”态的线程或进程next；
3．找到这样的进程后，就调用proc\_run函数，保存当前进程current的执行现场（进程上下文），恢复新进程的执行现场，完成进程切换。

至此，新的进程next就开始执行了。由于在proc10中只有两个内核线程，且idleproc要让出CPU给initproc执行，我们可以看到schedule函数通过查找proc\_list进程队列，只能找到一个处于“就绪”态的initproc内核线程。并通过proc\_run和进一步的switch\_to函数完成两个执行现场的切换，具体流程如下：

1. 让current指向next内核线程initproc；
2. 设置current_pgdir的值为next内核线程initproc的页目录表起始地址next-\>cr3，这实际上是完成进程间的页表切换；
3. 由switch\_to函数完成具体的两个线程的执行现场切换，即切换各个寄存器，当switch\_to函数执行最后一条指令时，就跳转到initproc执行了。

由于idleproc和initproc都是共用一个内核页表boot\_cr3，所以此时第二步其实没用，但考虑到以后的进程有各自的页表，其起始地址各不相同，只有完成页表切换，才能确保新的进程能够正常执行。

第三步proc\_run函数调用switch\_to函数，参数是前一个进程和后一个进程的执行现场：process context。在上一节“设计进程控制块”中，描述了context结构包含的要保存和恢复的寄存器。我们再看看switch.S中的switch\_to函数的执行流程：

```
.text
.globl switch_to
switch_to:
//save the registers
    st.w    sp, a0, 48
    st.w    fp, a0, 44
    st.w    ra, a0, 40
    st.w    tp, a0, 36
    st.w	s8, a0, 32
    st.w	s7, a0, 28
    st.w	s6, a0, 24
    st.w	s5, a0, 20
    st.w	s4, a0, 16
    st.w	s3, a0, 12
    st.w	s2, a0, 8
    st.w	s1, a0, 4
    st.w	s0, a0, 0

    //use as nop
    dbar    0
```

首先，保存前一个进程的执行现场，第三条汇编指令（如下所示）保存了进程在返回switch\_to函数后的指令地址到context.sf_ra中

```
 st.w    ra, a0, 40
```

在接下来的汇编指令完成了保存前一个进程的其他10个寄存器到context中的相应成员变量中。至此前一个进程的执行现场保存完毕。再往后是恢复向一个进程的执行现场，这其实就是上述保存过程的逆执行过程，逐一把context中相关成员变量的值赋值给对应的寄存器，最后两条汇编指令就是将程序跳转到context.sf_ra保存的地址处执行。即当前进程已经是下一个进程了。uCore会执行进程切换，让initproc执行。在对initproc进行初始化时，设置了initproc-\>context.sf_era = (uintptr\_t)forkret，这样，当执行switch\_to函数并返回后，initproc将执行其实际上的执行入口地址forkret。而forkret会调用位于kern/trap/trapentry.S中的forkrets函数执行，具体代码如下：

```
.global forkrets
.type forkrets, @function
forkrets:
  addi.w a0, sp, -16
  b exception_return
.end forkrets
```

可以看出，forkrets函数首先把sp指向当前进程的中断帧，再跳转到中断返回函数中开始执行中断返回相关操作。中断返回执行完之后开始执行initproc的主体了。Initprocde的主体函数很简单就是输出一段字符串，然后就返回到kernel\_tread\_entry函数，并进一步调用do\_exit执行退出操作了。本来do\_exit应该完成一些资源回收工作等，但这些不是实验四涉及的，而是由后续的实验来完成。至此，实验四中的主要工作描述完毕。
