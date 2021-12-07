## TLB Refill例外处理
  
对于LoongArch32架构而言，实现虚存管理的关键在于实现TLB相关的例外处理。其过程中主要涉及到函数 -- handle_tlbmiss的具体实现。在TLB中无法找到的页面或者该页面不为有效时，CPU会产生TLB Refill例外，从而设置CSR.PRMD并跳转到TLB Refill例外处理程序开始处理。这个TLB Refill用于完成软件定义页表的实现。在uCore的设计中，我们将TLB Refill例外入口的设置与通用例外入口设置相同，从而可以复用保存现场，设置CRMD、内核栈等代码，然后由trap_dispatch根据读取已经保存的trapframe中的CSR.ESTAT寄存器的值判断是否为TLB Refill相关的例外，若是，则调用`handle_tlbmiss`。


因此，大致的调用关系如下：

> loongarch_trap--\>trap_dispatch--\>handle_tlbmiss

而当`handle_tlbmiss`函数处理时，如果发现对应的PTE不存在，就需要对缺页（Page Fault）进行处理。这里首先调用了`pgfault_handler`函数，进行了相关检查后最终调用到了`do_pgfault`函数，下面需要具体分析一下do\_pgfault函数。do\_pgfault的调用关系如下所示：

> loongarch_trap--\>trap_dispatch--\>handle_tlbmiss--\>pgfault_handler--\>do_pgfault

ucore中do\_pgfault函数是完成页访问异常处理的主要函数，它根据在trapframe中保存的CPU的控制寄存器CSR.BADVA中获取的页访问异常的虚拟地址以及根据errorCode的错误类型来查找此地址是否在某个VMA的地址范围内以及是否满足正确的读写权限，如果在此范围内并且权限也正确，这认为这是一次合法访问，但没有建立虚实对应关系。所以需要分配一个空闲的内存页，并修改页表完成虚地址到物理地址的映射，刷新TLB，然后返回到产生页访问异常的指令处重新执行此指令。如果该虚地址不在某VMA范围内，则认为是一次非法访问。