#include <inc/stdio.h>
#include <inc/string.h>
#include <inc/memlayout.h>
#include <inc/assert.h>
#include <inc/x86.h>
#include <inc/math.h>
#include <kern/console.h>
#include <kern/monitor.h>
#include <kern/kdebug.h>
#include <inc/types.h>


void subtract_List_Operation(operantion op[]);

int Isoperation(char r);


int Isnumber(char r);

int Isdot(char r);

void removeItem(float str[] , int location);





Float Getnumber(char* str, int* i);

Char GetOperation(char* str, int* i);

void clearnumber(char * number);

void calc( float numbers[] , operantion op [] );

int calculator();