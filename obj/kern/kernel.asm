
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
f0100015:	b8 00 10 11 00       	mov    $0x111000,%eax
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
f0100034:	bc 00 10 11 f0       	mov    $0xf0111000,%esp

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
f010004b:	68 80 21 10 f0       	push   $0xf0102180
f0100050:	e8 99 09 00 00       	call   f01009ee <cprintf>
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
f0100076:	e8 fb 07 00 00       	call   f0100876 <mon_backtrace>
f010007b:	83 c4 10             	add    $0x10,%esp
	cprintf("leaving test_backtrace %d\n", x);
f010007e:	83 ec 08             	sub    $0x8,%esp
f0100081:	53                   	push   %ebx
f0100082:	68 9c 21 10 f0       	push   $0xf010219c
f0100087:	e8 62 09 00 00       	call   f01009ee <cprintf>
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
f010009a:	b8 84 39 11 f0       	mov    $0xf0113984,%eax
f010009f:	2d 00 33 11 f0       	sub    $0xf0113300,%eax
f01000a4:	50                   	push   %eax
f01000a5:	6a 00                	push   $0x0
f01000a7:	68 00 33 11 f0       	push   $0xf0113300
f01000ac:	e8 6c 15 00 00       	call   f010161d <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b1:	e8 8c 04 00 00       	call   f0100542 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000b6:	83 c4 08             	add    $0x8,%esp
f01000b9:	68 ac 1a 00 00       	push   $0x1aac
f01000be:	68 b7 21 10 f0       	push   $0xf01021b7
f01000c3:	e8 26 09 00 00       	call   f01009ee <cprintf>

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
f01000dc:	e8 9f 07 00 00       	call   f0100880 <monitor>
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
f01000ee:	83 3d 80 39 11 f0 00 	cmpl   $0x0,0xf0113980
f01000f5:	75 37                	jne    f010012e <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000f7:	89 35 80 39 11 f0    	mov    %esi,0xf0113980

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
f010010b:	68 d2 21 10 f0       	push   $0xf01021d2
f0100110:	e8 d9 08 00 00       	call   f01009ee <cprintf>
	vcprintf(fmt, ap);
f0100115:	83 c4 08             	add    $0x8,%esp
f0100118:	53                   	push   %ebx
f0100119:	56                   	push   %esi
f010011a:	e8 a9 08 00 00       	call   f01009c8 <vcprintf>
	cprintf("\n");
f010011f:	c7 04 24 0e 22 10 f0 	movl   $0xf010220e,(%esp)
f0100126:	e8 c3 08 00 00       	call   f01009ee <cprintf>
	va_end(ap);
f010012b:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010012e:	83 ec 0c             	sub    $0xc,%esp
f0100131:	6a 00                	push   $0x0
f0100133:	e8 48 07 00 00       	call   f0100880 <monitor>
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
f010014d:	68 ea 21 10 f0       	push   $0xf01021ea
f0100152:	e8 97 08 00 00       	call   f01009ee <cprintf>
	vcprintf(fmt, ap);
f0100157:	83 c4 08             	add    $0x8,%esp
f010015a:	53                   	push   %ebx
f010015b:	ff 75 10             	pushl  0x10(%ebp)
f010015e:	e8 65 08 00 00       	call   f01009c8 <vcprintf>
	cprintf("\n");
f0100163:	c7 04 24 0e 22 10 f0 	movl   $0xf010220e,(%esp)
f010016a:	e8 7f 08 00 00       	call   f01009ee <cprintf>
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
f01001a2:	a1 44 35 11 f0       	mov    0xf0113544,%eax
f01001a7:	8d 48 01             	lea    0x1(%eax),%ecx
f01001aa:	89 0d 44 35 11 f0    	mov    %ecx,0xf0113544
f01001b0:	88 90 40 33 11 f0    	mov    %dl,-0xfeeccc0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f01001b6:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01001bc:	75 0a                	jne    f01001c8 <cons_intr+0x35>
			cons.wpos = 0;
f01001be:	c7 05 44 35 11 f0 00 	movl   $0x0,0xf0113544
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
f01001ee:	83 0d 00 33 11 f0 40 	orl    $0x40,0xf0113300
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
f0100206:	8b 0d 00 33 11 f0    	mov    0xf0113300,%ecx
f010020c:	89 cb                	mov    %ecx,%ebx
f010020e:	83 e3 40             	and    $0x40,%ebx
f0100211:	83 e0 7f             	and    $0x7f,%eax
f0100214:	85 db                	test   %ebx,%ebx
f0100216:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100219:	0f b6 d2             	movzbl %dl,%edx
f010021c:	0f b6 82 80 23 10 f0 	movzbl -0xfefdc80(%edx),%eax
f0100223:	83 c8 40             	or     $0x40,%eax
f0100226:	0f b6 c0             	movzbl %al,%eax
f0100229:	f7 d0                	not    %eax
f010022b:	21 c8                	and    %ecx,%eax
f010022d:	a3 00 33 11 f0       	mov    %eax,0xf0113300
		return 0;
f0100232:	b8 00 00 00 00       	mov    $0x0,%eax
f0100237:	e9 a1 00 00 00       	jmp    f01002dd <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f010023c:	8b 0d 00 33 11 f0    	mov    0xf0113300,%ecx
f0100242:	f6 c1 40             	test   $0x40,%cl
f0100245:	74 0e                	je     f0100255 <kbd_proc_data+0x7e>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100247:	83 c8 80             	or     $0xffffff80,%eax
f010024a:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010024c:	83 e1 bf             	and    $0xffffffbf,%ecx
f010024f:	89 0d 00 33 11 f0    	mov    %ecx,0xf0113300
	}

	shift |= shiftcode[data];
f0100255:	0f b6 c2             	movzbl %dl,%eax
f0100258:	0f b6 90 80 23 10 f0 	movzbl -0xfefdc80(%eax),%edx
f010025f:	0b 15 00 33 11 f0    	or     0xf0113300,%edx
	shift ^= togglecode[data];
f0100265:	0f b6 88 80 22 10 f0 	movzbl -0xfefdd80(%eax),%ecx
f010026c:	31 ca                	xor    %ecx,%edx
f010026e:	89 15 00 33 11 f0    	mov    %edx,0xf0113300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100274:	89 d1                	mov    %edx,%ecx
f0100276:	83 e1 03             	and    $0x3,%ecx
f0100279:	8b 0c 8d 40 22 10 f0 	mov    -0xfefddc0(,%ecx,4),%ecx
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
f01002b9:	68 04 22 10 f0       	push   $0xf0102204
f01002be:	e8 2b 07 00 00       	call   f01009ee <cprintf>
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
f010039e:	0f b7 05 48 35 11 f0 	movzwl 0xf0113548,%eax
f01003a5:	66 85 c0             	test   %ax,%ax
f01003a8:	0f 84 e6 00 00 00    	je     f0100494 <cons_putc+0x1b2>
			crt_pos--;
f01003ae:	83 e8 01             	sub    $0x1,%eax
f01003b1:	66 a3 48 35 11 f0    	mov    %ax,0xf0113548
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003b7:	0f b7 c0             	movzwl %ax,%eax
f01003ba:	66 81 e7 00 ff       	and    $0xff00,%di
f01003bf:	83 cf 20             	or     $0x20,%edi
f01003c2:	8b 15 4c 35 11 f0    	mov    0xf011354c,%edx
f01003c8:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003cc:	eb 78                	jmp    f0100446 <cons_putc+0x164>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003ce:	66 83 05 48 35 11 f0 	addw   $0x50,0xf0113548
f01003d5:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003d6:	0f b7 05 48 35 11 f0 	movzwl 0xf0113548,%eax
f01003dd:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003e3:	c1 e8 16             	shr    $0x16,%eax
f01003e6:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003e9:	c1 e0 04             	shl    $0x4,%eax
f01003ec:	66 a3 48 35 11 f0    	mov    %ax,0xf0113548
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
f0100428:	0f b7 05 48 35 11 f0 	movzwl 0xf0113548,%eax
f010042f:	8d 50 01             	lea    0x1(%eax),%edx
f0100432:	66 89 15 48 35 11 f0 	mov    %dx,0xf0113548
f0100439:	0f b7 c0             	movzwl %ax,%eax
f010043c:	8b 15 4c 35 11 f0    	mov    0xf011354c,%edx
f0100442:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100446:	66 81 3d 48 35 11 f0 	cmpw   $0x7cf,0xf0113548
f010044d:	cf 07 
f010044f:	76 43                	jbe    f0100494 <cons_putc+0x1b2>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100451:	a1 4c 35 11 f0       	mov    0xf011354c,%eax
f0100456:	83 ec 04             	sub    $0x4,%esp
f0100459:	68 00 0f 00 00       	push   $0xf00
f010045e:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100464:	52                   	push   %edx
f0100465:	50                   	push   %eax
f0100466:	e8 ff 11 00 00       	call   f010166a <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010046b:	8b 15 4c 35 11 f0    	mov    0xf011354c,%edx
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
f010048c:	66 83 2d 48 35 11 f0 	subw   $0x50,0xf0113548
f0100493:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100494:	8b 0d 50 35 11 f0    	mov    0xf0113550,%ecx
f010049a:	b8 0e 00 00 00       	mov    $0xe,%eax
f010049f:	89 ca                	mov    %ecx,%edx
f01004a1:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01004a2:	0f b7 1d 48 35 11 f0 	movzwl 0xf0113548,%ebx
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
f01004ca:	80 3d 54 35 11 f0 00 	cmpb   $0x0,0xf0113554
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
f0100508:	a1 40 35 11 f0       	mov    0xf0113540,%eax
f010050d:	3b 05 44 35 11 f0    	cmp    0xf0113544,%eax
f0100513:	74 26                	je     f010053b <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100515:	8d 50 01             	lea    0x1(%eax),%edx
f0100518:	89 15 40 35 11 f0    	mov    %edx,0xf0113540
f010051e:	0f b6 88 40 33 11 f0 	movzbl -0xfeeccc0(%eax),%ecx
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
f010052f:	c7 05 40 35 11 f0 00 	movl   $0x0,0xf0113540
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
f0100568:	c7 05 50 35 11 f0 b4 	movl   $0x3b4,0xf0113550
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
f0100580:	c7 05 50 35 11 f0 d4 	movl   $0x3d4,0xf0113550
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
f010058f:	8b 3d 50 35 11 f0    	mov    0xf0113550,%edi
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
f01005b6:	89 35 4c 35 11 f0    	mov    %esi,0xf011354c

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
f01005c3:	66 a3 48 35 11 f0    	mov    %ax,0xf0113548
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
f0100613:	88 0d 54 35 11 f0    	mov    %cl,0xf0113554
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
f0100626:	68 10 22 10 f0       	push   $0xf0102210
f010062b:	e8 be 03 00 00       	call   f01009ee <cprintf>
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
f0100669:	83 ec 08             	sub    $0x8,%esp
	int i=calculator();
f010066c:	e8 d3 14 00 00       	call   f0101b44 <calculator>
	return 0;
}
f0100671:	b8 00 00 00 00       	mov    $0x0,%eax
f0100676:	c9                   	leave  
f0100677:	c3                   	ret    

f0100678 <mon_help>:
}


int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100678:	55                   	push   %ebp
f0100679:	89 e5                	mov    %esp,%ebp
f010067b:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010067e:	68 80 24 10 f0       	push   $0xf0102480
f0100683:	68 9e 24 10 f0       	push   $0xf010249e
f0100688:	68 a3 24 10 f0       	push   $0xf01024a3
f010068d:	e8 5c 03 00 00       	call   f01009ee <cprintf>
f0100692:	83 c4 0c             	add    $0xc,%esp
f0100695:	68 2c 25 10 f0       	push   $0xf010252c
f010069a:	68 13 27 10 f0       	push   $0xf0102713
f010069f:	68 a3 24 10 f0       	push   $0xf01024a3
f01006a4:	e8 45 03 00 00       	call   f01009ee <cprintf>
f01006a9:	83 c4 0c             	add    $0xc,%esp
f01006ac:	68 54 25 10 f0       	push   $0xf0102554
f01006b1:	68 ac 24 10 f0       	push   $0xf01024ac
f01006b6:	68 a3 24 10 f0       	push   $0xf01024a3
f01006bb:	e8 2e 03 00 00       	call   f01009ee <cprintf>
	return 0;
}
f01006c0:	b8 00 00 00 00       	mov    $0x0,%eax
f01006c5:	c9                   	leave  
f01006c6:	c3                   	ret    

f01006c7 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006c7:	55                   	push   %ebp
f01006c8:	89 e5                	mov    %esp,%ebp
f01006ca:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006cd:	68 b5 24 10 f0       	push   $0xf01024b5
f01006d2:	e8 17 03 00 00       	call   f01009ee <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006d7:	83 c4 08             	add    $0x8,%esp
f01006da:	68 0c 00 10 00       	push   $0x10000c
f01006df:	68 7c 25 10 f0       	push   $0xf010257c
f01006e4:	e8 05 03 00 00       	call   f01009ee <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006e9:	83 c4 0c             	add    $0xc,%esp
f01006ec:	68 0c 00 10 00       	push   $0x10000c
f01006f1:	68 0c 00 10 f0       	push   $0xf010000c
f01006f6:	68 a4 25 10 f0       	push   $0xf01025a4
f01006fb:	e8 ee 02 00 00       	call   f01009ee <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100700:	83 c4 0c             	add    $0xc,%esp
f0100703:	68 75 21 10 00       	push   $0x102175
f0100708:	68 75 21 10 f0       	push   $0xf0102175
f010070d:	68 c8 25 10 f0       	push   $0xf01025c8
f0100712:	e8 d7 02 00 00       	call   f01009ee <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100717:	83 c4 0c             	add    $0xc,%esp
f010071a:	68 00 33 11 00       	push   $0x113300
f010071f:	68 00 33 11 f0       	push   $0xf0113300
f0100724:	68 ec 25 10 f0       	push   $0xf01025ec
f0100729:	e8 c0 02 00 00       	call   f01009ee <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010072e:	83 c4 0c             	add    $0xc,%esp
f0100731:	68 84 39 11 00       	push   $0x113984
f0100736:	68 84 39 11 f0       	push   $0xf0113984
f010073b:	68 10 26 10 f0       	push   $0xf0102610
f0100740:	e8 a9 02 00 00       	call   f01009ee <cprintf>
f0100745:	b8 83 3d 11 f0       	mov    $0xf0113d83,%eax
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f010074a:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f010074f:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f0100752:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100757:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010075d:	85 c0                	test   %eax,%eax
f010075f:	0f 48 c2             	cmovs  %edx,%eax
f0100762:	c1 f8 0a             	sar    $0xa,%eax
f0100765:	50                   	push   %eax
f0100766:	68 34 26 10 f0       	push   $0xf0102634
f010076b:	e8 7e 02 00 00       	call   f01009ee <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100770:	b8 00 00 00 00       	mov    $0x0,%eax
f0100775:	c9                   	leave  
f0100776:	c3                   	ret    

f0100777 <second_lab>:
	return 0;
}

int
second_lab(int argc, char **argv, struct Trapframe *tf)
{
f0100777:	55                   	push   %ebp
f0100778:	89 e5                	mov    %esp,%ebp
f010077a:	83 ec 14             	sub    $0x14,%esp
	/// Yassin call his calculator here;
	char *in= NULL;
	char *out;
	out = readline(in);
f010077d:	6a 00                	push   $0x0
f010077f:	e8 42 0c 00 00       	call   f01013c6 <readline>
	int i=0;
	float a=0;
	while (out+i)
f0100784:	83 c4 10             	add    $0x10,%esp
f0100787:	85 c0                	test   %eax,%eax
f0100789:	75 fc                	jne    f0100787 <second_lab+0x10>
			//operation or invalid argument
		}
		float a;
	}	
	return 0;
}
f010078b:	c9                   	leave  
f010078c:	c3                   	ret    

f010078d <first_lab>:

// First OS Lab

int
first_lab(int argc, char **argv, struct Trapframe *tf)
{
f010078d:	55                   	push   %ebp
f010078e:	89 e5                	mov    %esp,%ebp
f0100790:	57                   	push   %edi
f0100791:	56                   	push   %esi
f0100792:	53                   	push   %ebx
f0100793:	83 ec 28             	sub    $0x28,%esp
//		out=(char*)a;
///////////////////////////////////////// */
	char *in= NULL;
	char* arg;

	arg = readline(in);
f0100796:	6a 00                	push   $0x0
f0100798:	e8 29 0c 00 00       	call   f01013c6 <readline>
f010079d:	89 c3                	mov    %eax,%ebx
	int len=strlen(arg);
f010079f:	89 04 24             	mov    %eax,(%esp)
f01007a2:	e8 f8 0c 00 00       	call   f010149f <strlen>
f01007a7:	89 c7                	mov    %eax,%edi
	short neg = 0;
	int i=0;
	double a = 0;
	while (i<len)
f01007a9:	83 c4 10             	add    $0x10,%esp

	arg = readline(in);
	int len=strlen(arg);
	short neg = 0;
	int i=0;
	double a = 0;
f01007ac:	d9 ee                	fldz   
f01007ae:	dd 5d e0             	fstpl  -0x20(%ebp)
	char* arg;

	arg = readline(in);
	int len=strlen(arg);
	short neg = 0;
	int i=0;
f01007b1:	be 00 00 00 00       	mov    $0x0,%esi
	double a = 0;
	while (i<len)
f01007b6:	e9 90 00 00 00       	jmp    f010084b <first_lab+0xbe>
	{
		if (*(arg) == '.')
f01007bb:	0f b6 03             	movzbl (%ebx),%eax
f01007be:	3c 2e                	cmp    $0x2e,%al
f01007c0:	75 2b                	jne    f01007ed <first_lab+0x60>
		{
//			after the point
			a = a + (*(arg+1) - '0') * 0.1;
			cprintf("entered val %f",a);
f01007c2:	83 ec 0c             	sub    $0xc,%esp
	while (i<len)
	{
		if (*(arg) == '.')
		{
//			after the point
			a = a + (*(arg+1) - '0') * 0.1;
f01007c5:	0f be 43 01          	movsbl 0x1(%ebx),%eax
f01007c9:	83 e8 30             	sub    $0x30,%eax
f01007cc:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01007cf:	db 45 dc             	fildl  -0x24(%ebp)
f01007d2:	dc 0d e8 26 10 f0    	fmull  0xf01026e8
f01007d8:	dc 45 e0             	faddl  -0x20(%ebp)
			cprintf("entered val %f",a);
f01007db:	dd 1c 24             	fstpl  (%esp)
f01007de:	68 ce 24 10 f0       	push   $0xf01024ce
f01007e3:	e8 06 02 00 00       	call   f01009ee <cprintf>
			return 0;
f01007e8:	83 c4 10             	add    $0x10,%esp
f01007eb:	eb 7c                	jmp    f0100869 <first_lab+0xdc>
		}
		if (*(arg)=='-')
f01007ed:	3c 2d                	cmp    $0x2d,%al
f01007ef:	74 17                	je     f0100808 <first_lab+0x7b>
		{
			neg = 1;
		}
		else if (*(arg) < '0' || (*(arg) > '9'))
f01007f1:	83 e8 30             	sub    $0x30,%eax
f01007f4:	3c 09                	cmp    $0x9,%al
f01007f6:	76 10                	jbe    f0100808 <first_lab+0x7b>
		{
			cprintf("Invalid Argument");
f01007f8:	83 ec 0c             	sub    $0xc,%esp
f01007fb:	68 dd 24 10 f0       	push   $0xf01024dd
f0100800:	e8 e9 01 00 00       	call   f01009ee <cprintf>
f0100805:	83 c4 10             	add    $0x10,%esp
			//operation or invalid argument
		}
		// BUG: PowerBase has to be fixed
		// BUG: if power equals zero, the point disappears ?!
		a =  powerbase(10,len-i) / 10 * (*(arg) - '0') + a;
f0100808:	83 ec 08             	sub    $0x8,%esp
f010080b:	89 f8                	mov    %edi,%eax
f010080d:	89 f1                	mov    %esi,%ecx
f010080f:	29 c8                	sub    %ecx,%eax
f0100811:	0f be c0             	movsbl %al,%eax
f0100814:	50                   	push   %eax
f0100815:	6a 0a                	push   $0xa
f0100817:	e8 25 15 00 00       	call   f0101d41 <powerbase>
f010081c:	89 c1                	mov    %eax,%ecx
f010081e:	b8 67 66 66 66       	mov    $0x66666667,%eax
f0100823:	f7 e9                	imul   %ecx
f0100825:	c1 fa 02             	sar    $0x2,%edx
f0100828:	c1 f9 1f             	sar    $0x1f,%ecx
f010082b:	29 ca                	sub    %ecx,%edx
f010082d:	0f be 03             	movsbl (%ebx),%eax
f0100830:	83 e8 30             	sub    $0x30,%eax
f0100833:	0f af d0             	imul   %eax,%edx
f0100836:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0100839:	db 45 dc             	fildl  -0x24(%ebp)
f010083c:	dc 45 e0             	faddl  -0x20(%ebp)
f010083f:	dd 5d e0             	fstpl  -0x20(%ebp)
		i++;
f0100842:	83 c6 01             	add    $0x1,%esi
		arg=arg+1;
f0100845:	83 c3 01             	add    $0x1,%ebx
f0100848:	83 c4 10             	add    $0x10,%esp
	arg = readline(in);
	int len=strlen(arg);
	short neg = 0;
	int i=0;
	double a = 0;
	while (i<len)
f010084b:	39 fe                	cmp    %edi,%esi
f010084d:	0f 8c 68 ff ff ff    	jl     f01007bb <first_lab+0x2e>
		a =  powerbase(10,len-i) / 10 * (*(arg) - '0') + a;
		i++;
		arg=arg+1;
	}

	cprintf("entered val %f",a);
f0100853:	83 ec 04             	sub    $0x4,%esp
f0100856:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100859:	ff 75 e0             	pushl  -0x20(%ebp)
f010085c:	68 ce 24 10 f0       	push   $0xf01024ce
f0100861:	e8 88 01 00 00       	call   f01009ee <cprintf>
	return 0;
f0100866:	83 c4 10             	add    $0x10,%esp
}
f0100869:	b8 00 00 00 00       	mov    $0x0,%eax
f010086e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100871:	5b                   	pop    %ebx
f0100872:	5e                   	pop    %esi
f0100873:	5f                   	pop    %edi
f0100874:	5d                   	pop    %ebp
f0100875:	c3                   	ret    

f0100876 <mon_backtrace>:
}


int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100876:	55                   	push   %ebp
f0100877:	89 e5                	mov    %esp,%ebp
	// Your code here.
	return 0;
}
f0100879:	b8 00 00 00 00       	mov    $0x0,%eax
f010087e:	5d                   	pop    %ebp
f010087f:	c3                   	ret    

f0100880 <monitor>:
}


void
monitor(struct Trapframe *tf)
{
f0100880:	55                   	push   %ebp
f0100881:	89 e5                	mov    %esp,%ebp
f0100883:	57                   	push   %edi
f0100884:	56                   	push   %esi
f0100885:	53                   	push   %ebx
f0100886:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100889:	68 60 26 10 f0       	push   $0xf0102660
f010088e:	e8 5b 01 00 00       	call   f01009ee <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100893:	c7 04 24 84 26 10 f0 	movl   $0xf0102684,(%esp)
f010089a:	e8 4f 01 00 00       	call   f01009ee <cprintf>
f010089f:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f01008a2:	83 ec 0c             	sub    $0xc,%esp
f01008a5:	68 ee 24 10 f0       	push   $0xf01024ee
f01008aa:	e8 17 0b 00 00       	call   f01013c6 <readline>
f01008af:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01008b1:	83 c4 10             	add    $0x10,%esp
f01008b4:	85 c0                	test   %eax,%eax
f01008b6:	74 ea                	je     f01008a2 <monitor+0x22>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01008b8:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01008bf:	be 00 00 00 00       	mov    $0x0,%esi
f01008c4:	eb 0a                	jmp    f01008d0 <monitor+0x50>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01008c6:	c6 03 00             	movb   $0x0,(%ebx)
f01008c9:	89 f7                	mov    %esi,%edi
f01008cb:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01008ce:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01008d0:	0f b6 03             	movzbl (%ebx),%eax
f01008d3:	84 c0                	test   %al,%al
f01008d5:	74 63                	je     f010093a <monitor+0xba>
f01008d7:	83 ec 08             	sub    $0x8,%esp
f01008da:	0f be c0             	movsbl %al,%eax
f01008dd:	50                   	push   %eax
f01008de:	68 f2 24 10 f0       	push   $0xf01024f2
f01008e3:	e8 f8 0c 00 00       	call   f01015e0 <strchr>
f01008e8:	83 c4 10             	add    $0x10,%esp
f01008eb:	85 c0                	test   %eax,%eax
f01008ed:	75 d7                	jne    f01008c6 <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f01008ef:	80 3b 00             	cmpb   $0x0,(%ebx)
f01008f2:	74 46                	je     f010093a <monitor+0xba>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01008f4:	83 fe 0f             	cmp    $0xf,%esi
f01008f7:	75 14                	jne    f010090d <monitor+0x8d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01008f9:	83 ec 08             	sub    $0x8,%esp
f01008fc:	6a 10                	push   $0x10
f01008fe:	68 f7 24 10 f0       	push   $0xf01024f7
f0100903:	e8 e6 00 00 00       	call   f01009ee <cprintf>
f0100908:	83 c4 10             	add    $0x10,%esp
f010090b:	eb 95                	jmp    f01008a2 <monitor+0x22>
			return 0;
		}
		argv[argc++] = buf;
f010090d:	8d 7e 01             	lea    0x1(%esi),%edi
f0100910:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100914:	eb 03                	jmp    f0100919 <monitor+0x99>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100916:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100919:	0f b6 03             	movzbl (%ebx),%eax
f010091c:	84 c0                	test   %al,%al
f010091e:	74 ae                	je     f01008ce <monitor+0x4e>
f0100920:	83 ec 08             	sub    $0x8,%esp
f0100923:	0f be c0             	movsbl %al,%eax
f0100926:	50                   	push   %eax
f0100927:	68 f2 24 10 f0       	push   $0xf01024f2
f010092c:	e8 af 0c 00 00       	call   f01015e0 <strchr>
f0100931:	83 c4 10             	add    $0x10,%esp
f0100934:	85 c0                	test   %eax,%eax
f0100936:	74 de                	je     f0100916 <monitor+0x96>
f0100938:	eb 94                	jmp    f01008ce <monitor+0x4e>
			buf++;
	}
	argv[argc] = 0;
f010093a:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100941:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100942:	85 f6                	test   %esi,%esi
f0100944:	0f 84 58 ff ff ff    	je     f01008a2 <monitor+0x22>
f010094a:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f010094f:	83 ec 08             	sub    $0x8,%esp
f0100952:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100955:	ff 34 85 c0 26 10 f0 	pushl  -0xfefd940(,%eax,4)
f010095c:	ff 75 a8             	pushl  -0x58(%ebp)
f010095f:	e8 1e 0c 00 00       	call   f0101582 <strcmp>
f0100964:	83 c4 10             	add    $0x10,%esp
f0100967:	85 c0                	test   %eax,%eax
f0100969:	75 22                	jne    f010098d <monitor+0x10d>
			return commands[i].func(argc, argv, tf);
f010096b:	83 ec 04             	sub    $0x4,%esp
f010096e:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100971:	ff 75 08             	pushl  0x8(%ebp)
f0100974:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100977:	52                   	push   %edx
f0100978:	56                   	push   %esi
f0100979:	ff 14 85 c8 26 10 f0 	call   *-0xfefd938(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100980:	83 c4 10             	add    $0x10,%esp
f0100983:	85 c0                	test   %eax,%eax
f0100985:	0f 89 17 ff ff ff    	jns    f01008a2 <monitor+0x22>
f010098b:	eb 20                	jmp    f01009ad <monitor+0x12d>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f010098d:	83 c3 01             	add    $0x1,%ebx
f0100990:	83 fb 03             	cmp    $0x3,%ebx
f0100993:	75 ba                	jne    f010094f <monitor+0xcf>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100995:	83 ec 08             	sub    $0x8,%esp
f0100998:	ff 75 a8             	pushl  -0x58(%ebp)
f010099b:	68 14 25 10 f0       	push   $0xf0102514
f01009a0:	e8 49 00 00 00       	call   f01009ee <cprintf>
f01009a5:	83 c4 10             	add    $0x10,%esp
f01009a8:	e9 f5 fe ff ff       	jmp    f01008a2 <monitor+0x22>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01009ad:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01009b0:	5b                   	pop    %ebx
f01009b1:	5e                   	pop    %esi
f01009b2:	5f                   	pop    %edi
f01009b3:	5d                   	pop    %ebp
f01009b4:	c3                   	ret    

f01009b5 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01009b5:	55                   	push   %ebp
f01009b6:	89 e5                	mov    %esp,%ebp
f01009b8:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f01009bb:	ff 75 08             	pushl  0x8(%ebp)
f01009be:	e8 78 fc ff ff       	call   f010063b <cputchar>
f01009c3:	83 c4 10             	add    $0x10,%esp
	*cnt++;
}
f01009c6:	c9                   	leave  
f01009c7:	c3                   	ret    

f01009c8 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01009c8:	55                   	push   %ebp
f01009c9:	89 e5                	mov    %esp,%ebp
f01009cb:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f01009ce:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01009d5:	ff 75 0c             	pushl  0xc(%ebp)
f01009d8:	ff 75 08             	pushl  0x8(%ebp)
f01009db:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01009de:	50                   	push   %eax
f01009df:	68 b5 09 10 f0       	push   $0xf01009b5
f01009e4:	e8 bf 04 00 00       	call   f0100ea8 <vprintfmt>
	return cnt;
}
f01009e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01009ec:	c9                   	leave  
f01009ed:	c3                   	ret    

f01009ee <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01009ee:	55                   	push   %ebp
f01009ef:	89 e5                	mov    %esp,%ebp
f01009f1:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01009f4:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01009f7:	50                   	push   %eax
f01009f8:	ff 75 08             	pushl  0x8(%ebp)
f01009fb:	e8 c8 ff ff ff       	call   f01009c8 <vcprintf>
	va_end(ap);

	return cnt;
}
f0100a00:	c9                   	leave  
f0100a01:	c3                   	ret    

f0100a02 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100a02:	55                   	push   %ebp
f0100a03:	89 e5                	mov    %esp,%ebp
f0100a05:	57                   	push   %edi
f0100a06:	56                   	push   %esi
f0100a07:	53                   	push   %ebx
f0100a08:	83 ec 14             	sub    $0x14,%esp
f0100a0b:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0100a0e:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100a11:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100a14:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100a17:	8b 1a                	mov    (%edx),%ebx
f0100a19:	8b 01                	mov    (%ecx),%eax
f0100a1b:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a1e:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0100a25:	e9 88 00 00 00       	jmp    f0100ab2 <stab_binsearch+0xb0>
		int true_m = (l + r) / 2, m = true_m;
f0100a2a:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100a2d:	01 d8                	add    %ebx,%eax
f0100a2f:	89 c6                	mov    %eax,%esi
f0100a31:	c1 ee 1f             	shr    $0x1f,%esi
f0100a34:	01 c6                	add    %eax,%esi
f0100a36:	d1 fe                	sar    %esi
f0100a38:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0100a3b:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100a3e:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0100a41:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a43:	eb 03                	jmp    f0100a48 <stab_binsearch+0x46>
			m--;
f0100a45:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a48:	39 c3                	cmp    %eax,%ebx
f0100a4a:	7f 1f                	jg     f0100a6b <stab_binsearch+0x69>
f0100a4c:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0100a50:	83 ea 0c             	sub    $0xc,%edx
f0100a53:	39 f9                	cmp    %edi,%ecx
f0100a55:	75 ee                	jne    f0100a45 <stab_binsearch+0x43>
f0100a57:	89 45 e8             	mov    %eax,-0x18(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100a5a:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100a5d:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100a60:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0100a64:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100a67:	76 18                	jbe    f0100a81 <stab_binsearch+0x7f>
f0100a69:	eb 05                	jmp    f0100a70 <stab_binsearch+0x6e>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100a6b:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0100a6e:	eb 42                	jmp    f0100ab2 <stab_binsearch+0xb0>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100a70:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100a73:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0100a75:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a78:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100a7f:	eb 31                	jmp    f0100ab2 <stab_binsearch+0xb0>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100a81:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100a84:	73 17                	jae    f0100a9d <stab_binsearch+0x9b>
			*region_right = m - 1;
f0100a86:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100a89:	83 e8 01             	sub    $0x1,%eax
f0100a8c:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a8f:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100a92:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a94:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100a9b:	eb 15                	jmp    f0100ab2 <stab_binsearch+0xb0>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100a9d:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100aa0:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100aa3:	89 1e                	mov    %ebx,(%esi)
			l = m;
			addr++;
f0100aa5:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0100aa9:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100aab:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100ab2:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100ab5:	0f 8e 6f ff ff ff    	jle    f0100a2a <stab_binsearch+0x28>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100abb:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0100abf:	75 0f                	jne    f0100ad0 <stab_binsearch+0xce>
		*region_right = *region_left - 1;
f0100ac1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ac4:	8b 00                	mov    (%eax),%eax
f0100ac6:	83 e8 01             	sub    $0x1,%eax
f0100ac9:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100acc:	89 06                	mov    %eax,(%esi)
f0100ace:	eb 2c                	jmp    f0100afc <stab_binsearch+0xfa>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100ad0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ad3:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100ad5:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100ad8:	8b 0e                	mov    (%esi),%ecx
f0100ada:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100add:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0100ae0:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100ae3:	eb 03                	jmp    f0100ae8 <stab_binsearch+0xe6>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100ae5:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100ae8:	39 c8                	cmp    %ecx,%eax
f0100aea:	7e 0b                	jle    f0100af7 <stab_binsearch+0xf5>
		     l > *region_left && stabs[l].n_type != type;
f0100aec:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0100af0:	83 ea 0c             	sub    $0xc,%edx
f0100af3:	39 fb                	cmp    %edi,%ebx
f0100af5:	75 ee                	jne    f0100ae5 <stab_binsearch+0xe3>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100af7:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100afa:	89 06                	mov    %eax,(%esi)
	}
}
f0100afc:	83 c4 14             	add    $0x14,%esp
f0100aff:	5b                   	pop    %ebx
f0100b00:	5e                   	pop    %esi
f0100b01:	5f                   	pop    %edi
f0100b02:	5d                   	pop    %ebp
f0100b03:	c3                   	ret    

f0100b04 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100b04:	55                   	push   %ebp
f0100b05:	89 e5                	mov    %esp,%ebp
f0100b07:	57                   	push   %edi
f0100b08:	56                   	push   %esi
f0100b09:	53                   	push   %ebx
f0100b0a:	83 ec 1c             	sub    $0x1c,%esp
f0100b0d:	8b 7d 08             	mov    0x8(%ebp),%edi
f0100b10:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100b13:	c7 06 f0 26 10 f0    	movl   $0xf01026f0,(%esi)
	info->eip_line = 0;
f0100b19:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0100b20:	c7 46 08 f0 26 10 f0 	movl   $0xf01026f0,0x8(%esi)
	info->eip_fn_namelen = 9;
f0100b27:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f0100b2e:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0100b31:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100b38:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0100b3e:	76 11                	jbe    f0100b51 <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b40:	b8 2d 8f 10 f0       	mov    $0xf0108f2d,%eax
f0100b45:	3d cd 72 10 f0       	cmp    $0xf01072cd,%eax
f0100b4a:	77 19                	ja     f0100b65 <debuginfo_eip+0x61>
f0100b4c:	e9 4c 01 00 00       	jmp    f0100c9d <debuginfo_eip+0x199>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100b51:	83 ec 04             	sub    $0x4,%esp
f0100b54:	68 fa 26 10 f0       	push   $0xf01026fa
f0100b59:	6a 7f                	push   $0x7f
f0100b5b:	68 07 27 10 f0       	push   $0xf0102707
f0100b60:	e8 81 f5 ff ff       	call   f01000e6 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b65:	80 3d 2c 8f 10 f0 00 	cmpb   $0x0,0xf0108f2c
f0100b6c:	0f 85 32 01 00 00    	jne    f0100ca4 <debuginfo_eip+0x1a0>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100b72:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100b79:	b8 cc 72 10 f0       	mov    $0xf01072cc,%eax
f0100b7e:	2d e8 29 10 f0       	sub    $0xf01029e8,%eax
f0100b83:	c1 f8 02             	sar    $0x2,%eax
f0100b86:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100b8c:	83 e8 01             	sub    $0x1,%eax
f0100b8f:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100b92:	83 ec 08             	sub    $0x8,%esp
f0100b95:	57                   	push   %edi
f0100b96:	6a 64                	push   $0x64
f0100b98:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100b9b:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100b9e:	b8 e8 29 10 f0       	mov    $0xf01029e8,%eax
f0100ba3:	e8 5a fe ff ff       	call   f0100a02 <stab_binsearch>
	if (lfile == 0)
f0100ba8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100bab:	83 c4 10             	add    $0x10,%esp
f0100bae:	85 c0                	test   %eax,%eax
f0100bb0:	0f 84 f5 00 00 00    	je     f0100cab <debuginfo_eip+0x1a7>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100bb6:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100bb9:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100bbc:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100bbf:	83 ec 08             	sub    $0x8,%esp
f0100bc2:	57                   	push   %edi
f0100bc3:	6a 24                	push   $0x24
f0100bc5:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100bc8:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100bcb:	b8 e8 29 10 f0       	mov    $0xf01029e8,%eax
f0100bd0:	e8 2d fe ff ff       	call   f0100a02 <stab_binsearch>

	if (lfun <= rfun) {
f0100bd5:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100bd8:	83 c4 10             	add    $0x10,%esp
f0100bdb:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f0100bde:	7f 31                	jg     f0100c11 <debuginfo_eip+0x10d>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100be0:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100be3:	c1 e0 02             	shl    $0x2,%eax
f0100be6:	8d 90 e8 29 10 f0    	lea    -0xfefd618(%eax),%edx
f0100bec:	8b 88 e8 29 10 f0    	mov    -0xfefd618(%eax),%ecx
f0100bf2:	b8 2d 8f 10 f0       	mov    $0xf0108f2d,%eax
f0100bf7:	2d cd 72 10 f0       	sub    $0xf01072cd,%eax
f0100bfc:	39 c1                	cmp    %eax,%ecx
f0100bfe:	73 09                	jae    f0100c09 <debuginfo_eip+0x105>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100c00:	81 c1 cd 72 10 f0    	add    $0xf01072cd,%ecx
f0100c06:	89 4e 08             	mov    %ecx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100c09:	8b 42 08             	mov    0x8(%edx),%eax
f0100c0c:	89 46 10             	mov    %eax,0x10(%esi)
f0100c0f:	eb 06                	jmp    f0100c17 <debuginfo_eip+0x113>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100c11:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0100c14:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100c17:	83 ec 08             	sub    $0x8,%esp
f0100c1a:	6a 3a                	push   $0x3a
f0100c1c:	ff 76 08             	pushl  0x8(%esi)
f0100c1f:	e8 dd 09 00 00       	call   f0101601 <strfind>
f0100c24:	2b 46 08             	sub    0x8(%esi),%eax
f0100c27:	89 46 0c             	mov    %eax,0xc(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c2a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100c2d:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100c30:	8d 04 85 e8 29 10 f0 	lea    -0xfefd618(,%eax,4),%eax
f0100c37:	83 c4 10             	add    $0x10,%esp
f0100c3a:	eb 06                	jmp    f0100c42 <debuginfo_eip+0x13e>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100c3c:	83 eb 01             	sub    $0x1,%ebx
f0100c3f:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c42:	39 fb                	cmp    %edi,%ebx
f0100c44:	7c 1e                	jl     f0100c64 <debuginfo_eip+0x160>
	       && stabs[lline].n_type != N_SOL
f0100c46:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f0100c4a:	80 fa 84             	cmp    $0x84,%dl
f0100c4d:	74 6a                	je     f0100cb9 <debuginfo_eip+0x1b5>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100c4f:	80 fa 64             	cmp    $0x64,%dl
f0100c52:	75 e8                	jne    f0100c3c <debuginfo_eip+0x138>
f0100c54:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0100c58:	74 e2                	je     f0100c3c <debuginfo_eip+0x138>
f0100c5a:	eb 5d                	jmp    f0100cb9 <debuginfo_eip+0x1b5>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100c5c:	81 c2 cd 72 10 f0    	add    $0xf01072cd,%edx
f0100c62:	89 16                	mov    %edx,(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c64:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100c67:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c6a:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c6f:	39 cb                	cmp    %ecx,%ebx
f0100c71:	7d 60                	jge    f0100cd3 <debuginfo_eip+0x1cf>
		for (lline = lfun + 1;
f0100c73:	8d 53 01             	lea    0x1(%ebx),%edx
f0100c76:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100c79:	8d 04 85 e8 29 10 f0 	lea    -0xfefd618(,%eax,4),%eax
f0100c80:	eb 07                	jmp    f0100c89 <debuginfo_eip+0x185>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100c82:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0100c86:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100c89:	39 ca                	cmp    %ecx,%edx
f0100c8b:	74 25                	je     f0100cb2 <debuginfo_eip+0x1ae>
f0100c8d:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100c90:	80 78 04 a0          	cmpb   $0xa0,0x4(%eax)
f0100c94:	74 ec                	je     f0100c82 <debuginfo_eip+0x17e>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c96:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c9b:	eb 36                	jmp    f0100cd3 <debuginfo_eip+0x1cf>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100c9d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100ca2:	eb 2f                	jmp    f0100cd3 <debuginfo_eip+0x1cf>
f0100ca4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100ca9:	eb 28                	jmp    f0100cd3 <debuginfo_eip+0x1cf>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100cab:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100cb0:	eb 21                	jmp    f0100cd3 <debuginfo_eip+0x1cf>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100cb2:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cb7:	eb 1a                	jmp    f0100cd3 <debuginfo_eip+0x1cf>
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100cb9:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100cbc:	8b 14 85 e8 29 10 f0 	mov    -0xfefd618(,%eax,4),%edx
f0100cc3:	b8 2d 8f 10 f0       	mov    $0xf0108f2d,%eax
f0100cc8:	2d cd 72 10 f0       	sub    $0xf01072cd,%eax
f0100ccd:	39 c2                	cmp    %eax,%edx
f0100ccf:	72 8b                	jb     f0100c5c <debuginfo_eip+0x158>
f0100cd1:	eb 91                	jmp    f0100c64 <debuginfo_eip+0x160>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
}
f0100cd3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100cd6:	5b                   	pop    %ebx
f0100cd7:	5e                   	pop    %esi
f0100cd8:	5f                   	pop    %edi
f0100cd9:	5d                   	pop    %ebp
f0100cda:	c3                   	ret    

f0100cdb <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100cdb:	55                   	push   %ebp
f0100cdc:	89 e5                	mov    %esp,%ebp
f0100cde:	57                   	push   %edi
f0100cdf:	56                   	push   %esi
f0100ce0:	53                   	push   %ebx
f0100ce1:	83 ec 1c             	sub    $0x1c,%esp
f0100ce4:	89 c7                	mov    %eax,%edi
f0100ce6:	89 d6                	mov    %edx,%esi
f0100ce8:	8b 45 08             	mov    0x8(%ebp),%eax
f0100ceb:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100cee:	89 d1                	mov    %edx,%ecx
f0100cf0:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100cf3:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100cf6:	8b 45 10             	mov    0x10(%ebp),%eax
f0100cf9:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100cfc:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100cff:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0100d06:	39 4d e4             	cmp    %ecx,-0x1c(%ebp)
f0100d09:	72 05                	jb     f0100d10 <printnum+0x35>
f0100d0b:	3b 45 d8             	cmp    -0x28(%ebp),%eax
f0100d0e:	77 3e                	ja     f0100d4e <printnum+0x73>
                               
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100d10:	83 ec 0c             	sub    $0xc,%esp
f0100d13:	ff 75 18             	pushl  0x18(%ebp)
f0100d16:	83 eb 01             	sub    $0x1,%ebx
f0100d19:	53                   	push   %ebx
f0100d1a:	50                   	push   %eax
f0100d1b:	83 ec 08             	sub    $0x8,%esp
f0100d1e:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100d21:	ff 75 e0             	pushl  -0x20(%ebp)
f0100d24:	ff 75 dc             	pushl  -0x24(%ebp)
f0100d27:	ff 75 d8             	pushl  -0x28(%ebp)
f0100d2a:	e8 a1 11 00 00       	call   f0101ed0 <__udivdi3>
f0100d2f:	83 c4 18             	add    $0x18,%esp
f0100d32:	52                   	push   %edx
f0100d33:	50                   	push   %eax
f0100d34:	89 f2                	mov    %esi,%edx
f0100d36:	89 f8                	mov    %edi,%eax
f0100d38:	e8 9e ff ff ff       	call   f0100cdb <printnum>
f0100d3d:	83 c4 20             	add    $0x20,%esp
f0100d40:	eb 13                	jmp    f0100d55 <printnum+0x7a>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100d42:	83 ec 08             	sub    $0x8,%esp
f0100d45:	56                   	push   %esi
f0100d46:	ff 75 18             	pushl  0x18(%ebp)
f0100d49:	ff d7                	call   *%edi
f0100d4b:	83 c4 10             	add    $0x10,%esp
	if (num >= base) {
                               
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100d4e:	83 eb 01             	sub    $0x1,%ebx
f0100d51:	85 db                	test   %ebx,%ebx
f0100d53:	7f ed                	jg     f0100d42 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100d55:	83 ec 08             	sub    $0x8,%esp
f0100d58:	56                   	push   %esi
f0100d59:	83 ec 04             	sub    $0x4,%esp
f0100d5c:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100d5f:	ff 75 e0             	pushl  -0x20(%ebp)
f0100d62:	ff 75 dc             	pushl  -0x24(%ebp)
f0100d65:	ff 75 d8             	pushl  -0x28(%ebp)
f0100d68:	e8 93 12 00 00       	call   f0102000 <__umoddi3>
f0100d6d:	83 c4 14             	add    $0x14,%esp
f0100d70:	0f be 80 15 27 10 f0 	movsbl -0xfefd8eb(%eax),%eax
f0100d77:	50                   	push   %eax
f0100d78:	ff d7                	call   *%edi
f0100d7a:	83 c4 10             	add    $0x10,%esp
       
}
f0100d7d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100d80:	5b                   	pop    %ebx
f0100d81:	5e                   	pop    %esi
f0100d82:	5f                   	pop    %edi
f0100d83:	5d                   	pop    %ebp
f0100d84:	c3                   	ret    

f0100d85 <printnum2>:
static void
printnum2(void (*putch)(int, void*), void *putdat,
	 double num_float, unsigned base, int width, int padc)
{      
f0100d85:	55                   	push   %ebp
f0100d86:	89 e5                	mov    %esp,%ebp
f0100d88:	57                   	push   %edi
f0100d89:	56                   	push   %esi
f0100d8a:	53                   	push   %ebx
f0100d8b:	83 ec 3c             	sub    $0x3c,%esp
f0100d8e:	89 c7                	mov    %eax,%edi
f0100d90:	89 d6                	mov    %edx,%esi
f0100d92:	dd 45 08             	fldl   0x8(%ebp)
f0100d95:	dd 55 d0             	fstl   -0x30(%ebp)
f0100d98:	89 4d cc             	mov    %ecx,-0x34(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num_float >= base) { 
f0100d9b:	89 4d c0             	mov    %ecx,-0x40(%ebp)
f0100d9e:	c7 45 c4 00 00 00 00 	movl   $0x0,-0x3c(%ebp)
f0100da5:	df 6d c0             	fildll -0x40(%ebp)
f0100da8:	d9 c9                	fxch   %st(1)
f0100daa:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0100dad:	db e9                	fucomi %st(1),%st
f0100daf:	72 2d                	jb     f0100dde <printnum2+0x59>
		printnum2(putch, putdat, num_float / base, base, width - 1, padc);
f0100db1:	ff 75 14             	pushl  0x14(%ebp)
f0100db4:	8b 45 10             	mov    0x10(%ebp),%eax
f0100db7:	83 e8 01             	sub    $0x1,%eax
f0100dba:	50                   	push   %eax
f0100dbb:	de f1                	fdivp  %st,%st(1)
f0100dbd:	8d 64 24 f8          	lea    -0x8(%esp),%esp
f0100dc1:	dd 1c 24             	fstpl  (%esp)
f0100dc4:	89 f8                	mov    %edi,%eax
f0100dc6:	e8 ba ff ff ff       	call   f0100d85 <printnum2>
f0100dcb:	83 c4 10             	add    $0x10,%esp
f0100dce:	eb 2c                	jmp    f0100dfc <printnum2+0x77>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100dd0:	83 ec 08             	sub    $0x8,%esp
f0100dd3:	56                   	push   %esi
f0100dd4:	ff 75 14             	pushl  0x14(%ebp)
f0100dd7:	ff d7                	call   *%edi
f0100dd9:	83 c4 10             	add    $0x10,%esp
f0100ddc:	eb 04                	jmp    f0100de2 <printnum2+0x5d>
f0100dde:	dd d8                	fstp   %st(0)
f0100de0:	dd d8                	fstp   %st(0)
	// first recursively print all preceding (more significant) digits
	if (num_float >= base) { 
		printnum2(putch, putdat, num_float / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100de2:	83 eb 01             	sub    $0x1,%ebx
f0100de5:	85 db                	test   %ebx,%ebx
f0100de7:	7f e7                	jg     f0100dd0 <printnum2+0x4b>
f0100de9:	8b 55 10             	mov    0x10(%ebp),%edx
f0100dec:	83 ea 01             	sub    $0x1,%edx
f0100def:	b8 00 00 00 00       	mov    $0x0,%eax
f0100df4:	0f 49 c2             	cmovns %edx,%eax
f0100df7:	29 c2                	sub    %eax,%edx
f0100df9:	89 55 10             	mov    %edx,0x10(%ebp)
			putch(padc, putdat);
	}
        int x =(int)num_float;
	// then print this (the least significant) digit
	putch("0123456789abcdef"[x % base], putdat);
f0100dfc:	83 ec 08             	sub    $0x8,%esp
f0100dff:	56                   	push   %esi
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
	}
        int x =(int)num_float;
f0100e00:	d9 7d de             	fnstcw -0x22(%ebp)
f0100e03:	0f b7 45 de          	movzwl -0x22(%ebp),%eax
f0100e07:	b4 0c                	mov    $0xc,%ah
f0100e09:	66 89 45 dc          	mov    %ax,-0x24(%ebp)
f0100e0d:	dd 45 d0             	fldl   -0x30(%ebp)
f0100e10:	d9 6d dc             	fldcw  -0x24(%ebp)
f0100e13:	db 5d d8             	fistpl -0x28(%ebp)
f0100e16:	d9 6d de             	fldcw  -0x22(%ebp)
f0100e19:	8b 45 d8             	mov    -0x28(%ebp),%eax
	// then print this (the least significant) digit
	putch("0123456789abcdef"[x % base], putdat);
f0100e1c:	ba 00 00 00 00       	mov    $0x0,%edx
f0100e21:	f7 75 cc             	divl   -0x34(%ebp)
f0100e24:	0f be 82 15 27 10 f0 	movsbl -0xfefd8eb(%edx),%eax
f0100e2b:	50                   	push   %eax
f0100e2c:	ff d7                	call   *%edi
        if ( width == -3) {
f0100e2e:	83 c4 10             	add    $0x10,%esp
f0100e31:	83 7d 10 fd          	cmpl   $0xfffffffd,0x10(%ebp)
f0100e35:	75 0d                	jne    f0100e44 <printnum2+0xbf>
        putch('.',putdat);}
f0100e37:	83 ec 08             	sub    $0x8,%esp
f0100e3a:	56                   	push   %esi
f0100e3b:	6a 2e                	push   $0x2e
f0100e3d:	ff d7                	call   *%edi
f0100e3f:	83 c4 10             	add    $0x10,%esp
f0100e42:	eb 22                	jmp    f0100e66 <printnum2+0xe1>
        if ( width == -4 && num_float<10)
f0100e44:	83 7d 10 fc          	cmpl   $0xfffffffc,0x10(%ebp)
f0100e48:	75 1c                	jne    f0100e66 <printnum2+0xe1>
f0100e4a:	d9 05 40 29 10 f0    	flds   0xf0102940
f0100e50:	dd 45 d0             	fldl   -0x30(%ebp)
f0100e53:	d9 c9                	fxch   %st(1)
f0100e55:	df e9                	fucomip %st(1),%st
f0100e57:	dd d8                	fstp   %st(0)
f0100e59:	76 0b                	jbe    f0100e66 <printnum2+0xe1>
        putch('.',putdat);
f0100e5b:	83 ec 08             	sub    $0x8,%esp
f0100e5e:	56                   	push   %esi
f0100e5f:	6a 2e                	push   $0x2e
f0100e61:	ff d7                	call   *%edi
f0100e63:	83 c4 10             	add    $0x10,%esp
}
f0100e66:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e69:	5b                   	pop    %ebx
f0100e6a:	5e                   	pop    %esi
f0100e6b:	5f                   	pop    %edi
f0100e6c:	5d                   	pop    %ebp
f0100e6d:	c3                   	ret    

f0100e6e <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100e6e:	55                   	push   %ebp
f0100e6f:	89 e5                	mov    %esp,%ebp
f0100e71:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100e74:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100e78:	8b 10                	mov    (%eax),%edx
f0100e7a:	3b 50 04             	cmp    0x4(%eax),%edx
f0100e7d:	73 0a                	jae    f0100e89 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100e7f:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100e82:	89 08                	mov    %ecx,(%eax)
f0100e84:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e87:	88 02                	mov    %al,(%edx)
}
f0100e89:	5d                   	pop    %ebp
f0100e8a:	c3                   	ret    

f0100e8b <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100e8b:	55                   	push   %ebp
f0100e8c:	89 e5                	mov    %esp,%ebp
f0100e8e:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100e91:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100e94:	50                   	push   %eax
f0100e95:	ff 75 10             	pushl  0x10(%ebp)
f0100e98:	ff 75 0c             	pushl  0xc(%ebp)
f0100e9b:	ff 75 08             	pushl  0x8(%ebp)
f0100e9e:	e8 05 00 00 00       	call   f0100ea8 <vprintfmt>
	va_end(ap);
f0100ea3:	83 c4 10             	add    $0x10,%esp
}
f0100ea6:	c9                   	leave  
f0100ea7:	c3                   	ret    

f0100ea8 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100ea8:	55                   	push   %ebp
f0100ea9:	89 e5                	mov    %esp,%ebp
f0100eab:	57                   	push   %edi
f0100eac:	56                   	push   %esi
f0100ead:	53                   	push   %ebx
f0100eae:	83 ec 2c             	sub    $0x2c,%esp
f0100eb1:	8b 75 08             	mov    0x8(%ebp),%esi
f0100eb4:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100eb7:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100eba:	eb 12                	jmp    f0100ece <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100ebc:	85 c0                	test   %eax,%eax
f0100ebe:	0f 84 92 04 00 00    	je     f0101356 <vprintfmt+0x4ae>
				return;
			putch(ch, putdat);
f0100ec4:	83 ec 08             	sub    $0x8,%esp
f0100ec7:	53                   	push   %ebx
f0100ec8:	50                   	push   %eax
f0100ec9:	ff d6                	call   *%esi
f0100ecb:	83 c4 10             	add    $0x10,%esp
        double num_float;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100ece:	83 c7 01             	add    $0x1,%edi
f0100ed1:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0100ed5:	83 f8 25             	cmp    $0x25,%eax
f0100ed8:	75 e2                	jne    f0100ebc <vprintfmt+0x14>
f0100eda:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0100ede:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100ee5:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100eec:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0100ef3:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100ef8:	eb 07                	jmp    f0100f01 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100efa:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100efd:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f01:	8d 47 01             	lea    0x1(%edi),%eax
f0100f04:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100f07:	0f b6 07             	movzbl (%edi),%eax
f0100f0a:	0f b6 d0             	movzbl %al,%edx
f0100f0d:	83 e8 23             	sub    $0x23,%eax
f0100f10:	3c 55                	cmp    $0x55,%al
f0100f12:	0f 87 23 04 00 00    	ja     f010133b <vprintfmt+0x493>
f0100f18:	0f b6 c0             	movzbl %al,%eax
f0100f1b:	ff 24 85 c0 27 10 f0 	jmp    *-0xfefd840(,%eax,4)
f0100f22:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100f25:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0100f29:	eb d6                	jmp    f0100f01 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f2b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100f2e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f33:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100f36:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100f39:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0100f3d:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0100f40:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0100f43:	83 f9 09             	cmp    $0x9,%ecx
f0100f46:	77 3f                	ja     f0100f87 <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100f48:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0100f4b:	eb e9                	jmp    f0100f36 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100f4d:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f50:	8b 00                	mov    (%eax),%eax
f0100f52:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100f55:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f58:	8d 40 04             	lea    0x4(%eax),%eax
f0100f5b:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f5e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100f61:	eb 2a                	jmp    f0100f8d <vprintfmt+0xe5>
f0100f63:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100f66:	85 c0                	test   %eax,%eax
f0100f68:	ba 00 00 00 00       	mov    $0x0,%edx
f0100f6d:	0f 49 d0             	cmovns %eax,%edx
f0100f70:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f73:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100f76:	eb 89                	jmp    f0100f01 <vprintfmt+0x59>
f0100f78:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100f7b:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0100f82:	e9 7a ff ff ff       	jmp    f0100f01 <vprintfmt+0x59>
f0100f87:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100f8a:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0100f8d:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100f91:	0f 89 6a ff ff ff    	jns    f0100f01 <vprintfmt+0x59>
				width = precision, precision = -1;
f0100f97:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100f9a:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100f9d:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100fa4:	e9 58 ff ff ff       	jmp    f0100f01 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100fa9:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fac:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100faf:	e9 4d ff ff ff       	jmp    f0100f01 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fb4:	8b 45 14             	mov    0x14(%ebp),%eax
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100fb7:	83 45 14 04          	addl   $0x4,0x14(%ebp)
f0100fbb:	83 ec 08             	sub    $0x8,%esp
f0100fbe:	53                   	push   %ebx
f0100fbf:	ff 30                	pushl  (%eax)
f0100fc1:	ff d6                	call   *%esi
			break;
f0100fc3:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fc6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0100fc9:	e9 00 ff ff ff       	jmp    f0100ece <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100fce:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fd1:	8d 78 04             	lea    0x4(%eax),%edi
f0100fd4:	8b 00                	mov    (%eax),%eax
f0100fd6:	99                   	cltd   
f0100fd7:	31 d0                	xor    %edx,%eax
f0100fd9:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100fdb:	83 f8 07             	cmp    $0x7,%eax
f0100fde:	7f 0b                	jg     f0100feb <vprintfmt+0x143>
f0100fe0:	8b 14 85 20 29 10 f0 	mov    -0xfefd6e0(,%eax,4),%edx
f0100fe7:	85 d2                	test   %edx,%edx
f0100fe9:	75 1b                	jne    f0101006 <vprintfmt+0x15e>
				printfmt(putch, putdat, "error %d", err);
f0100feb:	50                   	push   %eax
f0100fec:	68 2d 27 10 f0       	push   $0xf010272d
f0100ff1:	53                   	push   %ebx
f0100ff2:	56                   	push   %esi
f0100ff3:	e8 93 fe ff ff       	call   f0100e8b <printfmt>
f0100ff8:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100ffb:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ffe:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0101001:	e9 c8 fe ff ff       	jmp    f0100ece <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0101006:	52                   	push   %edx
f0101007:	68 36 27 10 f0       	push   $0xf0102736
f010100c:	53                   	push   %ebx
f010100d:	56                   	push   %esi
f010100e:	e8 78 fe ff ff       	call   f0100e8b <printfmt>
f0101013:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0101016:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101019:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010101c:	e9 ad fe ff ff       	jmp    f0100ece <vprintfmt+0x26>
f0101021:	8b 45 14             	mov    0x14(%ebp),%eax
f0101024:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0101027:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f010102a:	89 4d cc             	mov    %ecx,-0x34(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f010102d:	83 45 14 04          	addl   $0x4,0x14(%ebp)
f0101031:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0101033:	85 ff                	test   %edi,%edi
f0101035:	b8 26 27 10 f0       	mov    $0xf0102726,%eax
f010103a:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f010103d:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0101041:	0f 84 90 00 00 00    	je     f01010d7 <vprintfmt+0x22f>
f0101047:	85 c9                	test   %ecx,%ecx
f0101049:	0f 8e 96 00 00 00    	jle    f01010e5 <vprintfmt+0x23d>
				for (width -= strnlen(p, precision); width > 0; width--)
f010104f:	83 ec 08             	sub    $0x8,%esp
f0101052:	52                   	push   %edx
f0101053:	57                   	push   %edi
f0101054:	e8 5e 04 00 00       	call   f01014b7 <strnlen>
f0101059:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f010105c:	29 c1                	sub    %eax,%ecx
f010105e:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0101061:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0101064:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0101068:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010106b:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f010106e:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101070:	eb 0f                	jmp    f0101081 <vprintfmt+0x1d9>
					putch(padc, putdat);
f0101072:	83 ec 08             	sub    $0x8,%esp
f0101075:	53                   	push   %ebx
f0101076:	ff 75 e0             	pushl  -0x20(%ebp)
f0101079:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010107b:	83 ef 01             	sub    $0x1,%edi
f010107e:	83 c4 10             	add    $0x10,%esp
f0101081:	85 ff                	test   %edi,%edi
f0101083:	7f ed                	jg     f0101072 <vprintfmt+0x1ca>
f0101085:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101088:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f010108b:	85 c9                	test   %ecx,%ecx
f010108d:	b8 00 00 00 00       	mov    $0x0,%eax
f0101092:	0f 49 c1             	cmovns %ecx,%eax
f0101095:	29 c1                	sub    %eax,%ecx
f0101097:	89 75 08             	mov    %esi,0x8(%ebp)
f010109a:	8b 75 d0             	mov    -0x30(%ebp),%esi
f010109d:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01010a0:	89 cb                	mov    %ecx,%ebx
f01010a2:	eb 4d                	jmp    f01010f1 <vprintfmt+0x249>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f01010a4:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01010a8:	74 1b                	je     f01010c5 <vprintfmt+0x21d>
f01010aa:	0f be c0             	movsbl %al,%eax
f01010ad:	83 e8 20             	sub    $0x20,%eax
f01010b0:	83 f8 5e             	cmp    $0x5e,%eax
f01010b3:	76 10                	jbe    f01010c5 <vprintfmt+0x21d>
					putch('?', putdat);
f01010b5:	83 ec 08             	sub    $0x8,%esp
f01010b8:	ff 75 0c             	pushl  0xc(%ebp)
f01010bb:	6a 3f                	push   $0x3f
f01010bd:	ff 55 08             	call   *0x8(%ebp)
f01010c0:	83 c4 10             	add    $0x10,%esp
f01010c3:	eb 0d                	jmp    f01010d2 <vprintfmt+0x22a>
				else
					putch(ch, putdat);
f01010c5:	83 ec 08             	sub    $0x8,%esp
f01010c8:	ff 75 0c             	pushl  0xc(%ebp)
f01010cb:	52                   	push   %edx
f01010cc:	ff 55 08             	call   *0x8(%ebp)
f01010cf:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01010d2:	83 eb 01             	sub    $0x1,%ebx
f01010d5:	eb 1a                	jmp    f01010f1 <vprintfmt+0x249>
f01010d7:	89 75 08             	mov    %esi,0x8(%ebp)
f01010da:	8b 75 d0             	mov    -0x30(%ebp),%esi
f01010dd:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01010e0:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f01010e3:	eb 0c                	jmp    f01010f1 <vprintfmt+0x249>
f01010e5:	89 75 08             	mov    %esi,0x8(%ebp)
f01010e8:	8b 75 d0             	mov    -0x30(%ebp),%esi
f01010eb:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01010ee:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f01010f1:	83 c7 01             	add    $0x1,%edi
f01010f4:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f01010f8:	0f be d0             	movsbl %al,%edx
f01010fb:	85 d2                	test   %edx,%edx
f01010fd:	74 23                	je     f0101122 <vprintfmt+0x27a>
f01010ff:	85 f6                	test   %esi,%esi
f0101101:	78 a1                	js     f01010a4 <vprintfmt+0x1fc>
f0101103:	83 ee 01             	sub    $0x1,%esi
f0101106:	79 9c                	jns    f01010a4 <vprintfmt+0x1fc>
f0101108:	89 df                	mov    %ebx,%edi
f010110a:	8b 75 08             	mov    0x8(%ebp),%esi
f010110d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101110:	eb 18                	jmp    f010112a <vprintfmt+0x282>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0101112:	83 ec 08             	sub    $0x8,%esp
f0101115:	53                   	push   %ebx
f0101116:	6a 20                	push   $0x20
f0101118:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f010111a:	83 ef 01             	sub    $0x1,%edi
f010111d:	83 c4 10             	add    $0x10,%esp
f0101120:	eb 08                	jmp    f010112a <vprintfmt+0x282>
f0101122:	89 df                	mov    %ebx,%edi
f0101124:	8b 75 08             	mov    0x8(%ebp),%esi
f0101127:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010112a:	85 ff                	test   %edi,%edi
f010112c:	7f e4                	jg     f0101112 <vprintfmt+0x26a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010112e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101131:	e9 98 fd ff ff       	jmp    f0100ece <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101136:	83 f9 01             	cmp    $0x1,%ecx
f0101139:	7e 19                	jle    f0101154 <vprintfmt+0x2ac>
		return va_arg(*ap, long long);
f010113b:	8b 45 14             	mov    0x14(%ebp),%eax
f010113e:	8b 50 04             	mov    0x4(%eax),%edx
f0101141:	8b 00                	mov    (%eax),%eax
f0101143:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101146:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101149:	8b 45 14             	mov    0x14(%ebp),%eax
f010114c:	8d 40 08             	lea    0x8(%eax),%eax
f010114f:	89 45 14             	mov    %eax,0x14(%ebp)
f0101152:	eb 38                	jmp    f010118c <vprintfmt+0x2e4>
	else if (lflag)
f0101154:	85 c9                	test   %ecx,%ecx
f0101156:	74 1b                	je     f0101173 <vprintfmt+0x2cb>
		return va_arg(*ap, long);
f0101158:	8b 45 14             	mov    0x14(%ebp),%eax
f010115b:	8b 00                	mov    (%eax),%eax
f010115d:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101160:	89 c1                	mov    %eax,%ecx
f0101162:	c1 f9 1f             	sar    $0x1f,%ecx
f0101165:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0101168:	8b 45 14             	mov    0x14(%ebp),%eax
f010116b:	8d 40 04             	lea    0x4(%eax),%eax
f010116e:	89 45 14             	mov    %eax,0x14(%ebp)
f0101171:	eb 19                	jmp    f010118c <vprintfmt+0x2e4>
	else
		return va_arg(*ap, int);
f0101173:	8b 45 14             	mov    0x14(%ebp),%eax
f0101176:	8b 00                	mov    (%eax),%eax
f0101178:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010117b:	89 c1                	mov    %eax,%ecx
f010117d:	c1 f9 1f             	sar    $0x1f,%ecx
f0101180:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0101183:	8b 45 14             	mov    0x14(%ebp),%eax
f0101186:	8d 40 04             	lea    0x4(%eax),%eax
f0101189:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f010118c:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010118f:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0101192:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0101197:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f010119b:	0f 89 66 01 00 00    	jns    f0101307 <vprintfmt+0x45f>
				putch('-', putdat);
f01011a1:	83 ec 08             	sub    $0x8,%esp
f01011a4:	53                   	push   %ebx
f01011a5:	6a 2d                	push   $0x2d
f01011a7:	ff d6                	call   *%esi
				num = -(long long) num;
f01011a9:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01011ac:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01011af:	f7 da                	neg    %edx
f01011b1:	83 d1 00             	adc    $0x0,%ecx
f01011b4:	f7 d9                	neg    %ecx
f01011b6:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f01011b9:	b8 0a 00 00 00       	mov    $0xa,%eax
f01011be:	e9 44 01 00 00       	jmp    f0101307 <vprintfmt+0x45f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01011c3:	83 f9 01             	cmp    $0x1,%ecx
f01011c6:	7e 18                	jle    f01011e0 <vprintfmt+0x338>
		return va_arg(*ap, unsigned long long);
f01011c8:	8b 45 14             	mov    0x14(%ebp),%eax
f01011cb:	8b 10                	mov    (%eax),%edx
f01011cd:	8b 48 04             	mov    0x4(%eax),%ecx
f01011d0:	8d 40 08             	lea    0x8(%eax),%eax
f01011d3:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f01011d6:	b8 0a 00 00 00       	mov    $0xa,%eax
f01011db:	e9 27 01 00 00       	jmp    f0101307 <vprintfmt+0x45f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f01011e0:	85 c9                	test   %ecx,%ecx
f01011e2:	74 1a                	je     f01011fe <vprintfmt+0x356>
		return va_arg(*ap, unsigned long);
f01011e4:	8b 45 14             	mov    0x14(%ebp),%eax
f01011e7:	8b 10                	mov    (%eax),%edx
f01011e9:	b9 00 00 00 00       	mov    $0x0,%ecx
f01011ee:	8d 40 04             	lea    0x4(%eax),%eax
f01011f1:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f01011f4:	b8 0a 00 00 00       	mov    $0xa,%eax
f01011f9:	e9 09 01 00 00       	jmp    f0101307 <vprintfmt+0x45f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f01011fe:	8b 45 14             	mov    0x14(%ebp),%eax
f0101201:	8b 10                	mov    (%eax),%edx
f0101203:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101208:	8d 40 04             	lea    0x4(%eax),%eax
f010120b:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f010120e:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101213:	e9 ef 00 00 00       	jmp    f0101307 <vprintfmt+0x45f>
			goto number;

               // signed float
		case 'f':
			num_float = va_arg(ap, double);
f0101218:	8b 45 14             	mov    0x14(%ebp),%eax
f010121b:	8d 78 08             	lea    0x8(%eax),%edi
                        num_float = num_float*100;
f010121e:	d9 05 44 29 10 f0    	flds   0xf0102944
f0101224:	dc 08                	fmull  (%eax)
f0101226:	d9 c0                	fld    %st(0)
f0101228:	dd 5d d8             	fstpl  -0x28(%ebp)
			if ( num_float < 0) {
f010122b:	d9 ee                	fldz   
f010122d:	df e9                	fucomip %st(1),%st
f010122f:	dd d8                	fstp   %st(0)
f0101231:	76 13                	jbe    f0101246 <vprintfmt+0x39e>
				putch('-', putdat);
f0101233:	83 ec 08             	sub    $0x8,%esp
f0101236:	53                   	push   %ebx
f0101237:	6a 2d                	push   $0x2d
f0101239:	ff d6                	call   *%esi
				num_float = - num_float;
f010123b:	dd 45 d8             	fldl   -0x28(%ebp)
f010123e:	d9 e0                	fchs   
f0101240:	dd 5d d8             	fstpl  -0x28(%ebp)
f0101243:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
                        
			printnum2(putch, putdat, num_float, base, width, padc);
f0101246:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f010124a:	50                   	push   %eax
f010124b:	ff 75 e0             	pushl  -0x20(%ebp)
f010124e:	ff 75 dc             	pushl  -0x24(%ebp)
f0101251:	ff 75 d8             	pushl  -0x28(%ebp)
f0101254:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0101259:	89 da                	mov    %ebx,%edx
f010125b:	89 f0                	mov    %esi,%eax
f010125d:	e8 23 fb ff ff       	call   f0100d85 <printnum2>
			break;
f0101262:	83 c4 10             	add    $0x10,%esp
			base = 10;
			goto number;

               // signed float
		case 'f':
			num_float = va_arg(ap, double);
f0101265:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101268:	8b 7d e4             	mov    -0x1c(%ebp),%edi
				num_float = - num_float;
			}
			base = 10;
                        
			printnum2(putch, putdat, num_float, base, width, padc);
			break;
f010126b:	e9 5e fc ff ff       	jmp    f0100ece <vprintfmt+0x26>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f0101270:	83 ec 08             	sub    $0x8,%esp
f0101273:	53                   	push   %ebx
f0101274:	6a 58                	push   $0x58
f0101276:	ff d6                	call   *%esi
			putch('X', putdat);
f0101278:	83 c4 08             	add    $0x8,%esp
f010127b:	53                   	push   %ebx
f010127c:	6a 58                	push   $0x58
f010127e:	ff d6                	call   *%esi
			putch('X', putdat);
f0101280:	83 c4 08             	add    $0x8,%esp
f0101283:	53                   	push   %ebx
f0101284:	6a 58                	push   $0x58
f0101286:	ff d6                	call   *%esi
			break;
f0101288:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010128b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
f010128e:	e9 3b fc ff ff       	jmp    f0100ece <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
f0101293:	83 ec 08             	sub    $0x8,%esp
f0101296:	53                   	push   %ebx
f0101297:	6a 30                	push   $0x30
f0101299:	ff d6                	call   *%esi
			putch('x', putdat);
f010129b:	83 c4 08             	add    $0x8,%esp
f010129e:	53                   	push   %ebx
f010129f:	6a 78                	push   $0x78
f01012a1:	ff d6                	call   *%esi
			num = (unsigned long long)
f01012a3:	8b 45 14             	mov    0x14(%ebp),%eax
f01012a6:	8b 10                	mov    (%eax),%edx
f01012a8:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f01012ad:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01012b0:	8d 40 04             	lea    0x4(%eax),%eax
f01012b3:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01012b6:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f01012bb:	eb 4a                	jmp    f0101307 <vprintfmt+0x45f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01012bd:	83 f9 01             	cmp    $0x1,%ecx
f01012c0:	7e 15                	jle    f01012d7 <vprintfmt+0x42f>
		return va_arg(*ap, unsigned long long);
f01012c2:	8b 45 14             	mov    0x14(%ebp),%eax
f01012c5:	8b 10                	mov    (%eax),%edx
f01012c7:	8b 48 04             	mov    0x4(%eax),%ecx
f01012ca:	8d 40 08             	lea    0x8(%eax),%eax
f01012cd:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f01012d0:	b8 10 00 00 00       	mov    $0x10,%eax
f01012d5:	eb 30                	jmp    f0101307 <vprintfmt+0x45f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f01012d7:	85 c9                	test   %ecx,%ecx
f01012d9:	74 17                	je     f01012f2 <vprintfmt+0x44a>
		return va_arg(*ap, unsigned long);
f01012db:	8b 45 14             	mov    0x14(%ebp),%eax
f01012de:	8b 10                	mov    (%eax),%edx
f01012e0:	b9 00 00 00 00       	mov    $0x0,%ecx
f01012e5:	8d 40 04             	lea    0x4(%eax),%eax
f01012e8:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f01012eb:	b8 10 00 00 00       	mov    $0x10,%eax
f01012f0:	eb 15                	jmp    f0101307 <vprintfmt+0x45f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f01012f2:	8b 45 14             	mov    0x14(%ebp),%eax
f01012f5:	8b 10                	mov    (%eax),%edx
f01012f7:	b9 00 00 00 00       	mov    $0x0,%ecx
f01012fc:	8d 40 04             	lea    0x4(%eax),%eax
f01012ff:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0101302:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101307:	83 ec 0c             	sub    $0xc,%esp
f010130a:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f010130e:	57                   	push   %edi
f010130f:	ff 75 e0             	pushl  -0x20(%ebp)
f0101312:	50                   	push   %eax
f0101313:	51                   	push   %ecx
f0101314:	52                   	push   %edx
f0101315:	89 da                	mov    %ebx,%edx
f0101317:	89 f0                	mov    %esi,%eax
f0101319:	e8 bd f9 ff ff       	call   f0100cdb <printnum>
			break;
f010131e:	83 c4 20             	add    $0x20,%esp
f0101321:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101324:	e9 a5 fb ff ff       	jmp    f0100ece <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0101329:	83 ec 08             	sub    $0x8,%esp
f010132c:	53                   	push   %ebx
f010132d:	52                   	push   %edx
f010132e:	ff d6                	call   *%esi
			break;
f0101330:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101333:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0101336:	e9 93 fb ff ff       	jmp    f0100ece <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f010133b:	83 ec 08             	sub    $0x8,%esp
f010133e:	53                   	push   %ebx
f010133f:	6a 25                	push   $0x25
f0101341:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101343:	83 c4 10             	add    $0x10,%esp
f0101346:	eb 03                	jmp    f010134b <vprintfmt+0x4a3>
f0101348:	83 ef 01             	sub    $0x1,%edi
f010134b:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f010134f:	75 f7                	jne    f0101348 <vprintfmt+0x4a0>
f0101351:	e9 78 fb ff ff       	jmp    f0100ece <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0101356:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101359:	5b                   	pop    %ebx
f010135a:	5e                   	pop    %esi
f010135b:	5f                   	pop    %edi
f010135c:	5d                   	pop    %ebp
f010135d:	c3                   	ret    

f010135e <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f010135e:	55                   	push   %ebp
f010135f:	89 e5                	mov    %esp,%ebp
f0101361:	83 ec 18             	sub    $0x18,%esp
f0101364:	8b 45 08             	mov    0x8(%ebp),%eax
f0101367:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010136a:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010136d:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101371:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101374:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010137b:	85 c0                	test   %eax,%eax
f010137d:	74 26                	je     f01013a5 <vsnprintf+0x47>
f010137f:	85 d2                	test   %edx,%edx
f0101381:	7e 22                	jle    f01013a5 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101383:	ff 75 14             	pushl  0x14(%ebp)
f0101386:	ff 75 10             	pushl  0x10(%ebp)
f0101389:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010138c:	50                   	push   %eax
f010138d:	68 6e 0e 10 f0       	push   $0xf0100e6e
f0101392:	e8 11 fb ff ff       	call   f0100ea8 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101397:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010139a:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010139d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01013a0:	83 c4 10             	add    $0x10,%esp
f01013a3:	eb 05                	jmp    f01013aa <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01013a5:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01013aa:	c9                   	leave  
f01013ab:	c3                   	ret    

f01013ac <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01013ac:	55                   	push   %ebp
f01013ad:	89 e5                	mov    %esp,%ebp
f01013af:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01013b2:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01013b5:	50                   	push   %eax
f01013b6:	ff 75 10             	pushl  0x10(%ebp)
f01013b9:	ff 75 0c             	pushl  0xc(%ebp)
f01013bc:	ff 75 08             	pushl  0x8(%ebp)
f01013bf:	e8 9a ff ff ff       	call   f010135e <vsnprintf>
	va_end(ap);

	return rc;
}
f01013c4:	c9                   	leave  
f01013c5:	c3                   	ret    

f01013c6 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01013c6:	55                   	push   %ebp
f01013c7:	89 e5                	mov    %esp,%ebp
f01013c9:	57                   	push   %edi
f01013ca:	56                   	push   %esi
f01013cb:	53                   	push   %ebx
f01013cc:	83 ec 0c             	sub    $0xc,%esp
f01013cf:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01013d2:	85 c0                	test   %eax,%eax
f01013d4:	74 11                	je     f01013e7 <readline+0x21>
		cprintf("%s", prompt);
f01013d6:	83 ec 08             	sub    $0x8,%esp
f01013d9:	50                   	push   %eax
f01013da:	68 36 27 10 f0       	push   $0xf0102736
f01013df:	e8 0a f6 ff ff       	call   f01009ee <cprintf>
f01013e4:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f01013e7:	83 ec 0c             	sub    $0xc,%esp
f01013ea:	6a 00                	push   $0x0
f01013ec:	e8 6b f2 ff ff       	call   f010065c <iscons>
f01013f1:	89 c7                	mov    %eax,%edi
f01013f3:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01013f6:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01013fb:	e8 4b f2 ff ff       	call   f010064b <getchar>
f0101400:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0101402:	85 c0                	test   %eax,%eax
f0101404:	79 18                	jns    f010141e <readline+0x58>
			cprintf("read error: %e\n", c);
f0101406:	83 ec 08             	sub    $0x8,%esp
f0101409:	50                   	push   %eax
f010140a:	68 48 29 10 f0       	push   $0xf0102948
f010140f:	e8 da f5 ff ff       	call   f01009ee <cprintf>
			return NULL;
f0101414:	83 c4 10             	add    $0x10,%esp
f0101417:	b8 00 00 00 00       	mov    $0x0,%eax
f010141c:	eb 79                	jmp    f0101497 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f010141e:	83 f8 7f             	cmp    $0x7f,%eax
f0101421:	0f 94 c2             	sete   %dl
f0101424:	83 f8 08             	cmp    $0x8,%eax
f0101427:	0f 94 c0             	sete   %al
f010142a:	08 c2                	or     %al,%dl
f010142c:	74 1a                	je     f0101448 <readline+0x82>
f010142e:	85 f6                	test   %esi,%esi
f0101430:	7e 16                	jle    f0101448 <readline+0x82>
			if (echoing)
f0101432:	85 ff                	test   %edi,%edi
f0101434:	74 0d                	je     f0101443 <readline+0x7d>
				cputchar('\b');
f0101436:	83 ec 0c             	sub    $0xc,%esp
f0101439:	6a 08                	push   $0x8
f010143b:	e8 fb f1 ff ff       	call   f010063b <cputchar>
f0101440:	83 c4 10             	add    $0x10,%esp
			i--;
f0101443:	83 ee 01             	sub    $0x1,%esi
f0101446:	eb b3                	jmp    f01013fb <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101448:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010144e:	7f 20                	jg     f0101470 <readline+0xaa>
f0101450:	83 fb 1f             	cmp    $0x1f,%ebx
f0101453:	7e 1b                	jle    f0101470 <readline+0xaa>
			if (echoing)
f0101455:	85 ff                	test   %edi,%edi
f0101457:	74 0c                	je     f0101465 <readline+0x9f>
				cputchar(c);
f0101459:	83 ec 0c             	sub    $0xc,%esp
f010145c:	53                   	push   %ebx
f010145d:	e8 d9 f1 ff ff       	call   f010063b <cputchar>
f0101462:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0101465:	88 9e 80 35 11 f0    	mov    %bl,-0xfeeca80(%esi)
f010146b:	8d 76 01             	lea    0x1(%esi),%esi
f010146e:	eb 8b                	jmp    f01013fb <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0101470:	83 fb 0d             	cmp    $0xd,%ebx
f0101473:	74 05                	je     f010147a <readline+0xb4>
f0101475:	83 fb 0a             	cmp    $0xa,%ebx
f0101478:	75 81                	jne    f01013fb <readline+0x35>
			if (echoing)
f010147a:	85 ff                	test   %edi,%edi
f010147c:	74 0d                	je     f010148b <readline+0xc5>
				cputchar('\n');
f010147e:	83 ec 0c             	sub    $0xc,%esp
f0101481:	6a 0a                	push   $0xa
f0101483:	e8 b3 f1 ff ff       	call   f010063b <cputchar>
f0101488:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f010148b:	c6 86 80 35 11 f0 00 	movb   $0x0,-0xfeeca80(%esi)
			return buf;
f0101492:	b8 80 35 11 f0       	mov    $0xf0113580,%eax
		}
	}
}
f0101497:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010149a:	5b                   	pop    %ebx
f010149b:	5e                   	pop    %esi
f010149c:	5f                   	pop    %edi
f010149d:	5d                   	pop    %ebp
f010149e:	c3                   	ret    

f010149f <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f010149f:	55                   	push   %ebp
f01014a0:	89 e5                	mov    %esp,%ebp
f01014a2:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01014a5:	b8 00 00 00 00       	mov    $0x0,%eax
f01014aa:	eb 03                	jmp    f01014af <strlen+0x10>
		n++;
f01014ac:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01014af:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01014b3:	75 f7                	jne    f01014ac <strlen+0xd>
		n++;
	return n;
}
f01014b5:	5d                   	pop    %ebp
f01014b6:	c3                   	ret    

f01014b7 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01014b7:	55                   	push   %ebp
f01014b8:	89 e5                	mov    %esp,%ebp
f01014ba:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01014bd:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01014c0:	ba 00 00 00 00       	mov    $0x0,%edx
f01014c5:	eb 03                	jmp    f01014ca <strnlen+0x13>
		n++;
f01014c7:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01014ca:	39 c2                	cmp    %eax,%edx
f01014cc:	74 08                	je     f01014d6 <strnlen+0x1f>
f01014ce:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f01014d2:	75 f3                	jne    f01014c7 <strnlen+0x10>
f01014d4:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f01014d6:	5d                   	pop    %ebp
f01014d7:	c3                   	ret    

f01014d8 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01014d8:	55                   	push   %ebp
f01014d9:	89 e5                	mov    %esp,%ebp
f01014db:	53                   	push   %ebx
f01014dc:	8b 45 08             	mov    0x8(%ebp),%eax
f01014df:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01014e2:	89 c2                	mov    %eax,%edx
f01014e4:	83 c2 01             	add    $0x1,%edx
f01014e7:	83 c1 01             	add    $0x1,%ecx
f01014ea:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01014ee:	88 5a ff             	mov    %bl,-0x1(%edx)
f01014f1:	84 db                	test   %bl,%bl
f01014f3:	75 ef                	jne    f01014e4 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01014f5:	5b                   	pop    %ebx
f01014f6:	5d                   	pop    %ebp
f01014f7:	c3                   	ret    

f01014f8 <strcat>:

char *
strcat(char *dst, const char *src)
{
f01014f8:	55                   	push   %ebp
f01014f9:	89 e5                	mov    %esp,%ebp
f01014fb:	53                   	push   %ebx
f01014fc:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01014ff:	53                   	push   %ebx
f0101500:	e8 9a ff ff ff       	call   f010149f <strlen>
f0101505:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0101508:	ff 75 0c             	pushl  0xc(%ebp)
f010150b:	01 d8                	add    %ebx,%eax
f010150d:	50                   	push   %eax
f010150e:	e8 c5 ff ff ff       	call   f01014d8 <strcpy>
	return dst;
}
f0101513:	89 d8                	mov    %ebx,%eax
f0101515:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101518:	c9                   	leave  
f0101519:	c3                   	ret    

f010151a <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010151a:	55                   	push   %ebp
f010151b:	89 e5                	mov    %esp,%ebp
f010151d:	56                   	push   %esi
f010151e:	53                   	push   %ebx
f010151f:	8b 75 08             	mov    0x8(%ebp),%esi
f0101522:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101525:	89 f3                	mov    %esi,%ebx
f0101527:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010152a:	89 f2                	mov    %esi,%edx
f010152c:	eb 0f                	jmp    f010153d <strncpy+0x23>
		*dst++ = *src;
f010152e:	83 c2 01             	add    $0x1,%edx
f0101531:	0f b6 01             	movzbl (%ecx),%eax
f0101534:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101537:	80 39 01             	cmpb   $0x1,(%ecx)
f010153a:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010153d:	39 da                	cmp    %ebx,%edx
f010153f:	75 ed                	jne    f010152e <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101541:	89 f0                	mov    %esi,%eax
f0101543:	5b                   	pop    %ebx
f0101544:	5e                   	pop    %esi
f0101545:	5d                   	pop    %ebp
f0101546:	c3                   	ret    

f0101547 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101547:	55                   	push   %ebp
f0101548:	89 e5                	mov    %esp,%ebp
f010154a:	56                   	push   %esi
f010154b:	53                   	push   %ebx
f010154c:	8b 75 08             	mov    0x8(%ebp),%esi
f010154f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101552:	8b 55 10             	mov    0x10(%ebp),%edx
f0101555:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101557:	85 d2                	test   %edx,%edx
f0101559:	74 21                	je     f010157c <strlcpy+0x35>
f010155b:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f010155f:	89 f2                	mov    %esi,%edx
f0101561:	eb 09                	jmp    f010156c <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101563:	83 c2 01             	add    $0x1,%edx
f0101566:	83 c1 01             	add    $0x1,%ecx
f0101569:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f010156c:	39 c2                	cmp    %eax,%edx
f010156e:	74 09                	je     f0101579 <strlcpy+0x32>
f0101570:	0f b6 19             	movzbl (%ecx),%ebx
f0101573:	84 db                	test   %bl,%bl
f0101575:	75 ec                	jne    f0101563 <strlcpy+0x1c>
f0101577:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0101579:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f010157c:	29 f0                	sub    %esi,%eax
}
f010157e:	5b                   	pop    %ebx
f010157f:	5e                   	pop    %esi
f0101580:	5d                   	pop    %ebp
f0101581:	c3                   	ret    

f0101582 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101582:	55                   	push   %ebp
f0101583:	89 e5                	mov    %esp,%ebp
f0101585:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101588:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f010158b:	eb 06                	jmp    f0101593 <strcmp+0x11>
		p++, q++;
f010158d:	83 c1 01             	add    $0x1,%ecx
f0101590:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0101593:	0f b6 01             	movzbl (%ecx),%eax
f0101596:	84 c0                	test   %al,%al
f0101598:	74 04                	je     f010159e <strcmp+0x1c>
f010159a:	3a 02                	cmp    (%edx),%al
f010159c:	74 ef                	je     f010158d <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f010159e:	0f b6 c0             	movzbl %al,%eax
f01015a1:	0f b6 12             	movzbl (%edx),%edx
f01015a4:	29 d0                	sub    %edx,%eax
}
f01015a6:	5d                   	pop    %ebp
f01015a7:	c3                   	ret    

f01015a8 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01015a8:	55                   	push   %ebp
f01015a9:	89 e5                	mov    %esp,%ebp
f01015ab:	53                   	push   %ebx
f01015ac:	8b 45 08             	mov    0x8(%ebp),%eax
f01015af:	8b 55 0c             	mov    0xc(%ebp),%edx
f01015b2:	89 c3                	mov    %eax,%ebx
f01015b4:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01015b7:	eb 06                	jmp    f01015bf <strncmp+0x17>
		n--, p++, q++;
f01015b9:	83 c0 01             	add    $0x1,%eax
f01015bc:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01015bf:	39 d8                	cmp    %ebx,%eax
f01015c1:	74 15                	je     f01015d8 <strncmp+0x30>
f01015c3:	0f b6 08             	movzbl (%eax),%ecx
f01015c6:	84 c9                	test   %cl,%cl
f01015c8:	74 04                	je     f01015ce <strncmp+0x26>
f01015ca:	3a 0a                	cmp    (%edx),%cl
f01015cc:	74 eb                	je     f01015b9 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01015ce:	0f b6 00             	movzbl (%eax),%eax
f01015d1:	0f b6 12             	movzbl (%edx),%edx
f01015d4:	29 d0                	sub    %edx,%eax
f01015d6:	eb 05                	jmp    f01015dd <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01015d8:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01015dd:	5b                   	pop    %ebx
f01015de:	5d                   	pop    %ebp
f01015df:	c3                   	ret    

f01015e0 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01015e0:	55                   	push   %ebp
f01015e1:	89 e5                	mov    %esp,%ebp
f01015e3:	8b 45 08             	mov    0x8(%ebp),%eax
f01015e6:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01015ea:	eb 07                	jmp    f01015f3 <strchr+0x13>
		if (*s == c)
f01015ec:	38 ca                	cmp    %cl,%dl
f01015ee:	74 0f                	je     f01015ff <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01015f0:	83 c0 01             	add    $0x1,%eax
f01015f3:	0f b6 10             	movzbl (%eax),%edx
f01015f6:	84 d2                	test   %dl,%dl
f01015f8:	75 f2                	jne    f01015ec <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f01015fa:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01015ff:	5d                   	pop    %ebp
f0101600:	c3                   	ret    

f0101601 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101601:	55                   	push   %ebp
f0101602:	89 e5                	mov    %esp,%ebp
f0101604:	8b 45 08             	mov    0x8(%ebp),%eax
f0101607:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010160b:	eb 03                	jmp    f0101610 <strfind+0xf>
f010160d:	83 c0 01             	add    $0x1,%eax
f0101610:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0101613:	84 d2                	test   %dl,%dl
f0101615:	74 04                	je     f010161b <strfind+0x1a>
f0101617:	38 ca                	cmp    %cl,%dl
f0101619:	75 f2                	jne    f010160d <strfind+0xc>
			break;
	return (char *) s;
}
f010161b:	5d                   	pop    %ebp
f010161c:	c3                   	ret    

f010161d <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f010161d:	55                   	push   %ebp
f010161e:	89 e5                	mov    %esp,%ebp
f0101620:	57                   	push   %edi
f0101621:	56                   	push   %esi
f0101622:	53                   	push   %ebx
f0101623:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101626:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101629:	85 c9                	test   %ecx,%ecx
f010162b:	74 36                	je     f0101663 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010162d:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101633:	75 28                	jne    f010165d <memset+0x40>
f0101635:	f6 c1 03             	test   $0x3,%cl
f0101638:	75 23                	jne    f010165d <memset+0x40>
		c &= 0xFF;
f010163a:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010163e:	89 d3                	mov    %edx,%ebx
f0101640:	c1 e3 08             	shl    $0x8,%ebx
f0101643:	89 d6                	mov    %edx,%esi
f0101645:	c1 e6 18             	shl    $0x18,%esi
f0101648:	89 d0                	mov    %edx,%eax
f010164a:	c1 e0 10             	shl    $0x10,%eax
f010164d:	09 f0                	or     %esi,%eax
f010164f:	09 c2                	or     %eax,%edx
f0101651:	89 d0                	mov    %edx,%eax
f0101653:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0101655:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0101658:	fc                   	cld    
f0101659:	f3 ab                	rep stos %eax,%es:(%edi)
f010165b:	eb 06                	jmp    f0101663 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010165d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101660:	fc                   	cld    
f0101661:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0101663:	89 f8                	mov    %edi,%eax
f0101665:	5b                   	pop    %ebx
f0101666:	5e                   	pop    %esi
f0101667:	5f                   	pop    %edi
f0101668:	5d                   	pop    %ebp
f0101669:	c3                   	ret    

f010166a <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010166a:	55                   	push   %ebp
f010166b:	89 e5                	mov    %esp,%ebp
f010166d:	57                   	push   %edi
f010166e:	56                   	push   %esi
f010166f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101672:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101675:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101678:	39 c6                	cmp    %eax,%esi
f010167a:	73 35                	jae    f01016b1 <memmove+0x47>
f010167c:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010167f:	39 d0                	cmp    %edx,%eax
f0101681:	73 2e                	jae    f01016b1 <memmove+0x47>
		s += n;
		d += n;
f0101683:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f0101686:	89 d6                	mov    %edx,%esi
f0101688:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010168a:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0101690:	75 13                	jne    f01016a5 <memmove+0x3b>
f0101692:	f6 c1 03             	test   $0x3,%cl
f0101695:	75 0e                	jne    f01016a5 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0101697:	83 ef 04             	sub    $0x4,%edi
f010169a:	8d 72 fc             	lea    -0x4(%edx),%esi
f010169d:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f01016a0:	fd                   	std    
f01016a1:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01016a3:	eb 09                	jmp    f01016ae <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01016a5:	83 ef 01             	sub    $0x1,%edi
f01016a8:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01016ab:	fd                   	std    
f01016ac:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01016ae:	fc                   	cld    
f01016af:	eb 1d                	jmp    f01016ce <memmove+0x64>
f01016b1:	89 f2                	mov    %esi,%edx
f01016b3:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01016b5:	f6 c2 03             	test   $0x3,%dl
f01016b8:	75 0f                	jne    f01016c9 <memmove+0x5f>
f01016ba:	f6 c1 03             	test   $0x3,%cl
f01016bd:	75 0a                	jne    f01016c9 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01016bf:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f01016c2:	89 c7                	mov    %eax,%edi
f01016c4:	fc                   	cld    
f01016c5:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01016c7:	eb 05                	jmp    f01016ce <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01016c9:	89 c7                	mov    %eax,%edi
f01016cb:	fc                   	cld    
f01016cc:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01016ce:	5e                   	pop    %esi
f01016cf:	5f                   	pop    %edi
f01016d0:	5d                   	pop    %ebp
f01016d1:	c3                   	ret    

f01016d2 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01016d2:	55                   	push   %ebp
f01016d3:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01016d5:	ff 75 10             	pushl  0x10(%ebp)
f01016d8:	ff 75 0c             	pushl  0xc(%ebp)
f01016db:	ff 75 08             	pushl  0x8(%ebp)
f01016de:	e8 87 ff ff ff       	call   f010166a <memmove>
}
f01016e3:	c9                   	leave  
f01016e4:	c3                   	ret    

f01016e5 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01016e5:	55                   	push   %ebp
f01016e6:	89 e5                	mov    %esp,%ebp
f01016e8:	56                   	push   %esi
f01016e9:	53                   	push   %ebx
f01016ea:	8b 45 08             	mov    0x8(%ebp),%eax
f01016ed:	8b 55 0c             	mov    0xc(%ebp),%edx
f01016f0:	89 c6                	mov    %eax,%esi
f01016f2:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01016f5:	eb 1a                	jmp    f0101711 <memcmp+0x2c>
		if (*s1 != *s2)
f01016f7:	0f b6 08             	movzbl (%eax),%ecx
f01016fa:	0f b6 1a             	movzbl (%edx),%ebx
f01016fd:	38 d9                	cmp    %bl,%cl
f01016ff:	74 0a                	je     f010170b <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0101701:	0f b6 c1             	movzbl %cl,%eax
f0101704:	0f b6 db             	movzbl %bl,%ebx
f0101707:	29 d8                	sub    %ebx,%eax
f0101709:	eb 0f                	jmp    f010171a <memcmp+0x35>
		s1++, s2++;
f010170b:	83 c0 01             	add    $0x1,%eax
f010170e:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101711:	39 f0                	cmp    %esi,%eax
f0101713:	75 e2                	jne    f01016f7 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0101715:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010171a:	5b                   	pop    %ebx
f010171b:	5e                   	pop    %esi
f010171c:	5d                   	pop    %ebp
f010171d:	c3                   	ret    

f010171e <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010171e:	55                   	push   %ebp
f010171f:	89 e5                	mov    %esp,%ebp
f0101721:	8b 45 08             	mov    0x8(%ebp),%eax
f0101724:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0101727:	89 c2                	mov    %eax,%edx
f0101729:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f010172c:	eb 07                	jmp    f0101735 <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f010172e:	38 08                	cmp    %cl,(%eax)
f0101730:	74 07                	je     f0101739 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0101732:	83 c0 01             	add    $0x1,%eax
f0101735:	39 d0                	cmp    %edx,%eax
f0101737:	72 f5                	jb     f010172e <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0101739:	5d                   	pop    %ebp
f010173a:	c3                   	ret    

f010173b <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f010173b:	55                   	push   %ebp
f010173c:	89 e5                	mov    %esp,%ebp
f010173e:	57                   	push   %edi
f010173f:	56                   	push   %esi
f0101740:	53                   	push   %ebx
f0101741:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101744:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101747:	eb 03                	jmp    f010174c <strtol+0x11>
		s++;
f0101749:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010174c:	0f b6 01             	movzbl (%ecx),%eax
f010174f:	3c 09                	cmp    $0x9,%al
f0101751:	74 f6                	je     f0101749 <strtol+0xe>
f0101753:	3c 20                	cmp    $0x20,%al
f0101755:	74 f2                	je     f0101749 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0101757:	3c 2b                	cmp    $0x2b,%al
f0101759:	75 0a                	jne    f0101765 <strtol+0x2a>
		s++;
f010175b:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f010175e:	bf 00 00 00 00       	mov    $0x0,%edi
f0101763:	eb 10                	jmp    f0101775 <strtol+0x3a>
f0101765:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f010176a:	3c 2d                	cmp    $0x2d,%al
f010176c:	75 07                	jne    f0101775 <strtol+0x3a>
		s++, neg = 1;
f010176e:	8d 49 01             	lea    0x1(%ecx),%ecx
f0101771:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101775:	85 db                	test   %ebx,%ebx
f0101777:	0f 94 c0             	sete   %al
f010177a:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0101780:	75 19                	jne    f010179b <strtol+0x60>
f0101782:	80 39 30             	cmpb   $0x30,(%ecx)
f0101785:	75 14                	jne    f010179b <strtol+0x60>
f0101787:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f010178b:	0f 85 82 00 00 00    	jne    f0101813 <strtol+0xd8>
		s += 2, base = 16;
f0101791:	83 c1 02             	add    $0x2,%ecx
f0101794:	bb 10 00 00 00       	mov    $0x10,%ebx
f0101799:	eb 16                	jmp    f01017b1 <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f010179b:	84 c0                	test   %al,%al
f010179d:	74 12                	je     f01017b1 <strtol+0x76>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010179f:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01017a4:	80 39 30             	cmpb   $0x30,(%ecx)
f01017a7:	75 08                	jne    f01017b1 <strtol+0x76>
		s++, base = 8;
f01017a9:	83 c1 01             	add    $0x1,%ecx
f01017ac:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f01017b1:	b8 00 00 00 00       	mov    $0x0,%eax
f01017b6:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01017b9:	0f b6 11             	movzbl (%ecx),%edx
f01017bc:	8d 72 d0             	lea    -0x30(%edx),%esi
f01017bf:	89 f3                	mov    %esi,%ebx
f01017c1:	80 fb 09             	cmp    $0x9,%bl
f01017c4:	77 08                	ja     f01017ce <strtol+0x93>
			dig = *s - '0';
f01017c6:	0f be d2             	movsbl %dl,%edx
f01017c9:	83 ea 30             	sub    $0x30,%edx
f01017cc:	eb 22                	jmp    f01017f0 <strtol+0xb5>
		else if (*s >= 'a' && *s <= 'z')
f01017ce:	8d 72 9f             	lea    -0x61(%edx),%esi
f01017d1:	89 f3                	mov    %esi,%ebx
f01017d3:	80 fb 19             	cmp    $0x19,%bl
f01017d6:	77 08                	ja     f01017e0 <strtol+0xa5>
			dig = *s - 'a' + 10;
f01017d8:	0f be d2             	movsbl %dl,%edx
f01017db:	83 ea 57             	sub    $0x57,%edx
f01017de:	eb 10                	jmp    f01017f0 <strtol+0xb5>
		else if (*s >= 'A' && *s <= 'Z')
f01017e0:	8d 72 bf             	lea    -0x41(%edx),%esi
f01017e3:	89 f3                	mov    %esi,%ebx
f01017e5:	80 fb 19             	cmp    $0x19,%bl
f01017e8:	77 16                	ja     f0101800 <strtol+0xc5>
			dig = *s - 'A' + 10;
f01017ea:	0f be d2             	movsbl %dl,%edx
f01017ed:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f01017f0:	3b 55 10             	cmp    0x10(%ebp),%edx
f01017f3:	7d 0f                	jge    f0101804 <strtol+0xc9>
			break;
		s++, val = (val * base) + dig;
f01017f5:	83 c1 01             	add    $0x1,%ecx
f01017f8:	0f af 45 10          	imul   0x10(%ebp),%eax
f01017fc:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f01017fe:	eb b9                	jmp    f01017b9 <strtol+0x7e>
f0101800:	89 c2                	mov    %eax,%edx
f0101802:	eb 02                	jmp    f0101806 <strtol+0xcb>
f0101804:	89 c2                	mov    %eax,%edx

	if (endptr)
f0101806:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010180a:	74 0d                	je     f0101819 <strtol+0xde>
		*endptr = (char *) s;
f010180c:	8b 75 0c             	mov    0xc(%ebp),%esi
f010180f:	89 0e                	mov    %ecx,(%esi)
f0101811:	eb 06                	jmp    f0101819 <strtol+0xde>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101813:	84 c0                	test   %al,%al
f0101815:	75 92                	jne    f01017a9 <strtol+0x6e>
f0101817:	eb 98                	jmp    f01017b1 <strtol+0x76>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0101819:	f7 da                	neg    %edx
f010181b:	85 ff                	test   %edi,%edi
f010181d:	0f 45 c2             	cmovne %edx,%eax
}
f0101820:	5b                   	pop    %ebx
f0101821:	5e                   	pop    %esi
f0101822:	5f                   	pop    %edi
f0101823:	5d                   	pop    %ebp
f0101824:	c3                   	ret    

f0101825 <subtract_List_Operation>:
#include <inc/calculator.h>



void subtract_List_Operation(operantion op[])
{
f0101825:	55                   	push   %ebp
f0101826:	89 e5                	mov    %esp,%ebp
f0101828:	8b 55 08             	mov    0x8(%ebp),%edx
f010182b:	89 d0                	mov    %edx,%eax
f010182d:	83 c2 30             	add    $0x30,%edx
	int i;
	for (i = 0; i < 6; i++)
	{
		op[i].position = op[i].position - 1;
f0101830:	83 28 01             	subl   $0x1,(%eax)
f0101833:	83 c0 08             	add    $0x8,%eax


void subtract_List_Operation(operantion op[])
{
	int i;
	for (i = 0; i < 6; i++)
f0101836:	39 d0                	cmp    %edx,%eax
f0101838:	75 f6                	jne    f0101830 <subtract_List_Operation+0xb>
	{
		op[i].position = op[i].position - 1;
	}
}
f010183a:	5d                   	pop    %ebp
f010183b:	c3                   	ret    

f010183c <Isoperation>:

int Isoperation(char r)
{
f010183c:	55                   	push   %ebp
f010183d:	89 e5                	mov    %esp,%ebp
f010183f:	8b 55 08             	mov    0x8(%ebp),%edx
	if (r == '+' || r == '-' || r == '*' || r == '/' || r == '%')
f0101842:	89 d0                	mov    %edx,%eax
f0101844:	83 e0 f7             	and    $0xfffffff7,%eax
f0101847:	3c 25                	cmp    $0x25,%al
f0101849:	0f 94 c1             	sete   %cl
f010184c:	80 fa 2f             	cmp    $0x2f,%dl
f010184f:	0f 94 c0             	sete   %al
f0101852:	09 c8                	or     %ecx,%eax
f0101854:	83 ea 2a             	sub    $0x2a,%edx
f0101857:	80 fa 01             	cmp    $0x1,%dl
f010185a:	0f 96 c2             	setbe  %dl
f010185d:	09 d0                	or     %edx,%eax
f010185f:	0f b6 c0             	movzbl %al,%eax
	}
	else
	{
		return 0;
	}
}
f0101862:	5d                   	pop    %ebp
f0101863:	c3                   	ret    

f0101864 <Isnumber>:


int Isnumber(char r)
{
f0101864:	55                   	push   %ebp
f0101865:	89 e5                	mov    %esp,%ebp
	if (r >= '0' && r <= '9')
f0101867:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
f010186b:	83 e8 30             	sub    $0x30,%eax
f010186e:	3c 09                	cmp    $0x9,%al
f0101870:	0f 96 c0             	setbe  %al
f0101873:	0f b6 c0             	movzbl %al,%eax
	}
	else
	{
		return 0;
	}
}
f0101876:	5d                   	pop    %ebp
f0101877:	c3                   	ret    

f0101878 <Isdot>:

int Isdot(char r)
{
f0101878:	55                   	push   %ebp
f0101879:	89 e5                	mov    %esp,%ebp
	if (r == '.')
f010187b:	80 7d 08 2e          	cmpb   $0x2e,0x8(%ebp)
f010187f:	0f 94 c0             	sete   %al
f0101882:	0f b6 c0             	movzbl %al,%eax
	else
	{
		return 0;
	}

}
f0101885:	5d                   	pop    %ebp
f0101886:	c3                   	ret    

f0101887 <removeItem>:

void removeItem(float str[], int location)
{
f0101887:	55                   	push   %ebp
f0101888:	89 e5                	mov    %esp,%ebp
f010188a:	8b 55 08             	mov    0x8(%ebp),%edx
f010188d:	8b 45 0c             	mov    0xc(%ebp),%eax
	int i;

	for (i = location; i < 6; i++)
f0101890:	eb 0a                	jmp    f010189c <removeItem+0x15>
	{
		str[i] = str[i + 1];
f0101892:	d9 44 82 04          	flds   0x4(%edx,%eax,4)
f0101896:	d9 1c 82             	fstps  (%edx,%eax,4)

void removeItem(float str[], int location)
{
	int i;

	for (i = location; i < 6; i++)
f0101899:	83 c0 01             	add    $0x1,%eax
f010189c:	83 f8 05             	cmp    $0x5,%eax
f010189f:	7e f1                	jle    f0101892 <removeItem+0xb>
	{
		str[i] = str[i + 1];
	}

	str[5] = 0;
f01018a1:	c7 42 14 00 00 00 00 	movl   $0x0,0x14(%edx)

}
f01018a8:	5d                   	pop    %ebp
f01018a9:	c3                   	ret    

f01018aa <Getnumber>:



Float Getnumber(char* str, int *i)
{   
f01018aa:	55                   	push   %ebp
f01018ab:	89 e5                	mov    %esp,%ebp
f01018ad:	57                   	push   %edi
f01018ae:	56                   	push   %esi
f01018af:	53                   	push   %ebx
f01018b0:	81 ec 9c 00 00 00    	sub    $0x9c,%esp
f01018b6:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01018b9:	8b 5d 10             	mov    0x10(%ebp),%ebx
f01018bc:	8d 45 84             	lea    -0x7c(%ebp),%eax
f01018bf:	8d 55 e8             	lea    -0x18(%ebp),%edx
	int dot = 1;
	int y = 1;
	char number[100];
	for(x = 0 ;x < 100; x++)
	{
	number[x] = '0';
f01018c2:	c6 00 30             	movb   $0x30,(%eax)
f01018c5:	83 c0 01             	add    $0x1,%eax
	int x = 0;
	Float Value;
	int dot = 1;
	int y = 1;
	char number[100];
	for(x = 0 ;x < 100; x++)
f01018c8:	39 d0                	cmp    %edx,%eax
f01018ca:	75 f6                	jne    f01018c2 <Getnumber+0x18>
	{
	number[x] = '0';
	}
	number[strlen(str)] = '\0';
f01018cc:	83 ec 0c             	sub    $0xc,%esp
f01018cf:	57                   	push   %edi
f01018d0:	e8 ca fb ff ff       	call   f010149f <strlen>
f01018d5:	c6 44 05 84 00       	movb   $0x0,-0x7c(%ebp,%eax,1)
	number[0] = str[*i];
f01018da:	8b 03                	mov    (%ebx),%eax
f01018dc:	0f b6 14 07          	movzbl (%edi,%eax,1),%edx
f01018e0:	88 55 84             	mov    %dl,-0x7c(%ebp)
	*i=*i+1;
f01018e3:	83 c0 01             	add    $0x1,%eax
f01018e6:	89 85 60 ff ff ff    	mov    %eax,-0xa0(%ebp)
f01018ec:	89 03                	mov    %eax,(%ebx)
	int j=*i;
	while (*i < strlen(str))
f01018ee:	83 c4 10             	add    $0x10,%esp
f01018f1:	be 02 00 00 00       	mov    $0x2,%esi

Float Getnumber(char* str, int *i)
{   
	int x = 0;
	Float Value;
	int dot = 1;
f01018f6:	c7 85 64 ff ff ff 01 	movl   $0x1,-0x9c(%ebp)
f01018fd:	00 00 00 
	}
	number[strlen(str)] = '\0';
	number[0] = str[*i];
	*i=*i+1;
	int j=*i;
	while (*i < strlen(str))
f0101900:	e9 8b 00 00 00       	jmp    f0101990 <Getnumber+0xe6>
	{
		cprintf("I form inside Getnumber %d\n",*i);
f0101905:	83 ec 08             	sub    $0x8,%esp
f0101908:	ff 33                	pushl  (%ebx)
f010190a:	68 58 29 10 f0       	push   $0xf0102958
f010190f:	e8 da f0 ff ff       	call   f01009ee <cprintf>
		if (Isnumber(str[*i]))
f0101914:	8b 03                	mov    (%ebx),%eax
f0101916:	0f b6 14 07          	movzbl (%edi,%eax,1),%edx
}


int Isnumber(char r)
{
	if (r >= '0' && r <= '9')
f010191a:	8d 4a d0             	lea    -0x30(%edx),%ecx
	*i=*i+1;
	int j=*i;
	while (*i < strlen(str))
	{
		cprintf("I form inside Getnumber %d\n",*i);
		if (Isnumber(str[*i]))
f010191d:	83 c4 10             	add    $0x10,%esp
f0101920:	80 f9 09             	cmp    $0x9,%cl
f0101923:	77 0b                	ja     f0101930 <Getnumber+0x86>
		{
			number[y] = str[*i];
f0101925:	88 54 35 83          	mov    %dl,-0x7d(%ebp,%esi,1)
			y++;
			*i=*i+1;
f0101929:	83 c0 01             	add    $0x1,%eax
f010192c:	89 03                	mov    %eax,(%ebx)
f010192e:	eb 5d                	jmp    f010198d <Getnumber+0xe3>

		}
		else if (Isdot((str[*i])) && dot)
f0101930:	83 bd 64 ff ff ff 00 	cmpl   $0x0,-0x9c(%ebp)
f0101937:	0f 95 c1             	setne  %cl
f010193a:	74 17                	je     f0101953 <Getnumber+0xa9>
f010193c:	80 fa 2e             	cmp    $0x2e,%dl
f010193f:	75 12                	jne    f0101953 <Getnumber+0xa9>
		{
			number[y] = str[*i];
f0101941:	88 54 35 83          	mov    %dl,-0x7d(%ebp,%esi,1)
			dot--;
f0101945:	83 ad 64 ff ff ff 01 	subl   $0x1,-0x9c(%ebp)
			y++;
			*i=*i+1;
f010194c:	83 c0 01             	add    $0x1,%eax
f010194f:	89 03                	mov    %eax,(%ebx)
f0101951:	eb 3a                	jmp    f010198d <Getnumber+0xe3>
f0101953:	89 cf                	mov    %ecx,%edi
		}
		else if ( Isoperation(str[*i]) )
f0101955:	83 ec 0c             	sub    $0xc,%esp
	*i=*i+1;
	int j=*i;
	while (*i < strlen(str))
	{
		cprintf("I form inside Getnumber %d\n",*i);
		if (Isnumber(str[*i]))
f0101958:	0f be d2             	movsbl %dl,%edx
			number[y] = str[*i];
			dot--;
			y++;
			*i=*i+1;
		}
		else if ( Isoperation(str[*i]) )
f010195b:	52                   	push   %edx
f010195c:	e8 db fe ff ff       	call   f010183c <Isoperation>
f0101961:	83 c4 10             	add    $0x10,%esp
f0101964:	85 c0                	test   %eax,%eax
f0101966:	74 13                	je     f010197b <Getnumber+0xd1>
	        {
			if (dot)
f0101968:	89 f8                	mov    %edi,%eax
f010196a:	84 c0                	test   %al,%al
f010196c:	74 4b                	je     f01019b9 <Getnumber+0x10f>
		             {
	         	number[y] = '.';
f010196e:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
f0101974:	c6 44 05 84 2e       	movb   $0x2e,-0x7c(%ebp,%eax,1)
f0101979:	eb 3e                	jmp    f01019b9 <Getnumber+0x10f>
			}
		else
		{
			Value.error = 1;
			Value.number = 1;
			return Value;
f010197b:	8b 45 08             	mov    0x8(%ebp),%eax
f010197e:	c7 00 00 00 80 3f    	movl   $0x3f800000,(%eax)
f0101984:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
f010198b:	eb 63                	jmp    f01019f0 <Getnumber+0x146>
f010198d:	83 c6 01             	add    $0x1,%esi
f0101990:	8d 46 ff             	lea    -0x1(%esi),%eax
f0101993:	89 85 68 ff ff ff    	mov    %eax,-0x98(%ebp)
	}
	number[strlen(str)] = '\0';
	number[0] = str[*i];
	*i=*i+1;
	int j=*i;
	while (*i < strlen(str))
f0101999:	8b 03                	mov    (%ebx),%eax
f010199b:	89 85 6c ff ff ff    	mov    %eax,-0x94(%ebp)
f01019a1:	83 ec 0c             	sub    $0xc,%esp
f01019a4:	57                   	push   %edi
f01019a5:	e8 f5 fa ff ff       	call   f010149f <strlen>
f01019aa:	83 c4 10             	add    $0x10,%esp
f01019ad:	39 85 6c ff ff ff    	cmp    %eax,-0x94(%ebp)
f01019b3:	0f 8c 4c ff ff ff    	jl     f0101905 <Getnumber+0x5b>
			Value.error = 1;
			Value.number = 1;
			return Value;
		}
	}
	number[*i-j+1]='\0';
f01019b9:	8b 03                	mov    (%ebx),%eax
f01019bb:	2b 85 60 ff ff ff    	sub    -0xa0(%ebp),%eax
f01019c1:	c6 44 05 85 00       	movb   $0x0,-0x7b(%ebp,%eax,1)
	Value = char_to_float(number);
f01019c6:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
f01019cc:	83 ec 08             	sub    $0x8,%esp
f01019cf:	8d 55 84             	lea    -0x7c(%ebp),%edx
f01019d2:	52                   	push   %edx
f01019d3:	50                   	push   %eax
f01019d4:	e8 9a 03 00 00       	call   f0101d73 <char_to_float>
f01019d9:	8b 85 70 ff ff ff    	mov    -0x90(%ebp),%eax
	return Value;
f01019df:	8b 7d 08             	mov    0x8(%ebp),%edi
f01019e2:	89 07                	mov    %eax,(%edi)
f01019e4:	8b 85 74 ff ff ff    	mov    -0x8c(%ebp),%eax
f01019ea:	89 47 04             	mov    %eax,0x4(%edi)
f01019ed:	83 c4 0c             	add    $0xc,%esp
}
f01019f0:	8b 45 08             	mov    0x8(%ebp),%eax
f01019f3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01019f6:	5b                   	pop    %ebx
f01019f7:	5e                   	pop    %esi
f01019f8:	5f                   	pop    %edi
f01019f9:	5d                   	pop    %ebp
f01019fa:	c2 04 00             	ret    $0x4

f01019fd <GetOperation>:

Char GetOperation(char* str, int i)
{
f01019fd:	55                   	push   %ebp
f01019fe:	89 e5                	mov    %esp,%ebp
f0101a00:	53                   	push   %ebx
f0101a01:	8b 45 08             	mov    0x8(%ebp),%eax
	Char operat;
	if (str[i] == '-' || str[i] == '+' || str[i] == '*' || str[i] == '/' || str[i] == '%')
f0101a04:	8b 55 10             	mov    0x10(%ebp),%edx
f0101a07:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101a0a:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0101a0e:	89 d1                	mov    %edx,%ecx
f0101a10:	83 e1 f7             	and    $0xfffffff7,%ecx
f0101a13:	80 f9 25             	cmp    $0x25,%cl
f0101a16:	0f 94 c3             	sete   %bl
f0101a19:	80 fa 2f             	cmp    $0x2f,%dl
f0101a1c:	0f 94 c1             	sete   %cl
f0101a1f:	08 cb                	or     %cl,%bl
f0101a21:	75 08                	jne    f0101a2b <GetOperation+0x2e>
f0101a23:	8d 4a d6             	lea    -0x2a(%edx),%ecx
f0101a26:	80 f9 01             	cmp    $0x1,%cl
f0101a29:	77 0b                	ja     f0101a36 <GetOperation+0x39>
	{
		operat.error = 0;
		operat.value = str[i];
		return operat;
f0101a2b:	88 10                	mov    %dl,(%eax)
f0101a2d:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
f0101a34:	eb 0a                	jmp    f0101a40 <GetOperation+0x43>
	}
	else
	{
		operat.error = 1;
		operat.value = '0';
		return operat;
f0101a36:	c6 00 30             	movb   $0x30,(%eax)
f0101a39:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
	}

}
f0101a40:	5b                   	pop    %ebx
f0101a41:	5d                   	pop    %ebp
f0101a42:	c2 04 00             	ret    $0x4

f0101a45 <calc>:

void calc(float numbers[], operantion op[])
{
f0101a45:	55                   	push   %ebp
f0101a46:	89 e5                	mov    %esp,%ebp
f0101a48:	57                   	push   %edi
f0101a49:	56                   	push   %esi
f0101a4a:	53                   	push   %ebx
f0101a4b:	83 ec 1c             	sub    $0x1c,%esp
f0101a4e:	8b 75 08             	mov    0x8(%ebp),%esi
f0101a51:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0101a54:	89 fb                	mov    %edi,%ebx
f0101a56:	8d 47 30             	lea    0x30(%edi),%eax
f0101a59:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101a5c:	89 da                	mov    %ebx,%edx
	int i;

	for (i = 0; i < 6; i++)
	{
		if (op[i].operant == '*')
f0101a5e:	0f b6 43 04          	movzbl 0x4(%ebx),%eax
f0101a62:	3c 2a                	cmp    $0x2a,%al
f0101a64:	75 16                	jne    f0101a7c <calc+0x37>
		{
			numbers[op[i].position - 1] = numbers[op[i].position - 1] * numbers[op[i].position];
f0101a66:	8b 03                	mov    (%ebx),%eax
f0101a68:	8d 0c 85 fc ff ff ff 	lea    -0x4(,%eax,4),%ecx
f0101a6f:	8d 04 0e             	lea    (%esi,%ecx,1),%eax
f0101a72:	d9 00                	flds   (%eax)
f0101a74:	d8 4c 0e 04          	fmuls  0x4(%esi,%ecx,1)
f0101a78:	d9 18                	fstps  (%eax)
f0101a7a:	eb 7e                	jmp    f0101afa <calc+0xb5>

		}
		else if (op[i].operant == '/')
f0101a7c:	3c 2f                	cmp    $0x2f,%al
f0101a7e:	75 39                	jne    f0101ab9 <calc+0x74>
		{
			if (numbers[op[i].position ] == 0)
f0101a80:	8b 03                	mov    (%ebx),%eax
f0101a82:	8d 0c 85 00 00 00 00 	lea    0x0(,%eax,4),%ecx
f0101a89:	d9 04 86             	flds   (%esi,%eax,4)
f0101a8c:	d9 ee                	fldz   
f0101a8e:	d9 c9                	fxch   %st(1)
f0101a90:	db e9                	fucomi %st(1),%st
f0101a92:	dd d9                	fstp   %st(1)
f0101a94:	7a 19                	jp     f0101aaf <calc+0x6a>
f0101a96:	75 17                	jne    f0101aaf <calc+0x6a>
f0101a98:	dd d8                	fstp   %st(0)
			{
				cprintf("error");
f0101a9a:	83 ec 0c             	sub    $0xc,%esp
f0101a9d:	68 45 27 10 f0       	push   $0xf0102745
f0101aa2:	e8 47 ef ff ff       	call   f01009ee <cprintf>
				return;
f0101aa7:	83 c4 10             	add    $0x10,%esp
f0101aaa:	e9 8d 00 00 00       	jmp    f0101b3c <calc+0xf7>
			}
			numbers[op[i].position - 1] = numbers[op[i].position - 1] / numbers[op[i].position];
f0101aaf:	8d 44 0e fc          	lea    -0x4(%esi,%ecx,1),%eax
f0101ab3:	d8 38                	fdivrs (%eax)
f0101ab5:	d9 18                	fstps  (%eax)
f0101ab7:	eb 41                	jmp    f0101afa <calc+0xb5>
		}
		else if (op[i].operant == '%')
f0101ab9:	3c 25                	cmp    $0x25,%al
f0101abb:	74 09                	je     f0101ac6 <calc+0x81>
	}

}

void calc(float numbers[], operantion op[])
{
f0101abd:	d9 ee                	fldz   
f0101abf:	b8 00 00 00 00       	mov    $0x0,%eax
f0101ac4:	eb 58                	jmp    f0101b1e <calc+0xd9>
			}
			numbers[op[i].position - 1] = numbers[op[i].position - 1] / numbers[op[i].position];
		}
		else if (op[i].operant == '%')
		{
			if (numbers[op[i].position ] == 0)
f0101ac6:	8b 03                	mov    (%ebx),%eax
f0101ac8:	8d 0c 85 00 00 00 00 	lea    0x0(,%eax,4),%ecx
f0101acf:	d9 04 86             	flds   (%esi,%eax,4)
f0101ad2:	d9 ee                	fldz   
f0101ad4:	d9 c9                	fxch   %st(1)
f0101ad6:	db e9                	fucomi %st(1),%st
f0101ad8:	dd d9                	fstp   %st(1)
f0101ada:	7a 16                	jp     f0101af2 <calc+0xad>
f0101adc:	75 14                	jne    f0101af2 <calc+0xad>
f0101ade:	dd d8                	fstp   %st(0)
			{
				cprintf("error");
f0101ae0:	83 ec 0c             	sub    $0xc,%esp
f0101ae3:	68 45 27 10 f0       	push   $0xf0102745
f0101ae8:	e8 01 ef ff ff       	call   f01009ee <cprintf>
				return;
f0101aed:	83 c4 10             	add    $0x10,%esp
f0101af0:	eb 4a                	jmp    f0101b3c <calc+0xf7>
			}
		int y = (int)(numbers[op[i].position - 1] / numbers[op[i].position]);
		numbers[op[i].position - 1] = numbers[op[i].position - 1] / numbers[op[i].position];
f0101af2:	8d 44 0e fc          	lea    -0x4(%esi,%ecx,1),%eax
f0101af6:	d8 38                	fdivrs (%eax)
f0101af8:	d9 18                	fstps  (%eax)
		}
		else{ break; }
		removeItem(numbers, op[i].position);
f0101afa:	83 ec 08             	sub    $0x8,%esp
f0101afd:	ff 32                	pushl  (%edx)
f0101aff:	56                   	push   %esi
f0101b00:	e8 82 fd ff ff       	call   f0101887 <removeItem>
		subtract_List_Operation(op);
f0101b05:	89 3c 24             	mov    %edi,(%esp)
f0101b08:	e8 18 fd ff ff       	call   f0101825 <subtract_List_Operation>
f0101b0d:	83 c3 08             	add    $0x8,%ebx

void calc(float numbers[], operantion op[])
{
	int i;

	for (i = 0; i < 6; i++)
f0101b10:	83 c4 10             	add    $0x10,%esp
f0101b13:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f0101b16:	0f 85 40 ff ff ff    	jne    f0101a5c <calc+0x17>
f0101b1c:	eb 9f                	jmp    f0101abd <calc+0x78>
	}
	float result;
	result = 0;
	for (i = 0; i < sizeof(numbers); i++)
	{
		result = result + numbers[i];
f0101b1e:	d8 04 86             	fadds  (%esi,%eax,4)
		removeItem(numbers, op[i].position);
		subtract_List_Operation(op);
	}
	float result;
	result = 0;
	for (i = 0; i < sizeof(numbers); i++)
f0101b21:	83 c0 01             	add    $0x1,%eax
f0101b24:	83 f8 04             	cmp    $0x4,%eax
f0101b27:	75 f5                	jne    f0101b1e <calc+0xd9>
	{
		result = result + numbers[i];
	}
	cprintf("%f", result);
f0101b29:	83 ec 0c             	sub    $0xc,%esp
f0101b2c:	dd 1c 24             	fstpl  (%esp)
f0101b2f:	68 da 24 10 f0       	push   $0xf01024da
f0101b34:	e8 b5 ee ff ff       	call   f01009ee <cprintf>
f0101b39:	83 c4 10             	add    $0x10,%esp

}
f0101b3c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101b3f:	5b                   	pop    %ebx
f0101b40:	5e                   	pop    %esi
f0101b41:	5f                   	pop    %edi
f0101b42:	5d                   	pop    %ebp
f0101b43:	c3                   	ret    

f0101b44 <calculator>:

int calculator()
{
f0101b44:	55                   	push   %ebp
f0101b45:	89 e5                	mov    %esp,%ebp
f0101b47:	57                   	push   %edi
f0101b48:	56                   	push   %esi
f0101b49:	53                   	push   %ebx
f0101b4a:	83 ec 6c             	sub    $0x6c,%esp

	operantion oper;
	oper.operant = '0';
	oper.position = 0;

	for (i = 0; i < 6; i++)
f0101b4d:	b8 00 00 00 00       	mov    $0x0,%eax
	{
		numericop[i].operant ='0';
		numericop[i].position = 0 ;
		A[i] = 0;
f0101b52:	d9 ee                	fldz   
	oper.operant = '0';
	oper.position = 0;

	for (i = 0; i < 6; i++)
	{
		numericop[i].operant ='0';
f0101b54:	c6 44 c5 a0 30       	movb   $0x30,-0x60(%ebp,%eax,8)
		numericop[i].position = 0 ;
f0101b59:	c7 44 c5 9c 00 00 00 	movl   $0x0,-0x64(%ebp,%eax,8)
f0101b60:	00 
		A[i] = 0;
f0101b61:	d9 54 85 d0          	fsts   -0x30(%ebp,%eax,4)

	operantion oper;
	oper.operant = '0';
	oper.position = 0;

	for (i = 0; i < 6; i++)
f0101b65:	83 c0 01             	add    $0x1,%eax
f0101b68:	83 f8 05             	cmp    $0x5,%eax
f0101b6b:	7e e7                	jle    f0101b54 <calculator+0x10>
f0101b6d:	dd d8                	fstp   %st(0)
f0101b6f:	89 45 cc             	mov    %eax,-0x34(%ebp)
	{
		numericop[i].operant ='0';
		numericop[i].position = 0 ;
		A[i] = 0;
	}
	cprintf("Expression:");
f0101b72:	83 ec 0c             	sub    $0xc,%esp
f0101b75:	68 74 29 10 f0       	push   $0xf0102974
f0101b7a:	e8 6f ee ff ff       	call   f01009ee <cprintf>
	char *op  = readline("");
f0101b7f:	c7 04 24 0f 22 10 f0 	movl   $0xf010220f,(%esp)
f0101b86:	e8 3b f8 ff ff       	call   f01013c6 <readline>
f0101b8b:	89 c3                	mov    %eax,%ebx
f0101b8d:	83 c4 10             	add    $0x10,%esp
	char number[100];
	for(i = 0 ; i < 100; i++)
f0101b90:	b8 00 00 00 00       	mov    $0x0,%eax
f0101b95:	83 c0 01             	add    $0x1,%eax
f0101b98:	83 f8 63             	cmp    $0x63,%eax
f0101b9b:	7e f8                	jle    f0101b95 <calculator+0x51>
f0101b9d:	89 45 cc             	mov    %eax,-0x34(%ebp)
	{
	number[i] = '0';	
	}
	number[strlen(op)] = '\0';
f0101ba0:	83 ec 0c             	sub    $0xc,%esp
f0101ba3:	53                   	push   %ebx
f0101ba4:	e8 f6 f8 ff ff       	call   f010149f <strlen>
	i = 0;
f0101ba9:	c7 45 cc 00 00 00 00 	movl   $0x0,-0x34(%ebp)
	if (!(op[0] != '-' || Isnumber(op[0])))
f0101bb0:	83 c4 10             	add    $0x10,%esp
f0101bb3:	80 3b 2d             	cmpb   $0x2d,(%ebx)
f0101bb6:	75 1a                	jne    f0101bd2 <calculator+0x8e>
	{
		cprintf("error");
f0101bb8:	83 ec 0c             	sub    $0xc,%esp
f0101bbb:	68 45 27 10 f0       	push   $0xf0102745
f0101bc0:	e8 29 ee ff ff       	call   f01009ee <cprintf>
		return -1;
f0101bc5:	83 c4 10             	add    $0x10,%esp
f0101bc8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101bcd:	e9 67 01 00 00       	jmp    f0101d39 <calculator+0x1f5>
	}
	if (!(Isnumber(op[strlen(op) - 1]) || Isdot(op[strlen(op) - 1])))
f0101bd2:	83 ec 0c             	sub    $0xc,%esp
f0101bd5:	53                   	push   %ebx
f0101bd6:	e8 c4 f8 ff ff       	call   f010149f <strlen>
}


int Isnumber(char r)
{
	if (r >= '0' && r <= '9')
f0101bdb:	0f b6 44 03 ff       	movzbl -0x1(%ebx,%eax,1),%eax
f0101be0:	83 e8 30             	sub    $0x30,%eax
	if (!(op[0] != '-' || Isnumber(op[0])))
	{
		cprintf("error");
		return -1;
	}
	if (!(Isnumber(op[strlen(op) - 1]) || Isdot(op[strlen(op) - 1])))
f0101be3:	83 c4 10             	add    $0x10,%esp
f0101be6:	3c 09                	cmp    $0x9,%al
f0101be8:	77 14                	ja     f0101bfe <calculator+0xba>
		A[i] = 0;
	}
	cprintf("Expression:");
	char *op  = readline("");
	char number[100];
	for(i = 0 ; i < 100; i++)
f0101bea:	c7 45 8c 00 00 00 00 	movl   $0x0,-0x74(%ebp)
f0101bf1:	be 01 00 00 00       	mov    $0x1,%esi
	}

	while (i < strlen(op))
	{
		cprintf("I form inside Calculator %d\n",i);
		Float answer_num = Getnumber(op, &i);
f0101bf6:	8d 7d 90             	lea    -0x70(%ebp),%edi
f0101bf9:	e9 d6 00 00 00       	jmp    f0101cd4 <calculator+0x190>
	if (!(op[0] != '-' || Isnumber(op[0])))
	{
		cprintf("error");
		return -1;
	}
	if (!(Isnumber(op[strlen(op) - 1]) || Isdot(op[strlen(op) - 1])))
f0101bfe:	83 ec 0c             	sub    $0xc,%esp
f0101c01:	53                   	push   %ebx
f0101c02:	e8 98 f8 ff ff       	call   f010149f <strlen>
f0101c07:	83 c4 10             	add    $0x10,%esp
f0101c0a:	80 7c 03 ff 2e       	cmpb   $0x2e,-0x1(%ebx,%eax,1)
f0101c0f:	74 d9                	je     f0101bea <calculator+0xa6>
	{
		cprintf("error");
f0101c11:	83 ec 0c             	sub    $0xc,%esp
f0101c14:	68 45 27 10 f0       	push   $0xf0102745
f0101c19:	e8 d0 ed ff ff       	call   f01009ee <cprintf>
		return -1;
f0101c1e:	83 c4 10             	add    $0x10,%esp
f0101c21:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101c26:	e9 0e 01 00 00       	jmp    f0101d39 <calculator+0x1f5>
	}

	while (i < strlen(op))
	{
		cprintf("I form inside Calculator %d\n",i);
f0101c2b:	83 ec 08             	sub    $0x8,%esp
f0101c2e:	52                   	push   %edx
f0101c2f:	68 80 29 10 f0       	push   $0xf0102980
f0101c34:	e8 b5 ed ff ff       	call   f01009ee <cprintf>
		Float answer_num = Getnumber(op, &i);
f0101c39:	83 c4 0c             	add    $0xc,%esp
f0101c3c:	8d 45 cc             	lea    -0x34(%ebp),%eax
f0101c3f:	50                   	push   %eax
f0101c40:	53                   	push   %ebx
f0101c41:	57                   	push   %edi
f0101c42:	e8 63 fc ff ff       	call   f01018aa <Getnumber>
f0101c47:	8b 45 90             	mov    -0x70(%ebp),%eax
		if (answer_num.error)
f0101c4a:	83 c4 0c             	add    $0xc,%esp
f0101c4d:	83 7d 94 00          	cmpl   $0x0,-0x6c(%ebp)
f0101c51:	74 12                	je     f0101c65 <calculator+0x121>
		{
			cprintf("error");
f0101c53:	83 ec 0c             	sub    $0xc,%esp
f0101c56:	68 45 27 10 f0       	push   $0xf0102745
f0101c5b:	e8 8e ed ff ff       	call   f01009ee <cprintf>
			return -1;
f0101c60:	83 c4 10             	add    $0x10,%esp
f0101c63:	eb 68                	jmp    f0101ccd <calculator+0x189>
		}
		else
		{
			A[numposition] = answer_num.number;
f0101c65:	89 44 b5 cc          	mov    %eax,-0x34(%ebp,%esi,4)
			numposition++;
		}
		if (i == strlen(op))
f0101c69:	83 ec 0c             	sub    $0xc,%esp
f0101c6c:	53                   	push   %ebx
f0101c6d:	e8 2d f8 ff ff       	call   f010149f <strlen>
f0101c72:	8b 55 cc             	mov    -0x34(%ebp),%edx
f0101c75:	83 c4 10             	add    $0x10,%esp
f0101c78:	39 d0                	cmp    %edx,%eax
f0101c7a:	74 6f                	je     f0101ceb <calculator+0x1a7>
		{
			break;
		}
		Char answer_char = GetOperation(op, i);
f0101c7c:	83 ec 04             	sub    $0x4,%esp
f0101c7f:	52                   	push   %edx
f0101c80:	53                   	push   %ebx
f0101c81:	57                   	push   %edi
f0101c82:	e8 76 fd ff ff       	call   f01019fd <GetOperation>
f0101c87:	8b 45 90             	mov    -0x70(%ebp),%eax
		if (answer_char.error)
f0101c8a:	83 c4 0c             	add    $0xc,%esp
f0101c8d:	83 7d 94 00          	cmpl   $0x0,-0x6c(%ebp)
f0101c91:	74 12                	je     f0101ca5 <calculator+0x161>
		{
			cprintf("error");
f0101c93:	83 ec 0c             	sub    $0xc,%esp
f0101c96:	68 45 27 10 f0       	push   $0xf0102745
f0101c9b:	e8 4e ed ff ff       	call   f01009ee <cprintf>
			return -1;
f0101ca0:	83 c4 10             	add    $0x10,%esp
f0101ca3:	eb 28                	jmp    f0101ccd <calculator+0x189>
		}
		else
		{
			if (answer_char.value == '+')
f0101ca5:	3c 2b                	cmp    $0x2b,%al
f0101ca7:	75 06                	jne    f0101caf <calculator+0x16b>
			{
				i++;
f0101ca9:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
f0101cad:	eb 19                	jmp    f0101cc8 <calculator+0x184>
			}
			else if (!(answer_char.value == '-'))
f0101caf:	3c 2d                	cmp    $0x2d,%al
f0101cb1:	74 15                	je     f0101cc8 <calculator+0x184>
			{
				numericop[operantnum].operant = answer_char.value;
f0101cb3:	8b 4d 8c             	mov    -0x74(%ebp),%ecx
f0101cb6:	88 44 cd a0          	mov    %al,-0x60(%ebp,%ecx,8)
				numericop[operantnum].position = Operation_Position;
f0101cba:	89 74 cd 9c          	mov    %esi,-0x64(%ebp,%ecx,8)
				operantnum++;
f0101cbe:	83 c1 01             	add    $0x1,%ecx
f0101cc1:	89 4d 8c             	mov    %ecx,-0x74(%ebp)
				i++;
f0101cc4:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
			}
			Operation_Position++;
f0101cc8:	83 c6 01             	add    $0x1,%esi
f0101ccb:	eb 07                	jmp    f0101cd4 <calculator+0x190>
		cprintf("I form inside Calculator %d\n",i);
		Float answer_num = Getnumber(op, &i);
		if (answer_num.error)
		{
			cprintf("error");
			return -1;
f0101ccd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101cd2:	eb 65                	jmp    f0101d39 <calculator+0x1f5>
	{
		cprintf("error");
		return -1;
	}

	while (i < strlen(op))
f0101cd4:	83 ec 0c             	sub    $0xc,%esp
f0101cd7:	53                   	push   %ebx
f0101cd8:	e8 c2 f7 ff ff       	call   f010149f <strlen>
f0101cdd:	8b 55 cc             	mov    -0x34(%ebp),%edx
f0101ce0:	83 c4 10             	add    $0x10,%esp
f0101ce3:	39 d0                	cmp    %edx,%eax
f0101ce5:	0f 8f 40 ff ff ff    	jg     f0101c2b <calculator+0xe7>
			}
			Operation_Position++;
		}

	}
	cprintf(" float A array %f\n %f\n %f\n %f\n %f\n %f\n",A[0],A[1],A[2],A[3],A[4],A[5]);
f0101ceb:	83 ec 3c             	sub    $0x3c,%esp
f0101cee:	d9 45 e4             	flds   -0x1c(%ebp)
f0101cf1:	dd 5c 24 28          	fstpl  0x28(%esp)
f0101cf5:	d9 45 e0             	flds   -0x20(%ebp)
f0101cf8:	dd 5c 24 20          	fstpl  0x20(%esp)
f0101cfc:	d9 45 dc             	flds   -0x24(%ebp)
f0101cff:	dd 5c 24 18          	fstpl  0x18(%esp)
f0101d03:	d9 45 d8             	flds   -0x28(%ebp)
f0101d06:	dd 5c 24 10          	fstpl  0x10(%esp)
f0101d0a:	d9 45 d4             	flds   -0x2c(%ebp)
f0101d0d:	dd 5c 24 08          	fstpl  0x8(%esp)
f0101d11:	d9 45 d0             	flds   -0x30(%ebp)
f0101d14:	dd 1c 24             	fstpl  (%esp)
f0101d17:	68 a0 29 10 f0       	push   $0xf01029a0
f0101d1c:	e8 cd ec ff ff       	call   f01009ee <cprintf>
	calc(A, numericop);
f0101d21:	83 c4 38             	add    $0x38,%esp
f0101d24:	8d 45 9c             	lea    -0x64(%ebp),%eax
f0101d27:	50                   	push   %eax
f0101d28:	8d 45 d0             	lea    -0x30(%ebp),%eax
f0101d2b:	50                   	push   %eax
f0101d2c:	e8 14 fd ff ff       	call   f0101a45 <calc>
	return 0;
f0101d31:	83 c4 10             	add    $0x10,%esp
f0101d34:	b8 00 00 00 00       	mov    $0x0,%eax

f0101d39:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101d3c:	5b                   	pop    %ebx
f0101d3d:	5e                   	pop    %esi
f0101d3e:	5f                   	pop    %edi
f0101d3f:	5d                   	pop    %ebp
f0101d40:	c3                   	ret    

f0101d41 <powerbase>:
#include <kern/kdebug.h>



int powerbase(char base, char power)
{
f0101d41:	55                   	push   %ebp
f0101d42:	89 e5                	mov    %esp,%ebp
f0101d44:	53                   	push   %ebx
f0101d45:	83 ec 04             	sub    $0x4,%esp
f0101d48:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101d4b:	8b 55 0c             	mov    0xc(%ebp),%edx
    if(power!=1)
        return (base*powerbase(base,power-1));
    return base;
f0101d4e:	0f be c3             	movsbl %bl,%eax



int powerbase(char base, char power)
{
    if(power!=1)
f0101d51:	80 fa 01             	cmp    $0x1,%dl
f0101d54:	74 18                	je     f0101d6e <powerbase+0x2d>
        return (base*powerbase(base,power-1));
f0101d56:	89 c3                	mov    %eax,%ebx
f0101d58:	83 ec 08             	sub    $0x8,%esp
f0101d5b:	83 ea 01             	sub    $0x1,%edx
f0101d5e:	0f be d2             	movsbl %dl,%edx
f0101d61:	52                   	push   %edx
f0101d62:	50                   	push   %eax
f0101d63:	e8 d9 ff ff ff       	call   f0101d41 <powerbase>
f0101d68:	83 c4 10             	add    $0x10,%esp
f0101d6b:	0f af c3             	imul   %ebx,%eax
    return base;
}
f0101d6e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101d71:	c9                   	leave  
f0101d72:	c3                   	ret    

f0101d73 <char_to_float>:

Float char_to_float(char* arg)
{
f0101d73:	55                   	push   %ebp
f0101d74:	89 e5                	mov    %esp,%ebp
f0101d76:	57                   	push   %edi
f0101d77:	56                   	push   %esi
f0101d78:	53                   	push   %ebx
f0101d79:	83 ec 38             	sub    $0x38,%esp
f0101d7c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
    int len=strlen(arg);
f0101d7f:	53                   	push   %ebx
f0101d80:	e8 1a f7 ff ff       	call   f010149f <strlen>
f0101d85:	89 c7                	mov    %eax,%edi
    float a = 0;

    Float retval;
    retval.error=0;

    while (i<len)
f0101d87:	83 c4 10             	add    $0x10,%esp
    short neg = 0;
    int i=0;
    float a = 0;

    Float retval;
    retval.error=0;
f0101d8a:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
Float char_to_float(char* arg)
{
    int len=strlen(arg);
    short neg = 0;
    int i=0;
    float a = 0;
f0101d91:	d9 ee                	fldz   
f0101d93:	d9 5d e0             	fstps  -0x20(%ebp)

Float char_to_float(char* arg)
{
    int len=strlen(arg);
    short neg = 0;
    int i=0;
f0101d96:	be 00 00 00 00       	mov    $0x0,%esi
}

Float char_to_float(char* arg)
{
    int len=strlen(arg);
    short neg = 0;
f0101d9b:	66 c7 45 d6 00 00    	movw   $0x0,-0x2a(%ebp)
    float a = 0;

    Float retval;
    retval.error=0;

    while (i<len)
f0101da1:	e9 d9 00 00 00       	jmp    f0101e7f <char_to_float+0x10c>
    {
        if (*(arg) == '.')
f0101da6:	0f b6 03             	movzbl (%ebx),%eax
f0101da9:	3c 2e                	cmp    $0x2e,%al
f0101dab:	75 5e                	jne    f0101e0b <char_to_float+0x98>
        {
                if (!(arg+1))
f0101dad:	83 fb ff             	cmp    $0xffffffff,%ebx
f0101db0:	75 14                	jne    f0101dc6 <char_to_float+0x53>
                {
                    return retval;
f0101db2:	8b 45 08             	mov    0x8(%ebp),%eax
f0101db5:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0101dbb:	8b 7d d8             	mov    -0x28(%ebp),%edi
f0101dbe:	89 78 04             	mov    %edi,0x4(%eax)
f0101dc1:	e9 f8 00 00 00       	jmp    f0101ebe <char_to_float+0x14b>
                }
                a = a + (*(arg+1) - '0') * 0.1;
f0101dc6:	0f be 43 01          	movsbl 0x1(%ebx),%eax
f0101dca:	83 e8 30             	sub    $0x30,%eax
f0101dcd:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0101dd0:	db 45 dc             	fildl  -0x24(%ebp)
f0101dd3:	dc 0d e8 26 10 f0    	fmull  0xf01026e8
f0101dd9:	d8 45 e0             	fadds  -0x20(%ebp)
f0101ddc:	d9 5d e4             	fstps  -0x1c(%ebp)
f0101ddf:	d9 45 e4             	flds   -0x1c(%ebp)
f0101de2:	d9 55 e0             	fsts   -0x20(%ebp)
                if ((arg+2))
f0101de5:	83 fb fe             	cmp    $0xfffffffe,%ebx
f0101de8:	0f 84 9b 00 00 00    	je     f0101e89 <char_to_float+0x116>
                {
                    a = a + (*(arg+2) - '0') * 0.1;
f0101dee:	0f be 43 02          	movsbl 0x2(%ebx),%eax
f0101df2:	83 e8 30             	sub    $0x30,%eax
f0101df5:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101df8:	db 45 e0             	fildl  -0x20(%ebp)
f0101dfb:	dc 0d e8 26 10 f0    	fmull  0xf01026e8
f0101e01:	de c1                	faddp  %st,%st(1)
f0101e03:	d9 5d e0             	fstps  -0x20(%ebp)
f0101e06:	e9 80 00 00 00       	jmp    f0101e8b <char_to_float+0x118>
                }
                retval.number=a;
                goto ifnegative;
        }

        if (*(arg)=='-'&& i==0)
f0101e0b:	3c 2d                	cmp    $0x2d,%al
f0101e0d:	75 0f                	jne    f0101e1e <char_to_float+0xab>
f0101e0f:	85 f6                	test   %esi,%esi
f0101e11:	75 0b                	jne    f0101e1e <char_to_float+0xab>
        {
            neg = 1;
            len--;
f0101e13:	83 ef 01             	sub    $0x1,%edi
                goto ifnegative;
        }

        if (*(arg)=='-'&& i==0)
        {
            neg = 1;
f0101e16:	66 c7 45 d6 01 00    	movw   $0x1,-0x2a(%ebp)
            len--;
            goto argplus;
f0101e1c:	eb 5e                	jmp    f0101e7c <char_to_float+0x109>
        }
        else if (*(arg) < '0' || (*(arg) > '9'))
f0101e1e:	83 e8 30             	sub    $0x30,%eax
f0101e21:	3c 09                	cmp    $0x9,%al
f0101e23:	76 17                	jbe    f0101e3c <char_to_float+0xc9>
        {
            retval.error = 1;
            cprintf("Invalid Argument");
f0101e25:	83 ec 0c             	sub    $0xc,%esp
f0101e28:	68 dd 24 10 f0       	push   $0xf01024dd
f0101e2d:	e8 bc eb ff ff       	call   f01009ee <cprintf>
f0101e32:	83 c4 10             	add    $0x10,%esp
            len--;
            goto argplus;
        }
        else if (*(arg) < '0' || (*(arg) > '9'))
        {
            retval.error = 1;
f0101e35:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
            cprintf("Invalid Argument");
            //operation or invalid argument
        }
        // BUG: PowerBase has to be fixed
        // BUG: if power equals zero, the point disappears ?!
        a =  powerbase(10,len-i) / 10 * (*(arg) - '0') + a;
f0101e3c:	83 ec 08             	sub    $0x8,%esp
f0101e3f:	89 f8                	mov    %edi,%eax
f0101e41:	89 f1                	mov    %esi,%ecx
f0101e43:	29 c8                	sub    %ecx,%eax
f0101e45:	0f be c0             	movsbl %al,%eax
f0101e48:	50                   	push   %eax
f0101e49:	6a 0a                	push   $0xa
f0101e4b:	e8 f1 fe ff ff       	call   f0101d41 <powerbase>
f0101e50:	83 c4 10             	add    $0x10,%esp
f0101e53:	89 c1                	mov    %eax,%ecx
f0101e55:	b8 67 66 66 66       	mov    $0x66666667,%eax
f0101e5a:	f7 e9                	imul   %ecx
f0101e5c:	c1 fa 02             	sar    $0x2,%edx
f0101e5f:	c1 f9 1f             	sar    $0x1f,%ecx
f0101e62:	29 ca                	sub    %ecx,%edx
f0101e64:	0f be 03             	movsbl (%ebx),%eax
f0101e67:	83 e8 30             	sub    $0x30,%eax
f0101e6a:	0f af d0             	imul   %eax,%edx
f0101e6d:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101e70:	db 45 dc             	fildl  -0x24(%ebp)
f0101e73:	d8 45 e0             	fadds  -0x20(%ebp)
f0101e76:	d9 5d e0             	fstps  -0x20(%ebp)
        i++;
f0101e79:	83 c6 01             	add    $0x1,%esi
        argplus: arg=arg+1;
f0101e7c:	83 c3 01             	add    $0x1,%ebx
    float a = 0;

    Float retval;
    retval.error=0;

    while (i<len)
f0101e7f:	39 f7                	cmp    %esi,%edi
f0101e81:	0f 8f 1f ff ff ff    	jg     f0101da6 <char_to_float+0x33>
f0101e87:	eb 02                	jmp    f0101e8b <char_to_float+0x118>
f0101e89:	dd d8                	fstp   %st(0)
        a =  powerbase(10,len-i) / 10 * (*(arg) - '0') + a;
        i++;
        argplus: arg=arg+1;
    }
ifnegative:
    if (neg==1)
f0101e8b:	66 83 7d d6 01       	cmpw   $0x1,-0x2a(%ebp)
f0101e90:	75 08                	jne    f0101e9a <char_to_float+0x127>
    {
        retval.number=a*-1;
f0101e92:	d9 45 e0             	flds   -0x20(%ebp)
f0101e95:	d9 e0                	fchs   
f0101e97:	d9 5d e0             	fstps  -0x20(%ebp)
    }
    else
    {
        retval.number=a;
    }
        cprintf("form inside char_to_float %f",retval.number);
f0101e9a:	83 ec 0c             	sub    $0xc,%esp
f0101e9d:	d9 45 e0             	flds   -0x20(%ebp)
f0101ea0:	dd 1c 24             	fstpl  (%esp)
f0101ea3:	68 c8 29 10 f0       	push   $0xf01029c8
f0101ea8:	e8 41 eb ff ff       	call   f01009ee <cprintf>
    return retval;
f0101ead:	8b 45 08             	mov    0x8(%ebp),%eax
f0101eb0:	d9 45 e0             	flds   -0x20(%ebp)
f0101eb3:	d9 18                	fstps  (%eax)
f0101eb5:	8b 7d d8             	mov    -0x28(%ebp),%edi
f0101eb8:	89 78 04             	mov    %edi,0x4(%eax)
f0101ebb:	83 c4 10             	add    $0x10,%esp
}
f0101ebe:	8b 45 08             	mov    0x8(%ebp),%eax
f0101ec1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101ec4:	5b                   	pop    %ebx
f0101ec5:	5e                   	pop    %esi
f0101ec6:	5f                   	pop    %edi
f0101ec7:	5d                   	pop    %ebp
f0101ec8:	c2 04 00             	ret    $0x4
f0101ecb:	66 90                	xchg   %ax,%ax
f0101ecd:	66 90                	xchg   %ax,%ax
f0101ecf:	90                   	nop

f0101ed0 <__udivdi3>:
f0101ed0:	55                   	push   %ebp
f0101ed1:	57                   	push   %edi
f0101ed2:	56                   	push   %esi
f0101ed3:	83 ec 10             	sub    $0x10,%esp
f0101ed6:	8b 54 24 2c          	mov    0x2c(%esp),%edx
f0101eda:	8b 7c 24 20          	mov    0x20(%esp),%edi
f0101ede:	8b 74 24 24          	mov    0x24(%esp),%esi
f0101ee2:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0101ee6:	85 d2                	test   %edx,%edx
f0101ee8:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101eec:	89 34 24             	mov    %esi,(%esp)
f0101eef:	89 c8                	mov    %ecx,%eax
f0101ef1:	75 35                	jne    f0101f28 <__udivdi3+0x58>
f0101ef3:	39 f1                	cmp    %esi,%ecx
f0101ef5:	0f 87 bd 00 00 00    	ja     f0101fb8 <__udivdi3+0xe8>
f0101efb:	85 c9                	test   %ecx,%ecx
f0101efd:	89 cd                	mov    %ecx,%ebp
f0101eff:	75 0b                	jne    f0101f0c <__udivdi3+0x3c>
f0101f01:	b8 01 00 00 00       	mov    $0x1,%eax
f0101f06:	31 d2                	xor    %edx,%edx
f0101f08:	f7 f1                	div    %ecx
f0101f0a:	89 c5                	mov    %eax,%ebp
f0101f0c:	89 f0                	mov    %esi,%eax
f0101f0e:	31 d2                	xor    %edx,%edx
f0101f10:	f7 f5                	div    %ebp
f0101f12:	89 c6                	mov    %eax,%esi
f0101f14:	89 f8                	mov    %edi,%eax
f0101f16:	f7 f5                	div    %ebp
f0101f18:	89 f2                	mov    %esi,%edx
f0101f1a:	83 c4 10             	add    $0x10,%esp
f0101f1d:	5e                   	pop    %esi
f0101f1e:	5f                   	pop    %edi
f0101f1f:	5d                   	pop    %ebp
f0101f20:	c3                   	ret    
f0101f21:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101f28:	3b 14 24             	cmp    (%esp),%edx
f0101f2b:	77 7b                	ja     f0101fa8 <__udivdi3+0xd8>
f0101f2d:	0f bd f2             	bsr    %edx,%esi
f0101f30:	83 f6 1f             	xor    $0x1f,%esi
f0101f33:	0f 84 97 00 00 00    	je     f0101fd0 <__udivdi3+0x100>
f0101f39:	bd 20 00 00 00       	mov    $0x20,%ebp
f0101f3e:	89 d7                	mov    %edx,%edi
f0101f40:	89 f1                	mov    %esi,%ecx
f0101f42:	29 f5                	sub    %esi,%ebp
f0101f44:	d3 e7                	shl    %cl,%edi
f0101f46:	89 c2                	mov    %eax,%edx
f0101f48:	89 e9                	mov    %ebp,%ecx
f0101f4a:	d3 ea                	shr    %cl,%edx
f0101f4c:	89 f1                	mov    %esi,%ecx
f0101f4e:	09 fa                	or     %edi,%edx
f0101f50:	8b 3c 24             	mov    (%esp),%edi
f0101f53:	d3 e0                	shl    %cl,%eax
f0101f55:	89 54 24 08          	mov    %edx,0x8(%esp)
f0101f59:	89 e9                	mov    %ebp,%ecx
f0101f5b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101f5f:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101f63:	89 fa                	mov    %edi,%edx
f0101f65:	d3 ea                	shr    %cl,%edx
f0101f67:	89 f1                	mov    %esi,%ecx
f0101f69:	d3 e7                	shl    %cl,%edi
f0101f6b:	89 e9                	mov    %ebp,%ecx
f0101f6d:	d3 e8                	shr    %cl,%eax
f0101f6f:	09 c7                	or     %eax,%edi
f0101f71:	89 f8                	mov    %edi,%eax
f0101f73:	f7 74 24 08          	divl   0x8(%esp)
f0101f77:	89 d5                	mov    %edx,%ebp
f0101f79:	89 c7                	mov    %eax,%edi
f0101f7b:	f7 64 24 0c          	mull   0xc(%esp)
f0101f7f:	39 d5                	cmp    %edx,%ebp
f0101f81:	89 14 24             	mov    %edx,(%esp)
f0101f84:	72 11                	jb     f0101f97 <__udivdi3+0xc7>
f0101f86:	8b 54 24 04          	mov    0x4(%esp),%edx
f0101f8a:	89 f1                	mov    %esi,%ecx
f0101f8c:	d3 e2                	shl    %cl,%edx
f0101f8e:	39 c2                	cmp    %eax,%edx
f0101f90:	73 5e                	jae    f0101ff0 <__udivdi3+0x120>
f0101f92:	3b 2c 24             	cmp    (%esp),%ebp
f0101f95:	75 59                	jne    f0101ff0 <__udivdi3+0x120>
f0101f97:	8d 47 ff             	lea    -0x1(%edi),%eax
f0101f9a:	31 f6                	xor    %esi,%esi
f0101f9c:	89 f2                	mov    %esi,%edx
f0101f9e:	83 c4 10             	add    $0x10,%esp
f0101fa1:	5e                   	pop    %esi
f0101fa2:	5f                   	pop    %edi
f0101fa3:	5d                   	pop    %ebp
f0101fa4:	c3                   	ret    
f0101fa5:	8d 76 00             	lea    0x0(%esi),%esi
f0101fa8:	31 f6                	xor    %esi,%esi
f0101faa:	31 c0                	xor    %eax,%eax
f0101fac:	89 f2                	mov    %esi,%edx
f0101fae:	83 c4 10             	add    $0x10,%esp
f0101fb1:	5e                   	pop    %esi
f0101fb2:	5f                   	pop    %edi
f0101fb3:	5d                   	pop    %ebp
f0101fb4:	c3                   	ret    
f0101fb5:	8d 76 00             	lea    0x0(%esi),%esi
f0101fb8:	89 f2                	mov    %esi,%edx
f0101fba:	31 f6                	xor    %esi,%esi
f0101fbc:	89 f8                	mov    %edi,%eax
f0101fbe:	f7 f1                	div    %ecx
f0101fc0:	89 f2                	mov    %esi,%edx
f0101fc2:	83 c4 10             	add    $0x10,%esp
f0101fc5:	5e                   	pop    %esi
f0101fc6:	5f                   	pop    %edi
f0101fc7:	5d                   	pop    %ebp
f0101fc8:	c3                   	ret    
f0101fc9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101fd0:	3b 4c 24 04          	cmp    0x4(%esp),%ecx
f0101fd4:	76 0b                	jbe    f0101fe1 <__udivdi3+0x111>
f0101fd6:	31 c0                	xor    %eax,%eax
f0101fd8:	3b 14 24             	cmp    (%esp),%edx
f0101fdb:	0f 83 37 ff ff ff    	jae    f0101f18 <__udivdi3+0x48>
f0101fe1:	b8 01 00 00 00       	mov    $0x1,%eax
f0101fe6:	e9 2d ff ff ff       	jmp    f0101f18 <__udivdi3+0x48>
f0101feb:	90                   	nop
f0101fec:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101ff0:	89 f8                	mov    %edi,%eax
f0101ff2:	31 f6                	xor    %esi,%esi
f0101ff4:	e9 1f ff ff ff       	jmp    f0101f18 <__udivdi3+0x48>
f0101ff9:	66 90                	xchg   %ax,%ax
f0101ffb:	66 90                	xchg   %ax,%ax
f0101ffd:	66 90                	xchg   %ax,%ax
f0101fff:	90                   	nop

f0102000 <__umoddi3>:
f0102000:	55                   	push   %ebp
f0102001:	57                   	push   %edi
f0102002:	56                   	push   %esi
f0102003:	83 ec 20             	sub    $0x20,%esp
f0102006:	8b 44 24 34          	mov    0x34(%esp),%eax
f010200a:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010200e:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0102012:	89 c6                	mov    %eax,%esi
f0102014:	89 44 24 10          	mov    %eax,0x10(%esp)
f0102018:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f010201c:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
f0102020:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0102024:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f0102028:	89 74 24 18          	mov    %esi,0x18(%esp)
f010202c:	85 c0                	test   %eax,%eax
f010202e:	89 c2                	mov    %eax,%edx
f0102030:	75 1e                	jne    f0102050 <__umoddi3+0x50>
f0102032:	39 f7                	cmp    %esi,%edi
f0102034:	76 52                	jbe    f0102088 <__umoddi3+0x88>
f0102036:	89 c8                	mov    %ecx,%eax
f0102038:	89 f2                	mov    %esi,%edx
f010203a:	f7 f7                	div    %edi
f010203c:	89 d0                	mov    %edx,%eax
f010203e:	31 d2                	xor    %edx,%edx
f0102040:	83 c4 20             	add    $0x20,%esp
f0102043:	5e                   	pop    %esi
f0102044:	5f                   	pop    %edi
f0102045:	5d                   	pop    %ebp
f0102046:	c3                   	ret    
f0102047:	89 f6                	mov    %esi,%esi
f0102049:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0102050:	39 f0                	cmp    %esi,%eax
f0102052:	77 5c                	ja     f01020b0 <__umoddi3+0xb0>
f0102054:	0f bd e8             	bsr    %eax,%ebp
f0102057:	83 f5 1f             	xor    $0x1f,%ebp
f010205a:	75 64                	jne    f01020c0 <__umoddi3+0xc0>
f010205c:	8b 6c 24 14          	mov    0x14(%esp),%ebp
f0102060:	39 6c 24 0c          	cmp    %ebp,0xc(%esp)
f0102064:	0f 86 f6 00 00 00    	jbe    f0102160 <__umoddi3+0x160>
f010206a:	3b 44 24 18          	cmp    0x18(%esp),%eax
f010206e:	0f 82 ec 00 00 00    	jb     f0102160 <__umoddi3+0x160>
f0102074:	8b 44 24 14          	mov    0x14(%esp),%eax
f0102078:	8b 54 24 18          	mov    0x18(%esp),%edx
f010207c:	83 c4 20             	add    $0x20,%esp
f010207f:	5e                   	pop    %esi
f0102080:	5f                   	pop    %edi
f0102081:	5d                   	pop    %ebp
f0102082:	c3                   	ret    
f0102083:	90                   	nop
f0102084:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0102088:	85 ff                	test   %edi,%edi
f010208a:	89 fd                	mov    %edi,%ebp
f010208c:	75 0b                	jne    f0102099 <__umoddi3+0x99>
f010208e:	b8 01 00 00 00       	mov    $0x1,%eax
f0102093:	31 d2                	xor    %edx,%edx
f0102095:	f7 f7                	div    %edi
f0102097:	89 c5                	mov    %eax,%ebp
f0102099:	8b 44 24 10          	mov    0x10(%esp),%eax
f010209d:	31 d2                	xor    %edx,%edx
f010209f:	f7 f5                	div    %ebp
f01020a1:	89 c8                	mov    %ecx,%eax
f01020a3:	f7 f5                	div    %ebp
f01020a5:	eb 95                	jmp    f010203c <__umoddi3+0x3c>
f01020a7:	89 f6                	mov    %esi,%esi
f01020a9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f01020b0:	89 c8                	mov    %ecx,%eax
f01020b2:	89 f2                	mov    %esi,%edx
f01020b4:	83 c4 20             	add    $0x20,%esp
f01020b7:	5e                   	pop    %esi
f01020b8:	5f                   	pop    %edi
f01020b9:	5d                   	pop    %ebp
f01020ba:	c3                   	ret    
f01020bb:	90                   	nop
f01020bc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01020c0:	b8 20 00 00 00       	mov    $0x20,%eax
f01020c5:	89 e9                	mov    %ebp,%ecx
f01020c7:	29 e8                	sub    %ebp,%eax
f01020c9:	d3 e2                	shl    %cl,%edx
f01020cb:	89 c7                	mov    %eax,%edi
f01020cd:	89 44 24 18          	mov    %eax,0x18(%esp)
f01020d1:	8b 44 24 0c          	mov    0xc(%esp),%eax
f01020d5:	89 f9                	mov    %edi,%ecx
f01020d7:	d3 e8                	shr    %cl,%eax
f01020d9:	89 c1                	mov    %eax,%ecx
f01020db:	8b 44 24 0c          	mov    0xc(%esp),%eax
f01020df:	09 d1                	or     %edx,%ecx
f01020e1:	89 fa                	mov    %edi,%edx
f01020e3:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f01020e7:	89 e9                	mov    %ebp,%ecx
f01020e9:	d3 e0                	shl    %cl,%eax
f01020eb:	89 f9                	mov    %edi,%ecx
f01020ed:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01020f1:	89 f0                	mov    %esi,%eax
f01020f3:	d3 e8                	shr    %cl,%eax
f01020f5:	89 e9                	mov    %ebp,%ecx
f01020f7:	89 c7                	mov    %eax,%edi
f01020f9:	8b 44 24 1c          	mov    0x1c(%esp),%eax
f01020fd:	d3 e6                	shl    %cl,%esi
f01020ff:	89 d1                	mov    %edx,%ecx
f0102101:	89 fa                	mov    %edi,%edx
f0102103:	d3 e8                	shr    %cl,%eax
f0102105:	89 e9                	mov    %ebp,%ecx
f0102107:	09 f0                	or     %esi,%eax
f0102109:	8b 74 24 1c          	mov    0x1c(%esp),%esi
f010210d:	f7 74 24 10          	divl   0x10(%esp)
f0102111:	d3 e6                	shl    %cl,%esi
f0102113:	89 d1                	mov    %edx,%ecx
f0102115:	f7 64 24 0c          	mull   0xc(%esp)
f0102119:	39 d1                	cmp    %edx,%ecx
f010211b:	89 74 24 14          	mov    %esi,0x14(%esp)
f010211f:	89 d7                	mov    %edx,%edi
f0102121:	89 c6                	mov    %eax,%esi
f0102123:	72 0a                	jb     f010212f <__umoddi3+0x12f>
f0102125:	39 44 24 14          	cmp    %eax,0x14(%esp)
f0102129:	73 10                	jae    f010213b <__umoddi3+0x13b>
f010212b:	39 d1                	cmp    %edx,%ecx
f010212d:	75 0c                	jne    f010213b <__umoddi3+0x13b>
f010212f:	89 d7                	mov    %edx,%edi
f0102131:	89 c6                	mov    %eax,%esi
f0102133:	2b 74 24 0c          	sub    0xc(%esp),%esi
f0102137:	1b 7c 24 10          	sbb    0x10(%esp),%edi
f010213b:	89 ca                	mov    %ecx,%edx
f010213d:	89 e9                	mov    %ebp,%ecx
f010213f:	8b 44 24 14          	mov    0x14(%esp),%eax
f0102143:	29 f0                	sub    %esi,%eax
f0102145:	19 fa                	sbb    %edi,%edx
f0102147:	d3 e8                	shr    %cl,%eax
f0102149:	0f b6 4c 24 18       	movzbl 0x18(%esp),%ecx
f010214e:	89 d7                	mov    %edx,%edi
f0102150:	d3 e7                	shl    %cl,%edi
f0102152:	89 e9                	mov    %ebp,%ecx
f0102154:	09 f8                	or     %edi,%eax
f0102156:	d3 ea                	shr    %cl,%edx
f0102158:	83 c4 20             	add    $0x20,%esp
f010215b:	5e                   	pop    %esi
f010215c:	5f                   	pop    %edi
f010215d:	5d                   	pop    %ebp
f010215e:	c3                   	ret    
f010215f:	90                   	nop
f0102160:	8b 74 24 10          	mov    0x10(%esp),%esi
f0102164:	29 f9                	sub    %edi,%ecx
f0102166:	19 c6                	sbb    %eax,%esi
f0102168:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f010216c:	89 74 24 18          	mov    %esi,0x18(%esp)
f0102170:	e9 ff fe ff ff       	jmp    f0102074 <__umoddi3+0x74>
