// Simple command-line kernel monitor useful for
// controlling the kernel and exploring the system interactively.

#include <inc/stdio.h>
#include <inc/string.h>
#include <inc/memlayout.h>
#include <inc/assert.h>
#include <inc/x86.h>
#include <inc/math.h>
#include <kern/console.h>
#include <kern/monitor.h>
#include <kern/kdebug.h>
#include <inc/calculator.h>
//#include "apps/include/first_lab.h"

#define CMDBUF_SIZE	80	// enough for one VGA text line


struct Command {
	const char *name;
	const char *desc;
	// return -1 to force monitor to exit
	int (*func)(int argc, char** argv, struct Trapframe* tf);
};

static struct Command commands[] = {
	{ "help", "Display this list of commands", mon_help },
	{ "calc", "Capital to small and small to Capital", calca },
	{ "kerninfo", "Display information about the kernel", mon_kerninfo },
};
#define NCOMMANDS (sizeof(commands)/sizeof(commands[0]))

/***** Implementations of basic kernel monitor commands *****/
int calca(int argc, char **argv, struct Trapframe *tf)
{
	return calculator();
}

int
second_lab(int argc, char **argv, struct Trapframe *tf)
{
	/// Yassin call his calculator here;
	char *in= NULL;
	char *out;
	out = readline(in);
	int i=0;
	float a=0;
	while (out+i)
	{
		if (*(out+i) != '.')
		{
			//after the point
		} 
		if (*(out+i) < '0' || *(out+i) > '9')
		{
			//operation or invalid argument
		}
		float a;
	}	
	return 0;
}


// First OS Lab

int
first_lab(int argc, char **argv, struct Trapframe *tf)
{
/*	char *in= NULL;
	char *out;
	out = readline(in);
		int i=0;

		while((out+i)!= NULL)
		{
			char o=out[i];
			__asm__ __volatile__(
			"cmpb %[o],'z'\n\t"
			"jg upcase\n\t"
			"addb $31,%[o]\n\t"
			"jmp end\n\t"
			"upcase:\n\t"
			"subb $32,%[o]\n\t"
			"end:\n\t"
			:[o]"=r"(o) 
			:"r"(o));
			out[i]=o;	
			i++;			
		}

		float x=10;
		float y=9;
		float z=x*y;
		char* c="123";
//		float* a=(float*)c;
//		float* a=(float*)c;
//		out=(char*)a;
///////////////////////////////////////// */
	char *in= NULL;
	char* arg;

	arg = readline(in);
	int len=strlen(arg);
	short neg = 0;
	int i=0;
	double a = 0;
	while (i<len)
	{
		if (*(arg) == '.')
		{
//			after the point
			a = a + (*(arg+1) - '0') * 0.1;
			cprintf("entered val %f",a);
			return 0;
		}
		if (*(arg)=='-')
		{
			neg = 1;
		}
		else if (*(arg) < '0' || (*(arg) > '9'))
		{
			cprintf("Invalid Argument");
			//operation or invalid argument
		}
		// BUG: PowerBase has to be fixed
		// BUG: if power equals zero, the point disappears ?!
		a =  powerbase(10,len-i) / 10 * (*(arg) - '0') + a;
		i++;
		arg=arg+1;
	}

	cprintf("entered val %f",a);
	return 0;
}


int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}


int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	// Your code here.
	return 0;
}



/***** Kernel monitor command interpreter *****/

#define WHITESPACE "\t\r\n "
#define MAXARGS 16

static int
runcmd(char *buf, struct Trapframe *tf)
{
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
		if (*buf == 0)
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
	}
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
	return 0;
}


void
monitor(struct Trapframe *tf)
{
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
	cprintf("Type 'help' for a list of commands.\n");


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
