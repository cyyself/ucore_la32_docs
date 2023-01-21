## 设备层文件 IO 层 

在本实验中，为了统一地访问设备，我们可以把一个设备看成一个文件，通过访问文件的接口来访问设备。目前实现了stdin设备文件文件、stdout设备文件、disk0设备。stdin设备就是串口，stdout设备就是CONSOLE，而disk0设备是承载SFS文件系统的磁盘设备（尽管它是一个内存模拟的磁盘）。下面我们逐一分析ucore是如何让用户把设备看成文件来访问。

### 关键数据结构 

为了表示一个设备，需要有对应的数据结构，ucore为此定义了struct device，其描述如下：

```c
struct device {
    size_t d_blocks;    //设备占用的数据块个数            
    size_t d_blocksize;  //数据块的大小
    int (*d_open)(struct device *dev, uint32_t open_flags);  //打开设备的函数指针
    int (*d_close)(struct device *dev); //关闭设备的函数指针
    int (*d_io)(struct device *dev, struct iobuf *iob, bool write); //读写设备的函数指针
    int (*d_ioctl)(struct device *dev, int op, void *data); //用ioctl方式控制设备的函数指针
};
```

这个数据结构能够支持对块设备（比如磁盘）、字符设备（比如串口）的表示，完成对设备的基本操作。ucore虚拟文件系统为了把这些设备链接在一起，还定义了一个设备链表，即双向链表vdev\_list，这样通过访问此链表，可以找到ucore能够访问的所有设备文件。

但这个设备描述没有与文件系统以及表示一个文件的inode数据结构建立关系，为此，还需要另外一个数据结构把device和inode联通起来，这就是vfs\_dev\_t数据结构：

```c
// device info entry in vdev_list 
typedef struct {
    const char *devname;
    struct inode *devnode;
    struct fs *fs;
    bool mountable;
    list_entry_t vdev_link;
} vfs_dev_t;
```

利用vfs\_dev\_t数据结构，就可以让文件系统通过一个链接vfs\_dev\_t结构的双向链表找到device对应的inode数据结构，一个inode节点的成员变量in\_type的值是0x1234，则此 inode的成员变量in\_info将成为一个device结构。这样inode就和一个设备建立了联系，这个inode就是一个设备文件。

### stdout设备文件

**初始化**

既然stdout设备是设备文件系统的文件，自然有自己的inode结构。在系统初始化时，即只需如下处理过程

```
kern_init-->fs_init-->dev_init-->dev_init_stdout --> dev_create_inode
                 --> stdout_device_init
                 --> vfs_add_dev
```

在dev\_init\_stdout中完成了对stdout设备文件的初始化。即首先创建了一个inode，然后通过stdout\_device\_init完成对inode中的成员变量inode-\>\_\_device\_info进行初始：

这里的stdout设备文件实际上就是指的console外设（它其实是串口、并口和CGA的组合型外设）。这个设备文件是一个只写设备，如果读这个设备，就会出错。接下来我们看看stdout设备的相关处理过程。

**初始化**

stdout设备文件的初始化过程主要由stdout\_device\_init完成，其具体实现如下：

```c
static void
stdout_device_init(struct device *dev) {
    dev->d_blocks = 0;
    dev->d_blocksize = 1;
    dev->d_open = stdout_open;
    dev->d_close = stdout_close;
    dev->d_io = stdout_io;
    dev->d_ioctl = stdout_ioctl;
}
```

可以看到，stdout\_open函数完成设备文件打开工作，如果发现用户进程调用open函数的参数flags不是只写（O\_WRONLY），则会报错。

**访问操作实现**

stdout\_io函数完成设备的写操作工作，具体实现如下：

```c
static int
stdout_io(struct device *dev, struct iobuf *iob, bool write) {
    if (write) {
        char *data = iob->io_base;
        for (; iob->io_resid != 0; iob->io_resid --) {
            kputchar(*data ++);
        }
        return 0;
    }
    return -E_INVAL;
}
```

可以看到，要写的数据放在iob-\>io\_base所指的内存区域，一直写到iob-\>io\_resid的值为0为止。每次写操作都是通过cputchar来完成的，此函数最终将通过console外设驱动来完成把数据输出到串口、并口和CGA显示器上过程。另外，也可以注意到，如果用户想执行读操作，则stdout\_io函数直接返回错误值**-**E\_INVAL。

### stdin 设备文件 

这里的stdin设备文件实际上就是指的串口输入。这个设备文件是一个只读设备，如果写这个设备，就会出错。接下来我们看看stdin设备的相关处理过程。

**初始化**

stdin设备文件的初始化过程主要由stdin\_device\_init完成了主要的初始化工作，具体实现如下：

```c
static void
stdin_device_init(struct device *dev) {
    dev->d_blocks = 0;
    dev->d_blocksize = 1;
    dev->d_open = stdin_open;
    dev->d_close = stdin_close;
    dev->d_io = stdin_io;
    dev->d_ioctl = stdin_ioctl;

    p_rpos = p_wpos = 0;
    wait_queue_init(wait_queue);
}
```

相对于stdout的初始化过程，stdin的初始化相对复杂一些，多了一个stdin\_buffer缓冲区，描述缓冲区读写位置的变量p\_rpos、p\_wpos以及用于等待缓冲区的等待队列wait\_queue。在stdin\_device\_init函数的初始化中，也完成了对p\_rpos、p\_wpos和wait\_queue的初始化。

**访问操作实现**

stdin\_io函数负责完成设备的读操作工作，具体实现如下：

```c
static int
stdin_io(struct device *dev, struct iobuf *iob, bool write) {
    if (!write) {
        int ret;
        if ((ret = dev_stdin_read(iob->io_base, iob->io_resid)) > 0) {
            iob->io_resid -= ret;
        }
        return ret;
    }
    return -E_INVAL;
}
```

可以看到，如果是写操作，则stdin\_io函数直接报错返回。所以这也进一步说明了此设备文件是只读文件。如果此读操作，则此函数进一步调用dev\_stdin\_read函数完成对串口设备的读入操作。dev\_stdin\_read函数的实现相对复杂一些，主要的流程如下：

```c
static int
dev_stdin_read(char *buf, size_t len) {
    int ret = 0;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        for (; ret < len; ret ++, p_rpos ++) {
        try_again:
            if (p_rpos < p_wpos) {
                *buf ++ = stdin_buffer[p_rpos % stdin_BUFSIZE];
            }
            else {
                wait_t __wait, *wait = &__wait;
                wait_current_set(wait_queue, wait, WT_KBD);
                local_intr_restore(intr_flag);

                schedule();

                local_intr_save(intr_flag);
                wait_current_del(wait_queue, wait);
                if (wait->wakeup_flags == WT_KBD) {
                    goto try_again;
                }
                break;
            }
        }
    }
    local_intr_restore(intr_flag);
    return ret;
}
```

在上述函数中可以看出，如果p\_rpos < p\_wpos，则表示有串口输入的新字符在stdin\_buffer中，于是就从stdin\_buffer中取出新字符放到iobuf指向的缓冲区中；如果p\_rpos \>=p\_wpos，则表明没有新字符，这样调用read用户态库函数的用户进程就需要采用等待队列的睡眠操作进入睡眠状态，等待串口输入字符的产生。

串口输入字符后，如何唤醒等待串口输入的用户进程呢？回顾lab1中的外设中断处理，可以了解到，当用户在QEMU程序中输入字符时，会产生串口中断，在trap\_dispatch函数中，当识别出中断是串口中断时，会调用dev\_stdin\_write函数，来把字符写入到stdin\_buffer中，且会通过等待队列的唤醒操作唤醒正在等待串口输入的用户进程。
