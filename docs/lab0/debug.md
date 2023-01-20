## 程序调试

我们已经给了一个简单的裸机程序的例子，但我们在后续的OS实验中往往会遇到需要调试的程序，因此

### 在程序编译时增加调试信息

为了方便调试，我们往往需要在编译时关闭编译优化并让编译器输出调试信息，需要对Makefile进行以下修改：

1. 调用GCC关闭编译优化，去除我们已经写的`-O3`
2. 调用GCC添加`-g`参数增加调试信息

最终，我们需要对Makefile进行以下修改：

```diff
10c10
<       $(CC) -nostdlib -T lab0.ld start.S main.c -g -o $@
---
>       $(CC) -nostdlib -T lab0.ld start.S main.c -O3 -o $@
```

然后，我们使用`make clean`，然后`make`完成编译。

### QEMU开启GDB端口

不同于我们以往使用GDB直接attach到某一个进程或直接通过gdb打开某个程序并运行，对于QEMU中的裸机程序调试，我们需要让GDB调试器与QEMU进行通信。而GDB也定义了[GDB Remote Serial Protocol](https://ftp.gnu.org/old-gnu/Manuals/gdb/html_node/gdb_129.html)，QEMU也同样支持，并通过TCP Socket的方式与GDB交互。

我们在QEMU中可以使用`-s`参数，该参数等价于`-gdb tcp::1234`，将GDB Remote Serial Protocol监听在TCP 1234端口。

此外，QEMU监听了该端口后，我们仅仅拥有了GDB直接连接某个进程的能力，但我们的操作系统运行起来后可能已经跑过了我们所需要调试的地方，因此我们还可以对QEMU使用`-S`参数，使QEMU启动时不立刻运行程序。

综上所述，我们需要对QEMU添加以下两个参数：

- `-S`
	在启动时不立刻启动CPU

- `-s`
	相当于-gdb tcp::1234，将gdbserver监听到本地的1234端口。

我们可以在编译好的ucore目录中直接使用以下命令启动QEMU：

```shell
qemu-system-loongarch32 -M ls3a5k32 -m 32m -kernel start.elf -nographic -S -s
```

### GDB的使用

我们需要再新建另一个终端，完成gdb的操作。（这一步大家根据大家习惯使用的终端不同可以有不同的做法，例如直接在终端里新建窗口，或者在VSCode里的新建一个Terminal，或者使用screen/tmux等工具）。

在新建的中断中，首先进入到我们的lab0文件夹，然后使用一下命令运行`gdb`，并打开我们的裸机程序`：

```shell
loongarch32r-linux-gnusf-gdb start.elf
```

然后，我们使用以下命令连接到QEMU：

```shell
target remote 127.0.0.1:1234
```

其中，命令可以被简写为：

```shell
tar rem :1234
```

连接到GDB之后，我们就可以使用正常调试程序同样的步骤调试我们的裸机程序了。如果没有连接上遇到了报错请确保QEMU已启动且仅启动了一个。

同学们可以尝试在GDB控制台中使用以下命令：

- layout [src/asm/split]

    改变gdb的布局，src指代码，asm指反汇编，split会同时显示两者

- breakpoint [target]

    可以简写为`b`

    target可以为符号名（函数名）/代码文件:行号等。

    例如，想要在`uart_put_c`函数添加断点，可以使用以下命令：

    ```shell
    b uart_put_c
    ```

    如果想要在main.c的第10行添加断点，可以使用以下命令：

    ```shell
    b main.c:10
    ```

    如果想要在PC（程序计数器） `0xa0000004`处添加断点，可以使用以下命令：

    ```shell
    b *0xa0000004
    ```

- info break

    查询所有调用栈

- info registers

    查询所有寄存器状态

- continue

    可以简写为`c`

    继续执行程序。
    
    对于QEMU调试而言，默认处于暂停状态，需要在我们设置好断点后使用`c`让QEMU开始运行我们的裸机程序。

- backtrace

    可以简写为`bt`

    查看当前的调用栈，观测函数调用的情况。

- next

    可以简写为`n`

    单步执行当前程序，不进入函数。

- step

    可以简写为`s`

    单步执行调试程序，遇到函数时进入函数。

- stepi

    可以简写为`si`

    单步执行一条汇编指令。

- print [expr]

    可以简写为`p`

    [expr]部分可以替换为任意表达式。但gdb中能够支持的表达式有限。

    例如我们程序执行到了`uart_put_c`函数，我们若想查看传入的`char c`参数的值，可以使用以下命令：

    ```shell
    p c
    ```

    如果我们想要查看c的十六进制值，可以使用以下命令：

    ```shell
    p/x c
    ```

    如果我们想要查看内存地址`0xa0000129`处的char字符，可以使用以下命令：

    ```shell
    p *(char*)0xa0000129
    ```

- display [expr]

    可以简写为`disp`

    和print作用类似，但print只打印一次，disp则是在每次gdb调试时进行打印。


除此之外，gdb还有非常多的命令与使用技巧，这一部分留给同学们自行上网查找相关资料并学习。

### .gdbinit

每次我们打开gdb时都使用target remote 127.0.0.1:1234并修改layout非常麻烦，有没有什么方便的方式呢？

答案是有的，那就是编写一个gdbinit脚本。

我们可以编写以下内容保存到lab0文件夹下的`.gdbinit`文件中：

```
target remote 127.0.0.1:1234
layout split
```

!!! warning

    Linux下`.`开头的文件默认为隐藏文件，直接使用`ls`命令并不会出现，需要使用`ls -a`查看。

然后再次启动`loongarch32r-linux-gnusf-gdb start.elf`，此时也许会告诉我们一个错误提示，这是gdb基于安全考虑。如果我们保证gdb运行的文件夹下`.gdbinit`均是可以信任的，可以先退出gdb（通过在gdb控制台执行`exit`），然后在shell中使用以下命令设置安全加载路径为所有路径（设置为`/`）：

```shell
echo "set auto-load safe-path /" > ~/.gdbinit
```

然后再次启动`loongarch32r-linux-gnusf-gdb start.elf`，如果QEMU已经开启并已使用-s参数监听GDB RSP在1234端口，此时应该就能够自动连上QEMU了。

!!! info

    Tips: 当你多次调试程序同一个位置，意味着你要多次使用相同的断点时，也可以将断点的b [target]命令写在.gdbinit中，这样就不必每次重新设置断点。