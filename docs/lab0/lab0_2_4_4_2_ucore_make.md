##### ucore 代码编译

编译过程：在解压缩后的 ucore 源码包中使用 make 命令即可。例如如果要运行位于`sys_code`中我们已经完成的代码：
```
	chy@laptop: ~/sys_code$  make qemu -j 16
```
在sys_code目录下的obj目录中，生成了最终目标文件：
 - ucore-kernel-initrd：包含磁盘部分的Kernel的文件

还生成了其他很多文件，这里就不一一列举了。

注意，这里的-j 16指的是编译时最多开启16线程，这里推荐将16修改为你使用的电脑CPU的逻辑线程数。

