#### 中断与异常

操作系统需要对计算机系统中的各种外设进行管理，这就需要CPU和外设能够相互通信才行。一般外设的速度远慢于CPU的速度。如果让操作系统通过CPU“主动关心”外设的事件，即采用通常的轮询(polling)机制，则太浪费CPU资源了。所以需要操作系统和CPU能够一起提供某种机制，让外设在需要操作系统处理外设相关事件的时候，能够“主动通知”操作系统，即打断操作系统和应用的正常执行，让操作系统完成外设的相关处理，然后在恢复操作系统和应用的正常执行。在操作系统中，这种机制称为中断机制。中断机制给操作系统提供了处理意外情况的能力，同时它也是实现进程/线程抢占式调度的一个重要基石。但中断的引入导致了对操作系统的理解更加困难。、

在LoongArch32架构中，中断属于异常(Exception)的一种，uCore内核目前处理的异常包括以下类型：

- 中断          (EX_IRQ,CSR.ESTAT.Ecode=0)
- Load操作页无效 (EX_TLBL,CSR.ESTAT.Ecode=1)
- Store操作页无效(EX_TLBS,CSR.ESTAT.Ecode=2)
- TLB 重填      (EX_TLBR,CSR.ESTAT.Ecode=31)
- 指令不存在     (EX_RI,CSR.ESTAT.Ecode=13)
- 指令特权等级错误(EX_IPE,CSR.ESTAT.Ecode=14)
- 系统调用       (EX_SYS,CSR.ESTAT.Ecode=11)
- 地址错误例外    (EX_ADE,CSR.ESTAT.Ecode=8) 例如地址没有对齐

LoongArch32架构的处理器也提供了两个例外入口。分别是常规例外与TLB例外。由于TLB例外涉及重填页表的工作，因此必须为物理地址。而常规例外入口则可以根据目前处理器的运行状态选择使用虚拟地址或物理地址。

**注意：这里我们所使用的QEMU在直接地址翻译模式下，会抹除CSR.RFBASE地址的高3位，因此我们不需要关心TLB重填时地址访问的地址的问题，可以直接修改CSR.CRMD来开启映射地址翻译模式，然后当做虚拟地址一样处理即可。**

这两个例外入口也存储在CSR寄存器中，名称分别为CSR.EBASE与CSR.RFBASE。当例外产生时，处理器会进行如下操作：
- 将CSR.CRMD的PLV、IE分别存到CSR.PRMD的PPLV和IE中，然后将CSR.CRMD的PLV置为0，IE置为0。
- 将触发例外指令的PC值记录到CSR.ERA中
- 跳转到例外入口处取值。（如果是TLB相关例外跳转到CSR.RFBASE，否则为CSR.EBASE）

然后将PC跳转到对应的例外入口地址处，交给软件完成例外的处理操作。

当例外处理结束后，软件应该执行ERTN从例外状态返回，该指令会完成如下操作：
- 将CSR.PRMD中的PPLV、PIE值回复到CSR.CRMD的PLV、IE中。
- 跳转到CSR.ERA所记录的地址处取指。