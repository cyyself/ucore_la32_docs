## Stride Scheduling 

### 基本思路 

**【提示】请先看练习2中提到的论文, 理解后在看下面的内容。**

考察 round-robin 调度器，在假设所有进程都充分使用了其拥有的 CPU 时间资源的情况下，所有进程得到的 CPU 时间应该是相等的。但是有时候我们希望调度器能够更智能地为每个进程分配合理的 CPU 资源。假设我们为不同的进程分配不同的优先级，则我们有可能希望每个进程得到的时间资源与他们的优先级成正比关系。Stride调度是基于这种想法的一个较为典型和简单的算法。除了简单易于实现以外，它还有如下的特点：

* 可控性：如我们之前所希望的，可以证明 Stride Scheduling对进程的调度次数正比于其优先级。
* 确定性：在不考虑计时器事件的情况下，整个调度机制都是可预知和重现的。该算法的基本思想可以考虑如下：       
  1. 为每个runnable的进程设置一个当前状态stride，表示该进程当前的调度权。另外定义其对应的pass值，表示对应进程在调度后，stride 需要进行的累加值。  
  2. 每次需要调度时，从当前 runnable 态的进程中选择 stride最小的进程调度。
  3. 对于获得调度的进程P，将对应的stride加上其对应的步长pass（只与进程的优先权有关系）。  
  4. 在一段固定的时间之后，回到 2.步骤，重新调度当前stride最小的进程。   
可以证明，如果令 P.pass =BigStride / P.priority 其中 P.priority 表示进程的优先权（大于 1），而 BigStride 表示一个预先定义的大常数，则该调度方案为每个进程分配的时间将与其优先级成正比。证明过程我们在这里略去，有兴趣的同学可以在网上查找相关资料。将该调度器应用到
ucore 的调度器框架中来，则需要将调度器接口实现如下：

* init:    
– 初始化调度器类的信息（如果有的话）。   
– 初始化当前的运行队列为一个空的容器结构。（比如和RR调度算法一样，初始化为一个有序列表）   

* enqueue    
– 初始化刚进入运行队列的进程 proc的stride属性。     
– 将 proc插入放入运行队列中去（注意：这里并不要求放置在队列头部）。    

* dequeue    
– 从运行队列中删除相应的元素。     

* pick next      
– 扫描整个运行队列，返回其中stride值最小的对应进程。     
– 更新对应进程的stride值，即pass = BIG\_STRIDE / P-\>priority; P-\>stride += pass。     

* proc tick:   
– 检测当前进程是否已用完分配的时间片。如果时间片用完，应该正确设置进程结构的相关标记来引起进程切换。    
– 一个 process 最多可以连续运行 rq.max\_time\_slice个时间片。    

在具体实现时，有一个需要注意的地方：stride属性的溢出问题，在之前的实现里面我们并没有考虑 stride 的数值范围，而这个值在理论上是不断增加的，在
stride溢出以后，基于stride的比较可能会出现错误。比如假设当前存在两个进程A和B，stride属性采用16位无符号整数进行存储。当前队列中元素如下（假设当前运行的进程已经被重新放置进运行队列中）：   

![image](../lab6_figs/image001.png)

此时应该选择 A 作为调度的进程，而在一轮调度后，队列将如下：

![image](../lab6_figs/image002.png)

可以看到由于溢出的出现，进程间stride的理论比较和实际比较结果出现了偏差。我们首先在理论上分析这个问题：令PASS\_MAX为当前所有进程里最大的步进值。则我们可以证明如下结论：对每次Stride调度器的调度步骤中，有其最大的步进值STRIDE\_MAX和最小的步进值STRIDE\_MIN之差：

STRIDE\_MAX – STRIDE\_MIN <= PASS\_MAX

提问 1：如何证明该结论？

有了该结论，在加上之前对优先级有Priority \> 1限制，我们有STRIDE\_MAX – STRIDE\_MIN <= BIG\_STRIDE,于是我们只要将BigStride取在某个范围之内，即可保证对于任意两个 Stride 之差都会在机器整数表示的范围之内。而我们可以通过其与0的比较结构，来得到两个Stride的大小关系。在上例中，虽然在直接的数值表示上 98 < 65535，但是 98 - 65535 的结果用带符号的 16位整数表示的结果为99,与理论值之差相等。所以在这个意义下 98 \> 65535。基于这种特殊考虑的比较方法，即便Stride有可能溢出，我们仍能够得到理论上的当前最小Stride，并做出正确的调度决定。

提问 2：在 ucore 中，目前Stride是采用无符号的32位整数表示。则BigStride应该取多少，才能保证比较的正确性？

### 使用优先队列实现 Stride Scheduling 

在上述的实现描述中，对于每一次pick\_next函数，我们都需要完整地扫描来获得当前最小的stride及其进程。这在进程非常多的时候是非常耗时和低效的，有兴趣的同学可以在实现了基于列表扫描的Stride调度器之后比较一下priority程序在Round-Robin及Stride调度器下各自的运行时间。考虑到其调度选择于优先队列的抽象逻辑一致，我们考虑使用优化的优先队列数据结构实现该调度。

优先队列是这样一种数据结构：使用者可以快速的插入和删除队列中的元素，并且在预先指定的顺序下快速取得当前在队列中的最小（或者最大）值及其对应元素。可以看到，这样的数据结构非常符合 Stride 调度器的实现。

本次实验提供了libs/skew\_heap.h
作为优先队列的一个实现，该实现定义相关的结构和接口，其中主要包括：

```
1   // 优先队列节点的结构
2   typedef struct skew_heap_entry  skew_heap_entry_t;
3   // 初始化一个队列节点
4   void skew_heap_init(skew_heap_entry_t *a);
5   // 将节点 b 插入至以节点 a 为队列头的队列中去，返回插入后的队列
6   skew_heap_entry_t  *skew_heap_insert(skew_heap_entry_t  *a,
7                                        skew_heap_entry_t  *b,
8                                        compare_f comp);
9   // 将节点 b 插入从以节点 a 为队列头的队列中去，返回删除后的队列
10      skew_heap_entry_t  *skew_heap_remove(skew_heap_entry_t  *a,
11                                           skew_heap_entry_t  *b,
12                                           compare_f comp);
```

其中优先队列的顺序是由比较函数comp决定的，sched\_stride.c中提供了proc\_stride\_comp\_f比较器用来比较两个stride的大小，你可以直接使用它。当使用优先队列作为Stride调度器的实现方式之后，运行队列结构也需要作相关改变，其中包括：

* struct
run\_queue中的lab6\_run\_pool指针，在使用优先队列的实现中表示当前优先队列的头元素，如果优先队列为空，则其指向空指针（NULL）。

* struct
proc\_struct中的lab6\_run\_pool结构，表示当前进程对应的优先队列节点。本次实验已经修改了系统相关部分的代码，使得其能够很好地适应LAB6新加入的数据结构和接口。而在实验中我们需要做的是用优先队列实现一个正确和高效的Stride调度器，如果用较简略的伪代码描述，则有：

* init(rq):   
– Initialize rq-\>run\_list   
– Set rq-\>lab6\_run\_pool to NULL   
– Set rq-\>proc\_num to 0   

* enqueue(rq, proc)   
– Initialize proc-\>time\_slice    
– Insert proc-\>lab6\_run\_pool into rq-\>lab6\_run\_pool   
– rq-\>proc\_num ++   

* dequeue(rq, proc)   
– Remove proc-\>lab6\_run\_pool from rq-\>lab6\_run\_pool    
– rq-\>proc\_num --   

* pick\_next(rq)   
– If rq-\>lab6\_run\_pool == NULL, return NULL   
– Find the proc corresponding to the pointer rq-\>lab6\_run\_pool   
– proc-\>lab6\_stride += BIG\_STRIDE / proc-\>lab6\_priority   
– Return proc   

* proc\_tick(rq, proc):   
– If proc-\>time\_slice \> 0, proc-\>time\_slice --   
– If proc-\>time\_slice == 0, set the flag proc-\>need\_resched    
