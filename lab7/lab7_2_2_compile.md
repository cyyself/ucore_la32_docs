### 编译方法

**Makefile修改**
在Makefile中取消LAB7	:= -DLAB7_EX1 -D_SHOW_PHI(第12行)的注释
```
LAB1	:= -DLAB1_EX4 # -D_SHOW_100_TICKS -D_SHOW_SERIAL_INPUT
LAB2	:= -DLAB2_EX1 -DLAB2_EX2 -DLAB2_EX3
LAB3	:= -DLAB3_EX1 -DLAB3_EX2
LAB4	:= -DLAB4_EX1 -DLAB4_EX2
LAB5	:= -DLAB5_EX1 -DLAB5_EX2
LAB6	:= -DLAB6_EX2
LAB7	:= -DLAB7_EX1 -D_SHOW_PHI
# LAB8	:= -DLAB8_EX1 -DLAB8_EX2
```

编译并运行代码的命令如下：
```bash
make

make qemu -j 16
```
补全代码后可以得到如下显示界面（仅供参考）
```bash
chenyu$ make qemu -j 16
(THU.CST) os is loading ...

Special kernel symbols:
  entry  0xA00000A0 (phys)
  etext 0xA0021000 (phys)
  edata 0xA0155490 (phys)
  end   0xA0158770 (phys)
Kernel executable memory footprint: 1246KB
memory management: default_pmm_manager
memory map:
    [A0000000, A2000000]

freemem start at: A0199000
free pages: 00001E67
## 00000020
check_alloc_page() succeeded!
check_pgdir() succeeded!
check_boot_pgdir() succeeded!
check_slab() succeeded!
kmalloc_init() succeeded!
check_vma_struct() succeeded!
check_pgfault() succeeded!
check_vmm() succeeded.
sched class: stride_scheduler
proc_init succeeded
kernel_execve: pid = 2, name = "exit".
I am the parent. Forking the child...
I am parent, fork a child pid 13
I am the parent, waiting now..
I am No.0 philosopher_sema
Iter 1, No.0 philosopher_sema is thinking
I am No.1 philosopher_sema
Iter 1, No.1 philosopher_sema is thinking
I am No.2 philosopher_sema
Iter 1, No.2 philosopher_sema is thinking
I am No.2 philosopher_condvar
Iter 1, No.2 philosopher_condvar is thinking
I am No.3 philosopher_sema
Iter 1, No.3 philosopher_sema is thinking
I am No.4 philosopher_sema
Iter 1, No.4 philosopher_sema is thinking
I am No.0 philosopher_condvar
Iter 1, No.0 philosopher_condvar is thinking
I am No.1 philosopher_condvar
Iter 1, No.1 philosopher_condvar is thinking
I am No.3 philosopher_condvar
Iter 1, No.3 philosopher_condvar is thinking
I am No.4 philosopher_condvar
Iter 1, No.4 philosopher_condvar is thinking
I am the child.
waitpid 13 ok.
exit pass.
Iter 1, No.0 philosopher_sema is eating
Iter 1, No.2 philosopher_sema is eating
phi_test_condvar: state_condvar[2] will eating
phi_test_condvar: signal self_cv[2] 
cond_signal begin: cvp a01b20b8, cvp->count 0, cvp->owner->next_count 0
cond_signal end: cvp a01b20b8, cvp->count 0, cvp->owner->next_count 0
Iter 1, No.2 philosopher_condvar is eating
phi_test_condvar: state_condvar[0] will eating
phi_test_condvar: signal self_cv[0] 
cond_signal begin: cvp a01b2090, cvp->count 0, cvp->owner->next_count 0
cond_signal end: cvp a01b2090, cvp->count 0, cvp->owner->next_count 0
Iter 1, No.0 philosopher_condvar is eating
phi_take_forks_condvar: 1 didn't get fork and will wait
cond_wait begin:  cvp a01b20a4, cvp->count 0, cvp->owner->next_count 0
phi_take_forks_condvar: 3 didn't get fork and will wait
cond_wait begin:  cvp a01b20cc, cvp->count 0, cvp->owner->next_count 0
phi_take_forks_condvar: 4 didn't get fork and will wait
cond_wait begin:  cvp a01b20e0, cvp->count 0, cvp->owner->next_count 0
Iter 2, No.0 philosopher_sema is thinking
Iter 2, No.2 philosopher_sema is thinking
Iter 1, No.1 philosopher_sema is eating
phi_test_condvar: state_condvar[3] will eating
phi_test_condvar: signal self_cv[3] 
cond_signal begin: cvp a01b20cc, cvp->count 1, cvp->owner->next_count 0
Iter 1, No.4 philosopher_sema is eating
cond_wait end:  cvp a01b20cc, cvp->count 0, cvp->owner->next_count 1
Iter 1, No.3 philosopher_condvar is eating
cond_signal end: cvp a01b20cc, cvp->count 0, cvp->owner->next_count 0
Iter 2, No.2 philosopher_condvar is thinking
phi_test_condvar: state_condvar[1] will eating
phi_test_condvar: signal self_cv[1] 
cond_signal begin: cvp a01b20a4, cvp->count 1, cvp->owner->next_count 0
cond_wait end:  cvp a01b20a4, cvp->count 0, cvp->owner->next_count 1
Iter 1, No.1 philosopher_condvar is eating
cond_signal end: cvp a01b20a4, cvp->count 0, cvp->owner->next_count 0
Iter 2, No.0 philosopher_condvar is thinking
phi_take_forks_condvar: 0 didn't get fork and will wait
cond_wait begin:  cvp a01b2090, cvp->count 0, cvp->owner->next_count 0
phi_test_condvar: state_condvar[0] will eating
phi_test_condvar: signal self_cv[0] 
cond_signal begin: cvp a01b2090, cvp->count 1, cvp->owner->next_count 0
cond_wait end:  cvp a01b2090, cvp->count 0, cvp->owner->next_count 1
Iter 2, No.0 philosopher_condvar is eating
cond_signal end: cvp a01b2090, cvp->count 0, cvp->owner->next_count 0
Iter 2, No.1 philosopher_condvar is thinking
Iter 2, No.1 philosopher_sema is thinking
phi_take_forks_condvar: 2 didn't get fork and will wait
cond_wait begin:  cvp a01b20b8, cvp->count 0, cvp->owner->next_count 0
Iter 2, No.2 philosopher_sema is eating
Iter 2, No.4 philosopher_sema is thinking
phi_test_condvar: state_condvar[2] will eating
phi_test_condvar: signal self_cv[2] 
cond_signal begin: cvp a01b20b8, cvp->count 1, cvp->owner->next_count 0
Iter 2, No.0 philosopher_sema is eating
cond_wait end:  cvp a01b20b8, cvp->count 0, cvp->owner->next_count 1
Iter 2, No.2 philosopher_condvar is eating
cond_signal end: cvp a01b20b8, cvp->count 0, cvp->owner->next_count 0
Iter 2, No.3 philosopher_condvar is thinking
Iter 3, No.0 philosopher_sema is thinking
Iter 3, No.2 philosopher_condvar is thinking
phi_test_condvar: state_condvar[4] will eating
phi_test_condvar: signal self_cv[4] 
cond_signal begin: cvp a01b20e0, cvp->count 1, cvp->owner->next_count 0
cond_wait end:  cvp a01b20e0, cvp->count 0, cvp->owner->next_count 1
Iter 1, No.4 philosopher_condvar is eating
Iter 3, No.2 philosopher_sema is thinking
Iter 1, No.3 philosopher_sema is eating
cond_signal end: cvp a01b20e0, cvp->count 0, cvp->owner->next_count 0
Iter 3, No.0 philosopher_condvar is thinking
phi_test_condvar: state_condvar[1] will eating
phi_test_condvar: signal self_cv[1] 
cond_signal begin: cvp a01b20a4, cvp->count 0, cvp->owner->next_count 0
cond_signal end: cvp a01b20a4, cvp->count 0, cvp->owner->next_count 0
Iter 2, No.1 philosopher_condvar is eating
phi_take_forks_condvar: 3 didn't get fork and will wait
cond_wait begin:  cvp a01b20cc, cvp->count 0, cvp->owner->next_count 0
Iter 2, No.1 philosopher_sema is eating
Iter 2, No.3 philosopher_sema is thinking
Iter 2, No.4 philosopher_sema is eating
phi_take_forks_condvar: 0 didn't get fork and will wait
cond_wait begin:  cvp a01b2090, cvp->count 0, cvp->owner->next_count 0
Iter 3, No.1 philosopher_condvar is thinking
phi_test_condvar: state_condvar[3] will eating
phi_test_condvar: signal self_cv[3] 
cond_signal begin: cvp a01b20cc, cvp->count 1, cvp->owner->next_count 0
cond_wait end:  cvp a01b20cc, cvp->count 0, cvp->owner->next_count 1
Iter 2, No.3 philosopher_condvar is eating
Iter 3, No.1 philosopher_sema is thinking
Iter 3, No.2 philosopher_sema is eating
cond_signal end: cvp a01b20cc, cvp->count 0, cvp->owner->next_count 0
phi_test_condvar: state_condvar[0] will eating
phi_test_condvar: signal self_cv[0] 
cond_signal begin: cvp a01b2090, cvp->count 1, cvp->owner->next_count 0
cond_wait end:  cvp a01b2090, cvp->count 0, cvp->owner->next_count 1
Iter 3, No.0 philosopher_condvar is eating
cond_signal end: cvp a01b2090, cvp->count 0, cvp->owner->next_count 0
Iter 2, No.4 philosopher_condvar is thinking
phi_take_forks_condvar: 2 didn't get fork and will wait
cond_wait begin:  cvp a01b20b8, cvp->count 0, cvp->owner->next_count 0
phi_take_forks_condvar: 4 didn't get fork and will wait
cond_wait begin:  cvp a01b20e0, cvp->count 0, cvp->owner->next_count 0
Iter 4, No.0 philosopher_condvar is thinking
Iter 3, No.4 philosopher_sema is thinking
phi_test_condvar: state_condvar[1] will eating
phi_test_condvar: signal self_cv[1] 
cond_signal begin: cvp a01b20a4, cvp->count 0, cvp->owner->next_count 0
cond_signal end: cvp a01b20a4, cvp->count 0, cvp->owner->next_count 0
Iter 3, No.1 philosopher_condvar is eating
phi_test_condvar: state_condvar[4] will eating
phi_test_condvar: signal self_cv[4] 
cond_signal begin: cvp a01b20e0, cvp->count 1, cvp->owner->next_count 0
Iter 3, No.0 philosopher_sema is eating
Iter 4, No.2 philosopher_sema is thinking
Iter 2, No.3 philosopher_sema is eating
cond_wait end:  cvp a01b20e0, cvp->count 0, cvp->owner->next_count 1
Iter 2, No.4 philosopher_condvar is eating
cond_signal end: cvp a01b20e0, cvp->count 0, cvp->owner->next_count 0
Iter 3, No.3 philosopher_condvar is thinking
phi_take_forks_condvar: 3 didn't get fork and will wait
cond_wait begin:  cvp a01b20cc, cvp->count 0, cvp->owner->next_count 0
phi_test_condvar: state_condvar[3] will eating
phi_test_condvar: signal self_cv[3] 
cond_signal begin: cvp a01b20cc, cvp->count 1, cvp->owner->next_count 0
cond_wait end:  cvp a01b20cc, cvp->count 0, cvp->owner->next_count 1
Iter 3, No.3 philosopher_condvar is eating
cond_signal end: cvp a01b20cc, cvp->count 0, cvp->owner->next_count 0
Iter 3, No.4 philosopher_condvar is thinking
Iter 4, No.0 philosopher_sema is thinking
Iter 3, No.1 philosopher_sema is eating
Iter 3, No.3 philosopher_sema is thinking
Iter 4, No.1 philosopher_condvar is thinking
Iter 3, No.4 philosopher_sema is eating
phi_test_condvar: state_condvar[0] will eating
phi_test_condvar: signal self_cv[0] 
cond_signal begin: cvp a01b2090, cvp->count 0, cvp->owner->next_count 0
cond_signal end: cvp a01b2090, cvp->count 0, cvp->owner->next_count 0
Iter 4, No.0 philosopher_condvar is eating
Iter 4, No.4 philosopher_sema is thinking
No.0 philosopher_condvar quit
phi_test_condvar: state_condvar[2] will eating
phi_test_condvar: signal self_cv[2] 
cond_signal begin: cvp a01b20b8, cvp->count 1, cvp->owner->next_count 0
cond_wait end:  cvp a01b20b8, cvp->count 0, cvp->owner->next_count 1
Iter 3, No.2 philosopher_condvar is eating
Iter 4, No.1 philosopher_sema is thinking
Iter 4, No.2 philosopher_sema is eating
cond_signal end: cvp a01b20b8, cvp->count 0, cvp->owner->next_count 0
Iter 4, No.3 philosopher_condvar is thinking
phi_test_condvar: state_condvar[4] will eating
phi_test_condvar: signal self_cv[4] 
cond_signal begin: cvp a01b20e0, cvp->count 0, cvp->owner->next_count 0
cond_signal end: cvp a01b20e0, cvp->count 0, cvp->owner->next_count 0
Iter 3, No.4 philosopher_condvar is eating
Iter 4, No.0 philosopher_sema is eating
phi_take_forks_condvar: 1 didn't get fork and will wait
cond_wait begin:  cvp a01b20a4, cvp->count 0, cvp->owner->next_count 0
phi_take_forks_condvar: 3 didn't get fork and will wait
cond_wait begin:  cvp a01b20cc, cvp->count 0, cvp->owner->next_count 0
Iter 4, No.4 philosopher_condvar is thinking
No.0 philosopher_sema quit
phi_test_condvar: state_condvar[1] will eating
phi_test_condvar: signal self_cv[1] 
cond_signal begin: cvp a01b20a4, cvp->count 1, cvp->owner->next_count 0
Iter 4, No.4 philosopher_sema is eating
cond_wait end:  cvp a01b20a4, cvp->count 0, cvp->owner->next_count 1
Iter 4, No.1 philosopher_condvar is eating
cond_signal end: cvp a01b20a4, cvp->count 0, cvp->owner->next_count 0
phi_test_condvar: state_condvar[3] will eating
phi_test_condvar: signal self_cv[3] 
cond_signal begin: cvp a01b20cc, cvp->count 1, cvp->owner->next_count 0
cond_wait end:  cvp a01b20cc, cvp->count 0, cvp->owner->next_count 1
Iter 4, No.3 philosopher_condvar is eating
No.2 philosopher_sema quit
Iter 4, No.1 philosopher_sema is eating
cond_signal end: cvp a01b20cc, cvp->count 0, cvp->owner->next_count 0
Iter 4, No.2 philosopher_condvar is thinking
phi_take_forks_condvar: 4 didn't get fork and will wait
cond_wait begin:  cvp a01b20e0, cvp->count 0, cvp->owner->next_count 0
No.1 philosopher_sema quit
phi_take_forks_condvar: 2 didn't get fork and will wait
cond_wait begin:  cvp a01b20b8, cvp->count 0, cvp->owner->next_count 0
No.4 philosopher_sema quit
Iter 3, No.3 philosopher_sema is eating
No.1 philosopher_condvar quit
phi_test_condvar: state_condvar[2] will eating
phi_test_condvar: signal self_cv[2] 
cond_signal begin: cvp a01b20b8, cvp->count 1, cvp->owner->next_count 0
cond_wait end:  cvp a01b20b8, cvp->count 0, cvp->owner->next_count 1
Iter 4, No.2 philosopher_condvar is eating
cond_signal end: cvp a01b20b8, cvp->count 0, cvp->owner->next_count 0
phi_test_condvar: state_condvar[4] will eating
phi_test_condvar: signal self_cv[4] 
cond_signal begin: cvp a01b20e0, cvp->count 1, cvp->owner->next_count 0
cond_wait end:  cvp a01b20e0, cvp->count 0, cvp->owner->next_count 1
Iter 4, No.4 philosopher_condvar is eating
cond_signal end: cvp a01b20e0, cvp->count 0, cvp->owner->next_count 0
No.3 philosopher_condvar quit
Iter 4, No.3 philosopher_sema is thinking
No.4 philosopher_condvar quit
No.2 philosopher_condvar quit
Iter 4, No.3 philosopher_sema is eating
No.3 philosopher_sema quit
all user-mode processes have quit.
init check memory pass.
kernel panic at kern/process/proc.c:554:
    initproc exit.

Welcome to the kernel debug monitor!!
Type 'help' for a list of commands.
K> 
```
