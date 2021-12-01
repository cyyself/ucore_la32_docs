#### 创建第 1 个内核线程 initproc 

第0个内核线程主要工作是完成内核中各个子系统的初始化，然后就通过执行cpu\_idle函数开始过退休生活了。所以uCore接下来还需创建其他进程来完成各种工作，但idleproc内核子线程自己不想做，于是就通过调用kernel\_thread函数创建了一个内核线程init\_main。在实验四中，这个子内核线程的工作就是输出一些字符串，然后就返回了（参看init\_main函数）。但在后续的实验中，init\_main的工作就是创建特定的其他内核线程或用户进程（实验五涉及）。下面我们来分析一下创建内核线程的函数kernel\_thread：

```
kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags)
{
	 struct trapframe tf;
    memset(&tf, 0, sizeof(struct trapframe));
    tf.tf_regs.reg_r[LOONGARCH_REG_A0] = (uint32_t)arg;
    tf.tf_regs.reg_r[LOONGARCH_REG_A1] = (uint32_t)fn;
    tf.tf_regs.reg_r[LOONGARCH_REG_V0] = 0;
    tf.tf_estat = read_csr_exst();
    tf.tf_era = (uint32_t)kernel_thread_entry;  
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
}
```

注意，kernel\_thread函数采用了局部变量tf来放置保存内核线程的临时中断帧，并把中断帧的指针传递给do\_fork函数，而do\_fork函数会调用copy\_thread函数来在新创建的进程内核栈上专门给进程的中断帧分配一块空间。给中断帧分配完空间后，就需要构造新进程的中断帧，具体过程是：首先给tf进行清零初始化，并设置tf.tf_regs.reg_r[LOONGARCH_REG_A0],tf.tf_regs.reg_r[LOONGARCH_REG_A1],tf.tf_regs.reg_r[LOONGARCH_REG_V0]，tf.tf_estat寄存器的值。tf.tf\_era的指出了是kernel\_thread\_entry（位于kern/process/entry.S中），kernel\_thread\_entry是entry.S中实现的汇编函数，它做的事情很简单：

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
    proc->tf->tf_regs.reg_r[LOONGARCH_REG_V0] = 0;
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
initproc->tf.tf_regs.reg_r[LOONGARCH_REG_V0] = 0;
initproc->tf.tf_era = (uint32_t)kernel_thread_entry; 
initproc->tf->tf_regs.reg_r[LOONGARCH_REG_SP] = esp;
initproc->context.sf_ra = (uintptr_t)forkret;
initproc->context.sf_sp = (uintptr_t)(initproc->tf) - 32;
```

设置好中断帧后，最后就是设置initproc的进程上下文，（process context，也称执行现场）了。只有设置好执行现场后，一旦uCore调度器选择了initproc执行，就需要根据initproc-\>context中保存的执行现场来恢复initproc的执行。这里设置了initproc的执行现场中主要的两个信息：上次停止执行时的下一条指令地址context.sf_ra和上次停止执行时的堆栈地址context.sf_sp。其实initproc还没有执行过，所以这其实就是initproc实际执行的第一条指令地址和堆栈指针。可以看出，由于initproc的中断帧占用了实际给initproc分配的栈空间的顶部，所以initproc就只能把栈顶指针context.sf_sp设置在initproc的中断帧的起始位置。根据context.sf_ra的赋值，可以知道initproc实际开始执行的地方在forkret函数（主要完成do\_fork函数返回的处理工作）处。至此，initproc内核线程已经做好准备执行了。
