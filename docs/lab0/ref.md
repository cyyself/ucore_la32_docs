# ucore实验中的常用工具

在ucore实验中，一些基本的常用工具如下：
  - 命令行shell: bash shell -- 有对文件和目录操作的各种命令，如ls、cd、rm、pwd...
  - 系统维护工具：apt、git
    - apt：安装管理各种软件，主要在debian, ubuntu linux系统中
    - git：开发软件的版本维护工具
  - 源码阅读与编辑工具：eclipse-CDT、understand、gedit、vim
    - Eclipse-CDT：基于Eclipse的C/C++集成开发环境、跨平台、丰富的分析理解代码的功能，可与qemu结合，联机源码级Debug uCore OS。
    - Understand：商业软件、跨平台、丰富的分析理解代码的功能，Windows上有类似的sourceinsight软件
    - gedit：Linux中的常用文本编辑，Windows上有类似的notepad
    - vim: Linux/unix中的传统编辑器，类似有emacs等，可通过exuberant-ctags、cscope等实现代码定位
  - 源码比较和打补丁工具：diff、meld，用于比较不同目录或不同文件的区别, patch是打补丁工具
    - diff, patch是命令行工具，使用简单
    - meld是图形界面的工具，功能相对直观和方便，类似的工具还有 kdiff3、diffmerge、P4merge
  - 开发编译调试工具：gcc 、gdb 、make
    - gcc：C语言编译器
    - gdb：执行程序调试器
    - ld：链接器
    - objdump：对ELF格式执行程序文件进行反编译、转换执行格式等操作的工具
    - nm：查看执行文件中的变量、函数的地址
    - readelf：分析ELF格式的执行程序文件
    - make：软件工程管理工具， make命令执行时，需要一个 makefile 文件，以告诉make命令如何去编译和链接程序
    - dd：读写数据到文件和设备中的工具
  - 硬件模拟器：qemu -- qemu可模拟多种CPU硬件环境，本实验中，用于模拟一台LoongArch32的计算机系统。
  - markdown文本格式的编写和阅读工具(比如阅读ucore_docs)
    - 编写工具 haroopad 
    - 阅读工具 gitbook


# 上述工具的使用方法在线信息
- apt-get
  - http://wiki.ubuntu.org.cn/Apt-get%E4%BD%BF%E7%94%A8%E6%8C%87%E5%8D%97
- git github
  - http://www.cnblogs.com/cspku/articles/Git_cmds.html
  - http://www.worldhello.net/gotgithub/index.html
- diff patch
  - http://www.ibm.com/developerworks/cn/linux/l-diffp/index.html
  - http://www.cnblogs.com/itech/archive/2009/08/19/1549729.html  
- gcc
  - http://wiki.ubuntu.org.cn/Gcchowto
  - http://wiki.ubuntu.org.cn/Compiling_Cpp
  - http://wiki.ubuntu.org.cn/C_Cpp_IDE
  - http://wiki.ubuntu.org.cn/C%E8%AF%AD%E8%A8%80%E7%AE%80%E8%A6%81%E8%AF%AD%E6%B3%95%E6%8C%87%E5%8D%97
- gdb
  - http://wiki.ubuntu.org.cn/%E7%94%A8GDB%E8%B0%83%E8%AF%95%E7%A8%8B%E5%BA%8F
- make & makefile
  - http://wiki.ubuntu.com.cn/index.php?title=%E8%B7%9F%E6%88%91%E4%B8%80%E8%B5%B7%E5%86%99Makefile&variant=zh-cn
  - http://blog.csdn.net/a_ran/article/details/43937041
- shell
   - http://wiki.ubuntu.org.cn/Shell%E7%BC%96%E7%A8%8B%E5%9F%BA%E7%A1%80
   - http://wiki.ubuntu.org.cn/%E9%AB%98%E7%BA%A7Bash%E8%84%9A%E6%9C%AC%E7%BC%96%E7%A8%8B%E6%8C%87%E5%8D%97
- understand
   - http://blog.csdn.net/qwang24/article/details/4064975
- vim
   - http://www.httpy.com/html/wangluobiancheng/Perljiaocheng/2014/0613/93894.html
   - http://wenku.baidu.com/view/4b004dd5360cba1aa811da77.html
- meld
   - https://linuxtoy.org/archives/meld-2.html
- qemu
   - http://wenku.baidu.com/view/04c0116aa45177232f60a2eb.html
- Eclipse-CDT
   - http://blog.csdn.net/anzhu_111/article/details/5946634  
- haroopad
   - http://pad.haroopress.com/
- gitbook
   - https://github.com/GitbookIO/gitbook  https://www.gitbook.com/

# 参考资料

> 一些资料信息来源于 http://pdos.csail.mit.edu/6.828/2014/reference.html

### UNIX general info
- [Youtube Unix intro](https://www.youtube.com/watch?v=tc4ROCJYbm0)
- [The UNIX Time-Sharing System](http://citeseer.ist.psu.edu/10962.html), Dennis M. Ritchie and Ken L.Thompson,. Bell System Technical Journal 57, number 6, part 2 (July-August 1978) pages 1905-1930. 
- [The Evolution of the Unix Time-sharing System](http://www.read.seas.harvard.edu/~kohler/class/aosref/ritchie84evolution.pdf), Dennis M. Ritchie, 1979.
- The C programming language (second edition) by Kernighan and Ritchie. Prentice Hall, Inc., 1988. ISBN 0-13-110362-8, 1998.

### building or reading a small OS
 - [How to make an Operating System](https://www.gitbook.com/book/samypesse/how-to-create-an-operating-system/details)
 - [xv6 book 中文](https://www.gitbook.com/book/th0ar/xv6-chinese/details)
 - [自己动手写操作系统](http://item.jd.com/10142246.html)于渊 著,电子工业出版社,2005
 - [Linux-0.11内核完全注释](http://oldlinux.org/download/clk011c-3.0-toc.pdf) 赵炯，2009
 - [oldlinux论坛](http://www.oldlinux.org/oldlinux/)
 - [osdev.org](http://wiki.osdev.org/Expanded_Main_Page)

### some OS course
 - [6.828: Operating Systems Engineering - in MIT](http://pdos.csail.mit.edu/6.828/2014/index.html)
 - [CS-537: Introduction to Operating Systems - in WISC](http://pages.cs.wisc.edu/~remzi/Classes/537/Fall2013/)
 
### 16550 UART Serial Port 
 - [PC16550D Universal Asynchronous Receiver/Transmitter with FIFOs](http://www.national.com/pf/PC/PC16550D.html), National Semiconductor, 1995.
 - [http://byterunner.com/16550.html](http://byterunner.com/16550.html), Byterunner Technologies.
 - [Interfacing the Serial / RS232 Port,](http://www.beyondlogic.org/serial/serial.htm), Craig Peacock, August 2001.
