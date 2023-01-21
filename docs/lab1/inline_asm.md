## 内联汇编

我们在阅读Lab1的C代码时往往会看到`asm`关键字，这是一种内联汇编的写法，使得我们能够在C语言中直接操作汇编，以达成读写控制状态寄存器（CSR）、发起系统调用等C语言无法直接完成的操作。

这里对内联汇编进行简要介绍。

### GCC基本内联汇编

GCC 提供了两类内联汇编语句（inline asm statements）：基本内联汇编语句（basic inline asm statement)和扩展内联汇编语句（extended inline asm statement）。GCC基本内联汇编很简单，一般是按照下面的格式：

```c
asm("statements");
```

例如：

```c
asm("nop");
```
 
"asm" 和 "\_\_asm\_\_" 的含义是完全一样的。如果有多行汇编，则每一行都要加上 "\n\t"。其中的 “\n” 是换行符，"\t” 是 tab 符，在每条命令的 结束加这两个符号，是为了让 gcc 把内联汇编代码翻译成一般的汇编代码时能够保证换行和留有一定的空格。对于基本asm语句，GCC编译出来的汇编代码就是双引号里的内容。例如：

```c
asm( "li.w $t0, 1\n\t"
    "li.w $t1, 2\n\t"
    "addi.w $t0, $t1, $t2"
);
```
实际上gcc在处理汇编时，是要把asm(...)的内容"打印"到汇编文件中，所以格式控制字符是必要的。

在上面的例子中，由于我们在内联汇编中改变了 t0 和 t1 的值，但是由于 gcc 的特殊的处理方法，即先形成汇编文件，再交给 GAS 去汇编，所以 GAS 并不知道我们已经改变了 t0 和 t1 的值，如果程序的上下文需要 t0 或 t1 作其他内存单元或变量的暂存，就会产生没有预料的多次赋值，引起严重的后果。对于变量 _boo也存在一样的问题。为了解决这个问题，就要用到扩展 GCC 内联汇编语法。

参考：
- [GCC Manual， 版本为5.0.0 pre-release,6.43节（How to Use Inline Assembly Language in C Code）](https://gcc.gnu.org/onlinedocs/gcc.pdf)
- [GCC-Inline-Assembly-HOWTO](http://www.ibiblio.org/gferg/ldp/GCC-Inline-Assembly-HOWTO.html)

### GCC扩展内联汇编

使用GCC扩展内联汇编的例子如下：

```c
#define read_a0() ({ \
unsigned int __dummy; \
__asm__( \
    "move $a0, %0\n\t" \
    :"=r" (__dummy)); \
__dummy; \
})
```

它代表什么含义呢？这需要从其基本格式讲起。GCC扩展内联汇编的基本格式是：          

```c
asm [volatile] ( Assembler Template
   : Output Operands
   [ : Input Operands
   [ : Clobbers ] ])
```

其中，\_\_asm\_\_ 表示汇编代码的开始，其后可以跟 \_\_volatile\_\_（这是可选项），其含义是避免 “asm” 指令被删除、移动或组合，在执行代码时，如果不希望汇编语句被 gcc 优化而改变位置，就需要在 asm 符号后添加 volatile 关键词：asm volatile(...)；或者更详细地说明为：\_\_asm\_\_ \_\_volatile\_\_(...)；然后就是小括弧，括弧中的内容是具体的内联汇编指令代码。 "<asm routine>" 为汇编指令部分，例如，"movl %%cr0,%0\n\t"。数字前加前缀 “％“，如％1，％2等表示使用寄存器的样板操作数。可以使用的操作数总数取决于具体CPU中通用寄存器的数 量，如LoongArch32可以有32个。指令中有几个操作数，就说明有几个变量需要与寄存器结合，由gcc在编译时根据后面输出部分和输入部分的约束条件进行相应的处理。

输出部分（output operand list），用以规定对输出变量（目标操作数）如何与寄存器结合的约束（constraint）,输出部分可以有多个约束，互相以逗号分开。每个约束以“＝”开头，接着用一个字母来表示操作数的类型，然后是关于变量结合的约束。例如，上例中：

```c
	:"=r" (__dummy)
```
“＝r”表示相应的目标操作数（指令部分的%0）可以使用任何一个通用寄存器，并且变量__dummy 存放在这个寄存器中，但如果是：               

```c
	:“＝m”(__dummy)
```

“＝m”就表示相应的目标操作数是存放在内存单元__dummy中。表示约束条件的字母很多，下表给出几个主要的约束字母及其含义：

<table>
	<tr><td>字母</td><td>含义</td></tr>
	<tr><td>m, v, o</td><td>内存单元</td></tr>
	<tr><td>R</td><td>任何通用寄存器</td>	</tr>
	<tr><td>I, h</td><td>直接操作数</td></tr>
	<tr><td>G</td><td>任意</td></tr>
	<tr><td>I</td><td>常数（0～31）</td></tr>
</table>

输入部分（input  operand list）：输入部分与输出部分相似，但没有“＝”。如果输入部分一个操作数所要求使用的寄存器，与前面输出部分某个约束所要求的是同一个寄存器，那就把对应操作数的编号（如“1”，“2”等）放在约束条件中。在后面的例子中，可看到这种情况。修改部分（clobber list,也称 乱码列表）:这部分常常以“memory”为约束条件，以表示操作完成后内存中的内容已有改变，如果原来某个寄存器的内容来自内存，那么现在内存中这个单元的内容已经改变。乱码列表通知编译器，有些寄存器或内存因内联汇编块造成乱码，可隐式地破坏了条件寄存器的某些位（字段）。 注意，指令部分为必选项，而输入部分、输出部分及修改部分为可选项，当输入部分存在，而输出部分不存在时，冒号“：”要保留，当“memory”存在时，三个冒号都要保留。

参考：
- [GCC Manual， 版本为5.0.0 pre-release,6.43节（How to Use Inline Assembly Language in C Code）](https://gcc.gnu.org/onlinedocs/gcc.pdf)
- [GCC-Inline-Assembly-HOWTO](http://www.ibiblio.org/gferg/ldp/GCC-Inline-Assembly-HOWTO.html)