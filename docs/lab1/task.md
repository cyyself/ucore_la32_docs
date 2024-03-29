## 练习
为了实现lab1的目标，lab1提供了4个基本练习，要求完成实验报告。
注意有“LAB1”的注释，代码中所有需要完成的地方（challenge除外）都有“LAB1”和“YOUR CODE”的注释

对实验报告的要求：
 - 基于markdown格式来完成，以文本方式为主。
 - 填写各个基本练习中要求完成的报告内容
 - 完成实验后，请分析ucore_lab中提供的参考答案，并请在实验报告中说明你的实现与参考答案的区别
 - 列出你认为本实验中重要的知识点，以及与对应的OS原理中的知识点，并简要说明你对二者的含义，关系，差异等方面的理解（也可能出现实验中的知识点没有对应的原理知识点）
 - 列出你认为OS原理中很重要，但在实验中没有对应上的知识点

### 练习1：理解通过make生成执行文件的过程。（要求在报告中写出对下述问题的回答）

列出本实验各练习中对应的OS原理的知识点，并说明本实验中的实现部分如何对应和体现了原理中的基本概念和关键知识点。
 
在此练习中，大家需要通过静态分析代码来了解：

1. 操作系统镜像文件ucore-kernel.elf是如何一步一步生成的？(需要比较详细地解释Makefile中每一条相关命令和命令参数的含义，以及说明命令导致的结果)

补充材料：

如何调试Makefile

当执行make时，一般只会显示输出，不会显示make到底执行了哪些命令。

如想了解make执行了哪些命令，我们在Makefile中设置了`V=@`参数，`@`在Makefile中用于隐藏执行的命令，若想要显示，我们可以在每次`make`执行时添加参数`V=`来避免隐藏执行的命令：

	$ make clean
	$ make "V="

要获取更多有关make的信息，可上网查询，并请执行

	$ man make

### 练习2：使用qemu执行并调试lab1中的软件。（要求在报告中简要写出练习过程）

为了熟悉使用qemu和gdb进行的调试工作，我们进行如下的小练习：

1. 从uCore内核的入口点开始，单步跟踪内核初始化的执行
2. 自己找一个内核中的代码位置，设置断点并进行测试。

补充材料：
我们主要通过硬件模拟器qemu来进行各种实验。在实验的过程中我们可能会遇上各种各样的问题，调试是必要的。qemu支持使用gdb进行的强大而方便的调试。所以用好qemu和gdb是完成各种实验的基本要素。

默认的gdb需要进行一些额外的配置才进行qemu的调试任务。qemu和gdb之间使用网络端口1234进行通讯。在打开qemu进行模拟之后，执行gdb并输入

	target remote localhost:1234

即可连接qemu，此时qemu会进入停止状态，听从gdb的命令。

另外，我们可能需要qemu在一开始便进入等待模式，则我们不再使用make qemu开始系统的运行，而使用make debug来完成这项工作。这样qemu便不会在gdb尚未连接的时候擅自运行了。

***gdb的地址断点***

在gdb命令行中，使用b *[地址]便可以在指定内存地址设置断点，当qemu中的cpu执行到指定地址时，便会将控制权交给gdb。

***gdb的单步命令***

在gdb中，有next, nexti, step, stepi等指令来单步调试程序，他们功能各不相同，区别在于单步的“跨度”上。

	next 单步到程序源代码的下一行，不进入函数。
	nexti 单步一条机器指令，不进入函数。
	step 单步到下一个不同的源代码行（包括进入函数）。
	stepi 单步一条机器指令。


### 练习3：分析内核启动后在启用映射地址翻译之前需要在CSR中写入哪些必要配置？。（要求在报告中写出分析）

提示：需要阅读**小节“LoongArch32存储管理”**和kern/init/entry.S源码，了解内核如何进行DMW的配置，需要了解：
 - DMW有几个，可配置项有哪些？
 - 对于一个地址映射窗口，什么情况下可以启用一致可缓存？什么情况下必须强序非缓存？（提示：可以了解MMIO与DMA对于内存序以及是否缓存的要求。）
 - 在LoongArch32架构中，页表与DMW同时匹配时，哪个优先级更高？


### 练习4：完善例外初始化和处理 （需要编程）

请完成编码工作和回答如下问题：

1. 结合LoongArch32的文档，列出LoongArch32有哪些例外？以及这些例外有哪两个例外向量入口？
2. 请编程完善`kern/driver/clock.c`中的时钟中断处理函数`clock_int_handler`，在对时钟中断进行处理的部分填写trap函数中处理时钟中断的部分，使操作系统每遇到100次时钟中断后，调用kprintf，向屏幕上打印一行文字”100 ticks”。
3. 请编程完善`kern/driver/console.c`中的串口中断处理函数`serial_int_handler`，在接收到一个字符后读取该字符，并调用kprintf输出该字符。


要求完成问题2、3提出的相关函数实现，提交改进后的源代码包（可以编译执行），并在实验报告中简要说明实现过程，并写出对问题1的回答。完成这问题2和3要求的部分代码后，运行整个系统，可以看到大约每1秒会输出一次”100 ticks”，而按下的键也会在屏幕上显示。



提示：可阅读小节“中断与异常”。
