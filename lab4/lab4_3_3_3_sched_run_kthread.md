#### 调度并执行内核线程 initproc 

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
2. 设置CR3寄存器的值为next内核线程initproc的页目录表起始地址next-\>cr3，这实际上是完成进程间的页表切换；
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
