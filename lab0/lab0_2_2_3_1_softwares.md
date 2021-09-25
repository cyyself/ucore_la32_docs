
##### 实验中可能使用的软件

***编辑器***

这里我们推荐使用Visual Studio Code作为编辑器，原因是它可以很方便地使用Docker插件方便我们对LoongArch32的运行环境进行操作。

***exuberant-ctags***
exuberant-ctags 可以为程序语言对象生成索引，其结果能够被一个文本编辑器或者其他工具简捷迅速的定位。支持的编辑器有 Vim、Emacs 等。
实验中，可以使用命令：

	ctags -h=.h.c.S -R
默认的生成文件为 tags (可以通过 -f 来指定)，在相同路径下使用 Vim 可以使用改索引文件，例如:

	使用 “ctrl + ]” 可以跳转到相应的声明或者定义处，使用 “ctrl + t” 返回（查询堆栈）等。

提示：习惯GUI方式的同学，可采用图形界面的understand、source insight等软件。
***diff & patch***

diff 为 Linux 命令，用于比较文本或者文件夹差异，可以通过 man 来查询其功能以及参数的使用。使用 patch 命令可以对文件或者文件夹应用修改。

例如实验中可能会在 proj_b 中应用前一个实验proj_a 中对文件进行的修改，可以使用如下命令：

	diff -r -u -P proj_a_original proj_a_mine > diff.patch
	cd proj_b
	patch -p1 -u < ../diff.patch

注意：proj_a_original 指 proj_a 的源文件，即未经修改的源码包，proj_a_mine 是修改后的代码包。第一条命令是递归的比较文件夹差异，并将结果重定向输出到 diff.patch 文件中；第三条命令是将 proj_a 的修改应用到 proj_b 文件夹中的代码中。

提示：习惯GUI方式的同学，可采用图形界面的meld、kdiff3、UltraCompare等软件。
