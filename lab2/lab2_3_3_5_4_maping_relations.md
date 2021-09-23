### 系统执行中地址映射的过程（大改，待检查）
在lab1和lab2中都会涉及如何建立映射关系的操作，在龙芯架构中MMU支持两种地址翻译模式：直接地址翻译模式和映射地址翻译模式。直接地址翻译模式下物理地址默认直接等于虚拟地址的[PALEN-1:0]位（不足补0）。当处理器核的MMU处于映射地址翻译模式，具体又分为直接映射地址翻译模式和页表映射地址翻译模式。直接映射地址模式是通过直接映射配置窗口机制完成虚实地址的直接映射，映射地址翻译模式通过页表完成映射。

在lab1和lab2中我们在ucore的入口函数kernel_entry（entry.S文件中）中设置了CSR.CRMD的DA=0且PG=1，即处理器核的MMU处于映射地址翻译模式。同时，我们将CSR.DWM0寄存器的值设置为0xa0000001，表示 0xa0000000-0xbfffffff段的虚拟地址通过直接映射地址翻译模式映射到0x00000000-0x1fffffff的物理地址。将CSR.DWM1寄存器的值设置为0x80000011，表示0x80000000-0x9fffffff段的虚拟地址用过直接映射地址翻译模式映射到0x00000000-0x1fffffff的物理地址。除了这两段虚拟地址之外的虚拟地址都是通过页表映射地址翻译模式进行映射。

下面，我们来看看这是如何一步一步实现地址映射的。观察一下链接脚本，即tools/kernel.ld文件：
```
OUTPUT_ARCH(loongarch)
ENTRY(kernel_entry)
SECTIONS
{
    . = 0x80000000;

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
```
从上述代码可以看出ld工具形成的ucore的起始虚拟地址从0x80000000开始，由于这个段的地址是直接映射地址段，所以其起始的物理地址为0x00000000，即

```
 phy addr  = CSR.DMW0[31:29]  : virtual addr[28:0] 
```

**第一个阶段**从kernel_entry函数开始到pmm_init函数执行之前，ucore采用直接映射地址方式进行地址翻译，翻译方式如上。注意，由于0x80000000-0x9fffffff和0xa0000000-0xbfffffff才能进行直接映射，所以内核的大小不能超过512M。

**第二个阶段**（创建初始页目录表，开启分页模式）从pmm_init函数被调用开始，在pmm_init函数中创建了boot_pgdir，初始化了页目录表，正式开始了页表映射地址翻译模式。

