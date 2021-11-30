### 项目组成 

**编译执行**

编译并运行代码的命令如下：

```
make
make qemu
```

则可以得到如下的显示内容（仅供参考，不是标准答案输出）
```
(THU.CST) os is loading ...

Special kernel symbols:
  entry  0xc010002a (phys)
  etext  0xc010a708 (phys)
  edata  0xc0127ae0 (phys)
  end    0xc012ad58 (phys)

...

++ setup timer interrupts
this initproc, pid = 1, name = "init"
To U: "Hello world!!".
To U: "en.., Bye, Bye. :)"
kernel panic at kern/process/proc.c:354:
    process exit!!.

Welcome to the kernel debug monitor!!
Type 'help' for a list of commands.
K> qemu: terminating on signal 2
```
