#include <inc/stdio.h>
#include <inc/string.h>
#include <inc/memlayout.h>
#include <inc/assert.h>
#include <inc/x86.h>
#include <inc/math.h>
#include <kern/console.h>
#include <kern/monitor.h>
#include <kern/kdebug.h>



int powerbase(char base, char power)
{
	if(power!=1)
		return (base*powerbase(base,power-1));
	return base;
}

Float char_to_float(char* arg)
{
	int len=strlen(arg);
	short neg = 0;
	int i=0;
	double a = 0;

	Float retval;
	retval.error=0;

	while (i<len)
	{
		if (*(arg) == '.')
		{
//			after the point
			a = a + (*(arg+1) - '0') * 0.1;
			cprintf("entered val %f",a);
			retval.number=a;
			return retval;
		}
		if (*(arg)=='-')
		{
			neg = 1;
		}
		else if (*(arg) < '0' || (*(arg) > '9'))
		{
			retval.error = 1;
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
	retval.number=a;
	return retval;
}

