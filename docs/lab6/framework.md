## 调度框架和调度算法 

### 设计思路 

实行一个进程调度策略，到底需要实现哪些基本功能对应的数据结构？首先考虑到一个无论哪种调度算法都需要选择一个就绪进程来占用CPU运行。为此我们可把就绪进程组织起来，可用队列（双向链表）、二叉树、红黑树、数组…等不同的组织方式。

在操作方面，如果需要选择一个就绪进程，就可以从基于某种组织方式的就绪进程集合中选择出一个进程执行。需要注意，这里“选择”和“出”是两个操作，选择是在集合中挑选一个“合适”的进程，“出”意味着离开就绪进程集合。另外考虑到一个处于运行态的进程还会由于某种原因（比如时间片用完了）回到就绪态而不能继续占用CPU执行，这就会重新进入到就绪进程集合中。这两种情况就形成了调度器相关的三个基本操作：在就绪进程集合中选择、进入就绪进程集合和离开就绪进程集合。这三个操作属于调度器的基本操作。

在进程的执行过程中，就绪进程的等待时间和执行进程的执行时间是影响调度选择的重要因素，这两个因素随着时间的流逝和各种事件的发生在不停地变化，比如处于就绪态的进程等待调度的时间在增长，处于运行态的进程所消耗的时间片在减少等。这些进程状态变化的情况需要及时让进程调度器知道，便于选择更合适的进程执行。所以这种进程变化的情况就形成了调度器相关的一个变化感知操作：timer时间事件感知操作。这样在进程运行或等待的过程中，调度器可以调整进程控制块中与进程调度相关的属性值（比如消耗的时间片、进程优先级等），并可能导致对进程组织形式的调整（比如以时间片大小的顺序来重排双向链表等），并最终可能导致调选择新的进程占用CPU运行。这个操作属于调度器的进程调度属性调整操作。

### 数据结构 

在理解框架之前，需要先了解一下调度器框架所需要的数据结构。

* 通常的操作系统中，进程池是很大的（虽然在 ucore 中，MAX\_PROCESS 很小）。在 ucore 中，调度器引入 run-queue（简称rq,即运行队列）的概念，通过链表结构管理进程。
* 由于目前 ucore 设计运行在单CPU上，其内部只有一个全局的运行队列，用来管理系统内全部的进程。
* 运行队列通过链表的形式进行组织。链表的每一个节点是一个list\_entry\_t,每个list\_entry\_t 又对应到了 struct proc\_struct \*,这其间的转换是通过宏 le2proc 来完成 的。具体来说，我们知道在 struct proc\_struct 中有一个叫 run\_link 的 list\_entry\_t，因此可以通过偏移量逆向找到对因某个 run\_list的 struct proc\_struct。即进程结构指针 proc = le2proc(链表节点指针, run\_link)。
* 为了保证调度器接口的通用性，ucore调度框架定义了如下接口，该接口中，几乎全部成员变量均为函数指针。具体的功能会在后面的框架说明中介绍。

```
struct sched_class {
	// 调度器的名字
	const char *name;
	// 初始化运行队列
	void (*init) (struct run_queue *rq);
	// 将进程 p 插入队列 rq
	void (*enqueue) (struct run_queue *rq, struct proc_struct *p);
	// 将进程 p 从队列 rq 中删除
	void (*dequeue) (struct run_queue *rq, struct proc_struct *p);
	// 返回 运行队列 中下一个可执行的进程
	struct proc_struct* (*pick_next) (struct run_queue *rq);
	// timetick 处理函数
	void (*proc_tick)(struct  run_queue* rq, struct proc_struct* p);
};
```

* 此外，proc.h 中的 struct proc\_struct 中也记录了一些调度相关的信息：

```
struct proc_struct {
    // . . .
    // 该进程是否需要调度，只对当前进程有效
    volatile bool need_resched;
    // 该进程的调度链表结构，该结构内部的连接组成了 运行队列 列表
    list_entry_t run_link;
    // 该进程剩余的时间片，只对当前进程有效
    int time_slice;
    // round-robin 调度器并不会用到以下成员
    // 该进程在优先队列中的节点，仅在 LAB6 使用
    skew_heap_entry_t  lab6_run_pool;
    // 该进程的调度优先级，仅在 LAB6 使用
    uint32_t lab6_priority;
    // 该进程的调度步进值，仅在 LAB6 使用
    uint32_t lab6_stride;
};
```

在此次实验中，你需要了解 default\_sched.c中的实现RR调度算法的函数。在该文件中，你可以看到ucore 已经为 RR 调度算法创建好了一个名为 RR\_sched\_class 的调度策略类。

通过数据结构 struct run\_queue 来描述完整的 run\_queue（运行队列）。它的主要结构如下：

```
struct run_queue {
    //其运行队列的哨兵结构，可以看作是队列头和尾
    list_entry_t run_list;
    //优先队列形式的进程容器，只在 LAB6 中使用
    skew_heap_entry_t  *lab6_run_pool;
    //表示其内部的进程总数
    unsigned int proc_num;
    //每个进程一轮占用的最多时间片
    int max_time_slice;
};
```

在 ucore 框架中，运行队列存储的是当前可以调度的进程，所以，只有状态为runnable的进程才能够进入运行队列。当前正在运行的进程并不会在运行队列中，这一点需要注意。

### 调度点的相关关键函数 

虽然进程各种状态变化的原因和导致的调度处理各异，但其实仔细观察各个流程的共性部分，会发现其中只涉及了三个关键调度相关函数：wakup\_proc、shedule、run\_timer\_list。如果我们能够让这三个调度相关函数的实现与具体调度算法无关，那么就可以认为ucore实现了一个与调度算法无关的调度框架。

wakeup\_proc函数其实完成了把一个就绪进程放入到就绪进程队列中的工作，为此还调用了一个调度类接口函数sched\_class\_enqueue，这使得wakeup\_proc的实现与具体调度算法无关。schedule函数完成了与调度框架和调度算法相关三件事情:把当前继续占用CPU执行的运行进程放放入到就绪进程队列中，从就绪进程队列中选择一个“合适”就绪进程，把这个“合适”的就绪进程从就绪进程队列中摘除。通过调用三个调度类接口函数sched\_class\_enqueue、sched\_class\_pick\_next、sched\_class\_enqueue来使得完成这三件事情与具体的调度算法无关。run\_timer\_list函数在每次timer中断处理过程中被调用，从而可用来调用调度算法所需的timer时间事件感知操作，调整相关进程的进程调度相关的属性值。通过调用调度类接口函数sched\_class\_proc\_tick使得此操作与具体调度算法无关。

这里涉及了一系列调度类接口函数：

* sched_class_enqueue
* sched_class_dequeue
* sched_class_pick_next
* sched_class_proc_tick

这4个函数的实现其实就是调用某基于sched\_class数据结构的特定调度算法实现的4个指针函数。采用这样的调度类框架后，如果我们需要实现一个新的调度算法，则我们需要定义一个针对此算法的调度类的实例，一个就绪进程队列的组织结构描述就行了，其他的事情都可交给调度类框架来完成。

### RR 调度算法实现 

RR调度算法的调度思想 是让所有runnable态的进程分时轮流使用CPU时间。RR调度器维护当前runnable进程的有序运行队列。当前进程的时间片用完之后，调度器将当前进程放置到运行队列的尾部，再从其头部取出进程进行调度。RR调度算法的就绪队列在组织结构上也是一个双向链表，只是增加了一个成员变量，表明在此就绪进程队列中的最大执行时间片。而且在进程控制块proc\_struct中增加了一个成员变量time\_slice，用来记录进程当前的可运行时间片段。这是由于RR调度算法需要考虑执行进程的运行时间不能太长。在每个timer到时的时候，操作系统会递减当前执行进程的time\_slice，当time\_slice为0时，就意味着这个进程运行了一段时间（这个时间片段称为进程的时间片），需要把CPU让给其他进程执行，于是操作系统就需要让此进程重新回到rq的队列尾，且重置此进程的时间片为就绪队列的成员变量最大时间片max\_time\_slice值，然后再从rq的队列头取出一个新的进程执行。下面来分析一下其调度算法的实现。

RR\_enqueue的函数实现如下表所示。即把某进程的进程控制块指针放入到rq队列末尾，且如果进程控制块的时间片为0，则需要把它重置为rq成员变量max\_time\_slice。这表示如果进程在当前的执行时间片已经用完，需要等到下一次有机会运行时，才能再执行一段时间。

```
static void
RR_enqueue(struct run_queue *rq, struct proc_struct *proc) {
    assert(list_empty(&(proc->run_link)));
    list_add_before(&(rq->run_list), &(proc->run_link));
    if (proc->time_slice == 0 || proc->time_slice > rq->max_time_slice) {
        proc->time_slice = rq->max_time_slice;
    }
    proc->rq = rq;
    rq->proc_num ++;
}
```

RR\_pick\_next的函数实现如下表所示。即选取就绪进程队列rq中的队头队列元素，并把队列元素转换成进程控制块指针。

```
static struct proc_struct *
RR_pick_next(struct run_queue *rq) {
    list_entry_t *le = list_next(&(rq->run_list));
    if (le != &(rq->run_list)) {
        return le2proc(le, run_link);
    }
    return NULL;
}
```

RR\_dequeue的函数实现如下表所示。即把就绪进程队列rq的进程控制块指针的队列元素删除，并把表示就绪进程个数的proc\_num减一。

```
static void
RR_dequeue(struct run_queue *rq, struct proc_struct *proc) {
    assert(!list_empty(&(proc->run_link)) && proc->rq == rq);
    list_del_init(&(proc->run_link));
    rq->proc_num --;
}
```

RR\_proc\_tick的函数实现如下表所示。即每次timer到时后，trap函数将会间接调用此函数来把当前执行进程的时间片time\_slice减一。如果time\_slice降到零，则设置此进程成员变量need\_resched标识为1，这样在下一次中断来后执行trap函数时，会由于当前进程程成员变量need\_resched标识为1而执行schedule函数，从而把当前执行进程放回就绪队列末尾，而从就绪队列头取出在就绪队列上等待时间最久的那个就绪进程执行。

```
static void
RR_proc_tick(struct run_queue *rq, struct proc_struct *proc) {
    if (proc->time_slice > 0) {
        proc->time_slice --;
    }
    if (proc->time_slice == 0) {
        proc->need_resched = 1;
    }
}
```

