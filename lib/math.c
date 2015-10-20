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
    float a = 0;

    Float retval;
    retval.error=0;

    while (i<len)
    {
        if (*(arg) == '.')
        {
                if (!(arg+1))
                {
                    return retval;
                }
                a = a + (*(arg+1) - '0') * 0.1;
                retval.number=a;
                goto ifnegative;
                if ((arg+2))
                {
                    a = a + (*(arg+2) - '0') * 0.1;
                }
                else
                {
                    retval.error=1; 
                    return retval;
                }
        }

        if (*(arg)=='-'&& i==0)
        {
            neg = 1;
            len--;
            goto argplus;
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
        argplus: arg=arg+1;
    }
ifnegative:
    if (neg==1)
    {
        retval.number=a*-1;
    }
    else
    {
        retval.number=a;
    }
        cprintf("form inside char_to_float %f",retval.number);
    return retval;
}

