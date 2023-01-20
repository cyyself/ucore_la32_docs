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
