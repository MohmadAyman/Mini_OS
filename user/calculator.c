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
	for (i = 0; i < 6; i++)
	{
		op[i].position = op[i].position - 1;
	}
}

int Isoperation(char r)
{
	cprintf("error inside is operation");
	if (r == '+' || r == '-' || r == '*' || r == '/' || r == '%')
	{
				cprintf(" error inside isoperation : Return 1");

		return 1;
	}
	else
	{
				cprintf(" error inside isoperation : Return 0");

		return 0;
	}
					cprintf(" error inside isoperation : Return 0");

	return 0;
}


int Isnumber(char r)
{
	cprintf("%c",r);
	if (r >= '0' && r <= '9')
	{
		cprintf(" error inside isnumber : Return 1");

		return 1;
	}
	else
	{
	cprintf(" error inside isnumber : Return 0");

		return 0;
	}
	return 0;

		cprintf(" error inside isnumber");
}

int Isdot(char r)
{
	cprintf("error inside isdot");
	if (r == '.')
	{
				cprintf(" error inside Isdot : Return 1");

		return 1;
	}
	else
	{
			cprintf(" error inside Isdot : Return 0");

		return 0;
	}
				cprintf(" error inside Isdot : Return 0");

	return 0;

}

void removeItem(float str[], int location)
{
	int i;

	for (i = location; i < 6; i++)
	{
		str[i] = str[i + 1];
	}

	str[6] = 0;

}

void clearnumber(char * number)
{

	int i = 0;
	for (i = 0; i < strlen(number); i++)
	{
		number[i] = '0';
	}
	number[strlen(number)] = '\0';
}


Float Getnumber(char* str, int *i)
{
	Float Value;
	int dot = 1;
	int y = 1;
	char number[100];
	number[strlen(str)] = '\0';
	clearnumber(number);
	number[0] = str[*i];
	*i++;
	cprintf("%d",strlen(str));
	while (*i < strlen(str))
	{
		cprintf("inside Getnumber loop");
		cprintf("Isnumber Argument %c",str[*i]);
		if (Isnumber(str[*i]))
		{
			cprintf("first number");
			number[y] = str[*i];
			y++;
			*i++;
		}
		cprintf("is a dot error");
		if (Isdot((str[*i])) && dot)
		{
			cprintf("is a dot");

			number[y] = str[*i];
			dot--;
			y++;
			*i++;
		}
		cprintf("isoperation error");
		if ( Isoperation(str[*i]) )
	        {
			    cprintf("is operation");

				if (dot)
			    {
		         	number[y] = '.';
			    }
		            break;
			}

			cprintf("get number error inside Getnuber");
			Value.error = 1;
			Value.number = 1;
			return Value;
	}
	cprintf("*i > strlen(str)");
	Value = char_to_float(number);
	cprintf("the returned float %f",Value.number);
	return Value;
}

Char GetOperation(char* str, int i)
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

void calc(float numbers[], operantion op[])
{
	int i;

	for (i = 0; i < 6; i++)
	{
		if (op[i].operant == '*')
		{
			numbers[op[i].position - 1] = numbers[op[i].position - 1] * numbers[op[i].position];

		}
		else if (op[i].operant == '/')
		{
			if (numbers[op[i].position == 0])
			{
				cprintf("error");
				return;
			}
			numbers[op[i].position - 1] = numbers[op[i].position - 1] / numbers[op[i].position];
		}
		else if (op[i].operant == '%')
		{
			if (numbers[op[i].position == 0])
			{
				cprintf("error");
				return;
			}
		int y = (int)(numbers[op[i].position - 1] / numbers[op[i].position]);
		numbers[op[i].position - 1] = numbers[op[i].position - 1] / numbers[op[i].position];
		}
		else{ break; }
		removeItem(numbers, op[i].position);
		subtract_List_Operation(op);
	}
	float result;
	result = 0;
	for (i = 0; i < sizeof(numbers); i++)
	{
		result = result + numbers[i];
	}
	cprintf("%f", result);

}

int calculator()
{
	int numposition = 0;
	int Operation_Position = 1;
	int operantnum = 0;
	float A[6];
	int i = 0;


	operantion numericop[6];

	operantion oper;
	oper.operant = '0';
	oper.position = 0;

	for (i = 0; i < 6; i++)
	{
		numericop[i].operant ='0';
		numericop[i].position = 0 ;
	}
	cprintf("Expression:");
	char *op  = readline("");
	char number[256];
	number[strlen(op)] = '\0';
	clearnumber(number);
	i = 0;
	if (!(op[0] != '-' || Isnumber(op[0])))
	{
		cprintf("error");
		return -1;
	}
	if (!(Isnumber(op[strlen(op) - 1]) || Isdot(op[strlen(op) - 1])))
	{
		cprintf("error");
		return -1;
	}

	while (i < strlen(op))
	{
		cprintf("inside the main loop, no errors \n");
		Float answer_num = Getnumber(op, &i);
		cprintf("getnumber error solved");
		if (answer_num.error)
		{
			cprintf("error");
			return -1;
		}
		else
		{
			cprintf("in else in calculator");
			A[numposition] = answer_num.number;
			numposition++;
			cprintf("sucssecfuly got the float number %f",answer_num.number);
		}
		if (i == strlen(op))
		{
			break;
		}
		Char answer_char = GetOperation(op, i);
		if (answer_char.error)
		{
			cprintf("error");
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
