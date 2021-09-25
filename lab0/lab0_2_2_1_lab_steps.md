
#### 开发OS lab实验的简单步骤

1. 使用git checkout 进入不同的实验分支，一共有8个实验，使用git checkout lab1可以进入实验一，若已有更改需要先进行git commit或加上-f参数放弃更改
2. 使用代码编辑器填写对应的代码，然后使用make qemu运行。如果需要调试可以打开两个终端窗口，一个窗口执行make debug，另一个窗口执行make gdb。也欢迎寻找自己合适的工具使用，如tmux与screen。
3. 观察实验结果。