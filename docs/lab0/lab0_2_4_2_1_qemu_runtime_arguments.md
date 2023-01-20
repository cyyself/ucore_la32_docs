
##### 运行参数

在提供的Docker中，在命令行中可以直接使用 qemu-system-loongson32 命令运行程序。qemu 运行可以有多参数，格式如：

	qemu-system-loongson32 [options]

部分参数说明：

- `-m ls3a5k32`

	模拟ls3a5k32机器

- `-monitor tcp::4288,server,nowait`

	将monitor监听在tcp4288端口，这样我们可以通过nc来连接

- `-serial stdio`

	将模拟的硬件串口连接到stdio（标准输入输出），这样我们可以直接在命令行与QEMU虚拟机内的串口进行交互

- `-m 256`

	设置内存256M

- `-nographic`

	禁止使用图形输出，方便终端调试。

- `-kernel obj/ucore-kernel-initrd`

	指定QEMU运行时载入obj/ucore-kernel-initrd的内核

- `-S`

	在启动时不立刻启动CPU

- `-s`

	相当于-gdb tcp::1234，将gdbserver监听到本地的1234端口。

例如，如果只是要简单地运行qemu，可以输入：

	qemu-system-loongson32 -kernel obj/ucore-kernel-initrd -M ls3a5k32 -m 256 -nographic

注意：没有指定-monitor参数的情况下可以使用`Ctrl`+`A`进入monitor。若在这种情况需要退出QEMU，无法直接使用`Ctrl`+`C`，需要先`Ctrl`+`A`然后按`X`。

