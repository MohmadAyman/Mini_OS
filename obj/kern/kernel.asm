
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 56 00 00 00       	call   f0100094 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 0c             	sub    $0xc,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	53                   	push   %ebx
f010004b:	68 00 1c 10 f0       	push   $0xf0101c00
f0100050:	e8 98 09 00 00       	call   f01009ed <cprintf>
	if (x > 0)
f0100055:	83 c4 10             	add    $0x10,%esp
f0100058:	85 db                	test   %ebx,%ebx
f010005a:	7e 11                	jle    f010006d <test_backtrace+0x2d>
		test_backtrace(x-1);
f010005c:	83 ec 0c             	sub    $0xc,%esp
f010005f:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100062:	50                   	push   %eax
f0100063:	e8 d8 ff ff ff       	call   f0100040 <test_backtrace>
f0100068:	83 c4 10             	add    $0x10,%esp
f010006b:	eb 11                	jmp    f010007e <test_backtrace+0x3e>
	else
		mon_backtrace(0, 0, 0);
f010006d:	83 ec 04             	sub    $0x4,%esp
f0100070:	6a 00                	push   $0x0
f0100072:	6a 00                	push   $0x0
f0100074:	6a 00                	push   $0x0
f0100076:	e8 fa 07 00 00       	call   f0100875 <mon_backtrace>
f010007b:	83 c4 10             	add    $0x10,%esp
	cprintf("leaving test_backtrace %d\n", x);
f010007e:	83 ec 08             	sub    $0x8,%esp
f0100081:	53                   	push   %ebx
f0100082:	68 1c 1c 10 f0       	push   $0xf0101c1c
f0100087:	e8 61 09 00 00       	call   f01009ed <cprintf>
f010008c:	83 c4 10             	add    $0x10,%esp
}
f010008f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100092:	c9                   	leave  
f0100093:	c3                   	ret    

f0100094 <i386_init>:

void
i386_init(void)
{
f0100094:	55                   	push   %ebp
f0100095:	89 e5                	mov    %esp,%ebp
f0100097:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f010009a:	b8 84 29 11 f0       	mov    $0xf0112984,%eax
f010009f:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000a4:	50                   	push   %eax
f01000a5:	6a 00                	push   $0x0
f01000a7:	68 00 23 11 f0       	push   $0xf0112300
f01000ac:	e8 47 15 00 00       	call   f01015f8 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b1:	e8 8c 04 00 00       	call   f0100542 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000b6:	83 c4 08             	add    $0x8,%esp
f01000b9:	68 ac 1a 00 00       	push   $0x1aac
f01000be:	68 37 1c 10 f0       	push   $0xf0101c37
f01000c3:	e8 25 09 00 00       	call   f01009ed <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000c8:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000cf:	e8 6c ff ff ff       	call   f0100040 <test_backtrace>
f01000d4:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000d7:	83 ec 0c             	sub    $0xc,%esp
f01000da:	6a 00                	push   $0x0
f01000dc:	e8 9e 07 00 00       	call   f010087f <monitor>
f01000e1:	83 c4 10             	add    $0x10,%esp
f01000e4:	eb f1                	jmp    f01000d7 <i386_init+0x43>

f01000e6 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000e6:	55                   	push   %ebp
f01000e7:	89 e5                	mov    %esp,%ebp
f01000e9:	56                   	push   %esi
f01000ea:	53                   	push   %ebx
f01000eb:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000ee:	83 3d 80 29 11 f0 00 	cmpl   $0x0,0xf0112980
f01000f5:	75 37                	jne    f010012e <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000f7:	89 35 80 29 11 f0    	mov    %esi,0xf0112980

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000fd:	fa                   	cli    
f01000fe:	fc                   	cld    

	va_start(ap, fmt);
f01000ff:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100102:	83 ec 04             	sub    $0x4,%esp
f0100105:	ff 75 0c             	pushl  0xc(%ebp)
f0100108:	ff 75 08             	pushl  0x8(%ebp)
f010010b:	68 52 1c 10 f0       	push   $0xf0101c52
f0100110:	e8 d8 08 00 00       	call   f01009ed <cprintf>
	vcprintf(fmt, ap);
f0100115:	83 c4 08             	add    $0x8,%esp
f0100118:	53                   	push   %ebx
f0100119:	56                   	push   %esi
f010011a:	e8 a8 08 00 00       	call   f01009c7 <vcprintf>
	cprintf("\n");
f010011f:	c7 04 24 8e 1c 10 f0 	movl   $0xf0101c8e,(%esp)
f0100126:	e8 c2 08 00 00       	call   f01009ed <cprintf>
	va_end(ap);
f010012b:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010012e:	83 ec 0c             	sub    $0xc,%esp
f0100131:	6a 00                	push   $0x0
f0100133:	e8 47 07 00 00       	call   f010087f <monitor>
f0100138:	83 c4 10             	add    $0x10,%esp
f010013b:	eb f1                	jmp    f010012e <_panic+0x48>

f010013d <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010013d:	55                   	push   %ebp
f010013e:	89 e5                	mov    %esp,%ebp
f0100140:	53                   	push   %ebx
f0100141:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100144:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100147:	ff 75 0c             	pushl  0xc(%ebp)
f010014a:	ff 75 08             	pushl  0x8(%ebp)
f010014d:	68 6a 1c 10 f0       	push   $0xf0101c6a
f0100152:	e8 96 08 00 00       	call   f01009ed <cprintf>
	vcprintf(fmt, ap);
f0100157:	83 c4 08             	add    $0x8,%esp
f010015a:	53                   	push   %ebx
f010015b:	ff 75 10             	pushl  0x10(%ebp)
f010015e:	e8 64 08 00 00       	call   f01009c7 <vcprintf>
	cprintf("\n");
f0100163:	c7 04 24 8e 1c 10 f0 	movl   $0xf0101c8e,(%esp)
f010016a:	e8 7e 08 00 00       	call   f01009ed <cprintf>
	va_end(ap);
f010016f:	83 c4 10             	add    $0x10,%esp
}
f0100172:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100175:	c9                   	leave  
f0100176:	c3                   	ret    

f0100177 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100177:	55                   	push   %ebp
f0100178:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010017a:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010017f:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100180:	a8 01                	test   $0x1,%al
f0100182:	74 08                	je     f010018c <serial_proc_data+0x15>
f0100184:	b2 f8                	mov    $0xf8,%dl
f0100186:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100187:	0f b6 c0             	movzbl %al,%eax
f010018a:	eb 05                	jmp    f0100191 <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f010018c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100191:	5d                   	pop    %ebp
f0100192:	c3                   	ret    

f0100193 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100193:	55                   	push   %ebp
f0100194:	89 e5                	mov    %esp,%ebp
f0100196:	53                   	push   %ebx
f0100197:	83 ec 04             	sub    $0x4,%esp
f010019a:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f010019c:	eb 2a                	jmp    f01001c8 <cons_intr+0x35>
		if (c == 0)
f010019e:	85 d2                	test   %edx,%edx
f01001a0:	74 26                	je     f01001c8 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f01001a2:	a1 44 25 11 f0       	mov    0xf0112544,%eax
f01001a7:	8d 48 01             	lea    0x1(%eax),%ecx
f01001aa:	89 0d 44 25 11 f0    	mov    %ecx,0xf0112544
f01001b0:	88 90 40 23 11 f0    	mov    %dl,-0xfeedcc0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f01001b6:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01001bc:	75 0a                	jne    f01001c8 <cons_intr+0x35>
			cons.wpos = 0;
f01001be:	c7 05 44 25 11 f0 00 	movl   $0x0,0xf0112544
f01001c5:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001c8:	ff d3                	call   *%ebx
f01001ca:	89 c2                	mov    %eax,%edx
f01001cc:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001cf:	75 cd                	jne    f010019e <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001d1:	83 c4 04             	add    $0x4,%esp
f01001d4:	5b                   	pop    %ebx
f01001d5:	5d                   	pop    %ebp
f01001d6:	c3                   	ret    

f01001d7 <kbd_proc_data>:
f01001d7:	ba 64 00 00 00       	mov    $0x64,%edx
f01001dc:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01001dd:	a8 01                	test   $0x1,%al
f01001df:	0f 84 f0 00 00 00    	je     f01002d5 <kbd_proc_data+0xfe>
f01001e5:	b2 60                	mov    $0x60,%dl
f01001e7:	ec                   	in     (%dx),%al
f01001e8:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001ea:	3c e0                	cmp    $0xe0,%al
f01001ec:	75 0d                	jne    f01001fb <kbd_proc_data+0x24>
		// E0 escape character
		shift |= E0ESC;
f01001ee:	83 0d 00 23 11 f0 40 	orl    $0x40,0xf0112300
		return 0;
f01001f5:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01001fa:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001fb:	55                   	push   %ebp
f01001fc:	89 e5                	mov    %esp,%ebp
f01001fe:	53                   	push   %ebx
f01001ff:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f0100202:	84 c0                	test   %al,%al
f0100204:	79 36                	jns    f010023c <kbd_proc_data+0x65>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f0100206:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f010020c:	89 cb                	mov    %ecx,%ebx
f010020e:	83 e3 40             	and    $0x40,%ebx
f0100211:	83 e0 7f             	and    $0x7f,%eax
f0100214:	85 db                	test   %ebx,%ebx
f0100216:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100219:	0f b6 d2             	movzbl %dl,%edx
f010021c:	0f b6 82 00 1e 10 f0 	movzbl -0xfefe200(%edx),%eax
f0100223:	83 c8 40             	or     $0x40,%eax
f0100226:	0f b6 c0             	movzbl %al,%eax
f0100229:	f7 d0                	not    %eax
f010022b:	21 c8                	and    %ecx,%eax
f010022d:	a3 00 23 11 f0       	mov    %eax,0xf0112300
		return 0;
f0100232:	b8 00 00 00 00       	mov    $0x0,%eax
f0100237:	e9 a1 00 00 00       	jmp    f01002dd <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f010023c:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f0100242:	f6 c1 40             	test   $0x40,%cl
f0100245:	74 0e                	je     f0100255 <kbd_proc_data+0x7e>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100247:	83 c8 80             	or     $0xffffff80,%eax
f010024a:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010024c:	83 e1 bf             	and    $0xffffffbf,%ecx
f010024f:	89 0d 00 23 11 f0    	mov    %ecx,0xf0112300
	}

	shift |= shiftcode[data];
f0100255:	0f b6 c2             	movzbl %dl,%eax
f0100258:	0f b6 90 00 1e 10 f0 	movzbl -0xfefe200(%eax),%edx
f010025f:	0b 15 00 23 11 f0    	or     0xf0112300,%edx
	shift ^= togglecode[data];
f0100265:	0f b6 88 00 1d 10 f0 	movzbl -0xfefe300(%eax),%ecx
f010026c:	31 ca                	xor    %ecx,%edx
f010026e:	89 15 00 23 11 f0    	mov    %edx,0xf0112300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100274:	89 d1                	mov    %edx,%ecx
f0100276:	83 e1 03             	and    $0x3,%ecx
f0100279:	8b 0c 8d c0 1c 10 f0 	mov    -0xfefe340(,%ecx,4),%ecx
f0100280:	0f b6 04 01          	movzbl (%ecx,%eax,1),%eax
f0100284:	0f b6 d8             	movzbl %al,%ebx
	if (shift & CAPSLOCK) {
f0100287:	f6 c2 08             	test   $0x8,%dl
f010028a:	74 1b                	je     f01002a7 <kbd_proc_data+0xd0>
		if ('a' <= c && c <= 'z')
f010028c:	89 d8                	mov    %ebx,%eax
f010028e:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100291:	83 f9 19             	cmp    $0x19,%ecx
f0100294:	77 05                	ja     f010029b <kbd_proc_data+0xc4>
			c += 'A' - 'a';
f0100296:	83 eb 20             	sub    $0x20,%ebx
f0100299:	eb 0c                	jmp    f01002a7 <kbd_proc_data+0xd0>
		else if ('A' <= c && c <= 'Z')
f010029b:	83 e8 41             	sub    $0x41,%eax
			c += 'a' - 'A';
f010029e:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01002a1:	83 f8 19             	cmp    $0x19,%eax
f01002a4:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002a7:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01002ad:	75 2c                	jne    f01002db <kbd_proc_data+0x104>
f01002af:	f7 d2                	not    %edx
f01002b1:	f6 c2 06             	test   $0x6,%dl
f01002b4:	75 25                	jne    f01002db <kbd_proc_data+0x104>
		cprintf("Rebooting!\n");
f01002b6:	83 ec 0c             	sub    $0xc,%esp
f01002b9:	68 84 1c 10 f0       	push   $0xf0101c84
f01002be:	e8 2a 07 00 00       	call   f01009ed <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002c3:	ba 92 00 00 00       	mov    $0x92,%edx
f01002c8:	b8 03 00 00 00       	mov    $0x3,%eax
f01002cd:	ee                   	out    %al,(%dx)
f01002ce:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002d1:	89 d8                	mov    %ebx,%eax
f01002d3:	eb 08                	jmp    f01002dd <kbd_proc_data+0x106>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01002d5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002da:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002db:	89 d8                	mov    %ebx,%eax
}
f01002dd:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01002e0:	c9                   	leave  
f01002e1:	c3                   	ret    

f01002e2 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002e2:	55                   	push   %ebp
f01002e3:	89 e5                	mov    %esp,%ebp
f01002e5:	57                   	push   %edi
f01002e6:	56                   	push   %esi
f01002e7:	53                   	push   %ebx
f01002e8:	83 ec 1c             	sub    $0x1c,%esp
f01002eb:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002ed:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002f2:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002f7:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002fc:	eb 09                	jmp    f0100307 <cons_putc+0x25>
f01002fe:	89 ca                	mov    %ecx,%edx
f0100300:	ec                   	in     (%dx),%al
f0100301:	ec                   	in     (%dx),%al
f0100302:	ec                   	in     (%dx),%al
f0100303:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f0100304:	83 c3 01             	add    $0x1,%ebx
f0100307:	89 f2                	mov    %esi,%edx
f0100309:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f010030a:	a8 20                	test   $0x20,%al
f010030c:	75 08                	jne    f0100316 <cons_putc+0x34>
f010030e:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100314:	7e e8                	jle    f01002fe <cons_putc+0x1c>
f0100316:	89 f8                	mov    %edi,%eax
f0100318:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010031b:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100320:	89 f8                	mov    %edi,%eax
f0100322:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100323:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100328:	be 79 03 00 00       	mov    $0x379,%esi
f010032d:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100332:	eb 09                	jmp    f010033d <cons_putc+0x5b>
f0100334:	89 ca                	mov    %ecx,%edx
f0100336:	ec                   	in     (%dx),%al
f0100337:	ec                   	in     (%dx),%al
f0100338:	ec                   	in     (%dx),%al
f0100339:	ec                   	in     (%dx),%al
f010033a:	83 c3 01             	add    $0x1,%ebx
f010033d:	89 f2                	mov    %esi,%edx
f010033f:	ec                   	in     (%dx),%al
f0100340:	84 c0                	test   %al,%al
f0100342:	78 08                	js     f010034c <cons_putc+0x6a>
f0100344:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f010034a:	7e e8                	jle    f0100334 <cons_putc+0x52>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010034c:	ba 78 03 00 00       	mov    $0x378,%edx
f0100351:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100355:	ee                   	out    %al,(%dx)
f0100356:	b2 7a                	mov    $0x7a,%dl
f0100358:	b8 0d 00 00 00       	mov    $0xd,%eax
f010035d:	ee                   	out    %al,(%dx)
f010035e:	b8 08 00 00 00       	mov    $0x8,%eax
f0100363:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100364:	89 fa                	mov    %edi,%edx
f0100366:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f010036c:	89 f8                	mov    %edi,%eax
f010036e:	80 cc 07             	or     $0x7,%ah
f0100371:	85 d2                	test   %edx,%edx
f0100373:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100376:	89 f8                	mov    %edi,%eax
f0100378:	0f b6 c0             	movzbl %al,%eax
f010037b:	83 f8 09             	cmp    $0x9,%eax
f010037e:	74 74                	je     f01003f4 <cons_putc+0x112>
f0100380:	83 f8 09             	cmp    $0x9,%eax
f0100383:	7f 0a                	jg     f010038f <cons_putc+0xad>
f0100385:	83 f8 08             	cmp    $0x8,%eax
f0100388:	74 14                	je     f010039e <cons_putc+0xbc>
f010038a:	e9 99 00 00 00       	jmp    f0100428 <cons_putc+0x146>
f010038f:	83 f8 0a             	cmp    $0xa,%eax
f0100392:	74 3a                	je     f01003ce <cons_putc+0xec>
f0100394:	83 f8 0d             	cmp    $0xd,%eax
f0100397:	74 3d                	je     f01003d6 <cons_putc+0xf4>
f0100399:	e9 8a 00 00 00       	jmp    f0100428 <cons_putc+0x146>
	case '\b':
		if (crt_pos > 0) {
f010039e:	0f b7 05 48 25 11 f0 	movzwl 0xf0112548,%eax
f01003a5:	66 85 c0             	test   %ax,%ax
f01003a8:	0f 84 e6 00 00 00    	je     f0100494 <cons_putc+0x1b2>
			crt_pos--;
f01003ae:	83 e8 01             	sub    $0x1,%eax
f01003b1:	66 a3 48 25 11 f0    	mov    %ax,0xf0112548
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003b7:	0f b7 c0             	movzwl %ax,%eax
f01003ba:	66 81 e7 00 ff       	and    $0xff00,%di
f01003bf:	83 cf 20             	or     $0x20,%edi
f01003c2:	8b 15 4c 25 11 f0    	mov    0xf011254c,%edx
f01003c8:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003cc:	eb 78                	jmp    f0100446 <cons_putc+0x164>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003ce:	66 83 05 48 25 11 f0 	addw   $0x50,0xf0112548
f01003d5:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003d6:	0f b7 05 48 25 11 f0 	movzwl 0xf0112548,%eax
f01003dd:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003e3:	c1 e8 16             	shr    $0x16,%eax
f01003e6:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003e9:	c1 e0 04             	shl    $0x4,%eax
f01003ec:	66 a3 48 25 11 f0    	mov    %ax,0xf0112548
f01003f2:	eb 52                	jmp    f0100446 <cons_putc+0x164>
		break;
	case '\t':
		cons_putc(' ');
f01003f4:	b8 20 00 00 00       	mov    $0x20,%eax
f01003f9:	e8 e4 fe ff ff       	call   f01002e2 <cons_putc>
		cons_putc(' ');
f01003fe:	b8 20 00 00 00       	mov    $0x20,%eax
f0100403:	e8 da fe ff ff       	call   f01002e2 <cons_putc>
		cons_putc(' ');
f0100408:	b8 20 00 00 00       	mov    $0x20,%eax
f010040d:	e8 d0 fe ff ff       	call   f01002e2 <cons_putc>
		cons_putc(' ');
f0100412:	b8 20 00 00 00       	mov    $0x20,%eax
f0100417:	e8 c6 fe ff ff       	call   f01002e2 <cons_putc>
		cons_putc(' ');
f010041c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100421:	e8 bc fe ff ff       	call   f01002e2 <cons_putc>
f0100426:	eb 1e                	jmp    f0100446 <cons_putc+0x164>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100428:	0f b7 05 48 25 11 f0 	movzwl 0xf0112548,%eax
f010042f:	8d 50 01             	lea    0x1(%eax),%edx
f0100432:	66 89 15 48 25 11 f0 	mov    %dx,0xf0112548
f0100439:	0f b7 c0             	movzwl %ax,%eax
f010043c:	8b 15 4c 25 11 f0    	mov    0xf011254c,%edx
f0100442:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100446:	66 81 3d 48 25 11 f0 	cmpw   $0x7cf,0xf0112548
f010044d:	cf 07 
f010044f:	76 43                	jbe    f0100494 <cons_putc+0x1b2>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100451:	a1 4c 25 11 f0       	mov    0xf011254c,%eax
f0100456:	83 ec 04             	sub    $0x4,%esp
f0100459:	68 00 0f 00 00       	push   $0xf00
f010045e:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100464:	52                   	push   %edx
f0100465:	50                   	push   %eax
f0100466:	e8 da 11 00 00       	call   f0101645 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010046b:	8b 15 4c 25 11 f0    	mov    0xf011254c,%edx
f0100471:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100477:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f010047d:	83 c4 10             	add    $0x10,%esp
f0100480:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100485:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100488:	39 d0                	cmp    %edx,%eax
f010048a:	75 f4                	jne    f0100480 <cons_putc+0x19e>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f010048c:	66 83 2d 48 25 11 f0 	subw   $0x50,0xf0112548
f0100493:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100494:	8b 0d 50 25 11 f0    	mov    0xf0112550,%ecx
f010049a:	b8 0e 00 00 00       	mov    $0xe,%eax
f010049f:	89 ca                	mov    %ecx,%edx
f01004a1:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01004a2:	0f b7 1d 48 25 11 f0 	movzwl 0xf0112548,%ebx
f01004a9:	8d 71 01             	lea    0x1(%ecx),%esi
f01004ac:	89 d8                	mov    %ebx,%eax
f01004ae:	66 c1 e8 08          	shr    $0x8,%ax
f01004b2:	89 f2                	mov    %esi,%edx
f01004b4:	ee                   	out    %al,(%dx)
f01004b5:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004ba:	89 ca                	mov    %ecx,%edx
f01004bc:	ee                   	out    %al,(%dx)
f01004bd:	89 d8                	mov    %ebx,%eax
f01004bf:	89 f2                	mov    %esi,%edx
f01004c1:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004c2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01004c5:	5b                   	pop    %ebx
f01004c6:	5e                   	pop    %esi
f01004c7:	5f                   	pop    %edi
f01004c8:	5d                   	pop    %ebp
f01004c9:	c3                   	ret    

f01004ca <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004ca:	80 3d 54 25 11 f0 00 	cmpb   $0x0,0xf0112554
f01004d1:	74 11                	je     f01004e4 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004d3:	55                   	push   %ebp
f01004d4:	89 e5                	mov    %esp,%ebp
f01004d6:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004d9:	b8 77 01 10 f0       	mov    $0xf0100177,%eax
f01004de:	e8 b0 fc ff ff       	call   f0100193 <cons_intr>
}
f01004e3:	c9                   	leave  
f01004e4:	f3 c3                	repz ret 

f01004e6 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004e6:	55                   	push   %ebp
f01004e7:	89 e5                	mov    %esp,%ebp
f01004e9:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004ec:	b8 d7 01 10 f0       	mov    $0xf01001d7,%eax
f01004f1:	e8 9d fc ff ff       	call   f0100193 <cons_intr>
}
f01004f6:	c9                   	leave  
f01004f7:	c3                   	ret    

f01004f8 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004f8:	55                   	push   %ebp
f01004f9:	89 e5                	mov    %esp,%ebp
f01004fb:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004fe:	e8 c7 ff ff ff       	call   f01004ca <serial_intr>
	kbd_intr();
f0100503:	e8 de ff ff ff       	call   f01004e6 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100508:	a1 40 25 11 f0       	mov    0xf0112540,%eax
f010050d:	3b 05 44 25 11 f0    	cmp    0xf0112544,%eax
f0100513:	74 26                	je     f010053b <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100515:	8d 50 01             	lea    0x1(%eax),%edx
f0100518:	89 15 40 25 11 f0    	mov    %edx,0xf0112540
f010051e:	0f b6 88 40 23 11 f0 	movzbl -0xfeedcc0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100525:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100527:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010052d:	75 11                	jne    f0100540 <cons_getc+0x48>
			cons.rpos = 0;
f010052f:	c7 05 40 25 11 f0 00 	movl   $0x0,0xf0112540
f0100536:	00 00 00 
f0100539:	eb 05                	jmp    f0100540 <cons_getc+0x48>
		return c;
	}
	return 0;
f010053b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100540:	c9                   	leave  
f0100541:	c3                   	ret    

f0100542 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f0100542:	55                   	push   %ebp
f0100543:	89 e5                	mov    %esp,%ebp
f0100545:	57                   	push   %edi
f0100546:	56                   	push   %esi
f0100547:	53                   	push   %ebx
f0100548:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f010054b:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100552:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100559:	5a a5 
	if (*cp != 0xA55A) {
f010055b:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100562:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100566:	74 11                	je     f0100579 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100568:	c7 05 50 25 11 f0 b4 	movl   $0x3b4,0xf0112550
f010056f:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100572:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100577:	eb 16                	jmp    f010058f <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100579:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100580:	c7 05 50 25 11 f0 d4 	movl   $0x3d4,0xf0112550
f0100587:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f010058a:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f010058f:	8b 3d 50 25 11 f0    	mov    0xf0112550,%edi
f0100595:	b8 0e 00 00 00       	mov    $0xe,%eax
f010059a:	89 fa                	mov    %edi,%edx
f010059c:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f010059d:	8d 4f 01             	lea    0x1(%edi),%ecx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005a0:	89 ca                	mov    %ecx,%edx
f01005a2:	ec                   	in     (%dx),%al
f01005a3:	0f b6 c0             	movzbl %al,%eax
f01005a6:	c1 e0 08             	shl    $0x8,%eax
f01005a9:	89 c3                	mov    %eax,%ebx
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005ab:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005b0:	89 fa                	mov    %edi,%edx
f01005b2:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005b3:	89 ca                	mov    %ecx,%edx
f01005b5:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005b6:	89 35 4c 25 11 f0    	mov    %esi,0xf011254c

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01005bc:	0f b6 c8             	movzbl %al,%ecx
f01005bf:	89 d8                	mov    %ebx,%eax
f01005c1:	09 c8                	or     %ecx,%eax

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01005c3:	66 a3 48 25 11 f0    	mov    %ax,0xf0112548
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005c9:	bb fa 03 00 00       	mov    $0x3fa,%ebx
f01005ce:	b8 00 00 00 00       	mov    $0x0,%eax
f01005d3:	89 da                	mov    %ebx,%edx
f01005d5:	ee                   	out    %al,(%dx)
f01005d6:	b2 fb                	mov    $0xfb,%dl
f01005d8:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005dd:	ee                   	out    %al,(%dx)
f01005de:	be f8 03 00 00       	mov    $0x3f8,%esi
f01005e3:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005e8:	89 f2                	mov    %esi,%edx
f01005ea:	ee                   	out    %al,(%dx)
f01005eb:	b2 f9                	mov    $0xf9,%dl
f01005ed:	b8 00 00 00 00       	mov    $0x0,%eax
f01005f2:	ee                   	out    %al,(%dx)
f01005f3:	b2 fb                	mov    $0xfb,%dl
f01005f5:	b8 03 00 00 00       	mov    $0x3,%eax
f01005fa:	ee                   	out    %al,(%dx)
f01005fb:	b2 fc                	mov    $0xfc,%dl
f01005fd:	b8 00 00 00 00       	mov    $0x0,%eax
f0100602:	ee                   	out    %al,(%dx)
f0100603:	b2 f9                	mov    $0xf9,%dl
f0100605:	b8 01 00 00 00       	mov    $0x1,%eax
f010060a:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010060b:	b2 fd                	mov    $0xfd,%dl
f010060d:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f010060e:	3c ff                	cmp    $0xff,%al
f0100610:	0f 95 c1             	setne  %cl
f0100613:	88 0d 54 25 11 f0    	mov    %cl,0xf0112554
f0100619:	89 da                	mov    %ebx,%edx
f010061b:	ec                   	in     (%dx),%al
f010061c:	89 f2                	mov    %esi,%edx
f010061e:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f010061f:	84 c9                	test   %cl,%cl
f0100621:	75 10                	jne    f0100633 <cons_init+0xf1>
		cprintf("Serial port does not exist!\n");
f0100623:	83 ec 0c             	sub    $0xc,%esp
f0100626:	68 90 1c 10 f0       	push   $0xf0101c90
f010062b:	e8 bd 03 00 00       	call   f01009ed <cprintf>
f0100630:	83 c4 10             	add    $0x10,%esp
}
f0100633:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100636:	5b                   	pop    %ebx
f0100637:	5e                   	pop    %esi
f0100638:	5f                   	pop    %edi
f0100639:	5d                   	pop    %ebp
f010063a:	c3                   	ret    

f010063b <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010063b:	55                   	push   %ebp
f010063c:	89 e5                	mov    %esp,%ebp
f010063e:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100641:	8b 45 08             	mov    0x8(%ebp),%eax
f0100644:	e8 99 fc ff ff       	call   f01002e2 <cons_putc>
}
f0100649:	c9                   	leave  
f010064a:	c3                   	ret    

f010064b <getchar>:

int
getchar(void)
{
f010064b:	55                   	push   %ebp
f010064c:	89 e5                	mov    %esp,%ebp
f010064e:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100651:	e8 a2 fe ff ff       	call   f01004f8 <cons_getc>
f0100656:	85 c0                	test   %eax,%eax
f0100658:	74 f7                	je     f0100651 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010065a:	c9                   	leave  
f010065b:	c3                   	ret    

f010065c <iscons>:

int
iscons(int fdnum)
{
f010065c:	55                   	push   %ebp
f010065d:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f010065f:	b8 01 00 00 00       	mov    $0x1,%eax
f0100664:	5d                   	pop    %ebp
f0100665:	c3                   	ret    

f0100666 <calca>:
};
#define NCOMMANDS (sizeof(commands)/sizeof(commands[0]))

/***** Implementations of basic kernel monitor commands *****/
int calca(int argc, char **argv, struct Trapframe *tf)
{
f0100666:	55                   	push   %ebp
f0100667:	89 e5                	mov    %esp,%ebp
f0100669:	83 ec 10             	sub    $0x10,%esp
//	return calculator() ;
return powerbase(10,1);
f010066c:	6a 01                	push   $0x1
f010066e:	6a 0a                	push   $0xa
f0100670:	e8 8b 11 00 00       	call   f0101800 <powerbase>

}
f0100675:	c9                   	leave  
f0100676:	c3                   	ret    

f0100677 <mon_help>:
}


int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100677:	55                   	push   %ebp
f0100678:	89 e5                	mov    %esp,%ebp
f010067a:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010067d:	68 00 1f 10 f0       	push   $0xf0101f00
f0100682:	68 1e 1f 10 f0       	push   $0xf0101f1e
f0100687:	68 23 1f 10 f0       	push   $0xf0101f23
f010068c:	e8 5c 03 00 00       	call   f01009ed <cprintf>
f0100691:	83 c4 0c             	add    $0xc,%esp
f0100694:	68 b0 1f 10 f0       	push   $0xf0101fb0
f0100699:	68 2c 1f 10 f0       	push   $0xf0101f2c
f010069e:	68 23 1f 10 f0       	push   $0xf0101f23
f01006a3:	e8 45 03 00 00       	call   f01009ed <cprintf>
f01006a8:	83 c4 0c             	add    $0xc,%esp
f01006ab:	68 d8 1f 10 f0       	push   $0xf0101fd8
f01006b0:	68 31 1f 10 f0       	push   $0xf0101f31
f01006b5:	68 23 1f 10 f0       	push   $0xf0101f23
f01006ba:	e8 2e 03 00 00       	call   f01009ed <cprintf>
	return 0;
}
f01006bf:	b8 00 00 00 00       	mov    $0x0,%eax
f01006c4:	c9                   	leave  
f01006c5:	c3                   	ret    

f01006c6 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006c6:	55                   	push   %ebp
f01006c7:	89 e5                	mov    %esp,%ebp
f01006c9:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006cc:	68 3a 1f 10 f0       	push   $0xf0101f3a
f01006d1:	e8 17 03 00 00       	call   f01009ed <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006d6:	83 c4 08             	add    $0x8,%esp
f01006d9:	68 0c 00 10 00       	push   $0x10000c
f01006de:	68 00 20 10 f0       	push   $0xf0102000
f01006e3:	e8 05 03 00 00       	call   f01009ed <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006e8:	83 c4 0c             	add    $0xc,%esp
f01006eb:	68 0c 00 10 00       	push   $0x10000c
f01006f0:	68 0c 00 10 f0       	push   $0xf010000c
f01006f5:	68 28 20 10 f0       	push   $0xf0102028
f01006fa:	e8 ee 02 00 00       	call   f01009ed <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006ff:	83 c4 0c             	add    $0xc,%esp
f0100702:	68 f5 1b 10 00       	push   $0x101bf5
f0100707:	68 f5 1b 10 f0       	push   $0xf0101bf5
f010070c:	68 4c 20 10 f0       	push   $0xf010204c
f0100711:	e8 d7 02 00 00       	call   f01009ed <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100716:	83 c4 0c             	add    $0xc,%esp
f0100719:	68 00 23 11 00       	push   $0x112300
f010071e:	68 00 23 11 f0       	push   $0xf0112300
f0100723:	68 70 20 10 f0       	push   $0xf0102070
f0100728:	e8 c0 02 00 00       	call   f01009ed <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010072d:	83 c4 0c             	add    $0xc,%esp
f0100730:	68 84 29 11 00       	push   $0x112984
f0100735:	68 84 29 11 f0       	push   $0xf0112984
f010073a:	68 94 20 10 f0       	push   $0xf0102094
f010073f:	e8 a9 02 00 00       	call   f01009ed <cprintf>
f0100744:	b8 83 2d 11 f0       	mov    $0xf0112d83,%eax
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100749:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f010074e:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f0100751:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100756:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010075c:	85 c0                	test   %eax,%eax
f010075e:	0f 48 c2             	cmovs  %edx,%eax
f0100761:	c1 f8 0a             	sar    $0xa,%eax
f0100764:	50                   	push   %eax
f0100765:	68 b8 20 10 f0       	push   $0xf01020b8
f010076a:	e8 7e 02 00 00       	call   f01009ed <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f010076f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100774:	c9                   	leave  
f0100775:	c3                   	ret    

f0100776 <second_lab>:

}

int
second_lab(int argc, char **argv, struct Trapframe *tf)
{
f0100776:	55                   	push   %ebp
f0100777:	89 e5                	mov    %esp,%ebp
f0100779:	83 ec 14             	sub    $0x14,%esp
	/// Yassin call his calculator here;
	char *in= NULL;
	char *out;
	out = readline(in);
f010077c:	6a 00                	push   $0x0
f010077e:	e8 1e 0c 00 00       	call   f01013a1 <readline>
	int i=0;
	float a=0;
	while (out+i)
f0100783:	83 c4 10             	add    $0x10,%esp
f0100786:	85 c0                	test   %eax,%eax
f0100788:	75 fc                	jne    f0100786 <second_lab+0x10>
			//operation or invalid argument
		}
		float a;
	}	
	return 0;
}
f010078a:	c9                   	leave  
f010078b:	c3                   	ret    

f010078c <first_lab>:

// First OS Lab

int
first_lab(int argc, char **argv, struct Trapframe *tf)
{
f010078c:	55                   	push   %ebp
f010078d:	89 e5                	mov    %esp,%ebp
f010078f:	57                   	push   %edi
f0100790:	56                   	push   %esi
f0100791:	53                   	push   %ebx
f0100792:	83 ec 28             	sub    $0x28,%esp
//		out=(char*)a;
///////////////////////////////////////// */
	char *in= NULL;
	char* arg;

	arg = readline(in);
f0100795:	6a 00                	push   $0x0
f0100797:	e8 05 0c 00 00       	call   f01013a1 <readline>
f010079c:	89 c3                	mov    %eax,%ebx
	int len=strlen(arg);
f010079e:	89 04 24             	mov    %eax,(%esp)
f01007a1:	e8 d4 0c 00 00       	call   f010147a <strlen>
f01007a6:	89 c7                	mov    %eax,%edi
	short neg = 0;
	int i=0;
	double a = 0;
	while (i<len)
f01007a8:	83 c4 10             	add    $0x10,%esp

	arg = readline(in);
	int len=strlen(arg);
	short neg = 0;
	int i=0;
	double a = 0;
f01007ab:	d9 ee                	fldz   
f01007ad:	dd 5d e0             	fstpl  -0x20(%ebp)
	char* arg;

	arg = readline(in);
	int len=strlen(arg);
	short neg = 0;
	int i=0;
f01007b0:	be 00 00 00 00       	mov    $0x0,%esi
	double a = 0;
	while (i<len)
f01007b5:	e9 90 00 00 00       	jmp    f010084a <first_lab+0xbe>
	{
		if (*(arg) == '.')
f01007ba:	0f b6 03             	movzbl (%ebx),%eax
f01007bd:	3c 2e                	cmp    $0x2e,%al
f01007bf:	75 2b                	jne    f01007ec <first_lab+0x60>
		{
//			after the point
			a = a + (*(arg+1) - '0') * 0.1;
			cprintf("entered val %f",a);
f01007c1:	83 ec 0c             	sub    $0xc,%esp
	while (i<len)
	{
		if (*(arg) == '.')
		{
//			after the point
			a = a + (*(arg+1) - '0') * 0.1;
f01007c4:	0f be 43 01          	movsbl 0x1(%ebx),%eax
f01007c8:	83 e8 30             	sub    $0x30,%eax
f01007cb:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01007ce:	db 45 dc             	fildl  -0x24(%ebp)
f01007d1:	dc 0d 68 21 10 f0    	fmull  0xf0102168
f01007d7:	dc 45 e0             	faddl  -0x20(%ebp)
			cprintf("entered val %f",a);
f01007da:	dd 1c 24             	fstpl  (%esp)
f01007dd:	68 53 1f 10 f0       	push   $0xf0101f53
f01007e2:	e8 06 02 00 00       	call   f01009ed <cprintf>
			return 0;
f01007e7:	83 c4 10             	add    $0x10,%esp
f01007ea:	eb 7c                	jmp    f0100868 <first_lab+0xdc>
		}
		if (*(arg)=='-')
f01007ec:	3c 2d                	cmp    $0x2d,%al
f01007ee:	74 17                	je     f0100807 <first_lab+0x7b>
		{
			neg = 1;
		}
		else if (*(arg) < '0' || (*(arg) > '9'))
f01007f0:	83 e8 30             	sub    $0x30,%eax
f01007f3:	3c 09                	cmp    $0x9,%al
f01007f5:	76 10                	jbe    f0100807 <first_lab+0x7b>
		{
			cprintf("Invalid Argument");
f01007f7:	83 ec 0c             	sub    $0xc,%esp
f01007fa:	68 62 1f 10 f0       	push   $0xf0101f62
f01007ff:	e8 e9 01 00 00       	call   f01009ed <cprintf>
f0100804:	83 c4 10             	add    $0x10,%esp
			//operation or invalid argument
		}
		// BUG: PowerBase has to be fixed
		// BUG: if power equals zero, the point disappears ?!
		a =  powerbase(10,len-i) / 10 * (*(arg) - '0') + a;
f0100807:	83 ec 08             	sub    $0x8,%esp
f010080a:	89 f8                	mov    %edi,%eax
f010080c:	89 f1                	mov    %esi,%ecx
f010080e:	29 c8                	sub    %ecx,%eax
f0100810:	0f be c0             	movsbl %al,%eax
f0100813:	50                   	push   %eax
f0100814:	6a 0a                	push   $0xa
f0100816:	e8 e5 0f 00 00       	call   f0101800 <powerbase>
f010081b:	89 c1                	mov    %eax,%ecx
f010081d:	b8 67 66 66 66       	mov    $0x66666667,%eax
f0100822:	f7 e9                	imul   %ecx
f0100824:	c1 fa 02             	sar    $0x2,%edx
f0100827:	c1 f9 1f             	sar    $0x1f,%ecx
f010082a:	29 ca                	sub    %ecx,%edx
f010082c:	0f be 03             	movsbl (%ebx),%eax
f010082f:	83 e8 30             	sub    $0x30,%eax
f0100832:	0f af d0             	imul   %eax,%edx
f0100835:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0100838:	db 45 dc             	fildl  -0x24(%ebp)
f010083b:	dc 45 e0             	faddl  -0x20(%ebp)
f010083e:	dd 5d e0             	fstpl  -0x20(%ebp)
		i++;
f0100841:	83 c6 01             	add    $0x1,%esi
		arg=arg+1;
f0100844:	83 c3 01             	add    $0x1,%ebx
f0100847:	83 c4 10             	add    $0x10,%esp
	arg = readline(in);
	int len=strlen(arg);
	short neg = 0;
	int i=0;
	double a = 0;
	while (i<len)
f010084a:	39 fe                	cmp    %edi,%esi
f010084c:	0f 8c 68 ff ff ff    	jl     f01007ba <first_lab+0x2e>
		a =  powerbase(10,len-i) / 10 * (*(arg) - '0') + a;
		i++;
		arg=arg+1;
	}

	cprintf("entered val %f",a);
f0100852:	83 ec 04             	sub    $0x4,%esp
f0100855:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100858:	ff 75 e0             	pushl  -0x20(%ebp)
f010085b:	68 53 1f 10 f0       	push   $0xf0101f53
f0100860:	e8 88 01 00 00       	call   f01009ed <cprintf>
	return 0;
f0100865:	83 c4 10             	add    $0x10,%esp
}
f0100868:	b8 00 00 00 00       	mov    $0x0,%eax
f010086d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100870:	5b                   	pop    %ebx
f0100871:	5e                   	pop    %esi
f0100872:	5f                   	pop    %edi
f0100873:	5d                   	pop    %ebp
f0100874:	c3                   	ret    

f0100875 <mon_backtrace>:
}


int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100875:	55                   	push   %ebp
f0100876:	89 e5                	mov    %esp,%ebp
	// Your code here.
	return 0;
}
f0100878:	b8 00 00 00 00       	mov    $0x0,%eax
f010087d:	5d                   	pop    %ebp
f010087e:	c3                   	ret    

f010087f <monitor>:
}


void
monitor(struct Trapframe *tf)
{
f010087f:	55                   	push   %ebp
f0100880:	89 e5                	mov    %esp,%ebp
f0100882:	57                   	push   %edi
f0100883:	56                   	push   %esi
f0100884:	53                   	push   %ebx
f0100885:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100888:	68 e4 20 10 f0       	push   $0xf01020e4
f010088d:	e8 5b 01 00 00       	call   f01009ed <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100892:	c7 04 24 08 21 10 f0 	movl   $0xf0102108,(%esp)
f0100899:	e8 4f 01 00 00       	call   f01009ed <cprintf>
f010089e:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f01008a1:	83 ec 0c             	sub    $0xc,%esp
f01008a4:	68 73 1f 10 f0       	push   $0xf0101f73
f01008a9:	e8 f3 0a 00 00       	call   f01013a1 <readline>
f01008ae:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01008b0:	83 c4 10             	add    $0x10,%esp
f01008b3:	85 c0                	test   %eax,%eax
f01008b5:	74 ea                	je     f01008a1 <monitor+0x22>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01008b7:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01008be:	be 00 00 00 00       	mov    $0x0,%esi
f01008c3:	eb 0a                	jmp    f01008cf <monitor+0x50>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01008c5:	c6 03 00             	movb   $0x0,(%ebx)
f01008c8:	89 f7                	mov    %esi,%edi
f01008ca:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01008cd:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01008cf:	0f b6 03             	movzbl (%ebx),%eax
f01008d2:	84 c0                	test   %al,%al
f01008d4:	74 63                	je     f0100939 <monitor+0xba>
f01008d6:	83 ec 08             	sub    $0x8,%esp
f01008d9:	0f be c0             	movsbl %al,%eax
f01008dc:	50                   	push   %eax
f01008dd:	68 77 1f 10 f0       	push   $0xf0101f77
f01008e2:	e8 d4 0c 00 00       	call   f01015bb <strchr>
f01008e7:	83 c4 10             	add    $0x10,%esp
f01008ea:	85 c0                	test   %eax,%eax
f01008ec:	75 d7                	jne    f01008c5 <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f01008ee:	80 3b 00             	cmpb   $0x0,(%ebx)
f01008f1:	74 46                	je     f0100939 <monitor+0xba>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01008f3:	83 fe 0f             	cmp    $0xf,%esi
f01008f6:	75 14                	jne    f010090c <monitor+0x8d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01008f8:	83 ec 08             	sub    $0x8,%esp
f01008fb:	6a 10                	push   $0x10
f01008fd:	68 7c 1f 10 f0       	push   $0xf0101f7c
f0100902:	e8 e6 00 00 00       	call   f01009ed <cprintf>
f0100907:	83 c4 10             	add    $0x10,%esp
f010090a:	eb 95                	jmp    f01008a1 <monitor+0x22>
			return 0;
		}
		argv[argc++] = buf;
f010090c:	8d 7e 01             	lea    0x1(%esi),%edi
f010090f:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100913:	eb 03                	jmp    f0100918 <monitor+0x99>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100915:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100918:	0f b6 03             	movzbl (%ebx),%eax
f010091b:	84 c0                	test   %al,%al
f010091d:	74 ae                	je     f01008cd <monitor+0x4e>
f010091f:	83 ec 08             	sub    $0x8,%esp
f0100922:	0f be c0             	movsbl %al,%eax
f0100925:	50                   	push   %eax
f0100926:	68 77 1f 10 f0       	push   $0xf0101f77
f010092b:	e8 8b 0c 00 00       	call   f01015bb <strchr>
f0100930:	83 c4 10             	add    $0x10,%esp
f0100933:	85 c0                	test   %eax,%eax
f0100935:	74 de                	je     f0100915 <monitor+0x96>
f0100937:	eb 94                	jmp    f01008cd <monitor+0x4e>
			buf++;
	}
	argv[argc] = 0;
f0100939:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100940:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100941:	85 f6                	test   %esi,%esi
f0100943:	0f 84 58 ff ff ff    	je     f01008a1 <monitor+0x22>
f0100949:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f010094e:	83 ec 08             	sub    $0x8,%esp
f0100951:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100954:	ff 34 85 40 21 10 f0 	pushl  -0xfefdec0(,%eax,4)
f010095b:	ff 75 a8             	pushl  -0x58(%ebp)
f010095e:	e8 fa 0b 00 00       	call   f010155d <strcmp>
f0100963:	83 c4 10             	add    $0x10,%esp
f0100966:	85 c0                	test   %eax,%eax
f0100968:	75 22                	jne    f010098c <monitor+0x10d>
			return commands[i].func(argc, argv, tf);
f010096a:	83 ec 04             	sub    $0x4,%esp
f010096d:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100970:	ff 75 08             	pushl  0x8(%ebp)
f0100973:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100976:	52                   	push   %edx
f0100977:	56                   	push   %esi
f0100978:	ff 14 85 48 21 10 f0 	call   *-0xfefdeb8(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f010097f:	83 c4 10             	add    $0x10,%esp
f0100982:	85 c0                	test   %eax,%eax
f0100984:	0f 89 17 ff ff ff    	jns    f01008a1 <monitor+0x22>
f010098a:	eb 20                	jmp    f01009ac <monitor+0x12d>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f010098c:	83 c3 01             	add    $0x1,%ebx
f010098f:	83 fb 03             	cmp    $0x3,%ebx
f0100992:	75 ba                	jne    f010094e <monitor+0xcf>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100994:	83 ec 08             	sub    $0x8,%esp
f0100997:	ff 75 a8             	pushl  -0x58(%ebp)
f010099a:	68 99 1f 10 f0       	push   $0xf0101f99
f010099f:	e8 49 00 00 00       	call   f01009ed <cprintf>
f01009a4:	83 c4 10             	add    $0x10,%esp
f01009a7:	e9 f5 fe ff ff       	jmp    f01008a1 <monitor+0x22>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01009ac:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01009af:	5b                   	pop    %ebx
f01009b0:	5e                   	pop    %esi
f01009b1:	5f                   	pop    %edi
f01009b2:	5d                   	pop    %ebp
f01009b3:	c3                   	ret    

f01009b4 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01009b4:	55                   	push   %ebp
f01009b5:	89 e5                	mov    %esp,%ebp
f01009b7:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f01009ba:	ff 75 08             	pushl  0x8(%ebp)
f01009bd:	e8 79 fc ff ff       	call   f010063b <cputchar>
f01009c2:	83 c4 10             	add    $0x10,%esp
	*cnt++;
}
f01009c5:	c9                   	leave  
f01009c6:	c3                   	ret    

f01009c7 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01009c7:	55                   	push   %ebp
f01009c8:	89 e5                	mov    %esp,%ebp
f01009ca:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f01009cd:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01009d4:	ff 75 0c             	pushl  0xc(%ebp)
f01009d7:	ff 75 08             	pushl  0x8(%ebp)
f01009da:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01009dd:	50                   	push   %eax
f01009de:	68 b4 09 10 f0       	push   $0xf01009b4
f01009e3:	e8 9b 04 00 00       	call   f0100e83 <vprintfmt>
	return cnt;
}
f01009e8:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01009eb:	c9                   	leave  
f01009ec:	c3                   	ret    

f01009ed <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01009ed:	55                   	push   %ebp
f01009ee:	89 e5                	mov    %esp,%ebp
f01009f0:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01009f3:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01009f6:	50                   	push   %eax
f01009f7:	ff 75 08             	pushl  0x8(%ebp)
f01009fa:	e8 c8 ff ff ff       	call   f01009c7 <vcprintf>
	va_end(ap);

	return cnt;
}
f01009ff:	c9                   	leave  
f0100a00:	c3                   	ret    

f0100a01 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100a01:	55                   	push   %ebp
f0100a02:	89 e5                	mov    %esp,%ebp
f0100a04:	57                   	push   %edi
f0100a05:	56                   	push   %esi
f0100a06:	53                   	push   %ebx
f0100a07:	83 ec 14             	sub    $0x14,%esp
f0100a0a:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0100a0d:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100a10:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100a13:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100a16:	8b 1a                	mov    (%edx),%ebx
f0100a18:	8b 01                	mov    (%ecx),%eax
f0100a1a:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a1d:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0100a24:	e9 88 00 00 00       	jmp    f0100ab1 <stab_binsearch+0xb0>
		int true_m = (l + r) / 2, m = true_m;
f0100a29:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100a2c:	01 d8                	add    %ebx,%eax
f0100a2e:	89 c6                	mov    %eax,%esi
f0100a30:	c1 ee 1f             	shr    $0x1f,%esi
f0100a33:	01 c6                	add    %eax,%esi
f0100a35:	d1 fe                	sar    %esi
f0100a37:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0100a3a:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100a3d:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0100a40:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a42:	eb 03                	jmp    f0100a47 <stab_binsearch+0x46>
			m--;
f0100a44:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a47:	39 c3                	cmp    %eax,%ebx
f0100a49:	7f 1f                	jg     f0100a6a <stab_binsearch+0x69>
f0100a4b:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0100a4f:	83 ea 0c             	sub    $0xc,%edx
f0100a52:	39 f9                	cmp    %edi,%ecx
f0100a54:	75 ee                	jne    f0100a44 <stab_binsearch+0x43>
f0100a56:	89 45 e8             	mov    %eax,-0x18(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100a59:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100a5c:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100a5f:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0100a63:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100a66:	76 18                	jbe    f0100a80 <stab_binsearch+0x7f>
f0100a68:	eb 05                	jmp    f0100a6f <stab_binsearch+0x6e>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100a6a:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0100a6d:	eb 42                	jmp    f0100ab1 <stab_binsearch+0xb0>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100a6f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100a72:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0100a74:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a77:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100a7e:	eb 31                	jmp    f0100ab1 <stab_binsearch+0xb0>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100a80:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100a83:	73 17                	jae    f0100a9c <stab_binsearch+0x9b>
			*region_right = m - 1;
f0100a85:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100a88:	83 e8 01             	sub    $0x1,%eax
f0100a8b:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a8e:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100a91:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a93:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100a9a:	eb 15                	jmp    f0100ab1 <stab_binsearch+0xb0>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100a9c:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100a9f:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100aa2:	89 1e                	mov    %ebx,(%esi)
			l = m;
			addr++;
f0100aa4:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0100aa8:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100aaa:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100ab1:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100ab4:	0f 8e 6f ff ff ff    	jle    f0100a29 <stab_binsearch+0x28>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100aba:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0100abe:	75 0f                	jne    f0100acf <stab_binsearch+0xce>
		*region_right = *region_left - 1;
f0100ac0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ac3:	8b 00                	mov    (%eax),%eax
f0100ac5:	83 e8 01             	sub    $0x1,%eax
f0100ac8:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100acb:	89 06                	mov    %eax,(%esi)
f0100acd:	eb 2c                	jmp    f0100afb <stab_binsearch+0xfa>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100acf:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ad2:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100ad4:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100ad7:	8b 0e                	mov    (%esi),%ecx
f0100ad9:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100adc:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0100adf:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100ae2:	eb 03                	jmp    f0100ae7 <stab_binsearch+0xe6>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100ae4:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100ae7:	39 c8                	cmp    %ecx,%eax
f0100ae9:	7e 0b                	jle    f0100af6 <stab_binsearch+0xf5>
		     l > *region_left && stabs[l].n_type != type;
f0100aeb:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0100aef:	83 ea 0c             	sub    $0xc,%edx
f0100af2:	39 fb                	cmp    %edi,%ebx
f0100af4:	75 ee                	jne    f0100ae4 <stab_binsearch+0xe3>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100af6:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100af9:	89 06                	mov    %eax,(%esi)
	}
}
f0100afb:	83 c4 14             	add    $0x14,%esp
f0100afe:	5b                   	pop    %ebx
f0100aff:	5e                   	pop    %esi
f0100b00:	5f                   	pop    %edi
f0100b01:	5d                   	pop    %ebp
f0100b02:	c3                   	ret    

f0100b03 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100b03:	55                   	push   %ebp
f0100b04:	89 e5                	mov    %esp,%ebp
f0100b06:	57                   	push   %edi
f0100b07:	56                   	push   %esi
f0100b08:	53                   	push   %ebx
f0100b09:	83 ec 1c             	sub    $0x1c,%esp
f0100b0c:	8b 7d 08             	mov    0x8(%ebp),%edi
f0100b0f:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100b12:	c7 06 70 21 10 f0    	movl   $0xf0102170,(%esi)
	info->eip_line = 0;
f0100b18:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0100b1f:	c7 46 08 70 21 10 f0 	movl   $0xf0102170,0x8(%esi)
	info->eip_fn_namelen = 9;
f0100b26:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f0100b2d:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0100b30:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100b37:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0100b3d:	76 11                	jbe    f0100b50 <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b3f:	b8 41 7d 10 f0       	mov    $0xf0107d41,%eax
f0100b44:	3d 1d 63 10 f0       	cmp    $0xf010631d,%eax
f0100b49:	77 19                	ja     f0100b64 <debuginfo_eip+0x61>
f0100b4b:	e9 4c 01 00 00       	jmp    f0100c9c <debuginfo_eip+0x199>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100b50:	83 ec 04             	sub    $0x4,%esp
f0100b53:	68 7a 21 10 f0       	push   $0xf010217a
f0100b58:	6a 7f                	push   $0x7f
f0100b5a:	68 87 21 10 f0       	push   $0xf0102187
f0100b5f:	e8 82 f5 ff ff       	call   f01000e6 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b64:	80 3d 40 7d 10 f0 00 	cmpb   $0x0,0xf0107d40
f0100b6b:	0f 85 32 01 00 00    	jne    f0100ca3 <debuginfo_eip+0x1a0>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100b71:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100b78:	b8 1c 63 10 f0       	mov    $0xf010631c,%eax
f0100b7d:	2d d4 23 10 f0       	sub    $0xf01023d4,%eax
f0100b82:	c1 f8 02             	sar    $0x2,%eax
f0100b85:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100b8b:	83 e8 01             	sub    $0x1,%eax
f0100b8e:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100b91:	83 ec 08             	sub    $0x8,%esp
f0100b94:	57                   	push   %edi
f0100b95:	6a 64                	push   $0x64
f0100b97:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100b9a:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100b9d:	b8 d4 23 10 f0       	mov    $0xf01023d4,%eax
f0100ba2:	e8 5a fe ff ff       	call   f0100a01 <stab_binsearch>
	if (lfile == 0)
f0100ba7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100baa:	83 c4 10             	add    $0x10,%esp
f0100bad:	85 c0                	test   %eax,%eax
f0100baf:	0f 84 f5 00 00 00    	je     f0100caa <debuginfo_eip+0x1a7>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100bb5:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100bb8:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100bbb:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100bbe:	83 ec 08             	sub    $0x8,%esp
f0100bc1:	57                   	push   %edi
f0100bc2:	6a 24                	push   $0x24
f0100bc4:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100bc7:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100bca:	b8 d4 23 10 f0       	mov    $0xf01023d4,%eax
f0100bcf:	e8 2d fe ff ff       	call   f0100a01 <stab_binsearch>

	if (lfun <= rfun) {
f0100bd4:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100bd7:	83 c4 10             	add    $0x10,%esp
f0100bda:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f0100bdd:	7f 31                	jg     f0100c10 <debuginfo_eip+0x10d>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100bdf:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100be2:	c1 e0 02             	shl    $0x2,%eax
f0100be5:	8d 90 d4 23 10 f0    	lea    -0xfefdc2c(%eax),%edx
f0100beb:	8b 88 d4 23 10 f0    	mov    -0xfefdc2c(%eax),%ecx
f0100bf1:	b8 41 7d 10 f0       	mov    $0xf0107d41,%eax
f0100bf6:	2d 1d 63 10 f0       	sub    $0xf010631d,%eax
f0100bfb:	39 c1                	cmp    %eax,%ecx
f0100bfd:	73 09                	jae    f0100c08 <debuginfo_eip+0x105>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100bff:	81 c1 1d 63 10 f0    	add    $0xf010631d,%ecx
f0100c05:	89 4e 08             	mov    %ecx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100c08:	8b 42 08             	mov    0x8(%edx),%eax
f0100c0b:	89 46 10             	mov    %eax,0x10(%esi)
f0100c0e:	eb 06                	jmp    f0100c16 <debuginfo_eip+0x113>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100c10:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0100c13:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100c16:	83 ec 08             	sub    $0x8,%esp
f0100c19:	6a 3a                	push   $0x3a
f0100c1b:	ff 76 08             	pushl  0x8(%esi)
f0100c1e:	e8 b9 09 00 00       	call   f01015dc <strfind>
f0100c23:	2b 46 08             	sub    0x8(%esi),%eax
f0100c26:	89 46 0c             	mov    %eax,0xc(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c29:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100c2c:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100c2f:	8d 04 85 d4 23 10 f0 	lea    -0xfefdc2c(,%eax,4),%eax
f0100c36:	83 c4 10             	add    $0x10,%esp
f0100c39:	eb 06                	jmp    f0100c41 <debuginfo_eip+0x13e>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100c3b:	83 eb 01             	sub    $0x1,%ebx
f0100c3e:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c41:	39 fb                	cmp    %edi,%ebx
f0100c43:	7c 1e                	jl     f0100c63 <debuginfo_eip+0x160>
	       && stabs[lline].n_type != N_SOL
f0100c45:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f0100c49:	80 fa 84             	cmp    $0x84,%dl
f0100c4c:	74 6a                	je     f0100cb8 <debuginfo_eip+0x1b5>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100c4e:	80 fa 64             	cmp    $0x64,%dl
f0100c51:	75 e8                	jne    f0100c3b <debuginfo_eip+0x138>
f0100c53:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0100c57:	74 e2                	je     f0100c3b <debuginfo_eip+0x138>
f0100c59:	eb 5d                	jmp    f0100cb8 <debuginfo_eip+0x1b5>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100c5b:	81 c2 1d 63 10 f0    	add    $0xf010631d,%edx
f0100c61:	89 16                	mov    %edx,(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c63:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100c66:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c69:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c6e:	39 cb                	cmp    %ecx,%ebx
f0100c70:	7d 60                	jge    f0100cd2 <debuginfo_eip+0x1cf>
		for (lline = lfun + 1;
f0100c72:	8d 53 01             	lea    0x1(%ebx),%edx
f0100c75:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100c78:	8d 04 85 d4 23 10 f0 	lea    -0xfefdc2c(,%eax,4),%eax
f0100c7f:	eb 07                	jmp    f0100c88 <debuginfo_eip+0x185>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100c81:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0100c85:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100c88:	39 ca                	cmp    %ecx,%edx
f0100c8a:	74 25                	je     f0100cb1 <debuginfo_eip+0x1ae>
f0100c8c:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100c8f:	80 78 04 a0          	cmpb   $0xa0,0x4(%eax)
f0100c93:	74 ec                	je     f0100c81 <debuginfo_eip+0x17e>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c95:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c9a:	eb 36                	jmp    f0100cd2 <debuginfo_eip+0x1cf>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100c9c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100ca1:	eb 2f                	jmp    f0100cd2 <debuginfo_eip+0x1cf>
f0100ca3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100ca8:	eb 28                	jmp    f0100cd2 <debuginfo_eip+0x1cf>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100caa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100caf:	eb 21                	jmp    f0100cd2 <debuginfo_eip+0x1cf>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100cb1:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cb6:	eb 1a                	jmp    f0100cd2 <debuginfo_eip+0x1cf>
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100cb8:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100cbb:	8b 14 85 d4 23 10 f0 	mov    -0xfefdc2c(,%eax,4),%edx
f0100cc2:	b8 41 7d 10 f0       	mov    $0xf0107d41,%eax
f0100cc7:	2d 1d 63 10 f0       	sub    $0xf010631d,%eax
f0100ccc:	39 c2                	cmp    %eax,%edx
f0100cce:	72 8b                	jb     f0100c5b <debuginfo_eip+0x158>
f0100cd0:	eb 91                	jmp    f0100c63 <debuginfo_eip+0x160>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
}
f0100cd2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100cd5:	5b                   	pop    %ebx
f0100cd6:	5e                   	pop    %esi
f0100cd7:	5f                   	pop    %edi
f0100cd8:	5d                   	pop    %ebp
f0100cd9:	c3                   	ret    

f0100cda <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100cda:	55                   	push   %ebp
f0100cdb:	89 e5                	mov    %esp,%ebp
f0100cdd:	57                   	push   %edi
f0100cde:	56                   	push   %esi
f0100cdf:	53                   	push   %ebx
f0100ce0:	83 ec 1c             	sub    $0x1c,%esp
f0100ce3:	89 c7                	mov    %eax,%edi
f0100ce5:	89 d6                	mov    %edx,%esi
f0100ce7:	8b 45 08             	mov    0x8(%ebp),%eax
f0100cea:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100ced:	89 d1                	mov    %edx,%ecx
f0100cef:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100cf2:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100cf5:	8b 45 10             	mov    0x10(%ebp),%eax
f0100cf8:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100cfb:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100cfe:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0100d05:	39 4d e4             	cmp    %ecx,-0x1c(%ebp)
f0100d08:	72 05                	jb     f0100d0f <printnum+0x35>
f0100d0a:	3b 45 d8             	cmp    -0x28(%ebp),%eax
f0100d0d:	77 3e                	ja     f0100d4d <printnum+0x73>
                               
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100d0f:	83 ec 0c             	sub    $0xc,%esp
f0100d12:	ff 75 18             	pushl  0x18(%ebp)
f0100d15:	83 eb 01             	sub    $0x1,%ebx
f0100d18:	53                   	push   %ebx
f0100d19:	50                   	push   %eax
f0100d1a:	83 ec 08             	sub    $0x8,%esp
f0100d1d:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100d20:	ff 75 e0             	pushl  -0x20(%ebp)
f0100d23:	ff 75 dc             	pushl  -0x24(%ebp)
f0100d26:	ff 75 d8             	pushl  -0x28(%ebp)
f0100d29:	e8 22 0c 00 00       	call   f0101950 <__udivdi3>
f0100d2e:	83 c4 18             	add    $0x18,%esp
f0100d31:	52                   	push   %edx
f0100d32:	50                   	push   %eax
f0100d33:	89 f2                	mov    %esi,%edx
f0100d35:	89 f8                	mov    %edi,%eax
f0100d37:	e8 9e ff ff ff       	call   f0100cda <printnum>
f0100d3c:	83 c4 20             	add    $0x20,%esp
f0100d3f:	eb 13                	jmp    f0100d54 <printnum+0x7a>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100d41:	83 ec 08             	sub    $0x8,%esp
f0100d44:	56                   	push   %esi
f0100d45:	ff 75 18             	pushl  0x18(%ebp)
f0100d48:	ff d7                	call   *%edi
f0100d4a:	83 c4 10             	add    $0x10,%esp
	if (num >= base) {
                               
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100d4d:	83 eb 01             	sub    $0x1,%ebx
f0100d50:	85 db                	test   %ebx,%ebx
f0100d52:	7f ed                	jg     f0100d41 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100d54:	83 ec 08             	sub    $0x8,%esp
f0100d57:	56                   	push   %esi
f0100d58:	83 ec 04             	sub    $0x4,%esp
f0100d5b:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100d5e:	ff 75 e0             	pushl  -0x20(%ebp)
f0100d61:	ff 75 dc             	pushl  -0x24(%ebp)
f0100d64:	ff 75 d8             	pushl  -0x28(%ebp)
f0100d67:	e8 14 0d 00 00       	call   f0101a80 <__umoddi3>
f0100d6c:	83 c4 14             	add    $0x14,%esp
f0100d6f:	0f be 80 95 21 10 f0 	movsbl -0xfefde6b(%eax),%eax
f0100d76:	50                   	push   %eax
f0100d77:	ff d7                	call   *%edi
f0100d79:	83 c4 10             	add    $0x10,%esp
       
}
f0100d7c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100d7f:	5b                   	pop    %ebx
f0100d80:	5e                   	pop    %esi
f0100d81:	5f                   	pop    %edi
f0100d82:	5d                   	pop    %ebp
f0100d83:	c3                   	ret    

f0100d84 <printnum2>:
static void
printnum2(void (*putch)(int, void*), void *putdat,
	 double num_float, unsigned base, int width, int padc)
{      
f0100d84:	55                   	push   %ebp
f0100d85:	89 e5                	mov    %esp,%ebp
f0100d87:	57                   	push   %edi
f0100d88:	56                   	push   %esi
f0100d89:	53                   	push   %ebx
f0100d8a:	83 ec 3c             	sub    $0x3c,%esp
f0100d8d:	89 c7                	mov    %eax,%edi
f0100d8f:	89 d6                	mov    %edx,%esi
f0100d91:	dd 45 08             	fldl   0x8(%ebp)
f0100d94:	dd 55 d0             	fstl   -0x30(%ebp)
f0100d97:	89 4d cc             	mov    %ecx,-0x34(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num_float >= base) { 
f0100d9a:	89 4d c0             	mov    %ecx,-0x40(%ebp)
f0100d9d:	c7 45 c4 00 00 00 00 	movl   $0x0,-0x3c(%ebp)
f0100da4:	df 6d c0             	fildll -0x40(%ebp)
f0100da7:	d9 c9                	fxch   %st(1)
f0100da9:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0100dac:	db e9                	fucomi %st(1),%st
f0100dae:	72 2d                	jb     f0100ddd <printnum2+0x59>
		printnum2(putch, putdat, num_float / base, base, width - 1, padc);
f0100db0:	ff 75 14             	pushl  0x14(%ebp)
f0100db3:	8b 45 10             	mov    0x10(%ebp),%eax
f0100db6:	83 e8 01             	sub    $0x1,%eax
f0100db9:	50                   	push   %eax
f0100dba:	de f1                	fdivp  %st,%st(1)
f0100dbc:	8d 64 24 f8          	lea    -0x8(%esp),%esp
f0100dc0:	dd 1c 24             	fstpl  (%esp)
f0100dc3:	89 f8                	mov    %edi,%eax
f0100dc5:	e8 ba ff ff ff       	call   f0100d84 <printnum2>
f0100dca:	83 c4 10             	add    $0x10,%esp
f0100dcd:	eb 2c                	jmp    f0100dfb <printnum2+0x77>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100dcf:	83 ec 08             	sub    $0x8,%esp
f0100dd2:	56                   	push   %esi
f0100dd3:	ff 75 14             	pushl  0x14(%ebp)
f0100dd6:	ff d7                	call   *%edi
f0100dd8:	83 c4 10             	add    $0x10,%esp
f0100ddb:	eb 04                	jmp    f0100de1 <printnum2+0x5d>
f0100ddd:	dd d8                	fstp   %st(0)
f0100ddf:	dd d8                	fstp   %st(0)
	// first recursively print all preceding (more significant) digits
	if (num_float >= base) { 
		printnum2(putch, putdat, num_float / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100de1:	83 eb 01             	sub    $0x1,%ebx
f0100de4:	85 db                	test   %ebx,%ebx
f0100de6:	7f e7                	jg     f0100dcf <printnum2+0x4b>
f0100de8:	8b 55 10             	mov    0x10(%ebp),%edx
f0100deb:	83 ea 01             	sub    $0x1,%edx
f0100dee:	b8 00 00 00 00       	mov    $0x0,%eax
f0100df3:	0f 49 c2             	cmovns %edx,%eax
f0100df6:	29 c2                	sub    %eax,%edx
f0100df8:	89 55 10             	mov    %edx,0x10(%ebp)
			putch(padc, putdat);
	}
        int x =(int)num_float;
	// then print this (the least significant) digit
	putch("0123456789abcdef"[x % base], putdat);
f0100dfb:	83 ec 08             	sub    $0x8,%esp
f0100dfe:	56                   	push   %esi
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
	}
        int x =(int)num_float;
f0100dff:	d9 7d de             	fnstcw -0x22(%ebp)
f0100e02:	0f b7 45 de          	movzwl -0x22(%ebp),%eax
f0100e06:	b4 0c                	mov    $0xc,%ah
f0100e08:	66 89 45 dc          	mov    %ax,-0x24(%ebp)
f0100e0c:	dd 45 d0             	fldl   -0x30(%ebp)
f0100e0f:	d9 6d dc             	fldcw  -0x24(%ebp)
f0100e12:	db 5d d8             	fistpl -0x28(%ebp)
f0100e15:	d9 6d de             	fldcw  -0x22(%ebp)
f0100e18:	8b 45 d8             	mov    -0x28(%ebp),%eax
	// then print this (the least significant) digit
	putch("0123456789abcdef"[x % base], putdat);
f0100e1b:	ba 00 00 00 00       	mov    $0x0,%edx
f0100e20:	f7 75 cc             	divl   -0x34(%ebp)
f0100e23:	0f be 82 95 21 10 f0 	movsbl -0xfefde6b(%edx),%eax
f0100e2a:	50                   	push   %eax
f0100e2b:	ff d7                	call   *%edi
        if ( width == -3) {
f0100e2d:	83 c4 10             	add    $0x10,%esp
f0100e30:	83 7d 10 fd          	cmpl   $0xfffffffd,0x10(%ebp)
f0100e34:	75 0b                	jne    f0100e41 <printnum2+0xbd>
        putch('.',putdat);}
f0100e36:	83 ec 08             	sub    $0x8,%esp
f0100e39:	56                   	push   %esi
f0100e3a:	6a 2e                	push   $0x2e
f0100e3c:	ff d7                	call   *%edi
f0100e3e:	83 c4 10             	add    $0x10,%esp
}
f0100e41:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e44:	5b                   	pop    %ebx
f0100e45:	5e                   	pop    %esi
f0100e46:	5f                   	pop    %edi
f0100e47:	5d                   	pop    %ebp
f0100e48:	c3                   	ret    

f0100e49 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100e49:	55                   	push   %ebp
f0100e4a:	89 e5                	mov    %esp,%ebp
f0100e4c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100e4f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100e53:	8b 10                	mov    (%eax),%edx
f0100e55:	3b 50 04             	cmp    0x4(%eax),%edx
f0100e58:	73 0a                	jae    f0100e64 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100e5a:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100e5d:	89 08                	mov    %ecx,(%eax)
f0100e5f:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e62:	88 02                	mov    %al,(%edx)
}
f0100e64:	5d                   	pop    %ebp
f0100e65:	c3                   	ret    

f0100e66 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100e66:	55                   	push   %ebp
f0100e67:	89 e5                	mov    %esp,%ebp
f0100e69:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100e6c:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100e6f:	50                   	push   %eax
f0100e70:	ff 75 10             	pushl  0x10(%ebp)
f0100e73:	ff 75 0c             	pushl  0xc(%ebp)
f0100e76:	ff 75 08             	pushl  0x8(%ebp)
f0100e79:	e8 05 00 00 00       	call   f0100e83 <vprintfmt>
	va_end(ap);
f0100e7e:	83 c4 10             	add    $0x10,%esp
}
f0100e81:	c9                   	leave  
f0100e82:	c3                   	ret    

f0100e83 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100e83:	55                   	push   %ebp
f0100e84:	89 e5                	mov    %esp,%ebp
f0100e86:	57                   	push   %edi
f0100e87:	56                   	push   %esi
f0100e88:	53                   	push   %ebx
f0100e89:	83 ec 2c             	sub    $0x2c,%esp
f0100e8c:	8b 75 08             	mov    0x8(%ebp),%esi
f0100e8f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100e92:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100e95:	eb 12                	jmp    f0100ea9 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100e97:	85 c0                	test   %eax,%eax
f0100e99:	0f 84 92 04 00 00    	je     f0101331 <vprintfmt+0x4ae>
				return;
			putch(ch, putdat);
f0100e9f:	83 ec 08             	sub    $0x8,%esp
f0100ea2:	53                   	push   %ebx
f0100ea3:	50                   	push   %eax
f0100ea4:	ff d6                	call   *%esi
f0100ea6:	83 c4 10             	add    $0x10,%esp
        double num_float;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100ea9:	83 c7 01             	add    $0x1,%edi
f0100eac:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0100eb0:	83 f8 25             	cmp    $0x25,%eax
f0100eb3:	75 e2                	jne    f0100e97 <vprintfmt+0x14>
f0100eb5:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0100eb9:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100ec0:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100ec7:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0100ece:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100ed3:	eb 07                	jmp    f0100edc <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ed5:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100ed8:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100edc:	8d 47 01             	lea    0x1(%edi),%eax
f0100edf:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100ee2:	0f b6 07             	movzbl (%edi),%eax
f0100ee5:	0f b6 d0             	movzbl %al,%edx
f0100ee8:	83 e8 23             	sub    $0x23,%eax
f0100eeb:	3c 55                	cmp    $0x55,%al
f0100eed:	0f 87 23 04 00 00    	ja     f0101316 <vprintfmt+0x493>
f0100ef3:	0f b6 c0             	movzbl %al,%eax
f0100ef6:	ff 24 85 40 22 10 f0 	jmp    *-0xfefddc0(,%eax,4)
f0100efd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100f00:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0100f04:	eb d6                	jmp    f0100edc <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f06:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100f09:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f0e:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100f11:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100f14:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0100f18:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0100f1b:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0100f1e:	83 f9 09             	cmp    $0x9,%ecx
f0100f21:	77 3f                	ja     f0100f62 <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100f23:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0100f26:	eb e9                	jmp    f0100f11 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100f28:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f2b:	8b 00                	mov    (%eax),%eax
f0100f2d:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100f30:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f33:	8d 40 04             	lea    0x4(%eax),%eax
f0100f36:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f39:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100f3c:	eb 2a                	jmp    f0100f68 <vprintfmt+0xe5>
f0100f3e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100f41:	85 c0                	test   %eax,%eax
f0100f43:	ba 00 00 00 00       	mov    $0x0,%edx
f0100f48:	0f 49 d0             	cmovns %eax,%edx
f0100f4b:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f4e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100f51:	eb 89                	jmp    f0100edc <vprintfmt+0x59>
f0100f53:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100f56:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0100f5d:	e9 7a ff ff ff       	jmp    f0100edc <vprintfmt+0x59>
f0100f62:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100f65:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0100f68:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100f6c:	0f 89 6a ff ff ff    	jns    f0100edc <vprintfmt+0x59>
				width = precision, precision = -1;
f0100f72:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100f75:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100f78:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100f7f:	e9 58 ff ff ff       	jmp    f0100edc <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100f84:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f87:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100f8a:	e9 4d ff ff ff       	jmp    f0100edc <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f8f:	8b 45 14             	mov    0x14(%ebp),%eax
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100f92:	83 45 14 04          	addl   $0x4,0x14(%ebp)
f0100f96:	83 ec 08             	sub    $0x8,%esp
f0100f99:	53                   	push   %ebx
f0100f9a:	ff 30                	pushl  (%eax)
f0100f9c:	ff d6                	call   *%esi
			break;
f0100f9e:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fa1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0100fa4:	e9 00 ff ff ff       	jmp    f0100ea9 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100fa9:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fac:	8d 78 04             	lea    0x4(%eax),%edi
f0100faf:	8b 00                	mov    (%eax),%eax
f0100fb1:	99                   	cltd   
f0100fb2:	31 d0                	xor    %edx,%eax
f0100fb4:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100fb6:	83 f8 07             	cmp    $0x7,%eax
f0100fb9:	7f 0b                	jg     f0100fc6 <vprintfmt+0x143>
f0100fbb:	8b 14 85 a0 23 10 f0 	mov    -0xfefdc60(,%eax,4),%edx
f0100fc2:	85 d2                	test   %edx,%edx
f0100fc4:	75 1b                	jne    f0100fe1 <vprintfmt+0x15e>
				printfmt(putch, putdat, "error %d", err);
f0100fc6:	50                   	push   %eax
f0100fc7:	68 ad 21 10 f0       	push   $0xf01021ad
f0100fcc:	53                   	push   %ebx
f0100fcd:	56                   	push   %esi
f0100fce:	e8 93 fe ff ff       	call   f0100e66 <printfmt>
f0100fd3:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100fd6:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fd9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0100fdc:	e9 c8 fe ff ff       	jmp    f0100ea9 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0100fe1:	52                   	push   %edx
f0100fe2:	68 b6 21 10 f0       	push   $0xf01021b6
f0100fe7:	53                   	push   %ebx
f0100fe8:	56                   	push   %esi
f0100fe9:	e8 78 fe ff ff       	call   f0100e66 <printfmt>
f0100fee:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100ff1:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ff4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100ff7:	e9 ad fe ff ff       	jmp    f0100ea9 <vprintfmt+0x26>
f0100ffc:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fff:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0101002:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0101005:	89 4d cc             	mov    %ecx,-0x34(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0101008:	83 45 14 04          	addl   $0x4,0x14(%ebp)
f010100c:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f010100e:	85 ff                	test   %edi,%edi
f0101010:	b8 a6 21 10 f0       	mov    $0xf01021a6,%eax
f0101015:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0101018:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f010101c:	0f 84 90 00 00 00    	je     f01010b2 <vprintfmt+0x22f>
f0101022:	85 c9                	test   %ecx,%ecx
f0101024:	0f 8e 96 00 00 00    	jle    f01010c0 <vprintfmt+0x23d>
				for (width -= strnlen(p, precision); width > 0; width--)
f010102a:	83 ec 08             	sub    $0x8,%esp
f010102d:	52                   	push   %edx
f010102e:	57                   	push   %edi
f010102f:	e8 5e 04 00 00       	call   f0101492 <strnlen>
f0101034:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0101037:	29 c1                	sub    %eax,%ecx
f0101039:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f010103c:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f010103f:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0101043:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101046:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0101049:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010104b:	eb 0f                	jmp    f010105c <vprintfmt+0x1d9>
					putch(padc, putdat);
f010104d:	83 ec 08             	sub    $0x8,%esp
f0101050:	53                   	push   %ebx
f0101051:	ff 75 e0             	pushl  -0x20(%ebp)
f0101054:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101056:	83 ef 01             	sub    $0x1,%edi
f0101059:	83 c4 10             	add    $0x10,%esp
f010105c:	85 ff                	test   %edi,%edi
f010105e:	7f ed                	jg     f010104d <vprintfmt+0x1ca>
f0101060:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101063:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0101066:	85 c9                	test   %ecx,%ecx
f0101068:	b8 00 00 00 00       	mov    $0x0,%eax
f010106d:	0f 49 c1             	cmovns %ecx,%eax
f0101070:	29 c1                	sub    %eax,%ecx
f0101072:	89 75 08             	mov    %esi,0x8(%ebp)
f0101075:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101078:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010107b:	89 cb                	mov    %ecx,%ebx
f010107d:	eb 4d                	jmp    f01010cc <vprintfmt+0x249>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f010107f:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0101083:	74 1b                	je     f01010a0 <vprintfmt+0x21d>
f0101085:	0f be c0             	movsbl %al,%eax
f0101088:	83 e8 20             	sub    $0x20,%eax
f010108b:	83 f8 5e             	cmp    $0x5e,%eax
f010108e:	76 10                	jbe    f01010a0 <vprintfmt+0x21d>
					putch('?', putdat);
f0101090:	83 ec 08             	sub    $0x8,%esp
f0101093:	ff 75 0c             	pushl  0xc(%ebp)
f0101096:	6a 3f                	push   $0x3f
f0101098:	ff 55 08             	call   *0x8(%ebp)
f010109b:	83 c4 10             	add    $0x10,%esp
f010109e:	eb 0d                	jmp    f01010ad <vprintfmt+0x22a>
				else
					putch(ch, putdat);
f01010a0:	83 ec 08             	sub    $0x8,%esp
f01010a3:	ff 75 0c             	pushl  0xc(%ebp)
f01010a6:	52                   	push   %edx
f01010a7:	ff 55 08             	call   *0x8(%ebp)
f01010aa:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01010ad:	83 eb 01             	sub    $0x1,%ebx
f01010b0:	eb 1a                	jmp    f01010cc <vprintfmt+0x249>
f01010b2:	89 75 08             	mov    %esi,0x8(%ebp)
f01010b5:	8b 75 d0             	mov    -0x30(%ebp),%esi
f01010b8:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01010bb:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f01010be:	eb 0c                	jmp    f01010cc <vprintfmt+0x249>
f01010c0:	89 75 08             	mov    %esi,0x8(%ebp)
f01010c3:	8b 75 d0             	mov    -0x30(%ebp),%esi
f01010c6:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01010c9:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f01010cc:	83 c7 01             	add    $0x1,%edi
f01010cf:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f01010d3:	0f be d0             	movsbl %al,%edx
f01010d6:	85 d2                	test   %edx,%edx
f01010d8:	74 23                	je     f01010fd <vprintfmt+0x27a>
f01010da:	85 f6                	test   %esi,%esi
f01010dc:	78 a1                	js     f010107f <vprintfmt+0x1fc>
f01010de:	83 ee 01             	sub    $0x1,%esi
f01010e1:	79 9c                	jns    f010107f <vprintfmt+0x1fc>
f01010e3:	89 df                	mov    %ebx,%edi
f01010e5:	8b 75 08             	mov    0x8(%ebp),%esi
f01010e8:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01010eb:	eb 18                	jmp    f0101105 <vprintfmt+0x282>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01010ed:	83 ec 08             	sub    $0x8,%esp
f01010f0:	53                   	push   %ebx
f01010f1:	6a 20                	push   $0x20
f01010f3:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01010f5:	83 ef 01             	sub    $0x1,%edi
f01010f8:	83 c4 10             	add    $0x10,%esp
f01010fb:	eb 08                	jmp    f0101105 <vprintfmt+0x282>
f01010fd:	89 df                	mov    %ebx,%edi
f01010ff:	8b 75 08             	mov    0x8(%ebp),%esi
f0101102:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101105:	85 ff                	test   %edi,%edi
f0101107:	7f e4                	jg     f01010ed <vprintfmt+0x26a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101109:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010110c:	e9 98 fd ff ff       	jmp    f0100ea9 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101111:	83 f9 01             	cmp    $0x1,%ecx
f0101114:	7e 19                	jle    f010112f <vprintfmt+0x2ac>
		return va_arg(*ap, long long);
f0101116:	8b 45 14             	mov    0x14(%ebp),%eax
f0101119:	8b 50 04             	mov    0x4(%eax),%edx
f010111c:	8b 00                	mov    (%eax),%eax
f010111e:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101121:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101124:	8b 45 14             	mov    0x14(%ebp),%eax
f0101127:	8d 40 08             	lea    0x8(%eax),%eax
f010112a:	89 45 14             	mov    %eax,0x14(%ebp)
f010112d:	eb 38                	jmp    f0101167 <vprintfmt+0x2e4>
	else if (lflag)
f010112f:	85 c9                	test   %ecx,%ecx
f0101131:	74 1b                	je     f010114e <vprintfmt+0x2cb>
		return va_arg(*ap, long);
f0101133:	8b 45 14             	mov    0x14(%ebp),%eax
f0101136:	8b 00                	mov    (%eax),%eax
f0101138:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010113b:	89 c1                	mov    %eax,%ecx
f010113d:	c1 f9 1f             	sar    $0x1f,%ecx
f0101140:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0101143:	8b 45 14             	mov    0x14(%ebp),%eax
f0101146:	8d 40 04             	lea    0x4(%eax),%eax
f0101149:	89 45 14             	mov    %eax,0x14(%ebp)
f010114c:	eb 19                	jmp    f0101167 <vprintfmt+0x2e4>
	else
		return va_arg(*ap, int);
f010114e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101151:	8b 00                	mov    (%eax),%eax
f0101153:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101156:	89 c1                	mov    %eax,%ecx
f0101158:	c1 f9 1f             	sar    $0x1f,%ecx
f010115b:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f010115e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101161:	8d 40 04             	lea    0x4(%eax),%eax
f0101164:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0101167:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010116a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f010116d:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0101172:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0101176:	0f 89 66 01 00 00    	jns    f01012e2 <vprintfmt+0x45f>
				putch('-', putdat);
f010117c:	83 ec 08             	sub    $0x8,%esp
f010117f:	53                   	push   %ebx
f0101180:	6a 2d                	push   $0x2d
f0101182:	ff d6                	call   *%esi
				num = -(long long) num;
f0101184:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101187:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010118a:	f7 da                	neg    %edx
f010118c:	83 d1 00             	adc    $0x0,%ecx
f010118f:	f7 d9                	neg    %ecx
f0101191:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0101194:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101199:	e9 44 01 00 00       	jmp    f01012e2 <vprintfmt+0x45f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f010119e:	83 f9 01             	cmp    $0x1,%ecx
f01011a1:	7e 18                	jle    f01011bb <vprintfmt+0x338>
		return va_arg(*ap, unsigned long long);
f01011a3:	8b 45 14             	mov    0x14(%ebp),%eax
f01011a6:	8b 10                	mov    (%eax),%edx
f01011a8:	8b 48 04             	mov    0x4(%eax),%ecx
f01011ab:	8d 40 08             	lea    0x8(%eax),%eax
f01011ae:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f01011b1:	b8 0a 00 00 00       	mov    $0xa,%eax
f01011b6:	e9 27 01 00 00       	jmp    f01012e2 <vprintfmt+0x45f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f01011bb:	85 c9                	test   %ecx,%ecx
f01011bd:	74 1a                	je     f01011d9 <vprintfmt+0x356>
		return va_arg(*ap, unsigned long);
f01011bf:	8b 45 14             	mov    0x14(%ebp),%eax
f01011c2:	8b 10                	mov    (%eax),%edx
f01011c4:	b9 00 00 00 00       	mov    $0x0,%ecx
f01011c9:	8d 40 04             	lea    0x4(%eax),%eax
f01011cc:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f01011cf:	b8 0a 00 00 00       	mov    $0xa,%eax
f01011d4:	e9 09 01 00 00       	jmp    f01012e2 <vprintfmt+0x45f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f01011d9:	8b 45 14             	mov    0x14(%ebp),%eax
f01011dc:	8b 10                	mov    (%eax),%edx
f01011de:	b9 00 00 00 00       	mov    $0x0,%ecx
f01011e3:	8d 40 04             	lea    0x4(%eax),%eax
f01011e6:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f01011e9:	b8 0a 00 00 00       	mov    $0xa,%eax
f01011ee:	e9 ef 00 00 00       	jmp    f01012e2 <vprintfmt+0x45f>
			goto number;

               // signed float
		case 'f':
			num_float = va_arg(ap, double);
f01011f3:	8b 45 14             	mov    0x14(%ebp),%eax
f01011f6:	8d 78 08             	lea    0x8(%eax),%edi
                        num_float = num_float*100;
f01011f9:	d9 05 c0 23 10 f0    	flds   0xf01023c0
f01011ff:	dc 08                	fmull  (%eax)
f0101201:	d9 c0                	fld    %st(0)
f0101203:	dd 5d d8             	fstpl  -0x28(%ebp)
			if ( num_float < 0) {
f0101206:	d9 ee                	fldz   
f0101208:	df e9                	fucomip %st(1),%st
f010120a:	dd d8                	fstp   %st(0)
f010120c:	76 13                	jbe    f0101221 <vprintfmt+0x39e>
				putch('-', putdat);
f010120e:	83 ec 08             	sub    $0x8,%esp
f0101211:	53                   	push   %ebx
f0101212:	6a 2d                	push   $0x2d
f0101214:	ff d6                	call   *%esi
				num_float = - num_float;
f0101216:	dd 45 d8             	fldl   -0x28(%ebp)
f0101219:	d9 e0                	fchs   
f010121b:	dd 5d d8             	fstpl  -0x28(%ebp)
f010121e:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
                        
			printnum2(putch, putdat, num_float, base, width, padc);
f0101221:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0101225:	50                   	push   %eax
f0101226:	ff 75 e0             	pushl  -0x20(%ebp)
f0101229:	ff 75 dc             	pushl  -0x24(%ebp)
f010122c:	ff 75 d8             	pushl  -0x28(%ebp)
f010122f:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0101234:	89 da                	mov    %ebx,%edx
f0101236:	89 f0                	mov    %esi,%eax
f0101238:	e8 47 fb ff ff       	call   f0100d84 <printnum2>
			break;
f010123d:	83 c4 10             	add    $0x10,%esp
			base = 10;
			goto number;

               // signed float
		case 'f':
			num_float = va_arg(ap, double);
f0101240:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101243:	8b 7d e4             	mov    -0x1c(%ebp),%edi
				num_float = - num_float;
			}
			base = 10;
                        
			printnum2(putch, putdat, num_float, base, width, padc);
			break;
f0101246:	e9 5e fc ff ff       	jmp    f0100ea9 <vprintfmt+0x26>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f010124b:	83 ec 08             	sub    $0x8,%esp
f010124e:	53                   	push   %ebx
f010124f:	6a 58                	push   $0x58
f0101251:	ff d6                	call   *%esi
			putch('X', putdat);
f0101253:	83 c4 08             	add    $0x8,%esp
f0101256:	53                   	push   %ebx
f0101257:	6a 58                	push   $0x58
f0101259:	ff d6                	call   *%esi
			putch('X', putdat);
f010125b:	83 c4 08             	add    $0x8,%esp
f010125e:	53                   	push   %ebx
f010125f:	6a 58                	push   $0x58
f0101261:	ff d6                	call   *%esi
			break;
f0101263:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101266:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
f0101269:	e9 3b fc ff ff       	jmp    f0100ea9 <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
f010126e:	83 ec 08             	sub    $0x8,%esp
f0101271:	53                   	push   %ebx
f0101272:	6a 30                	push   $0x30
f0101274:	ff d6                	call   *%esi
			putch('x', putdat);
f0101276:	83 c4 08             	add    $0x8,%esp
f0101279:	53                   	push   %ebx
f010127a:	6a 78                	push   $0x78
f010127c:	ff d6                	call   *%esi
			num = (unsigned long long)
f010127e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101281:	8b 10                	mov    (%eax),%edx
f0101283:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0101288:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010128b:	8d 40 04             	lea    0x4(%eax),%eax
f010128e:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101291:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0101296:	eb 4a                	jmp    f01012e2 <vprintfmt+0x45f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101298:	83 f9 01             	cmp    $0x1,%ecx
f010129b:	7e 15                	jle    f01012b2 <vprintfmt+0x42f>
		return va_arg(*ap, unsigned long long);
f010129d:	8b 45 14             	mov    0x14(%ebp),%eax
f01012a0:	8b 10                	mov    (%eax),%edx
f01012a2:	8b 48 04             	mov    0x4(%eax),%ecx
f01012a5:	8d 40 08             	lea    0x8(%eax),%eax
f01012a8:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f01012ab:	b8 10 00 00 00       	mov    $0x10,%eax
f01012b0:	eb 30                	jmp    f01012e2 <vprintfmt+0x45f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f01012b2:	85 c9                	test   %ecx,%ecx
f01012b4:	74 17                	je     f01012cd <vprintfmt+0x44a>
		return va_arg(*ap, unsigned long);
f01012b6:	8b 45 14             	mov    0x14(%ebp),%eax
f01012b9:	8b 10                	mov    (%eax),%edx
f01012bb:	b9 00 00 00 00       	mov    $0x0,%ecx
f01012c0:	8d 40 04             	lea    0x4(%eax),%eax
f01012c3:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f01012c6:	b8 10 00 00 00       	mov    $0x10,%eax
f01012cb:	eb 15                	jmp    f01012e2 <vprintfmt+0x45f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f01012cd:	8b 45 14             	mov    0x14(%ebp),%eax
f01012d0:	8b 10                	mov    (%eax),%edx
f01012d2:	b9 00 00 00 00       	mov    $0x0,%ecx
f01012d7:	8d 40 04             	lea    0x4(%eax),%eax
f01012da:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f01012dd:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f01012e2:	83 ec 0c             	sub    $0xc,%esp
f01012e5:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f01012e9:	57                   	push   %edi
f01012ea:	ff 75 e0             	pushl  -0x20(%ebp)
f01012ed:	50                   	push   %eax
f01012ee:	51                   	push   %ecx
f01012ef:	52                   	push   %edx
f01012f0:	89 da                	mov    %ebx,%edx
f01012f2:	89 f0                	mov    %esi,%eax
f01012f4:	e8 e1 f9 ff ff       	call   f0100cda <printnum>
			break;
f01012f9:	83 c4 20             	add    $0x20,%esp
f01012fc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01012ff:	e9 a5 fb ff ff       	jmp    f0100ea9 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0101304:	83 ec 08             	sub    $0x8,%esp
f0101307:	53                   	push   %ebx
f0101308:	52                   	push   %edx
f0101309:	ff d6                	call   *%esi
			break;
f010130b:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010130e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0101311:	e9 93 fb ff ff       	jmp    f0100ea9 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0101316:	83 ec 08             	sub    $0x8,%esp
f0101319:	53                   	push   %ebx
f010131a:	6a 25                	push   $0x25
f010131c:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f010131e:	83 c4 10             	add    $0x10,%esp
f0101321:	eb 03                	jmp    f0101326 <vprintfmt+0x4a3>
f0101323:	83 ef 01             	sub    $0x1,%edi
f0101326:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f010132a:	75 f7                	jne    f0101323 <vprintfmt+0x4a0>
f010132c:	e9 78 fb ff ff       	jmp    f0100ea9 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0101331:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101334:	5b                   	pop    %ebx
f0101335:	5e                   	pop    %esi
f0101336:	5f                   	pop    %edi
f0101337:	5d                   	pop    %ebp
f0101338:	c3                   	ret    

f0101339 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101339:	55                   	push   %ebp
f010133a:	89 e5                	mov    %esp,%ebp
f010133c:	83 ec 18             	sub    $0x18,%esp
f010133f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101342:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101345:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101348:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f010134c:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010134f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101356:	85 c0                	test   %eax,%eax
f0101358:	74 26                	je     f0101380 <vsnprintf+0x47>
f010135a:	85 d2                	test   %edx,%edx
f010135c:	7e 22                	jle    f0101380 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f010135e:	ff 75 14             	pushl  0x14(%ebp)
f0101361:	ff 75 10             	pushl  0x10(%ebp)
f0101364:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101367:	50                   	push   %eax
f0101368:	68 49 0e 10 f0       	push   $0xf0100e49
f010136d:	e8 11 fb ff ff       	call   f0100e83 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101372:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101375:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101378:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010137b:	83 c4 10             	add    $0x10,%esp
f010137e:	eb 05                	jmp    f0101385 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0101380:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0101385:	c9                   	leave  
f0101386:	c3                   	ret    

f0101387 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0101387:	55                   	push   %ebp
f0101388:	89 e5                	mov    %esp,%ebp
f010138a:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f010138d:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101390:	50                   	push   %eax
f0101391:	ff 75 10             	pushl  0x10(%ebp)
f0101394:	ff 75 0c             	pushl  0xc(%ebp)
f0101397:	ff 75 08             	pushl  0x8(%ebp)
f010139a:	e8 9a ff ff ff       	call   f0101339 <vsnprintf>
	va_end(ap);

	return rc;
f010139f:	c9                   	leave  
f01013a0:	c3                   	ret    

f01013a1 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01013a1:	55                   	push   %ebp
f01013a2:	89 e5                	mov    %esp,%ebp
f01013a4:	57                   	push   %edi
f01013a5:	56                   	push   %esi
f01013a6:	53                   	push   %ebx
f01013a7:	83 ec 0c             	sub    $0xc,%esp
f01013aa:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01013ad:	85 c0                	test   %eax,%eax
f01013af:	74 11                	je     f01013c2 <readline+0x21>
		cprintf("%s", prompt);
f01013b1:	83 ec 08             	sub    $0x8,%esp
f01013b4:	50                   	push   %eax
f01013b5:	68 b6 21 10 f0       	push   $0xf01021b6
f01013ba:	e8 2e f6 ff ff       	call   f01009ed <cprintf>
f01013bf:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f01013c2:	83 ec 0c             	sub    $0xc,%esp
f01013c5:	6a 00                	push   $0x0
f01013c7:	e8 90 f2 ff ff       	call   f010065c <iscons>
f01013cc:	89 c7                	mov    %eax,%edi
f01013ce:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01013d1:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01013d6:	e8 70 f2 ff ff       	call   f010064b <getchar>
f01013db:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01013dd:	85 c0                	test   %eax,%eax
f01013df:	79 18                	jns    f01013f9 <readline+0x58>
			cprintf("read error: %e\n", c);
f01013e1:	83 ec 08             	sub    $0x8,%esp
f01013e4:	50                   	push   %eax
f01013e5:	68 c4 23 10 f0       	push   $0xf01023c4
f01013ea:	e8 fe f5 ff ff       	call   f01009ed <cprintf>
			return NULL;
f01013ef:	83 c4 10             	add    $0x10,%esp
f01013f2:	b8 00 00 00 00       	mov    $0x0,%eax
f01013f7:	eb 79                	jmp    f0101472 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01013f9:	83 f8 7f             	cmp    $0x7f,%eax
f01013fc:	0f 94 c2             	sete   %dl
f01013ff:	83 f8 08             	cmp    $0x8,%eax
f0101402:	0f 94 c0             	sete   %al
f0101405:	08 c2                	or     %al,%dl
f0101407:	74 1a                	je     f0101423 <readline+0x82>
f0101409:	85 f6                	test   %esi,%esi
f010140b:	7e 16                	jle    f0101423 <readline+0x82>
			if (echoing)
f010140d:	85 ff                	test   %edi,%edi
f010140f:	74 0d                	je     f010141e <readline+0x7d>
				cputchar('\b');
f0101411:	83 ec 0c             	sub    $0xc,%esp
f0101414:	6a 08                	push   $0x8
f0101416:	e8 20 f2 ff ff       	call   f010063b <cputchar>
f010141b:	83 c4 10             	add    $0x10,%esp
			i--;
f010141e:	83 ee 01             	sub    $0x1,%esi
f0101421:	eb b3                	jmp    f01013d6 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101423:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0101429:	7f 20                	jg     f010144b <readline+0xaa>
f010142b:	83 fb 1f             	cmp    $0x1f,%ebx
f010142e:	7e 1b                	jle    f010144b <readline+0xaa>
			if (echoing)
f0101430:	85 ff                	test   %edi,%edi
f0101432:	74 0c                	je     f0101440 <readline+0x9f>
				cputchar(c);
f0101434:	83 ec 0c             	sub    $0xc,%esp
f0101437:	53                   	push   %ebx
f0101438:	e8 fe f1 ff ff       	call   f010063b <cputchar>
f010143d:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0101440:	88 9e 80 25 11 f0    	mov    %bl,-0xfeeda80(%esi)
f0101446:	8d 76 01             	lea    0x1(%esi),%esi
f0101449:	eb 8b                	jmp    f01013d6 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f010144b:	83 fb 0d             	cmp    $0xd,%ebx
f010144e:	74 05                	je     f0101455 <readline+0xb4>
f0101450:	83 fb 0a             	cmp    $0xa,%ebx
f0101453:	75 81                	jne    f01013d6 <readline+0x35>
			if (echoing)
f0101455:	85 ff                	test   %edi,%edi
f0101457:	74 0d                	je     f0101466 <readline+0xc5>
				cputchar('\n');
f0101459:	83 ec 0c             	sub    $0xc,%esp
f010145c:	6a 0a                	push   $0xa
f010145e:	e8 d8 f1 ff ff       	call   f010063b <cputchar>
f0101463:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0101466:	c6 86 80 25 11 f0 00 	movb   $0x0,-0xfeeda80(%esi)
			return buf;
f010146d:	b8 80 25 11 f0       	mov    $0xf0112580,%eax
		}
	}
}
f0101472:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101475:	5b                   	pop    %ebx
f0101476:	5e                   	pop    %esi
f0101477:	5f                   	pop    %edi
f0101478:	5d                   	pop    %ebp
f0101479:	c3                   	ret    

f010147a <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f010147a:	55                   	push   %ebp
f010147b:	89 e5                	mov    %esp,%ebp
f010147d:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101480:	b8 00 00 00 00       	mov    $0x0,%eax
f0101485:	eb 03                	jmp    f010148a <strlen+0x10>
		n++;
f0101487:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f010148a:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f010148e:	75 f7                	jne    f0101487 <strlen+0xd>
		n++;
	return n;
}
f0101490:	5d                   	pop    %ebp
f0101491:	c3                   	ret    

f0101492 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101492:	55                   	push   %ebp
f0101493:	89 e5                	mov    %esp,%ebp
f0101495:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101498:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010149b:	ba 00 00 00 00       	mov    $0x0,%edx
f01014a0:	eb 03                	jmp    f01014a5 <strnlen+0x13>
		n++;
f01014a2:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01014a5:	39 c2                	cmp    %eax,%edx
f01014a7:	74 08                	je     f01014b1 <strnlen+0x1f>
f01014a9:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f01014ad:	75 f3                	jne    f01014a2 <strnlen+0x10>
f01014af:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f01014b1:	5d                   	pop    %ebp
f01014b2:	c3                   	ret    

f01014b3 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01014b3:	55                   	push   %ebp
f01014b4:	89 e5                	mov    %esp,%ebp
f01014b6:	53                   	push   %ebx
f01014b7:	8b 45 08             	mov    0x8(%ebp),%eax
f01014ba:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01014bd:	89 c2                	mov    %eax,%edx
f01014bf:	83 c2 01             	add    $0x1,%edx
f01014c2:	83 c1 01             	add    $0x1,%ecx
f01014c5:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01014c9:	88 5a ff             	mov    %bl,-0x1(%edx)
f01014cc:	84 db                	test   %bl,%bl
f01014ce:	75 ef                	jne    f01014bf <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01014d0:	5b                   	pop    %ebx
f01014d1:	5d                   	pop    %ebp
f01014d2:	c3                   	ret    

f01014d3 <strcat>:

char *
strcat(char *dst, const char *src)
{
f01014d3:	55                   	push   %ebp
f01014d4:	89 e5                	mov    %esp,%ebp
f01014d6:	53                   	push   %ebx
f01014d7:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01014da:	53                   	push   %ebx
f01014db:	e8 9a ff ff ff       	call   f010147a <strlen>
f01014e0:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f01014e3:	ff 75 0c             	pushl  0xc(%ebp)
f01014e6:	01 d8                	add    %ebx,%eax
f01014e8:	50                   	push   %eax
f01014e9:	e8 c5 ff ff ff       	call   f01014b3 <strcpy>
	return dst;
}
f01014ee:	89 d8                	mov    %ebx,%eax
f01014f0:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01014f3:	c9                   	leave  
f01014f4:	c3                   	ret    

f01014f5 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01014f5:	55                   	push   %ebp
f01014f6:	89 e5                	mov    %esp,%ebp
f01014f8:	56                   	push   %esi
f01014f9:	53                   	push   %ebx
f01014fa:	8b 75 08             	mov    0x8(%ebp),%esi
f01014fd:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101500:	89 f3                	mov    %esi,%ebx
f0101502:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101505:	89 f2                	mov    %esi,%edx
f0101507:	eb 0f                	jmp    f0101518 <strncpy+0x23>
		*dst++ = *src;
f0101509:	83 c2 01             	add    $0x1,%edx
f010150c:	0f b6 01             	movzbl (%ecx),%eax
f010150f:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101512:	80 39 01             	cmpb   $0x1,(%ecx)
f0101515:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101518:	39 da                	cmp    %ebx,%edx
f010151a:	75 ed                	jne    f0101509 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f010151c:	89 f0                	mov    %esi,%eax
f010151e:	5b                   	pop    %ebx
f010151f:	5e                   	pop    %esi
f0101520:	5d                   	pop    %ebp
f0101521:	c3                   	ret    

f0101522 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101522:	55                   	push   %ebp
f0101523:	89 e5                	mov    %esp,%ebp
f0101525:	56                   	push   %esi
f0101526:	53                   	push   %ebx
f0101527:	8b 75 08             	mov    0x8(%ebp),%esi
f010152a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010152d:	8b 55 10             	mov    0x10(%ebp),%edx
f0101530:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101532:	85 d2                	test   %edx,%edx
f0101534:	74 21                	je     f0101557 <strlcpy+0x35>
f0101536:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f010153a:	89 f2                	mov    %esi,%edx
f010153c:	eb 09                	jmp    f0101547 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f010153e:	83 c2 01             	add    $0x1,%edx
f0101541:	83 c1 01             	add    $0x1,%ecx
f0101544:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101547:	39 c2                	cmp    %eax,%edx
f0101549:	74 09                	je     f0101554 <strlcpy+0x32>
f010154b:	0f b6 19             	movzbl (%ecx),%ebx
f010154e:	84 db                	test   %bl,%bl
f0101550:	75 ec                	jne    f010153e <strlcpy+0x1c>
f0101552:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0101554:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0101557:	29 f0                	sub    %esi,%eax
}
f0101559:	5b                   	pop    %ebx
f010155a:	5e                   	pop    %esi
f010155b:	5d                   	pop    %ebp
f010155c:	c3                   	ret    

f010155d <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010155d:	55                   	push   %ebp
f010155e:	89 e5                	mov    %esp,%ebp
f0101560:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101563:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101566:	eb 06                	jmp    f010156e <strcmp+0x11>
		p++, q++;
f0101568:	83 c1 01             	add    $0x1,%ecx
f010156b:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010156e:	0f b6 01             	movzbl (%ecx),%eax
f0101571:	84 c0                	test   %al,%al
f0101573:	74 04                	je     f0101579 <strcmp+0x1c>
f0101575:	3a 02                	cmp    (%edx),%al
f0101577:	74 ef                	je     f0101568 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101579:	0f b6 c0             	movzbl %al,%eax
f010157c:	0f b6 12             	movzbl (%edx),%edx
f010157f:	29 d0                	sub    %edx,%eax
}
f0101581:	5d                   	pop    %ebp
f0101582:	c3                   	ret    

f0101583 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101583:	55                   	push   %ebp
f0101584:	89 e5                	mov    %esp,%ebp
f0101586:	53                   	push   %ebx
f0101587:	8b 45 08             	mov    0x8(%ebp),%eax
f010158a:	8b 55 0c             	mov    0xc(%ebp),%edx
f010158d:	89 c3                	mov    %eax,%ebx
f010158f:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0101592:	eb 06                	jmp    f010159a <strncmp+0x17>
		n--, p++, q++;
f0101594:	83 c0 01             	add    $0x1,%eax
f0101597:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f010159a:	39 d8                	cmp    %ebx,%eax
f010159c:	74 15                	je     f01015b3 <strncmp+0x30>
f010159e:	0f b6 08             	movzbl (%eax),%ecx
f01015a1:	84 c9                	test   %cl,%cl
f01015a3:	74 04                	je     f01015a9 <strncmp+0x26>
f01015a5:	3a 0a                	cmp    (%edx),%cl
f01015a7:	74 eb                	je     f0101594 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01015a9:	0f b6 00             	movzbl (%eax),%eax
f01015ac:	0f b6 12             	movzbl (%edx),%edx
f01015af:	29 d0                	sub    %edx,%eax
f01015b1:	eb 05                	jmp    f01015b8 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01015b3:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01015b8:	5b                   	pop    %ebx
f01015b9:	5d                   	pop    %ebp
f01015ba:	c3                   	ret    

f01015bb <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01015bb:	55                   	push   %ebp
f01015bc:	89 e5                	mov    %esp,%ebp
f01015be:	8b 45 08             	mov    0x8(%ebp),%eax
f01015c1:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01015c5:	eb 07                	jmp    f01015ce <strchr+0x13>
		if (*s == c)
f01015c7:	38 ca                	cmp    %cl,%dl
f01015c9:	74 0f                	je     f01015da <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01015cb:	83 c0 01             	add    $0x1,%eax
f01015ce:	0f b6 10             	movzbl (%eax),%edx
f01015d1:	84 d2                	test   %dl,%dl
f01015d3:	75 f2                	jne    f01015c7 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f01015d5:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01015da:	5d                   	pop    %ebp
f01015db:	c3                   	ret    

f01015dc <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01015dc:	55                   	push   %ebp
f01015dd:	89 e5                	mov    %esp,%ebp
f01015df:	8b 45 08             	mov    0x8(%ebp),%eax
f01015e2:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01015e6:	eb 03                	jmp    f01015eb <strfind+0xf>
f01015e8:	83 c0 01             	add    $0x1,%eax
f01015eb:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01015ee:	84 d2                	test   %dl,%dl
f01015f0:	74 04                	je     f01015f6 <strfind+0x1a>
f01015f2:	38 ca                	cmp    %cl,%dl
f01015f4:	75 f2                	jne    f01015e8 <strfind+0xc>
			break;
	return (char *) s;
}
f01015f6:	5d                   	pop    %ebp
f01015f7:	c3                   	ret    

f01015f8 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01015f8:	55                   	push   %ebp
f01015f9:	89 e5                	mov    %esp,%ebp
f01015fb:	57                   	push   %edi
f01015fc:	56                   	push   %esi
f01015fd:	53                   	push   %ebx
f01015fe:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101601:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101604:	85 c9                	test   %ecx,%ecx
f0101606:	74 36                	je     f010163e <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101608:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010160e:	75 28                	jne    f0101638 <memset+0x40>
f0101610:	f6 c1 03             	test   $0x3,%cl
f0101613:	75 23                	jne    f0101638 <memset+0x40>
		c &= 0xFF;
f0101615:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101619:	89 d3                	mov    %edx,%ebx
f010161b:	c1 e3 08             	shl    $0x8,%ebx
f010161e:	89 d6                	mov    %edx,%esi
f0101620:	c1 e6 18             	shl    $0x18,%esi
f0101623:	89 d0                	mov    %edx,%eax
f0101625:	c1 e0 10             	shl    $0x10,%eax
f0101628:	09 f0                	or     %esi,%eax
f010162a:	09 c2                	or     %eax,%edx
f010162c:	89 d0                	mov    %edx,%eax
f010162e:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0101630:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0101633:	fc                   	cld    
f0101634:	f3 ab                	rep stos %eax,%es:(%edi)
f0101636:	eb 06                	jmp    f010163e <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0101638:	8b 45 0c             	mov    0xc(%ebp),%eax
f010163b:	fc                   	cld    
f010163c:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010163e:	89 f8                	mov    %edi,%eax
f0101640:	5b                   	pop    %ebx
f0101641:	5e                   	pop    %esi
f0101642:	5f                   	pop    %edi
f0101643:	5d                   	pop    %ebp
f0101644:	c3                   	ret    

f0101645 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101645:	55                   	push   %ebp
f0101646:	89 e5                	mov    %esp,%ebp
f0101648:	57                   	push   %edi
f0101649:	56                   	push   %esi
f010164a:	8b 45 08             	mov    0x8(%ebp),%eax
f010164d:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101650:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101653:	39 c6                	cmp    %eax,%esi
f0101655:	73 35                	jae    f010168c <memmove+0x47>
f0101657:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010165a:	39 d0                	cmp    %edx,%eax
f010165c:	73 2e                	jae    f010168c <memmove+0x47>
		s += n;
		d += n;
f010165e:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f0101661:	89 d6                	mov    %edx,%esi
f0101663:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101665:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010166b:	75 13                	jne    f0101680 <memmove+0x3b>
f010166d:	f6 c1 03             	test   $0x3,%cl
f0101670:	75 0e                	jne    f0101680 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0101672:	83 ef 04             	sub    $0x4,%edi
f0101675:	8d 72 fc             	lea    -0x4(%edx),%esi
f0101678:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f010167b:	fd                   	std    
f010167c:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010167e:	eb 09                	jmp    f0101689 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0101680:	83 ef 01             	sub    $0x1,%edi
f0101683:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0101686:	fd                   	std    
f0101687:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101689:	fc                   	cld    
f010168a:	eb 1d                	jmp    f01016a9 <memmove+0x64>
f010168c:	89 f2                	mov    %esi,%edx
f010168e:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101690:	f6 c2 03             	test   $0x3,%dl
f0101693:	75 0f                	jne    f01016a4 <memmove+0x5f>
f0101695:	f6 c1 03             	test   $0x3,%cl
f0101698:	75 0a                	jne    f01016a4 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f010169a:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f010169d:	89 c7                	mov    %eax,%edi
f010169f:	fc                   	cld    
f01016a0:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01016a2:	eb 05                	jmp    f01016a9 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01016a4:	89 c7                	mov    %eax,%edi
f01016a6:	fc                   	cld    
f01016a7:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01016a9:	5e                   	pop    %esi
f01016aa:	5f                   	pop    %edi
f01016ab:	5d                   	pop    %ebp
f01016ac:	c3                   	ret    

f01016ad <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01016ad:	55                   	push   %ebp
f01016ae:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01016b0:	ff 75 10             	pushl  0x10(%ebp)
f01016b3:	ff 75 0c             	pushl  0xc(%ebp)
f01016b6:	ff 75 08             	pushl  0x8(%ebp)
f01016b9:	e8 87 ff ff ff       	call   f0101645 <memmove>
}
f01016be:	c9                   	leave  
f01016bf:	c3                   	ret    

f01016c0 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01016c0:	55                   	push   %ebp
f01016c1:	89 e5                	mov    %esp,%ebp
f01016c3:	56                   	push   %esi
f01016c4:	53                   	push   %ebx
f01016c5:	8b 45 08             	mov    0x8(%ebp),%eax
f01016c8:	8b 55 0c             	mov    0xc(%ebp),%edx
f01016cb:	89 c6                	mov    %eax,%esi
f01016cd:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01016d0:	eb 1a                	jmp    f01016ec <memcmp+0x2c>
		if (*s1 != *s2)
f01016d2:	0f b6 08             	movzbl (%eax),%ecx
f01016d5:	0f b6 1a             	movzbl (%edx),%ebx
f01016d8:	38 d9                	cmp    %bl,%cl
f01016da:	74 0a                	je     f01016e6 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f01016dc:	0f b6 c1             	movzbl %cl,%eax
f01016df:	0f b6 db             	movzbl %bl,%ebx
f01016e2:	29 d8                	sub    %ebx,%eax
f01016e4:	eb 0f                	jmp    f01016f5 <memcmp+0x35>
		s1++, s2++;
f01016e6:	83 c0 01             	add    $0x1,%eax
f01016e9:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01016ec:	39 f0                	cmp    %esi,%eax
f01016ee:	75 e2                	jne    f01016d2 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01016f0:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01016f5:	5b                   	pop    %ebx
f01016f6:	5e                   	pop    %esi
f01016f7:	5d                   	pop    %ebp
f01016f8:	c3                   	ret    

f01016f9 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01016f9:	55                   	push   %ebp
f01016fa:	89 e5                	mov    %esp,%ebp
f01016fc:	8b 45 08             	mov    0x8(%ebp),%eax
f01016ff:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0101702:	89 c2                	mov    %eax,%edx
f0101704:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0101707:	eb 07                	jmp    f0101710 <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101709:	38 08                	cmp    %cl,(%eax)
f010170b:	74 07                	je     f0101714 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010170d:	83 c0 01             	add    $0x1,%eax
f0101710:	39 d0                	cmp    %edx,%eax
f0101712:	72 f5                	jb     f0101709 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0101714:	5d                   	pop    %ebp
f0101715:	c3                   	ret    

f0101716 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101716:	55                   	push   %ebp
f0101717:	89 e5                	mov    %esp,%ebp
f0101719:	57                   	push   %edi
f010171a:	56                   	push   %esi
f010171b:	53                   	push   %ebx
f010171c:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010171f:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101722:	eb 03                	jmp    f0101727 <strtol+0x11>
		s++;
f0101724:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101727:	0f b6 01             	movzbl (%ecx),%eax
f010172a:	3c 09                	cmp    $0x9,%al
f010172c:	74 f6                	je     f0101724 <strtol+0xe>
f010172e:	3c 20                	cmp    $0x20,%al
f0101730:	74 f2                	je     f0101724 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0101732:	3c 2b                	cmp    $0x2b,%al
f0101734:	75 0a                	jne    f0101740 <strtol+0x2a>
		s++;
f0101736:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0101739:	bf 00 00 00 00       	mov    $0x0,%edi
f010173e:	eb 10                	jmp    f0101750 <strtol+0x3a>
f0101740:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0101745:	3c 2d                	cmp    $0x2d,%al
f0101747:	75 07                	jne    f0101750 <strtol+0x3a>
		s++, neg = 1;
f0101749:	8d 49 01             	lea    0x1(%ecx),%ecx
f010174c:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101750:	85 db                	test   %ebx,%ebx
f0101752:	0f 94 c0             	sete   %al
f0101755:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f010175b:	75 19                	jne    f0101776 <strtol+0x60>
f010175d:	80 39 30             	cmpb   $0x30,(%ecx)
f0101760:	75 14                	jne    f0101776 <strtol+0x60>
f0101762:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0101766:	0f 85 82 00 00 00    	jne    f01017ee <strtol+0xd8>
		s += 2, base = 16;
f010176c:	83 c1 02             	add    $0x2,%ecx
f010176f:	bb 10 00 00 00       	mov    $0x10,%ebx
f0101774:	eb 16                	jmp    f010178c <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f0101776:	84 c0                	test   %al,%al
f0101778:	74 12                	je     f010178c <strtol+0x76>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010177a:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010177f:	80 39 30             	cmpb   $0x30,(%ecx)
f0101782:	75 08                	jne    f010178c <strtol+0x76>
		s++, base = 8;
f0101784:	83 c1 01             	add    $0x1,%ecx
f0101787:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f010178c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101791:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101794:	0f b6 11             	movzbl (%ecx),%edx
f0101797:	8d 72 d0             	lea    -0x30(%edx),%esi
f010179a:	89 f3                	mov    %esi,%ebx
f010179c:	80 fb 09             	cmp    $0x9,%bl
f010179f:	77 08                	ja     f01017a9 <strtol+0x93>
			dig = *s - '0';
f01017a1:	0f be d2             	movsbl %dl,%edx
f01017a4:	83 ea 30             	sub    $0x30,%edx
f01017a7:	eb 22                	jmp    f01017cb <strtol+0xb5>
		else if (*s >= 'a' && *s <= 'z')
f01017a9:	8d 72 9f             	lea    -0x61(%edx),%esi
f01017ac:	89 f3                	mov    %esi,%ebx
f01017ae:	80 fb 19             	cmp    $0x19,%bl
f01017b1:	77 08                	ja     f01017bb <strtol+0xa5>
			dig = *s - 'a' + 10;
f01017b3:	0f be d2             	movsbl %dl,%edx
f01017b6:	83 ea 57             	sub    $0x57,%edx
f01017b9:	eb 10                	jmp    f01017cb <strtol+0xb5>
		else if (*s >= 'A' && *s <= 'Z')
f01017bb:	8d 72 bf             	lea    -0x41(%edx),%esi
f01017be:	89 f3                	mov    %esi,%ebx
f01017c0:	80 fb 19             	cmp    $0x19,%bl
f01017c3:	77 16                	ja     f01017db <strtol+0xc5>
			dig = *s - 'A' + 10;
f01017c5:	0f be d2             	movsbl %dl,%edx
f01017c8:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f01017cb:	3b 55 10             	cmp    0x10(%ebp),%edx
f01017ce:	7d 0f                	jge    f01017df <strtol+0xc9>
			break;
		s++, val = (val * base) + dig;
f01017d0:	83 c1 01             	add    $0x1,%ecx
f01017d3:	0f af 45 10          	imul   0x10(%ebp),%eax
f01017d7:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f01017d9:	eb b9                	jmp    f0101794 <strtol+0x7e>
f01017db:	89 c2                	mov    %eax,%edx
f01017dd:	eb 02                	jmp    f01017e1 <strtol+0xcb>
f01017df:	89 c2                	mov    %eax,%edx

	if (endptr)
f01017e1:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01017e5:	74 0d                	je     f01017f4 <strtol+0xde>
		*endptr = (char *) s;
f01017e7:	8b 75 0c             	mov    0xc(%ebp),%esi
f01017ea:	89 0e                	mov    %ecx,(%esi)
f01017ec:	eb 06                	jmp    f01017f4 <strtol+0xde>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01017ee:	84 c0                	test   %al,%al
f01017f0:	75 92                	jne    f0101784 <strtol+0x6e>
f01017f2:	eb 98                	jmp    f010178c <strtol+0x76>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f01017f4:	f7 da                	neg    %edx
f01017f6:	85 ff                	test   %edi,%edi
f01017f8:	0f 45 c2             	cmovne %edx,%eax
}
f01017fb:	5b                   	pop    %ebx
f01017fc:	5e                   	pop    %esi
f01017fd:	5f                   	pop    %edi
f01017fe:	5d                   	pop    %ebp
f01017ff:	c3                   	ret    

f0101800 <powerbase>:
#include <kern/kdebug.h>



int powerbase(char base, char power)
{
f0101800:	55                   	push   %ebp
f0101801:	89 e5                	mov    %esp,%ebp
f0101803:	53                   	push   %ebx
f0101804:	83 ec 04             	sub    $0x4,%esp
f0101807:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010180a:	8b 55 0c             	mov    0xc(%ebp),%edx
	if(power!=1)
		return (base*powerbase(base,power-1));
	return base;
f010180d:	0f be c3             	movsbl %bl,%eax



int powerbase(char base, char power)
{
	if(power!=1)
f0101810:	80 fa 01             	cmp    $0x1,%dl
f0101813:	74 18                	je     f010182d <powerbase+0x2d>
		return (base*powerbase(base,power-1));
f0101815:	89 c3                	mov    %eax,%ebx
f0101817:	83 ec 08             	sub    $0x8,%esp
f010181a:	83 ea 01             	sub    $0x1,%edx
f010181d:	0f be d2             	movsbl %dl,%edx
f0101820:	52                   	push   %edx
f0101821:	50                   	push   %eax
f0101822:	e8 d9 ff ff ff       	call   f0101800 <powerbase>
f0101827:	83 c4 10             	add    $0x10,%esp
f010182a:	0f af c3             	imul   %ebx,%eax
	return base;
}
f010182d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101830:	c9                   	leave  
f0101831:	c3                   	ret    

f0101832 <char_to_float>:

Float char_to_float(char* arg)
{
f0101832:	55                   	push   %ebp
f0101833:	89 e5                	mov    %esp,%ebp
f0101835:	57                   	push   %edi
f0101836:	56                   	push   %esi
f0101837:	53                   	push   %ebx
f0101838:	83 ec 38             	sub    $0x38,%esp
f010183b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	int len=strlen(arg);
f010183e:	53                   	push   %ebx
f010183f:	e8 36 fc ff ff       	call   f010147a <strlen>
f0101844:	89 c7                	mov    %eax,%edi
	double a = 0;

	Float retval;
	retval.error=0;

	while (i<len)
f0101846:	83 c4 10             	add    $0x10,%esp
	short neg = 0;
	int i=0;
	double a = 0;

	Float retval;
	retval.error=0;
f0101849:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
Float char_to_float(char* arg)
{
	int len=strlen(arg);
	short neg = 0;
	int i=0;
	double a = 0;
f0101850:	d9 ee                	fldz   
f0101852:	dd 5d d8             	fstpl  -0x28(%ebp)

Float char_to_float(char* arg)
{
	int len=strlen(arg);
	short neg = 0;
	int i=0;
f0101855:	be 00 00 00 00       	mov    $0x0,%esi
f010185a:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010185d:	89 f3                	mov    %esi,%ebx
f010185f:	8b 75 0c             	mov    0xc(%ebp),%esi
	double a = 0;

	Float retval;
	retval.error=0;

	while (i<len)
f0101862:	e9 a9 00 00 00       	jmp    f0101910 <char_to_float+0xde>
	{
		if (*(arg) == '.')
f0101867:	0f b6 06             	movzbl (%esi),%eax
f010186a:	3c 2e                	cmp    $0x2e,%al
f010186c:	75 3f                	jne    f01018ad <char_to_float+0x7b>
		{
//			after the point
			a = a + (*(arg+1) - '0') * 0.1;
f010186e:	0f be 46 01          	movsbl 0x1(%esi),%eax
f0101872:	83 e8 30             	sub    $0x30,%eax
f0101875:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101878:	db 45 e0             	fildl  -0x20(%ebp)
f010187b:	dc 0d 68 21 10 f0    	fmull  0xf0102168
f0101881:	dc 45 d8             	faddl  -0x28(%ebp)
			cprintf("entered val %f",a);
f0101884:	83 ec 0c             	sub    $0xc,%esp
f0101887:	dd 55 d8             	fstl   -0x28(%ebp)
f010188a:	dd 1c 24             	fstpl  (%esp)
f010188d:	68 53 1f 10 f0       	push   $0xf0101f53
f0101892:	e8 56 f1 ff ff       	call   f01009ed <cprintf>
			retval.number=a;
f0101897:	8b 45 08             	mov    0x8(%ebp),%eax
f010189a:	dd 45 d8             	fldl   -0x28(%ebp)
f010189d:	d9 18                	fstps  (%eax)
			return retval;
f010189f:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01018a2:	89 78 04             	mov    %edi,0x4(%eax)
f01018a5:	83 c4 10             	add    $0x10,%esp
f01018a8:	e9 8f 00 00 00       	jmp    f010193c <char_to_float+0x10a>
		}
		if (*(arg)=='-')
f01018ad:	3c 2d                	cmp    $0x2d,%al
f01018af:	74 1e                	je     f01018cf <char_to_float+0x9d>
		{
			neg = 1;
		}
		else if (*(arg) < '0' || (*(arg) > '9'))
f01018b1:	83 e8 30             	sub    $0x30,%eax
f01018b4:	3c 09                	cmp    $0x9,%al
f01018b6:	76 17                	jbe    f01018cf <char_to_float+0x9d>
		{
			retval.error = 1;
			cprintf("Invalid Argument");
f01018b8:	83 ec 0c             	sub    $0xc,%esp
f01018bb:	68 62 1f 10 f0       	push   $0xf0101f62
f01018c0:	e8 28 f1 ff ff       	call   f01009ed <cprintf>
f01018c5:	83 c4 10             	add    $0x10,%esp
		{
			neg = 1;
		}
		else if (*(arg) < '0' || (*(arg) > '9'))
		{
			retval.error = 1;
f01018c8:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
			cprintf("Invalid Argument");
			//operation or invalid argument
		}
		// BUG: PowerBase has to be fixed
		// BUG: if power equals zero, the point disappears ?!
		a =  powerbase(10,len-i) / 10 * (*(arg) - '0') + a;
f01018cf:	83 ec 08             	sub    $0x8,%esp
f01018d2:	89 f8                	mov    %edi,%eax
f01018d4:	29 d8                	sub    %ebx,%eax
f01018d6:	0f be c0             	movsbl %al,%eax
f01018d9:	50                   	push   %eax
f01018da:	6a 0a                	push   $0xa
f01018dc:	e8 1f ff ff ff       	call   f0101800 <powerbase>
f01018e1:	83 c4 10             	add    $0x10,%esp
f01018e4:	89 c1                	mov    %eax,%ecx
f01018e6:	b8 67 66 66 66       	mov    $0x66666667,%eax
f01018eb:	f7 e9                	imul   %ecx
f01018ed:	c1 fa 02             	sar    $0x2,%edx
f01018f0:	c1 f9 1f             	sar    $0x1f,%ecx
f01018f3:	29 ca                	sub    %ecx,%edx
f01018f5:	0f be 06             	movsbl (%esi),%eax
f01018f8:	83 e8 30             	sub    $0x30,%eax
f01018fb:	0f af d0             	imul   %eax,%edx
f01018fe:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0101901:	db 45 e0             	fildl  -0x20(%ebp)
f0101904:	dc 45 d8             	faddl  -0x28(%ebp)
f0101907:	dd 5d d8             	fstpl  -0x28(%ebp)
		i++;
f010190a:	83 c3 01             	add    $0x1,%ebx
		arg=arg+1;
f010190d:	83 c6 01             	add    $0x1,%esi
	double a = 0;

	Float retval;
	retval.error=0;

	while (i<len)
f0101910:	39 fb                	cmp    %edi,%ebx
f0101912:	0f 8c 4f ff ff ff    	jl     f0101867 <char_to_float+0x35>
		a =  powerbase(10,len-i) / 10 * (*(arg) - '0') + a;
		i++;
		arg=arg+1;
	}

	cprintf("entered val %f",a);
f0101918:	83 ec 04             	sub    $0x4,%esp
f010191b:	ff 75 dc             	pushl  -0x24(%ebp)
f010191e:	ff 75 d8             	pushl  -0x28(%ebp)
f0101921:	68 53 1f 10 f0       	push   $0xf0101f53
f0101926:	e8 c2 f0 ff ff       	call   f01009ed <cprintf>
	retval.number=a;
f010192b:	8b 45 08             	mov    0x8(%ebp),%eax
f010192e:	dd 45 d8             	fldl   -0x28(%ebp)
f0101931:	d9 18                	fstps  (%eax)
	return retval;
f0101933:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101936:	89 78 04             	mov    %edi,0x4(%eax)
f0101939:	83 c4 10             	add    $0x10,%esp
}
f010193c:	8b 45 08             	mov    0x8(%ebp),%eax
f010193f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101942:	5b                   	pop    %ebx
f0101943:	5e                   	pop    %esi
f0101944:	5f                   	pop    %edi
f0101945:	5d                   	pop    %ebp
f0101946:	c2 04 00             	ret    $0x4
f0101949:	66 90                	xchg   %ax,%ax
f010194b:	66 90                	xchg   %ax,%ax
f010194d:	66 90                	xchg   %ax,%ax
f010194f:	90                   	nop

f0101950 <__udivdi3>:
f0101950:	55                   	push   %ebp
f0101951:	57                   	push   %edi
f0101952:	56                   	push   %esi
f0101953:	83 ec 10             	sub    $0x10,%esp
f0101956:	8b 54 24 2c          	mov    0x2c(%esp),%edx
f010195a:	8b 7c 24 20          	mov    0x20(%esp),%edi
f010195e:	8b 74 24 24          	mov    0x24(%esp),%esi
f0101962:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0101966:	85 d2                	test   %edx,%edx
f0101968:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010196c:	89 34 24             	mov    %esi,(%esp)
f010196f:	89 c8                	mov    %ecx,%eax
f0101971:	75 35                	jne    f01019a8 <__udivdi3+0x58>
f0101973:	39 f1                	cmp    %esi,%ecx
f0101975:	0f 87 bd 00 00 00    	ja     f0101a38 <__udivdi3+0xe8>
f010197b:	85 c9                	test   %ecx,%ecx
f010197d:	89 cd                	mov    %ecx,%ebp
f010197f:	75 0b                	jne    f010198c <__udivdi3+0x3c>
f0101981:	b8 01 00 00 00       	mov    $0x1,%eax
f0101986:	31 d2                	xor    %edx,%edx
f0101988:	f7 f1                	div    %ecx
f010198a:	89 c5                	mov    %eax,%ebp
f010198c:	89 f0                	mov    %esi,%eax
f010198e:	31 d2                	xor    %edx,%edx
f0101990:	f7 f5                	div    %ebp
f0101992:	89 c6                	mov    %eax,%esi
f0101994:	89 f8                	mov    %edi,%eax
f0101996:	f7 f5                	div    %ebp
f0101998:	89 f2                	mov    %esi,%edx
f010199a:	83 c4 10             	add    $0x10,%esp
f010199d:	5e                   	pop    %esi
f010199e:	5f                   	pop    %edi
f010199f:	5d                   	pop    %ebp
f01019a0:	c3                   	ret    
f01019a1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01019a8:	3b 14 24             	cmp    (%esp),%edx
f01019ab:	77 7b                	ja     f0101a28 <__udivdi3+0xd8>
f01019ad:	0f bd f2             	bsr    %edx,%esi
f01019b0:	83 f6 1f             	xor    $0x1f,%esi
f01019b3:	0f 84 97 00 00 00    	je     f0101a50 <__udivdi3+0x100>
f01019b9:	bd 20 00 00 00       	mov    $0x20,%ebp
f01019be:	89 d7                	mov    %edx,%edi
f01019c0:	89 f1                	mov    %esi,%ecx
f01019c2:	29 f5                	sub    %esi,%ebp
f01019c4:	d3 e7                	shl    %cl,%edi
f01019c6:	89 c2                	mov    %eax,%edx
f01019c8:	89 e9                	mov    %ebp,%ecx
f01019ca:	d3 ea                	shr    %cl,%edx
f01019cc:	89 f1                	mov    %esi,%ecx
f01019ce:	09 fa                	or     %edi,%edx
f01019d0:	8b 3c 24             	mov    (%esp),%edi
f01019d3:	d3 e0                	shl    %cl,%eax
f01019d5:	89 54 24 08          	mov    %edx,0x8(%esp)
f01019d9:	89 e9                	mov    %ebp,%ecx
f01019db:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01019df:	8b 44 24 04          	mov    0x4(%esp),%eax
f01019e3:	89 fa                	mov    %edi,%edx
f01019e5:	d3 ea                	shr    %cl,%edx
f01019e7:	89 f1                	mov    %esi,%ecx
f01019e9:	d3 e7                	shl    %cl,%edi
f01019eb:	89 e9                	mov    %ebp,%ecx
f01019ed:	d3 e8                	shr    %cl,%eax
f01019ef:	09 c7                	or     %eax,%edi
f01019f1:	89 f8                	mov    %edi,%eax
f01019f3:	f7 74 24 08          	divl   0x8(%esp)
f01019f7:	89 d5                	mov    %edx,%ebp
f01019f9:	89 c7                	mov    %eax,%edi
f01019fb:	f7 64 24 0c          	mull   0xc(%esp)
f01019ff:	39 d5                	cmp    %edx,%ebp
f0101a01:	89 14 24             	mov    %edx,(%esp)
f0101a04:	72 11                	jb     f0101a17 <__udivdi3+0xc7>
f0101a06:	8b 54 24 04          	mov    0x4(%esp),%edx
f0101a0a:	89 f1                	mov    %esi,%ecx
f0101a0c:	d3 e2                	shl    %cl,%edx
f0101a0e:	39 c2                	cmp    %eax,%edx
f0101a10:	73 5e                	jae    f0101a70 <__udivdi3+0x120>
f0101a12:	3b 2c 24             	cmp    (%esp),%ebp
f0101a15:	75 59                	jne    f0101a70 <__udivdi3+0x120>
f0101a17:	8d 47 ff             	lea    -0x1(%edi),%eax
f0101a1a:	31 f6                	xor    %esi,%esi
f0101a1c:	89 f2                	mov    %esi,%edx
f0101a1e:	83 c4 10             	add    $0x10,%esp
f0101a21:	5e                   	pop    %esi
f0101a22:	5f                   	pop    %edi
f0101a23:	5d                   	pop    %ebp
f0101a24:	c3                   	ret    
f0101a25:	8d 76 00             	lea    0x0(%esi),%esi
f0101a28:	31 f6                	xor    %esi,%esi
f0101a2a:	31 c0                	xor    %eax,%eax
f0101a2c:	89 f2                	mov    %esi,%edx
f0101a2e:	83 c4 10             	add    $0x10,%esp
f0101a31:	5e                   	pop    %esi
f0101a32:	5f                   	pop    %edi
f0101a33:	5d                   	pop    %ebp
f0101a34:	c3                   	ret    
f0101a35:	8d 76 00             	lea    0x0(%esi),%esi
f0101a38:	89 f2                	mov    %esi,%edx
f0101a3a:	31 f6                	xor    %esi,%esi
f0101a3c:	89 f8                	mov    %edi,%eax
f0101a3e:	f7 f1                	div    %ecx
f0101a40:	89 f2                	mov    %esi,%edx
f0101a42:	83 c4 10             	add    $0x10,%esp
f0101a45:	5e                   	pop    %esi
f0101a46:	5f                   	pop    %edi
f0101a47:	5d                   	pop    %ebp
f0101a48:	c3                   	ret    
f0101a49:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101a50:	3b 4c 24 04          	cmp    0x4(%esp),%ecx
f0101a54:	76 0b                	jbe    f0101a61 <__udivdi3+0x111>
f0101a56:	31 c0                	xor    %eax,%eax
f0101a58:	3b 14 24             	cmp    (%esp),%edx
f0101a5b:	0f 83 37 ff ff ff    	jae    f0101998 <__udivdi3+0x48>
f0101a61:	b8 01 00 00 00       	mov    $0x1,%eax
f0101a66:	e9 2d ff ff ff       	jmp    f0101998 <__udivdi3+0x48>
f0101a6b:	90                   	nop
f0101a6c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101a70:	89 f8                	mov    %edi,%eax
f0101a72:	31 f6                	xor    %esi,%esi
f0101a74:	e9 1f ff ff ff       	jmp    f0101998 <__udivdi3+0x48>
f0101a79:	66 90                	xchg   %ax,%ax
f0101a7b:	66 90                	xchg   %ax,%ax
f0101a7d:	66 90                	xchg   %ax,%ax
f0101a7f:	90                   	nop

f0101a80 <__umoddi3>:
f0101a80:	55                   	push   %ebp
f0101a81:	57                   	push   %edi
f0101a82:	56                   	push   %esi
f0101a83:	83 ec 20             	sub    $0x20,%esp
f0101a86:	8b 44 24 34          	mov    0x34(%esp),%eax
f0101a8a:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f0101a8e:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101a92:	89 c6                	mov    %eax,%esi
f0101a94:	89 44 24 10          	mov    %eax,0x10(%esp)
f0101a98:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f0101a9c:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
f0101aa0:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101aa4:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f0101aa8:	89 74 24 18          	mov    %esi,0x18(%esp)
f0101aac:	85 c0                	test   %eax,%eax
f0101aae:	89 c2                	mov    %eax,%edx
f0101ab0:	75 1e                	jne    f0101ad0 <__umoddi3+0x50>
f0101ab2:	39 f7                	cmp    %esi,%edi
f0101ab4:	76 52                	jbe    f0101b08 <__umoddi3+0x88>
f0101ab6:	89 c8                	mov    %ecx,%eax
f0101ab8:	89 f2                	mov    %esi,%edx
f0101aba:	f7 f7                	div    %edi
f0101abc:	89 d0                	mov    %edx,%eax
f0101abe:	31 d2                	xor    %edx,%edx
f0101ac0:	83 c4 20             	add    $0x20,%esp
f0101ac3:	5e                   	pop    %esi
f0101ac4:	5f                   	pop    %edi
f0101ac5:	5d                   	pop    %ebp
f0101ac6:	c3                   	ret    
f0101ac7:	89 f6                	mov    %esi,%esi
f0101ac9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0101ad0:	39 f0                	cmp    %esi,%eax
f0101ad2:	77 5c                	ja     f0101b30 <__umoddi3+0xb0>
f0101ad4:	0f bd e8             	bsr    %eax,%ebp
f0101ad7:	83 f5 1f             	xor    $0x1f,%ebp
f0101ada:	75 64                	jne    f0101b40 <__umoddi3+0xc0>
f0101adc:	8b 6c 24 14          	mov    0x14(%esp),%ebp
f0101ae0:	39 6c 24 0c          	cmp    %ebp,0xc(%esp)
f0101ae4:	0f 86 f6 00 00 00    	jbe    f0101be0 <__umoddi3+0x160>
f0101aea:	3b 44 24 18          	cmp    0x18(%esp),%eax
f0101aee:	0f 82 ec 00 00 00    	jb     f0101be0 <__umoddi3+0x160>
f0101af4:	8b 44 24 14          	mov    0x14(%esp),%eax
f0101af8:	8b 54 24 18          	mov    0x18(%esp),%edx
f0101afc:	83 c4 20             	add    $0x20,%esp
f0101aff:	5e                   	pop    %esi
f0101b00:	5f                   	pop    %edi
f0101b01:	5d                   	pop    %ebp
f0101b02:	c3                   	ret    
f0101b03:	90                   	nop
f0101b04:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101b08:	85 ff                	test   %edi,%edi
f0101b0a:	89 fd                	mov    %edi,%ebp
f0101b0c:	75 0b                	jne    f0101b19 <__umoddi3+0x99>
f0101b0e:	b8 01 00 00 00       	mov    $0x1,%eax
f0101b13:	31 d2                	xor    %edx,%edx
f0101b15:	f7 f7                	div    %edi
f0101b17:	89 c5                	mov    %eax,%ebp
f0101b19:	8b 44 24 10          	mov    0x10(%esp),%eax
f0101b1d:	31 d2                	xor    %edx,%edx
f0101b1f:	f7 f5                	div    %ebp
f0101b21:	89 c8                	mov    %ecx,%eax
f0101b23:	f7 f5                	div    %ebp
f0101b25:	eb 95                	jmp    f0101abc <__umoddi3+0x3c>
f0101b27:	89 f6                	mov    %esi,%esi
f0101b29:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0101b30:	89 c8                	mov    %ecx,%eax
f0101b32:	89 f2                	mov    %esi,%edx
f0101b34:	83 c4 20             	add    $0x20,%esp
f0101b37:	5e                   	pop    %esi
f0101b38:	5f                   	pop    %edi
f0101b39:	5d                   	pop    %ebp
f0101b3a:	c3                   	ret    
f0101b3b:	90                   	nop
f0101b3c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101b40:	b8 20 00 00 00       	mov    $0x20,%eax
f0101b45:	89 e9                	mov    %ebp,%ecx
f0101b47:	29 e8                	sub    %ebp,%eax
f0101b49:	d3 e2                	shl    %cl,%edx
f0101b4b:	89 c7                	mov    %eax,%edi
f0101b4d:	89 44 24 18          	mov    %eax,0x18(%esp)
f0101b51:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0101b55:	89 f9                	mov    %edi,%ecx
f0101b57:	d3 e8                	shr    %cl,%eax
f0101b59:	89 c1                	mov    %eax,%ecx
f0101b5b:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0101b5f:	09 d1                	or     %edx,%ecx
f0101b61:	89 fa                	mov    %edi,%edx
f0101b63:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0101b67:	89 e9                	mov    %ebp,%ecx
f0101b69:	d3 e0                	shl    %cl,%eax
f0101b6b:	89 f9                	mov    %edi,%ecx
f0101b6d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101b71:	89 f0                	mov    %esi,%eax
f0101b73:	d3 e8                	shr    %cl,%eax
f0101b75:	89 e9                	mov    %ebp,%ecx
f0101b77:	89 c7                	mov    %eax,%edi
f0101b79:	8b 44 24 1c          	mov    0x1c(%esp),%eax
f0101b7d:	d3 e6                	shl    %cl,%esi
f0101b7f:	89 d1                	mov    %edx,%ecx
f0101b81:	89 fa                	mov    %edi,%edx
f0101b83:	d3 e8                	shr    %cl,%eax
f0101b85:	89 e9                	mov    %ebp,%ecx
f0101b87:	09 f0                	or     %esi,%eax
f0101b89:	8b 74 24 1c          	mov    0x1c(%esp),%esi
f0101b8d:	f7 74 24 10          	divl   0x10(%esp)
f0101b91:	d3 e6                	shl    %cl,%esi
f0101b93:	89 d1                	mov    %edx,%ecx
f0101b95:	f7 64 24 0c          	mull   0xc(%esp)
f0101b99:	39 d1                	cmp    %edx,%ecx
f0101b9b:	89 74 24 14          	mov    %esi,0x14(%esp)
f0101b9f:	89 d7                	mov    %edx,%edi
f0101ba1:	89 c6                	mov    %eax,%esi
f0101ba3:	72 0a                	jb     f0101baf <__umoddi3+0x12f>
f0101ba5:	39 44 24 14          	cmp    %eax,0x14(%esp)
f0101ba9:	73 10                	jae    f0101bbb <__umoddi3+0x13b>
f0101bab:	39 d1                	cmp    %edx,%ecx
f0101bad:	75 0c                	jne    f0101bbb <__umoddi3+0x13b>
f0101baf:	89 d7                	mov    %edx,%edi
f0101bb1:	89 c6                	mov    %eax,%esi
f0101bb3:	2b 74 24 0c          	sub    0xc(%esp),%esi
f0101bb7:	1b 7c 24 10          	sbb    0x10(%esp),%edi
f0101bbb:	89 ca                	mov    %ecx,%edx
f0101bbd:	89 e9                	mov    %ebp,%ecx
f0101bbf:	8b 44 24 14          	mov    0x14(%esp),%eax
f0101bc3:	29 f0                	sub    %esi,%eax
f0101bc5:	19 fa                	sbb    %edi,%edx
f0101bc7:	d3 e8                	shr    %cl,%eax
f0101bc9:	0f b6 4c 24 18       	movzbl 0x18(%esp),%ecx
f0101bce:	89 d7                	mov    %edx,%edi
f0101bd0:	d3 e7                	shl    %cl,%edi
f0101bd2:	89 e9                	mov    %ebp,%ecx
f0101bd4:	09 f8                	or     %edi,%eax
f0101bd6:	d3 ea                	shr    %cl,%edx
f0101bd8:	83 c4 20             	add    $0x20,%esp
f0101bdb:	5e                   	pop    %esi
f0101bdc:	5f                   	pop    %edi
f0101bdd:	5d                   	pop    %ebp
f0101bde:	c3                   	ret    
f0101bdf:	90                   	nop
f0101be0:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101be4:	29 f9                	sub    %edi,%ecx
f0101be6:	19 c6                	sbb    %eax,%esi
f0101be8:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f0101bec:	89 74 24 18          	mov    %esi,0x18(%esp)
f0101bf0:	e9 ff fe ff ff       	jmp    f0101af4 <__umoddi3+0x74>
