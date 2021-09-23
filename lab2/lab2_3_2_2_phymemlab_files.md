### 项目组成（有待解决问题）

表1： 实验二文件列表

```
bash
|-- kern
| |-- debug
| | |-- assert.h
| | |-- kdebug.h
| | |-- monior.h
| | |-- monitor.c
| | |-- panic.c
| |-- driver
| | |-- clock.c
| | |-- clock.h
| | |-- console.c
| | |-- console.h
| | |-- intr.c
| | |-- intr.h
| | |-- picirq.c
| | |-- picirq.h
| |-- init
| | |-- entry.S
| | |-- init.c
| |-- libs
| | |-- atomic.h
| | |-- list.h
| | |-- hash.c
| | |-- printfmt.c
| | |-- rand.c
| | |-- readline.c
| | |-- stdio.c
| | |-- stdio.h
| | |-- stdlib.h
| | |-- string.c
| | |-- string.h
| |-- inclde
| | |-- asm
| | | |-- loongisa+csr.h
| | | |-- redef.h
| | | |-- stackframe.h
| | |-- atomic.h
| | |-- defs.h
| | |-- dirent.h
| | |-- error.h
| | |-- glue_pgmap.h
| | |-- list.h
| | |-- loongarch_tlb.h
| | |-- loongarch.h
| | |-- stat.h
| | |-- stdarg.h
| | |-- unistd.h
| |-- mm
| | |-- default_pmm.c
| | |-- default_pmm.h
| | |-- memlayout.h
| | |-- mmu.h
| | |-- pmm.c
| | |-- pmm.h
| | |-- thumips_tlb.c
| |-- sync
| | |-- sync.h
| |-- trap
| | |-- trap.c
| | |-- exception.S
| | |-- trap.h
| | |-- vectors.S
| | |-- loongarch_trapframe.h
|-- tools
|-- kernel.ld
```

相对与实验一，实验二主要增加和修改的文件如上表所示。主要改动如下：

* kern/mm/default\_pmm.[ch]：提供基本的基于链表方法的物理内存管理（分配单位为页，即4096字节）；
* kern/mm/pmm.[ch]：pmm.h定义物理内存管理类框架struct
pmm\_manager，基于此通用框架可以实现不同的物理内存管理策略和算法(default\_pmm.[ch]
实现了一个基于此框架的简单物理内存管理策略)；
pmm.c包含了对此物理内存管理类框架的访问，以及与建立、修改、访问页表相关的各种函数实现。
* kern/sync/sync.h：为确保内存管理修改相关数据时不被中断打断，提供两个功能，一个是保存eflag寄存器中的中断屏蔽位信息并屏蔽中断的功能，另一个是根据保存的中断屏蔽位信息来使能中断的功能；（可不用细看）
* libs/list.h：定义了通用双向链表结构以及相关的查找、插入等基本操作，这是建立基于链表方法的物理内存管理（以及其他内核功能）的基础。其他有类似双向链表需求的内核功能模块可直接使用list.h中定义的函数。
* libs/atomic.h：定义了对一个变量进行读写的原子操作，确保相关操作不被中断打断。（可不用细看）

**编译方法**

编译并运行代码的命令如下：
```bash
make

make qemu
```
则可以得到如下显示界面（仅供参考）
```bash
chenyu$ make qemu
(THU.CST) os is loading ...

Special kernel symbols:
  entry  0x800000C4 (phys)
  etext 0x80011000 (phys)
  edata 0x80020F90 (phys)
  end   0x800215E0 (phys)
Kernel executable memory footprint: 66KB
memory management: default_pmm_manager
memory map:
    [80000000, 82000000]

freemem start at: 80062000
free pages: 00001F9E
## 00000020
check_alloc_page() succeeded!
check_pgdir() succeeded!
check_boot_pgdir() succeeded!
-------------------- BEGIN --------------------
--------------------- END ---------------------
100 ticks
100 ticks
100 ticks
……
```
[^待解决]: 二级页表内容为空

通过上图，我们可以看到ucore在显示其entry（入口地址）、etext（代码段截止处地址）、edata（数据段截止处地址）、和end（ucore截止处地址）的值后，探测出计算机系统中的物理内存的布局。然后会显示内存范围和空闲内存的起始地址，显示可以分为多少个page。接下来ucore会以页为最小分配单位实现一个简单的内存分配管理，完成二级页表的建立，进入分页模式，执行各种我们设置的检查，最后显示ucore建立好的二级页表内容，并在分页模式下响应时钟中断。
