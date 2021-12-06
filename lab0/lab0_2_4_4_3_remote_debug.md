##### 使用远程调试

为了与qemu配合进行源代码级别的调试，需要先让qemu进入等待gdb调试器的接入并且还不能让qemu中的CPU执行，因此启动qemu的时候，我们需要使用参数-S –s这两个参数来做到这一点。在使用了前面提到的参数启动qemu之后，qemu中的CPU并不会马上开始执行，这时我们启动gdb，然后在gdb命令行界面下，使用下面的命令连接到qemu：

	(gdb)  target remote 127.0.0.1:1234

然后输入c（也就是continue）命令之后，qemu会继续执行下去，但是gdb由于不知道任何符号信息，并且也没有下断点，是不能进行源码级的调试的。为了让gdb获知符号信息，需要指定调试目标文件，gdb中使用file命令：

	(gdb)  file ./bin/kernel

之后gdb就会载入这个文件中的符号信息了。

通过gdb可以对ucore代码进行调试，以lab0中调试memset函数为例：

(1)  运行 `qemu-system-loongson32 -kernel obj/ucore-kernel-initrd -M ls3a5k32 -m 256 -nographic -S -s`

(2)  运行 gdb并与qemu进行连接 `gdb obj/ucore-kernel-initrd`

(3)  设置断点并执行

(4)  qemu 单步调试。

运行过程以及结果如下：

<table>
<tr><td>窗口一</td><td>窗口二</td>
<tr>
<td>
<pre>
➜  ucore-loongarch32 git:(master) qemu-system-loongson32 -kernel obj/ucore-kernel-initrd -M ls3a5k32 -m 256 -nographic -S -s 
mips_ls3a7a_init: num_nodes 1
mips_ls3a7a_init: node 0 mem 0x10000000
*****zl 1, mask0
memory_offset = 0x78;
cpu_offset = 0xc88; system_offset = 0xce8;
irq_offset = 0x3058;
interface_offset = 0x30b8;
boot_params_buf is 
param len=0x89f0
env a8f00020
</pre>
</td>
<td>
<pre>
➜  ~ docker exec -it la32-env /bin/zsh
➜  ~ echo "set auto-load safe-path /" >> ~/.gdbinit
➜  ~ cd ucore-loongarch32
➜  ucore-loongarch32 git:(master) loongarch32-linux-gnu-gdb obj/ucore-kernel-initrd 
For help, type "help".
Type "apropos word" to search for commands related to "word"...
Reading symbols from obj/ucore-kernel-initrd...done.
0xa0000000 in wrs_kernel_text_start ()
(gdb) break memset
Breakpoint 1 at 0xa0001314: file kern/libs/string.c, line 277.
(gdb) c
Continuing.
Breakpoint 1, memset (s=0xa1ffc000, c=0 '\000', n=4096) at kern/libs/string.c:277
277	    char *p = s;
(gdb)
</pre>
</td>



