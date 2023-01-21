## 用户进程管理 

### 创建用户进程 

在实验四中，我们已经完成了对内核线程的创建，但与用户进程的创建过程相比，创建内核线程的过程还远远不够。而这两个创建过程的差异本质上就是用户进程和内核线程的差异决定的。

#### 1. 应用程序的组成和编译 

我们首先来看一个应用程序，这里我们假定是hello应用程序，在user/hello.c中实现，代码如下：

```
#include <stdio.h>
#include <ulib.h>

int main(void) {
    cprintf("Hello world!!.\n");
    cprintf("I am process %d.\n", getpid());
    cprintf("hello pass.\n");
    return 0;
}
```

hello应用程序只是输出一些字符串，并通过系统调用sys\_getpid（在getpid函数中调用）输出代表hello应用程序执行的用户进程的进程标识--pid。

首先，我们需要了解ucore操作系统如何能够找到hello应用程序。这需要分析ucore和hello是如何编译的。在本实验源码目录下执行make，可得到如下输出：

```
……

+ cc user/hello.c

loongarch32-linux-gnu-gcc -c  -Iuser/libs -Ikern/include -fno-builtin-fprintf -fno-builtin -nostdlib  -nostdinc -g -G0 -Wa,-O0 -fno-pic -mno-shared -msoft-float -ggdb -gstabs -mlcsr   user/hello.c  -o obj/user/hello.o

loongarch32-linux-gnu-ld -T user/libs/user.ld  obj/user/hello.o --whole-archive obj/user/libuser.a -o obj/user/hello

……

sed 's/$FILE/hello/g' tools/piggy.S.in > obj/user/hello.S

……

# 注意，可以观察obj/user/hello.S文件，这里有使用.incbin去引入先前编译好的obj/user/hello
loongarch32-linux-gnu-gcc -c obj/user/hello.S -o obj/user/hello.piggy.o

loongarch32-linux-gnu-ld -nostdlib -n -G 0 -static -T tools/kernel.ld  obj/init/init.o  …… obj/user/hello.piggy.o …… -o obj/ucore-kernel-piggy

```

从中可以看出，hello应用程序不仅仅是hello.c，还包含了支持hello应用程序的用户态库：

* user/libs/initcode.S：所有应用程序的起始用户态执行地址“\_start”，调整了gp和sp后，调用umain函数。
* user/libs/umain.c：实现了umain函数，这是所有应用程序执行的第一个C函数，它将调用应用程序的main函数，并在main函数结束后调用exit函数，而exit函数最终将调用sys\_exit系统调用，让操作系统回收进程资源。
* user/libs/ulib.[ch]：实现了最小的C函数库，除了一些与系统调用无关的函数，其他函数是对访问系统调用的包装。
* user/libs/syscall.[ch]：用户层发出系统调用的具体实现。
* user/libs/stdio.c：实现cprintf函数，通过系统调用sys\_putc来完成字符输出。
* user/libs/panic.c：实现\_\_panic/\_\_warn函数，通过系统调用sys\_exit完成用户进程退出。

除了这些用户态库函数实现外，还有一些libs/\*.[ch]是操作系统内核和应用程序共用的函数实现。这些用户库函数其实在本质上与UNIX系统中的标准libc没有区别，只是实现得很简单，但hello应用程序的正确执行离不开这些库函数。

【注意】libs/\*.[ch]、user/libs/\*.[ch]、user/\*.[ch]的源码中没有任何特权指令。

a00c3160 _binary_obj_user_hello_end
a00125ac file_open
a00018d0 strcpy
a0000240 ide_device_valid
a01455c0 _binary_obj_user_forktree_start
a000cb30 wakeup_queue
a00156f0 vfs_set_bootfs
a000d12c cond_signal
a0011850 sysfile_fsync
a001a57c dev_init_stdout
a00b4ac0 _binary_obj_user_hello_start

在make的最后一步执行了一个ld命令，把hello应用程序的执行码obj/user/hello.piggy.o连接在了ucore kernel的末尾。并观察`tools/piggy.S.in`文件可以发现，我们定义了.global \_binary\_obj\_user\_$FILE\_start和.global \_binary\_obj\_user\_$FILE_end。这样这两个符号就会保留在最终ld生成的文件中，这样这个hello用户程序就能够和ucore内核一起被 bootloader 加载到内存里中，并且通过这两个全局变量定位hello用户程序执行码的起始位置和大小。而到了与文件系统相关的实验后，ucore会提供一个简单的文件系统，那时所有的用户程序就都不再用这种方法进行加载了，而可以用大家熟悉的文件方式进行加载了。

（注，后续的文件系统采用initrd的方式，并非位于磁盘。）

#### 2. 用户进程的虚拟地址空间 

在user/libs/user.ld描述了用户程序的用户虚拟空间的执行入口虚拟地址：

```
SECTIONS {
    /* Load programs at this address: "." means the current address */
    . = 0x10000000;
```

在tools/kernel.ld描述了操作系统的内核虚拟空间的起始入口虚拟地址：

```
SECTIONS {
    /* Load the kernel at this address: "." means the current address */
    . = 0xa0000000;
```

这样ucore把用户进程的虚拟地址空间分了两块，一块与内核线程一样，是所有用户进程都共享的内核虚拟地址空间，映射到同样的物理内存空间中，这样在物理内存中只需放置一份内核代码，使得用户进程从用户态进入核心态时，内核代码可以统一应对不同的内核程序；另外一块是用户虚拟地址空间，虽然虚拟地址范围一样，但映射到不同且没有交集的物理内存空间中。这样当ucore把用户进程的执行代码（即应用程序的执行代码）和数据（即应用程序的全局变量等）放到用户虚拟地址空间中时，确保了各个进程不会“非法”访问到其他进程的物理内存空间。

这样ucore给一个用户进程具体设定的虚拟内存空间（kern/mm/memlayout.h）如下所示：

![image](../lab5_figs/image001.png)

#### 3. 创建并执行用户进程 

在确定了用户进程的执行代码和数据，以及用户进程的虚拟空间布局后，我们可以来创建用户进程了。在本实验中第一个用户进程是由第二个内核线程initproc通过把hello应用程序执行码覆盖到initproc的用户虚拟内存空间来创建的，相关代码如下所示：

```
    // kernel_execve - do SYS_exec syscall to exec a user program called by user_main kernel_thread
static int kernel_execve(const char *name, unsigned char *binary, size_t size) {
    int ret, len = strlen(name);
    asm volatile(
      "addi.w   $a7, $zero,%1;\n" // syscall no.
      "move $a0, %2;\n"
      "move $a1, %3;\n"
      "move $a2, %4;\n"
      "move $a3, %5;\n"
      "syscall  0;\n"
      "move %0, $a7;\n"
      : "=r"(ret)
      : "i"(SYSCALL_BASE+SYS_exec), "r"(name), "r"(len), "r"(binary), "r"(size) 
      : "a0", "a1", "a2", "a3", "a7"
    );
    return ret;
}

#define __KERNEL_EXECVE(name, path, ...) ({                         \
const char *argv[] = {path, ##__VA_ARGS__, NULL};       \
					 kprintf("kernel_execve: pid = %d, name = \"%s\".\n",    \
							 current->pid, name);                            \
					 kernel_execve(name, argv);                              \
})

#define KERNEL_EXECVE(x, ...)                   __KERNEL_EXECVE(#x, #x, ##__VA_ARGS__)
……
// init_main - the second kernel thread used to create kswapd_main & user_main kernel threads
static int
init_main(void *arg) {
    #ifdef TEST
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
    #else
    KERNEL_EXECVE(hello);
    #endif
    panic("kernel_execve failed.\n");
    return 0;
}
```

对于上述代码，我们需要从后向前按照函数/宏的实现一个一个来分析。Initproc的执行主体是init\_main函数，这个函数在缺省情况下是执行宏KERNEL\_EXECVE(hello)，而这个宏最终是调用kernel\_execve函数来调用SYS\_exec系统调用，由于ld在链接hello应用程序执行码时定义了两全局变量：

* \_binary\_obj\_\_\_user\_hello\_out\_start：hello执行码的起始位置
* \_binary\_obj\_\_\_user\_hello\_out\_size中：hello执行码的大小

kernel\_execve把这两个变量作为SYS\_exec系统调用的参数，让ucore来创建此用户进程。当ucore收到此系统调用后，将依次调用如下函数

```
vector128(vectors.S)--\>
\_\_alltraps(trapentry.S)--\>trap(trap.c)--\>trap\_dispatch(trap.c)--
--\>syscall(syscall.c)--\>sys\_exec（syscall.c）--\>do\_execve(proc.c)
```

最终通过do\_execve函数来完成用户进程的创建工作。此函数的主要工作流程如下：

* 首先为加载新的执行码做好用户态内存空间清空准备。如果mm不为NULL，则设置页表为内核空间页表，且进一步判断mm的引用计数减1后是否为0，如果为0，则表明没有进程再需要此进程所占用的内存空间，为此将根据mm中的记录，释放进程所占用户空间内存和进程页表本身所占空间。最后把当前进程的mm内存管理指针为空。由于此处的initproc是内核线程，所以mm为NULL，整个处理都不会做。

* 接下来的一步是加载应用程序执行码到当前进程的新创建的用户态虚拟空间中。这里涉及到读ELF格式的文件，申请内存空间，建立用户态虚存空间，加载应用程序执行码等。load\_icode函数完成了整个复杂的工作。

load\_icode函数的主要工作就是给用户进程建立一个能够让用户进程正常运行的用户环境。此函数有一百多行，完成了如下重要工作：

1. 调用mm\_create函数来申请进程的内存管理数据结构mm所需内存空间，并对mm进行初始化；

2. 调用setup\_pgdir来申请一个页目录表所需的一个页大小的内存空间，并把描述ucore内核虚空间映射的内核页表（boot\_pgdir所指）的内容拷贝到此新目录表中，最后让mm-\>pgdir指向此页目录表，这就是进程新的页目录表了，且能够正确映射内核虚空间；

3. 根据应用程序执行码的起始位置来解析此ELF格式的执行程序，并调用mm\_map函数根据ELF格式的执行程序说明的各个段（代码段、数据段、BSS段等）的起始位置和大小建立对应的vma结构，并把vma插入到mm结构中，从而表明了用户进程的合法用户态虚拟地址空间；

4. 调用根据执行程序各个段的大小分配物理内存空间，并根据执行程序各个段的起始位置确定虚拟地址，并在页表中建立好物理地址和虚拟地址的映射关系，然后把执行程序各个段的内容拷贝到相应的内核虚拟地址中，至此应用程序执行码和数据已经根据编译时设定地址放置到虚拟内存中了；

5. 需要给用户进程设置用户栈，为此调用mm\_mmap函数建立用户栈的vma结构，明确用户栈的位置在用户虚空间的顶端，大小为256个页，即1MB，并分配一定数量的物理内存且建立好栈的虚地址<--\>物理地址映射关系；

6. 至此,进程内的内存管理vma和mm数据结构已经建立完成，于是把mm-\>pgdir赋值到变量current_pgdir中，即更新了用户进程的虚拟内存空间，此时的initproc已经被hello的代码和数据覆盖，成为了第一个用户进程，但此时这个用户进程的执行现场还没建立好；

7. 先清空进程的中断帧，再重新设置进程的中断帧，使得在执行中断返回指令后，能够让CPU转到用户态特权级，并回到用户态内存空间，且能够跳转到用户进程的第一条指令执行，并确保在用户态能够响应中断；

至此，用户进程的用户环境已经搭建完毕。此时initproc将按产生系统调用的函数调用路径原路返回，执行中断返回指令“ertn”（位于exception.S的最后一句）后，将切换到用户进程hello的第一条语句位置\_start处（位于user/libs/initcode.S的第三句）开始执行。

### 进程退出和等待进程 

当进程执行完它的工作后，就需要执行退出操作，释放进程占用的资源。ucore分了两步来完成这个工作，首先由进程本身完成大部分资源的占用内存回收工作，然后由此进程的父进程完成剩余资源占用内存的回收工作。为何不让进程本身完成所有的资源回收工作呢？这是因为进程要执行回收操作，就表明此进程还存在，还在执行指令，这就需要内核栈的空间不能释放，且表示进程存在的进程控制块不能释放。所以需要父进程来帮忙释放子进程无法完成的这两个资源回收工作。

为此在用户态的函数库中提供了exit函数，此函数最终访问sys\_exit系统调用接口让操作系统来帮助当前进程执行退出过程中的部分资源回收。我们来看看ucore是如何做进程退出工作的。

首先，exit函数会把一个退出码error\_code传递给ucore，ucore通过执行内核函数do\_exit来完成对当前进程的退出处理，主要工作简单地说就是回收当前进程所占的大部分内存资源，并通知父进程完成最后的回收工作，具体流程如下：

**1.** 如果current-\>mm != NULL，表示是用户进程，则开始回收此用户进程所占用的用户态虚拟内存空间；

a)
首先执行“lcr3(boot\_cr3)”，切换到内核态的页表上，这样当前用户进程目前只能在内核虚拟地址空间执行了，这是为了确保后续释放用户态内存和进程页表的工作能够正常执行；

b)
如果当前进程控制块的成员变量mm的成员变量mm\_count减1后为0（表明这个mm没有再被其他进程共享，可以彻底释放进程所占的用户虚拟空间了。），则开始回收用户进程所占的内存资源：

i.
调用exit\_mmap函数释放current-\>mm-\>vma链表中每个vma描述的进程合法空间中实际分配的内存，然后把对应的页表项内容清空，最后还把页表所占用的空间释放并把对应的页目录表项清空；

ii. 调用put\_pgdir函数释放当前进程的页目录所占的内存；

iii. 调用mm\_destroy函数释放mm中的vma所占内存，最后释放mm所占内存；

c)
此时设置current-\>mm为NULL，表示与当前进程相关的用户虚拟内存空间和对应的内存管理成员变量所占的内核虚拟内存空间已经回收完毕；

**2.**
这时，设置当前进程的执行状态current-\>state=PROC\_ZOMBIE，当前进程的退出码current-\>exit\_code=error\_code。此时当前进程已经不能被调度了，需要此进程的父进程来做最后的回收工作（即回收描述此进程的内核栈和进程控制块）；

**3.** 如果当前进程的父进程current-\>parent处于等待子进程状态：

current-\>parent-\>wait\_state==WT\_CHILD，

则唤醒父进程（即执行“wakup\_proc(current-\>parent)”），让父进程帮助自己完成最后的资源回收；

**4.**
如果当前进程还有子进程，则需要把这些子进程的父进程指针设置为内核线程initproc，且各个子进程指针需要插入到initproc的子进程链表中。如果某个子进程的执行状态是PROC\_ZOMBIE，则需要唤醒initproc来完成对此子进程的最后回收工作。

**5.** 执行schedule()函数，选择新的进程执行。

那么父进程如何完成对子进程的最后回收工作呢？这要求父进程要执行wait用户函数或wait\_pid用户函数，这两个函数的区别是，wait函数等待任意子进程的结束通知，而wait\_pid函数等待进程id号为pid的子进程结束通知。这两个函数最终访问sys\_wait系统调用接口让ucore来完成对子进程的最后回收工作，即回收子进程的内核栈和进程控制块所占内存空间，具体流程如下：

**1.**
如果pid!=0，表示只找一个进程id号为pid的退出状态的子进程，否则找任意一个处于退出状态的子进程；

**2.**
如果此子进程的执行状态不为PROC\_ZOMBIE，表明此子进程还没有退出，则当前进程只好设置自己的执行状态为PROC\_SLEEPING，睡眠原因为WT\_CHILD（即等待子进程退出），调用schedule()函数选择新的进程执行，自己睡眠等待，如果被唤醒，则重复跳回步骤1处执行；

**3.**
如果此子进程的执行状态为PROC\_ZOMBIE，表明此子进程处于退出状态，需要当前进程（即子进程的父进程）完成对子进程的最终回收工作，即首先把子进程控制块从两个进程队列proc\_list和hash\_list中删除，并释放子进程的内核堆栈和进程控制块。自此，子进程才彻底地结束了它的执行过程，消除了它所占用的所有资源。

### 系统调用实现 

系统调用的英文名字是System Call。操作系统为什么需要实现系统调用呢？其实这是实现了用户进程后，自然引申出来需要实现的操作系统功能。用户进程只能在操作系统给它圈定好的“用户环境”中执行，但“用户环境”限制了用户进程能够执行的指令，即用户进程只能执行一般的指令，无法执行特权指令。如果用户进程想执行一些需要特权指令的任务，比如通过网卡发网络包等，只能让操作系统来代劳了。于是就需要一种机制来确保用户进程不能执行特权指令，但能够请操作系统“帮忙”完成需要特权指令的任务，这种机制就是系统调用。

采用系统调用机制为用户进程提供一个获得操作系统服务的统一接口层，这样一来可简化用户进程的实现，把一些共性的、繁琐的、与硬件相关、与特权指令相关的任务放到操作系统层来实现，但提供一个简洁的接口给用户进程调用；二来这层接口事先可规定好，且严格检查用户进程传递进来的参数和操作系统要返回的数据，使得让操作系统给用户进程服务的同时，保护操作系统不会被用户进程破坏。

从硬件层面上看，需要硬件能够支持在用户态的用户进程通过某种机制切换到内核态。试验一讲述中断硬件支持和软件处理过程其实就可以用来完成系统调用所需的软硬件支持。下面我们来看看如何在ucore中实现系统调用。

#### 1. 建立系统调用的用户库准备 

在操作系统中初始化好系统调用相关的中断描述符、中断处理起始地址等后，还需在用户态的应用程序中初始化好相关工作，简化应用程序访问系统调用的复杂性。为此在用户态建立了一个中间层，即简化的libc实现，在user/libs/ulib.[ch]和user/libs/syscall.[ch]中完成了对访问系统调用的封装。用户态最终的访问系统调用函数是syscall，实现如下：

```
static inline int
syscall(int num, ...) {
    va_list ap;
    va_start(ap, num);
    uint32_t arg[MAX_ARGS];
    int i, ret;
    for (i = 0; i < MAX_ARGS; i ++) {
        arg[i] = va_arg(ap, uint32_t);
    }
    va_end(ap);

    num += SYSCALL_BASE;
    asm volatile(
      "move $a7, %1;\n" /* syscall no. */
      "move $a0, %2;\n"
      "move $a1, %3;\n"
      "move $a2, %4;\n"
      "move $a3, %5;\n"
      "syscall 0;\n"
      "move %0, $a7;\n"
      : "=r"(ret)
      : "r"(num), "r"(arg[0]), "r"(arg[1]), "r"(arg[2]), "r"(arg[3]) 
      : "a0", "a1", "a2", "a3", "a7"
    );
    return ret;
}
```

#### 2. 与用户进程相关的系统调用 

在本实验中，与进程相关的各个系统调用属性如下所示：

<table>
<tr><td>系统调用名</td><td>含义</td><td>具体完成服务的函数</td></tr>
<tr><td>SYS_exit</td><td>process exit</td><td>do_exit</td></tr>
<tr><td>SYS_fork</td><td>create child process, dup mm </td><td>do_fork-->wakeup_proc</td></tr>
<tr><td>SYS_wait</td><td>wait child process</td><td>do_wait</td></tr>
<tr><td>SYS_exec</td><td>after fork, process execute a new program</td><td>load a program and refresh the mm</td></tr>
<tr><td>SYS_yield</td><td>process flag itself need resecheduling</td><td>proc->need_sched=1, then scheduler will rescheule this process</td></tr>
<tr><td>SYS_kill</td><td>kill process</td><td>do_kill-->proc->flags |= PF_EXITING,                                                        -->wakeup_proc-->do_wait-->do_exit</td></tr>
<tr><td>SYS_getpid</td><td>get the process's pid</td><td> </td></tr>
</table>

通过这些系统调用，可方便地完成从进程/线程创建到退出的整个运行过程。

#### 3. 系统调用的执行过程 

与用户态的函数库调用执行过程相比，系统调用执行过程的有四点主要的不同：

* 通过“syscall”指令发起调用；
* 通过“ertn”指令完成调用返回；
* 当到达内核态后，操作系统需要严格检查系统调用传递的参数，确保不破坏整个系统的安全性；
* 执行系统调用可导致进程等待某事件发生，从而可引起进程切换；

下面我们以getpid系统调用的执行过程大致看看操作系统是如何完成整个执行过程的。当用户进程调用getpid函数，最终执行到“syscall”指令后，CPU根据操作系统建立的系统调用中断描述符，转入内核态，并跳转到exception13处（kern/trap/exception.S），开始了操作系统的系统调用执行过程，函数调用和返回操作的关系如下所示：

```
exception13(exception.S)--\>
\_\loongarch_trap(trap.c)--\>trap\_dispatch(trap.c)--
--\>syscall(syscall.c)--\>sys\_getpid(syscall.c)--\>……--\>\_\exception_return(exception.S)
```

在执行trap函数前，软件还需进一步保存执行系统调用前的执行现场，即把与用户进程继续执行所需的相关寄存器等当前内容保存到当前进程的中断帧trapframe中（注意，在创建进程是，把进程的trapframe放在给进程的内核栈分配的空间的顶部）。软件做的工作在exception.S的exception_handler函数部分：

```
exception_handler:
    // Save t0 and t1
	csrwr   t0, LISA_CSR_KS0
    csrwr   t1, LISA_CSR_KS1
    // Save previous stack pointer in t1
    move    t1, sp
    csrwr   t1, LISA_CSR_KS2
    //t1 saved the vaual of KS2,KS2 saved sp
    /*
        Warning: csrwr will bring the old csr register value into rd, 
        not only just write rd to csr register,
        so you may see the rd changed.
        It's documented in the manual from loongarch.
    */

    // check if user mode
    csrrd   t0, LISA_CSR_PRMD  
    andi    t0, t0, 3
    beq     t0, zero, 1f

    
    /* Coming from user mode - load kernel stack into sp */
    la      t0, current // current pointer
    ld.w    t0, t0, 0 // proc struct
    ld.w    t0, t0, 12 // kstack pointer
    addi.w  t1, zero, 1
    slli.w  t1, t1, 13 // KSTACKSIZE=8192=pow(2,13)
    add.w   sp, t0, t1
    csrrd   t1, LISA_CSR_KS2
  
1:
    //saved EXST to t0 for save EXST to sp later(line 114) 
    csrrd   t0, LISA_CSR_EXST
    //return KS2
    csrrd   t1, LISA_CSR_KS2
    b common_exception


common_exception:
   /*
    * At this point:
    *      Interrupts are off. (The processor did this for us.)
    *      t0 contains the exception status(like exception cause on MIPS).
    *      t1 contains the old stack pointer.
    *      sp points into the kernel stack.
    *      All other registers are untouched.
    */
   
   /*
    * Allocate stack space for 35 words to hold the trap frame,
    * plus four more words for a minimal argument block.
    */
    addi.w  sp, sp, -156
    st.w    s8, sp, 148
    st.w    s7, sp, 144
    st.w    s6, sp, 140
    st.w    s5, sp, 136
    st.w    s4, sp, 132
    st.w    s3, sp, 128
    st.w    s2, sp, 124
    st.w    s1, sp, 120
    st.w    s0, sp, 116
    st.w    fp, sp, 112
    st.w    reserved_reg, sp, 108
    st.w    t8, sp, 104
    st.w    t7, sp, 100
    st.w    t6, sp, 96
    st.w    t5, sp, 92
    st.w    t4, sp, 88
    st.w    t3, sp, 84
    st.w    t2, sp, 80
    //st.w    t1, sp, 76
    //st.w    t0, sp, 72
    st.w    a7, sp, 68
    st.w    a6, sp, 64
    st.w    a5, sp, 60
    st.w    a4, sp, 56
    st.w    a3, sp, 52
    st.w    a2, sp, 48
    st.w    a1, sp, 44
    st.w    a0, sp, 40
    st.w    t1, sp, 36  // replace sp with real sp, now use t1 for free
    st.w    tp, sp, 32
    // save real t0 and t1 after real sp (stored in t1 previously) stored
    csrrd   t1, LISA_CSR_KS1
    st.w    t1, sp, 76
    csrrd   t1, LISA_CSR_KS0
    st.w    t1, sp, 72
    
    // replace with real value
    // save tf_era after t0 and t1 saved
    csrrd   t1, LISA_CSR_EPC
    st.w    t1, sp, 152

   /*
    * Save remaining exception context information.
    */

    // save ra (note: not in pushregs, it's tf_ra)
    st.w    ra, sp, 28
    // save prmd
    csrrd   t1, LISA_CSR_PRMD
    st.w    t1, sp, 24
    // save estat
    st.w    t0, sp, 20
    // now use t0 for free
    // store badv
    csrrd   t0, LISA_CSR_BADV
    st.w    t0, sp, 16
    st.w    zero, sp, 12
    // support nested interrupt

    // IE and PLV will automatically set to 0 when trap occur

    // set trapframe as function argument
    addi.w  a0, sp, 16
	li	t0, 0xb0	# PLV=0, IE=0, PG=1
	csrwr	t0, LISA_CSR_CRMD
    la.abs  t0, loongarch_trap
    jirl    ra, t0, 0
    //bl loongarch_trap
……
```

自此，用于保存用户态的用户进程执行现场的trapframe的内容填写完毕，操作系统可开始完成具体的系统调用服务。在sys\_getpid函数中，简单地把当前进程的pid成员变量做为函数返回值就是一个具体的系统调用服务。完成服务后，操作系统按调用关系的路径原路返回到\_\_exception.S中。然后操作系统开始根据当前进程的中断帧内容做恢复执行现场操作。其实就是把trapframe的一部分内容保存到寄存器内容。这是内核栈的结构如下：

```
exception_return:
    // restore prmd
    ld.w    t0, sp, 24
    li      t1, 7
    csrxchg t0, t1, LISA_CSR_PRMD
    // restore era no k0 and k1 for la32, so must do first
    ld.w    t0, sp, 152
    csrwr   t0, LISA_CSR_EPC
    // restore general registers
    ld.w    ra, sp, 28
    ld.w    tp, sp, 32
    //ld.w    sp, sp, 36 (do it finally)
    ld.w    a0, sp, 40
    ld.w    a1, sp, 44
    ld.w    a2, sp, 48
    ld.w    a3, sp, 52
    ld.w    a4, sp, 56
    ld.w    a5, sp, 60
    ld.w    a6, sp, 64
    ld.w    a7, sp, 68
    ld.w    t0, sp, 72
    ld.w    t1, sp, 76
    ld.w    t2, sp, 80
    ld.w    t3, sp, 84
    ld.w    t4, sp, 88
    ld.w    t5, sp, 92
    ld.w    t6, sp, 96
    ld.w    t7, sp, 100
    ld.w    t8, sp, 104
    ld.w    reserved_reg, sp, 108
    ld.w    fp, sp, 112
    ld.w    s0, sp, 116
    ld.w    s1, sp, 120
    ld.w    s2, sp, 124
    ld.w    s3, sp, 128
    ld.w    s4, sp, 132
    ld.w    s5, sp, 136
    ld.w    s6, sp, 140
    ld.w    s7, sp, 144
    ld.w    s8, sp, 148
    // restore sp
    ld.w    sp, sp, 36
    ertn

    .end exception_return
    .end common_exception
```

这时执行“ertn”指令后，CPU根据内核栈的情况回复到用户态，即“syscall”后的那条指令。这样整个系统调用就执行完毕了。

至此，实验五中的主要工作描述完毕。
