
**链接地址/虚地址/物理地址/加载地址以及edata/end/text的含义**

**链接脚本简介**

ucore kernel各个部分由组成kernel的各个.o或.a文件构成，且各个部分在内存中地址位置由ld工具根据kernel.ld链接脚本（linker
script）来设定。ld工具使用命令-T指定链接脚本。链接脚本主要用于规定如何把输入文件（各个.o或.a文件）内的section放入输出文件（lab2/bin/kernel，即ELF格式的ucore内核）内，
并控制输出文件内各部分在程序地址空间内的布局。下面简单分析一下/lab2/tools/kernel.ld，来了解一下ucore内核的地址布局情况。kernel.ld的内容如下所示：

```
OUTPUT_ARCH(loongarch)
ENTRY(kernel_entry)
SECTIONS
{
    . = 0xa0000000;

  .text      :
  {
    . = ALIGN(4);
    wrs_kernel_text_start = .; _wrs_kernel_text_start = .;
    *(.startup)
    *(.text) 
    *(.text.*)
    *(.gnu.linkonce.t*)
    *(.mips16.fn.*) 
    *(.mips16.call.*) /* for MIPS */
    *(.rodata) *(.rodata.*) *(.gnu.linkonce.r*) *(.rodata1)
    . = ALIGN(4096);
    *(.ramexv)
  }

  . = ALIGN(16);
  wrs_kernel_text_end = .; _wrs_kernel_text_end = .;
  etext = .; _etext = .;

  .stab : {
      . = ALIGN(4);
      PROVIDE(__STAB_BEGIN__ = .);
      *(.stab)
      PROVIDE(__STAB_END__ = .);
      BYTE(0)     /* Force the linker to allocate space
                 for this section */
      . = ALIGN(4);
  }

  .stabstr : {
      . = ALIGN(4);
      PROVIDE(__STABSTR_BEGIN__ = .);
      *(.stabstr)
      PROVIDE(__STABSTR_END__ = .);
      BYTE(0)     /* Force the linker to allocate space
                 for this section */
      . = ALIGN(4);
  }

  .data ALIGN(4)   : 
  {
    wrs_kernel_data_start = .; _wrs_kernel_data_start = .;
    *(.data)
    *(.data.*)
    *(.gnu.linkonce.d*)
    *(.data1)
    *(.eh_frame)
    *(.gcc_except_table)
    . = ALIGN(8);
    _gp = . + 0x7ff0;  /* set gp for MIPS startup code */
      /* got*, dynamic, sdata*, lit[48], and sbss should follow _gp */
    *(.got.plt)
    *(.got)
    *(.dynamic)
    *(.got2)
    *(.sdata) *(.sdata.*) *(.lit8) *(.lit4)
      . = ALIGN(16);
  }

  . = ALIGN(16);
  edata = .; _edata = .;
  wrs_kernel_data_end = .; _wrs_kernel_data_end = .;

  .bss  ALIGN(4)  :
  {
    wrs_kernel_bss_start = .; _wrs_kernel_bss_start = .;
    *(.sbss) *(.scommon) *(.dynbss) *(.bss) *(COMMON)
    . = ALIGN(16);
  }

  . = ALIGN(16);
  end = .; _end = .;
  wrs_kernel_bss_end = .; _wrs_kernel_bss_end = .;

}
```
其实从链接脚本的内容，可以大致猜出它指定告诉链接器的各种信息：

* 内核加载地址：0xa0000000
* 入口（起始代码）地址： ENTRY(kern\_entry)
* cpu机器类型：loongarch

其最主要的信息是告诉链接器各输入文件的各section应该怎么组合：应该从哪个地址开始放，各个section以什么顺序放，分别怎么对齐等等，最终组成输出文件的各section。除此之外，linker script还可以定义各种符号（如.text、.data、.bss等），形成最终生成的一堆符号的列表（符号表），每个符号包含了符号名字，符号所引用的内存地址，以及其他一些属性信息。符号实际上就是一个地址的符号表示，其本身不占用的程序运行的内存空间。

**链接地址/加载地址/虚地址/物理地址**

ucore 设定了ucore运行中的虚地址空间，具体设置可看lab2/kern/mm/memlayout.h 中描述的"Virtual memory map"图，可以了解虚地址和物理地址的对应关系。lab2/tools/kernel.ld描述的是执行代码的链接地址（link\_addr），比如内核起始地址是0x80000000，这是一个虚地址。所以我们可以认为链接地址等于虚地址。当内核开始执行时我们采用直接地址映射方式将虚拟地址映射到物理地址，其映射方式如下：

phy addr  = CSR.DMW0[31:29]  : virtual addr[28:0] 

即虚地址和物理地址之间有一个偏移。

**edata/end/text的含义**

在基于ELF执行文件格式的代码中，存在一些对代码和数据的表述，基本概念如下：

* BSS段（bss segment）：指用来存放程序中未初始化的全局变量的内存区域。BSS是英文Block
Started by Symbol的简称。BSS段属于静态内存分配。
* 数据段（data segment）：指用来存放程序中已初始化的全局变量的一块内存区域。数据段属于静态内存分配。
* 代码段（code segment/text segment）：指用来存放程序执行代码的一块内存区域。这部分区域的大小在程序运行前就已经确定，并且内存区域通常属于只读,某些架构也允许代码段为可写，即允许修改程序。在代码段中，也有可能包含一些只读的常数变量，例如字符串常量等。

在lab2/kern/init/init.c的kern\_init函数中，声明了外部全局变量：
```c
extern char edata[], end[];
```
但搜寻所有源码文件\*.[ch]，没有发现有这两个变量的定义。那这两个变量从哪里来的呢？其实在lab2/tools/kernel.ld中，可以看到如下内容：
```
…
.text : {
        *(.text .stub .text.* .gnu.linkonce.t.*)
}
…
    .data : {
        *(.data)
}
…
PROVIDE(edata = .);
…
    .bss : {
        *(.bss)
}
…
PROVIDE(end = .);
…
```
这里的“.”表示当前地址，“.text”表示代码段起始地址，“.data”也是一个地址，可以看出，它即代表了代码段的结束地址，也是数据段的起始地址。类推下去，“edata”表示数据段的结束地址，“.bss”表示数据段的结束地址和BSS段的起始地址，而“end”表示BSS段的结束地址。

这样回头看kerne\_init中的外部全局变量，可知edata[]和end[]这些变量是ld根据kernel.ld链接脚本生成的全局变量，表示相应段的起始地址或结束地址等，它们不在任何一个.S、.c或.h文件中定义。



