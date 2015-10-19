
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
f010004b:	68 00 21 10 f0       	push   $0xf0102100
f0100050:	e8 94 09 00 00       	call   f01009e9 <cprintf>
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
f0100076:	e8 f6 07 00 00       	call   f0100871 <mon_backtrace>
f010007b:	83 c4 10             	add    $0x10,%esp
	cprintf("leaving test_backtrace %d\n", x);
f010007e:	83 ec 08             	sub    $0x8,%esp
f0100081:	53                   	push   %ebx
f0100082:	68 1c 21 10 f0       	push   $0xf010211c
f0100087:	e8 5d 09 00 00       	call   f01009e9 <cprintf>
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
f01000ac:	e8 43 15 00 00       	call   f01015f4 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b1:	e8 8c 04 00 00       	call   f0100542 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000b6:	83 c4 08             	add    $0x8,%esp
f01000b9:	68 ac 1a 00 00       	push   $0x1aac
f01000be:	68 37 21 10 f0       	push   $0xf0102137
f01000c3:	e8 21 09 00 00       	call   f01009e9 <cprintf>

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
f01000dc:	e8 9a 07 00 00       	call   f010087b <monitor>
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
f010010b:	68 52 21 10 f0       	push   $0xf0102152
f0100110:	e8 d4 08 00 00       	call   f01009e9 <cprintf>
	vcprintf(fmt, ap);
f0100115:	83 c4 08             	add    $0x8,%esp
f0100118:	53                   	push   %ebx
f0100119:	56                   	push   %esi
f010011a:	e8 a4 08 00 00       	call   f01009c3 <vcprintf>
	cprintf("\n");
f010011f:	c7 04 24 8e 21 10 f0 	movl   $0xf010218e,(%esp)
f0100126:	e8 be 08 00 00       	call   f01009e9 <cprintf>
	va_end(ap);
f010012b:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010012e:	83 ec 0c             	sub    $0xc,%esp
f0100131:	6a 00                	push   $0x0
f0100133:	e8 43 07 00 00       	call   f010087b <monitor>
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
f010014d:	68 6a 21 10 f0       	push   $0xf010216a
f0100152:	e8 92 08 00 00       	call   f01009e9 <cprintf>
	vcprintf(fmt, ap);
f0100157:	83 c4 08             	add    $0x8,%esp
f010015a:	53                   	push   %ebx
f010015b:	ff 75 10             	pushl  0x10(%ebp)
f010015e:	e8 60 08 00 00       	call   f01009c3 <vcprintf>
	cprintf("\n");
f0100163:	c7 04 24 8e 21 10 f0 	movl   $0xf010218e,(%esp)
f010016a:	e8 7a 08 00 00       	call   f01009e9 <cprintf>
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
f010021c:	0f b6 82 00 23 10 f0 	movzbl -0xfefdd00(%edx),%eax
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
f0100258:	0f b6 90 00 23 10 f0 	movzbl -0xfefdd00(%eax),%edx
f010025f:	0b 15 00 33 11 f0    	or     0xf0113300,%edx
	shift ^= togglecode[data];
f0100265:	0f b6 88 00 22 10 f0 	movzbl -0xfefde00(%eax),%ecx
f010026c:	31 ca                	xor    %ecx,%edx
f010026e:	89 15 00 33 11 f0    	mov    %edx,0xf0113300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100274:	89 d1                	mov    %edx,%ecx
f0100276:	83 e1 03             	and    $0x3,%ecx
f0100279:	8b 0c 8d c0 21 10 f0 	mov    -0xfefde40(,%ecx,4),%ecx
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
f01002b9:	68 84 21 10 f0       	push   $0xf0102184
f01002be:	e8 26 07 00 00       	call   f01009e9 <cprintf>
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
f0100466:	e8 d6 11 00 00       	call   f0101641 <memmove>
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
f0100626:	68 90 21 10 f0       	push   $0xf0102190
f010062b:	e8 b9 03 00 00       	call   f01009e9 <cprintf>
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
	return calculator();
f010066c:	e8 8f 14 00 00       	call   f0101b00 <calculator>
}
f0100671:	c9                   	leave  
f0100672:	c3                   	ret    

f0100673 <mon_help>:
}


int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100673:	55                   	push   %ebp
f0100674:	89 e5                	mov    %esp,%ebp
f0100676:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100679:	68 00 24 10 f0       	push   $0xf0102400
f010067e:	68 1e 24 10 f0       	push   $0xf010241e
f0100683:	68 23 24 10 f0       	push   $0xf0102423
f0100688:	e8 5c 03 00 00       	call   f01009e9 <cprintf>
f010068d:	83 c4 0c             	add    $0xc,%esp
f0100690:	68 b0 24 10 f0       	push   $0xf01024b0
f0100695:	68 2c 24 10 f0       	push   $0xf010242c
f010069a:	68 23 24 10 f0       	push   $0xf0102423
f010069f:	e8 45 03 00 00       	call   f01009e9 <cprintf>
f01006a4:	83 c4 0c             	add    $0xc,%esp
f01006a7:	68 d8 24 10 f0       	push   $0xf01024d8
f01006ac:	68 31 24 10 f0       	push   $0xf0102431
f01006b1:	68 23 24 10 f0       	push   $0xf0102423
f01006b6:	e8 2e 03 00 00       	call   f01009e9 <cprintf>
	return 0;
}
f01006bb:	b8 00 00 00 00       	mov    $0x0,%eax
f01006c0:	c9                   	leave  
f01006c1:	c3                   	ret    

f01006c2 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006c2:	55                   	push   %ebp
f01006c3:	89 e5                	mov    %esp,%ebp
f01006c5:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006c8:	68 3a 24 10 f0       	push   $0xf010243a
f01006cd:	e8 17 03 00 00       	call   f01009e9 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006d2:	83 c4 08             	add    $0x8,%esp
f01006d5:	68 0c 00 10 00       	push   $0x10000c
f01006da:	68 00 25 10 f0       	push   $0xf0102500
f01006df:	e8 05 03 00 00       	call   f01009e9 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006e4:	83 c4 0c             	add    $0xc,%esp
f01006e7:	68 0c 00 10 00       	push   $0x10000c
f01006ec:	68 0c 00 10 f0       	push   $0xf010000c
f01006f1:	68 28 25 10 f0       	push   $0xf0102528
f01006f6:	e8 ee 02 00 00       	call   f01009e9 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006fb:	83 c4 0c             	add    $0xc,%esp
f01006fe:	68 c5 20 10 00       	push   $0x1020c5
f0100703:	68 c5 20 10 f0       	push   $0xf01020c5
f0100708:	68 4c 25 10 f0       	push   $0xf010254c
f010070d:	e8 d7 02 00 00       	call   f01009e9 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100712:	83 c4 0c             	add    $0xc,%esp
f0100715:	68 00 33 11 00       	push   $0x113300
f010071a:	68 00 33 11 f0       	push   $0xf0113300
f010071f:	68 70 25 10 f0       	push   $0xf0102570
f0100724:	e8 c0 02 00 00       	call   f01009e9 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100729:	83 c4 0c             	add    $0xc,%esp
f010072c:	68 84 39 11 00       	push   $0x113984
f0100731:	68 84 39 11 f0       	push   $0xf0113984
f0100736:	68 94 25 10 f0       	push   $0xf0102594
f010073b:	e8 a9 02 00 00       	call   f01009e9 <cprintf>
f0100740:	b8 83 3d 11 f0       	mov    $0xf0113d83,%eax
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100745:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f010074a:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f010074d:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100752:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100758:	85 c0                	test   %eax,%eax
f010075a:	0f 48 c2             	cmovs  %edx,%eax
f010075d:	c1 f8 0a             	sar    $0xa,%eax
f0100760:	50                   	push   %eax
f0100761:	68 b8 25 10 f0       	push   $0xf01025b8
f0100766:	e8 7e 02 00 00       	call   f01009e9 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f010076b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100770:	c9                   	leave  
f0100771:	c3                   	ret    

f0100772 <second_lab>:
	return calculator();
}

int
second_lab(int argc, char **argv, struct Trapframe *tf)
{
f0100772:	55                   	push   %ebp
f0100773:	89 e5                	mov    %esp,%ebp
f0100775:	83 ec 14             	sub    $0x14,%esp
	/// Yassin call his calculator here;
	char *in= NULL;
	char *out;
	out = readline(in);
f0100778:	6a 00                	push   $0x0
f010077a:	e8 1e 0c 00 00       	call   f010139d <readline>
	int i=0;
	float a=0;
	while (out+i)
f010077f:	83 c4 10             	add    $0x10,%esp
f0100782:	85 c0                	test   %eax,%eax
f0100784:	75 fc                	jne    f0100782 <second_lab+0x10>
			//operation or invalid argument
		}
		float a;
	}	
	return 0;
}
f0100786:	c9                   	leave  
f0100787:	c3                   	ret    

f0100788 <first_lab>:

// First OS Lab

int
first_lab(int argc, char **argv, struct Trapframe *tf)
{
f0100788:	55                   	push   %ebp
f0100789:	89 e5                	mov    %esp,%ebp
f010078b:	57                   	push   %edi
f010078c:	56                   	push   %esi
f010078d:	53                   	push   %ebx
f010078e:	83 ec 28             	sub    $0x28,%esp
//		out=(char*)a;
///////////////////////////////////////// */
	char *in= NULL;
	char* arg;

	arg = readline(in);
f0100791:	6a 00                	push   $0x0
f0100793:	e8 05 0c 00 00       	call   f010139d <readline>
f0100798:	89 c3                	mov    %eax,%ebx
	int len=strlen(arg);
f010079a:	89 04 24             	mov    %eax,(%esp)
f010079d:	e8 d4 0c 00 00       	call   f0101476 <strlen>
f01007a2:	89 c7                	mov    %eax,%edi
	short neg = 0;
	int i=0;
	double a = 0;
	while (i<len)
f01007a4:	83 c4 10             	add    $0x10,%esp

	arg = readline(in);
	int len=strlen(arg);
	short neg = 0;
	int i=0;
	double a = 0;
f01007a7:	d9 ee                	fldz   
f01007a9:	dd 5d e0             	fstpl  -0x20(%ebp)
	char* arg;

	arg = readline(in);
	int len=strlen(arg);
	short neg = 0;
	int i=0;
f01007ac:	be 00 00 00 00       	mov    $0x0,%esi
	double a = 0;
	while (i<len)
f01007b1:	e9 90 00 00 00       	jmp    f0100846 <first_lab+0xbe>
	{
		if (*(arg) == '.')
f01007b6:	0f b6 03             	movzbl (%ebx),%eax
f01007b9:	3c 2e                	cmp    $0x2e,%al
f01007bb:	75 2b                	jne    f01007e8 <first_lab+0x60>
		{
//			after the point
			a = a + (*(arg+1) - '0') * 0.1;
			cprintf("entered val %f",a);
f01007bd:	83 ec 0c             	sub    $0xc,%esp
	while (i<len)
	{
		if (*(arg) == '.')
		{
//			after the point
			a = a + (*(arg+1) - '0') * 0.1;
f01007c0:	0f be 43 01          	movsbl 0x1(%ebx),%eax
f01007c4:	83 e8 30             	sub    $0x30,%eax
f01007c7:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01007ca:	db 45 dc             	fildl  -0x24(%ebp)
f01007cd:	dc 0d 68 26 10 f0    	fmull  0xf0102668
f01007d3:	dc 45 e0             	faddl  -0x20(%ebp)
			cprintf("entered val %f",a);
f01007d6:	dd 1c 24             	fstpl  (%esp)
f01007d9:	68 53 24 10 f0       	push   $0xf0102453
f01007de:	e8 06 02 00 00       	call   f01009e9 <cprintf>
			return 0;
f01007e3:	83 c4 10             	add    $0x10,%esp
f01007e6:	eb 7c                	jmp    f0100864 <first_lab+0xdc>
		}
		if (*(arg)=='-')
f01007e8:	3c 2d                	cmp    $0x2d,%al
f01007ea:	74 17                	je     f0100803 <first_lab+0x7b>
		{
			neg = 1;
		}
		else if (*(arg) < '0' || (*(arg) > '9'))
f01007ec:	83 e8 30             	sub    $0x30,%eax
f01007ef:	3c 09                	cmp    $0x9,%al
f01007f1:	76 10                	jbe    f0100803 <first_lab+0x7b>
		{
			cprintf("Invalid Argument");
f01007f3:	83 ec 0c             	sub    $0xc,%esp
f01007f6:	68 62 24 10 f0       	push   $0xf0102462
f01007fb:	e8 e9 01 00 00       	call   f01009e9 <cprintf>
f0100800:	83 c4 10             	add    $0x10,%esp
			//operation or invalid argument
		}
		// BUG: PowerBase has to be fixed
		// BUG: if power equals zero, the point disappears ?!
		a =  powerbase(10,len-i) / 10 * (*(arg) - '0') + a;
f0100803:	83 ec 08             	sub    $0x8,%esp
f0100806:	89 f8                	mov    %edi,%eax
f0100808:	89 f1                	mov    %esi,%ecx
f010080a:	29 c8                	sub    %ecx,%eax
f010080c:	0f be c0             	movsbl %al,%eax
f010080f:	50                   	push   %eax
f0100810:	6a 0a                	push   $0xa
f0100812:	e8 b5 14 00 00       	call   f0101ccc <powerbase>
f0100817:	89 c1                	mov    %eax,%ecx
f0100819:	b8 67 66 66 66       	mov    $0x66666667,%eax
f010081e:	f7 e9                	imul   %ecx
f0100820:	c1 fa 02             	sar    $0x2,%edx
f0100823:	c1 f9 1f             	sar    $0x1f,%ecx
f0100826:	29 ca                	sub    %ecx,%edx
f0100828:	0f be 03             	movsbl (%ebx),%eax
f010082b:	83 e8 30             	sub    $0x30,%eax
f010082e:	0f af d0             	imul   %eax,%edx
f0100831:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0100834:	db 45 dc             	fildl  -0x24(%ebp)
f0100837:	dc 45 e0             	faddl  -0x20(%ebp)
f010083a:	dd 5d e0             	fstpl  -0x20(%ebp)
		i++;
f010083d:	83 c6 01             	add    $0x1,%esi
		arg=arg+1;
f0100840:	83 c3 01             	add    $0x1,%ebx
f0100843:	83 c4 10             	add    $0x10,%esp
	arg = readline(in);
	int len=strlen(arg);
	short neg = 0;
	int i=0;
	double a = 0;
	while (i<len)
f0100846:	39 fe                	cmp    %edi,%esi
f0100848:	0f 8c 68 ff ff ff    	jl     f01007b6 <first_lab+0x2e>
		a =  powerbase(10,len-i) / 10 * (*(arg) - '0') + a;
		i++;
		arg=arg+1;
	}

	cprintf("entered val %f",a);
f010084e:	83 ec 04             	sub    $0x4,%esp
f0100851:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100854:	ff 75 e0             	pushl  -0x20(%ebp)
f0100857:	68 53 24 10 f0       	push   $0xf0102453
f010085c:	e8 88 01 00 00       	call   f01009e9 <cprintf>
	return 0;
f0100861:	83 c4 10             	add    $0x10,%esp
}
f0100864:	b8 00 00 00 00       	mov    $0x0,%eax
f0100869:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010086c:	5b                   	pop    %ebx
f010086d:	5e                   	pop    %esi
f010086e:	5f                   	pop    %edi
f010086f:	5d                   	pop    %ebp
f0100870:	c3                   	ret    

f0100871 <mon_backtrace>:
}


int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100871:	55                   	push   %ebp
f0100872:	89 e5                	mov    %esp,%ebp
	// Your code here.
	return 0;
}
f0100874:	b8 00 00 00 00       	mov    $0x0,%eax
f0100879:	5d                   	pop    %ebp
f010087a:	c3                   	ret    

f010087b <monitor>:
}


void
monitor(struct Trapframe *tf)
{
f010087b:	55                   	push   %ebp
f010087c:	89 e5                	mov    %esp,%ebp
f010087e:	57                   	push   %edi
f010087f:	56                   	push   %esi
f0100880:	53                   	push   %ebx
f0100881:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100884:	68 e4 25 10 f0       	push   $0xf01025e4
f0100889:	e8 5b 01 00 00       	call   f01009e9 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010088e:	c7 04 24 08 26 10 f0 	movl   $0xf0102608,(%esp)
f0100895:	e8 4f 01 00 00       	call   f01009e9 <cprintf>
f010089a:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f010089d:	83 ec 0c             	sub    $0xc,%esp
f01008a0:	68 73 24 10 f0       	push   $0xf0102473
f01008a5:	e8 f3 0a 00 00       	call   f010139d <readline>
f01008aa:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01008ac:	83 c4 10             	add    $0x10,%esp
f01008af:	85 c0                	test   %eax,%eax
f01008b1:	74 ea                	je     f010089d <monitor+0x22>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01008b3:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01008ba:	be 00 00 00 00       	mov    $0x0,%esi
f01008bf:	eb 0a                	jmp    f01008cb <monitor+0x50>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01008c1:	c6 03 00             	movb   $0x0,(%ebx)
f01008c4:	89 f7                	mov    %esi,%edi
f01008c6:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01008c9:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01008cb:	0f b6 03             	movzbl (%ebx),%eax
f01008ce:	84 c0                	test   %al,%al
f01008d0:	74 63                	je     f0100935 <monitor+0xba>
f01008d2:	83 ec 08             	sub    $0x8,%esp
f01008d5:	0f be c0             	movsbl %al,%eax
f01008d8:	50                   	push   %eax
f01008d9:	68 77 24 10 f0       	push   $0xf0102477
f01008de:	e8 d4 0c 00 00       	call   f01015b7 <strchr>
f01008e3:	83 c4 10             	add    $0x10,%esp
f01008e6:	85 c0                	test   %eax,%eax
f01008e8:	75 d7                	jne    f01008c1 <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f01008ea:	80 3b 00             	cmpb   $0x0,(%ebx)
f01008ed:	74 46                	je     f0100935 <monitor+0xba>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01008ef:	83 fe 0f             	cmp    $0xf,%esi
f01008f2:	75 14                	jne    f0100908 <monitor+0x8d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01008f4:	83 ec 08             	sub    $0x8,%esp
f01008f7:	6a 10                	push   $0x10
f01008f9:	68 7c 24 10 f0       	push   $0xf010247c
f01008fe:	e8 e6 00 00 00       	call   f01009e9 <cprintf>
f0100903:	83 c4 10             	add    $0x10,%esp
f0100906:	eb 95                	jmp    f010089d <monitor+0x22>
			return 0;
		}
		argv[argc++] = buf;
f0100908:	8d 7e 01             	lea    0x1(%esi),%edi
f010090b:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f010090f:	eb 03                	jmp    f0100914 <monitor+0x99>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100911:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100914:	0f b6 03             	movzbl (%ebx),%eax
f0100917:	84 c0                	test   %al,%al
f0100919:	74 ae                	je     f01008c9 <monitor+0x4e>
f010091b:	83 ec 08             	sub    $0x8,%esp
f010091e:	0f be c0             	movsbl %al,%eax
f0100921:	50                   	push   %eax
f0100922:	68 77 24 10 f0       	push   $0xf0102477
f0100927:	e8 8b 0c 00 00       	call   f01015b7 <strchr>
f010092c:	83 c4 10             	add    $0x10,%esp
f010092f:	85 c0                	test   %eax,%eax
f0100931:	74 de                	je     f0100911 <monitor+0x96>
f0100933:	eb 94                	jmp    f01008c9 <monitor+0x4e>
			buf++;
	}
	argv[argc] = 0;
f0100935:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f010093c:	00 

	// Lookup and invoke the command
	if (argc == 0)
f010093d:	85 f6                	test   %esi,%esi
f010093f:	0f 84 58 ff ff ff    	je     f010089d <monitor+0x22>
f0100945:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f010094a:	83 ec 08             	sub    $0x8,%esp
f010094d:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100950:	ff 34 85 40 26 10 f0 	pushl  -0xfefd9c0(,%eax,4)
f0100957:	ff 75 a8             	pushl  -0x58(%ebp)
f010095a:	e8 fa 0b 00 00       	call   f0101559 <strcmp>
f010095f:	83 c4 10             	add    $0x10,%esp
f0100962:	85 c0                	test   %eax,%eax
f0100964:	75 22                	jne    f0100988 <monitor+0x10d>
			return commands[i].func(argc, argv, tf);
f0100966:	83 ec 04             	sub    $0x4,%esp
f0100969:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010096c:	ff 75 08             	pushl  0x8(%ebp)
f010096f:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100972:	52                   	push   %edx
f0100973:	56                   	push   %esi
f0100974:	ff 14 85 48 26 10 f0 	call   *-0xfefd9b8(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f010097b:	83 c4 10             	add    $0x10,%esp
f010097e:	85 c0                	test   %eax,%eax
f0100980:	0f 89 17 ff ff ff    	jns    f010089d <monitor+0x22>
f0100986:	eb 20                	jmp    f01009a8 <monitor+0x12d>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100988:	83 c3 01             	add    $0x1,%ebx
f010098b:	83 fb 03             	cmp    $0x3,%ebx
f010098e:	75 ba                	jne    f010094a <monitor+0xcf>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100990:	83 ec 08             	sub    $0x8,%esp
f0100993:	ff 75 a8             	pushl  -0x58(%ebp)
f0100996:	68 99 24 10 f0       	push   $0xf0102499
f010099b:	e8 49 00 00 00       	call   f01009e9 <cprintf>
f01009a0:	83 c4 10             	add    $0x10,%esp
f01009a3:	e9 f5 fe ff ff       	jmp    f010089d <monitor+0x22>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01009a8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01009ab:	5b                   	pop    %ebx
f01009ac:	5e                   	pop    %esi
f01009ad:	5f                   	pop    %edi
f01009ae:	5d                   	pop    %ebp
f01009af:	c3                   	ret    

f01009b0 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01009b0:	55                   	push   %ebp
f01009b1:	89 e5                	mov    %esp,%ebp
f01009b3:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f01009b6:	ff 75 08             	pushl  0x8(%ebp)
f01009b9:	e8 7d fc ff ff       	call   f010063b <cputchar>
f01009be:	83 c4 10             	add    $0x10,%esp
	*cnt++;
}
f01009c1:	c9                   	leave  
f01009c2:	c3                   	ret    

f01009c3 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01009c3:	55                   	push   %ebp
f01009c4:	89 e5                	mov    %esp,%ebp
f01009c6:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f01009c9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01009d0:	ff 75 0c             	pushl  0xc(%ebp)
f01009d3:	ff 75 08             	pushl  0x8(%ebp)
f01009d6:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01009d9:	50                   	push   %eax
f01009da:	68 b0 09 10 f0       	push   $0xf01009b0
f01009df:	e8 9b 04 00 00       	call   f0100e7f <vprintfmt>
	return cnt;
}
f01009e4:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01009e7:	c9                   	leave  
f01009e8:	c3                   	ret    

f01009e9 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01009e9:	55                   	push   %ebp
f01009ea:	89 e5                	mov    %esp,%ebp
f01009ec:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01009ef:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01009f2:	50                   	push   %eax
f01009f3:	ff 75 08             	pushl  0x8(%ebp)
f01009f6:	e8 c8 ff ff ff       	call   f01009c3 <vcprintf>
	va_end(ap);

	return cnt;
}
f01009fb:	c9                   	leave  
f01009fc:	c3                   	ret    

f01009fd <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01009fd:	55                   	push   %ebp
f01009fe:	89 e5                	mov    %esp,%ebp
f0100a00:	57                   	push   %edi
f0100a01:	56                   	push   %esi
f0100a02:	53                   	push   %ebx
f0100a03:	83 ec 14             	sub    $0x14,%esp
f0100a06:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0100a09:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100a0c:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100a0f:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100a12:	8b 1a                	mov    (%edx),%ebx
f0100a14:	8b 01                	mov    (%ecx),%eax
f0100a16:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a19:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0100a20:	e9 88 00 00 00       	jmp    f0100aad <stab_binsearch+0xb0>
		int true_m = (l + r) / 2, m = true_m;
f0100a25:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100a28:	01 d8                	add    %ebx,%eax
f0100a2a:	89 c6                	mov    %eax,%esi
f0100a2c:	c1 ee 1f             	shr    $0x1f,%esi
f0100a2f:	01 c6                	add    %eax,%esi
f0100a31:	d1 fe                	sar    %esi
f0100a33:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0100a36:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100a39:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0100a3c:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a3e:	eb 03                	jmp    f0100a43 <stab_binsearch+0x46>
			m--;
f0100a40:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a43:	39 c3                	cmp    %eax,%ebx
f0100a45:	7f 1f                	jg     f0100a66 <stab_binsearch+0x69>
f0100a47:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0100a4b:	83 ea 0c             	sub    $0xc,%edx
f0100a4e:	39 f9                	cmp    %edi,%ecx
f0100a50:	75 ee                	jne    f0100a40 <stab_binsearch+0x43>
f0100a52:	89 45 e8             	mov    %eax,-0x18(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100a55:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100a58:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100a5b:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0100a5f:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100a62:	76 18                	jbe    f0100a7c <stab_binsearch+0x7f>
f0100a64:	eb 05                	jmp    f0100a6b <stab_binsearch+0x6e>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100a66:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0100a69:	eb 42                	jmp    f0100aad <stab_binsearch+0xb0>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100a6b:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100a6e:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0100a70:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a73:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100a7a:	eb 31                	jmp    f0100aad <stab_binsearch+0xb0>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100a7c:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100a7f:	73 17                	jae    f0100a98 <stab_binsearch+0x9b>
			*region_right = m - 1;
f0100a81:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100a84:	83 e8 01             	sub    $0x1,%eax
f0100a87:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a8a:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100a8d:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a8f:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100a96:	eb 15                	jmp    f0100aad <stab_binsearch+0xb0>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100a98:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100a9b:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100a9e:	89 1e                	mov    %ebx,(%esi)
			l = m;
			addr++;
f0100aa0:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0100aa4:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100aa6:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100aad:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100ab0:	0f 8e 6f ff ff ff    	jle    f0100a25 <stab_binsearch+0x28>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100ab6:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0100aba:	75 0f                	jne    f0100acb <stab_binsearch+0xce>
		*region_right = *region_left - 1;
f0100abc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100abf:	8b 00                	mov    (%eax),%eax
f0100ac1:	83 e8 01             	sub    $0x1,%eax
f0100ac4:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100ac7:	89 06                	mov    %eax,(%esi)
f0100ac9:	eb 2c                	jmp    f0100af7 <stab_binsearch+0xfa>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100acb:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ace:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100ad0:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100ad3:	8b 0e                	mov    (%esi),%ecx
f0100ad5:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100ad8:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0100adb:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100ade:	eb 03                	jmp    f0100ae3 <stab_binsearch+0xe6>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100ae0:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100ae3:	39 c8                	cmp    %ecx,%eax
f0100ae5:	7e 0b                	jle    f0100af2 <stab_binsearch+0xf5>
		     l > *region_left && stabs[l].n_type != type;
f0100ae7:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0100aeb:	83 ea 0c             	sub    $0xc,%edx
f0100aee:	39 fb                	cmp    %edi,%ebx
f0100af0:	75 ee                	jne    f0100ae0 <stab_binsearch+0xe3>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100af2:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100af5:	89 06                	mov    %eax,(%esi)
	}
}
f0100af7:	83 c4 14             	add    $0x14,%esp
f0100afa:	5b                   	pop    %ebx
f0100afb:	5e                   	pop    %esi
f0100afc:	5f                   	pop    %edi
f0100afd:	5d                   	pop    %ebp
f0100afe:	c3                   	ret    

f0100aff <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100aff:	55                   	push   %ebp
f0100b00:	89 e5                	mov    %esp,%ebp
f0100b02:	57                   	push   %edi
f0100b03:	56                   	push   %esi
f0100b04:	53                   	push   %ebx
f0100b05:	83 ec 1c             	sub    $0x1c,%esp
f0100b08:	8b 7d 08             	mov    0x8(%ebp),%edi
f0100b0b:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100b0e:	c7 06 70 26 10 f0    	movl   $0xf0102670,(%esi)
	info->eip_line = 0;
f0100b14:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0100b1b:	c7 46 08 70 26 10 f0 	movl   $0xf0102670,0x8(%esi)
	info->eip_fn_namelen = 9;
f0100b22:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f0100b29:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0100b2c:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100b33:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0100b39:	76 11                	jbe    f0100b4c <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b3b:	b8 0f 8e 10 f0       	mov    $0xf0108e0f,%eax
f0100b40:	3d 71 71 10 f0       	cmp    $0xf0107171,%eax
f0100b45:	77 19                	ja     f0100b60 <debuginfo_eip+0x61>
f0100b47:	e9 4c 01 00 00       	jmp    f0100c98 <debuginfo_eip+0x199>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100b4c:	83 ec 04             	sub    $0x4,%esp
f0100b4f:	68 7a 26 10 f0       	push   $0xf010267a
f0100b54:	6a 7f                	push   $0x7f
f0100b56:	68 87 26 10 f0       	push   $0xf0102687
f0100b5b:	e8 86 f5 ff ff       	call   f01000e6 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b60:	80 3d 0e 8e 10 f0 00 	cmpb   $0x0,0xf0108e0e
f0100b67:	0f 85 32 01 00 00    	jne    f0100c9f <debuginfo_eip+0x1a0>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100b6d:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100b74:	b8 70 71 10 f0       	mov    $0xf0107170,%eax
f0100b79:	2d e0 28 10 f0       	sub    $0xf01028e0,%eax
f0100b7e:	c1 f8 02             	sar    $0x2,%eax
f0100b81:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100b87:	83 e8 01             	sub    $0x1,%eax
f0100b8a:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100b8d:	83 ec 08             	sub    $0x8,%esp
f0100b90:	57                   	push   %edi
f0100b91:	6a 64                	push   $0x64
f0100b93:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100b96:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100b99:	b8 e0 28 10 f0       	mov    $0xf01028e0,%eax
f0100b9e:	e8 5a fe ff ff       	call   f01009fd <stab_binsearch>
	if (lfile == 0)
f0100ba3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ba6:	83 c4 10             	add    $0x10,%esp
f0100ba9:	85 c0                	test   %eax,%eax
f0100bab:	0f 84 f5 00 00 00    	je     f0100ca6 <debuginfo_eip+0x1a7>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100bb1:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100bb4:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100bb7:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100bba:	83 ec 08             	sub    $0x8,%esp
f0100bbd:	57                   	push   %edi
f0100bbe:	6a 24                	push   $0x24
f0100bc0:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100bc3:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100bc6:	b8 e0 28 10 f0       	mov    $0xf01028e0,%eax
f0100bcb:	e8 2d fe ff ff       	call   f01009fd <stab_binsearch>

	if (lfun <= rfun) {
f0100bd0:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100bd3:	83 c4 10             	add    $0x10,%esp
f0100bd6:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f0100bd9:	7f 31                	jg     f0100c0c <debuginfo_eip+0x10d>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100bdb:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100bde:	c1 e0 02             	shl    $0x2,%eax
f0100be1:	8d 90 e0 28 10 f0    	lea    -0xfefd720(%eax),%edx
f0100be7:	8b 88 e0 28 10 f0    	mov    -0xfefd720(%eax),%ecx
f0100bed:	b8 0f 8e 10 f0       	mov    $0xf0108e0f,%eax
f0100bf2:	2d 71 71 10 f0       	sub    $0xf0107171,%eax
f0100bf7:	39 c1                	cmp    %eax,%ecx
f0100bf9:	73 09                	jae    f0100c04 <debuginfo_eip+0x105>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100bfb:	81 c1 71 71 10 f0    	add    $0xf0107171,%ecx
f0100c01:	89 4e 08             	mov    %ecx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100c04:	8b 42 08             	mov    0x8(%edx),%eax
f0100c07:	89 46 10             	mov    %eax,0x10(%esi)
f0100c0a:	eb 06                	jmp    f0100c12 <debuginfo_eip+0x113>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100c0c:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0100c0f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100c12:	83 ec 08             	sub    $0x8,%esp
f0100c15:	6a 3a                	push   $0x3a
f0100c17:	ff 76 08             	pushl  0x8(%esi)
f0100c1a:	e8 b9 09 00 00       	call   f01015d8 <strfind>
f0100c1f:	2b 46 08             	sub    0x8(%esi),%eax
f0100c22:	89 46 0c             	mov    %eax,0xc(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c25:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100c28:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100c2b:	8d 04 85 e0 28 10 f0 	lea    -0xfefd720(,%eax,4),%eax
f0100c32:	83 c4 10             	add    $0x10,%esp
f0100c35:	eb 06                	jmp    f0100c3d <debuginfo_eip+0x13e>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100c37:	83 eb 01             	sub    $0x1,%ebx
f0100c3a:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c3d:	39 fb                	cmp    %edi,%ebx
f0100c3f:	7c 1e                	jl     f0100c5f <debuginfo_eip+0x160>
	       && stabs[lline].n_type != N_SOL
f0100c41:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f0100c45:	80 fa 84             	cmp    $0x84,%dl
f0100c48:	74 6a                	je     f0100cb4 <debuginfo_eip+0x1b5>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100c4a:	80 fa 64             	cmp    $0x64,%dl
f0100c4d:	75 e8                	jne    f0100c37 <debuginfo_eip+0x138>
f0100c4f:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0100c53:	74 e2                	je     f0100c37 <debuginfo_eip+0x138>
f0100c55:	eb 5d                	jmp    f0100cb4 <debuginfo_eip+0x1b5>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100c57:	81 c2 71 71 10 f0    	add    $0xf0107171,%edx
f0100c5d:	89 16                	mov    %edx,(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c5f:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100c62:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c65:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c6a:	39 cb                	cmp    %ecx,%ebx
f0100c6c:	7d 60                	jge    f0100cce <debuginfo_eip+0x1cf>
		for (lline = lfun + 1;
f0100c6e:	8d 53 01             	lea    0x1(%ebx),%edx
f0100c71:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100c74:	8d 04 85 e0 28 10 f0 	lea    -0xfefd720(,%eax,4),%eax
f0100c7b:	eb 07                	jmp    f0100c84 <debuginfo_eip+0x185>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100c7d:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0100c81:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100c84:	39 ca                	cmp    %ecx,%edx
f0100c86:	74 25                	je     f0100cad <debuginfo_eip+0x1ae>
f0100c88:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100c8b:	80 78 04 a0          	cmpb   $0xa0,0x4(%eax)
f0100c8f:	74 ec                	je     f0100c7d <debuginfo_eip+0x17e>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c91:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c96:	eb 36                	jmp    f0100cce <debuginfo_eip+0x1cf>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100c98:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c9d:	eb 2f                	jmp    f0100cce <debuginfo_eip+0x1cf>
f0100c9f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100ca4:	eb 28                	jmp    f0100cce <debuginfo_eip+0x1cf>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100ca6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100cab:	eb 21                	jmp    f0100cce <debuginfo_eip+0x1cf>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100cad:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cb2:	eb 1a                	jmp    f0100cce <debuginfo_eip+0x1cf>
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100cb4:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100cb7:	8b 14 85 e0 28 10 f0 	mov    -0xfefd720(,%eax,4),%edx
f0100cbe:	b8 0f 8e 10 f0       	mov    $0xf0108e0f,%eax
f0100cc3:	2d 71 71 10 f0       	sub    $0xf0107171,%eax
f0100cc8:	39 c2                	cmp    %eax,%edx
f0100cca:	72 8b                	jb     f0100c57 <debuginfo_eip+0x158>
f0100ccc:	eb 91                	jmp    f0100c5f <debuginfo_eip+0x160>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
}
f0100cce:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100cd1:	5b                   	pop    %ebx
f0100cd2:	5e                   	pop    %esi
f0100cd3:	5f                   	pop    %edi
f0100cd4:	5d                   	pop    %ebp
f0100cd5:	c3                   	ret    

f0100cd6 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100cd6:	55                   	push   %ebp
f0100cd7:	89 e5                	mov    %esp,%ebp
f0100cd9:	57                   	push   %edi
f0100cda:	56                   	push   %esi
f0100cdb:	53                   	push   %ebx
f0100cdc:	83 ec 1c             	sub    $0x1c,%esp
f0100cdf:	89 c7                	mov    %eax,%edi
f0100ce1:	89 d6                	mov    %edx,%esi
f0100ce3:	8b 45 08             	mov    0x8(%ebp),%eax
f0100ce6:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100ce9:	89 d1                	mov    %edx,%ecx
f0100ceb:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100cee:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100cf1:	8b 45 10             	mov    0x10(%ebp),%eax
f0100cf4:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100cf7:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100cfa:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0100d01:	39 4d e4             	cmp    %ecx,-0x1c(%ebp)
f0100d04:	72 05                	jb     f0100d0b <printnum+0x35>
f0100d06:	3b 45 d8             	cmp    -0x28(%ebp),%eax
f0100d09:	77 3e                	ja     f0100d49 <printnum+0x73>
                               
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100d0b:	83 ec 0c             	sub    $0xc,%esp
f0100d0e:	ff 75 18             	pushl  0x18(%ebp)
f0100d11:	83 eb 01             	sub    $0x1,%ebx
f0100d14:	53                   	push   %ebx
f0100d15:	50                   	push   %eax
f0100d16:	83 ec 08             	sub    $0x8,%esp
f0100d19:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100d1c:	ff 75 e0             	pushl  -0x20(%ebp)
f0100d1f:	ff 75 dc             	pushl  -0x24(%ebp)
f0100d22:	ff 75 d8             	pushl  -0x28(%ebp)
f0100d25:	e8 f6 10 00 00       	call   f0101e20 <__udivdi3>
f0100d2a:	83 c4 18             	add    $0x18,%esp
f0100d2d:	52                   	push   %edx
f0100d2e:	50                   	push   %eax
f0100d2f:	89 f2                	mov    %esi,%edx
f0100d31:	89 f8                	mov    %edi,%eax
f0100d33:	e8 9e ff ff ff       	call   f0100cd6 <printnum>
f0100d38:	83 c4 20             	add    $0x20,%esp
f0100d3b:	eb 13                	jmp    f0100d50 <printnum+0x7a>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100d3d:	83 ec 08             	sub    $0x8,%esp
f0100d40:	56                   	push   %esi
f0100d41:	ff 75 18             	pushl  0x18(%ebp)
f0100d44:	ff d7                	call   *%edi
f0100d46:	83 c4 10             	add    $0x10,%esp
	if (num >= base) {
                               
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100d49:	83 eb 01             	sub    $0x1,%ebx
f0100d4c:	85 db                	test   %ebx,%ebx
f0100d4e:	7f ed                	jg     f0100d3d <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100d50:	83 ec 08             	sub    $0x8,%esp
f0100d53:	56                   	push   %esi
f0100d54:	83 ec 04             	sub    $0x4,%esp
f0100d57:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100d5a:	ff 75 e0             	pushl  -0x20(%ebp)
f0100d5d:	ff 75 dc             	pushl  -0x24(%ebp)
f0100d60:	ff 75 d8             	pushl  -0x28(%ebp)
f0100d63:	e8 e8 11 00 00       	call   f0101f50 <__umoddi3>
f0100d68:	83 c4 14             	add    $0x14,%esp
f0100d6b:	0f be 80 95 26 10 f0 	movsbl -0xfefd96b(%eax),%eax
f0100d72:	50                   	push   %eax
f0100d73:	ff d7                	call   *%edi
f0100d75:	83 c4 10             	add    $0x10,%esp
       
}
f0100d78:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100d7b:	5b                   	pop    %ebx
f0100d7c:	5e                   	pop    %esi
f0100d7d:	5f                   	pop    %edi
f0100d7e:	5d                   	pop    %ebp
f0100d7f:	c3                   	ret    

f0100d80 <printnum2>:
static void
printnum2(void (*putch)(int, void*), void *putdat,
	 double num_float, unsigned base, int width, int padc)
{      
f0100d80:	55                   	push   %ebp
f0100d81:	89 e5                	mov    %esp,%ebp
f0100d83:	57                   	push   %edi
f0100d84:	56                   	push   %esi
f0100d85:	53                   	push   %ebx
f0100d86:	83 ec 3c             	sub    $0x3c,%esp
f0100d89:	89 c7                	mov    %eax,%edi
f0100d8b:	89 d6                	mov    %edx,%esi
f0100d8d:	dd 45 08             	fldl   0x8(%ebp)
f0100d90:	dd 55 d0             	fstl   -0x30(%ebp)
f0100d93:	89 4d cc             	mov    %ecx,-0x34(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num_float >= base) { 
f0100d96:	89 4d c0             	mov    %ecx,-0x40(%ebp)
f0100d99:	c7 45 c4 00 00 00 00 	movl   $0x0,-0x3c(%ebp)
f0100da0:	df 6d c0             	fildll -0x40(%ebp)
f0100da3:	d9 c9                	fxch   %st(1)
f0100da5:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0100da8:	db e9                	fucomi %st(1),%st
f0100daa:	72 2d                	jb     f0100dd9 <printnum2+0x59>
		printnum2(putch, putdat, num_float / base, base, width - 1, padc);
f0100dac:	ff 75 14             	pushl  0x14(%ebp)
f0100daf:	8b 45 10             	mov    0x10(%ebp),%eax
f0100db2:	83 e8 01             	sub    $0x1,%eax
f0100db5:	50                   	push   %eax
f0100db6:	de f1                	fdivp  %st,%st(1)
f0100db8:	8d 64 24 f8          	lea    -0x8(%esp),%esp
f0100dbc:	dd 1c 24             	fstpl  (%esp)
f0100dbf:	89 f8                	mov    %edi,%eax
f0100dc1:	e8 ba ff ff ff       	call   f0100d80 <printnum2>
f0100dc6:	83 c4 10             	add    $0x10,%esp
f0100dc9:	eb 2c                	jmp    f0100df7 <printnum2+0x77>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100dcb:	83 ec 08             	sub    $0x8,%esp
f0100dce:	56                   	push   %esi
f0100dcf:	ff 75 14             	pushl  0x14(%ebp)
f0100dd2:	ff d7                	call   *%edi
f0100dd4:	83 c4 10             	add    $0x10,%esp
f0100dd7:	eb 04                	jmp    f0100ddd <printnum2+0x5d>
f0100dd9:	dd d8                	fstp   %st(0)
f0100ddb:	dd d8                	fstp   %st(0)
	// first recursively print all preceding (more significant) digits
	if (num_float >= base) { 
		printnum2(putch, putdat, num_float / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100ddd:	83 eb 01             	sub    $0x1,%ebx
f0100de0:	85 db                	test   %ebx,%ebx
f0100de2:	7f e7                	jg     f0100dcb <printnum2+0x4b>
f0100de4:	8b 55 10             	mov    0x10(%ebp),%edx
f0100de7:	83 ea 01             	sub    $0x1,%edx
f0100dea:	b8 00 00 00 00       	mov    $0x0,%eax
f0100def:	0f 49 c2             	cmovns %edx,%eax
f0100df2:	29 c2                	sub    %eax,%edx
f0100df4:	89 55 10             	mov    %edx,0x10(%ebp)
			putch(padc, putdat);
	}
        int x =(int)num_float;
	// then print this (the least significant) digit
	putch("0123456789abcdef"[x % base], putdat);
f0100df7:	83 ec 08             	sub    $0x8,%esp
f0100dfa:	56                   	push   %esi
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
	}
        int x =(int)num_float;
f0100dfb:	d9 7d de             	fnstcw -0x22(%ebp)
f0100dfe:	0f b7 45 de          	movzwl -0x22(%ebp),%eax
f0100e02:	b4 0c                	mov    $0xc,%ah
f0100e04:	66 89 45 dc          	mov    %ax,-0x24(%ebp)
f0100e08:	dd 45 d0             	fldl   -0x30(%ebp)
f0100e0b:	d9 6d dc             	fldcw  -0x24(%ebp)
f0100e0e:	db 5d d8             	fistpl -0x28(%ebp)
f0100e11:	d9 6d de             	fldcw  -0x22(%ebp)
f0100e14:	8b 45 d8             	mov    -0x28(%ebp),%eax
	// then print this (the least significant) digit
	putch("0123456789abcdef"[x % base], putdat);
f0100e17:	ba 00 00 00 00       	mov    $0x0,%edx
f0100e1c:	f7 75 cc             	divl   -0x34(%ebp)
f0100e1f:	0f be 82 95 26 10 f0 	movsbl -0xfefd96b(%edx),%eax
f0100e26:	50                   	push   %eax
f0100e27:	ff d7                	call   *%edi
        if ( width == -3) {
f0100e29:	83 c4 10             	add    $0x10,%esp
f0100e2c:	83 7d 10 fd          	cmpl   $0xfffffffd,0x10(%ebp)
f0100e30:	75 0b                	jne    f0100e3d <printnum2+0xbd>
        putch('.',putdat);}
f0100e32:	83 ec 08             	sub    $0x8,%esp
f0100e35:	56                   	push   %esi
f0100e36:	6a 2e                	push   $0x2e
f0100e38:	ff d7                	call   *%edi
f0100e3a:	83 c4 10             	add    $0x10,%esp
}
f0100e3d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e40:	5b                   	pop    %ebx
f0100e41:	5e                   	pop    %esi
f0100e42:	5f                   	pop    %edi
f0100e43:	5d                   	pop    %ebp
f0100e44:	c3                   	ret    

f0100e45 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100e45:	55                   	push   %ebp
f0100e46:	89 e5                	mov    %esp,%ebp
f0100e48:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100e4b:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100e4f:	8b 10                	mov    (%eax),%edx
f0100e51:	3b 50 04             	cmp    0x4(%eax),%edx
f0100e54:	73 0a                	jae    f0100e60 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100e56:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100e59:	89 08                	mov    %ecx,(%eax)
f0100e5b:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e5e:	88 02                	mov    %al,(%edx)
}
f0100e60:	5d                   	pop    %ebp
f0100e61:	c3                   	ret    

f0100e62 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100e62:	55                   	push   %ebp
f0100e63:	89 e5                	mov    %esp,%ebp
f0100e65:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100e68:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100e6b:	50                   	push   %eax
f0100e6c:	ff 75 10             	pushl  0x10(%ebp)
f0100e6f:	ff 75 0c             	pushl  0xc(%ebp)
f0100e72:	ff 75 08             	pushl  0x8(%ebp)
f0100e75:	e8 05 00 00 00       	call   f0100e7f <vprintfmt>
	va_end(ap);
f0100e7a:	83 c4 10             	add    $0x10,%esp
}
f0100e7d:	c9                   	leave  
f0100e7e:	c3                   	ret    

f0100e7f <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100e7f:	55                   	push   %ebp
f0100e80:	89 e5                	mov    %esp,%ebp
f0100e82:	57                   	push   %edi
f0100e83:	56                   	push   %esi
f0100e84:	53                   	push   %ebx
f0100e85:	83 ec 2c             	sub    $0x2c,%esp
f0100e88:	8b 75 08             	mov    0x8(%ebp),%esi
f0100e8b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100e8e:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100e91:	eb 12                	jmp    f0100ea5 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100e93:	85 c0                	test   %eax,%eax
f0100e95:	0f 84 92 04 00 00    	je     f010132d <vprintfmt+0x4ae>
				return;
			putch(ch, putdat);
f0100e9b:	83 ec 08             	sub    $0x8,%esp
f0100e9e:	53                   	push   %ebx
f0100e9f:	50                   	push   %eax
f0100ea0:	ff d6                	call   *%esi
f0100ea2:	83 c4 10             	add    $0x10,%esp
        double num_float;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100ea5:	83 c7 01             	add    $0x1,%edi
f0100ea8:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0100eac:	83 f8 25             	cmp    $0x25,%eax
f0100eaf:	75 e2                	jne    f0100e93 <vprintfmt+0x14>
f0100eb1:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0100eb5:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100ebc:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100ec3:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0100eca:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100ecf:	eb 07                	jmp    f0100ed8 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ed1:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100ed4:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ed8:	8d 47 01             	lea    0x1(%edi),%eax
f0100edb:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100ede:	0f b6 07             	movzbl (%edi),%eax
f0100ee1:	0f b6 d0             	movzbl %al,%edx
f0100ee4:	83 e8 23             	sub    $0x23,%eax
f0100ee7:	3c 55                	cmp    $0x55,%al
f0100ee9:	0f 87 23 04 00 00    	ja     f0101312 <vprintfmt+0x493>
f0100eef:	0f b6 c0             	movzbl %al,%eax
f0100ef2:	ff 24 85 40 27 10 f0 	jmp    *-0xfefd8c0(,%eax,4)
f0100ef9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100efc:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0100f00:	eb d6                	jmp    f0100ed8 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f02:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100f05:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f0a:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100f0d:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100f10:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0100f14:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0100f17:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0100f1a:	83 f9 09             	cmp    $0x9,%ecx
f0100f1d:	77 3f                	ja     f0100f5e <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100f1f:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0100f22:	eb e9                	jmp    f0100f0d <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100f24:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f27:	8b 00                	mov    (%eax),%eax
f0100f29:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100f2c:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f2f:	8d 40 04             	lea    0x4(%eax),%eax
f0100f32:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f35:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100f38:	eb 2a                	jmp    f0100f64 <vprintfmt+0xe5>
f0100f3a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100f3d:	85 c0                	test   %eax,%eax
f0100f3f:	ba 00 00 00 00       	mov    $0x0,%edx
f0100f44:	0f 49 d0             	cmovns %eax,%edx
f0100f47:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f4a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100f4d:	eb 89                	jmp    f0100ed8 <vprintfmt+0x59>
f0100f4f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100f52:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0100f59:	e9 7a ff ff ff       	jmp    f0100ed8 <vprintfmt+0x59>
f0100f5e:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100f61:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0100f64:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100f68:	0f 89 6a ff ff ff    	jns    f0100ed8 <vprintfmt+0x59>
				width = precision, precision = -1;
f0100f6e:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100f71:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100f74:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100f7b:	e9 58 ff ff ff       	jmp    f0100ed8 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100f80:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f83:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100f86:	e9 4d ff ff ff       	jmp    f0100ed8 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f8b:	8b 45 14             	mov    0x14(%ebp),%eax
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100f8e:	83 45 14 04          	addl   $0x4,0x14(%ebp)
f0100f92:	83 ec 08             	sub    $0x8,%esp
f0100f95:	53                   	push   %ebx
f0100f96:	ff 30                	pushl  (%eax)
f0100f98:	ff d6                	call   *%esi
			break;
f0100f9a:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f9d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0100fa0:	e9 00 ff ff ff       	jmp    f0100ea5 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100fa5:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fa8:	8d 78 04             	lea    0x4(%eax),%edi
f0100fab:	8b 00                	mov    (%eax),%eax
f0100fad:	99                   	cltd   
f0100fae:	31 d0                	xor    %edx,%eax
f0100fb0:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100fb2:	83 f8 07             	cmp    $0x7,%eax
f0100fb5:	7f 0b                	jg     f0100fc2 <vprintfmt+0x143>
f0100fb7:	8b 14 85 a0 28 10 f0 	mov    -0xfefd760(,%eax,4),%edx
f0100fbe:	85 d2                	test   %edx,%edx
f0100fc0:	75 1b                	jne    f0100fdd <vprintfmt+0x15e>
				printfmt(putch, putdat, "error %d", err);
f0100fc2:	50                   	push   %eax
f0100fc3:	68 ad 26 10 f0       	push   $0xf01026ad
f0100fc8:	53                   	push   %ebx
f0100fc9:	56                   	push   %esi
f0100fca:	e8 93 fe ff ff       	call   f0100e62 <printfmt>
f0100fcf:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100fd2:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fd5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0100fd8:	e9 c8 fe ff ff       	jmp    f0100ea5 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0100fdd:	52                   	push   %edx
f0100fde:	68 b6 26 10 f0       	push   $0xf01026b6
f0100fe3:	53                   	push   %ebx
f0100fe4:	56                   	push   %esi
f0100fe5:	e8 78 fe ff ff       	call   f0100e62 <printfmt>
f0100fea:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100fed:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ff0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100ff3:	e9 ad fe ff ff       	jmp    f0100ea5 <vprintfmt+0x26>
f0100ff8:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ffb:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0100ffe:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0101001:	89 4d cc             	mov    %ecx,-0x34(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0101004:	83 45 14 04          	addl   $0x4,0x14(%ebp)
f0101008:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f010100a:	85 ff                	test   %edi,%edi
f010100c:	b8 a6 26 10 f0       	mov    $0xf01026a6,%eax
f0101011:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0101014:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0101018:	0f 84 90 00 00 00    	je     f01010ae <vprintfmt+0x22f>
f010101e:	85 c9                	test   %ecx,%ecx
f0101020:	0f 8e 96 00 00 00    	jle    f01010bc <vprintfmt+0x23d>
				for (width -= strnlen(p, precision); width > 0; width--)
f0101026:	83 ec 08             	sub    $0x8,%esp
f0101029:	52                   	push   %edx
f010102a:	57                   	push   %edi
f010102b:	e8 5e 04 00 00       	call   f010148e <strnlen>
f0101030:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0101033:	29 c1                	sub    %eax,%ecx
f0101035:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0101038:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f010103b:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f010103f:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101042:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0101045:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101047:	eb 0f                	jmp    f0101058 <vprintfmt+0x1d9>
					putch(padc, putdat);
f0101049:	83 ec 08             	sub    $0x8,%esp
f010104c:	53                   	push   %ebx
f010104d:	ff 75 e0             	pushl  -0x20(%ebp)
f0101050:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101052:	83 ef 01             	sub    $0x1,%edi
f0101055:	83 c4 10             	add    $0x10,%esp
f0101058:	85 ff                	test   %edi,%edi
f010105a:	7f ed                	jg     f0101049 <vprintfmt+0x1ca>
f010105c:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010105f:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0101062:	85 c9                	test   %ecx,%ecx
f0101064:	b8 00 00 00 00       	mov    $0x0,%eax
f0101069:	0f 49 c1             	cmovns %ecx,%eax
f010106c:	29 c1                	sub    %eax,%ecx
f010106e:	89 75 08             	mov    %esi,0x8(%ebp)
f0101071:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101074:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101077:	89 cb                	mov    %ecx,%ebx
f0101079:	eb 4d                	jmp    f01010c8 <vprintfmt+0x249>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f010107b:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f010107f:	74 1b                	je     f010109c <vprintfmt+0x21d>
f0101081:	0f be c0             	movsbl %al,%eax
f0101084:	83 e8 20             	sub    $0x20,%eax
f0101087:	83 f8 5e             	cmp    $0x5e,%eax
f010108a:	76 10                	jbe    f010109c <vprintfmt+0x21d>
					putch('?', putdat);
f010108c:	83 ec 08             	sub    $0x8,%esp
f010108f:	ff 75 0c             	pushl  0xc(%ebp)
f0101092:	6a 3f                	push   $0x3f
f0101094:	ff 55 08             	call   *0x8(%ebp)
f0101097:	83 c4 10             	add    $0x10,%esp
f010109a:	eb 0d                	jmp    f01010a9 <vprintfmt+0x22a>
				else
					putch(ch, putdat);
f010109c:	83 ec 08             	sub    $0x8,%esp
f010109f:	ff 75 0c             	pushl  0xc(%ebp)
f01010a2:	52                   	push   %edx
f01010a3:	ff 55 08             	call   *0x8(%ebp)
f01010a6:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01010a9:	83 eb 01             	sub    $0x1,%ebx
f01010ac:	eb 1a                	jmp    f01010c8 <vprintfmt+0x249>
f01010ae:	89 75 08             	mov    %esi,0x8(%ebp)
f01010b1:	8b 75 d0             	mov    -0x30(%ebp),%esi
f01010b4:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01010b7:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f01010ba:	eb 0c                	jmp    f01010c8 <vprintfmt+0x249>
f01010bc:	89 75 08             	mov    %esi,0x8(%ebp)
f01010bf:	8b 75 d0             	mov    -0x30(%ebp),%esi
f01010c2:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01010c5:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f01010c8:	83 c7 01             	add    $0x1,%edi
f01010cb:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f01010cf:	0f be d0             	movsbl %al,%edx
f01010d2:	85 d2                	test   %edx,%edx
f01010d4:	74 23                	je     f01010f9 <vprintfmt+0x27a>
f01010d6:	85 f6                	test   %esi,%esi
f01010d8:	78 a1                	js     f010107b <vprintfmt+0x1fc>
f01010da:	83 ee 01             	sub    $0x1,%esi
f01010dd:	79 9c                	jns    f010107b <vprintfmt+0x1fc>
f01010df:	89 df                	mov    %ebx,%edi
f01010e1:	8b 75 08             	mov    0x8(%ebp),%esi
f01010e4:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01010e7:	eb 18                	jmp    f0101101 <vprintfmt+0x282>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01010e9:	83 ec 08             	sub    $0x8,%esp
f01010ec:	53                   	push   %ebx
f01010ed:	6a 20                	push   $0x20
f01010ef:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01010f1:	83 ef 01             	sub    $0x1,%edi
f01010f4:	83 c4 10             	add    $0x10,%esp
f01010f7:	eb 08                	jmp    f0101101 <vprintfmt+0x282>
f01010f9:	89 df                	mov    %ebx,%edi
f01010fb:	8b 75 08             	mov    0x8(%ebp),%esi
f01010fe:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101101:	85 ff                	test   %edi,%edi
f0101103:	7f e4                	jg     f01010e9 <vprintfmt+0x26a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101105:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101108:	e9 98 fd ff ff       	jmp    f0100ea5 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f010110d:	83 f9 01             	cmp    $0x1,%ecx
f0101110:	7e 19                	jle    f010112b <vprintfmt+0x2ac>
		return va_arg(*ap, long long);
f0101112:	8b 45 14             	mov    0x14(%ebp),%eax
f0101115:	8b 50 04             	mov    0x4(%eax),%edx
f0101118:	8b 00                	mov    (%eax),%eax
f010111a:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010111d:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101120:	8b 45 14             	mov    0x14(%ebp),%eax
f0101123:	8d 40 08             	lea    0x8(%eax),%eax
f0101126:	89 45 14             	mov    %eax,0x14(%ebp)
f0101129:	eb 38                	jmp    f0101163 <vprintfmt+0x2e4>
	else if (lflag)
f010112b:	85 c9                	test   %ecx,%ecx
f010112d:	74 1b                	je     f010114a <vprintfmt+0x2cb>
		return va_arg(*ap, long);
f010112f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101132:	8b 00                	mov    (%eax),%eax
f0101134:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101137:	89 c1                	mov    %eax,%ecx
f0101139:	c1 f9 1f             	sar    $0x1f,%ecx
f010113c:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f010113f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101142:	8d 40 04             	lea    0x4(%eax),%eax
f0101145:	89 45 14             	mov    %eax,0x14(%ebp)
f0101148:	eb 19                	jmp    f0101163 <vprintfmt+0x2e4>
	else
		return va_arg(*ap, int);
f010114a:	8b 45 14             	mov    0x14(%ebp),%eax
f010114d:	8b 00                	mov    (%eax),%eax
f010114f:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101152:	89 c1                	mov    %eax,%ecx
f0101154:	c1 f9 1f             	sar    $0x1f,%ecx
f0101157:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f010115a:	8b 45 14             	mov    0x14(%ebp),%eax
f010115d:	8d 40 04             	lea    0x4(%eax),%eax
f0101160:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0101163:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101166:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0101169:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f010116e:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0101172:	0f 89 66 01 00 00    	jns    f01012de <vprintfmt+0x45f>
				putch('-', putdat);
f0101178:	83 ec 08             	sub    $0x8,%esp
f010117b:	53                   	push   %ebx
f010117c:	6a 2d                	push   $0x2d
f010117e:	ff d6                	call   *%esi
				num = -(long long) num;
f0101180:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101183:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0101186:	f7 da                	neg    %edx
f0101188:	83 d1 00             	adc    $0x0,%ecx
f010118b:	f7 d9                	neg    %ecx
f010118d:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0101190:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101195:	e9 44 01 00 00       	jmp    f01012de <vprintfmt+0x45f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f010119a:	83 f9 01             	cmp    $0x1,%ecx
f010119d:	7e 18                	jle    f01011b7 <vprintfmt+0x338>
		return va_arg(*ap, unsigned long long);
f010119f:	8b 45 14             	mov    0x14(%ebp),%eax
f01011a2:	8b 10                	mov    (%eax),%edx
f01011a4:	8b 48 04             	mov    0x4(%eax),%ecx
f01011a7:	8d 40 08             	lea    0x8(%eax),%eax
f01011aa:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f01011ad:	b8 0a 00 00 00       	mov    $0xa,%eax
f01011b2:	e9 27 01 00 00       	jmp    f01012de <vprintfmt+0x45f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f01011b7:	85 c9                	test   %ecx,%ecx
f01011b9:	74 1a                	je     f01011d5 <vprintfmt+0x356>
		return va_arg(*ap, unsigned long);
f01011bb:	8b 45 14             	mov    0x14(%ebp),%eax
f01011be:	8b 10                	mov    (%eax),%edx
f01011c0:	b9 00 00 00 00       	mov    $0x0,%ecx
f01011c5:	8d 40 04             	lea    0x4(%eax),%eax
f01011c8:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f01011cb:	b8 0a 00 00 00       	mov    $0xa,%eax
f01011d0:	e9 09 01 00 00       	jmp    f01012de <vprintfmt+0x45f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f01011d5:	8b 45 14             	mov    0x14(%ebp),%eax
f01011d8:	8b 10                	mov    (%eax),%edx
f01011da:	b9 00 00 00 00       	mov    $0x0,%ecx
f01011df:	8d 40 04             	lea    0x4(%eax),%eax
f01011e2:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f01011e5:	b8 0a 00 00 00       	mov    $0xa,%eax
f01011ea:	e9 ef 00 00 00       	jmp    f01012de <vprintfmt+0x45f>
			goto number;

               // signed float
		case 'f':
			num_float = va_arg(ap, double);
f01011ef:	8b 45 14             	mov    0x14(%ebp),%eax
f01011f2:	8d 78 08             	lea    0x8(%eax),%edi
                        num_float = num_float*100;
f01011f5:	d9 05 c0 28 10 f0    	flds   0xf01028c0
f01011fb:	dc 08                	fmull  (%eax)
f01011fd:	d9 c0                	fld    %st(0)
f01011ff:	dd 5d d8             	fstpl  -0x28(%ebp)
			if ( num_float < 0) {
f0101202:	d9 ee                	fldz   
f0101204:	df e9                	fucomip %st(1),%st
f0101206:	dd d8                	fstp   %st(0)
f0101208:	76 13                	jbe    f010121d <vprintfmt+0x39e>
				putch('-', putdat);
f010120a:	83 ec 08             	sub    $0x8,%esp
f010120d:	53                   	push   %ebx
f010120e:	6a 2d                	push   $0x2d
f0101210:	ff d6                	call   *%esi
				num_float = - num_float;
f0101212:	dd 45 d8             	fldl   -0x28(%ebp)
f0101215:	d9 e0                	fchs   
f0101217:	dd 5d d8             	fstpl  -0x28(%ebp)
f010121a:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
                        
			printnum2(putch, putdat, num_float, base, width, padc);
f010121d:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0101221:	50                   	push   %eax
f0101222:	ff 75 e0             	pushl  -0x20(%ebp)
f0101225:	ff 75 dc             	pushl  -0x24(%ebp)
f0101228:	ff 75 d8             	pushl  -0x28(%ebp)
f010122b:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0101230:	89 da                	mov    %ebx,%edx
f0101232:	89 f0                	mov    %esi,%eax
f0101234:	e8 47 fb ff ff       	call   f0100d80 <printnum2>
			break;
f0101239:	83 c4 10             	add    $0x10,%esp
			base = 10;
			goto number;

               // signed float
		case 'f':
			num_float = va_arg(ap, double);
f010123c:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010123f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
				num_float = - num_float;
			}
			base = 10;
                        
			printnum2(putch, putdat, num_float, base, width, padc);
			break;
f0101242:	e9 5e fc ff ff       	jmp    f0100ea5 <vprintfmt+0x26>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f0101247:	83 ec 08             	sub    $0x8,%esp
f010124a:	53                   	push   %ebx
f010124b:	6a 58                	push   $0x58
f010124d:	ff d6                	call   *%esi
			putch('X', putdat);
f010124f:	83 c4 08             	add    $0x8,%esp
f0101252:	53                   	push   %ebx
f0101253:	6a 58                	push   $0x58
f0101255:	ff d6                	call   *%esi
			putch('X', putdat);
f0101257:	83 c4 08             	add    $0x8,%esp
f010125a:	53                   	push   %ebx
f010125b:	6a 58                	push   $0x58
f010125d:	ff d6                	call   *%esi
			break;
f010125f:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101262:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
f0101265:	e9 3b fc ff ff       	jmp    f0100ea5 <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
f010126a:	83 ec 08             	sub    $0x8,%esp
f010126d:	53                   	push   %ebx
f010126e:	6a 30                	push   $0x30
f0101270:	ff d6                	call   *%esi
			putch('x', putdat);
f0101272:	83 c4 08             	add    $0x8,%esp
f0101275:	53                   	push   %ebx
f0101276:	6a 78                	push   $0x78
f0101278:	ff d6                	call   *%esi
			num = (unsigned long long)
f010127a:	8b 45 14             	mov    0x14(%ebp),%eax
f010127d:	8b 10                	mov    (%eax),%edx
f010127f:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0101284:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0101287:	8d 40 04             	lea    0x4(%eax),%eax
f010128a:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f010128d:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0101292:	eb 4a                	jmp    f01012de <vprintfmt+0x45f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101294:	83 f9 01             	cmp    $0x1,%ecx
f0101297:	7e 15                	jle    f01012ae <vprintfmt+0x42f>
		return va_arg(*ap, unsigned long long);
f0101299:	8b 45 14             	mov    0x14(%ebp),%eax
f010129c:	8b 10                	mov    (%eax),%edx
f010129e:	8b 48 04             	mov    0x4(%eax),%ecx
f01012a1:	8d 40 08             	lea    0x8(%eax),%eax
f01012a4:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f01012a7:	b8 10 00 00 00       	mov    $0x10,%eax
f01012ac:	eb 30                	jmp    f01012de <vprintfmt+0x45f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f01012ae:	85 c9                	test   %ecx,%ecx
f01012b0:	74 17                	je     f01012c9 <vprintfmt+0x44a>
		return va_arg(*ap, unsigned long);
f01012b2:	8b 45 14             	mov    0x14(%ebp),%eax
f01012b5:	8b 10                	mov    (%eax),%edx
f01012b7:	b9 00 00 00 00       	mov    $0x0,%ecx
f01012bc:	8d 40 04             	lea    0x4(%eax),%eax
f01012bf:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f01012c2:	b8 10 00 00 00       	mov    $0x10,%eax
f01012c7:	eb 15                	jmp    f01012de <vprintfmt+0x45f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f01012c9:	8b 45 14             	mov    0x14(%ebp),%eax
f01012cc:	8b 10                	mov    (%eax),%edx
f01012ce:	b9 00 00 00 00       	mov    $0x0,%ecx
f01012d3:	8d 40 04             	lea    0x4(%eax),%eax
f01012d6:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f01012d9:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f01012de:	83 ec 0c             	sub    $0xc,%esp
f01012e1:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f01012e5:	57                   	push   %edi
f01012e6:	ff 75 e0             	pushl  -0x20(%ebp)
f01012e9:	50                   	push   %eax
f01012ea:	51                   	push   %ecx
f01012eb:	52                   	push   %edx
f01012ec:	89 da                	mov    %ebx,%edx
f01012ee:	89 f0                	mov    %esi,%eax
f01012f0:	e8 e1 f9 ff ff       	call   f0100cd6 <printnum>
			break;
f01012f5:	83 c4 20             	add    $0x20,%esp
f01012f8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01012fb:	e9 a5 fb ff ff       	jmp    f0100ea5 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0101300:	83 ec 08             	sub    $0x8,%esp
f0101303:	53                   	push   %ebx
f0101304:	52                   	push   %edx
f0101305:	ff d6                	call   *%esi
			break;
f0101307:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010130a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f010130d:	e9 93 fb ff ff       	jmp    f0100ea5 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0101312:	83 ec 08             	sub    $0x8,%esp
f0101315:	53                   	push   %ebx
f0101316:	6a 25                	push   $0x25
f0101318:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f010131a:	83 c4 10             	add    $0x10,%esp
f010131d:	eb 03                	jmp    f0101322 <vprintfmt+0x4a3>
f010131f:	83 ef 01             	sub    $0x1,%edi
f0101322:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0101326:	75 f7                	jne    f010131f <vprintfmt+0x4a0>
f0101328:	e9 78 fb ff ff       	jmp    f0100ea5 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f010132d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101330:	5b                   	pop    %ebx
f0101331:	5e                   	pop    %esi
f0101332:	5f                   	pop    %edi
f0101333:	5d                   	pop    %ebp
f0101334:	c3                   	ret    

f0101335 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101335:	55                   	push   %ebp
f0101336:	89 e5                	mov    %esp,%ebp
f0101338:	83 ec 18             	sub    $0x18,%esp
f010133b:	8b 45 08             	mov    0x8(%ebp),%eax
f010133e:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101341:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101344:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101348:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010134b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101352:	85 c0                	test   %eax,%eax
f0101354:	74 26                	je     f010137c <vsnprintf+0x47>
f0101356:	85 d2                	test   %edx,%edx
f0101358:	7e 22                	jle    f010137c <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f010135a:	ff 75 14             	pushl  0x14(%ebp)
f010135d:	ff 75 10             	pushl  0x10(%ebp)
f0101360:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101363:	50                   	push   %eax
f0101364:	68 45 0e 10 f0       	push   $0xf0100e45
f0101369:	e8 11 fb ff ff       	call   f0100e7f <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010136e:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101371:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101374:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101377:	83 c4 10             	add    $0x10,%esp
f010137a:	eb 05                	jmp    f0101381 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f010137c:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0101381:	c9                   	leave  
f0101382:	c3                   	ret    

f0101383 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0101383:	55                   	push   %ebp
f0101384:	89 e5                	mov    %esp,%ebp
f0101386:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101389:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f010138c:	50                   	push   %eax
f010138d:	ff 75 10             	pushl  0x10(%ebp)
f0101390:	ff 75 0c             	pushl  0xc(%ebp)
f0101393:	ff 75 08             	pushl  0x8(%ebp)
f0101396:	e8 9a ff ff ff       	call   f0101335 <vsnprintf>
	va_end(ap);

	return rc;
f010139b:	c9                   	leave  
f010139c:	c3                   	ret    

f010139d <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f010139d:	55                   	push   %ebp
f010139e:	89 e5                	mov    %esp,%ebp
f01013a0:	57                   	push   %edi
f01013a1:	56                   	push   %esi
f01013a2:	53                   	push   %ebx
f01013a3:	83 ec 0c             	sub    $0xc,%esp
f01013a6:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01013a9:	85 c0                	test   %eax,%eax
f01013ab:	74 11                	je     f01013be <readline+0x21>
		cprintf("%s", prompt);
f01013ad:	83 ec 08             	sub    $0x8,%esp
f01013b0:	50                   	push   %eax
f01013b1:	68 b6 26 10 f0       	push   $0xf01026b6
f01013b6:	e8 2e f6 ff ff       	call   f01009e9 <cprintf>
f01013bb:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f01013be:	83 ec 0c             	sub    $0xc,%esp
f01013c1:	6a 00                	push   $0x0
f01013c3:	e8 94 f2 ff ff       	call   f010065c <iscons>
f01013c8:	89 c7                	mov    %eax,%edi
f01013ca:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01013cd:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01013d2:	e8 74 f2 ff ff       	call   f010064b <getchar>
f01013d7:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01013d9:	85 c0                	test   %eax,%eax
f01013db:	79 18                	jns    f01013f5 <readline+0x58>
			cprintf("read error: %e\n", c);
f01013dd:	83 ec 08             	sub    $0x8,%esp
f01013e0:	50                   	push   %eax
f01013e1:	68 c4 28 10 f0       	push   $0xf01028c4
f01013e6:	e8 fe f5 ff ff       	call   f01009e9 <cprintf>
			return NULL;
f01013eb:	83 c4 10             	add    $0x10,%esp
f01013ee:	b8 00 00 00 00       	mov    $0x0,%eax
f01013f3:	eb 79                	jmp    f010146e <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01013f5:	83 f8 7f             	cmp    $0x7f,%eax
f01013f8:	0f 94 c2             	sete   %dl
f01013fb:	83 f8 08             	cmp    $0x8,%eax
f01013fe:	0f 94 c0             	sete   %al
f0101401:	08 c2                	or     %al,%dl
f0101403:	74 1a                	je     f010141f <readline+0x82>
f0101405:	85 f6                	test   %esi,%esi
f0101407:	7e 16                	jle    f010141f <readline+0x82>
			if (echoing)
f0101409:	85 ff                	test   %edi,%edi
f010140b:	74 0d                	je     f010141a <readline+0x7d>
				cputchar('\b');
f010140d:	83 ec 0c             	sub    $0xc,%esp
f0101410:	6a 08                	push   $0x8
f0101412:	e8 24 f2 ff ff       	call   f010063b <cputchar>
f0101417:	83 c4 10             	add    $0x10,%esp
			i--;
f010141a:	83 ee 01             	sub    $0x1,%esi
f010141d:	eb b3                	jmp    f01013d2 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f010141f:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0101425:	7f 20                	jg     f0101447 <readline+0xaa>
f0101427:	83 fb 1f             	cmp    $0x1f,%ebx
f010142a:	7e 1b                	jle    f0101447 <readline+0xaa>
			if (echoing)
f010142c:	85 ff                	test   %edi,%edi
f010142e:	74 0c                	je     f010143c <readline+0x9f>
				cputchar(c);
f0101430:	83 ec 0c             	sub    $0xc,%esp
f0101433:	53                   	push   %ebx
f0101434:	e8 02 f2 ff ff       	call   f010063b <cputchar>
f0101439:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f010143c:	88 9e 80 35 11 f0    	mov    %bl,-0xfeeca80(%esi)
f0101442:	8d 76 01             	lea    0x1(%esi),%esi
f0101445:	eb 8b                	jmp    f01013d2 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0101447:	83 fb 0d             	cmp    $0xd,%ebx
f010144a:	74 05                	je     f0101451 <readline+0xb4>
f010144c:	83 fb 0a             	cmp    $0xa,%ebx
f010144f:	75 81                	jne    f01013d2 <readline+0x35>
			if (echoing)
f0101451:	85 ff                	test   %edi,%edi
f0101453:	74 0d                	je     f0101462 <readline+0xc5>
				cputchar('\n');
f0101455:	83 ec 0c             	sub    $0xc,%esp
f0101458:	6a 0a                	push   $0xa
f010145a:	e8 dc f1 ff ff       	call   f010063b <cputchar>
f010145f:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0101462:	c6 86 80 35 11 f0 00 	movb   $0x0,-0xfeeca80(%esi)
			return buf;
f0101469:	b8 80 35 11 f0       	mov    $0xf0113580,%eax
		}
	}
}
f010146e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101471:	5b                   	pop    %ebx
f0101472:	5e                   	pop    %esi
f0101473:	5f                   	pop    %edi
f0101474:	5d                   	pop    %ebp
f0101475:	c3                   	ret    

f0101476 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101476:	55                   	push   %ebp
f0101477:	89 e5                	mov    %esp,%ebp
f0101479:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f010147c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101481:	eb 03                	jmp    f0101486 <strlen+0x10>
		n++;
f0101483:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101486:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f010148a:	75 f7                	jne    f0101483 <strlen+0xd>
		n++;
	return n;
}
f010148c:	5d                   	pop    %ebp
f010148d:	c3                   	ret    

f010148e <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010148e:	55                   	push   %ebp
f010148f:	89 e5                	mov    %esp,%ebp
f0101491:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101494:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101497:	ba 00 00 00 00       	mov    $0x0,%edx
f010149c:	eb 03                	jmp    f01014a1 <strnlen+0x13>
		n++;
f010149e:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01014a1:	39 c2                	cmp    %eax,%edx
f01014a3:	74 08                	je     f01014ad <strnlen+0x1f>
f01014a5:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f01014a9:	75 f3                	jne    f010149e <strnlen+0x10>
f01014ab:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f01014ad:	5d                   	pop    %ebp
f01014ae:	c3                   	ret    

f01014af <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01014af:	55                   	push   %ebp
f01014b0:	89 e5                	mov    %esp,%ebp
f01014b2:	53                   	push   %ebx
f01014b3:	8b 45 08             	mov    0x8(%ebp),%eax
f01014b6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01014b9:	89 c2                	mov    %eax,%edx
f01014bb:	83 c2 01             	add    $0x1,%edx
f01014be:	83 c1 01             	add    $0x1,%ecx
f01014c1:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01014c5:	88 5a ff             	mov    %bl,-0x1(%edx)
f01014c8:	84 db                	test   %bl,%bl
f01014ca:	75 ef                	jne    f01014bb <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01014cc:	5b                   	pop    %ebx
f01014cd:	5d                   	pop    %ebp
f01014ce:	c3                   	ret    

f01014cf <strcat>:

char *
strcat(char *dst, const char *src)
{
f01014cf:	55                   	push   %ebp
f01014d0:	89 e5                	mov    %esp,%ebp
f01014d2:	53                   	push   %ebx
f01014d3:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01014d6:	53                   	push   %ebx
f01014d7:	e8 9a ff ff ff       	call   f0101476 <strlen>
f01014dc:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f01014df:	ff 75 0c             	pushl  0xc(%ebp)
f01014e2:	01 d8                	add    %ebx,%eax
f01014e4:	50                   	push   %eax
f01014e5:	e8 c5 ff ff ff       	call   f01014af <strcpy>
	return dst;
}
f01014ea:	89 d8                	mov    %ebx,%eax
f01014ec:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01014ef:	c9                   	leave  
f01014f0:	c3                   	ret    

f01014f1 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01014f1:	55                   	push   %ebp
f01014f2:	89 e5                	mov    %esp,%ebp
f01014f4:	56                   	push   %esi
f01014f5:	53                   	push   %ebx
f01014f6:	8b 75 08             	mov    0x8(%ebp),%esi
f01014f9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01014fc:	89 f3                	mov    %esi,%ebx
f01014fe:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101501:	89 f2                	mov    %esi,%edx
f0101503:	eb 0f                	jmp    f0101514 <strncpy+0x23>
		*dst++ = *src;
f0101505:	83 c2 01             	add    $0x1,%edx
f0101508:	0f b6 01             	movzbl (%ecx),%eax
f010150b:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010150e:	80 39 01             	cmpb   $0x1,(%ecx)
f0101511:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101514:	39 da                	cmp    %ebx,%edx
f0101516:	75 ed                	jne    f0101505 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101518:	89 f0                	mov    %esi,%eax
f010151a:	5b                   	pop    %ebx
f010151b:	5e                   	pop    %esi
f010151c:	5d                   	pop    %ebp
f010151d:	c3                   	ret    

f010151e <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010151e:	55                   	push   %ebp
f010151f:	89 e5                	mov    %esp,%ebp
f0101521:	56                   	push   %esi
f0101522:	53                   	push   %ebx
f0101523:	8b 75 08             	mov    0x8(%ebp),%esi
f0101526:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101529:	8b 55 10             	mov    0x10(%ebp),%edx
f010152c:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f010152e:	85 d2                	test   %edx,%edx
f0101530:	74 21                	je     f0101553 <strlcpy+0x35>
f0101532:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0101536:	89 f2                	mov    %esi,%edx
f0101538:	eb 09                	jmp    f0101543 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f010153a:	83 c2 01             	add    $0x1,%edx
f010153d:	83 c1 01             	add    $0x1,%ecx
f0101540:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101543:	39 c2                	cmp    %eax,%edx
f0101545:	74 09                	je     f0101550 <strlcpy+0x32>
f0101547:	0f b6 19             	movzbl (%ecx),%ebx
f010154a:	84 db                	test   %bl,%bl
f010154c:	75 ec                	jne    f010153a <strlcpy+0x1c>
f010154e:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0101550:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0101553:	29 f0                	sub    %esi,%eax
}
f0101555:	5b                   	pop    %ebx
f0101556:	5e                   	pop    %esi
f0101557:	5d                   	pop    %ebp
f0101558:	c3                   	ret    

f0101559 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101559:	55                   	push   %ebp
f010155a:	89 e5                	mov    %esp,%ebp
f010155c:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010155f:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101562:	eb 06                	jmp    f010156a <strcmp+0x11>
		p++, q++;
f0101564:	83 c1 01             	add    $0x1,%ecx
f0101567:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010156a:	0f b6 01             	movzbl (%ecx),%eax
f010156d:	84 c0                	test   %al,%al
f010156f:	74 04                	je     f0101575 <strcmp+0x1c>
f0101571:	3a 02                	cmp    (%edx),%al
f0101573:	74 ef                	je     f0101564 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101575:	0f b6 c0             	movzbl %al,%eax
f0101578:	0f b6 12             	movzbl (%edx),%edx
f010157b:	29 d0                	sub    %edx,%eax
}
f010157d:	5d                   	pop    %ebp
f010157e:	c3                   	ret    

f010157f <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f010157f:	55                   	push   %ebp
f0101580:	89 e5                	mov    %esp,%ebp
f0101582:	53                   	push   %ebx
f0101583:	8b 45 08             	mov    0x8(%ebp),%eax
f0101586:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101589:	89 c3                	mov    %eax,%ebx
f010158b:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f010158e:	eb 06                	jmp    f0101596 <strncmp+0x17>
		n--, p++, q++;
f0101590:	83 c0 01             	add    $0x1,%eax
f0101593:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101596:	39 d8                	cmp    %ebx,%eax
f0101598:	74 15                	je     f01015af <strncmp+0x30>
f010159a:	0f b6 08             	movzbl (%eax),%ecx
f010159d:	84 c9                	test   %cl,%cl
f010159f:	74 04                	je     f01015a5 <strncmp+0x26>
f01015a1:	3a 0a                	cmp    (%edx),%cl
f01015a3:	74 eb                	je     f0101590 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01015a5:	0f b6 00             	movzbl (%eax),%eax
f01015a8:	0f b6 12             	movzbl (%edx),%edx
f01015ab:	29 d0                	sub    %edx,%eax
f01015ad:	eb 05                	jmp    f01015b4 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01015af:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01015b4:	5b                   	pop    %ebx
f01015b5:	5d                   	pop    %ebp
f01015b6:	c3                   	ret    

f01015b7 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01015b7:	55                   	push   %ebp
f01015b8:	89 e5                	mov    %esp,%ebp
f01015ba:	8b 45 08             	mov    0x8(%ebp),%eax
f01015bd:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01015c1:	eb 07                	jmp    f01015ca <strchr+0x13>
		if (*s == c)
f01015c3:	38 ca                	cmp    %cl,%dl
f01015c5:	74 0f                	je     f01015d6 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01015c7:	83 c0 01             	add    $0x1,%eax
f01015ca:	0f b6 10             	movzbl (%eax),%edx
f01015cd:	84 d2                	test   %dl,%dl
f01015cf:	75 f2                	jne    f01015c3 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f01015d1:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01015d6:	5d                   	pop    %ebp
f01015d7:	c3                   	ret    

f01015d8 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01015d8:	55                   	push   %ebp
f01015d9:	89 e5                	mov    %esp,%ebp
f01015db:	8b 45 08             	mov    0x8(%ebp),%eax
f01015de:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01015e2:	eb 03                	jmp    f01015e7 <strfind+0xf>
f01015e4:	83 c0 01             	add    $0x1,%eax
f01015e7:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01015ea:	84 d2                	test   %dl,%dl
f01015ec:	74 04                	je     f01015f2 <strfind+0x1a>
f01015ee:	38 ca                	cmp    %cl,%dl
f01015f0:	75 f2                	jne    f01015e4 <strfind+0xc>
			break;
	return (char *) s;
}
f01015f2:	5d                   	pop    %ebp
f01015f3:	c3                   	ret    

f01015f4 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01015f4:	55                   	push   %ebp
f01015f5:	89 e5                	mov    %esp,%ebp
f01015f7:	57                   	push   %edi
f01015f8:	56                   	push   %esi
f01015f9:	53                   	push   %ebx
f01015fa:	8b 7d 08             	mov    0x8(%ebp),%edi
f01015fd:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101600:	85 c9                	test   %ecx,%ecx
f0101602:	74 36                	je     f010163a <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101604:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010160a:	75 28                	jne    f0101634 <memset+0x40>
f010160c:	f6 c1 03             	test   $0x3,%cl
f010160f:	75 23                	jne    f0101634 <memset+0x40>
		c &= 0xFF;
f0101611:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101615:	89 d3                	mov    %edx,%ebx
f0101617:	c1 e3 08             	shl    $0x8,%ebx
f010161a:	89 d6                	mov    %edx,%esi
f010161c:	c1 e6 18             	shl    $0x18,%esi
f010161f:	89 d0                	mov    %edx,%eax
f0101621:	c1 e0 10             	shl    $0x10,%eax
f0101624:	09 f0                	or     %esi,%eax
f0101626:	09 c2                	or     %eax,%edx
f0101628:	89 d0                	mov    %edx,%eax
f010162a:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f010162c:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f010162f:	fc                   	cld    
f0101630:	f3 ab                	rep stos %eax,%es:(%edi)
f0101632:	eb 06                	jmp    f010163a <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0101634:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101637:	fc                   	cld    
f0101638:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010163a:	89 f8                	mov    %edi,%eax
f010163c:	5b                   	pop    %ebx
f010163d:	5e                   	pop    %esi
f010163e:	5f                   	pop    %edi
f010163f:	5d                   	pop    %ebp
f0101640:	c3                   	ret    

f0101641 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101641:	55                   	push   %ebp
f0101642:	89 e5                	mov    %esp,%ebp
f0101644:	57                   	push   %edi
f0101645:	56                   	push   %esi
f0101646:	8b 45 08             	mov    0x8(%ebp),%eax
f0101649:	8b 75 0c             	mov    0xc(%ebp),%esi
f010164c:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f010164f:	39 c6                	cmp    %eax,%esi
f0101651:	73 35                	jae    f0101688 <memmove+0x47>
f0101653:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0101656:	39 d0                	cmp    %edx,%eax
f0101658:	73 2e                	jae    f0101688 <memmove+0x47>
		s += n;
		d += n;
f010165a:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f010165d:	89 d6                	mov    %edx,%esi
f010165f:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101661:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0101667:	75 13                	jne    f010167c <memmove+0x3b>
f0101669:	f6 c1 03             	test   $0x3,%cl
f010166c:	75 0e                	jne    f010167c <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f010166e:	83 ef 04             	sub    $0x4,%edi
f0101671:	8d 72 fc             	lea    -0x4(%edx),%esi
f0101674:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f0101677:	fd                   	std    
f0101678:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010167a:	eb 09                	jmp    f0101685 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f010167c:	83 ef 01             	sub    $0x1,%edi
f010167f:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0101682:	fd                   	std    
f0101683:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101685:	fc                   	cld    
f0101686:	eb 1d                	jmp    f01016a5 <memmove+0x64>
f0101688:	89 f2                	mov    %esi,%edx
f010168a:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010168c:	f6 c2 03             	test   $0x3,%dl
f010168f:	75 0f                	jne    f01016a0 <memmove+0x5f>
f0101691:	f6 c1 03             	test   $0x3,%cl
f0101694:	75 0a                	jne    f01016a0 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0101696:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0101699:	89 c7                	mov    %eax,%edi
f010169b:	fc                   	cld    
f010169c:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010169e:	eb 05                	jmp    f01016a5 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01016a0:	89 c7                	mov    %eax,%edi
f01016a2:	fc                   	cld    
f01016a3:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01016a5:	5e                   	pop    %esi
f01016a6:	5f                   	pop    %edi
f01016a7:	5d                   	pop    %ebp
f01016a8:	c3                   	ret    

f01016a9 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01016a9:	55                   	push   %ebp
f01016aa:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01016ac:	ff 75 10             	pushl  0x10(%ebp)
f01016af:	ff 75 0c             	pushl  0xc(%ebp)
f01016b2:	ff 75 08             	pushl  0x8(%ebp)
f01016b5:	e8 87 ff ff ff       	call   f0101641 <memmove>
}
f01016ba:	c9                   	leave  
f01016bb:	c3                   	ret    

f01016bc <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01016bc:	55                   	push   %ebp
f01016bd:	89 e5                	mov    %esp,%ebp
f01016bf:	56                   	push   %esi
f01016c0:	53                   	push   %ebx
f01016c1:	8b 45 08             	mov    0x8(%ebp),%eax
f01016c4:	8b 55 0c             	mov    0xc(%ebp),%edx
f01016c7:	89 c6                	mov    %eax,%esi
f01016c9:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01016cc:	eb 1a                	jmp    f01016e8 <memcmp+0x2c>
		if (*s1 != *s2)
f01016ce:	0f b6 08             	movzbl (%eax),%ecx
f01016d1:	0f b6 1a             	movzbl (%edx),%ebx
f01016d4:	38 d9                	cmp    %bl,%cl
f01016d6:	74 0a                	je     f01016e2 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f01016d8:	0f b6 c1             	movzbl %cl,%eax
f01016db:	0f b6 db             	movzbl %bl,%ebx
f01016de:	29 d8                	sub    %ebx,%eax
f01016e0:	eb 0f                	jmp    f01016f1 <memcmp+0x35>
		s1++, s2++;
f01016e2:	83 c0 01             	add    $0x1,%eax
f01016e5:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01016e8:	39 f0                	cmp    %esi,%eax
f01016ea:	75 e2                	jne    f01016ce <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01016ec:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01016f1:	5b                   	pop    %ebx
f01016f2:	5e                   	pop    %esi
f01016f3:	5d                   	pop    %ebp
f01016f4:	c3                   	ret    

f01016f5 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01016f5:	55                   	push   %ebp
f01016f6:	89 e5                	mov    %esp,%ebp
f01016f8:	8b 45 08             	mov    0x8(%ebp),%eax
f01016fb:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f01016fe:	89 c2                	mov    %eax,%edx
f0101700:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0101703:	eb 07                	jmp    f010170c <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101705:	38 08                	cmp    %cl,(%eax)
f0101707:	74 07                	je     f0101710 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0101709:	83 c0 01             	add    $0x1,%eax
f010170c:	39 d0                	cmp    %edx,%eax
f010170e:	72 f5                	jb     f0101705 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0101710:	5d                   	pop    %ebp
f0101711:	c3                   	ret    

f0101712 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101712:	55                   	push   %ebp
f0101713:	89 e5                	mov    %esp,%ebp
f0101715:	57                   	push   %edi
f0101716:	56                   	push   %esi
f0101717:	53                   	push   %ebx
f0101718:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010171b:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010171e:	eb 03                	jmp    f0101723 <strtol+0x11>
		s++;
f0101720:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101723:	0f b6 01             	movzbl (%ecx),%eax
f0101726:	3c 09                	cmp    $0x9,%al
f0101728:	74 f6                	je     f0101720 <strtol+0xe>
f010172a:	3c 20                	cmp    $0x20,%al
f010172c:	74 f2                	je     f0101720 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f010172e:	3c 2b                	cmp    $0x2b,%al
f0101730:	75 0a                	jne    f010173c <strtol+0x2a>
		s++;
f0101732:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0101735:	bf 00 00 00 00       	mov    $0x0,%edi
f010173a:	eb 10                	jmp    f010174c <strtol+0x3a>
f010173c:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0101741:	3c 2d                	cmp    $0x2d,%al
f0101743:	75 07                	jne    f010174c <strtol+0x3a>
		s++, neg = 1;
f0101745:	8d 49 01             	lea    0x1(%ecx),%ecx
f0101748:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010174c:	85 db                	test   %ebx,%ebx
f010174e:	0f 94 c0             	sete   %al
f0101751:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0101757:	75 19                	jne    f0101772 <strtol+0x60>
f0101759:	80 39 30             	cmpb   $0x30,(%ecx)
f010175c:	75 14                	jne    f0101772 <strtol+0x60>
f010175e:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0101762:	0f 85 82 00 00 00    	jne    f01017ea <strtol+0xd8>
		s += 2, base = 16;
f0101768:	83 c1 02             	add    $0x2,%ecx
f010176b:	bb 10 00 00 00       	mov    $0x10,%ebx
f0101770:	eb 16                	jmp    f0101788 <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f0101772:	84 c0                	test   %al,%al
f0101774:	74 12                	je     f0101788 <strtol+0x76>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0101776:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010177b:	80 39 30             	cmpb   $0x30,(%ecx)
f010177e:	75 08                	jne    f0101788 <strtol+0x76>
		s++, base = 8;
f0101780:	83 c1 01             	add    $0x1,%ecx
f0101783:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0101788:	b8 00 00 00 00       	mov    $0x0,%eax
f010178d:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101790:	0f b6 11             	movzbl (%ecx),%edx
f0101793:	8d 72 d0             	lea    -0x30(%edx),%esi
f0101796:	89 f3                	mov    %esi,%ebx
f0101798:	80 fb 09             	cmp    $0x9,%bl
f010179b:	77 08                	ja     f01017a5 <strtol+0x93>
			dig = *s - '0';
f010179d:	0f be d2             	movsbl %dl,%edx
f01017a0:	83 ea 30             	sub    $0x30,%edx
f01017a3:	eb 22                	jmp    f01017c7 <strtol+0xb5>
		else if (*s >= 'a' && *s <= 'z')
f01017a5:	8d 72 9f             	lea    -0x61(%edx),%esi
f01017a8:	89 f3                	mov    %esi,%ebx
f01017aa:	80 fb 19             	cmp    $0x19,%bl
f01017ad:	77 08                	ja     f01017b7 <strtol+0xa5>
			dig = *s - 'a' + 10;
f01017af:	0f be d2             	movsbl %dl,%edx
f01017b2:	83 ea 57             	sub    $0x57,%edx
f01017b5:	eb 10                	jmp    f01017c7 <strtol+0xb5>
		else if (*s >= 'A' && *s <= 'Z')
f01017b7:	8d 72 bf             	lea    -0x41(%edx),%esi
f01017ba:	89 f3                	mov    %esi,%ebx
f01017bc:	80 fb 19             	cmp    $0x19,%bl
f01017bf:	77 16                	ja     f01017d7 <strtol+0xc5>
			dig = *s - 'A' + 10;
f01017c1:	0f be d2             	movsbl %dl,%edx
f01017c4:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f01017c7:	3b 55 10             	cmp    0x10(%ebp),%edx
f01017ca:	7d 0f                	jge    f01017db <strtol+0xc9>
			break;
		s++, val = (val * base) + dig;
f01017cc:	83 c1 01             	add    $0x1,%ecx
f01017cf:	0f af 45 10          	imul   0x10(%ebp),%eax
f01017d3:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f01017d5:	eb b9                	jmp    f0101790 <strtol+0x7e>
f01017d7:	89 c2                	mov    %eax,%edx
f01017d9:	eb 02                	jmp    f01017dd <strtol+0xcb>
f01017db:	89 c2                	mov    %eax,%edx

	if (endptr)
f01017dd:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01017e1:	74 0d                	je     f01017f0 <strtol+0xde>
		*endptr = (char *) s;
f01017e3:	8b 75 0c             	mov    0xc(%ebp),%esi
f01017e6:	89 0e                	mov    %ecx,(%esi)
f01017e8:	eb 06                	jmp    f01017f0 <strtol+0xde>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01017ea:	84 c0                	test   %al,%al
f01017ec:	75 92                	jne    f0101780 <strtol+0x6e>
f01017ee:	eb 98                	jmp    f0101788 <strtol+0x76>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f01017f0:	f7 da                	neg    %edx
f01017f2:	85 ff                	test   %edi,%edi
f01017f4:	0f 45 c2             	cmovne %edx,%eax
}
f01017f7:	5b                   	pop    %ebx
f01017f8:	5e                   	pop    %esi
f01017f9:	5f                   	pop    %edi
f01017fa:	5d                   	pop    %ebp
f01017fb:	c3                   	ret    

f01017fc <subtract_List_Operation>:
#include <inc/calculator.h>



void subtract_List_Operation(operantion op[])
{
f01017fc:	55                   	push   %ebp
f01017fd:	89 e5                	mov    %esp,%ebp
f01017ff:	8b 55 08             	mov    0x8(%ebp),%edx
f0101802:	89 d0                	mov    %edx,%eax
f0101804:	83 c2 30             	add    $0x30,%edx
	int i;
	for (i = 0; i < 6; i++)
	{
		op[i].position = op[i].position - 1;
f0101807:	83 28 01             	subl   $0x1,(%eax)
f010180a:	83 c0 08             	add    $0x8,%eax


void subtract_List_Operation(operantion op[])
{
	int i;
	for (i = 0; i < 6; i++)
f010180d:	39 d0                	cmp    %edx,%eax
f010180f:	75 f6                	jne    f0101807 <subtract_List_Operation+0xb>
	{
		op[i].position = op[i].position - 1;
	}
}
f0101811:	5d                   	pop    %ebp
f0101812:	c3                   	ret    

f0101813 <Isoperation>:

int Isoperation(char r)
{
f0101813:	55                   	push   %ebp
f0101814:	89 e5                	mov    %esp,%ebp
f0101816:	8b 55 08             	mov    0x8(%ebp),%edx
	if (r == '+' || r == '-' || r == '*' || r == '/' || r == '%')
f0101819:	89 d0                	mov    %edx,%eax
f010181b:	83 e0 f7             	and    $0xfffffff7,%eax
f010181e:	3c 25                	cmp    $0x25,%al
f0101820:	0f 94 c1             	sete   %cl
f0101823:	80 fa 2f             	cmp    $0x2f,%dl
f0101826:	0f 94 c0             	sete   %al
f0101829:	09 c8                	or     %ecx,%eax
f010182b:	83 ea 2a             	sub    $0x2a,%edx
f010182e:	80 fa 01             	cmp    $0x1,%dl
f0101831:	0f 96 c2             	setbe  %dl
f0101834:	09 d0                	or     %edx,%eax
f0101836:	0f b6 c0             	movzbl %al,%eax
	}
	else
	{
		return 0;
	}
}
f0101839:	5d                   	pop    %ebp
f010183a:	c3                   	ret    

f010183b <Isnumber>:


int Isnumber(char r)
{
f010183b:	55                   	push   %ebp
f010183c:	89 e5                	mov    %esp,%ebp
	if (r >= '0' && r <= '9')
f010183e:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
f0101842:	83 e8 30             	sub    $0x30,%eax
f0101845:	3c 09                	cmp    $0x9,%al
f0101847:	0f 96 c0             	setbe  %al
f010184a:	0f b6 c0             	movzbl %al,%eax
	}
	else
	{
		return 0;
	}
}
f010184d:	5d                   	pop    %ebp
f010184e:	c3                   	ret    

f010184f <Isdot>:

int Isdot(char r)
{
f010184f:	55                   	push   %ebp
f0101850:	89 e5                	mov    %esp,%ebp
	if (r == '.')
f0101852:	80 7d 08 2e          	cmpb   $0x2e,0x8(%ebp)
f0101856:	0f 94 c0             	sete   %al
f0101859:	0f b6 c0             	movzbl %al,%eax
	else
	{
		return 0;
	}

}
f010185c:	5d                   	pop    %ebp
f010185d:	c3                   	ret    

f010185e <removeItem>:

void removeItem(float str[], int location)
{
f010185e:	55                   	push   %ebp
f010185f:	89 e5                	mov    %esp,%ebp
f0101861:	8b 55 08             	mov    0x8(%ebp),%edx
f0101864:	8b 45 0c             	mov    0xc(%ebp),%eax
	int i;

	for (i = location; i < 6; i++)
f0101867:	eb 0a                	jmp    f0101873 <removeItem+0x15>
	{
		str[i] = str[i + 1];
f0101869:	d9 44 82 04          	flds   0x4(%edx,%eax,4)
f010186d:	d9 1c 82             	fstps  (%edx,%eax,4)

void removeItem(float str[], int location)
{
	int i;

	for (i = location; i < 6; i++)
f0101870:	83 c0 01             	add    $0x1,%eax
f0101873:	83 f8 05             	cmp    $0x5,%eax
f0101876:	7e f1                	jle    f0101869 <removeItem+0xb>
	{
		str[i] = str[i + 1];
	}

	str[6] = 0;
f0101878:	c7 42 18 00 00 00 00 	movl   $0x0,0x18(%edx)

}
f010187f:	5d                   	pop    %ebp
f0101880:	c3                   	ret    

f0101881 <clearnumber>:

void clearnumber(char * number)
{
f0101881:	55                   	push   %ebp
f0101882:	89 e5                	mov    %esp,%ebp
f0101884:	56                   	push   %esi
f0101885:	53                   	push   %ebx
f0101886:	8b 75 08             	mov    0x8(%ebp),%esi

	int i = 0;
	for (i = 0; i < strlen(number); i++)
f0101889:	bb 00 00 00 00       	mov    $0x0,%ebx
f010188e:	eb 07                	jmp    f0101897 <clearnumber+0x16>
	{
		number[i] = '0';
f0101890:	c6 04 1e 30          	movb   $0x30,(%esi,%ebx,1)

void clearnumber(char * number)
{

	int i = 0;
	for (i = 0; i < strlen(number); i++)
f0101894:	83 c3 01             	add    $0x1,%ebx
f0101897:	83 ec 0c             	sub    $0xc,%esp
f010189a:	56                   	push   %esi
f010189b:	e8 d6 fb ff ff       	call   f0101476 <strlen>
f01018a0:	83 c4 10             	add    $0x10,%esp
f01018a3:	39 c3                	cmp    %eax,%ebx
f01018a5:	7c e9                	jl     f0101890 <clearnumber+0xf>
	{
		number[i] = '0';
	}
	number[strlen(number)] = '\0';
f01018a7:	83 ec 0c             	sub    $0xc,%esp
f01018aa:	56                   	push   %esi
f01018ab:	e8 c6 fb ff ff       	call   f0101476 <strlen>
f01018b0:	c6 04 06 00          	movb   $0x0,(%esi,%eax,1)
f01018b4:	83 c4 10             	add    $0x10,%esp
}
f01018b7:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01018ba:	5b                   	pop    %ebx
f01018bb:	5e                   	pop    %esi
f01018bc:	5d                   	pop    %ebp
f01018bd:	c3                   	ret    

f01018be <Getnumber>:


Float Getnumber(char* str, int *i)
{
f01018be:	55                   	push   %ebp
f01018bf:	89 e5                	mov    %esp,%ebp
f01018c1:	57                   	push   %edi
f01018c2:	56                   	push   %esi
f01018c3:	53                   	push   %ebx
f01018c4:	81 ec 98 00 00 00    	sub    $0x98,%esp
f01018ca:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01018cd:	8b 5d 10             	mov    0x10(%ebp),%ebx
	Float Value;
	int dot = 1;
	int y = 0;
	char number[100];
	number[strlen(str)] = '\0';
f01018d0:	57                   	push   %edi
f01018d1:	e8 a0 fb ff ff       	call   f0101476 <strlen>
f01018d6:	c6 44 05 84 00       	movb   $0x0,-0x7c(%ebp,%eax,1)
	clearnumber(number);
f01018db:	8d 45 84             	lea    -0x7c(%ebp),%eax
f01018de:	89 04 24             	mov    %eax,(%esp)
f01018e1:	e8 9b ff ff ff       	call   f0101881 <clearnumber>
			y = 1;
	number[0] = str[*i];
f01018e6:	8b 03                	mov    (%ebx),%eax
f01018e8:	0f b6 04 07          	movzbl (%edi,%eax,1),%eax
f01018ec:	88 45 84             	mov    %al,-0x7c(%ebp)
f01018ef:	83 c3 08             	add    $0x8,%ebx
	*i++;
	while (*i < strlen(str))
f01018f2:	83 c4 10             	add    $0x10,%esp
f01018f5:	be 02 00 00 00       	mov    $0x2,%esi


Float Getnumber(char* str, int *i)
{
	Float Value;
	int dot = 1;
f01018fa:	c7 85 68 ff ff ff 01 	movl   $0x1,-0x98(%ebp)
f0101901:	00 00 00 
	number[strlen(str)] = '\0';
	clearnumber(number);
			y = 1;
	number[0] = str[*i];
	*i++;
	while (*i < strlen(str))
f0101904:	eb 4a                	jmp    f0101950 <Getnumber+0x92>
	{
		if (Isnumber(str[*i]))
f0101906:	8b 43 fc             	mov    -0x4(%ebx),%eax
f0101909:	0f b6 04 07          	movzbl (%edi,%eax,1),%eax
}


int Isnumber(char r)
{
	if (r >= '0' && r <= '9')
f010190d:	8d 50 d0             	lea    -0x30(%eax),%edx
			y = 1;
	number[0] = str[*i];
	*i++;
	while (*i < strlen(str))
	{
		if (Isnumber(str[*i]))
f0101910:	80 fa 09             	cmp    $0x9,%dl
f0101913:	77 06                	ja     f010191b <Getnumber+0x5d>
		{
			number[y] = str[*i];
f0101915:	88 44 35 83          	mov    %al,-0x7d(%ebp,%esi,1)
f0101919:	eb 2f                	jmp    f010194a <Getnumber+0x8c>
			y++;
			*i++;
		}
		else if (Isdot((str[*i])) && dot)
f010191b:	3c 2e                	cmp    $0x2e,%al
f010191d:	75 19                	jne    f0101938 <Getnumber+0x7a>
f010191f:	8b 95 68 ff ff ff    	mov    -0x98(%ebp),%edx
f0101925:	85 d2                	test   %edx,%edx
f0101927:	74 0f                	je     f0101938 <Getnumber+0x7a>
		{
			number[y] = str[*i];
f0101929:	88 44 35 83          	mov    %al,-0x7d(%ebp,%esi,1)
			dot--;
f010192d:	83 ea 01             	sub    $0x1,%edx
f0101930:	89 95 68 ff ff ff    	mov    %edx,-0x98(%ebp)
			y++;
			*i++;
f0101936:	eb 12                	jmp    f010194a <Getnumber+0x8c>
		}
		else
		{
			Value.error = 1;
			Value.number = 1;
			return Value;
f0101938:	8b 45 08             	mov    0x8(%ebp),%eax
f010193b:	c7 00 00 00 80 3f    	movl   $0x3f800000,(%eax)
f0101941:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
f0101948:	eb 4d                	jmp    f0101997 <Getnumber+0xd9>
f010194a:	83 c3 04             	add    $0x4,%ebx
f010194d:	83 c6 01             	add    $0x1,%esi
	number[strlen(str)] = '\0';
	clearnumber(number);
			y = 1;
	number[0] = str[*i];
	*i++;
	while (*i < strlen(str))
f0101950:	8b 43 fc             	mov    -0x4(%ebx),%eax
f0101953:	89 85 6c ff ff ff    	mov    %eax,-0x94(%ebp)
f0101959:	83 ec 0c             	sub    $0xc,%esp
f010195c:	57                   	push   %edi
f010195d:	e8 14 fb ff ff       	call   f0101476 <strlen>
f0101962:	83 c4 10             	add    $0x10,%esp
f0101965:	39 85 6c ff ff ff    	cmp    %eax,-0x94(%ebp)
f010196b:	7c 99                	jl     f0101906 <Getnumber+0x48>
			Value.error = 1;
			Value.number = 1;
			return Value;
		}
	}
	Value = char_to_float(number);
f010196d:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
f0101973:	83 ec 08             	sub    $0x8,%esp
f0101976:	8d 55 84             	lea    -0x7c(%ebp),%edx
f0101979:	52                   	push   %edx
f010197a:	50                   	push   %eax
f010197b:	e8 7e 03 00 00       	call   f0101cfe <char_to_float>
f0101980:	8b 85 70 ff ff ff    	mov    -0x90(%ebp),%eax
	return Value;
f0101986:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101989:	89 01                	mov    %eax,(%ecx)
f010198b:	8b 85 74 ff ff ff    	mov    -0x8c(%ebp),%eax
f0101991:	89 41 04             	mov    %eax,0x4(%ecx)
f0101994:	83 c4 0c             	add    $0xc,%esp


}
f0101997:	8b 45 08             	mov    0x8(%ebp),%eax
f010199a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010199d:	5b                   	pop    %ebx
f010199e:	5e                   	pop    %esi
f010199f:	5f                   	pop    %edi
f01019a0:	5d                   	pop    %ebp
f01019a1:	c2 04 00             	ret    $0x4

f01019a4 <GetOperation>:

Char GetOperation(char* str, int i)
{
f01019a4:	55                   	push   %ebp
f01019a5:	89 e5                	mov    %esp,%ebp
f01019a7:	53                   	push   %ebx
f01019a8:	8b 45 08             	mov    0x8(%ebp),%eax
	Char operat;
	if (str[i] == '-' || str[i] == '+' || str[i] == '*' || str[i] == '/' || str[i] == '%')
f01019ab:	8b 55 10             	mov    0x10(%ebp),%edx
f01019ae:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01019b1:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f01019b5:	89 d1                	mov    %edx,%ecx
f01019b7:	83 e1 f7             	and    $0xfffffff7,%ecx
f01019ba:	80 f9 25             	cmp    $0x25,%cl
f01019bd:	0f 94 c3             	sete   %bl
f01019c0:	80 fa 2f             	cmp    $0x2f,%dl
f01019c3:	0f 94 c1             	sete   %cl
f01019c6:	08 cb                	or     %cl,%bl
f01019c8:	75 08                	jne    f01019d2 <GetOperation+0x2e>
f01019ca:	8d 4a d6             	lea    -0x2a(%edx),%ecx
f01019cd:	80 f9 01             	cmp    $0x1,%cl
f01019d0:	77 0b                	ja     f01019dd <GetOperation+0x39>
	{
		operat.error = 0;
		operat.value = str[i];
		return operat;
f01019d2:	88 10                	mov    %dl,(%eax)
f01019d4:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
f01019db:	eb 0a                	jmp    f01019e7 <GetOperation+0x43>
	}
	else
	{
		operat.error = 1;
		operat.value = '0';
		return operat;
f01019dd:	c6 00 30             	movb   $0x30,(%eax)
f01019e0:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
	}

}
f01019e7:	5b                   	pop    %ebx
f01019e8:	5d                   	pop    %ebp
f01019e9:	c2 04 00             	ret    $0x4

f01019ec <calc>:

void calc(float numbers[], operantion op[])
{
f01019ec:	55                   	push   %ebp
f01019ed:	89 e5                	mov    %esp,%ebp
f01019ef:	57                   	push   %edi
f01019f0:	56                   	push   %esi
f01019f1:	53                   	push   %ebx
f01019f2:	83 ec 1c             	sub    $0x1c,%esp
f01019f5:	8b 75 08             	mov    0x8(%ebp),%esi
f01019f8:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01019fb:	89 fb                	mov    %edi,%ebx
f01019fd:	8d 47 30             	lea    0x30(%edi),%eax
f0101a00:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101a03:	89 da                	mov    %ebx,%edx
	int i;

	for (i = 0; i < 6; i++)
	{
		if (op[i].operant == '*')
f0101a05:	0f b6 43 04          	movzbl 0x4(%ebx),%eax
f0101a09:	3c 2a                	cmp    $0x2a,%al
f0101a0b:	75 19                	jne    f0101a26 <calc+0x3a>
		{
			numbers[op[i].position - 1] = numbers[op[i].position - 1] * numbers[op[i].position];
f0101a0d:	8b 03                	mov    (%ebx),%eax
f0101a0f:	8d 0c 85 fc ff ff ff 	lea    -0x4(,%eax,4),%ecx
f0101a16:	8d 04 0e             	lea    (%esi,%ecx,1),%eax
f0101a19:	d9 00                	flds   (%eax)
f0101a1b:	d8 4c 0e 04          	fmuls  0x4(%esi,%ecx,1)
f0101a1f:	d9 18                	fstps  (%eax)
f0101a21:	e9 90 00 00 00       	jmp    f0101ab6 <calc+0xca>

		}
		else if (op[i].operant == '/')
f0101a26:	3c 2f                	cmp    $0x2f,%al
f0101a28:	75 42                	jne    f0101a6c <calc+0x80>
		{
			if (numbers[op[i].position == 0])
f0101a2a:	8b 0b                	mov    (%ebx),%ecx
f0101a2c:	83 f9 01             	cmp    $0x1,%ecx
f0101a2f:	19 c0                	sbb    %eax,%eax
f0101a31:	83 e0 04             	and    $0x4,%eax
f0101a34:	d9 04 06             	flds   (%esi,%eax,1)
f0101a37:	d9 ee                	fldz   
f0101a39:	d9 c9                	fxch   %st(1)
f0101a3b:	df e9                	fucomip %st(1),%st
f0101a3d:	dd d8                	fstp   %st(0)
f0101a3f:	7a 02                	jp     f0101a43 <calc+0x57>
f0101a41:	74 15                	je     f0101a58 <calc+0x6c>
			{
				cprintf("error");
f0101a43:	83 ec 0c             	sub    $0xc,%esp
f0101a46:	68 c5 26 10 f0       	push   $0xf01026c5
f0101a4b:	e8 99 ef ff ff       	call   f01009e9 <cprintf>
				return;
f0101a50:	83 c4 10             	add    $0x10,%esp
f0101a53:	e9 a0 00 00 00       	jmp    f0101af8 <calc+0x10c>
			}
			numbers[op[i].position - 1] = numbers[op[i].position - 1] / numbers[op[i].position];
f0101a58:	8d 0c 8d fc ff ff ff 	lea    -0x4(,%ecx,4),%ecx
f0101a5f:	8d 04 0e             	lea    (%esi,%ecx,1),%eax
f0101a62:	d9 00                	flds   (%eax)
f0101a64:	d8 74 0e 04          	fdivs  0x4(%esi,%ecx,1)
f0101a68:	d9 18                	fstps  (%eax)
f0101a6a:	eb 4a                	jmp    f0101ab6 <calc+0xca>
		}
		else if (op[i].operant == '%')
f0101a6c:	3c 25                	cmp    $0x25,%al
f0101a6e:	74 09                	je     f0101a79 <calc+0x8d>
		{
			if (numbers[op[i].position == 0])
f0101a70:	d9 ee                	fldz   
f0101a72:	b8 00 00 00 00       	mov    $0x0,%eax
f0101a77:	eb 61                	jmp    f0101ada <calc+0xee>
f0101a79:	8b 0b                	mov    (%ebx),%ecx
f0101a7b:	83 f9 01             	cmp    $0x1,%ecx
f0101a7e:	19 c0                	sbb    %eax,%eax
f0101a80:	83 e0 04             	and    $0x4,%eax
f0101a83:	d9 04 06             	flds   (%esi,%eax,1)
f0101a86:	d9 ee                	fldz   
f0101a88:	d9 c9                	fxch   %st(1)
f0101a8a:	df e9                	fucomip %st(1),%st
f0101a8c:	dd d8                	fstp   %st(0)
f0101a8e:	7a 02                	jp     f0101a92 <calc+0xa6>
f0101a90:	74 12                	je     f0101aa4 <calc+0xb8>
			{
				cprintf("error");
f0101a92:	83 ec 0c             	sub    $0xc,%esp
f0101a95:	68 c5 26 10 f0       	push   $0xf01026c5
f0101a9a:	e8 4a ef ff ff       	call   f01009e9 <cprintf>
				return;
f0101a9f:	83 c4 10             	add    $0x10,%esp
f0101aa2:	eb 54                	jmp    f0101af8 <calc+0x10c>
			}
		int y = (int)(numbers[op[i].position - 1] / numbers[op[i].position]);
		numbers[op[i].position - 1] = numbers[op[i].position - 1] / numbers[op[i].position];
f0101aa4:	8d 0c 8d fc ff ff ff 	lea    -0x4(,%ecx,4),%ecx
f0101aab:	8d 04 0e             	lea    (%esi,%ecx,1),%eax
f0101aae:	d9 00                	flds   (%eax)
f0101ab0:	d8 74 0e 04          	fdivs  0x4(%esi,%ecx,1)
f0101ab4:	d9 18                	fstps  (%eax)
		}
		else{ break; }
		removeItem(numbers, op[i].position);
f0101ab6:	83 ec 08             	sub    $0x8,%esp
f0101ab9:	ff 32                	pushl  (%edx)
f0101abb:	56                   	push   %esi
f0101abc:	e8 9d fd ff ff       	call   f010185e <removeItem>
		subtract_List_Operation(op);
f0101ac1:	89 3c 24             	mov    %edi,(%esp)
f0101ac4:	e8 33 fd ff ff       	call   f01017fc <subtract_List_Operation>
f0101ac9:	83 c3 08             	add    $0x8,%ebx

void calc(float numbers[], operantion op[])
{
	int i;

	for (i = 0; i < 6; i++)
f0101acc:	83 c4 10             	add    $0x10,%esp
f0101acf:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f0101ad2:	0f 85 2b ff ff ff    	jne    f0101a03 <calc+0x17>
f0101ad8:	eb 96                	jmp    f0101a70 <calc+0x84>
	}
	float result;
	result = 0;
	for (i = 0; i < sizeof(numbers); i++)
	{
		result = result + numbers[i];
f0101ada:	d8 04 86             	fadds  (%esi,%eax,4)
		removeItem(numbers, op[i].position);
		subtract_List_Operation(op);
	}
	float result;
	result = 0;
	for (i = 0; i < sizeof(numbers); i++)
f0101add:	83 c0 01             	add    $0x1,%eax
f0101ae0:	83 f8 04             	cmp    $0x4,%eax
f0101ae3:	75 f5                	jne    f0101ada <calc+0xee>
	{
		result = result + numbers[i];
	}
	cprintf("%f", result);
f0101ae5:	83 ec 0c             	sub    $0xc,%esp
f0101ae8:	dd 1c 24             	fstpl  (%esp)
f0101aeb:	68 5f 24 10 f0       	push   $0xf010245f
f0101af0:	e8 f4 ee ff ff       	call   f01009e9 <cprintf>
f0101af5:	83 c4 10             	add    $0x10,%esp

}
f0101af8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101afb:	5b                   	pop    %ebx
f0101afc:	5e                   	pop    %esi
f0101afd:	5f                   	pop    %edi
f0101afe:	5d                   	pop    %ebp
f0101aff:	c3                   	ret    

f0101b00 <calculator>:

int calculator()
{
f0101b00:	55                   	push   %ebp
f0101b01:	89 e5                	mov    %esp,%ebp
f0101b03:	57                   	push   %edi
f0101b04:	56                   	push   %esi
f0101b05:	53                   	push   %ebx
f0101b06:	81 ec cc 00 00 00    	sub    $0xcc,%esp

	operantion oper;
	oper.operant = '0';
	oper.position = 0;

	for (i = 0; i < 6; i++)
f0101b0c:	b8 00 00 00 00       	mov    $0x0,%eax
	{
		numericop[i].operant ='0';
f0101b11:	c6 44 c5 a0 30       	movb   $0x30,-0x60(%ebp,%eax,8)
		numericop[i].position = 0 ;
f0101b16:	c7 44 c5 9c 00 00 00 	movl   $0x0,-0x64(%ebp,%eax,8)
f0101b1d:	00 

	operantion oper;
	oper.operant = '0';
	oper.position = 0;

	for (i = 0; i < 6; i++)
f0101b1e:	83 c0 01             	add    $0x1,%eax
f0101b21:	83 f8 05             	cmp    $0x5,%eax
f0101b24:	7e eb                	jle    f0101b11 <calculator+0x11>
f0101b26:	89 45 cc             	mov    %eax,-0x34(%ebp)
	{
		numericop[i].operant ='0';
		numericop[i].position = 0 ;
	}
	cprintf("Expression:");
f0101b29:	83 ec 0c             	sub    $0xc,%esp
f0101b2c:	68 d4 28 10 f0       	push   $0xf01028d4
f0101b31:	e8 b3 ee ff ff       	call   f01009e9 <cprintf>
	char *op  = readline("");
f0101b36:	c7 04 24 8f 21 10 f0 	movl   $0xf010218f,(%esp)
f0101b3d:	e8 5b f8 ff ff       	call   f010139d <readline>
f0101b42:	89 c3                	mov    %eax,%ebx
	char number[100];
	number[strlen(op)] = '\0';
f0101b44:	89 04 24             	mov    %eax,(%esp)
f0101b47:	e8 2a f9 ff ff       	call   f0101476 <strlen>
f0101b4c:	c6 84 05 38 ff ff ff 	movb   $0x0,-0xc8(%ebp,%eax,1)
f0101b53:	00 
	clearnumber(number);
f0101b54:	8d 85 38 ff ff ff    	lea    -0xc8(%ebp),%eax
f0101b5a:	89 04 24             	mov    %eax,(%esp)
f0101b5d:	e8 1f fd ff ff       	call   f0101881 <clearnumber>
	i = 0;
f0101b62:	c7 45 cc 00 00 00 00 	movl   $0x0,-0x34(%ebp)
	if (!(op[0] != '-' || Isnumber(op[0])))
f0101b69:	83 c4 10             	add    $0x10,%esp
f0101b6c:	80 3b 2d             	cmpb   $0x2d,(%ebx)
f0101b6f:	75 1a                	jne    f0101b8b <calculator+0x8b>
	{
		cprintf("error");
f0101b71:	83 ec 0c             	sub    $0xc,%esp
f0101b74:	68 c5 26 10 f0       	push   $0xf01026c5
f0101b79:	e8 6b ee ff ff       	call   f01009e9 <cprintf>
		return -1;
f0101b7e:	83 c4 10             	add    $0x10,%esp
f0101b81:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101b86:	e9 39 01 00 00       	jmp    f0101cc4 <calculator+0x1c4>
	}
	if (!(Isnumber(op[strlen(op) - 1]) || Isdot(op[strlen(op) - 1])))
f0101b8b:	83 ec 0c             	sub    $0xc,%esp
f0101b8e:	53                   	push   %ebx
f0101b8f:	e8 e2 f8 ff ff       	call   f0101476 <strlen>
}


int Isnumber(char r)
{
	if (r >= '0' && r <= '9')
f0101b94:	0f b6 44 03 ff       	movzbl -0x1(%ebx,%eax,1),%eax
f0101b99:	83 e8 30             	sub    $0x30,%eax
	if (!(op[0] != '-' || Isnumber(op[0])))
	{
		cprintf("error");
		return -1;
	}
	if (!(Isnumber(op[strlen(op) - 1]) || Isdot(op[strlen(op) - 1])))
f0101b9c:	83 c4 10             	add    $0x10,%esp
f0101b9f:	3c 09                	cmp    $0x9,%al
f0101ba1:	77 1a                	ja     f0101bbd <calculator+0xbd>

	operantion oper;
	oper.operant = '0';
	oper.position = 0;

	for (i = 0; i < 6; i++)
f0101ba3:	c7 85 2c ff ff ff 00 	movl   $0x0,-0xd4(%ebp)
f0101baa:	00 00 00 
f0101bad:	be 01 00 00 00       	mov    $0x1,%esi
		return -1;
	}

	while (i < strlen(op))
	{
		Float answer_num = Getnumber(op, &i);
f0101bb2:	8d bd 30 ff ff ff    	lea    -0xd0(%ebp),%edi
f0101bb8:	e9 da 00 00 00       	jmp    f0101c97 <calculator+0x197>
	if (!(op[0] != '-' || Isnumber(op[0])))
	{
		cprintf("error");
		return -1;
	}
	if (!(Isnumber(op[strlen(op) - 1]) || Isdot(op[strlen(op) - 1])))
f0101bbd:	83 ec 0c             	sub    $0xc,%esp
f0101bc0:	53                   	push   %ebx
f0101bc1:	e8 b0 f8 ff ff       	call   f0101476 <strlen>
f0101bc6:	83 c4 10             	add    $0x10,%esp
f0101bc9:	80 7c 03 ff 2e       	cmpb   $0x2e,-0x1(%ebx,%eax,1)
f0101bce:	74 d3                	je     f0101ba3 <calculator+0xa3>
	{
		cprintf("error");
f0101bd0:	83 ec 0c             	sub    $0xc,%esp
f0101bd3:	68 c5 26 10 f0       	push   $0xf01026c5
f0101bd8:	e8 0c ee ff ff       	call   f01009e9 <cprintf>
		return -1;
f0101bdd:	83 c4 10             	add    $0x10,%esp
f0101be0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101be5:	e9 da 00 00 00       	jmp    f0101cc4 <calculator+0x1c4>
	}

	while (i < strlen(op))
	{
		Float answer_num = Getnumber(op, &i);
f0101bea:	83 ec 04             	sub    $0x4,%esp
f0101bed:	8d 45 cc             	lea    -0x34(%ebp),%eax
f0101bf0:	50                   	push   %eax
f0101bf1:	53                   	push   %ebx
f0101bf2:	57                   	push   %edi
f0101bf3:	e8 c6 fc ff ff       	call   f01018be <Getnumber>
f0101bf8:	8b 85 30 ff ff ff    	mov    -0xd0(%ebp),%eax
		if (answer_num.error)
f0101bfe:	83 c4 0c             	add    $0xc,%esp
f0101c01:	83 bd 34 ff ff ff 00 	cmpl   $0x0,-0xcc(%ebp)
f0101c08:	74 12                	je     f0101c1c <calculator+0x11c>
		{
			cprintf("error");
f0101c0a:	83 ec 0c             	sub    $0xc,%esp
f0101c0d:	68 c5 26 10 f0       	push   $0xf01026c5
f0101c12:	e8 d2 ed ff ff       	call   f01009e9 <cprintf>
			return -1;
f0101c17:	83 c4 10             	add    $0x10,%esp
f0101c1a:	eb 74                	jmp    f0101c90 <calculator+0x190>
		}
		else
		{
			A[numposition] = answer_num.number;
f0101c1c:	89 44 b5 cc          	mov    %eax,-0x34(%ebp,%esi,4)
			numposition++;
		}
		if (i == strlen(op))
f0101c20:	83 ec 0c             	sub    $0xc,%esp
f0101c23:	53                   	push   %ebx
f0101c24:	e8 4d f8 ff ff       	call   f0101476 <strlen>
f0101c29:	8b 55 cc             	mov    -0x34(%ebp),%edx
f0101c2c:	83 c4 10             	add    $0x10,%esp
f0101c2f:	39 d0                	cmp    %edx,%eax
f0101c31:	74 79                	je     f0101cac <calculator+0x1ac>
		{
			break;
		}
		Char answer_char = GetOperation(op, i);
f0101c33:	83 ec 04             	sub    $0x4,%esp
f0101c36:	52                   	push   %edx
f0101c37:	53                   	push   %ebx
f0101c38:	57                   	push   %edi
f0101c39:	e8 66 fd ff ff       	call   f01019a4 <GetOperation>
f0101c3e:	8b 85 30 ff ff ff    	mov    -0xd0(%ebp),%eax
		if (answer_char.error)
f0101c44:	83 c4 0c             	add    $0xc,%esp
f0101c47:	83 bd 34 ff ff ff 00 	cmpl   $0x0,-0xcc(%ebp)
f0101c4e:	74 12                	je     f0101c62 <calculator+0x162>
		{
			cprintf("error");
f0101c50:	83 ec 0c             	sub    $0xc,%esp
f0101c53:	68 c5 26 10 f0       	push   $0xf01026c5
f0101c58:	e8 8c ed ff ff       	call   f01009e9 <cprintf>
			return -1;
f0101c5d:	83 c4 10             	add    $0x10,%esp
f0101c60:	eb 2e                	jmp    f0101c90 <calculator+0x190>
		}
		else
		{
			if (answer_char.value == '+')
f0101c62:	3c 2b                	cmp    $0x2b,%al
f0101c64:	75 06                	jne    f0101c6c <calculator+0x16c>
			{
				i++;
f0101c66:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
f0101c6a:	eb 1f                	jmp    f0101c8b <calculator+0x18b>
			}
			else if (!(answer_char.value == '-'))
f0101c6c:	3c 2d                	cmp    $0x2d,%al
f0101c6e:	74 1b                	je     f0101c8b <calculator+0x18b>
			{
				numericop[operantnum].operant = answer_char.value;
f0101c70:	8b 8d 2c ff ff ff    	mov    -0xd4(%ebp),%ecx
f0101c76:	88 44 cd a0          	mov    %al,-0x60(%ebp,%ecx,8)
				numericop[operantnum].position = Operation_Position;
f0101c7a:	89 74 cd 9c          	mov    %esi,-0x64(%ebp,%ecx,8)
				operantnum++;
f0101c7e:	83 c1 01             	add    $0x1,%ecx
f0101c81:	89 8d 2c ff ff ff    	mov    %ecx,-0xd4(%ebp)
				i++;
f0101c87:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)

			}
			Operation_Position++;
f0101c8b:	83 c6 01             	add    $0x1,%esi
f0101c8e:	eb 07                	jmp    f0101c97 <calculator+0x197>
	{
		Float answer_num = Getnumber(op, &i);
		if (answer_num.error)
		{
			cprintf("error");
			return -1;
f0101c90:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101c95:	eb 2d                	jmp    f0101cc4 <calculator+0x1c4>
	{
		cprintf("error");
		return -1;
	}

	while (i < strlen(op))
f0101c97:	83 ec 0c             	sub    $0xc,%esp
f0101c9a:	53                   	push   %ebx
f0101c9b:	e8 d6 f7 ff ff       	call   f0101476 <strlen>
f0101ca0:	83 c4 10             	add    $0x10,%esp
f0101ca3:	3b 45 cc             	cmp    -0x34(%ebp),%eax
f0101ca6:	0f 8f 3e ff ff ff    	jg     f0101bea <calculator+0xea>
			Operation_Position++;
		}

	}

	calc(A, numericop);
f0101cac:	83 ec 08             	sub    $0x8,%esp
f0101caf:	8d 45 9c             	lea    -0x64(%ebp),%eax
f0101cb2:	50                   	push   %eax
f0101cb3:	8d 45 d0             	lea    -0x30(%ebp),%eax
f0101cb6:	50                   	push   %eax
f0101cb7:	e8 30 fd ff ff       	call   f01019ec <calc>
	return 0;
f0101cbc:	83 c4 10             	add    $0x10,%esp
f0101cbf:	b8 00 00 00 00       	mov    $0x0,%eax

}
f0101cc4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101cc7:	5b                   	pop    %ebx
f0101cc8:	5e                   	pop    %esi
f0101cc9:	5f                   	pop    %edi
f0101cca:	5d                   	pop    %ebp
f0101ccb:	c3                   	ret    

f0101ccc <powerbase>:
#include <kern/kdebug.h>



int powerbase(char base, char power)
{
f0101ccc:	55                   	push   %ebp
f0101ccd:	89 e5                	mov    %esp,%ebp
f0101ccf:	53                   	push   %ebx
f0101cd0:	83 ec 04             	sub    $0x4,%esp
f0101cd3:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101cd6:	8b 55 0c             	mov    0xc(%ebp),%edx
	if(power!=1)
		return (base*powerbase(base,power-1));
	return base;
f0101cd9:	0f be c3             	movsbl %bl,%eax



int powerbase(char base, char power)
{
	if(power!=1)
f0101cdc:	80 fa 01             	cmp    $0x1,%dl
f0101cdf:	74 18                	je     f0101cf9 <powerbase+0x2d>
		return (base*powerbase(base,power-1));
f0101ce1:	89 c3                	mov    %eax,%ebx
f0101ce3:	83 ec 08             	sub    $0x8,%esp
f0101ce6:	83 ea 01             	sub    $0x1,%edx
f0101ce9:	0f be d2             	movsbl %dl,%edx
f0101cec:	52                   	push   %edx
f0101ced:	50                   	push   %eax
f0101cee:	e8 d9 ff ff ff       	call   f0101ccc <powerbase>
f0101cf3:	83 c4 10             	add    $0x10,%esp
f0101cf6:	0f af c3             	imul   %ebx,%eax
	return base;
}
f0101cf9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101cfc:	c9                   	leave  
f0101cfd:	c3                   	ret    

f0101cfe <char_to_float>:

Float char_to_float(char* arg)
{
f0101cfe:	55                   	push   %ebp
f0101cff:	89 e5                	mov    %esp,%ebp
f0101d01:	57                   	push   %edi
f0101d02:	56                   	push   %esi
f0101d03:	53                   	push   %ebx
f0101d04:	83 ec 38             	sub    $0x38,%esp
f0101d07:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	int len=strlen(arg);
f0101d0a:	53                   	push   %ebx
f0101d0b:	e8 66 f7 ff ff       	call   f0101476 <strlen>
f0101d10:	89 c7                	mov    %eax,%edi
	double a = 0;

	Float retval;
	retval.error=0;

	while (i<len)
f0101d12:	83 c4 10             	add    $0x10,%esp
	short neg = 0;
	int i=0;
	double a = 0;

	Float retval;
	retval.error=0;
f0101d15:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
Float char_to_float(char* arg)
{
	int len=strlen(arg);
	short neg = 0;
	int i=0;
	double a = 0;
f0101d1c:	d9 ee                	fldz   
f0101d1e:	dd 5d d8             	fstpl  -0x28(%ebp)

Float char_to_float(char* arg)
{
	int len=strlen(arg);
	short neg = 0;
	int i=0;
f0101d21:	be 00 00 00 00       	mov    $0x0,%esi
f0101d26:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101d29:	89 f3                	mov    %esi,%ebx
f0101d2b:	8b 75 0c             	mov    0xc(%ebp),%esi
	double a = 0;

	Float retval;
	retval.error=0;

	while (i<len)
f0101d2e:	e9 a9 00 00 00       	jmp    f0101ddc <char_to_float+0xde>
	{
		if (*(arg) == '.')
f0101d33:	0f b6 06             	movzbl (%esi),%eax
f0101d36:	3c 2e                	cmp    $0x2e,%al
f0101d38:	75 3f                	jne    f0101d79 <char_to_float+0x7b>
		{
//			after the point
			a = a + (*(arg+1) - '0') * 0.1;
f0101d3a:	0f be 46 01          	movsbl 0x1(%esi),%eax
f0101d3e:	83 e8 30             	sub    $0x30,%eax
f0101d41:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101d44:	db 45 e0             	fildl  -0x20(%ebp)
f0101d47:	dc 0d 68 26 10 f0    	fmull  0xf0102668
f0101d4d:	dc 45 d8             	faddl  -0x28(%ebp)
			cprintf("entered val %f",a);
f0101d50:	83 ec 0c             	sub    $0xc,%esp
f0101d53:	dd 55 d8             	fstl   -0x28(%ebp)
f0101d56:	dd 1c 24             	fstpl  (%esp)
f0101d59:	68 53 24 10 f0       	push   $0xf0102453
f0101d5e:	e8 86 ec ff ff       	call   f01009e9 <cprintf>
			retval.number=a;
f0101d63:	8b 45 08             	mov    0x8(%ebp),%eax
f0101d66:	dd 45 d8             	fldl   -0x28(%ebp)
f0101d69:	d9 18                	fstps  (%eax)
			return retval;
f0101d6b:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101d6e:	89 78 04             	mov    %edi,0x4(%eax)
f0101d71:	83 c4 10             	add    $0x10,%esp
f0101d74:	e9 8f 00 00 00       	jmp    f0101e08 <char_to_float+0x10a>
		}
		if (*(arg)=='-')
f0101d79:	3c 2d                	cmp    $0x2d,%al
f0101d7b:	74 1e                	je     f0101d9b <char_to_float+0x9d>
		{
			neg = 1;
		}
		else if (*(arg) < '0' || (*(arg) > '9'))
f0101d7d:	83 e8 30             	sub    $0x30,%eax
f0101d80:	3c 09                	cmp    $0x9,%al
f0101d82:	76 17                	jbe    f0101d9b <char_to_float+0x9d>
		{
			retval.error = 1;
			cprintf("Invalid Argument");
f0101d84:	83 ec 0c             	sub    $0xc,%esp
f0101d87:	68 62 24 10 f0       	push   $0xf0102462
f0101d8c:	e8 58 ec ff ff       	call   f01009e9 <cprintf>
f0101d91:	83 c4 10             	add    $0x10,%esp
		{
			neg = 1;
		}
		else if (*(arg) < '0' || (*(arg) > '9'))
		{
			retval.error = 1;
f0101d94:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
			cprintf("Invalid Argument");
			//operation or invalid argument
		}
		// BUG: PowerBase has to be fixed
		// BUG: if power equals zero, the point disappears ?!
		a =  powerbase(10,len-i) / 10 * (*(arg) - '0') + a;
f0101d9b:	83 ec 08             	sub    $0x8,%esp
f0101d9e:	89 f8                	mov    %edi,%eax
f0101da0:	29 d8                	sub    %ebx,%eax
f0101da2:	0f be c0             	movsbl %al,%eax
f0101da5:	50                   	push   %eax
f0101da6:	6a 0a                	push   $0xa
f0101da8:	e8 1f ff ff ff       	call   f0101ccc <powerbase>
f0101dad:	83 c4 10             	add    $0x10,%esp
f0101db0:	89 c1                	mov    %eax,%ecx
f0101db2:	b8 67 66 66 66       	mov    $0x66666667,%eax
f0101db7:	f7 e9                	imul   %ecx
f0101db9:	c1 fa 02             	sar    $0x2,%edx
f0101dbc:	c1 f9 1f             	sar    $0x1f,%ecx
f0101dbf:	29 ca                	sub    %ecx,%edx
f0101dc1:	0f be 06             	movsbl (%esi),%eax
f0101dc4:	83 e8 30             	sub    $0x30,%eax
f0101dc7:	0f af d0             	imul   %eax,%edx
f0101dca:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0101dcd:	db 45 e0             	fildl  -0x20(%ebp)
f0101dd0:	dc 45 d8             	faddl  -0x28(%ebp)
f0101dd3:	dd 5d d8             	fstpl  -0x28(%ebp)
		i++;
f0101dd6:	83 c3 01             	add    $0x1,%ebx
		arg=arg+1;
f0101dd9:	83 c6 01             	add    $0x1,%esi
	double a = 0;

	Float retval;
	retval.error=0;

	while (i<len)
f0101ddc:	39 fb                	cmp    %edi,%ebx
f0101dde:	0f 8c 4f ff ff ff    	jl     f0101d33 <char_to_float+0x35>
		a =  powerbase(10,len-i) / 10 * (*(arg) - '0') + a;
		i++;
		arg=arg+1;
	}

	cprintf("entered val %f",a);
f0101de4:	83 ec 04             	sub    $0x4,%esp
f0101de7:	ff 75 dc             	pushl  -0x24(%ebp)
f0101dea:	ff 75 d8             	pushl  -0x28(%ebp)
f0101ded:	68 53 24 10 f0       	push   $0xf0102453
f0101df2:	e8 f2 eb ff ff       	call   f01009e9 <cprintf>
	retval.number=a;
f0101df7:	8b 45 08             	mov    0x8(%ebp),%eax
f0101dfa:	dd 45 d8             	fldl   -0x28(%ebp)
f0101dfd:	d9 18                	fstps  (%eax)
	return retval;
f0101dff:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101e02:	89 78 04             	mov    %edi,0x4(%eax)
f0101e05:	83 c4 10             	add    $0x10,%esp
}
f0101e08:	8b 45 08             	mov    0x8(%ebp),%eax
f0101e0b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101e0e:	5b                   	pop    %ebx
f0101e0f:	5e                   	pop    %esi
f0101e10:	5f                   	pop    %edi
f0101e11:	5d                   	pop    %ebp
f0101e12:	c2 04 00             	ret    $0x4
f0101e15:	66 90                	xchg   %ax,%ax
f0101e17:	66 90                	xchg   %ax,%ax
f0101e19:	66 90                	xchg   %ax,%ax
f0101e1b:	66 90                	xchg   %ax,%ax
f0101e1d:	66 90                	xchg   %ax,%ax
f0101e1f:	90                   	nop

f0101e20 <__udivdi3>:
f0101e20:	55                   	push   %ebp
f0101e21:	57                   	push   %edi
f0101e22:	56                   	push   %esi
f0101e23:	83 ec 10             	sub    $0x10,%esp
f0101e26:	8b 54 24 2c          	mov    0x2c(%esp),%edx
f0101e2a:	8b 7c 24 20          	mov    0x20(%esp),%edi
f0101e2e:	8b 74 24 24          	mov    0x24(%esp),%esi
f0101e32:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0101e36:	85 d2                	test   %edx,%edx
f0101e38:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101e3c:	89 34 24             	mov    %esi,(%esp)
f0101e3f:	89 c8                	mov    %ecx,%eax
f0101e41:	75 35                	jne    f0101e78 <__udivdi3+0x58>
f0101e43:	39 f1                	cmp    %esi,%ecx
f0101e45:	0f 87 bd 00 00 00    	ja     f0101f08 <__udivdi3+0xe8>
f0101e4b:	85 c9                	test   %ecx,%ecx
f0101e4d:	89 cd                	mov    %ecx,%ebp
f0101e4f:	75 0b                	jne    f0101e5c <__udivdi3+0x3c>
f0101e51:	b8 01 00 00 00       	mov    $0x1,%eax
f0101e56:	31 d2                	xor    %edx,%edx
f0101e58:	f7 f1                	div    %ecx
f0101e5a:	89 c5                	mov    %eax,%ebp
f0101e5c:	89 f0                	mov    %esi,%eax
f0101e5e:	31 d2                	xor    %edx,%edx
f0101e60:	f7 f5                	div    %ebp
f0101e62:	89 c6                	mov    %eax,%esi
f0101e64:	89 f8                	mov    %edi,%eax
f0101e66:	f7 f5                	div    %ebp
f0101e68:	89 f2                	mov    %esi,%edx
f0101e6a:	83 c4 10             	add    $0x10,%esp
f0101e6d:	5e                   	pop    %esi
f0101e6e:	5f                   	pop    %edi
f0101e6f:	5d                   	pop    %ebp
f0101e70:	c3                   	ret    
f0101e71:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101e78:	3b 14 24             	cmp    (%esp),%edx
f0101e7b:	77 7b                	ja     f0101ef8 <__udivdi3+0xd8>
f0101e7d:	0f bd f2             	bsr    %edx,%esi
f0101e80:	83 f6 1f             	xor    $0x1f,%esi
f0101e83:	0f 84 97 00 00 00    	je     f0101f20 <__udivdi3+0x100>
f0101e89:	bd 20 00 00 00       	mov    $0x20,%ebp
f0101e8e:	89 d7                	mov    %edx,%edi
f0101e90:	89 f1                	mov    %esi,%ecx
f0101e92:	29 f5                	sub    %esi,%ebp
f0101e94:	d3 e7                	shl    %cl,%edi
f0101e96:	89 c2                	mov    %eax,%edx
f0101e98:	89 e9                	mov    %ebp,%ecx
f0101e9a:	d3 ea                	shr    %cl,%edx
f0101e9c:	89 f1                	mov    %esi,%ecx
f0101e9e:	09 fa                	or     %edi,%edx
f0101ea0:	8b 3c 24             	mov    (%esp),%edi
f0101ea3:	d3 e0                	shl    %cl,%eax
f0101ea5:	89 54 24 08          	mov    %edx,0x8(%esp)
f0101ea9:	89 e9                	mov    %ebp,%ecx
f0101eab:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101eaf:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101eb3:	89 fa                	mov    %edi,%edx
f0101eb5:	d3 ea                	shr    %cl,%edx
f0101eb7:	89 f1                	mov    %esi,%ecx
f0101eb9:	d3 e7                	shl    %cl,%edi
f0101ebb:	89 e9                	mov    %ebp,%ecx
f0101ebd:	d3 e8                	shr    %cl,%eax
f0101ebf:	09 c7                	or     %eax,%edi
f0101ec1:	89 f8                	mov    %edi,%eax
f0101ec3:	f7 74 24 08          	divl   0x8(%esp)
f0101ec7:	89 d5                	mov    %edx,%ebp
f0101ec9:	89 c7                	mov    %eax,%edi
f0101ecb:	f7 64 24 0c          	mull   0xc(%esp)
f0101ecf:	39 d5                	cmp    %edx,%ebp
f0101ed1:	89 14 24             	mov    %edx,(%esp)
f0101ed4:	72 11                	jb     f0101ee7 <__udivdi3+0xc7>
f0101ed6:	8b 54 24 04          	mov    0x4(%esp),%edx
f0101eda:	89 f1                	mov    %esi,%ecx
f0101edc:	d3 e2                	shl    %cl,%edx
f0101ede:	39 c2                	cmp    %eax,%edx
f0101ee0:	73 5e                	jae    f0101f40 <__udivdi3+0x120>
f0101ee2:	3b 2c 24             	cmp    (%esp),%ebp
f0101ee5:	75 59                	jne    f0101f40 <__udivdi3+0x120>
f0101ee7:	8d 47 ff             	lea    -0x1(%edi),%eax
f0101eea:	31 f6                	xor    %esi,%esi
f0101eec:	89 f2                	mov    %esi,%edx
f0101eee:	83 c4 10             	add    $0x10,%esp
f0101ef1:	5e                   	pop    %esi
f0101ef2:	5f                   	pop    %edi
f0101ef3:	5d                   	pop    %ebp
f0101ef4:	c3                   	ret    
f0101ef5:	8d 76 00             	lea    0x0(%esi),%esi
f0101ef8:	31 f6                	xor    %esi,%esi
f0101efa:	31 c0                	xor    %eax,%eax
f0101efc:	89 f2                	mov    %esi,%edx
f0101efe:	83 c4 10             	add    $0x10,%esp
f0101f01:	5e                   	pop    %esi
f0101f02:	5f                   	pop    %edi
f0101f03:	5d                   	pop    %ebp
f0101f04:	c3                   	ret    
f0101f05:	8d 76 00             	lea    0x0(%esi),%esi
f0101f08:	89 f2                	mov    %esi,%edx
f0101f0a:	31 f6                	xor    %esi,%esi
f0101f0c:	89 f8                	mov    %edi,%eax
f0101f0e:	f7 f1                	div    %ecx
f0101f10:	89 f2                	mov    %esi,%edx
f0101f12:	83 c4 10             	add    $0x10,%esp
f0101f15:	5e                   	pop    %esi
f0101f16:	5f                   	pop    %edi
f0101f17:	5d                   	pop    %ebp
f0101f18:	c3                   	ret    
f0101f19:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101f20:	3b 4c 24 04          	cmp    0x4(%esp),%ecx
f0101f24:	76 0b                	jbe    f0101f31 <__udivdi3+0x111>
f0101f26:	31 c0                	xor    %eax,%eax
f0101f28:	3b 14 24             	cmp    (%esp),%edx
f0101f2b:	0f 83 37 ff ff ff    	jae    f0101e68 <__udivdi3+0x48>
f0101f31:	b8 01 00 00 00       	mov    $0x1,%eax
f0101f36:	e9 2d ff ff ff       	jmp    f0101e68 <__udivdi3+0x48>
f0101f3b:	90                   	nop
f0101f3c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101f40:	89 f8                	mov    %edi,%eax
f0101f42:	31 f6                	xor    %esi,%esi
f0101f44:	e9 1f ff ff ff       	jmp    f0101e68 <__udivdi3+0x48>
f0101f49:	66 90                	xchg   %ax,%ax
f0101f4b:	66 90                	xchg   %ax,%ax
f0101f4d:	66 90                	xchg   %ax,%ax
f0101f4f:	90                   	nop

f0101f50 <__umoddi3>:
f0101f50:	55                   	push   %ebp
f0101f51:	57                   	push   %edi
f0101f52:	56                   	push   %esi
f0101f53:	83 ec 20             	sub    $0x20,%esp
f0101f56:	8b 44 24 34          	mov    0x34(%esp),%eax
f0101f5a:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f0101f5e:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101f62:	89 c6                	mov    %eax,%esi
f0101f64:	89 44 24 10          	mov    %eax,0x10(%esp)
f0101f68:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f0101f6c:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
f0101f70:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101f74:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f0101f78:	89 74 24 18          	mov    %esi,0x18(%esp)
f0101f7c:	85 c0                	test   %eax,%eax
f0101f7e:	89 c2                	mov    %eax,%edx
f0101f80:	75 1e                	jne    f0101fa0 <__umoddi3+0x50>
f0101f82:	39 f7                	cmp    %esi,%edi
f0101f84:	76 52                	jbe    f0101fd8 <__umoddi3+0x88>
f0101f86:	89 c8                	mov    %ecx,%eax
f0101f88:	89 f2                	mov    %esi,%edx
f0101f8a:	f7 f7                	div    %edi
f0101f8c:	89 d0                	mov    %edx,%eax
f0101f8e:	31 d2                	xor    %edx,%edx
f0101f90:	83 c4 20             	add    $0x20,%esp
f0101f93:	5e                   	pop    %esi
f0101f94:	5f                   	pop    %edi
f0101f95:	5d                   	pop    %ebp
f0101f96:	c3                   	ret    
f0101f97:	89 f6                	mov    %esi,%esi
f0101f99:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0101fa0:	39 f0                	cmp    %esi,%eax
f0101fa2:	77 5c                	ja     f0102000 <__umoddi3+0xb0>
f0101fa4:	0f bd e8             	bsr    %eax,%ebp
f0101fa7:	83 f5 1f             	xor    $0x1f,%ebp
f0101faa:	75 64                	jne    f0102010 <__umoddi3+0xc0>
f0101fac:	8b 6c 24 14          	mov    0x14(%esp),%ebp
f0101fb0:	39 6c 24 0c          	cmp    %ebp,0xc(%esp)
f0101fb4:	0f 86 f6 00 00 00    	jbe    f01020b0 <__umoddi3+0x160>
f0101fba:	3b 44 24 18          	cmp    0x18(%esp),%eax
f0101fbe:	0f 82 ec 00 00 00    	jb     f01020b0 <__umoddi3+0x160>
f0101fc4:	8b 44 24 14          	mov    0x14(%esp),%eax
f0101fc8:	8b 54 24 18          	mov    0x18(%esp),%edx
f0101fcc:	83 c4 20             	add    $0x20,%esp
f0101fcf:	5e                   	pop    %esi
f0101fd0:	5f                   	pop    %edi
f0101fd1:	5d                   	pop    %ebp
f0101fd2:	c3                   	ret    
f0101fd3:	90                   	nop
f0101fd4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101fd8:	85 ff                	test   %edi,%edi
f0101fda:	89 fd                	mov    %edi,%ebp
f0101fdc:	75 0b                	jne    f0101fe9 <__umoddi3+0x99>
f0101fde:	b8 01 00 00 00       	mov    $0x1,%eax
f0101fe3:	31 d2                	xor    %edx,%edx
f0101fe5:	f7 f7                	div    %edi
f0101fe7:	89 c5                	mov    %eax,%ebp
f0101fe9:	8b 44 24 10          	mov    0x10(%esp),%eax
f0101fed:	31 d2                	xor    %edx,%edx
f0101fef:	f7 f5                	div    %ebp
f0101ff1:	89 c8                	mov    %ecx,%eax
f0101ff3:	f7 f5                	div    %ebp
f0101ff5:	eb 95                	jmp    f0101f8c <__umoddi3+0x3c>
f0101ff7:	89 f6                	mov    %esi,%esi
f0101ff9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0102000:	89 c8                	mov    %ecx,%eax
f0102002:	89 f2                	mov    %esi,%edx
f0102004:	83 c4 20             	add    $0x20,%esp
f0102007:	5e                   	pop    %esi
f0102008:	5f                   	pop    %edi
f0102009:	5d                   	pop    %ebp
f010200a:	c3                   	ret    
f010200b:	90                   	nop
f010200c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0102010:	b8 20 00 00 00       	mov    $0x20,%eax
f0102015:	89 e9                	mov    %ebp,%ecx
f0102017:	29 e8                	sub    %ebp,%eax
f0102019:	d3 e2                	shl    %cl,%edx
f010201b:	89 c7                	mov    %eax,%edi
f010201d:	89 44 24 18          	mov    %eax,0x18(%esp)
f0102021:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0102025:	89 f9                	mov    %edi,%ecx
f0102027:	d3 e8                	shr    %cl,%eax
f0102029:	89 c1                	mov    %eax,%ecx
f010202b:	8b 44 24 0c          	mov    0xc(%esp),%eax
f010202f:	09 d1                	or     %edx,%ecx
f0102031:	89 fa                	mov    %edi,%edx
f0102033:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0102037:	89 e9                	mov    %ebp,%ecx
f0102039:	d3 e0                	shl    %cl,%eax
f010203b:	89 f9                	mov    %edi,%ecx
f010203d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102041:	89 f0                	mov    %esi,%eax
f0102043:	d3 e8                	shr    %cl,%eax
f0102045:	89 e9                	mov    %ebp,%ecx
f0102047:	89 c7                	mov    %eax,%edi
f0102049:	8b 44 24 1c          	mov    0x1c(%esp),%eax
f010204d:	d3 e6                	shl    %cl,%esi
f010204f:	89 d1                	mov    %edx,%ecx
f0102051:	89 fa                	mov    %edi,%edx
f0102053:	d3 e8                	shr    %cl,%eax
f0102055:	89 e9                	mov    %ebp,%ecx
f0102057:	09 f0                	or     %esi,%eax
f0102059:	8b 74 24 1c          	mov    0x1c(%esp),%esi
f010205d:	f7 74 24 10          	divl   0x10(%esp)
f0102061:	d3 e6                	shl    %cl,%esi
f0102063:	89 d1                	mov    %edx,%ecx
f0102065:	f7 64 24 0c          	mull   0xc(%esp)
f0102069:	39 d1                	cmp    %edx,%ecx
f010206b:	89 74 24 14          	mov    %esi,0x14(%esp)
f010206f:	89 d7                	mov    %edx,%edi
f0102071:	89 c6                	mov    %eax,%esi
f0102073:	72 0a                	jb     f010207f <__umoddi3+0x12f>
f0102075:	39 44 24 14          	cmp    %eax,0x14(%esp)
f0102079:	73 10                	jae    f010208b <__umoddi3+0x13b>
f010207b:	39 d1                	cmp    %edx,%ecx
f010207d:	75 0c                	jne    f010208b <__umoddi3+0x13b>
f010207f:	89 d7                	mov    %edx,%edi
f0102081:	89 c6                	mov    %eax,%esi
f0102083:	2b 74 24 0c          	sub    0xc(%esp),%esi
f0102087:	1b 7c 24 10          	sbb    0x10(%esp),%edi
f010208b:	89 ca                	mov    %ecx,%edx
f010208d:	89 e9                	mov    %ebp,%ecx
f010208f:	8b 44 24 14          	mov    0x14(%esp),%eax
f0102093:	29 f0                	sub    %esi,%eax
f0102095:	19 fa                	sbb    %edi,%edx
f0102097:	d3 e8                	shr    %cl,%eax
f0102099:	0f b6 4c 24 18       	movzbl 0x18(%esp),%ecx
f010209e:	89 d7                	mov    %edx,%edi
f01020a0:	d3 e7                	shl    %cl,%edi
f01020a2:	89 e9                	mov    %ebp,%ecx
f01020a4:	09 f8                	or     %edi,%eax
f01020a6:	d3 ea                	shr    %cl,%edx
f01020a8:	83 c4 20             	add    $0x20,%esp
f01020ab:	5e                   	pop    %esi
f01020ac:	5f                   	pop    %edi
f01020ad:	5d                   	pop    %ebp
f01020ae:	c3                   	ret    
f01020af:	90                   	nop
f01020b0:	8b 74 24 10          	mov    0x10(%esp),%esi
f01020b4:	29 f9                	sub    %edi,%ecx
f01020b6:	19 c6                	sbb    %eax,%esi
f01020b8:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f01020bc:	89 74 24 18          	mov    %esi,0x18(%esp)
f01020c0:	e9 ff fe ff ff       	jmp    f0101fc4 <__umoddi3+0x74>
