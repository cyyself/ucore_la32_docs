
##### GCC扩展内联汇编

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

	:"=r" (__dummy)

“＝r”表示相应的目标操作数（指令部分的%0）可以使用任何一个通用寄存器，并且变量__dummy 存放在这个寄存器中，但如果是：               

	:“＝m”(__dummy)

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
