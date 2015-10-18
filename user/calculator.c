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

void subtract_List_Operation(operantion op[])
{
	int i;
	for (i = 0; i < sizeof(op); i++)
	{
		op[i].position = op[i].position - 1;
	}
}

int Isoperation(char r)
{
	if (r == '+' || r == '-' || r == '*' || r == '/' || r == '%')
	{
		return 1;
	}
	else
	{
		return 0;
	}
}


int Isnumber(char r)
{
	if (r >= '0' && r <= '9' )
	{
		return 1;
	}
	else
	{
		return 0;
	}
}

int Isdot(char r)
{
	if (r == '.')
	{
		return 1;
	}
	else
	{
		return 0;
	}

}

void removeItem(float str[] , int location)
{
	int i ;
	
	for (i = location; i < (sizeof(str)-1); i++)
	{
		str[i] = str[i + 1];
	}

	str[sizeof(str) - 1] = 0;
	
}

Float Getnumber(char* str, int* i)
{
	Float Value;
	int dot = 1;
	int y = 0;
	char *number = (char*)malloc(strlen(str));
	for (y = 0; y < strlen(number); y++)



		y = 1;
	number[0] = str[i];
	i++;
	while (i < strlen(str))
	{
		if (Isnumber(str[i]))
		{
			number[y] = str[i];
			y++;
			i++;
		}
		else if (Isdot((str[i])) && dot)
		{
			number[y] = str[i];
			dot--;
			y++;
			i++;
		}
		else
		{
			Value.error = 1;
			Value.number = 1;
			return Value;
		}
	}
	Value = char_to_float(number);
	return Value;


}


Char GetOperation(char* str, int* i)
{ 
	Char operat; 
	if (str[i] == '-' || str[i] == '+' || str[i] == '*' || str[i] == '/' || str[i] == '%')
	{
		operat.error = 0;
		operat.value = str[i];
		return operat;
	}
	else
	{
		operat.error = 1;
		operat.value = '0';
		return operat;
	}

}

void clearnumber(char * number)
{
	
	int i = 0;
	for (i = 0; i < strlen(number); i++)
	{
		number[i] = '0';
	}
}

void calc( float numbers[] , operantion op [] )
{
	int i; 

	for (i = 0; i < sizeof(op); i++)
	{
		if (op[i].operant == '*')
		{
			numbers[op[i].position - 1] = numbers[op[i].position - 1] * numbers[op[i].position];
			
		}
		else if (op[i].operant == '/')
		{
			if (numbers[op[i].position == 0])
			{
				printf("error");
				return;
			}
			numbers[op[i].position - 1] = numbers[op[i].position - 1] / numbers[op[i].position];
		}
		/*else if (op[i].operant == '%')
		{   
			int y = int(numbers[op[i].position - 1] / numbers[op[i].position]);

			numbers[op[i].position - 1] = numbers[op[i].position - 1] / numbers[op[i].position];
		}*/
		else{ break; }
		removeItem(numbers, op[i].position);
		subtract_List_Operation(op);
	}
	float result ;
	result = 0;
	for (i = 0; i < sizeof(numbers); i++)
	{
		result = result + numbers[i];
	}
	printf("%f", result);
	
}

int calculator()
{
	int numposition = 0;
	int Operation_Position = 1;
	int operantnum = 0;
	float * A = (float*)malloc(6*sizeof(float));
	int i = 0;

	
	operantion numericop[6];

	operantion oper;
	oper.operant = '0';
	oper.position = 0;

	for (i = 0; i < 6; i++)
	{
		numericop[i] = oper;
	}

	char *op = NULL;
	printf("Expression:");
	readline(op);
	char *number = (char*)malloc(strlen(op));
	clearnumber(number);
	i = 0;
	if (!(op[0] != '-' ||  Isnumber(op[0])) )
	{
		 printf("error");
		 return -1;
	}
	if (!(Isnumber(op[strlen(op) - 1]) || Isdot(op[strlen(op) - 1])))
	{
		printf("error");
		return -1;
	}

	while (i < strlen(op))
	{
		Float answer_num = Getnumber(op, *i);
		if (answer_num.error)
		{
			printf("error");
			return -1;
		}
		else 
		{
			A[numposition] = answer_num.number;
			numposition++;
		}
		if (i == strlen(op))
		{
			break;
		}
		Char answer_char  = GetOperation(op, *i);
		if (answer_char.error)
		{
			printf("error");
			return -1;
		}
		else
		{
			if (answer_char.value == '+')
			{
				i++;
			}
			else if (!(answer_char.value == '-'))
			{ 
				numericop[operantnum].operant = answer_char.value;
				numericop[operantnum].position = Operation_Position;
				operantnum++;
				i++;
			    
			}
			Operation_Position++;
		}

	}

	calc(A, numericop);
	return 0;

}