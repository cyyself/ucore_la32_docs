### 编译方法

**Makefile修改**
在Makefile中取消LAB1	:= -DLAB1_EX4 -D_SHOW_100_TICKS -D_SHOW_SERIAL_INPUT(第6行)的注释
```
LAB1	:= -DLAB1_EX4 -D_SHOW_100_TICKS -D_SHOW_SERIAL_INPUT
# LAB2	:= -DLAB2_EX1 -DLAB2_EX2 -DLAB2_EX3
# LAB3	:= -DLAB3_EX1 -DLAB3_EX2
# LAB4	:= -DLAB4_EX1 -DLAB4_EX2
# LAB5	:= -DLAB5_EX1 -DLAB5_EX2
# LAB6	:= -DLAB6_EX2
# LAB7	:= -DLAB7_EX1 #-D_SHOW_PHI
# LAB8	:= -DLAB8_EX1 -DLAB8_EX2
```
-D_SHOW_100_TICKS选项可在终端每是毫秒打印一行"100 ticks"
-D_SHOW_SERIAL_INPUT选项会在终端打印键盘的输入
编译并运行代码的命令如下：
```bash
make

make qemu -j 16
```
补全代码后可以得到如下显示界面（仅供参考）
```bash
chenyu$ make qemu -j 16
(THU.CST) os is loading ...

Special kernel symbols:
  entry  0xA00000A0 (phys)
  etext 0xA001F000 (phys)
  edata 0xA0151820 (phys)
  end   0xA0154B00 (phys)
Kernel executable memory footprint: 1239KB
LAB1 Check - Please press your keyboard manually and see what happend.
100 ticks
100 ticks
100 ticks
100 ticks
100 ticks
100 ticks
100 ticks
got input 
100 ticks
got input s
got input d
got input g
100 ticks
got input s
got input g
100 ticks
```
