### 项目组成

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

通过上图，我们可以看到ucore在显示其entry（入口地址）、etext（代码段截止处地址）、edata（数据段截止处地址）、和end（ucore截止处地址）的值后，探测出计算机系统中的物理内存的布局。然后会显示内存范围和空闲内存的起始地址，显示可以分为多少个page。接下来ucore会以页为最小分配单位实现一个简单的内存分配管理，完成二级页表的建立，进入分页模式，执行各种我们设置的检查，最后响应时钟中断。
