## 实验目的：

操作系统是一个软件，也需要通过某种机制加载并运行它。对于LoongArch32的计算机来说，上电复位最初启动的是一个BIOS软件（例如PMON），该BIOS软件能够支持从网络加载ELF格式的操作系统内核，从而开始启动我们已经编译好的uCore内核。

而对于QEMU虚拟机而言，我们可以直接使用`-kernel`来指定我们需要加载的内核的ELF文件，从而直接完成了内核的载入过程，并直接从ELF的入口点开始启动。

- ucore OS软件
  - 编译运行ucore OS的过程
  - ucore OS的启动过程
  - 调试ucore OS的方法
  - 函数调用关系：在汇编级了解函数调用栈的结构和处理过程
  - 中断管理：与软件相关的中断处理
  - 外设管理：时钟