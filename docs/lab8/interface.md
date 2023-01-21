### 通用文件系统访问接口

**文件和目录相关用户库函数**

Lab8中部分用户库函数与文件系统有关，我们先讨论对单个文件进行操作的系统调用，然后讨论对目录和文件系统进行操作的系统调用。

在文件操作方面，最基本的相关函数是open、close、read、write。在读写一个文件之前，首先要用open系统调用将其打开。open的第一个参数指定文件的路径名，可使用绝对路径名；第二个参数指定打开的方式，可设置为O\_RDONLY、O\_WRONLY、O\_RDWR，分别表示只读、只写、可读可写。在打开一个文件后，就可以使用它返回的文件描述符fd对文件进行相关操作。在使用完一个文件后，还要用close系统调用把它关闭，其参数就是文件描述符fd。这样它的文件描述符就可以空出来，给别的文件使用。

读写文件内容的系统调用是read和write。read系统调用有三个参数：一个指定所操作的文件描述符，一个指定读取数据的存放地址，最后一个指定读多少个字节。在C程序中调用该系统调用的方法如下：

```
count = read(filehandle, buffer, nbytes);
```

该系统调用会把实际读到的字节数返回给count变量。在正常情形下这个值与nbytes相等，但有时可能会小一些。例如，在读文件时碰上了文件结束符，从而提前结束此次读操作。

如果由于参数无效或磁盘访问错误等原因，使得此次系统调用无法完成，则count被置为-1。而write函数的参数与之完全相同。

对于目录而言，最常用的操作是跳转到某个目录，这里对应的用户库函数是chdir。然后就需要读目录的内容了，即列出目录中的文件或目录名，这在处理上与读文件类似，即需要通过opendir函数打开目录，通过readdir来获取目录中的文件信息，读完后还需通过closedir函数来关闭目录。由于在ucore中把目录看成是一个特殊的文件，所以opendir和closedir实际上就是调用与文件相关的open和close函数。只有readdir需要调用获取目录内容的特殊系统调用sys\_getdirentry。而且这里没有写目录这一操作。在目录中增加内容其实就是在此目录中创建文件，需要用到创建文件的函数。

**文件和目录访问相关系统调用**

与文件相关的open、close、read、write用户库函数对应的是sys\_open、sys\_close、sys\_read、sys\_write四个系统调用接口。与目录相关的readdir用户库函数对应的是sys\_getdirentry系统调用。这些系统调用函数接口将通过syscall函数来获得ucore的内核服务。当到了ucore内核后，在调用文件系统抽象层的file接口和dir接口。

### 文件操作实现 

#### 打开文件 

有了上述分析后，我们可以看看如果一个用户进程打开文件会做哪些事情？首先假定用户进程需要打开的文件已经存在在硬盘上。以user/sfs\_filetest1.c为例，首先用户进程会调用在main函数中的如下语句：

```
int fd1 = safe_open("sfs\_filetest1", O_RDONLY);
```

从字面上可以看出，如果ucore能够正常查找到这个文件，就会返回一个代表文件的文件描述符fd1，这样在接下来的读写文件过程中，就直接用这样fd1来代表就可以了。那这个打开文件的过程是如何一步一步实现的呢？

**通用文件访问接口层的处理流程**

首先进入通用文件访问接口层的处理流程，即进一步调用如下用户态函数： open-\>sys\_open-\>syscall，从而引起系统调用进入到内核态。到了内核态后，通过中断处理例程，会调用到sys\_open内核函数，并进一步调用sysfile\_open内核函数。到了这里，需要把位于用户空间的字符串"sfs\_filetest1"拷贝到内核空间中的字符串path中，并进入到文件系统抽象层的处理流程完成进一步的打开文件操作中。

**文件系统抽象层的处理流程**

1. 分配一个空闲的file数据结构变量file在文件系统抽象层的处理中，首先调用的是file\_open函数，它要给这个即将打开的文件分配一个file数据结构的变量，这个变量其实是当前进程的打开文件数组current-\>fs\_struct-\>filemap[]中的一个空闲元素（即还没用于一个打开的文件），而这个元素的索引值就是最终要返回到用户进程并赋值给变量fd1。到了这一步还仅仅是给当前用户进程分配了一个file数据结构的变量，还没有找到对应的文件索引节点。

为此需要进一步调用vfs\_open函数来找到path指出的文件所对应的基于inode数据结构的VFS索引节点node。vfs\_open函数需要完成两件事情：通过vfs\_lookup找到path对应文件的inode；调用vop\_open函数打开文件。

2. 找到文件设备的根目录“/”的索引节点需要注意，这里的vfs\_lookup函数是一个针对目录的操作函数，它会调用vop\_lookup函数来找到SFS文件系统中的“/”目录下的“sfs\_filetest1”文件。为此，vfs\_lookup函数首先调用get\_device函数，并进一步调用vfs\_get\_bootfs函数（其实调用了）来找到根目录“/”对应的inode。这个inode就是位于vfs.c中的inode变量bootfs\_node。这个变量在init\_main函数（位于kern/process/proc.c）执行时获得了赋值。

3. 通过调用vop\_lookup函数来查找到根目录“/”下对应文件sfs\_filetest1的索引节点，，如果找到就返回此索引节点。

4. 把file和node建立联系。完成第3步后，将返回到file\_open函数中，通过执行语句“file-\>node=node;”，就把当前进程的current-\>fs\_struct-\>filemap[fd]（即file所指变量）的成员变量node指针指向了代表sfs\_filetest1文件的索引节点inode。这时返回fd。经过重重回退，通过系统调用返回，用户态的syscall-\>sys\_open-\>open-\>safe\_open等用户函数的层层函数返回，最终把把fd赋值给fd1。自此完成了打开文件操作。但这里我们还没有分析第2和第3步是如何进一步调用SFS文件系统提供的函数找位于SFS文件系统上的sfs\_filetest1文件所对应的sfs磁盘inode的过程。下面需要进一步对此进行分析。

**SFS文件系统层的处理流程**

这里需要分析文件系统抽象层中没有彻底分析的vop\_lookup函数到底做了啥。下面我们来看看。在sfs\_inode.c中的sfs\_node\_dirops变量定义了“.vop\_lookup = sfs\_lookup”，所以我们重点分析sfs\_lookup的实现。注意：在lab8中，为简化代码，sfs\_lookup函数中并没有实现能够对多级目录进行查找的控制逻辑（在ucore_plus中有实现）。

sfs\_lookup有三个参数：node，path，node\_store。其中node是根目录“/”所对应的inode节点；path是文件sfs\_filetest1的绝对路径/sfs\_filetest1，而node\_store是经过查找获得的sfs\_filetest1所对应的inode节点。

sfs\_lookup函数以“/”为分割符，从左至右逐一分解path获得各个子目录和最终文件对应的inode节点。在本例中是调用sfs\_lookup\_once查找以根目录下的文件sfs\_filetest1所对应的inode节点。当无法分解path后，就意味着找到了sfs\_filetest1对应的inode节点，就可顺利返回了。

当然这里讲得还比较简单，sfs\_lookup\_once将调用sfs\_dirent\_search\_nolock函数来查找与路径名匹配的目录项，如果找到目录项，则根据目录项中记录的inode所处的数据块索引值找到路径名对应的SFS磁盘inode，并读入SFS磁盘inode对的内容，创建SFS内存inode。

#### 读文件

读文件其实就是读出目录中的目录项，首先假定文件在磁盘上且已经打开。用户进程有如下语句：

```
read(fd, data, len);
```

即读取fd对应文件，读取长度为len，存入data中。下面来分析一下读文件的实现。

**通用文件访问接口层的处理流程**

先进入通用文件访问接口层的处理流程，即进一步调用如下用户态函数：read-\>sys\_read-\>syscall，从而引起系统调用进入到内核态。到了内核态以后，通过中断处理例程，会调用到sys\_read内核函数，并进一步调用sysfile\_read内核函数，进入到文件系统抽象层处理流程完成进一步读文件的操作。

**文件系统抽象层的处理流程**

1) 检查错误，即检查读取长度是否为0和文件是否可读。

2) 分配buffer空间，即调用kmalloc函数分配4096字节的buffer空间。

3) 读文件过程

[1] 实际读文件

循环读取文件，每次读取buffer大小。每次循环中，先检查剩余部分大小，若其小于4096字节，则只读取剩余部分的大小。然后调用file\_read函数（详细分析见后）将文件内容读取到buffer中，alen为实际大小。调用copy\_to\_user函数将读到的内容拷贝到用户的内存空间中，调整各变量以进行下一次循环读取，直至指定长度读取完成。最后函数调用层层返回至用户程序，用户程序收到了读到的文件内容。

[2] file\_read函数

这个函数是读文件的核心函数。函数有4个参数，fd是文件描述符，base是缓存的基地址，len是要读取的长度，copied\_store存放实际读取的长度。函数首先调用fd2file函数找到对应的file结构，并检查是否可读。调用filemap\_acquire函数使打开这个文件的计数加1。调用vop\_read函数将文件内容读到iob中（详细分析见后）。调整文件指针偏移量pos的值，使其向后移动实际读到的字节数iobuf\_used(iob)。最后调用filemap\_release函数使打开这个文件的计数减1，若打开计数为0，则释放file。

**SFS文件系统层的处理流程**

vop\_read函数实际上是对sfs\_read的包装。在sfs\_inode.c中sfs\_node\_fileops变量定义了.vop\_read = sfs\_read，所以下面来分析sfs\_read函数的实现。

sfs\_read函数调用sfs\_io函数。它有三个参数，node是对应文件的inode，iob是缓存，write表示是读还是写的布尔值（0表示读，1表示写），这里是0。函数先找到inode对应sfs和sin，然后调用sfs\_io\_nolock函数进行读取文件操作，最后调用iobuf\_skip函数调整iobuf的指针。

在sfs\_io\_nolock函数中，先计算一些辅助变量，并处理一些特殊情况（比如越界），然后有sfs\_buf\_op = sfs\_rbuf,sfs\_block\_op = sfs\_rblock，设置读取的函数操作。接着进行实际操作，先处理起始的没有对齐到块的部分，再以块为单位循环处理中间的部分，最后处理末尾剩余的部分。每部分中都调用sfs\_bmap\_load\_nolock函数得到blkno对应的inode编号，并调用sfs\_rbuf或sfs\_rblock函数读取数据（中间部分调用sfs\_rblock，起始和末尾部分调用sfs\_rbuf），调整相关变量。完成后如果offset + alen \> din-\>fileinfo.size（写文件时会出现这种情况，读文件时不会出现这种情况，alen为实际读写的长度），则调整文件大小为offset + alen并设置dirty变量。

sfs\_bmap\_load\_nolock函数将对应sfs\_inode的第index个索引指向的block的索引值取出存到相应的指针指向的单元（ino\_store）。它调用sfs\_bmap\_get\_nolock来完成相应的操作。sfs\_rbuf和sfs\_rblock函数最终都调用sfs\_rwblock\_nolock函数完成操作，而sfs\_rwblock\_nolock函数调用dop\_io-\>disk0\_io-\>disk0\_read\_blks\_nolock-\>ide\_read\_secs完成对磁盘的操作。
