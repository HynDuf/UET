#include <linux/init.h>
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/sched.h>
#include <linux/sched/signal.h>

struct task_struct *task;
struct list_head *list;

void depth_first_search_tasks(struct list_head *list, struct list_head *next)
{
       list_for_each(list, next)
       {
              task = list_entry(list, struct task_struct, sibling);
              printk(KERN_INFO "%s\t%ld\t%d\n", task->comm, (long) task->__state, task->pid);
              depth_first_search_tasks(list, &task->children);
       }
}

/* This function is called when the module is loaded. */
int simple_init(void)
{
       printk(KERN_INFO "Loading Module 21020007 Huynh Tien Dung\n");
       printk(KERN_INFO "Name\tState\tPID\n");
       // 1, 8415, 8416, 9298, 9204, 2, 6, 200, 3028, 3610, 4005

       depth_first_search_tasks(list, &init_task.children);
       return 0;
}

/* This function is called when the module is removed. */
void simple_exit(void)
{
       printk(KERN_INFO "Removing Module\n");
}

/* Macros for registering module entry and exit points. */
module_init(simple_init);
module_exit(simple_exit);

MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("Simple Module");
MODULE_AUTHOR("SGG");
