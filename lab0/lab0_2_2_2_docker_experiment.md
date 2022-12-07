
#### 通过Docker使用LoongArch32编译环境

为了方便大家的使用，减少不必要的环境配置中带来的奇怪问题的负担，我们将环境统一打包为了一个Docker容器，这样就免去了自己配置环境的麻烦。

考虑到近年来ARM处理器普及，有的同学可能会使用ARM架构处理器的电脑来完成实验，但我们提供的LoongArch32编译环境是针对x86-64架构的，因此需要使用qemu-user进行转译。

例如在Apple M1处理器的电脑上使用Debian/Ubuntu操作系统的虚拟机或者是使用树莓派完成实验，请先安装：

```
sudo apt install qemu-user qemu-user-static gcc-x86-64-linux-gnu binutils-x86-64-linux-gnu binutils-x86-64-linux-gnu-dbg build-essential
```


对于大家熟悉的x86-64架构上的Ubuntu系统，可以依次执行以下命令完成Docker的安装：

注意：其它Debian系发行版用户请正确将Ubuntu替换为你所使用的发行版，对于ARM处理器用户请将`amd64`替换为`arm64`（较老版本的树莓派为`armhf`）。

```shell
sudo apt-get install apt-transport-https ca-certificates curl gnupg2 software-properties-common
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
sudo add-apt-repository \
   "deb [arch=amd64] https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/debian \
   $(lsb_release -cs) \
   stable"
sudo apt-get update
sudo apt-get install docker-ce
```



在Docker安装完成后，推荐将当前用户加入Docker组中，方便我们进行后续操作：

```
sudo usermod -aG docker $USER
newgrp docker
# 注：在注销重新登录之前，所有的操作都需要先执行newgrp docker，推荐在这一步完成之后重启电脑
```

在Docker安装完成后，可以使用`docker pull chenyy/la32r-env`来导入我们打包完成的运行环境。

```shell
docker pull chenyy/la32r-env
```

之后，我们可以使用docker run开始运行我们的容器了，这里我们还做了一步额外的操作是挂载当前系统的用户相关文件以及用户主目录，这样可以在容器内直接使用当前用户的主目录：

```shell
docker run -it \
    --name la32-env \
    --user=$(id -u $USER):$(id -g $USER) \
    --net=host \
    --workdir="/home/$USER" \
    --volume="/home/$USER:/home/$USER" \
    --volume="/etc/group:/etc/group:ro" \
    --volume="/etc/passwd:/etc/passwd:ro" \
    --volume="/etc/shadow:/etc/shadow:ro" \
    --volume="/etc/sudoers.d:/etc/sudoers.d:ro" \
    chenyy/la32r-env
```

参数解释：
- --rm 运行后销毁
- --name 给容器命名
- --user 切换到指定的用户和用户组
- --net=host 与主机共享网络（默认采用Docker自带的NAT网卡，也就不可以直接用127.0.0.1连到容器）
- --env 设置环境变量
- --workdir 进入容器后的工作文件夹
- --volume 挂载到容器的文件夹


如果出现容器运行失败的情况，会导致容器出现残留，对于残留的容器我们可以使用`sudo docker ps -a`进行查看，若存在残留可以使用`docker rm ($容器id)`进行删除。

之后这就进入了我们提供的容器中，使用`cd`命令进入到ucore-loongarch32文件夹，然后输入`make qemu`可以观察操作系统运行情况，若运行成功则说明容器配置正确。

在Docker容器还在运行的时候，我们可以通过docker exec的方式继续启动一个该容器的终端，方便在容器内进行其它操作，使用命令`docker exec -it la32-env /bin/zsh`，其中`/bin/zsh`可以换成自己喜欢的Shell，如Bash。

而针对使用VSCode的同学，我们推荐可以直接安装VSCode的git插件，然后直接将VSCode挂到Docker容器中，操作如下：

![VSCode Docker](../lab0_figs/image003.png "VSCode attach Docker")