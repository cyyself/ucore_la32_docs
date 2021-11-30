
##### 实验中可能使用的软件

**编辑器**

这里我们推荐使用Visual Studio Code作为编辑器，原因是它可以很方便地使用Docker插件方便我们对LoongArch32的运行环境进行操作。

**git**

在本次实验中，我们采用Git作为版本控制工具，这样我们可以很方便地将一个实验的代码合并到后续实验。

进入实验文件夹后，我们可以采用`git branch`查看当前所处的实验。

这里我们推荐同学们安装`zsh`，并安装`oh-my-zsh`，并使用它自带的Git插件，这样在我们终端进入一个文件夹时可以直接显示目前所处的git branch，并告知是否有还未commit的修改，在开发上非常便利。

**diff & patch**

diff 为 Linux 命令，用于比较文本或者文件夹差异，可以通过 man 来查询其功能以及参数的使用。使用 patch 命令可以对文件或者文件夹应用修改。

例如实验中可能会在 proj_b 中应用前一个实验proj_a 中对文件进行的修改，可以使用如下命令：

	diff -r -u -P proj_a_original proj_a_mine > diff.patch
	cd proj_b
	patch -p1 -u < ../diff.patch

注意：proj_a_original 指 proj_a 的源文件，即未经修改的源码包，proj_a_mine 是修改后的代码包。第一条命令是递归的比较文件夹差异，并将结果重定向输出到 diff.patch 文件中；第三条命令是将 proj_a 的修改应用到 proj_b 文件夹中的代码中。

提示：习惯GUI方式的同学，可采用图形界面的meld、kdiff3、UltraCompare等软件。
