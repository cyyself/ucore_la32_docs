# 实验七：同步互斥

## 实验目的 

* 理解操作系统的同步互斥的设计实现；
* 理解底层支撑技术：禁用中断、定时器、等待队列；
* 在ucore中理解信号量（semaphore）机制的具体实现；
* 理解管程机制，在ucore内核中增加基于管程（monitor）的条件变量（condition variable）的支持；
* 了解经典进程同步问题，并能使用同步机制解决进程同步问题。

## 实验内容 

实验六完成了用户进程的调度框架和具体的调度算法，可调度运行多个进程。如果多个进程需要协同操作或访问共享资源，则存在如何同步和有序竞争的问题。本次实验，主要是熟悉ucore的进程同步机制—信号量（semaphore）机制，以及基于信号量的哲学家就餐问题解决方案。然后掌握管程的概念和原理，并参考信号量机制，实现基于管程的条件变量机制和基于条件变量来解决哲学家就餐问题。

在本次实验中，在kern/sync/check\_sync.c中提供了一个基于信号量的哲学家就餐问题解法。同时还需完成练习，即实现基于管程（主要是灵活运用条件变量和互斥信号量）的哲学家就餐问题解法。哲学家就餐问题描述如下：有五个哲学家，他们的生活方式是交替地进行思考和进餐。哲学家们公用一张圆桌，周围放有五把椅子，每人坐一把。在圆桌上有五个碗和五根筷子，当一个哲学家思考时，他不与其他人交谈，饥饿时便试图取用其左、右最靠近他的筷子，但他可能一根都拿不到。只有在他拿到两根筷子时，方能进餐，进餐完后，放下筷子又继续思考。

## 实验执行流程概述 

互斥是指某一资源同时只允许一个进程对其进行访问，具有唯一性和排它性，但互斥不用限制进程对资源的访问顺序，即访问可以是无序的。同步是指在进程间的执行必须严格按照规定的某种先后次序来运行，即访问是有序的，这种先后次序取决于要系统完成的任务需求。在进程写资源情况下，进程间要求满足互斥条件。在进程读资源情况下，可允许多个进程同时访问资源。

实验七设计实现了多种同步互斥手段，包括时钟中断管理、等待队列、信号量、管程机制（包含条件变量设计）等，并基于信号量实现了哲学家问题的执行过程。而本次实验的练习是要求用管程机制实现哲学家问题的执行过程。在实现信号量机制和管程机制时，需要让无法进入临界区的进程睡眠，为此在ucore中设计了等待队列wait_queue。当进程无法进入临界区（即无法获得信号量）时，可让进程进入等待队列，这时的进程处于等待状态（也可称为阻塞状态），从而会让实验六中的调度器选择一个处于就绪状态（即RUNNABLE
STATE）的进程，进行进程切换，让新进程有机会占用CPU执行，从而让整个系统的运行更加高效。

在实验七中的ucore初始化过程，开始的执行流程都与实验六相同，直到执行到创建第二个内核线程init\_main时，修改了init\_main的具体执行内容，即增加了check\_sync函数的调用，而位于kern/sync/check\_sync.c中的check\_sync函数可以理解为是实验七的起始执行点，是实验七的总控函数。进一步分析此函数，可以看到这个函数主要分为了两个部分，第一部分是实现基于信号量的哲学家问题，第二部分是实现基于管程的哲学家问题。

对于check\_sync函数的第一部分，首先实现初始化了一个互斥信号量，然后创建了对应5个哲学家行为的5个信号量，并创建5个内核线程代表5个哲学家，每个内核线程完成了基于信号量的哲学家吃饭睡觉思考行为实现。这部分是给学生作为练习参考用的。学生可以看看信号量是如何实现的，以及如何利用信号量完成哲学家问题。

对于check\_sync函数的第二部分，首先初始化了管程，然后又创建了5个内核线程代表5个哲学家，每个内核线程要完成基于管程的哲学家吃饭、睡觉、思考的行为实现。这部分需要学生来具体完成。学生需要掌握如何用信号量来实现条件变量，以及包含条件变量的管程如何能够确保哲学家能够正常思考和吃饭。
