#include <inc/stdio.h>
#include <inc/string.h>
#include <inc/memlayout.h>
#include <inc/assert.h>
#include <inc/x86.h>

#include <kern/console.h>
#include <kern/monitor.h>
#include <kern/kdebug.h>

int
run_first_lab(){
	int i=0;
	char *in= NULL;
	char *out;
	out = readline(in);
/*		while(out[i]!=NULL)
		{
			char o=out[i];
			__asm__volatile(
			"cmp [o],'z'\n\t"
			"jg upcase\n\t"
			"addb '31',[o]\n\t"
			"jmp end\n\t"
			"upcase:\n\t"
			"subl $32,[o]\n\t"
			"end:\n\t"
			:[o] "=r" (o) 
			:[o] "r" (o));				
		}
		*/
	cprintf(out);
}
