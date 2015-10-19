
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
f0100015:	b8 00 20 11 00       	mov    $0x112000,%eax
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
f0100034:	bc 00 20 11 f0       	mov    $0xf0112000,%esp

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
f010004b:	68 80 23 10 f0       	push   $0xf0102380
f0100050:	e8 fe 09 00 00       	call   f0100a53 <cprintf>
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
f0100076:	e8 60 08 00 00       	call   f01008db <mon_backtrace>
f010007b:	83 c4 10             	add    $0x10,%esp
	cprintf("leaving test_backtrace %d\n", x);
f010007e:	83 ec 08             	sub    $0x8,%esp
f0100081:	53                   	push   %ebx
f0100082:	68 9c 23 10 f0       	push   $0xf010239c
f0100087:	e8 c7 09 00 00       	call   f0100a53 <cprintf>
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
f010009a:	b8 84 49 11 f0       	mov    $0xf0114984,%eax
f010009f:	2d 00 43 11 f0       	sub    $0xf0114300,%eax
f01000a4:	50                   	push   %eax
f01000a5:	6a 00                	push   $0x0
f01000a7:	68 00 43 11 f0       	push   $0xf0114300
f01000ac:	e8 ad 15 00 00       	call   f010165e <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b1:	e8 8c 04 00 00       	call   f0100542 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000b6:	83 c4 08             	add    $0x8,%esp
f01000b9:	68 ac 1a 00 00       	push   $0x1aac
f01000be:	68 b7 23 10 f0       	push   $0xf01023b7
f01000c3:	e8 8b 09 00 00       	call   f0100a53 <cprintf>

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
f01000dc:	e8 04 08 00 00       	call   f01008e5 <monitor>
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
f01000ee:	83 3d 80 49 11 f0 00 	cmpl   $0x0,0xf0114980
f01000f5:	75 37                	jne    f010012e <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000f7:	89 35 80 49 11 f0    	mov    %esi,0xf0114980

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
f010010b:	68 d2 23 10 f0       	push   $0xf01023d2
f0100110:	e8 3e 09 00 00       	call   f0100a53 <cprintf>
	vcprintf(fmt, ap);
f0100115:	83 c4 08             	add    $0x8,%esp
f0100118:	53                   	push   %ebx
f0100119:	56                   	push   %esi
f010011a:	e8 0e 09 00 00       	call   f0100a2d <vcprintf>
	cprintf("\n");
f010011f:	c7 04 24 0e 24 10 f0 	movl   $0xf010240e,(%esp)
f0100126:	e8 28 09 00 00       	call   f0100a53 <cprintf>
	va_end(ap);
f010012b:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010012e:	83 ec 0c             	sub    $0xc,%esp
f0100131:	6a 00                	push   $0x0
f0100133:	e8 ad 07 00 00       	call   f01008e5 <monitor>
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
f010014d:	68 ea 23 10 f0       	push   $0xf01023ea
f0100152:	e8 fc 08 00 00       	call   f0100a53 <cprintf>
	vcprintf(fmt, ap);
f0100157:	83 c4 08             	add    $0x8,%esp
f010015a:	53                   	push   %ebx
f010015b:	ff 75 10             	pushl  0x10(%ebp)
f010015e:	e8 ca 08 00 00       	call   f0100a2d <vcprintf>
	cprintf("\n");
f0100163:	c7 04 24 0e 24 10 f0 	movl   $0xf010240e,(%esp)
f010016a:	e8 e4 08 00 00       	call   f0100a53 <cprintf>
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
f01001a2:	a1 44 45 11 f0       	mov    0xf0114544,%eax
f01001a7:	8d 48 01             	lea    0x1(%eax),%ecx
f01001aa:	89 0d 44 45 11 f0    	mov    %ecx,0xf0114544
f01001b0:	88 90 40 43 11 f0    	mov    %dl,-0xfeebcc0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f01001b6:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01001bc:	75 0a                	jne    f01001c8 <cons_intr+0x35>
			cons.wpos = 0;
f01001be:	c7 05 44 45 11 f0 00 	movl   $0x0,0xf0114544
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
f01001ee:	83 0d 00 43 11 f0 40 	orl    $0x40,0xf0114300
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
f0100206:	8b 0d 00 43 11 f0    	mov    0xf0114300,%ecx
f010020c:	89 cb                	mov    %ecx,%ebx
f010020e:	83 e3 40             	and    $0x40,%ebx
f0100211:	83 e0 7f             	and    $0x7f,%eax
f0100214:	85 db                	test   %ebx,%ebx
f0100216:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100219:	0f b6 d2             	movzbl %dl,%edx
f010021c:	0f b6 82 80 25 10 f0 	movzbl -0xfefda80(%edx),%eax
f0100223:	83 c8 40             	or     $0x40,%eax
f0100226:	0f b6 c0             	movzbl %al,%eax
f0100229:	f7 d0                	not    %eax
f010022b:	21 c8                	and    %ecx,%eax
f010022d:	a3 00 43 11 f0       	mov    %eax,0xf0114300
		return 0;
f0100232:	b8 00 00 00 00       	mov    $0x0,%eax
f0100237:	e9 a1 00 00 00       	jmp    f01002dd <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f010023c:	8b 0d 00 43 11 f0    	mov    0xf0114300,%ecx
f0100242:	f6 c1 40             	test   $0x40,%cl
f0100245:	74 0e                	je     f0100255 <kbd_proc_data+0x7e>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100247:	83 c8 80             	or     $0xffffff80,%eax
f010024a:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010024c:	83 e1 bf             	and    $0xffffffbf,%ecx
f010024f:	89 0d 00 43 11 f0    	mov    %ecx,0xf0114300
	}

	shift |= shiftcode[data];
f0100255:	0f b6 c2             	movzbl %dl,%eax
f0100258:	0f b6 90 80 25 10 f0 	movzbl -0xfefda80(%eax),%edx
f010025f:	0b 15 00 43 11 f0    	or     0xf0114300,%edx
	shift ^= togglecode[data];
f0100265:	0f b6 88 80 24 10 f0 	movzbl -0xfefdb80(%eax),%ecx
f010026c:	31 ca                	xor    %ecx,%edx
f010026e:	89 15 00 43 11 f0    	mov    %edx,0xf0114300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100274:	89 d1                	mov    %edx,%ecx
f0100276:	83 e1 03             	and    $0x3,%ecx
f0100279:	8b 0c 8d 40 24 10 f0 	mov    -0xfefdbc0(,%ecx,4),%ecx
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
f01002b9:	68 04 24 10 f0       	push   $0xf0102404
f01002be:	e8 90 07 00 00       	call   f0100a53 <cprintf>
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
f010039e:	0f b7 05 48 45 11 f0 	movzwl 0xf0114548,%eax
f01003a5:	66 85 c0             	test   %ax,%ax
f01003a8:	0f 84 e6 00 00 00    	je     f0100494 <cons_putc+0x1b2>
			crt_pos--;
f01003ae:	83 e8 01             	sub    $0x1,%eax
f01003b1:	66 a3 48 45 11 f0    	mov    %ax,0xf0114548
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003b7:	0f b7 c0             	movzwl %ax,%eax
f01003ba:	66 81 e7 00 ff       	and    $0xff00,%di
f01003bf:	83 cf 20             	or     $0x20,%edi
f01003c2:	8b 15 4c 45 11 f0    	mov    0xf011454c,%edx
f01003c8:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003cc:	eb 78                	jmp    f0100446 <cons_putc+0x164>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003ce:	66 83 05 48 45 11 f0 	addw   $0x50,0xf0114548
f01003d5:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003d6:	0f b7 05 48 45 11 f0 	movzwl 0xf0114548,%eax
f01003dd:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003e3:	c1 e8 16             	shr    $0x16,%eax
f01003e6:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003e9:	c1 e0 04             	shl    $0x4,%eax
f01003ec:	66 a3 48 45 11 f0    	mov    %ax,0xf0114548
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
f0100428:	0f b7 05 48 45 11 f0 	movzwl 0xf0114548,%eax
f010042f:	8d 50 01             	lea    0x1(%eax),%edx
f0100432:	66 89 15 48 45 11 f0 	mov    %dx,0xf0114548
f0100439:	0f b7 c0             	movzwl %ax,%eax
f010043c:	8b 15 4c 45 11 f0    	mov    0xf011454c,%edx
f0100442:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100446:	66 81 3d 48 45 11 f0 	cmpw   $0x7cf,0xf0114548
f010044d:	cf 07 
f010044f:	76 43                	jbe    f0100494 <cons_putc+0x1b2>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100451:	a1 4c 45 11 f0       	mov    0xf011454c,%eax
f0100456:	83 ec 04             	sub    $0x4,%esp
f0100459:	68 00 0f 00 00       	push   $0xf00
f010045e:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100464:	52                   	push   %edx
f0100465:	50                   	push   %eax
f0100466:	e8 40 12 00 00       	call   f01016ab <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010046b:	8b 15 4c 45 11 f0    	mov    0xf011454c,%edx
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
f010048c:	66 83 2d 48 45 11 f0 	subw   $0x50,0xf0114548
f0100493:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100494:	8b 0d 50 45 11 f0    	mov    0xf0114550,%ecx
f010049a:	b8 0e 00 00 00       	mov    $0xe,%eax
f010049f:	89 ca                	mov    %ecx,%edx
f01004a1:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01004a2:	0f b7 1d 48 45 11 f0 	movzwl 0xf0114548,%ebx
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
f01004ca:	80 3d 54 45 11 f0 00 	cmpb   $0x0,0xf0114554
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
f0100508:	a1 40 45 11 f0       	mov    0xf0114540,%eax
f010050d:	3b 05 44 45 11 f0    	cmp    0xf0114544,%eax
f0100513:	74 26                	je     f010053b <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100515:	8d 50 01             	lea    0x1(%eax),%edx
f0100518:	89 15 40 45 11 f0    	mov    %edx,0xf0114540
f010051e:	0f b6 88 40 43 11 f0 	movzbl -0xfeebcc0(%eax),%ecx
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
f010052f:	c7 05 40 45 11 f0 00 	movl   $0x0,0xf0114540
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
f0100568:	c7 05 50 45 11 f0 b4 	movl   $0x3b4,0xf0114550
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
f0100580:	c7 05 50 45 11 f0 d4 	movl   $0x3d4,0xf0114550
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
f010058f:	8b 3d 50 45 11 f0    	mov    0xf0114550,%edi
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
f01005b6:	89 35 4c 45 11 f0    	mov    %esi,0xf011454c

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
f01005c3:	66 a3 48 45 11 f0    	mov    %ax,0xf0114548
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
f0100613:	88 0d 54 45 11 f0    	mov    %cl,0xf0114554
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
f0100626:	68 10 24 10 f0       	push   $0xf0102410
f010062b:	e8 23 04 00 00       	call   f0100a53 <cprintf>
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
f010066c:	e8 cb 16 00 00       	call   f0101d3c <calculator>
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
f010067e:	68 80 26 10 f0       	push   $0xf0102680
f0100683:	68 9e 26 10 f0       	push   $0xf010269e
f0100688:	68 a3 26 10 f0       	push   $0xf01026a3
f010068d:	e8 c1 03 00 00       	call   f0100a53 <cprintf>
f0100692:	83 c4 0c             	add    $0xc,%esp
f0100695:	68 24 27 10 f0       	push   $0xf0102724
f010069a:	68 aa 2b 10 f0       	push   $0xf0102baa
f010069f:	68 a3 26 10 f0       	push   $0xf01026a3
f01006a4:	e8 aa 03 00 00       	call   f0100a53 <cprintf>
f01006a9:	83 c4 0c             	add    $0xc,%esp
f01006ac:	68 4c 27 10 f0       	push   $0xf010274c
f01006b1:	68 b9 26 10 f0       	push   $0xf01026b9
f01006b6:	68 a3 26 10 f0       	push   $0xf01026a3
f01006bb:	e8 93 03 00 00       	call   f0100a53 <cprintf>
	return 0;
}
f01006c0:	b8 00 00 00 00       	mov    $0x0,%eax
f01006c5:	c9                   	leave  
f01006c6:	c3                   	ret    

f01006c7 <first_lab>:

// First OS Lab

int
first_lab(int argc, char **argv, struct Trapframe *tf)
{
f01006c7:	55                   	push   %ebp
f01006c8:	89 e5                	mov    %esp,%ebp
f01006ca:	57                   	push   %edi
f01006cb:	56                   	push   %esi
f01006cc:	53                   	push   %ebx
f01006cd:	83 ec 38             	sub    $0x38,%esp
//		float* a=(float*)c;
//		float* a=(float*)c;
//		out=(char*)a;
///////////////////////////////////////// */
char *arg=NULL;
	arg=readline("");
f01006d0:	68 0f 24 10 f0       	push   $0xf010240f
f01006d5:	e8 2d 0d 00 00       	call   f0101407 <readline>
f01006da:	89 c3                	mov    %eax,%ebx
	int len=strlen(arg);
f01006dc:	89 04 24             	mov    %eax,(%esp)
f01006df:	e8 fc 0d 00 00       	call   f01014e0 <strlen>
f01006e4:	89 c7                	mov    %eax,%edi
	double a = 0;

	Float retval;
	retval.error=0;

	while (i<len)
f01006e6:	83 c4 10             	add    $0x10,%esp
char *arg=NULL;
	arg=readline("");
	int len=strlen(arg);
	short neg = 0;
	int i=0;
	double a = 0;
f01006e9:	d9 ee                	fldz   
f01006eb:	dd 5d d0             	fstpl  -0x30(%ebp)
///////////////////////////////////////// */
char *arg=NULL;
	arg=readline("");
	int len=strlen(arg);
	short neg = 0;
	int i=0;
f01006ee:	be 00 00 00 00       	mov    $0x0,%esi
	double a = 0;

	Float retval;
	retval.error=0;

	while (i<len)
f01006f3:	e9 eb 00 00 00       	jmp    f01007e3 <first_lab+0x11c>
	{
		if (*(arg) == '.')
f01006f8:	0f b6 03             	movzbl (%ebx),%eax
f01006fb:	3c 2e                	cmp    $0x2e,%al
f01006fd:	0f 85 82 00 00 00    	jne    f0100785 <first_lab+0xbe>
		{
			if (!(arg+1))
f0100703:	83 fb ff             	cmp    $0xffffffff,%ebx
f0100706:	0f 84 fc 00 00 00    	je     f0100808 <first_lab+0x141>
			{
				retval.error=1;
				return 0;
			}
			a = a + (*(arg+1) - '0') * 0.1;
f010070c:	0f b6 53 01          	movzbl 0x1(%ebx),%edx
								a = a + (*(arg+2) - '0') * 0.1;
				}
				else
				{
					retval.error=1; 
					return 0;
f0100710:	b8 00 00 00 00       	mov    $0x0,%eax
			{
				retval.error=1;
				return 0;
			}
			a = a + (*(arg+1) - '0') * 0.1;
				if ((arg+2)!= NULL)
f0100715:	83 fb fe             	cmp    $0xfffffffe,%ebx
f0100718:	0f 84 ef 00 00 00    	je     f010080d <first_lab+0x146>
			if (!(arg+1))
			{
				retval.error=1;
				return 0;
			}
			a = a + (*(arg+1) - '0') * 0.1;
f010071e:	0f be d2             	movsbl %dl,%edx
f0100721:	83 ea 30             	sub    $0x30,%edx
f0100724:	89 55 d8             	mov    %edx,-0x28(%ebp)
f0100727:	db 45 d8             	fildl  -0x28(%ebp)
f010072a:	dd 05 e8 28 10 f0    	fldl   0xf01028e8
f0100730:	dc c9                	fmul   %st,%st(1)
f0100732:	d9 c9                	fxch   %st(1)
f0100734:	dc 45 d0             	faddl  -0x30(%ebp)
				if ((arg+2)!= NULL)
				{
								a = a + (*(arg+2) - '0') * 0.1;
f0100737:	0f be 43 02          	movsbl 0x2(%ebx),%eax
f010073b:	83 e8 30             	sub    $0x30,%eax
f010073e:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100741:	db 45 d0             	fildl  -0x30(%ebp)
f0100744:	de ca                	fmulp  %st,%st(2)
f0100746:	de c1                	faddp  %st,%st(1)
				{
					retval.error=1; 
					return 0;
				}
			retval.number=a;
			cprintf("entered val %f",a);
f0100748:	83 ec 0c             	sub    $0xc,%esp
f010074b:	dd 55 d0             	fstl   -0x30(%ebp)
f010074e:	dd 1c 24             	fstpl  (%esp)
f0100751:	68 ac 26 10 f0       	push   $0xf01026ac
f0100756:	e8 f8 02 00 00       	call   f0100a53 <cprintf>
				else
				{
					retval.error=1; 
					return 0;
				}
			retval.number=a;
f010075b:	dd 45 d0             	fldl   -0x30(%ebp)
f010075e:	d9 5d e4             	fstps  -0x1c(%ebp)
f0100761:	d9 45 e4             	flds   -0x1c(%ebp)
			cprintf("entered val %f",a);
			return retval.number;
f0100764:	d9 7d e2             	fnstcw -0x1e(%ebp)
f0100767:	0f b7 45 e2          	movzwl -0x1e(%ebp),%eax
f010076b:	b4 0c                	mov    $0xc,%ah
f010076d:	66 89 45 e0          	mov    %ax,-0x20(%ebp)
f0100771:	d9 6d e0             	fldcw  -0x20(%ebp)
f0100774:	db 5d dc             	fistpl -0x24(%ebp)
f0100777:	d9 6d e2             	fldcw  -0x1e(%ebp)
f010077a:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010077d:	83 c4 10             	add    $0x10,%esp
f0100780:	e9 88 00 00 00       	jmp    f010080d <first_lab+0x146>
		}
		if (*(arg)=='-')
f0100785:	3c 2d                	cmp    $0x2d,%al
f0100787:	74 17                	je     f01007a0 <first_lab+0xd9>
		{
			neg = 1;
		}
		else if (*(arg) < '0' || (*(arg) > '9'))
f0100789:	83 e8 30             	sub    $0x30,%eax
f010078c:	3c 09                	cmp    $0x9,%al
f010078e:	76 10                	jbe    f01007a0 <first_lab+0xd9>
		{
			retval.error = 1;
			cprintf("Invalid Argument");
f0100790:	83 ec 0c             	sub    $0xc,%esp
f0100793:	68 bb 26 10 f0       	push   $0xf01026bb
f0100798:	e8 b6 02 00 00       	call   f0100a53 <cprintf>
f010079d:	83 c4 10             	add    $0x10,%esp
			//operation or invalid argument
		}
		// BUG: PowerBase has to be fixed
		// BUG: if power equals zero, the point disappears ?!
		a =  powerbase(10,len-i) / 10 * (*(arg) - '0') + a;
f01007a0:	83 ec 08             	sub    $0x8,%esp
f01007a3:	89 f8                	mov    %edi,%eax
f01007a5:	89 f1                	mov    %esi,%ecx
f01007a7:	29 c8                	sub    %ecx,%eax
f01007a9:	0f be c0             	movsbl %al,%eax
f01007ac:	50                   	push   %eax
f01007ad:	6a 0a                	push   $0xa
f01007af:	e8 c2 17 00 00       	call   f0101f76 <powerbase>
f01007b4:	89 c1                	mov    %eax,%ecx
f01007b6:	b8 67 66 66 66       	mov    $0x66666667,%eax
f01007bb:	f7 e9                	imul   %ecx
f01007bd:	c1 fa 02             	sar    $0x2,%edx
f01007c0:	c1 f9 1f             	sar    $0x1f,%ecx
f01007c3:	29 ca                	sub    %ecx,%edx
f01007c5:	0f be 03             	movsbl (%ebx),%eax
f01007c8:	83 e8 30             	sub    $0x30,%eax
f01007cb:	0f af d0             	imul   %eax,%edx
f01007ce:	89 55 d8             	mov    %edx,-0x28(%ebp)
f01007d1:	db 45 d8             	fildl  -0x28(%ebp)
f01007d4:	dc 45 d0             	faddl  -0x30(%ebp)
f01007d7:	dd 5d d0             	fstpl  -0x30(%ebp)
		i++;
f01007da:	83 c6 01             	add    $0x1,%esi
		arg=arg+1;
f01007dd:	83 c3 01             	add    $0x1,%ebx
f01007e0:	83 c4 10             	add    $0x10,%esp
	double a = 0;

	Float retval;
	retval.error=0;

	while (i<len)
f01007e3:	39 fe                	cmp    %edi,%esi
f01007e5:	0f 8c 0d ff ff ff    	jl     f01006f8 <first_lab+0x31>
	}
	else
	{
		retval.number=a;
	}
	cprintf("entered val %f",a);
f01007eb:	83 ec 04             	sub    $0x4,%esp
f01007ee:	ff 75 d4             	pushl  -0x2c(%ebp)
f01007f1:	ff 75 d0             	pushl  -0x30(%ebp)
f01007f4:	68 ac 26 10 f0       	push   $0xf01026ac
f01007f9:	e8 55 02 00 00       	call   f0100a53 <cprintf>
	return 0;
f01007fe:	83 c4 10             	add    $0x10,%esp
f0100801:	b8 00 00 00 00       	mov    $0x0,%eax
f0100806:	eb 05                	jmp    f010080d <first_lab+0x146>
		if (*(arg) == '.')
		{
			if (!(arg+1))
			{
				retval.error=1;
				return 0;
f0100808:	b8 00 00 00 00       	mov    $0x0,%eax
	{
		retval.number=a;
	}
	cprintf("entered val %f",a);
	return 0;
}
f010080d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100810:	5b                   	pop    %ebx
f0100811:	5e                   	pop    %esi
f0100812:	5f                   	pop    %edi
f0100813:	5d                   	pop    %ebp
f0100814:	c3                   	ret    

f0100815 <second_lab>:
	return 0;
}

int
second_lab(int argc, char **argv, struct Trapframe *tf)
{
f0100815:	55                   	push   %ebp
f0100816:	89 e5                	mov    %esp,%ebp
f0100818:	83 ec 14             	sub    $0x14,%esp
	/// Yassin call his calculator here;
	char *in= NULL;
	char *out;
	out = readline(in);
f010081b:	6a 00                	push   $0x0
f010081d:	e8 e5 0b 00 00       	call   f0101407 <readline>
	int i=0;
	float a=0;
	while (out+i)
f0100822:	83 c4 10             	add    $0x10,%esp
f0100825:	85 c0                	test   %eax,%eax
f0100827:	75 fc                	jne    f0100825 <second_lab+0x10>
			//operation or invalid argument
		}
		float a;
	}	
	return 0;
}
f0100829:	c9                   	leave  
f010082a:	c3                   	ret    

f010082b <mon_kerninfo>:
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f010082b:	55                   	push   %ebp
f010082c:	89 e5                	mov    %esp,%ebp
f010082e:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100831:	68 cc 26 10 f0       	push   $0xf01026cc
f0100836:	e8 18 02 00 00       	call   f0100a53 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f010083b:	83 c4 08             	add    $0x8,%esp
f010083e:	68 0c 00 10 00       	push   $0x10000c
f0100843:	68 74 27 10 f0       	push   $0xf0102774
f0100848:	e8 06 02 00 00       	call   f0100a53 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010084d:	83 c4 0c             	add    $0xc,%esp
f0100850:	68 0c 00 10 00       	push   $0x10000c
f0100855:	68 0c 00 10 f0       	push   $0xf010000c
f010085a:	68 9c 27 10 f0       	push   $0xf010279c
f010085f:	e8 ef 01 00 00       	call   f0100a53 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100864:	83 c4 0c             	add    $0xc,%esp
f0100867:	68 65 23 10 00       	push   $0x102365
f010086c:	68 65 23 10 f0       	push   $0xf0102365
f0100871:	68 c0 27 10 f0       	push   $0xf01027c0
f0100876:	e8 d8 01 00 00       	call   f0100a53 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010087b:	83 c4 0c             	add    $0xc,%esp
f010087e:	68 00 43 11 00       	push   $0x114300
f0100883:	68 00 43 11 f0       	push   $0xf0114300
f0100888:	68 e4 27 10 f0       	push   $0xf01027e4
f010088d:	e8 c1 01 00 00       	call   f0100a53 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100892:	83 c4 0c             	add    $0xc,%esp
f0100895:	68 84 49 11 00       	push   $0x114984
f010089a:	68 84 49 11 f0       	push   $0xf0114984
f010089f:	68 08 28 10 f0       	push   $0xf0102808
f01008a4:	e8 aa 01 00 00       	call   f0100a53 <cprintf>
f01008a9:	b8 83 4d 11 f0       	mov    $0xf0114d83,%eax
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01008ae:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01008b3:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f01008b6:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01008bb:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f01008c1:	85 c0                	test   %eax,%eax
f01008c3:	0f 48 c2             	cmovs  %edx,%eax
f01008c6:	c1 f8 0a             	sar    $0xa,%eax
f01008c9:	50                   	push   %eax
f01008ca:	68 2c 28 10 f0       	push   $0xf010282c
f01008cf:	e8 7f 01 00 00       	call   f0100a53 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f01008d4:	b8 00 00 00 00       	mov    $0x0,%eax
f01008d9:	c9                   	leave  
f01008da:	c3                   	ret    

f01008db <mon_backtrace>:


int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01008db:	55                   	push   %ebp
f01008dc:	89 e5                	mov    %esp,%ebp
	// Your code here.
	return 0;
}
f01008de:	b8 00 00 00 00       	mov    $0x0,%eax
f01008e3:	5d                   	pop    %ebp
f01008e4:	c3                   	ret    

f01008e5 <monitor>:
}


void
monitor(struct Trapframe *tf)
{
f01008e5:	55                   	push   %ebp
f01008e6:	89 e5                	mov    %esp,%ebp
f01008e8:	57                   	push   %edi
f01008e9:	56                   	push   %esi
f01008ea:	53                   	push   %ebx
f01008eb:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01008ee:	68 58 28 10 f0       	push   $0xf0102858
f01008f3:	e8 5b 01 00 00       	call   f0100a53 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01008f8:	c7 04 24 7c 28 10 f0 	movl   $0xf010287c,(%esp)
f01008ff:	e8 4f 01 00 00       	call   f0100a53 <cprintf>
f0100904:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f0100907:	83 ec 0c             	sub    $0xc,%esp
f010090a:	68 e5 26 10 f0       	push   $0xf01026e5
f010090f:	e8 f3 0a 00 00       	call   f0101407 <readline>
f0100914:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100916:	83 c4 10             	add    $0x10,%esp
f0100919:	85 c0                	test   %eax,%eax
f010091b:	74 ea                	je     f0100907 <monitor+0x22>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f010091d:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100924:	be 00 00 00 00       	mov    $0x0,%esi
f0100929:	eb 0a                	jmp    f0100935 <monitor+0x50>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f010092b:	c6 03 00             	movb   $0x0,(%ebx)
f010092e:	89 f7                	mov    %esi,%edi
f0100930:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100933:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100935:	0f b6 03             	movzbl (%ebx),%eax
f0100938:	84 c0                	test   %al,%al
f010093a:	74 63                	je     f010099f <monitor+0xba>
f010093c:	83 ec 08             	sub    $0x8,%esp
f010093f:	0f be c0             	movsbl %al,%eax
f0100942:	50                   	push   %eax
f0100943:	68 e9 26 10 f0       	push   $0xf01026e9
f0100948:	e8 d4 0c 00 00       	call   f0101621 <strchr>
f010094d:	83 c4 10             	add    $0x10,%esp
f0100950:	85 c0                	test   %eax,%eax
f0100952:	75 d7                	jne    f010092b <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f0100954:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100957:	74 46                	je     f010099f <monitor+0xba>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100959:	83 fe 0f             	cmp    $0xf,%esi
f010095c:	75 14                	jne    f0100972 <monitor+0x8d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f010095e:	83 ec 08             	sub    $0x8,%esp
f0100961:	6a 10                	push   $0x10
f0100963:	68 ee 26 10 f0       	push   $0xf01026ee
f0100968:	e8 e6 00 00 00       	call   f0100a53 <cprintf>
f010096d:	83 c4 10             	add    $0x10,%esp
f0100970:	eb 95                	jmp    f0100907 <monitor+0x22>
			return 0;
		}
		argv[argc++] = buf;
f0100972:	8d 7e 01             	lea    0x1(%esi),%edi
f0100975:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100979:	eb 03                	jmp    f010097e <monitor+0x99>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f010097b:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010097e:	0f b6 03             	movzbl (%ebx),%eax
f0100981:	84 c0                	test   %al,%al
f0100983:	74 ae                	je     f0100933 <monitor+0x4e>
f0100985:	83 ec 08             	sub    $0x8,%esp
f0100988:	0f be c0             	movsbl %al,%eax
f010098b:	50                   	push   %eax
f010098c:	68 e9 26 10 f0       	push   $0xf01026e9
f0100991:	e8 8b 0c 00 00       	call   f0101621 <strchr>
f0100996:	83 c4 10             	add    $0x10,%esp
f0100999:	85 c0                	test   %eax,%eax
f010099b:	74 de                	je     f010097b <monitor+0x96>
f010099d:	eb 94                	jmp    f0100933 <monitor+0x4e>
			buf++;
	}
	argv[argc] = 0;
f010099f:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01009a6:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01009a7:	85 f6                	test   %esi,%esi
f01009a9:	0f 84 58 ff ff ff    	je     f0100907 <monitor+0x22>
f01009af:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01009b4:	83 ec 08             	sub    $0x8,%esp
f01009b7:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01009ba:	ff 34 85 c0 28 10 f0 	pushl  -0xfefd740(,%eax,4)
f01009c1:	ff 75 a8             	pushl  -0x58(%ebp)
f01009c4:	e8 fa 0b 00 00       	call   f01015c3 <strcmp>
f01009c9:	83 c4 10             	add    $0x10,%esp
f01009cc:	85 c0                	test   %eax,%eax
f01009ce:	75 22                	jne    f01009f2 <monitor+0x10d>
			return commands[i].func(argc, argv, tf);
f01009d0:	83 ec 04             	sub    $0x4,%esp
f01009d3:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01009d6:	ff 75 08             	pushl  0x8(%ebp)
f01009d9:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01009dc:	52                   	push   %edx
f01009dd:	56                   	push   %esi
f01009de:	ff 14 85 c8 28 10 f0 	call   *-0xfefd738(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01009e5:	83 c4 10             	add    $0x10,%esp
f01009e8:	85 c0                	test   %eax,%eax
f01009ea:	0f 89 17 ff ff ff    	jns    f0100907 <monitor+0x22>
f01009f0:	eb 20                	jmp    f0100a12 <monitor+0x12d>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f01009f2:	83 c3 01             	add    $0x1,%ebx
f01009f5:	83 fb 03             	cmp    $0x3,%ebx
f01009f8:	75 ba                	jne    f01009b4 <monitor+0xcf>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01009fa:	83 ec 08             	sub    $0x8,%esp
f01009fd:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a00:	68 0b 27 10 f0       	push   $0xf010270b
f0100a05:	e8 49 00 00 00       	call   f0100a53 <cprintf>
f0100a0a:	83 c4 10             	add    $0x10,%esp
f0100a0d:	e9 f5 fe ff ff       	jmp    f0100907 <monitor+0x22>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100a12:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100a15:	5b                   	pop    %ebx
f0100a16:	5e                   	pop    %esi
f0100a17:	5f                   	pop    %edi
f0100a18:	5d                   	pop    %ebp
f0100a19:	c3                   	ret    

f0100a1a <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100a1a:	55                   	push   %ebp
f0100a1b:	89 e5                	mov    %esp,%ebp
f0100a1d:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0100a20:	ff 75 08             	pushl  0x8(%ebp)
f0100a23:	e8 13 fc ff ff       	call   f010063b <cputchar>
f0100a28:	83 c4 10             	add    $0x10,%esp
	*cnt++;
}
f0100a2b:	c9                   	leave  
f0100a2c:	c3                   	ret    

f0100a2d <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100a2d:	55                   	push   %ebp
f0100a2e:	89 e5                	mov    %esp,%ebp
f0100a30:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0100a33:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100a3a:	ff 75 0c             	pushl  0xc(%ebp)
f0100a3d:	ff 75 08             	pushl  0x8(%ebp)
f0100a40:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100a43:	50                   	push   %eax
f0100a44:	68 1a 0a 10 f0       	push   $0xf0100a1a
f0100a49:	e8 9b 04 00 00       	call   f0100ee9 <vprintfmt>
	return cnt;
}
f0100a4e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100a51:	c9                   	leave  
f0100a52:	c3                   	ret    

f0100a53 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100a53:	55                   	push   %ebp
f0100a54:	89 e5                	mov    %esp,%ebp
f0100a56:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100a59:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100a5c:	50                   	push   %eax
f0100a5d:	ff 75 08             	pushl  0x8(%ebp)
f0100a60:	e8 c8 ff ff ff       	call   f0100a2d <vcprintf>
	va_end(ap);

	return cnt;
}
f0100a65:	c9                   	leave  
f0100a66:	c3                   	ret    

f0100a67 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100a67:	55                   	push   %ebp
f0100a68:	89 e5                	mov    %esp,%ebp
f0100a6a:	57                   	push   %edi
f0100a6b:	56                   	push   %esi
f0100a6c:	53                   	push   %ebx
f0100a6d:	83 ec 14             	sub    $0x14,%esp
f0100a70:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0100a73:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100a76:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100a79:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100a7c:	8b 1a                	mov    (%edx),%ebx
f0100a7e:	8b 01                	mov    (%ecx),%eax
f0100a80:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a83:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0100a8a:	e9 88 00 00 00       	jmp    f0100b17 <stab_binsearch+0xb0>
		int true_m = (l + r) / 2, m = true_m;
f0100a8f:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100a92:	01 d8                	add    %ebx,%eax
f0100a94:	89 c6                	mov    %eax,%esi
f0100a96:	c1 ee 1f             	shr    $0x1f,%esi
f0100a99:	01 c6                	add    %eax,%esi
f0100a9b:	d1 fe                	sar    %esi
f0100a9d:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0100aa0:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100aa3:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0100aa6:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100aa8:	eb 03                	jmp    f0100aad <stab_binsearch+0x46>
			m--;
f0100aaa:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100aad:	39 c3                	cmp    %eax,%ebx
f0100aaf:	7f 1f                	jg     f0100ad0 <stab_binsearch+0x69>
f0100ab1:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0100ab5:	83 ea 0c             	sub    $0xc,%edx
f0100ab8:	39 f9                	cmp    %edi,%ecx
f0100aba:	75 ee                	jne    f0100aaa <stab_binsearch+0x43>
f0100abc:	89 45 e8             	mov    %eax,-0x18(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100abf:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100ac2:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100ac5:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0100ac9:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100acc:	76 18                	jbe    f0100ae6 <stab_binsearch+0x7f>
f0100ace:	eb 05                	jmp    f0100ad5 <stab_binsearch+0x6e>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100ad0:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0100ad3:	eb 42                	jmp    f0100b17 <stab_binsearch+0xb0>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100ad5:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100ad8:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0100ada:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100add:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100ae4:	eb 31                	jmp    f0100b17 <stab_binsearch+0xb0>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100ae6:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100ae9:	73 17                	jae    f0100b02 <stab_binsearch+0x9b>
			*region_right = m - 1;
f0100aeb:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100aee:	83 e8 01             	sub    $0x1,%eax
f0100af1:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100af4:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100af7:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100af9:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100b00:	eb 15                	jmp    f0100b17 <stab_binsearch+0xb0>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100b02:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100b05:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100b08:	89 1e                	mov    %ebx,(%esi)
			l = m;
			addr++;
f0100b0a:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0100b0e:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100b10:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100b17:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100b1a:	0f 8e 6f ff ff ff    	jle    f0100a8f <stab_binsearch+0x28>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100b20:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0100b24:	75 0f                	jne    f0100b35 <stab_binsearch+0xce>
		*region_right = *region_left - 1;
f0100b26:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b29:	8b 00                	mov    (%eax),%eax
f0100b2b:	83 e8 01             	sub    $0x1,%eax
f0100b2e:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100b31:	89 06                	mov    %eax,(%esi)
f0100b33:	eb 2c                	jmp    f0100b61 <stab_binsearch+0xfa>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100b35:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b38:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100b3a:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100b3d:	8b 0e                	mov    (%esi),%ecx
f0100b3f:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100b42:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0100b45:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100b48:	eb 03                	jmp    f0100b4d <stab_binsearch+0xe6>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100b4a:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100b4d:	39 c8                	cmp    %ecx,%eax
f0100b4f:	7e 0b                	jle    f0100b5c <stab_binsearch+0xf5>
		     l > *region_left && stabs[l].n_type != type;
f0100b51:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0100b55:	83 ea 0c             	sub    $0xc,%edx
f0100b58:	39 fb                	cmp    %edi,%ebx
f0100b5a:	75 ee                	jne    f0100b4a <stab_binsearch+0xe3>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100b5c:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100b5f:	89 06                	mov    %eax,(%esi)
	}
}
f0100b61:	83 c4 14             	add    $0x14,%esp
f0100b64:	5b                   	pop    %ebx
f0100b65:	5e                   	pop    %esi
f0100b66:	5f                   	pop    %edi
f0100b67:	5d                   	pop    %ebp
f0100b68:	c3                   	ret    

f0100b69 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100b69:	55                   	push   %ebp
f0100b6a:	89 e5                	mov    %esp,%ebp
f0100b6c:	57                   	push   %edi
f0100b6d:	56                   	push   %esi
f0100b6e:	53                   	push   %ebx
f0100b6f:	83 ec 1c             	sub    $0x1c,%esp
f0100b72:	8b 7d 08             	mov    0x8(%ebp),%edi
f0100b75:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100b78:	c7 06 f0 28 10 f0    	movl   $0xf01028f0,(%esi)
	info->eip_line = 0;
f0100b7e:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0100b85:	c7 46 08 f0 28 10 f0 	movl   $0xf01028f0,0x8(%esi)
	info->eip_fn_namelen = 9;
f0100b8c:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f0100b93:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0100b96:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100b9d:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0100ba3:	76 11                	jbe    f0100bb6 <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100ba5:	b8 9d 94 10 f0       	mov    $0xf010949d,%eax
f0100baa:	3d e1 77 10 f0       	cmp    $0xf01077e1,%eax
f0100baf:	77 19                	ja     f0100bca <debuginfo_eip+0x61>
f0100bb1:	e9 4c 01 00 00       	jmp    f0100d02 <debuginfo_eip+0x199>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100bb6:	83 ec 04             	sub    $0x4,%esp
f0100bb9:	68 fa 28 10 f0       	push   $0xf01028fa
f0100bbe:	6a 7f                	push   $0x7f
f0100bc0:	68 07 29 10 f0       	push   $0xf0102907
f0100bc5:	e8 1c f5 ff ff       	call   f01000e6 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100bca:	80 3d 9c 94 10 f0 00 	cmpb   $0x0,0xf010949c
f0100bd1:	0f 85 32 01 00 00    	jne    f0100d09 <debuginfo_eip+0x1a0>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100bd7:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100bde:	b8 e0 77 10 f0       	mov    $0xf01077e0,%eax
f0100be3:	2d 88 2d 10 f0       	sub    $0xf0102d88,%eax
f0100be8:	c1 f8 02             	sar    $0x2,%eax
f0100beb:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100bf1:	83 e8 01             	sub    $0x1,%eax
f0100bf4:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100bf7:	83 ec 08             	sub    $0x8,%esp
f0100bfa:	57                   	push   %edi
f0100bfb:	6a 64                	push   $0x64
f0100bfd:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100c00:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100c03:	b8 88 2d 10 f0       	mov    $0xf0102d88,%eax
f0100c08:	e8 5a fe ff ff       	call   f0100a67 <stab_binsearch>
	if (lfile == 0)
f0100c0d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c10:	83 c4 10             	add    $0x10,%esp
f0100c13:	85 c0                	test   %eax,%eax
f0100c15:	0f 84 f5 00 00 00    	je     f0100d10 <debuginfo_eip+0x1a7>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100c1b:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100c1e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c21:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100c24:	83 ec 08             	sub    $0x8,%esp
f0100c27:	57                   	push   %edi
f0100c28:	6a 24                	push   $0x24
f0100c2a:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100c2d:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100c30:	b8 88 2d 10 f0       	mov    $0xf0102d88,%eax
f0100c35:	e8 2d fe ff ff       	call   f0100a67 <stab_binsearch>

	if (lfun <= rfun) {
f0100c3a:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100c3d:	83 c4 10             	add    $0x10,%esp
f0100c40:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f0100c43:	7f 31                	jg     f0100c76 <debuginfo_eip+0x10d>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100c45:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100c48:	c1 e0 02             	shl    $0x2,%eax
f0100c4b:	8d 90 88 2d 10 f0    	lea    -0xfefd278(%eax),%edx
f0100c51:	8b 88 88 2d 10 f0    	mov    -0xfefd278(%eax),%ecx
f0100c57:	b8 9d 94 10 f0       	mov    $0xf010949d,%eax
f0100c5c:	2d e1 77 10 f0       	sub    $0xf01077e1,%eax
f0100c61:	39 c1                	cmp    %eax,%ecx
f0100c63:	73 09                	jae    f0100c6e <debuginfo_eip+0x105>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100c65:	81 c1 e1 77 10 f0    	add    $0xf01077e1,%ecx
f0100c6b:	89 4e 08             	mov    %ecx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100c6e:	8b 42 08             	mov    0x8(%edx),%eax
f0100c71:	89 46 10             	mov    %eax,0x10(%esi)
f0100c74:	eb 06                	jmp    f0100c7c <debuginfo_eip+0x113>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100c76:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0100c79:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100c7c:	83 ec 08             	sub    $0x8,%esp
f0100c7f:	6a 3a                	push   $0x3a
f0100c81:	ff 76 08             	pushl  0x8(%esi)
f0100c84:	e8 b9 09 00 00       	call   f0101642 <strfind>
f0100c89:	2b 46 08             	sub    0x8(%esi),%eax
f0100c8c:	89 46 0c             	mov    %eax,0xc(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c8f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100c92:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100c95:	8d 04 85 88 2d 10 f0 	lea    -0xfefd278(,%eax,4),%eax
f0100c9c:	83 c4 10             	add    $0x10,%esp
f0100c9f:	eb 06                	jmp    f0100ca7 <debuginfo_eip+0x13e>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100ca1:	83 eb 01             	sub    $0x1,%ebx
f0100ca4:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100ca7:	39 fb                	cmp    %edi,%ebx
f0100ca9:	7c 1e                	jl     f0100cc9 <debuginfo_eip+0x160>
	       && stabs[lline].n_type != N_SOL
f0100cab:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f0100caf:	80 fa 84             	cmp    $0x84,%dl
f0100cb2:	74 6a                	je     f0100d1e <debuginfo_eip+0x1b5>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100cb4:	80 fa 64             	cmp    $0x64,%dl
f0100cb7:	75 e8                	jne    f0100ca1 <debuginfo_eip+0x138>
f0100cb9:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0100cbd:	74 e2                	je     f0100ca1 <debuginfo_eip+0x138>
f0100cbf:	eb 5d                	jmp    f0100d1e <debuginfo_eip+0x1b5>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100cc1:	81 c2 e1 77 10 f0    	add    $0xf01077e1,%edx
f0100cc7:	89 16                	mov    %edx,(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100cc9:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100ccc:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100ccf:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100cd4:	39 cb                	cmp    %ecx,%ebx
f0100cd6:	7d 60                	jge    f0100d38 <debuginfo_eip+0x1cf>
		for (lline = lfun + 1;
f0100cd8:	8d 53 01             	lea    0x1(%ebx),%edx
f0100cdb:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100cde:	8d 04 85 88 2d 10 f0 	lea    -0xfefd278(,%eax,4),%eax
f0100ce5:	eb 07                	jmp    f0100cee <debuginfo_eip+0x185>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100ce7:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0100ceb:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100cee:	39 ca                	cmp    %ecx,%edx
f0100cf0:	74 25                	je     f0100d17 <debuginfo_eip+0x1ae>
f0100cf2:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100cf5:	80 78 04 a0          	cmpb   $0xa0,0x4(%eax)
f0100cf9:	74 ec                	je     f0100ce7 <debuginfo_eip+0x17e>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100cfb:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d00:	eb 36                	jmp    f0100d38 <debuginfo_eip+0x1cf>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100d02:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d07:	eb 2f                	jmp    f0100d38 <debuginfo_eip+0x1cf>
f0100d09:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d0e:	eb 28                	jmp    f0100d38 <debuginfo_eip+0x1cf>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100d10:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d15:	eb 21                	jmp    f0100d38 <debuginfo_eip+0x1cf>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100d17:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d1c:	eb 1a                	jmp    f0100d38 <debuginfo_eip+0x1cf>
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100d1e:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100d21:	8b 14 85 88 2d 10 f0 	mov    -0xfefd278(,%eax,4),%edx
f0100d28:	b8 9d 94 10 f0       	mov    $0xf010949d,%eax
f0100d2d:	2d e1 77 10 f0       	sub    $0xf01077e1,%eax
f0100d32:	39 c2                	cmp    %eax,%edx
f0100d34:	72 8b                	jb     f0100cc1 <debuginfo_eip+0x158>
f0100d36:	eb 91                	jmp    f0100cc9 <debuginfo_eip+0x160>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
}
f0100d38:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100d3b:	5b                   	pop    %ebx
f0100d3c:	5e                   	pop    %esi
f0100d3d:	5f                   	pop    %edi
f0100d3e:	5d                   	pop    %ebp
f0100d3f:	c3                   	ret    

f0100d40 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100d40:	55                   	push   %ebp
f0100d41:	89 e5                	mov    %esp,%ebp
f0100d43:	57                   	push   %edi
f0100d44:	56                   	push   %esi
f0100d45:	53                   	push   %ebx
f0100d46:	83 ec 1c             	sub    $0x1c,%esp
f0100d49:	89 c7                	mov    %eax,%edi
f0100d4b:	89 d6                	mov    %edx,%esi
f0100d4d:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d50:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100d53:	89 d1                	mov    %edx,%ecx
f0100d55:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100d58:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100d5b:	8b 45 10             	mov    0x10(%ebp),%eax
f0100d5e:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100d61:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100d64:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0100d6b:	39 4d e4             	cmp    %ecx,-0x1c(%ebp)
f0100d6e:	72 05                	jb     f0100d75 <printnum+0x35>
f0100d70:	3b 45 d8             	cmp    -0x28(%ebp),%eax
f0100d73:	77 3e                	ja     f0100db3 <printnum+0x73>
                               
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100d75:	83 ec 0c             	sub    $0xc,%esp
f0100d78:	ff 75 18             	pushl  0x18(%ebp)
f0100d7b:	83 eb 01             	sub    $0x1,%ebx
f0100d7e:	53                   	push   %ebx
f0100d7f:	50                   	push   %eax
f0100d80:	83 ec 08             	sub    $0x8,%esp
f0100d83:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100d86:	ff 75 e0             	pushl  -0x20(%ebp)
f0100d89:	ff 75 dc             	pushl  -0x24(%ebp)
f0100d8c:	ff 75 d8             	pushl  -0x28(%ebp)
f0100d8f:	e8 2c 13 00 00       	call   f01020c0 <__udivdi3>
f0100d94:	83 c4 18             	add    $0x18,%esp
f0100d97:	52                   	push   %edx
f0100d98:	50                   	push   %eax
f0100d99:	89 f2                	mov    %esi,%edx
f0100d9b:	89 f8                	mov    %edi,%eax
f0100d9d:	e8 9e ff ff ff       	call   f0100d40 <printnum>
f0100da2:	83 c4 20             	add    $0x20,%esp
f0100da5:	eb 13                	jmp    f0100dba <printnum+0x7a>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100da7:	83 ec 08             	sub    $0x8,%esp
f0100daa:	56                   	push   %esi
f0100dab:	ff 75 18             	pushl  0x18(%ebp)
f0100dae:	ff d7                	call   *%edi
f0100db0:	83 c4 10             	add    $0x10,%esp
	if (num >= base) {
                               
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100db3:	83 eb 01             	sub    $0x1,%ebx
f0100db6:	85 db                	test   %ebx,%ebx
f0100db8:	7f ed                	jg     f0100da7 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100dba:	83 ec 08             	sub    $0x8,%esp
f0100dbd:	56                   	push   %esi
f0100dbe:	83 ec 04             	sub    $0x4,%esp
f0100dc1:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100dc4:	ff 75 e0             	pushl  -0x20(%ebp)
f0100dc7:	ff 75 dc             	pushl  -0x24(%ebp)
f0100dca:	ff 75 d8             	pushl  -0x28(%ebp)
f0100dcd:	e8 1e 14 00 00       	call   f01021f0 <__umoddi3>
f0100dd2:	83 c4 14             	add    $0x14,%esp
f0100dd5:	0f be 80 15 29 10 f0 	movsbl -0xfefd6eb(%eax),%eax
f0100ddc:	50                   	push   %eax
f0100ddd:	ff d7                	call   *%edi
f0100ddf:	83 c4 10             	add    $0x10,%esp
       
}
f0100de2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100de5:	5b                   	pop    %ebx
f0100de6:	5e                   	pop    %esi
f0100de7:	5f                   	pop    %edi
f0100de8:	5d                   	pop    %ebp
f0100de9:	c3                   	ret    

f0100dea <printnum2>:
static void
printnum2(void (*putch)(int, void*), void *putdat,
	 double num_float, unsigned base, int width, int padc)
{      
f0100dea:	55                   	push   %ebp
f0100deb:	89 e5                	mov    %esp,%ebp
f0100ded:	57                   	push   %edi
f0100dee:	56                   	push   %esi
f0100def:	53                   	push   %ebx
f0100df0:	83 ec 3c             	sub    $0x3c,%esp
f0100df3:	89 c7                	mov    %eax,%edi
f0100df5:	89 d6                	mov    %edx,%esi
f0100df7:	dd 45 08             	fldl   0x8(%ebp)
f0100dfa:	dd 55 d0             	fstl   -0x30(%ebp)
f0100dfd:	89 4d cc             	mov    %ecx,-0x34(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num_float >= base) { 
f0100e00:	89 4d c0             	mov    %ecx,-0x40(%ebp)
f0100e03:	c7 45 c4 00 00 00 00 	movl   $0x0,-0x3c(%ebp)
f0100e0a:	df 6d c0             	fildll -0x40(%ebp)
f0100e0d:	d9 c9                	fxch   %st(1)
f0100e0f:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0100e12:	db e9                	fucomi %st(1),%st
f0100e14:	72 2d                	jb     f0100e43 <printnum2+0x59>
		printnum2(putch, putdat, num_float / base, base, width - 1, padc);
f0100e16:	ff 75 14             	pushl  0x14(%ebp)
f0100e19:	8b 45 10             	mov    0x10(%ebp),%eax
f0100e1c:	83 e8 01             	sub    $0x1,%eax
f0100e1f:	50                   	push   %eax
f0100e20:	de f1                	fdivp  %st,%st(1)
f0100e22:	8d 64 24 f8          	lea    -0x8(%esp),%esp
f0100e26:	dd 1c 24             	fstpl  (%esp)
f0100e29:	89 f8                	mov    %edi,%eax
f0100e2b:	e8 ba ff ff ff       	call   f0100dea <printnum2>
f0100e30:	83 c4 10             	add    $0x10,%esp
f0100e33:	eb 2c                	jmp    f0100e61 <printnum2+0x77>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100e35:	83 ec 08             	sub    $0x8,%esp
f0100e38:	56                   	push   %esi
f0100e39:	ff 75 14             	pushl  0x14(%ebp)
f0100e3c:	ff d7                	call   *%edi
f0100e3e:	83 c4 10             	add    $0x10,%esp
f0100e41:	eb 04                	jmp    f0100e47 <printnum2+0x5d>
f0100e43:	dd d8                	fstp   %st(0)
f0100e45:	dd d8                	fstp   %st(0)
	// first recursively print all preceding (more significant) digits
	if (num_float >= base) { 
		printnum2(putch, putdat, num_float / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100e47:	83 eb 01             	sub    $0x1,%ebx
f0100e4a:	85 db                	test   %ebx,%ebx
f0100e4c:	7f e7                	jg     f0100e35 <printnum2+0x4b>
f0100e4e:	8b 55 10             	mov    0x10(%ebp),%edx
f0100e51:	83 ea 01             	sub    $0x1,%edx
f0100e54:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e59:	0f 49 c2             	cmovns %edx,%eax
f0100e5c:	29 c2                	sub    %eax,%edx
f0100e5e:	89 55 10             	mov    %edx,0x10(%ebp)
			putch(padc, putdat);
	}
        int x =(int)num_float;
	// then print this (the least significant) digit
	putch("0123456789abcdef"[x % base], putdat);
f0100e61:	83 ec 08             	sub    $0x8,%esp
f0100e64:	56                   	push   %esi
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
	}
        int x =(int)num_float;
f0100e65:	d9 7d de             	fnstcw -0x22(%ebp)
f0100e68:	0f b7 45 de          	movzwl -0x22(%ebp),%eax
f0100e6c:	b4 0c                	mov    $0xc,%ah
f0100e6e:	66 89 45 dc          	mov    %ax,-0x24(%ebp)
f0100e72:	dd 45 d0             	fldl   -0x30(%ebp)
f0100e75:	d9 6d dc             	fldcw  -0x24(%ebp)
f0100e78:	db 5d d8             	fistpl -0x28(%ebp)
f0100e7b:	d9 6d de             	fldcw  -0x22(%ebp)
f0100e7e:	8b 45 d8             	mov    -0x28(%ebp),%eax
	// then print this (the least significant) digit
	putch("0123456789abcdef"[x % base], putdat);
f0100e81:	ba 00 00 00 00       	mov    $0x0,%edx
f0100e86:	f7 75 cc             	divl   -0x34(%ebp)
f0100e89:	0f be 82 15 29 10 f0 	movsbl -0xfefd6eb(%edx),%eax
f0100e90:	50                   	push   %eax
f0100e91:	ff d7                	call   *%edi
        if ( width == -3) {
f0100e93:	83 c4 10             	add    $0x10,%esp
f0100e96:	83 7d 10 fd          	cmpl   $0xfffffffd,0x10(%ebp)
f0100e9a:	75 0b                	jne    f0100ea7 <printnum2+0xbd>
        putch('.',putdat);}
f0100e9c:	83 ec 08             	sub    $0x8,%esp
f0100e9f:	56                   	push   %esi
f0100ea0:	6a 2e                	push   $0x2e
f0100ea2:	ff d7                	call   *%edi
f0100ea4:	83 c4 10             	add    $0x10,%esp
}
f0100ea7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100eaa:	5b                   	pop    %ebx
f0100eab:	5e                   	pop    %esi
f0100eac:	5f                   	pop    %edi
f0100ead:	5d                   	pop    %ebp
f0100eae:	c3                   	ret    

f0100eaf <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100eaf:	55                   	push   %ebp
f0100eb0:	89 e5                	mov    %esp,%ebp
f0100eb2:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100eb5:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100eb9:	8b 10                	mov    (%eax),%edx
f0100ebb:	3b 50 04             	cmp    0x4(%eax),%edx
f0100ebe:	73 0a                	jae    f0100eca <sprintputch+0x1b>
		*b->buf++ = ch;
f0100ec0:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100ec3:	89 08                	mov    %ecx,(%eax)
f0100ec5:	8b 45 08             	mov    0x8(%ebp),%eax
f0100ec8:	88 02                	mov    %al,(%edx)
}
f0100eca:	5d                   	pop    %ebp
f0100ecb:	c3                   	ret    

f0100ecc <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100ecc:	55                   	push   %ebp
f0100ecd:	89 e5                	mov    %esp,%ebp
f0100ecf:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100ed2:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100ed5:	50                   	push   %eax
f0100ed6:	ff 75 10             	pushl  0x10(%ebp)
f0100ed9:	ff 75 0c             	pushl  0xc(%ebp)
f0100edc:	ff 75 08             	pushl  0x8(%ebp)
f0100edf:	e8 05 00 00 00       	call   f0100ee9 <vprintfmt>
	va_end(ap);
f0100ee4:	83 c4 10             	add    $0x10,%esp
}
f0100ee7:	c9                   	leave  
f0100ee8:	c3                   	ret    

f0100ee9 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100ee9:	55                   	push   %ebp
f0100eea:	89 e5                	mov    %esp,%ebp
f0100eec:	57                   	push   %edi
f0100eed:	56                   	push   %esi
f0100eee:	53                   	push   %ebx
f0100eef:	83 ec 2c             	sub    $0x2c,%esp
f0100ef2:	8b 75 08             	mov    0x8(%ebp),%esi
f0100ef5:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100ef8:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100efb:	eb 12                	jmp    f0100f0f <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100efd:	85 c0                	test   %eax,%eax
f0100eff:	0f 84 92 04 00 00    	je     f0101397 <vprintfmt+0x4ae>
				return;
			putch(ch, putdat);
f0100f05:	83 ec 08             	sub    $0x8,%esp
f0100f08:	53                   	push   %ebx
f0100f09:	50                   	push   %eax
f0100f0a:	ff d6                	call   *%esi
f0100f0c:	83 c4 10             	add    $0x10,%esp
        double num_float;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100f0f:	83 c7 01             	add    $0x1,%edi
f0100f12:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0100f16:	83 f8 25             	cmp    $0x25,%eax
f0100f19:	75 e2                	jne    f0100efd <vprintfmt+0x14>
f0100f1b:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0100f1f:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100f26:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100f2d:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0100f34:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100f39:	eb 07                	jmp    f0100f42 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f3b:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100f3e:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f42:	8d 47 01             	lea    0x1(%edi),%eax
f0100f45:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100f48:	0f b6 07             	movzbl (%edi),%eax
f0100f4b:	0f b6 d0             	movzbl %al,%edx
f0100f4e:	83 e8 23             	sub    $0x23,%eax
f0100f51:	3c 55                	cmp    $0x55,%al
f0100f53:	0f 87 23 04 00 00    	ja     f010137c <vprintfmt+0x493>
f0100f59:	0f b6 c0             	movzbl %al,%eax
f0100f5c:	ff 24 85 c0 29 10 f0 	jmp    *-0xfefd640(,%eax,4)
f0100f63:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100f66:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0100f6a:	eb d6                	jmp    f0100f42 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f6c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100f6f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f74:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100f77:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100f7a:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0100f7e:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0100f81:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0100f84:	83 f9 09             	cmp    $0x9,%ecx
f0100f87:	77 3f                	ja     f0100fc8 <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100f89:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0100f8c:	eb e9                	jmp    f0100f77 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100f8e:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f91:	8b 00                	mov    (%eax),%eax
f0100f93:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100f96:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f99:	8d 40 04             	lea    0x4(%eax),%eax
f0100f9c:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f9f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100fa2:	eb 2a                	jmp    f0100fce <vprintfmt+0xe5>
f0100fa4:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100fa7:	85 c0                	test   %eax,%eax
f0100fa9:	ba 00 00 00 00       	mov    $0x0,%edx
f0100fae:	0f 49 d0             	cmovns %eax,%edx
f0100fb1:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fb4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100fb7:	eb 89                	jmp    f0100f42 <vprintfmt+0x59>
f0100fb9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100fbc:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0100fc3:	e9 7a ff ff ff       	jmp    f0100f42 <vprintfmt+0x59>
f0100fc8:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100fcb:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0100fce:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100fd2:	0f 89 6a ff ff ff    	jns    f0100f42 <vprintfmt+0x59>
				width = precision, precision = -1;
f0100fd8:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100fdb:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100fde:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100fe5:	e9 58 ff ff ff       	jmp    f0100f42 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100fea:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fed:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100ff0:	e9 4d ff ff ff       	jmp    f0100f42 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ff5:	8b 45 14             	mov    0x14(%ebp),%eax
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100ff8:	83 45 14 04          	addl   $0x4,0x14(%ebp)
f0100ffc:	83 ec 08             	sub    $0x8,%esp
f0100fff:	53                   	push   %ebx
f0101000:	ff 30                	pushl  (%eax)
f0101002:	ff d6                	call   *%esi
			break;
f0101004:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101007:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f010100a:	e9 00 ff ff ff       	jmp    f0100f0f <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f010100f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101012:	8d 78 04             	lea    0x4(%eax),%edi
f0101015:	8b 00                	mov    (%eax),%eax
f0101017:	99                   	cltd   
f0101018:	31 d0                	xor    %edx,%eax
f010101a:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010101c:	83 f8 07             	cmp    $0x7,%eax
f010101f:	7f 0b                	jg     f010102c <vprintfmt+0x143>
f0101021:	8b 14 85 20 2b 10 f0 	mov    -0xfefd4e0(,%eax,4),%edx
f0101028:	85 d2                	test   %edx,%edx
f010102a:	75 1b                	jne    f0101047 <vprintfmt+0x15e>
				printfmt(putch, putdat, "error %d", err);
f010102c:	50                   	push   %eax
f010102d:	68 2d 29 10 f0       	push   $0xf010292d
f0101032:	53                   	push   %ebx
f0101033:	56                   	push   %esi
f0101034:	e8 93 fe ff ff       	call   f0100ecc <printfmt>
f0101039:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f010103c:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010103f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0101042:	e9 c8 fe ff ff       	jmp    f0100f0f <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0101047:	52                   	push   %edx
f0101048:	68 36 29 10 f0       	push   $0xf0102936
f010104d:	53                   	push   %ebx
f010104e:	56                   	push   %esi
f010104f:	e8 78 fe ff ff       	call   f0100ecc <printfmt>
f0101054:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0101057:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010105a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010105d:	e9 ad fe ff ff       	jmp    f0100f0f <vprintfmt+0x26>
f0101062:	8b 45 14             	mov    0x14(%ebp),%eax
f0101065:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0101068:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f010106b:	89 4d cc             	mov    %ecx,-0x34(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f010106e:	83 45 14 04          	addl   $0x4,0x14(%ebp)
f0101072:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0101074:	85 ff                	test   %edi,%edi
f0101076:	b8 26 29 10 f0       	mov    $0xf0102926,%eax
f010107b:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f010107e:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0101082:	0f 84 90 00 00 00    	je     f0101118 <vprintfmt+0x22f>
f0101088:	85 c9                	test   %ecx,%ecx
f010108a:	0f 8e 96 00 00 00    	jle    f0101126 <vprintfmt+0x23d>
				for (width -= strnlen(p, precision); width > 0; width--)
f0101090:	83 ec 08             	sub    $0x8,%esp
f0101093:	52                   	push   %edx
f0101094:	57                   	push   %edi
f0101095:	e8 5e 04 00 00       	call   f01014f8 <strnlen>
f010109a:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f010109d:	29 c1                	sub    %eax,%ecx
f010109f:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f01010a2:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f01010a5:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f01010a9:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01010ac:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01010af:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01010b1:	eb 0f                	jmp    f01010c2 <vprintfmt+0x1d9>
					putch(padc, putdat);
f01010b3:	83 ec 08             	sub    $0x8,%esp
f01010b6:	53                   	push   %ebx
f01010b7:	ff 75 e0             	pushl  -0x20(%ebp)
f01010ba:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01010bc:	83 ef 01             	sub    $0x1,%edi
f01010bf:	83 c4 10             	add    $0x10,%esp
f01010c2:	85 ff                	test   %edi,%edi
f01010c4:	7f ed                	jg     f01010b3 <vprintfmt+0x1ca>
f01010c6:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01010c9:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f01010cc:	85 c9                	test   %ecx,%ecx
f01010ce:	b8 00 00 00 00       	mov    $0x0,%eax
f01010d3:	0f 49 c1             	cmovns %ecx,%eax
f01010d6:	29 c1                	sub    %eax,%ecx
f01010d8:	89 75 08             	mov    %esi,0x8(%ebp)
f01010db:	8b 75 d0             	mov    -0x30(%ebp),%esi
f01010de:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01010e1:	89 cb                	mov    %ecx,%ebx
f01010e3:	eb 4d                	jmp    f0101132 <vprintfmt+0x249>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f01010e5:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01010e9:	74 1b                	je     f0101106 <vprintfmt+0x21d>
f01010eb:	0f be c0             	movsbl %al,%eax
f01010ee:	83 e8 20             	sub    $0x20,%eax
f01010f1:	83 f8 5e             	cmp    $0x5e,%eax
f01010f4:	76 10                	jbe    f0101106 <vprintfmt+0x21d>
					putch('?', putdat);
f01010f6:	83 ec 08             	sub    $0x8,%esp
f01010f9:	ff 75 0c             	pushl  0xc(%ebp)
f01010fc:	6a 3f                	push   $0x3f
f01010fe:	ff 55 08             	call   *0x8(%ebp)
f0101101:	83 c4 10             	add    $0x10,%esp
f0101104:	eb 0d                	jmp    f0101113 <vprintfmt+0x22a>
				else
					putch(ch, putdat);
f0101106:	83 ec 08             	sub    $0x8,%esp
f0101109:	ff 75 0c             	pushl  0xc(%ebp)
f010110c:	52                   	push   %edx
f010110d:	ff 55 08             	call   *0x8(%ebp)
f0101110:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101113:	83 eb 01             	sub    $0x1,%ebx
f0101116:	eb 1a                	jmp    f0101132 <vprintfmt+0x249>
f0101118:	89 75 08             	mov    %esi,0x8(%ebp)
f010111b:	8b 75 d0             	mov    -0x30(%ebp),%esi
f010111e:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101121:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0101124:	eb 0c                	jmp    f0101132 <vprintfmt+0x249>
f0101126:	89 75 08             	mov    %esi,0x8(%ebp)
f0101129:	8b 75 d0             	mov    -0x30(%ebp),%esi
f010112c:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010112f:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0101132:	83 c7 01             	add    $0x1,%edi
f0101135:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0101139:	0f be d0             	movsbl %al,%edx
f010113c:	85 d2                	test   %edx,%edx
f010113e:	74 23                	je     f0101163 <vprintfmt+0x27a>
f0101140:	85 f6                	test   %esi,%esi
f0101142:	78 a1                	js     f01010e5 <vprintfmt+0x1fc>
f0101144:	83 ee 01             	sub    $0x1,%esi
f0101147:	79 9c                	jns    f01010e5 <vprintfmt+0x1fc>
f0101149:	89 df                	mov    %ebx,%edi
f010114b:	8b 75 08             	mov    0x8(%ebp),%esi
f010114e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101151:	eb 18                	jmp    f010116b <vprintfmt+0x282>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0101153:	83 ec 08             	sub    $0x8,%esp
f0101156:	53                   	push   %ebx
f0101157:	6a 20                	push   $0x20
f0101159:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f010115b:	83 ef 01             	sub    $0x1,%edi
f010115e:	83 c4 10             	add    $0x10,%esp
f0101161:	eb 08                	jmp    f010116b <vprintfmt+0x282>
f0101163:	89 df                	mov    %ebx,%edi
f0101165:	8b 75 08             	mov    0x8(%ebp),%esi
f0101168:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010116b:	85 ff                	test   %edi,%edi
f010116d:	7f e4                	jg     f0101153 <vprintfmt+0x26a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010116f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101172:	e9 98 fd ff ff       	jmp    f0100f0f <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101177:	83 f9 01             	cmp    $0x1,%ecx
f010117a:	7e 19                	jle    f0101195 <vprintfmt+0x2ac>
		return va_arg(*ap, long long);
f010117c:	8b 45 14             	mov    0x14(%ebp),%eax
f010117f:	8b 50 04             	mov    0x4(%eax),%edx
f0101182:	8b 00                	mov    (%eax),%eax
f0101184:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101187:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010118a:	8b 45 14             	mov    0x14(%ebp),%eax
f010118d:	8d 40 08             	lea    0x8(%eax),%eax
f0101190:	89 45 14             	mov    %eax,0x14(%ebp)
f0101193:	eb 38                	jmp    f01011cd <vprintfmt+0x2e4>
	else if (lflag)
f0101195:	85 c9                	test   %ecx,%ecx
f0101197:	74 1b                	je     f01011b4 <vprintfmt+0x2cb>
		return va_arg(*ap, long);
f0101199:	8b 45 14             	mov    0x14(%ebp),%eax
f010119c:	8b 00                	mov    (%eax),%eax
f010119e:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01011a1:	89 c1                	mov    %eax,%ecx
f01011a3:	c1 f9 1f             	sar    $0x1f,%ecx
f01011a6:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01011a9:	8b 45 14             	mov    0x14(%ebp),%eax
f01011ac:	8d 40 04             	lea    0x4(%eax),%eax
f01011af:	89 45 14             	mov    %eax,0x14(%ebp)
f01011b2:	eb 19                	jmp    f01011cd <vprintfmt+0x2e4>
	else
		return va_arg(*ap, int);
f01011b4:	8b 45 14             	mov    0x14(%ebp),%eax
f01011b7:	8b 00                	mov    (%eax),%eax
f01011b9:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01011bc:	89 c1                	mov    %eax,%ecx
f01011be:	c1 f9 1f             	sar    $0x1f,%ecx
f01011c1:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01011c4:	8b 45 14             	mov    0x14(%ebp),%eax
f01011c7:	8d 40 04             	lea    0x4(%eax),%eax
f01011ca:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f01011cd:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01011d0:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01011d3:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01011d8:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01011dc:	0f 89 66 01 00 00    	jns    f0101348 <vprintfmt+0x45f>
				putch('-', putdat);
f01011e2:	83 ec 08             	sub    $0x8,%esp
f01011e5:	53                   	push   %ebx
f01011e6:	6a 2d                	push   $0x2d
f01011e8:	ff d6                	call   *%esi
				num = -(long long) num;
f01011ea:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01011ed:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01011f0:	f7 da                	neg    %edx
f01011f2:	83 d1 00             	adc    $0x0,%ecx
f01011f5:	f7 d9                	neg    %ecx
f01011f7:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f01011fa:	b8 0a 00 00 00       	mov    $0xa,%eax
f01011ff:	e9 44 01 00 00       	jmp    f0101348 <vprintfmt+0x45f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101204:	83 f9 01             	cmp    $0x1,%ecx
f0101207:	7e 18                	jle    f0101221 <vprintfmt+0x338>
		return va_arg(*ap, unsigned long long);
f0101209:	8b 45 14             	mov    0x14(%ebp),%eax
f010120c:	8b 10                	mov    (%eax),%edx
f010120e:	8b 48 04             	mov    0x4(%eax),%ecx
f0101211:	8d 40 08             	lea    0x8(%eax),%eax
f0101214:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0101217:	b8 0a 00 00 00       	mov    $0xa,%eax
f010121c:	e9 27 01 00 00       	jmp    f0101348 <vprintfmt+0x45f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0101221:	85 c9                	test   %ecx,%ecx
f0101223:	74 1a                	je     f010123f <vprintfmt+0x356>
		return va_arg(*ap, unsigned long);
f0101225:	8b 45 14             	mov    0x14(%ebp),%eax
f0101228:	8b 10                	mov    (%eax),%edx
f010122a:	b9 00 00 00 00       	mov    $0x0,%ecx
f010122f:	8d 40 04             	lea    0x4(%eax),%eax
f0101232:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0101235:	b8 0a 00 00 00       	mov    $0xa,%eax
f010123a:	e9 09 01 00 00       	jmp    f0101348 <vprintfmt+0x45f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f010123f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101242:	8b 10                	mov    (%eax),%edx
f0101244:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101249:	8d 40 04             	lea    0x4(%eax),%eax
f010124c:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f010124f:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101254:	e9 ef 00 00 00       	jmp    f0101348 <vprintfmt+0x45f>
			goto number;

               // signed float
		case 'f':
			num_float = va_arg(ap, double);
f0101259:	8b 45 14             	mov    0x14(%ebp),%eax
f010125c:	8d 78 08             	lea    0x8(%eax),%edi
                        num_float = num_float*100;
f010125f:	d9 05 40 2b 10 f0    	flds   0xf0102b40
f0101265:	dc 08                	fmull  (%eax)
f0101267:	d9 c0                	fld    %st(0)
f0101269:	dd 5d d8             	fstpl  -0x28(%ebp)
			if ( num_float < 0) {
f010126c:	d9 ee                	fldz   
f010126e:	df e9                	fucomip %st(1),%st
f0101270:	dd d8                	fstp   %st(0)
f0101272:	76 13                	jbe    f0101287 <vprintfmt+0x39e>
				putch('-', putdat);
f0101274:	83 ec 08             	sub    $0x8,%esp
f0101277:	53                   	push   %ebx
f0101278:	6a 2d                	push   $0x2d
f010127a:	ff d6                	call   *%esi
				num_float = - num_float;
f010127c:	dd 45 d8             	fldl   -0x28(%ebp)
f010127f:	d9 e0                	fchs   
f0101281:	dd 5d d8             	fstpl  -0x28(%ebp)
f0101284:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
                        
			printnum2(putch, putdat, num_float, base, width, padc);
f0101287:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f010128b:	50                   	push   %eax
f010128c:	ff 75 e0             	pushl  -0x20(%ebp)
f010128f:	ff 75 dc             	pushl  -0x24(%ebp)
f0101292:	ff 75 d8             	pushl  -0x28(%ebp)
f0101295:	b9 0a 00 00 00       	mov    $0xa,%ecx
f010129a:	89 da                	mov    %ebx,%edx
f010129c:	89 f0                	mov    %esi,%eax
f010129e:	e8 47 fb ff ff       	call   f0100dea <printnum2>
			break;
f01012a3:	83 c4 10             	add    $0x10,%esp
			base = 10;
			goto number;

               // signed float
		case 'f':
			num_float = va_arg(ap, double);
f01012a6:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01012a9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
				num_float = - num_float;
			}
			base = 10;
                        
			printnum2(putch, putdat, num_float, base, width, padc);
			break;
f01012ac:	e9 5e fc ff ff       	jmp    f0100f0f <vprintfmt+0x26>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f01012b1:	83 ec 08             	sub    $0x8,%esp
f01012b4:	53                   	push   %ebx
f01012b5:	6a 58                	push   $0x58
f01012b7:	ff d6                	call   *%esi
			putch('X', putdat);
f01012b9:	83 c4 08             	add    $0x8,%esp
f01012bc:	53                   	push   %ebx
f01012bd:	6a 58                	push   $0x58
f01012bf:	ff d6                	call   *%esi
			putch('X', putdat);
f01012c1:	83 c4 08             	add    $0x8,%esp
f01012c4:	53                   	push   %ebx
f01012c5:	6a 58                	push   $0x58
f01012c7:	ff d6                	call   *%esi
			break;
f01012c9:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01012cc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
f01012cf:	e9 3b fc ff ff       	jmp    f0100f0f <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
f01012d4:	83 ec 08             	sub    $0x8,%esp
f01012d7:	53                   	push   %ebx
f01012d8:	6a 30                	push   $0x30
f01012da:	ff d6                	call   *%esi
			putch('x', putdat);
f01012dc:	83 c4 08             	add    $0x8,%esp
f01012df:	53                   	push   %ebx
f01012e0:	6a 78                	push   $0x78
f01012e2:	ff d6                	call   *%esi
			num = (unsigned long long)
f01012e4:	8b 45 14             	mov    0x14(%ebp),%eax
f01012e7:	8b 10                	mov    (%eax),%edx
f01012e9:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f01012ee:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01012f1:	8d 40 04             	lea    0x4(%eax),%eax
f01012f4:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01012f7:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f01012fc:	eb 4a                	jmp    f0101348 <vprintfmt+0x45f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01012fe:	83 f9 01             	cmp    $0x1,%ecx
f0101301:	7e 15                	jle    f0101318 <vprintfmt+0x42f>
		return va_arg(*ap, unsigned long long);
f0101303:	8b 45 14             	mov    0x14(%ebp),%eax
f0101306:	8b 10                	mov    (%eax),%edx
f0101308:	8b 48 04             	mov    0x4(%eax),%ecx
f010130b:	8d 40 08             	lea    0x8(%eax),%eax
f010130e:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0101311:	b8 10 00 00 00       	mov    $0x10,%eax
f0101316:	eb 30                	jmp    f0101348 <vprintfmt+0x45f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0101318:	85 c9                	test   %ecx,%ecx
f010131a:	74 17                	je     f0101333 <vprintfmt+0x44a>
		return va_arg(*ap, unsigned long);
f010131c:	8b 45 14             	mov    0x14(%ebp),%eax
f010131f:	8b 10                	mov    (%eax),%edx
f0101321:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101326:	8d 40 04             	lea    0x4(%eax),%eax
f0101329:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f010132c:	b8 10 00 00 00       	mov    $0x10,%eax
f0101331:	eb 15                	jmp    f0101348 <vprintfmt+0x45f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0101333:	8b 45 14             	mov    0x14(%ebp),%eax
f0101336:	8b 10                	mov    (%eax),%edx
f0101338:	b9 00 00 00 00       	mov    $0x0,%ecx
f010133d:	8d 40 04             	lea    0x4(%eax),%eax
f0101340:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0101343:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101348:	83 ec 0c             	sub    $0xc,%esp
f010134b:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f010134f:	57                   	push   %edi
f0101350:	ff 75 e0             	pushl  -0x20(%ebp)
f0101353:	50                   	push   %eax
f0101354:	51                   	push   %ecx
f0101355:	52                   	push   %edx
f0101356:	89 da                	mov    %ebx,%edx
f0101358:	89 f0                	mov    %esi,%eax
f010135a:	e8 e1 f9 ff ff       	call   f0100d40 <printnum>
			break;
f010135f:	83 c4 20             	add    $0x20,%esp
f0101362:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101365:	e9 a5 fb ff ff       	jmp    f0100f0f <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f010136a:	83 ec 08             	sub    $0x8,%esp
f010136d:	53                   	push   %ebx
f010136e:	52                   	push   %edx
f010136f:	ff d6                	call   *%esi
			break;
f0101371:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101374:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0101377:	e9 93 fb ff ff       	jmp    f0100f0f <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f010137c:	83 ec 08             	sub    $0x8,%esp
f010137f:	53                   	push   %ebx
f0101380:	6a 25                	push   $0x25
f0101382:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101384:	83 c4 10             	add    $0x10,%esp
f0101387:	eb 03                	jmp    f010138c <vprintfmt+0x4a3>
f0101389:	83 ef 01             	sub    $0x1,%edi
f010138c:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0101390:	75 f7                	jne    f0101389 <vprintfmt+0x4a0>
f0101392:	e9 78 fb ff ff       	jmp    f0100f0f <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0101397:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010139a:	5b                   	pop    %ebx
f010139b:	5e                   	pop    %esi
f010139c:	5f                   	pop    %edi
f010139d:	5d                   	pop    %ebp
f010139e:	c3                   	ret    

f010139f <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f010139f:	55                   	push   %ebp
f01013a0:	89 e5                	mov    %esp,%ebp
f01013a2:	83 ec 18             	sub    $0x18,%esp
f01013a5:	8b 45 08             	mov    0x8(%ebp),%eax
f01013a8:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01013ab:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01013ae:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01013b2:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01013b5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01013bc:	85 c0                	test   %eax,%eax
f01013be:	74 26                	je     f01013e6 <vsnprintf+0x47>
f01013c0:	85 d2                	test   %edx,%edx
f01013c2:	7e 22                	jle    f01013e6 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01013c4:	ff 75 14             	pushl  0x14(%ebp)
f01013c7:	ff 75 10             	pushl  0x10(%ebp)
f01013ca:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01013cd:	50                   	push   %eax
f01013ce:	68 af 0e 10 f0       	push   $0xf0100eaf
f01013d3:	e8 11 fb ff ff       	call   f0100ee9 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01013d8:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01013db:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01013de:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01013e1:	83 c4 10             	add    $0x10,%esp
f01013e4:	eb 05                	jmp    f01013eb <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01013e6:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01013eb:	c9                   	leave  
f01013ec:	c3                   	ret    

f01013ed <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01013ed:	55                   	push   %ebp
f01013ee:	89 e5                	mov    %esp,%ebp
f01013f0:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01013f3:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01013f6:	50                   	push   %eax
f01013f7:	ff 75 10             	pushl  0x10(%ebp)
f01013fa:	ff 75 0c             	pushl  0xc(%ebp)
f01013fd:	ff 75 08             	pushl  0x8(%ebp)
f0101400:	e8 9a ff ff ff       	call   f010139f <vsnprintf>
	va_end(ap);

	return rc;
f0101405:	c9                   	leave  
f0101406:	c3                   	ret    

f0101407 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101407:	55                   	push   %ebp
f0101408:	89 e5                	mov    %esp,%ebp
f010140a:	57                   	push   %edi
f010140b:	56                   	push   %esi
f010140c:	53                   	push   %ebx
f010140d:	83 ec 0c             	sub    $0xc,%esp
f0101410:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0101413:	85 c0                	test   %eax,%eax
f0101415:	74 11                	je     f0101428 <readline+0x21>
		cprintf("%s", prompt);
f0101417:	83 ec 08             	sub    $0x8,%esp
f010141a:	50                   	push   %eax
f010141b:	68 36 29 10 f0       	push   $0xf0102936
f0101420:	e8 2e f6 ff ff       	call   f0100a53 <cprintf>
f0101425:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0101428:	83 ec 0c             	sub    $0xc,%esp
f010142b:	6a 00                	push   $0x0
f010142d:	e8 2a f2 ff ff       	call   f010065c <iscons>
f0101432:	89 c7                	mov    %eax,%edi
f0101434:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0101437:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f010143c:	e8 0a f2 ff ff       	call   f010064b <getchar>
f0101441:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0101443:	85 c0                	test   %eax,%eax
f0101445:	79 18                	jns    f010145f <readline+0x58>
			cprintf("read error: %e\n", c);
f0101447:	83 ec 08             	sub    $0x8,%esp
f010144a:	50                   	push   %eax
f010144b:	68 44 2b 10 f0       	push   $0xf0102b44
f0101450:	e8 fe f5 ff ff       	call   f0100a53 <cprintf>
			return NULL;
f0101455:	83 c4 10             	add    $0x10,%esp
f0101458:	b8 00 00 00 00       	mov    $0x0,%eax
f010145d:	eb 79                	jmp    f01014d8 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f010145f:	83 f8 7f             	cmp    $0x7f,%eax
f0101462:	0f 94 c2             	sete   %dl
f0101465:	83 f8 08             	cmp    $0x8,%eax
f0101468:	0f 94 c0             	sete   %al
f010146b:	08 c2                	or     %al,%dl
f010146d:	74 1a                	je     f0101489 <readline+0x82>
f010146f:	85 f6                	test   %esi,%esi
f0101471:	7e 16                	jle    f0101489 <readline+0x82>
			if (echoing)
f0101473:	85 ff                	test   %edi,%edi
f0101475:	74 0d                	je     f0101484 <readline+0x7d>
				cputchar('\b');
f0101477:	83 ec 0c             	sub    $0xc,%esp
f010147a:	6a 08                	push   $0x8
f010147c:	e8 ba f1 ff ff       	call   f010063b <cputchar>
f0101481:	83 c4 10             	add    $0x10,%esp
			i--;
f0101484:	83 ee 01             	sub    $0x1,%esi
f0101487:	eb b3                	jmp    f010143c <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101489:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010148f:	7f 20                	jg     f01014b1 <readline+0xaa>
f0101491:	83 fb 1f             	cmp    $0x1f,%ebx
f0101494:	7e 1b                	jle    f01014b1 <readline+0xaa>
			if (echoing)
f0101496:	85 ff                	test   %edi,%edi
f0101498:	74 0c                	je     f01014a6 <readline+0x9f>
				cputchar(c);
f010149a:	83 ec 0c             	sub    $0xc,%esp
f010149d:	53                   	push   %ebx
f010149e:	e8 98 f1 ff ff       	call   f010063b <cputchar>
f01014a3:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f01014a6:	88 9e 80 45 11 f0    	mov    %bl,-0xfeeba80(%esi)
f01014ac:	8d 76 01             	lea    0x1(%esi),%esi
f01014af:	eb 8b                	jmp    f010143c <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f01014b1:	83 fb 0d             	cmp    $0xd,%ebx
f01014b4:	74 05                	je     f01014bb <readline+0xb4>
f01014b6:	83 fb 0a             	cmp    $0xa,%ebx
f01014b9:	75 81                	jne    f010143c <readline+0x35>
			if (echoing)
f01014bb:	85 ff                	test   %edi,%edi
f01014bd:	74 0d                	je     f01014cc <readline+0xc5>
				cputchar('\n');
f01014bf:	83 ec 0c             	sub    $0xc,%esp
f01014c2:	6a 0a                	push   $0xa
f01014c4:	e8 72 f1 ff ff       	call   f010063b <cputchar>
f01014c9:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f01014cc:	c6 86 80 45 11 f0 00 	movb   $0x0,-0xfeeba80(%esi)
			return buf;
f01014d3:	b8 80 45 11 f0       	mov    $0xf0114580,%eax
		}
	}
}
f01014d8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01014db:	5b                   	pop    %ebx
f01014dc:	5e                   	pop    %esi
f01014dd:	5f                   	pop    %edi
f01014de:	5d                   	pop    %ebp
f01014df:	c3                   	ret    

f01014e0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01014e0:	55                   	push   %ebp
f01014e1:	89 e5                	mov    %esp,%ebp
f01014e3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01014e6:	b8 00 00 00 00       	mov    $0x0,%eax
f01014eb:	eb 03                	jmp    f01014f0 <strlen+0x10>
		n++;
f01014ed:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01014f0:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01014f4:	75 f7                	jne    f01014ed <strlen+0xd>
		n++;
	return n;
}
f01014f6:	5d                   	pop    %ebp
f01014f7:	c3                   	ret    

f01014f8 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01014f8:	55                   	push   %ebp
f01014f9:	89 e5                	mov    %esp,%ebp
f01014fb:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01014fe:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101501:	ba 00 00 00 00       	mov    $0x0,%edx
f0101506:	eb 03                	jmp    f010150b <strnlen+0x13>
		n++;
f0101508:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010150b:	39 c2                	cmp    %eax,%edx
f010150d:	74 08                	je     f0101517 <strnlen+0x1f>
f010150f:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0101513:	75 f3                	jne    f0101508 <strnlen+0x10>
f0101515:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0101517:	5d                   	pop    %ebp
f0101518:	c3                   	ret    

f0101519 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101519:	55                   	push   %ebp
f010151a:	89 e5                	mov    %esp,%ebp
f010151c:	53                   	push   %ebx
f010151d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101520:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101523:	89 c2                	mov    %eax,%edx
f0101525:	83 c2 01             	add    $0x1,%edx
f0101528:	83 c1 01             	add    $0x1,%ecx
f010152b:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010152f:	88 5a ff             	mov    %bl,-0x1(%edx)
f0101532:	84 db                	test   %bl,%bl
f0101534:	75 ef                	jne    f0101525 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101536:	5b                   	pop    %ebx
f0101537:	5d                   	pop    %ebp
f0101538:	c3                   	ret    

f0101539 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101539:	55                   	push   %ebp
f010153a:	89 e5                	mov    %esp,%ebp
f010153c:	53                   	push   %ebx
f010153d:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101540:	53                   	push   %ebx
f0101541:	e8 9a ff ff ff       	call   f01014e0 <strlen>
f0101546:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0101549:	ff 75 0c             	pushl  0xc(%ebp)
f010154c:	01 d8                	add    %ebx,%eax
f010154e:	50                   	push   %eax
f010154f:	e8 c5 ff ff ff       	call   f0101519 <strcpy>
	return dst;
}
f0101554:	89 d8                	mov    %ebx,%eax
f0101556:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101559:	c9                   	leave  
f010155a:	c3                   	ret    

f010155b <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010155b:	55                   	push   %ebp
f010155c:	89 e5                	mov    %esp,%ebp
f010155e:	56                   	push   %esi
f010155f:	53                   	push   %ebx
f0101560:	8b 75 08             	mov    0x8(%ebp),%esi
f0101563:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101566:	89 f3                	mov    %esi,%ebx
f0101568:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010156b:	89 f2                	mov    %esi,%edx
f010156d:	eb 0f                	jmp    f010157e <strncpy+0x23>
		*dst++ = *src;
f010156f:	83 c2 01             	add    $0x1,%edx
f0101572:	0f b6 01             	movzbl (%ecx),%eax
f0101575:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101578:	80 39 01             	cmpb   $0x1,(%ecx)
f010157b:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010157e:	39 da                	cmp    %ebx,%edx
f0101580:	75 ed                	jne    f010156f <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101582:	89 f0                	mov    %esi,%eax
f0101584:	5b                   	pop    %ebx
f0101585:	5e                   	pop    %esi
f0101586:	5d                   	pop    %ebp
f0101587:	c3                   	ret    

f0101588 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101588:	55                   	push   %ebp
f0101589:	89 e5                	mov    %esp,%ebp
f010158b:	56                   	push   %esi
f010158c:	53                   	push   %ebx
f010158d:	8b 75 08             	mov    0x8(%ebp),%esi
f0101590:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101593:	8b 55 10             	mov    0x10(%ebp),%edx
f0101596:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101598:	85 d2                	test   %edx,%edx
f010159a:	74 21                	je     f01015bd <strlcpy+0x35>
f010159c:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f01015a0:	89 f2                	mov    %esi,%edx
f01015a2:	eb 09                	jmp    f01015ad <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01015a4:	83 c2 01             	add    $0x1,%edx
f01015a7:	83 c1 01             	add    $0x1,%ecx
f01015aa:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01015ad:	39 c2                	cmp    %eax,%edx
f01015af:	74 09                	je     f01015ba <strlcpy+0x32>
f01015b1:	0f b6 19             	movzbl (%ecx),%ebx
f01015b4:	84 db                	test   %bl,%bl
f01015b6:	75 ec                	jne    f01015a4 <strlcpy+0x1c>
f01015b8:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f01015ba:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01015bd:	29 f0                	sub    %esi,%eax
}
f01015bf:	5b                   	pop    %ebx
f01015c0:	5e                   	pop    %esi
f01015c1:	5d                   	pop    %ebp
f01015c2:	c3                   	ret    

f01015c3 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01015c3:	55                   	push   %ebp
f01015c4:	89 e5                	mov    %esp,%ebp
f01015c6:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01015c9:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01015cc:	eb 06                	jmp    f01015d4 <strcmp+0x11>
		p++, q++;
f01015ce:	83 c1 01             	add    $0x1,%ecx
f01015d1:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01015d4:	0f b6 01             	movzbl (%ecx),%eax
f01015d7:	84 c0                	test   %al,%al
f01015d9:	74 04                	je     f01015df <strcmp+0x1c>
f01015db:	3a 02                	cmp    (%edx),%al
f01015dd:	74 ef                	je     f01015ce <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01015df:	0f b6 c0             	movzbl %al,%eax
f01015e2:	0f b6 12             	movzbl (%edx),%edx
f01015e5:	29 d0                	sub    %edx,%eax
}
f01015e7:	5d                   	pop    %ebp
f01015e8:	c3                   	ret    

f01015e9 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01015e9:	55                   	push   %ebp
f01015ea:	89 e5                	mov    %esp,%ebp
f01015ec:	53                   	push   %ebx
f01015ed:	8b 45 08             	mov    0x8(%ebp),%eax
f01015f0:	8b 55 0c             	mov    0xc(%ebp),%edx
f01015f3:	89 c3                	mov    %eax,%ebx
f01015f5:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01015f8:	eb 06                	jmp    f0101600 <strncmp+0x17>
		n--, p++, q++;
f01015fa:	83 c0 01             	add    $0x1,%eax
f01015fd:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101600:	39 d8                	cmp    %ebx,%eax
f0101602:	74 15                	je     f0101619 <strncmp+0x30>
f0101604:	0f b6 08             	movzbl (%eax),%ecx
f0101607:	84 c9                	test   %cl,%cl
f0101609:	74 04                	je     f010160f <strncmp+0x26>
f010160b:	3a 0a                	cmp    (%edx),%cl
f010160d:	74 eb                	je     f01015fa <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f010160f:	0f b6 00             	movzbl (%eax),%eax
f0101612:	0f b6 12             	movzbl (%edx),%edx
f0101615:	29 d0                	sub    %edx,%eax
f0101617:	eb 05                	jmp    f010161e <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101619:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f010161e:	5b                   	pop    %ebx
f010161f:	5d                   	pop    %ebp
f0101620:	c3                   	ret    

f0101621 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101621:	55                   	push   %ebp
f0101622:	89 e5                	mov    %esp,%ebp
f0101624:	8b 45 08             	mov    0x8(%ebp),%eax
f0101627:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010162b:	eb 07                	jmp    f0101634 <strchr+0x13>
		if (*s == c)
f010162d:	38 ca                	cmp    %cl,%dl
f010162f:	74 0f                	je     f0101640 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0101631:	83 c0 01             	add    $0x1,%eax
f0101634:	0f b6 10             	movzbl (%eax),%edx
f0101637:	84 d2                	test   %dl,%dl
f0101639:	75 f2                	jne    f010162d <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f010163b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101640:	5d                   	pop    %ebp
f0101641:	c3                   	ret    

f0101642 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101642:	55                   	push   %ebp
f0101643:	89 e5                	mov    %esp,%ebp
f0101645:	8b 45 08             	mov    0x8(%ebp),%eax
f0101648:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010164c:	eb 03                	jmp    f0101651 <strfind+0xf>
f010164e:	83 c0 01             	add    $0x1,%eax
f0101651:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0101654:	84 d2                	test   %dl,%dl
f0101656:	74 04                	je     f010165c <strfind+0x1a>
f0101658:	38 ca                	cmp    %cl,%dl
f010165a:	75 f2                	jne    f010164e <strfind+0xc>
			break;
	return (char *) s;
}
f010165c:	5d                   	pop    %ebp
f010165d:	c3                   	ret    

f010165e <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f010165e:	55                   	push   %ebp
f010165f:	89 e5                	mov    %esp,%ebp
f0101661:	57                   	push   %edi
f0101662:	56                   	push   %esi
f0101663:	53                   	push   %ebx
f0101664:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101667:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010166a:	85 c9                	test   %ecx,%ecx
f010166c:	74 36                	je     f01016a4 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010166e:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101674:	75 28                	jne    f010169e <memset+0x40>
f0101676:	f6 c1 03             	test   $0x3,%cl
f0101679:	75 23                	jne    f010169e <memset+0x40>
		c &= 0xFF;
f010167b:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010167f:	89 d3                	mov    %edx,%ebx
f0101681:	c1 e3 08             	shl    $0x8,%ebx
f0101684:	89 d6                	mov    %edx,%esi
f0101686:	c1 e6 18             	shl    $0x18,%esi
f0101689:	89 d0                	mov    %edx,%eax
f010168b:	c1 e0 10             	shl    $0x10,%eax
f010168e:	09 f0                	or     %esi,%eax
f0101690:	09 c2                	or     %eax,%edx
f0101692:	89 d0                	mov    %edx,%eax
f0101694:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0101696:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0101699:	fc                   	cld    
f010169a:	f3 ab                	rep stos %eax,%es:(%edi)
f010169c:	eb 06                	jmp    f01016a4 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010169e:	8b 45 0c             	mov    0xc(%ebp),%eax
f01016a1:	fc                   	cld    
f01016a2:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01016a4:	89 f8                	mov    %edi,%eax
f01016a6:	5b                   	pop    %ebx
f01016a7:	5e                   	pop    %esi
f01016a8:	5f                   	pop    %edi
f01016a9:	5d                   	pop    %ebp
f01016aa:	c3                   	ret    

f01016ab <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01016ab:	55                   	push   %ebp
f01016ac:	89 e5                	mov    %esp,%ebp
f01016ae:	57                   	push   %edi
f01016af:	56                   	push   %esi
f01016b0:	8b 45 08             	mov    0x8(%ebp),%eax
f01016b3:	8b 75 0c             	mov    0xc(%ebp),%esi
f01016b6:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01016b9:	39 c6                	cmp    %eax,%esi
f01016bb:	73 35                	jae    f01016f2 <memmove+0x47>
f01016bd:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01016c0:	39 d0                	cmp    %edx,%eax
f01016c2:	73 2e                	jae    f01016f2 <memmove+0x47>
		s += n;
		d += n;
f01016c4:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f01016c7:	89 d6                	mov    %edx,%esi
f01016c9:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01016cb:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01016d1:	75 13                	jne    f01016e6 <memmove+0x3b>
f01016d3:	f6 c1 03             	test   $0x3,%cl
f01016d6:	75 0e                	jne    f01016e6 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01016d8:	83 ef 04             	sub    $0x4,%edi
f01016db:	8d 72 fc             	lea    -0x4(%edx),%esi
f01016de:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f01016e1:	fd                   	std    
f01016e2:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01016e4:	eb 09                	jmp    f01016ef <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01016e6:	83 ef 01             	sub    $0x1,%edi
f01016e9:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01016ec:	fd                   	std    
f01016ed:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01016ef:	fc                   	cld    
f01016f0:	eb 1d                	jmp    f010170f <memmove+0x64>
f01016f2:	89 f2                	mov    %esi,%edx
f01016f4:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01016f6:	f6 c2 03             	test   $0x3,%dl
f01016f9:	75 0f                	jne    f010170a <memmove+0x5f>
f01016fb:	f6 c1 03             	test   $0x3,%cl
f01016fe:	75 0a                	jne    f010170a <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0101700:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0101703:	89 c7                	mov    %eax,%edi
f0101705:	fc                   	cld    
f0101706:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101708:	eb 05                	jmp    f010170f <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f010170a:	89 c7                	mov    %eax,%edi
f010170c:	fc                   	cld    
f010170d:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f010170f:	5e                   	pop    %esi
f0101710:	5f                   	pop    %edi
f0101711:	5d                   	pop    %ebp
f0101712:	c3                   	ret    

f0101713 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0101713:	55                   	push   %ebp
f0101714:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0101716:	ff 75 10             	pushl  0x10(%ebp)
f0101719:	ff 75 0c             	pushl  0xc(%ebp)
f010171c:	ff 75 08             	pushl  0x8(%ebp)
f010171f:	e8 87 ff ff ff       	call   f01016ab <memmove>
}
f0101724:	c9                   	leave  
f0101725:	c3                   	ret    

f0101726 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0101726:	55                   	push   %ebp
f0101727:	89 e5                	mov    %esp,%ebp
f0101729:	56                   	push   %esi
f010172a:	53                   	push   %ebx
f010172b:	8b 45 08             	mov    0x8(%ebp),%eax
f010172e:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101731:	89 c6                	mov    %eax,%esi
f0101733:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101736:	eb 1a                	jmp    f0101752 <memcmp+0x2c>
		if (*s1 != *s2)
f0101738:	0f b6 08             	movzbl (%eax),%ecx
f010173b:	0f b6 1a             	movzbl (%edx),%ebx
f010173e:	38 d9                	cmp    %bl,%cl
f0101740:	74 0a                	je     f010174c <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0101742:	0f b6 c1             	movzbl %cl,%eax
f0101745:	0f b6 db             	movzbl %bl,%ebx
f0101748:	29 d8                	sub    %ebx,%eax
f010174a:	eb 0f                	jmp    f010175b <memcmp+0x35>
		s1++, s2++;
f010174c:	83 c0 01             	add    $0x1,%eax
f010174f:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101752:	39 f0                	cmp    %esi,%eax
f0101754:	75 e2                	jne    f0101738 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0101756:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010175b:	5b                   	pop    %ebx
f010175c:	5e                   	pop    %esi
f010175d:	5d                   	pop    %ebp
f010175e:	c3                   	ret    

f010175f <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010175f:	55                   	push   %ebp
f0101760:	89 e5                	mov    %esp,%ebp
f0101762:	8b 45 08             	mov    0x8(%ebp),%eax
f0101765:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0101768:	89 c2                	mov    %eax,%edx
f010176a:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f010176d:	eb 07                	jmp    f0101776 <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f010176f:	38 08                	cmp    %cl,(%eax)
f0101771:	74 07                	je     f010177a <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0101773:	83 c0 01             	add    $0x1,%eax
f0101776:	39 d0                	cmp    %edx,%eax
f0101778:	72 f5                	jb     f010176f <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f010177a:	5d                   	pop    %ebp
f010177b:	c3                   	ret    

f010177c <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f010177c:	55                   	push   %ebp
f010177d:	89 e5                	mov    %esp,%ebp
f010177f:	57                   	push   %edi
f0101780:	56                   	push   %esi
f0101781:	53                   	push   %ebx
f0101782:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101785:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101788:	eb 03                	jmp    f010178d <strtol+0x11>
		s++;
f010178a:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010178d:	0f b6 01             	movzbl (%ecx),%eax
f0101790:	3c 09                	cmp    $0x9,%al
f0101792:	74 f6                	je     f010178a <strtol+0xe>
f0101794:	3c 20                	cmp    $0x20,%al
f0101796:	74 f2                	je     f010178a <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0101798:	3c 2b                	cmp    $0x2b,%al
f010179a:	75 0a                	jne    f01017a6 <strtol+0x2a>
		s++;
f010179c:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f010179f:	bf 00 00 00 00       	mov    $0x0,%edi
f01017a4:	eb 10                	jmp    f01017b6 <strtol+0x3a>
f01017a6:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01017ab:	3c 2d                	cmp    $0x2d,%al
f01017ad:	75 07                	jne    f01017b6 <strtol+0x3a>
		s++, neg = 1;
f01017af:	8d 49 01             	lea    0x1(%ecx),%ecx
f01017b2:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01017b6:	85 db                	test   %ebx,%ebx
f01017b8:	0f 94 c0             	sete   %al
f01017bb:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01017c1:	75 19                	jne    f01017dc <strtol+0x60>
f01017c3:	80 39 30             	cmpb   $0x30,(%ecx)
f01017c6:	75 14                	jne    f01017dc <strtol+0x60>
f01017c8:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01017cc:	0f 85 82 00 00 00    	jne    f0101854 <strtol+0xd8>
		s += 2, base = 16;
f01017d2:	83 c1 02             	add    $0x2,%ecx
f01017d5:	bb 10 00 00 00       	mov    $0x10,%ebx
f01017da:	eb 16                	jmp    f01017f2 <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f01017dc:	84 c0                	test   %al,%al
f01017de:	74 12                	je     f01017f2 <strtol+0x76>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01017e0:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01017e5:	80 39 30             	cmpb   $0x30,(%ecx)
f01017e8:	75 08                	jne    f01017f2 <strtol+0x76>
		s++, base = 8;
f01017ea:	83 c1 01             	add    $0x1,%ecx
f01017ed:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f01017f2:	b8 00 00 00 00       	mov    $0x0,%eax
f01017f7:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01017fa:	0f b6 11             	movzbl (%ecx),%edx
f01017fd:	8d 72 d0             	lea    -0x30(%edx),%esi
f0101800:	89 f3                	mov    %esi,%ebx
f0101802:	80 fb 09             	cmp    $0x9,%bl
f0101805:	77 08                	ja     f010180f <strtol+0x93>
			dig = *s - '0';
f0101807:	0f be d2             	movsbl %dl,%edx
f010180a:	83 ea 30             	sub    $0x30,%edx
f010180d:	eb 22                	jmp    f0101831 <strtol+0xb5>
		else if (*s >= 'a' && *s <= 'z')
f010180f:	8d 72 9f             	lea    -0x61(%edx),%esi
f0101812:	89 f3                	mov    %esi,%ebx
f0101814:	80 fb 19             	cmp    $0x19,%bl
f0101817:	77 08                	ja     f0101821 <strtol+0xa5>
			dig = *s - 'a' + 10;
f0101819:	0f be d2             	movsbl %dl,%edx
f010181c:	83 ea 57             	sub    $0x57,%edx
f010181f:	eb 10                	jmp    f0101831 <strtol+0xb5>
		else if (*s >= 'A' && *s <= 'Z')
f0101821:	8d 72 bf             	lea    -0x41(%edx),%esi
f0101824:	89 f3                	mov    %esi,%ebx
f0101826:	80 fb 19             	cmp    $0x19,%bl
f0101829:	77 16                	ja     f0101841 <strtol+0xc5>
			dig = *s - 'A' + 10;
f010182b:	0f be d2             	movsbl %dl,%edx
f010182e:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0101831:	3b 55 10             	cmp    0x10(%ebp),%edx
f0101834:	7d 0f                	jge    f0101845 <strtol+0xc9>
			break;
		s++, val = (val * base) + dig;
f0101836:	83 c1 01             	add    $0x1,%ecx
f0101839:	0f af 45 10          	imul   0x10(%ebp),%eax
f010183d:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f010183f:	eb b9                	jmp    f01017fa <strtol+0x7e>
f0101841:	89 c2                	mov    %eax,%edx
f0101843:	eb 02                	jmp    f0101847 <strtol+0xcb>
f0101845:	89 c2                	mov    %eax,%edx

	if (endptr)
f0101847:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010184b:	74 0d                	je     f010185a <strtol+0xde>
		*endptr = (char *) s;
f010184d:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101850:	89 0e                	mov    %ecx,(%esi)
f0101852:	eb 06                	jmp    f010185a <strtol+0xde>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101854:	84 c0                	test   %al,%al
f0101856:	75 92                	jne    f01017ea <strtol+0x6e>
f0101858:	eb 98                	jmp    f01017f2 <strtol+0x76>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f010185a:	f7 da                	neg    %edx
f010185c:	85 ff                	test   %edi,%edi
f010185e:	0f 45 c2             	cmovne %edx,%eax
}
f0101861:	5b                   	pop    %ebx
f0101862:	5e                   	pop    %esi
f0101863:	5f                   	pop    %edi
f0101864:	5d                   	pop    %ebp
f0101865:	c3                   	ret    

f0101866 <subtract_List_Operation>:
#include <inc/calculator.h>



void subtract_List_Operation(operantion op[])
{
f0101866:	55                   	push   %ebp
f0101867:	89 e5                	mov    %esp,%ebp
f0101869:	8b 55 08             	mov    0x8(%ebp),%edx
f010186c:	89 d0                	mov    %edx,%eax
f010186e:	83 c2 30             	add    $0x30,%edx
	int i;
	for (i = 0; i < 6; i++)
	{
		op[i].position = op[i].position - 1;
f0101871:	83 28 01             	subl   $0x1,(%eax)
f0101874:	83 c0 08             	add    $0x8,%eax


void subtract_List_Operation(operantion op[])
{
	int i;
	for (i = 0; i < 6; i++)
f0101877:	39 d0                	cmp    %edx,%eax
f0101879:	75 f6                	jne    f0101871 <subtract_List_Operation+0xb>
	{
		op[i].position = op[i].position - 1;
	}
}
f010187b:	5d                   	pop    %ebp
f010187c:	c3                   	ret    

f010187d <Isoperation>:

int Isoperation(char r)
{
f010187d:	55                   	push   %ebp
f010187e:	89 e5                	mov    %esp,%ebp
f0101880:	53                   	push   %ebx
f0101881:	83 ec 10             	sub    $0x10,%esp
f0101884:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("error inside is operation");
f0101887:	68 54 2b 10 f0       	push   $0xf0102b54
f010188c:	e8 c2 f1 ff ff       	call   f0100a53 <cprintf>
	if (r == '+' || r == '-' || r == '*' || r == '/' || r == '%')
f0101891:	89 d8                	mov    %ebx,%eax
f0101893:	83 e0 f7             	and    $0xfffffff7,%eax
f0101896:	83 c4 10             	add    $0x10,%esp
f0101899:	3c 25                	cmp    $0x25,%al
f010189b:	0f 94 c2             	sete   %dl
f010189e:	80 fb 2f             	cmp    $0x2f,%bl
f01018a1:	0f 94 c0             	sete   %al
f01018a4:	08 c2                	or     %al,%dl
f01018a6:	75 08                	jne    f01018b0 <Isoperation+0x33>
f01018a8:	83 eb 2a             	sub    $0x2a,%ebx
f01018ab:	80 fb 01             	cmp    $0x1,%bl
f01018ae:	77 17                	ja     f01018c7 <Isoperation+0x4a>
	{
				cprintf(" error inside isoperation : Return 1");
f01018b0:	83 ec 0c             	sub    $0xc,%esp
f01018b3:	68 44 2c 10 f0       	push   $0xf0102c44
f01018b8:	e8 96 f1 ff ff       	call   f0100a53 <cprintf>

		return 1;
f01018bd:	83 c4 10             	add    $0x10,%esp
f01018c0:	b8 01 00 00 00       	mov    $0x1,%eax
f01018c5:	eb 15                	jmp    f01018dc <Isoperation+0x5f>
	}
	else
	{
				cprintf(" error inside isoperation : Return 0");
f01018c7:	83 ec 0c             	sub    $0xc,%esp
f01018ca:	68 6c 2c 10 f0       	push   $0xf0102c6c
f01018cf:	e8 7f f1 ff ff       	call   f0100a53 <cprintf>

		return 0;
f01018d4:	83 c4 10             	add    $0x10,%esp
f01018d7:	b8 00 00 00 00       	mov    $0x0,%eax
	}
					cprintf(" error inside isoperation : Return 0");

	return 0;
}
f01018dc:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01018df:	c9                   	leave  
f01018e0:	c3                   	ret    

f01018e1 <Isnumber>:


int Isnumber(char r)
{
f01018e1:	55                   	push   %ebp
f01018e2:	89 e5                	mov    %esp,%ebp
f01018e4:	53                   	push   %ebx
f01018e5:	83 ec 0c             	sub    $0xc,%esp
f01018e8:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("%c",r);
f01018eb:	0f be c3             	movsbl %bl,%eax
f01018ee:	50                   	push   %eax
f01018ef:	68 a9 2b 10 f0       	push   $0xf0102ba9
f01018f4:	e8 5a f1 ff ff       	call   f0100a53 <cprintf>
	if (r >= '0' && r <= '9')
f01018f9:	83 eb 30             	sub    $0x30,%ebx
f01018fc:	83 c4 10             	add    $0x10,%esp
f01018ff:	80 fb 09             	cmp    $0x9,%bl
f0101902:	77 17                	ja     f010191b <Isnumber+0x3a>
	{
		cprintf(" error inside isnumber : Return 1");
f0101904:	83 ec 0c             	sub    $0xc,%esp
f0101907:	68 94 2c 10 f0       	push   $0xf0102c94
f010190c:	e8 42 f1 ff ff       	call   f0100a53 <cprintf>

		return 1;
f0101911:	83 c4 10             	add    $0x10,%esp
f0101914:	b8 01 00 00 00       	mov    $0x1,%eax
f0101919:	eb 15                	jmp    f0101930 <Isnumber+0x4f>
	}
	else
	{
	cprintf(" error inside isnumber : Return 0");
f010191b:	83 ec 0c             	sub    $0xc,%esp
f010191e:	68 b8 2c 10 f0       	push   $0xf0102cb8
f0101923:	e8 2b f1 ff ff       	call   f0100a53 <cprintf>

		return 0;
f0101928:	83 c4 10             	add    $0x10,%esp
f010192b:	b8 00 00 00 00       	mov    $0x0,%eax
	}
	return 0;

		cprintf(" error inside isnumber");
}
f0101930:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101933:	c9                   	leave  
f0101934:	c3                   	ret    

f0101935 <Isdot>:

int Isdot(char r)
{
f0101935:	55                   	push   %ebp
f0101936:	89 e5                	mov    %esp,%ebp
f0101938:	53                   	push   %ebx
f0101939:	83 ec 10             	sub    $0x10,%esp
f010193c:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("error inside isdot");
f010193f:	68 6e 2b 10 f0       	push   $0xf0102b6e
f0101944:	e8 0a f1 ff ff       	call   f0100a53 <cprintf>
	if (r == '.')
f0101949:	83 c4 10             	add    $0x10,%esp
f010194c:	80 fb 2e             	cmp    $0x2e,%bl
f010194f:	75 17                	jne    f0101968 <Isdot+0x33>
	{
				cprintf(" error inside Isdot : Return 1");
f0101951:	83 ec 0c             	sub    $0xc,%esp
f0101954:	68 dc 2c 10 f0       	push   $0xf0102cdc
f0101959:	e8 f5 f0 ff ff       	call   f0100a53 <cprintf>

		return 1;
f010195e:	83 c4 10             	add    $0x10,%esp
f0101961:	b8 01 00 00 00       	mov    $0x1,%eax
f0101966:	eb 15                	jmp    f010197d <Isdot+0x48>
	}
	else
	{
			cprintf(" error inside Isdot : Return 0");
f0101968:	83 ec 0c             	sub    $0xc,%esp
f010196b:	68 fc 2c 10 f0       	push   $0xf0102cfc
f0101970:	e8 de f0 ff ff       	call   f0100a53 <cprintf>

		return 0;
f0101975:	83 c4 10             	add    $0x10,%esp
f0101978:	b8 00 00 00 00       	mov    $0x0,%eax
	}
				cprintf(" error inside Isdot : Return 0");

	return 0;

}
f010197d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101980:	c9                   	leave  
f0101981:	c3                   	ret    

f0101982 <removeItem>:

void removeItem(float str[], int location)
{
f0101982:	55                   	push   %ebp
f0101983:	89 e5                	mov    %esp,%ebp
f0101985:	8b 55 08             	mov    0x8(%ebp),%edx
f0101988:	8b 45 0c             	mov    0xc(%ebp),%eax
	int i;

	for (i = location; i < 6; i++)
f010198b:	eb 0a                	jmp    f0101997 <removeItem+0x15>
	{
		str[i] = str[i + 1];
f010198d:	d9 44 82 04          	flds   0x4(%edx,%eax,4)
f0101991:	d9 1c 82             	fstps  (%edx,%eax,4)

void removeItem(float str[], int location)
{
	int i;

	for (i = location; i < 6; i++)
f0101994:	83 c0 01             	add    $0x1,%eax
f0101997:	83 f8 05             	cmp    $0x5,%eax
f010199a:	7e f1                	jle    f010198d <removeItem+0xb>
	{
		str[i] = str[i + 1];
	}

	str[6] = 0;
f010199c:	c7 42 18 00 00 00 00 	movl   $0x0,0x18(%edx)

}
f01019a3:	5d                   	pop    %ebp
f01019a4:	c3                   	ret    

f01019a5 <clearnumber>:

void clearnumber(char * number)
{
f01019a5:	55                   	push   %ebp
f01019a6:	89 e5                	mov    %esp,%ebp
f01019a8:	56                   	push   %esi
f01019a9:	53                   	push   %ebx
f01019aa:	8b 75 08             	mov    0x8(%ebp),%esi

	int i = 0;
	for (i = 0; i < strlen(number); i++)
f01019ad:	bb 00 00 00 00       	mov    $0x0,%ebx
f01019b2:	eb 07                	jmp    f01019bb <clearnumber+0x16>
	{
		number[i] = '0';
f01019b4:	c6 04 1e 30          	movb   $0x30,(%esi,%ebx,1)

void clearnumber(char * number)
{

	int i = 0;
	for (i = 0; i < strlen(number); i++)
f01019b8:	83 c3 01             	add    $0x1,%ebx
f01019bb:	83 ec 0c             	sub    $0xc,%esp
f01019be:	56                   	push   %esi
f01019bf:	e8 1c fb ff ff       	call   f01014e0 <strlen>
f01019c4:	83 c4 10             	add    $0x10,%esp
f01019c7:	39 c3                	cmp    %eax,%ebx
f01019c9:	7c e9                	jl     f01019b4 <clearnumber+0xf>
	{
		number[i] = '0';
	}
	number[strlen(number)] = '\0';
f01019cb:	83 ec 0c             	sub    $0xc,%esp
f01019ce:	56                   	push   %esi
f01019cf:	e8 0c fb ff ff       	call   f01014e0 <strlen>
f01019d4:	c6 04 06 00          	movb   $0x0,(%esi,%eax,1)
f01019d8:	83 c4 10             	add    $0x10,%esp
}
f01019db:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01019de:	5b                   	pop    %ebx
f01019df:	5e                   	pop    %esi
f01019e0:	5d                   	pop    %ebp
f01019e1:	c3                   	ret    

f01019e2 <Getnumber>:


Float Getnumber(char* str, int *i)
{
f01019e2:	55                   	push   %ebp
f01019e3:	89 e5                	mov    %esp,%ebp
f01019e5:	57                   	push   %edi
f01019e6:	56                   	push   %esi
f01019e7:	53                   	push   %ebx
f01019e8:	81 ec 98 00 00 00    	sub    $0x98,%esp
f01019ee:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01019f1:	8b 75 10             	mov    0x10(%ebp),%esi
	Float Value;
	int dot = 1;
	int y = 1;
	char number[100];
	number[strlen(str)] = '\0';
f01019f4:	53                   	push   %ebx
f01019f5:	e8 e6 fa ff ff       	call   f01014e0 <strlen>
f01019fa:	c6 44 05 84 00       	movb   $0x0,-0x7c(%ebp,%eax,1)
	clearnumber(number);
f01019ff:	8d 45 84             	lea    -0x7c(%ebp),%eax
f0101a02:	89 04 24             	mov    %eax,(%esp)
f0101a05:	e8 9b ff ff ff       	call   f01019a5 <clearnumber>
	number[0] = str[*i];
f0101a0a:	8b 06                	mov    (%esi),%eax
f0101a0c:	0f b6 04 03          	movzbl (%ebx,%eax,1),%eax
f0101a10:	88 45 84             	mov    %al,-0x7c(%ebp)
	*i++;
	cprintf("%d",strlen(str));
f0101a13:	89 1c 24             	mov    %ebx,(%esp)
f0101a16:	e8 c5 fa ff ff       	call   f01014e0 <strlen>
f0101a1b:	83 c4 08             	add    $0x8,%esp
f0101a1e:	50                   	push   %eax
f0101a1f:	68 33 29 10 f0       	push   $0xf0102933
f0101a24:	e8 2a f0 ff ff       	call   f0100a53 <cprintf>
	while (*i < strlen(str))
f0101a29:	8b 7e 04             	mov    0x4(%esi),%edi
f0101a2c:	89 1c 24             	mov    %ebx,(%esp)
f0101a2f:	e8 ac fa ff ff       	call   f01014e0 <strlen>
f0101a34:	83 c4 10             	add    $0x10,%esp
f0101a37:	39 c7                	cmp    %eax,%edi
f0101a39:	0f 8d ec 00 00 00    	jge    f0101b2b <Getnumber+0x149>
	{
		cprintf("inside Getnumber loop");
f0101a3f:	83 ec 0c             	sub    $0xc,%esp
f0101a42:	68 81 2b 10 f0       	push   $0xf0102b81
f0101a47:	e8 07 f0 ff ff       	call   f0100a53 <cprintf>
		cprintf("Isnumber Argument %c",str[*i]);
f0101a4c:	83 c4 08             	add    $0x8,%esp
f0101a4f:	8b 46 04             	mov    0x4(%esi),%eax
f0101a52:	0f be 04 03          	movsbl (%ebx,%eax,1),%eax
f0101a56:	50                   	push   %eax
f0101a57:	68 97 2b 10 f0       	push   $0xf0102b97
f0101a5c:	e8 f2 ef ff ff       	call   f0100a53 <cprintf>
		if (Isnumber(str[*i]))
f0101a61:	8b 46 04             	mov    0x4(%esi),%eax
f0101a64:	0f be 04 03          	movsbl (%ebx,%eax,1),%eax
f0101a68:	89 04 24             	mov    %eax,(%esp)
f0101a6b:	e8 71 fe ff ff       	call   f01018e1 <Isnumber>
f0101a70:	83 c4 10             	add    $0x10,%esp
f0101a73:	85 c0                	test   %eax,%eax
f0101a75:	75 0a                	jne    f0101a81 <Getnumber+0x9f>
	int y = 1;
	char number[100];
	number[strlen(str)] = '\0';
	clearnumber(number);
	number[0] = str[*i];
	*i++;
f0101a77:	83 c6 04             	add    $0x4,%esi

Float Getnumber(char* str, int *i)
{
	Float Value;
	int dot = 1;
	int y = 1;
f0101a7a:	bf 01 00 00 00       	mov    $0x1,%edi
f0101a7f:	eb 22                	jmp    f0101aa3 <Getnumber+0xc1>
	{
		cprintf("inside Getnumber loop");
		cprintf("Isnumber Argument %c",str[*i]);
		if (Isnumber(str[*i]))
		{
			cprintf("first number");
f0101a81:	83 ec 0c             	sub    $0xc,%esp
f0101a84:	68 ac 2b 10 f0       	push   $0xf0102bac
f0101a89:	e8 c5 ef ff ff       	call   f0100a53 <cprintf>
			number[y] = str[*i];
f0101a8e:	8b 46 04             	mov    0x4(%esi),%eax
f0101a91:	0f b6 04 03          	movzbl (%ebx,%eax,1),%eax
f0101a95:	88 45 85             	mov    %al,-0x7b(%ebp)
			y++;
			*i++;
f0101a98:	83 c6 08             	add    $0x8,%esi
f0101a9b:	83 c4 10             	add    $0x10,%esp
		cprintf("Isnumber Argument %c",str[*i]);
		if (Isnumber(str[*i]))
		{
			cprintf("first number");
			number[y] = str[*i];
			y++;
f0101a9e:	bf 02 00 00 00       	mov    $0x2,%edi
			*i++;
		}
		cprintf("is a dot error");
f0101aa3:	83 ec 0c             	sub    $0xc,%esp
f0101aa6:	68 b9 2b 10 f0       	push   $0xf0102bb9
f0101aab:	e8 a3 ef ff ff       	call   f0100a53 <cprintf>
		if (Isdot((str[*i])) && dot)
f0101ab0:	8b 06                	mov    (%esi),%eax
f0101ab2:	0f be 04 03          	movsbl (%ebx,%eax,1),%eax
f0101ab6:	89 04 24             	mov    %eax,(%esp)
f0101ab9:	e8 77 fe ff ff       	call   f0101935 <Isdot>
f0101abe:	83 c4 10             	add    $0x10,%esp
f0101ac1:	85 c0                	test   %eax,%eax
f0101ac3:	0f 84 ce 00 00 00    	je     f0101b97 <Getnumber+0x1b5>
		{
			cprintf("is a dot");
f0101ac9:	83 ec 0c             	sub    $0xc,%esp
f0101acc:	68 c8 2b 10 f0       	push   $0xf0102bc8
f0101ad1:	e8 7d ef ff ff       	call   f0100a53 <cprintf>

			number[y] = str[*i];
f0101ad6:	8b 06                	mov    (%esi),%eax
f0101ad8:	0f b6 04 03          	movzbl (%ebx,%eax,1),%eax
f0101adc:	88 44 3d 84          	mov    %al,-0x7c(%ebp,%edi,1)
			dot--;
			y++;
			*i++;
		}
		cprintf("isoperation error");
f0101ae0:	c7 04 24 d1 2b 10 f0 	movl   $0xf0102bd1,(%esp)
f0101ae7:	e8 67 ef ff ff       	call   f0100a53 <cprintf>
		if ( Isoperation(str[*i]) )
f0101aec:	8b 46 04             	mov    0x4(%esi),%eax
f0101aef:	0f be 04 03          	movsbl (%ebx,%eax,1),%eax
f0101af3:	89 04 24             	mov    %eax,(%esp)
f0101af6:	e8 82 fd ff ff       	call   f010187d <Isoperation>
f0101afb:	83 c4 10             	add    $0x10,%esp
f0101afe:	85 c0                	test   %eax,%eax
f0101b00:	0f 85 b8 00 00 00    	jne    f0101bbe <Getnumber+0x1dc>
		         	number[y] = '.';
			    }
		            break;
			}

			cprintf("get number error inside Getnuber");
f0101b06:	83 ec 0c             	sub    $0xc,%esp
f0101b09:	68 1c 2d 10 f0       	push   $0xf0102d1c
f0101b0e:	e8 40 ef ff ff       	call   f0100a53 <cprintf>
			Value.error = 1;
			Value.number = 1;
			return Value;
f0101b13:	8b 45 08             	mov    0x8(%ebp),%eax
f0101b16:	c7 00 00 00 80 3f    	movl   $0x3f800000,(%eax)
f0101b1c:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
f0101b23:	83 c4 10             	add    $0x10,%esp
f0101b26:	e9 a8 00 00 00       	jmp    f0101bd3 <Getnumber+0x1f1>
	}
	cprintf("*i > strlen(str)");
f0101b2b:	83 ec 0c             	sub    $0xc,%esp
f0101b2e:	68 e3 2b 10 f0       	push   $0xf0102be3
f0101b33:	e8 1b ef ff ff       	call   f0100a53 <cprintf>
	Value = char_to_float(number);
f0101b38:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
f0101b3e:	83 c4 08             	add    $0x8,%esp
f0101b41:	8d 55 84             	lea    -0x7c(%ebp),%edx
f0101b44:	52                   	push   %edx
f0101b45:	50                   	push   %eax
f0101b46:	e8 5d 04 00 00       	call   f0101fa8 <char_to_float>
f0101b4b:	8b b5 74 ff ff ff    	mov    -0x8c(%ebp),%esi
f0101b51:	8b 9d 70 ff ff ff    	mov    -0x90(%ebp),%ebx
	cprintf("the returned float %f",Value.number);
f0101b57:	83 ec 10             	sub    $0x10,%esp
f0101b5a:	89 9d 6c ff ff ff    	mov    %ebx,-0x94(%ebp)
f0101b60:	d9 85 6c ff ff ff    	flds   -0x94(%ebp)
f0101b66:	dd 1c 24             	fstpl  (%esp)
f0101b69:	68 f4 2b 10 f0       	push   $0xf0102bf4
f0101b6e:	e8 e0 ee ff ff       	call   f0100a53 <cprintf>
	return Value;
f0101b73:	8b 45 08             	mov    0x8(%ebp),%eax
f0101b76:	89 18                	mov    %ebx,(%eax)
f0101b78:	89 70 04             	mov    %esi,0x4(%eax)
f0101b7b:	83 c4 20             	add    $0x20,%esp
f0101b7e:	eb 53                	jmp    f0101bd3 <Getnumber+0x1f1>
			*i++;
		}
		cprintf("isoperation error");
		if ( Isoperation(str[*i]) )
	        {
			    cprintf("is operation");
f0101b80:	83 ec 0c             	sub    $0xc,%esp
f0101b83:	68 61 2b 10 f0       	push   $0xf0102b61
f0101b88:	e8 c6 ee ff ff       	call   f0100a53 <cprintf>

				if (dot)
			    {
		         	number[y] = '.';
f0101b8d:	c6 44 3d 84 2e       	movb   $0x2e,-0x7c(%ebp,%edi,1)
f0101b92:	83 c4 10             	add    $0x10,%esp
f0101b95:	eb 94                	jmp    f0101b2b <Getnumber+0x149>
			number[y] = str[*i];
			dot--;
			y++;
			*i++;
		}
		cprintf("isoperation error");
f0101b97:	83 ec 0c             	sub    $0xc,%esp
f0101b9a:	68 d1 2b 10 f0       	push   $0xf0102bd1
f0101b9f:	e8 af ee ff ff       	call   f0100a53 <cprintf>
		if ( Isoperation(str[*i]) )
f0101ba4:	8b 06                	mov    (%esi),%eax
f0101ba6:	0f be 04 03          	movsbl (%ebx,%eax,1),%eax
f0101baa:	89 04 24             	mov    %eax,(%esp)
f0101bad:	e8 cb fc ff ff       	call   f010187d <Isoperation>
f0101bb2:	83 c4 10             	add    $0x10,%esp
f0101bb5:	85 c0                	test   %eax,%eax
f0101bb7:	75 c7                	jne    f0101b80 <Getnumber+0x19e>
f0101bb9:	e9 48 ff ff ff       	jmp    f0101b06 <Getnumber+0x124>
	        {
			    cprintf("is operation");
f0101bbe:	83 ec 0c             	sub    $0xc,%esp
f0101bc1:	68 61 2b 10 f0       	push   $0xf0102b61
f0101bc6:	e8 88 ee ff ff       	call   f0100a53 <cprintf>
f0101bcb:	83 c4 10             	add    $0x10,%esp
f0101bce:	e9 58 ff ff ff       	jmp    f0101b2b <Getnumber+0x149>
	}
	cprintf("*i > strlen(str)");
	Value = char_to_float(number);
	cprintf("the returned float %f",Value.number);
	return Value;
}
f0101bd3:	8b 45 08             	mov    0x8(%ebp),%eax
f0101bd6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101bd9:	5b                   	pop    %ebx
f0101bda:	5e                   	pop    %esi
f0101bdb:	5f                   	pop    %edi
f0101bdc:	5d                   	pop    %ebp
f0101bdd:	c2 04 00             	ret    $0x4

f0101be0 <GetOperation>:

Char GetOperation(char* str, int i)
{
f0101be0:	55                   	push   %ebp
f0101be1:	89 e5                	mov    %esp,%ebp
f0101be3:	53                   	push   %ebx
f0101be4:	8b 45 08             	mov    0x8(%ebp),%eax
	Char operat;
	if (str[i] == '-' || str[i] == '+' || str[i] == '*' || str[i] == '/' || str[i] == '%')
f0101be7:	8b 55 10             	mov    0x10(%ebp),%edx
f0101bea:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101bed:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0101bf1:	89 d1                	mov    %edx,%ecx
f0101bf3:	83 e1 f7             	and    $0xfffffff7,%ecx
f0101bf6:	80 f9 25             	cmp    $0x25,%cl
f0101bf9:	0f 94 c3             	sete   %bl
f0101bfc:	80 fa 2f             	cmp    $0x2f,%dl
f0101bff:	0f 94 c1             	sete   %cl
f0101c02:	08 cb                	or     %cl,%bl
f0101c04:	75 08                	jne    f0101c0e <GetOperation+0x2e>
f0101c06:	8d 4a d6             	lea    -0x2a(%edx),%ecx
f0101c09:	80 f9 01             	cmp    $0x1,%cl
f0101c0c:	77 0b                	ja     f0101c19 <GetOperation+0x39>
	{
		operat.error = 0;
		operat.value = str[i];
		return operat;
f0101c0e:	88 10                	mov    %dl,(%eax)
f0101c10:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
f0101c17:	eb 0a                	jmp    f0101c23 <GetOperation+0x43>
	}
	else
	{
		operat.error = 1;
		operat.value = '0';
		return operat;
f0101c19:	c6 00 30             	movb   $0x30,(%eax)
f0101c1c:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
	}

}
f0101c23:	5b                   	pop    %ebx
f0101c24:	5d                   	pop    %ebp
f0101c25:	c2 04 00             	ret    $0x4

f0101c28 <calc>:

void calc(float numbers[], operantion op[])
{
f0101c28:	55                   	push   %ebp
f0101c29:	89 e5                	mov    %esp,%ebp
f0101c2b:	57                   	push   %edi
f0101c2c:	56                   	push   %esi
f0101c2d:	53                   	push   %ebx
f0101c2e:	83 ec 1c             	sub    $0x1c,%esp
f0101c31:	8b 75 08             	mov    0x8(%ebp),%esi
f0101c34:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0101c37:	89 fb                	mov    %edi,%ebx
f0101c39:	8d 47 30             	lea    0x30(%edi),%eax
f0101c3c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101c3f:	89 da                	mov    %ebx,%edx
	int i;

	for (i = 0; i < 6; i++)
	{
		if (op[i].operant == '*')
f0101c41:	0f b6 43 04          	movzbl 0x4(%ebx),%eax
f0101c45:	3c 2a                	cmp    $0x2a,%al
f0101c47:	75 19                	jne    f0101c62 <calc+0x3a>
		{
			numbers[op[i].position - 1] = numbers[op[i].position - 1] * numbers[op[i].position];
f0101c49:	8b 03                	mov    (%ebx),%eax
f0101c4b:	8d 0c 85 fc ff ff ff 	lea    -0x4(,%eax,4),%ecx
f0101c52:	8d 04 0e             	lea    (%esi,%ecx,1),%eax
f0101c55:	d9 00                	flds   (%eax)
f0101c57:	d8 4c 0e 04          	fmuls  0x4(%esi,%ecx,1)
f0101c5b:	d9 18                	fstps  (%eax)
f0101c5d:	e9 90 00 00 00       	jmp    f0101cf2 <calc+0xca>

		}
		else if (op[i].operant == '/')
f0101c62:	3c 2f                	cmp    $0x2f,%al
f0101c64:	75 42                	jne    f0101ca8 <calc+0x80>
		{
			if (numbers[op[i].position == 0])
f0101c66:	8b 0b                	mov    (%ebx),%ecx
f0101c68:	83 f9 01             	cmp    $0x1,%ecx
f0101c6b:	19 c0                	sbb    %eax,%eax
f0101c6d:	83 e0 04             	and    $0x4,%eax
f0101c70:	d9 04 06             	flds   (%esi,%eax,1)
f0101c73:	d9 ee                	fldz   
f0101c75:	d9 c9                	fxch   %st(1)
f0101c77:	df e9                	fucomip %st(1),%st
f0101c79:	dd d8                	fstp   %st(0)
f0101c7b:	7a 02                	jp     f0101c7f <calc+0x57>
f0101c7d:	74 15                	je     f0101c94 <calc+0x6c>
			{
				cprintf("error");
f0101c7f:	83 ec 0c             	sub    $0xc,%esp
f0101c82:	68 45 29 10 f0       	push   $0xf0102945
f0101c87:	e8 c7 ed ff ff       	call   f0100a53 <cprintf>
				return;
f0101c8c:	83 c4 10             	add    $0x10,%esp
f0101c8f:	e9 a0 00 00 00       	jmp    f0101d34 <calc+0x10c>
			}
			numbers[op[i].position - 1] = numbers[op[i].position - 1] / numbers[op[i].position];
f0101c94:	8d 0c 8d fc ff ff ff 	lea    -0x4(,%ecx,4),%ecx
f0101c9b:	8d 04 0e             	lea    (%esi,%ecx,1),%eax
f0101c9e:	d9 00                	flds   (%eax)
f0101ca0:	d8 74 0e 04          	fdivs  0x4(%esi,%ecx,1)
f0101ca4:	d9 18                	fstps  (%eax)
f0101ca6:	eb 4a                	jmp    f0101cf2 <calc+0xca>
		}
		else if (op[i].operant == '%')
f0101ca8:	3c 25                	cmp    $0x25,%al
f0101caa:	74 09                	je     f0101cb5 <calc+0x8d>
		{
			if (numbers[op[i].position == 0])
f0101cac:	d9 ee                	fldz   
f0101cae:	b8 00 00 00 00       	mov    $0x0,%eax
f0101cb3:	eb 61                	jmp    f0101d16 <calc+0xee>
f0101cb5:	8b 0b                	mov    (%ebx),%ecx
f0101cb7:	83 f9 01             	cmp    $0x1,%ecx
f0101cba:	19 c0                	sbb    %eax,%eax
f0101cbc:	83 e0 04             	and    $0x4,%eax
f0101cbf:	d9 04 06             	flds   (%esi,%eax,1)
f0101cc2:	d9 ee                	fldz   
f0101cc4:	d9 c9                	fxch   %st(1)
f0101cc6:	df e9                	fucomip %st(1),%st
f0101cc8:	dd d8                	fstp   %st(0)
f0101cca:	7a 02                	jp     f0101cce <calc+0xa6>
f0101ccc:	74 12                	je     f0101ce0 <calc+0xb8>
			{
				cprintf("error");
f0101cce:	83 ec 0c             	sub    $0xc,%esp
f0101cd1:	68 45 29 10 f0       	push   $0xf0102945
f0101cd6:	e8 78 ed ff ff       	call   f0100a53 <cprintf>
				return;
f0101cdb:	83 c4 10             	add    $0x10,%esp
f0101cde:	eb 54                	jmp    f0101d34 <calc+0x10c>
			}
		int y = (int)(numbers[op[i].position - 1] / numbers[op[i].position]);
		numbers[op[i].position - 1] = numbers[op[i].position - 1] / numbers[op[i].position];
f0101ce0:	8d 0c 8d fc ff ff ff 	lea    -0x4(,%ecx,4),%ecx
f0101ce7:	8d 04 0e             	lea    (%esi,%ecx,1),%eax
f0101cea:	d9 00                	flds   (%eax)
f0101cec:	d8 74 0e 04          	fdivs  0x4(%esi,%ecx,1)
f0101cf0:	d9 18                	fstps  (%eax)
		}
		else{ break; }
		removeItem(numbers, op[i].position);
f0101cf2:	83 ec 08             	sub    $0x8,%esp
f0101cf5:	ff 32                	pushl  (%edx)
f0101cf7:	56                   	push   %esi
f0101cf8:	e8 85 fc ff ff       	call   f0101982 <removeItem>
		subtract_List_Operation(op);
f0101cfd:	89 3c 24             	mov    %edi,(%esp)
f0101d00:	e8 61 fb ff ff       	call   f0101866 <subtract_List_Operation>
f0101d05:	83 c3 08             	add    $0x8,%ebx

void calc(float numbers[], operantion op[])
{
	int i;

	for (i = 0; i < 6; i++)
f0101d08:	83 c4 10             	add    $0x10,%esp
f0101d0b:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f0101d0e:	0f 85 2b ff ff ff    	jne    f0101c3f <calc+0x17>
f0101d14:	eb 96                	jmp    f0101cac <calc+0x84>
	}
	float result;
	result = 0;
	for (i = 0; i < sizeof(numbers); i++)
	{
		result = result + numbers[i];
f0101d16:	d8 04 86             	fadds  (%esi,%eax,4)
		removeItem(numbers, op[i].position);
		subtract_List_Operation(op);
	}
	float result;
	result = 0;
	for (i = 0; i < sizeof(numbers); i++)
f0101d19:	83 c0 01             	add    $0x1,%eax
f0101d1c:	83 f8 04             	cmp    $0x4,%eax
f0101d1f:	75 f5                	jne    f0101d16 <calc+0xee>
	{
		result = result + numbers[i];
	}
	cprintf("%f", result);
f0101d21:	83 ec 0c             	sub    $0xc,%esp
f0101d24:	dd 1c 24             	fstpl  (%esp)
f0101d27:	68 b8 26 10 f0       	push   $0xf01026b8
f0101d2c:	e8 22 ed ff ff       	call   f0100a53 <cprintf>
f0101d31:	83 c4 10             	add    $0x10,%esp

}
f0101d34:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101d37:	5b                   	pop    %ebx
f0101d38:	5e                   	pop    %esi
f0101d39:	5f                   	pop    %edi
f0101d3a:	5d                   	pop    %ebp
f0101d3b:	c3                   	ret    

f0101d3c <calculator>:

int calculator()
{
f0101d3c:	55                   	push   %ebp
f0101d3d:	89 e5                	mov    %esp,%ebp
f0101d3f:	57                   	push   %edi
f0101d40:	56                   	push   %esi
f0101d41:	53                   	push   %ebx
f0101d42:	81 ec 7c 01 00 00    	sub    $0x17c,%esp

	operantion oper;
	oper.operant = '0';
	oper.position = 0;

	for (i = 0; i < 6; i++)
f0101d48:	b8 00 00 00 00       	mov    $0x0,%eax
	{
		numericop[i].operant ='0';
f0101d4d:	c6 44 c5 a0 30       	movb   $0x30,-0x60(%ebp,%eax,8)
		numericop[i].position = 0 ;
f0101d52:	c7 44 c5 9c 00 00 00 	movl   $0x0,-0x64(%ebp,%eax,8)
f0101d59:	00 

	operantion oper;
	oper.operant = '0';
	oper.position = 0;

	for (i = 0; i < 6; i++)
f0101d5a:	83 c0 01             	add    $0x1,%eax
f0101d5d:	83 f8 05             	cmp    $0x5,%eax
f0101d60:	7e eb                	jle    f0101d4d <calculator+0x11>
f0101d62:	89 45 cc             	mov    %eax,-0x34(%ebp)
	{
		numericop[i].operant ='0';
		numericop[i].position = 0 ;
	}
	cprintf("Expression:");
f0101d65:	83 ec 0c             	sub    $0xc,%esp
f0101d68:	68 0a 2c 10 f0       	push   $0xf0102c0a
f0101d6d:	e8 e1 ec ff ff       	call   f0100a53 <cprintf>
	char *op  = readline("");
f0101d72:	c7 04 24 0f 24 10 f0 	movl   $0xf010240f,(%esp)
f0101d79:	e8 89 f6 ff ff       	call   f0101407 <readline>
f0101d7e:	89 c6                	mov    %eax,%esi
	char number[256];
	number[strlen(op)] = '\0';
f0101d80:	89 04 24             	mov    %eax,(%esp)
f0101d83:	e8 58 f7 ff ff       	call   f01014e0 <strlen>
f0101d88:	c6 84 05 9c fe ff ff 	movb   $0x0,-0x164(%ebp,%eax,1)
f0101d8f:	00 
	clearnumber(number);
f0101d90:	8d 85 9c fe ff ff    	lea    -0x164(%ebp),%eax
f0101d96:	89 04 24             	mov    %eax,(%esp)
f0101d99:	e8 07 fc ff ff       	call   f01019a5 <clearnumber>
	i = 0;
f0101d9e:	c7 45 cc 00 00 00 00 	movl   $0x0,-0x34(%ebp)
	if (!(op[0] != '-' || Isnumber(op[0])))
f0101da5:	83 c4 10             	add    $0x10,%esp
f0101da8:	80 3e 2d             	cmpb   $0x2d,(%esi)
f0101dab:	75 2b                	jne    f0101dd8 <calculator+0x9c>
f0101dad:	83 ec 0c             	sub    $0xc,%esp
f0101db0:	6a 2d                	push   $0x2d
f0101db2:	e8 2a fb ff ff       	call   f01018e1 <Isnumber>
f0101db7:	83 c4 10             	add    $0x10,%esp
f0101dba:	85 c0                	test   %eax,%eax
f0101dbc:	75 1a                	jne    f0101dd8 <calculator+0x9c>
	{
		cprintf("error");
f0101dbe:	83 ec 0c             	sub    $0xc,%esp
f0101dc1:	68 45 29 10 f0       	push   $0xf0102945
f0101dc6:	e8 88 ec ff ff       	call   f0100a53 <cprintf>
		return -1;
f0101dcb:	83 c4 10             	add    $0x10,%esp
f0101dce:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101dd3:	e9 96 01 00 00       	jmp    f0101f6e <calculator+0x232>
	}
	if (!(Isnumber(op[strlen(op) - 1]) || Isdot(op[strlen(op) - 1])))
f0101dd8:	83 ec 0c             	sub    $0xc,%esp
f0101ddb:	56                   	push   %esi
f0101ddc:	e8 ff f6 ff ff       	call   f01014e0 <strlen>
f0101de1:	0f be 44 06 ff       	movsbl -0x1(%esi,%eax,1),%eax
f0101de6:	89 04 24             	mov    %eax,(%esp)
f0101de9:	e8 f3 fa ff ff       	call   f01018e1 <Isnumber>
f0101dee:	83 c4 10             	add    $0x10,%esp
f0101df1:	85 c0                	test   %eax,%eax
f0101df3:	74 1a                	je     f0101e0f <calculator+0xd3>

	operantion oper;
	oper.operant = '0';
	oper.position = 0;

	for (i = 0; i < 6; i++)
f0101df5:	c7 85 84 fe ff ff 00 	movl   $0x0,-0x17c(%ebp)
f0101dfc:	00 00 00 
f0101dff:	bf 01 00 00 00       	mov    $0x1,%edi
	}

	while (i < strlen(op))
	{
		cprintf("inside the main loop, no errors \n");
		Float answer_num = Getnumber(op, &i);
f0101e04:	8d 9d 90 fe ff ff    	lea    -0x170(%ebp),%ebx
f0101e0a:	e9 32 01 00 00       	jmp    f0101f41 <calculator+0x205>
	if (!(op[0] != '-' || Isnumber(op[0])))
	{
		cprintf("error");
		return -1;
	}
	if (!(Isnumber(op[strlen(op) - 1]) || Isdot(op[strlen(op) - 1])))
f0101e0f:	83 ec 0c             	sub    $0xc,%esp
f0101e12:	56                   	push   %esi
f0101e13:	e8 c8 f6 ff ff       	call   f01014e0 <strlen>
f0101e18:	0f be 44 06 ff       	movsbl -0x1(%esi,%eax,1),%eax
f0101e1d:	89 04 24             	mov    %eax,(%esp)
f0101e20:	e8 10 fb ff ff       	call   f0101935 <Isdot>
f0101e25:	83 c4 10             	add    $0x10,%esp
f0101e28:	85 c0                	test   %eax,%eax
f0101e2a:	75 c9                	jne    f0101df5 <calculator+0xb9>
	{
		cprintf("error");
f0101e2c:	83 ec 0c             	sub    $0xc,%esp
f0101e2f:	68 45 29 10 f0       	push   $0xf0102945
f0101e34:	e8 1a ec ff ff       	call   f0100a53 <cprintf>
		return -1;
f0101e39:	83 c4 10             	add    $0x10,%esp
f0101e3c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101e41:	e9 28 01 00 00       	jmp    f0101f6e <calculator+0x232>
	}

	while (i < strlen(op))
	{
		cprintf("inside the main loop, no errors \n");
f0101e46:	83 ec 0c             	sub    $0xc,%esp
f0101e49:	68 40 2d 10 f0       	push   $0xf0102d40
f0101e4e:	e8 00 ec ff ff       	call   f0100a53 <cprintf>
		Float answer_num = Getnumber(op, &i);
f0101e53:	83 c4 0c             	add    $0xc,%esp
f0101e56:	8d 45 cc             	lea    -0x34(%ebp),%eax
f0101e59:	50                   	push   %eax
f0101e5a:	56                   	push   %esi
f0101e5b:	53                   	push   %ebx
f0101e5c:	e8 81 fb ff ff       	call   f01019e2 <Getnumber>
f0101e61:	8b 85 94 fe ff ff    	mov    -0x16c(%ebp),%eax
f0101e67:	89 85 8c fe ff ff    	mov    %eax,-0x174(%ebp)
f0101e6d:	d9 85 90 fe ff ff    	flds   -0x170(%ebp)
f0101e73:	d9 9d 88 fe ff ff    	fstps  -0x178(%ebp)
		cprintf("getnumber error solved");
f0101e79:	68 16 2c 10 f0       	push   $0xf0102c16
f0101e7e:	e8 d0 eb ff ff       	call   f0100a53 <cprintf>
		if (answer_num.error)
f0101e83:	83 c4 10             	add    $0x10,%esp
f0101e86:	83 bd 8c fe ff ff 00 	cmpl   $0x0,-0x174(%ebp)
f0101e8d:	74 15                	je     f0101ea4 <calculator+0x168>
		{
			cprintf("error");
f0101e8f:	83 ec 0c             	sub    $0xc,%esp
f0101e92:	68 45 29 10 f0       	push   $0xf0102945
f0101e97:	e8 b7 eb ff ff       	call   f0100a53 <cprintf>
			return -1;
f0101e9c:	83 c4 10             	add    $0x10,%esp
f0101e9f:	e9 96 00 00 00       	jmp    f0101f3a <calculator+0x1fe>
		}
		else
		{
			cprintf("in else in calculator");
f0101ea4:	83 ec 0c             	sub    $0xc,%esp
f0101ea7:	68 2d 2c 10 f0       	push   $0xf0102c2d
f0101eac:	e8 a2 eb ff ff       	call   f0100a53 <cprintf>
			A[numposition] = answer_num.number;
f0101eb1:	d9 85 88 fe ff ff    	flds   -0x178(%ebp)
f0101eb7:	d9 54 bd cc          	fsts   -0x34(%ebp,%edi,4)
			numposition++;
			cprintf("sucssecfuly got the float number %f",answer_num.number);
f0101ebb:	dd 5c 24 04          	fstpl  0x4(%esp)
f0101ebf:	c7 04 24 64 2d 10 f0 	movl   $0xf0102d64,(%esp)
f0101ec6:	e8 88 eb ff ff       	call   f0100a53 <cprintf>
		}
		if (i == strlen(op))
f0101ecb:	89 34 24             	mov    %esi,(%esp)
f0101ece:	e8 0d f6 ff ff       	call   f01014e0 <strlen>
f0101ed3:	8b 55 cc             	mov    -0x34(%ebp),%edx
f0101ed6:	83 c4 10             	add    $0x10,%esp
f0101ed9:	39 d0                	cmp    %edx,%eax
f0101edb:	74 79                	je     f0101f56 <calculator+0x21a>
		{
			break;
		}
		Char answer_char = GetOperation(op, i);
f0101edd:	83 ec 04             	sub    $0x4,%esp
f0101ee0:	52                   	push   %edx
f0101ee1:	56                   	push   %esi
f0101ee2:	53                   	push   %ebx
f0101ee3:	e8 f8 fc ff ff       	call   f0101be0 <GetOperation>
f0101ee8:	8b 85 90 fe ff ff    	mov    -0x170(%ebp),%eax
		if (answer_char.error)
f0101eee:	83 c4 0c             	add    $0xc,%esp
f0101ef1:	83 bd 94 fe ff ff 00 	cmpl   $0x0,-0x16c(%ebp)
f0101ef8:	74 12                	je     f0101f0c <calculator+0x1d0>
		{
			cprintf("error");
f0101efa:	83 ec 0c             	sub    $0xc,%esp
f0101efd:	68 45 29 10 f0       	push   $0xf0102945
f0101f02:	e8 4c eb ff ff       	call   f0100a53 <cprintf>
			return -1;
f0101f07:	83 c4 10             	add    $0x10,%esp
f0101f0a:	eb 2e                	jmp    f0101f3a <calculator+0x1fe>
		}
		else
		{
			if (answer_char.value == '+')
f0101f0c:	3c 2b                	cmp    $0x2b,%al
f0101f0e:	75 06                	jne    f0101f16 <calculator+0x1da>
			{
				i++;
f0101f10:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
f0101f14:	eb 1f                	jmp    f0101f35 <calculator+0x1f9>
			}
			else if (!(answer_char.value == '-'))
f0101f16:	3c 2d                	cmp    $0x2d,%al
f0101f18:	74 1b                	je     f0101f35 <calculator+0x1f9>
			{
				numericop[operantnum].operant = answer_char.value;
f0101f1a:	8b 8d 84 fe ff ff    	mov    -0x17c(%ebp),%ecx
f0101f20:	88 44 cd a0          	mov    %al,-0x60(%ebp,%ecx,8)
				numericop[operantnum].position = Operation_Position;
f0101f24:	89 7c cd 9c          	mov    %edi,-0x64(%ebp,%ecx,8)
				operantnum++;
f0101f28:	83 c1 01             	add    $0x1,%ecx
f0101f2b:	89 8d 84 fe ff ff    	mov    %ecx,-0x17c(%ebp)
				i++;
f0101f31:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)

			}
			Operation_Position++;
f0101f35:	83 c7 01             	add    $0x1,%edi
f0101f38:	eb 07                	jmp    f0101f41 <calculator+0x205>
		Float answer_num = Getnumber(op, &i);
		cprintf("getnumber error solved");
		if (answer_num.error)
		{
			cprintf("error");
			return -1;
f0101f3a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101f3f:	eb 2d                	jmp    f0101f6e <calculator+0x232>
	{
		cprintf("error");
		return -1;
	}

	while (i < strlen(op))
f0101f41:	83 ec 0c             	sub    $0xc,%esp
f0101f44:	56                   	push   %esi
f0101f45:	e8 96 f5 ff ff       	call   f01014e0 <strlen>
f0101f4a:	83 c4 10             	add    $0x10,%esp
f0101f4d:	3b 45 cc             	cmp    -0x34(%ebp),%eax
f0101f50:	0f 8f f0 fe ff ff    	jg     f0101e46 <calculator+0x10a>
			Operation_Position++;
		}

	}

	calc(A, numericop);
f0101f56:	83 ec 08             	sub    $0x8,%esp
f0101f59:	8d 45 9c             	lea    -0x64(%ebp),%eax
f0101f5c:	50                   	push   %eax
f0101f5d:	8d 45 d0             	lea    -0x30(%ebp),%eax
f0101f60:	50                   	push   %eax
f0101f61:	e8 c2 fc ff ff       	call   f0101c28 <calc>
	return 0;
f0101f66:	83 c4 10             	add    $0x10,%esp
f0101f69:	b8 00 00 00 00       	mov    $0x0,%eax

}
f0101f6e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101f71:	5b                   	pop    %ebx
f0101f72:	5e                   	pop    %esi
f0101f73:	5f                   	pop    %edi
f0101f74:	5d                   	pop    %ebp
f0101f75:	c3                   	ret    

f0101f76 <powerbase>:
#include <kern/kdebug.h>



int powerbase(char base, char power)
{
f0101f76:	55                   	push   %ebp
f0101f77:	89 e5                	mov    %esp,%ebp
f0101f79:	53                   	push   %ebx
f0101f7a:	83 ec 04             	sub    $0x4,%esp
f0101f7d:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101f80:	8b 55 0c             	mov    0xc(%ebp),%edx
	if(power!=1)
		return (base*powerbase(base,power-1));
	return base;
f0101f83:	0f be c3             	movsbl %bl,%eax



int powerbase(char base, char power)
{
	if(power!=1)
f0101f86:	80 fa 01             	cmp    $0x1,%dl
f0101f89:	74 18                	je     f0101fa3 <powerbase+0x2d>
		return (base*powerbase(base,power-1));
f0101f8b:	89 c3                	mov    %eax,%ebx
f0101f8d:	83 ec 08             	sub    $0x8,%esp
f0101f90:	83 ea 01             	sub    $0x1,%edx
f0101f93:	0f be d2             	movsbl %dl,%edx
f0101f96:	52                   	push   %edx
f0101f97:	50                   	push   %eax
f0101f98:	e8 d9 ff ff ff       	call   f0101f76 <powerbase>
f0101f9d:	83 c4 10             	add    $0x10,%esp
f0101fa0:	0f af c3             	imul   %ebx,%eax
	return base;
}
f0101fa3:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101fa6:	c9                   	leave  
f0101fa7:	c3                   	ret    

f0101fa8 <char_to_float>:

Float char_to_float(char* arg)
{
f0101fa8:	55                   	push   %ebp
f0101fa9:	89 e5                	mov    %esp,%ebp
f0101fab:	57                   	push   %edi
f0101fac:	56                   	push   %esi
f0101fad:	53                   	push   %ebx
f0101fae:	83 ec 38             	sub    $0x38,%esp
f0101fb1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	int len=strlen(arg);
f0101fb4:	53                   	push   %ebx
f0101fb5:	e8 26 f5 ff ff       	call   f01014e0 <strlen>
f0101fba:	89 c7                	mov    %eax,%edi
	double a = 0;

	Float retval;
	retval.error=0;

	while (i<len)
f0101fbc:	83 c4 10             	add    $0x10,%esp
	short neg = 0;
	int i=0;
	double a = 0;

	Float retval;
	retval.error=0;
f0101fbf:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
Float char_to_float(char* arg)
{
	int len=strlen(arg);
	short neg = 0;
	int i=0;
	double a = 0;
f0101fc6:	d9 ee                	fldz   
f0101fc8:	dd 5d d8             	fstpl  -0x28(%ebp)

Float char_to_float(char* arg)
{
	int len=strlen(arg);
	short neg = 0;
	int i=0;
f0101fcb:	be 00 00 00 00       	mov    $0x0,%esi
f0101fd0:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101fd3:	89 f3                	mov    %esi,%ebx
f0101fd5:	8b 75 0c             	mov    0xc(%ebp),%esi
	double a = 0;

	Float retval;
	retval.error=0;

	while (i<len)
f0101fd8:	e9 a9 00 00 00       	jmp    f0102086 <char_to_float+0xde>
	{
		if (*(arg) == '.')
f0101fdd:	0f b6 06             	movzbl (%esi),%eax
f0101fe0:	3c 2e                	cmp    $0x2e,%al
f0101fe2:	75 3f                	jne    f0102023 <char_to_float+0x7b>
		{
//			after the point
			a = a + (*(arg+1) - '0') * 0.1;
f0101fe4:	0f be 46 01          	movsbl 0x1(%esi),%eax
f0101fe8:	83 e8 30             	sub    $0x30,%eax
f0101feb:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101fee:	db 45 e0             	fildl  -0x20(%ebp)
f0101ff1:	dc 0d e8 28 10 f0    	fmull  0xf01028e8
f0101ff7:	dc 45 d8             	faddl  -0x28(%ebp)
			cprintf("entered val %f",a);
f0101ffa:	83 ec 0c             	sub    $0xc,%esp
f0101ffd:	dd 55 d8             	fstl   -0x28(%ebp)
f0102000:	dd 1c 24             	fstpl  (%esp)
f0102003:	68 ac 26 10 f0       	push   $0xf01026ac
f0102008:	e8 46 ea ff ff       	call   f0100a53 <cprintf>
			retval.number=a;
f010200d:	8b 45 08             	mov    0x8(%ebp),%eax
f0102010:	dd 45 d8             	fldl   -0x28(%ebp)
f0102013:	d9 18                	fstps  (%eax)
			return retval;
f0102015:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102018:	89 78 04             	mov    %edi,0x4(%eax)
f010201b:	83 c4 10             	add    $0x10,%esp
f010201e:	e9 8f 00 00 00       	jmp    f01020b2 <char_to_float+0x10a>
		}
		if (*(arg)=='-')
f0102023:	3c 2d                	cmp    $0x2d,%al
f0102025:	74 1e                	je     f0102045 <char_to_float+0x9d>
		{
			neg = 1;
		}
		else if (*(arg) < '0' || (*(arg) > '9'))
f0102027:	83 e8 30             	sub    $0x30,%eax
f010202a:	3c 09                	cmp    $0x9,%al
f010202c:	76 17                	jbe    f0102045 <char_to_float+0x9d>
		{
			retval.error = 1;
			cprintf("Invalid Argument");
f010202e:	83 ec 0c             	sub    $0xc,%esp
f0102031:	68 bb 26 10 f0       	push   $0xf01026bb
f0102036:	e8 18 ea ff ff       	call   f0100a53 <cprintf>
f010203b:	83 c4 10             	add    $0x10,%esp
		{
			neg = 1;
		}
		else if (*(arg) < '0' || (*(arg) > '9'))
		{
			retval.error = 1;
f010203e:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
			cprintf("Invalid Argument");
			//operation or invalid argument
		}
		// BUG: PowerBase has to be fixed
		// BUG: if power equals zero, the point disappears ?!
		a =  powerbase(10,len-i) / 10 * (*(arg) - '0') + a;
f0102045:	83 ec 08             	sub    $0x8,%esp
f0102048:	89 f8                	mov    %edi,%eax
f010204a:	29 d8                	sub    %ebx,%eax
f010204c:	0f be c0             	movsbl %al,%eax
f010204f:	50                   	push   %eax
f0102050:	6a 0a                	push   $0xa
f0102052:	e8 1f ff ff ff       	call   f0101f76 <powerbase>
f0102057:	83 c4 10             	add    $0x10,%esp
f010205a:	89 c1                	mov    %eax,%ecx
f010205c:	b8 67 66 66 66       	mov    $0x66666667,%eax
f0102061:	f7 e9                	imul   %ecx
f0102063:	c1 fa 02             	sar    $0x2,%edx
f0102066:	c1 f9 1f             	sar    $0x1f,%ecx
f0102069:	29 ca                	sub    %ecx,%edx
f010206b:	0f be 06             	movsbl (%esi),%eax
f010206e:	83 e8 30             	sub    $0x30,%eax
f0102071:	0f af d0             	imul   %eax,%edx
f0102074:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0102077:	db 45 e0             	fildl  -0x20(%ebp)
f010207a:	dc 45 d8             	faddl  -0x28(%ebp)
f010207d:	dd 5d d8             	fstpl  -0x28(%ebp)
		i++;
f0102080:	83 c3 01             	add    $0x1,%ebx
		arg=arg+1;
f0102083:	83 c6 01             	add    $0x1,%esi
	double a = 0;

	Float retval;
	retval.error=0;

	while (i<len)
f0102086:	39 fb                	cmp    %edi,%ebx
f0102088:	0f 8c 4f ff ff ff    	jl     f0101fdd <char_to_float+0x35>
		a =  powerbase(10,len-i) / 10 * (*(arg) - '0') + a;
		i++;
		arg=arg+1;
	}

	cprintf("entered val %f",a);
f010208e:	83 ec 04             	sub    $0x4,%esp
f0102091:	ff 75 dc             	pushl  -0x24(%ebp)
f0102094:	ff 75 d8             	pushl  -0x28(%ebp)
f0102097:	68 ac 26 10 f0       	push   $0xf01026ac
f010209c:	e8 b2 e9 ff ff       	call   f0100a53 <cprintf>
	retval.number=a;
f01020a1:	8b 45 08             	mov    0x8(%ebp),%eax
f01020a4:	dd 45 d8             	fldl   -0x28(%ebp)
f01020a7:	d9 18                	fstps  (%eax)
	return retval;
f01020a9:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01020ac:	89 78 04             	mov    %edi,0x4(%eax)
f01020af:	83 c4 10             	add    $0x10,%esp
}
f01020b2:	8b 45 08             	mov    0x8(%ebp),%eax
f01020b5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01020b8:	5b                   	pop    %ebx
f01020b9:	5e                   	pop    %esi
f01020ba:	5f                   	pop    %edi
f01020bb:	5d                   	pop    %ebp
f01020bc:	c2 04 00             	ret    $0x4
f01020bf:	90                   	nop

f01020c0 <__udivdi3>:
f01020c0:	55                   	push   %ebp
f01020c1:	57                   	push   %edi
f01020c2:	56                   	push   %esi
f01020c3:	83 ec 10             	sub    $0x10,%esp
f01020c6:	8b 54 24 2c          	mov    0x2c(%esp),%edx
f01020ca:	8b 7c 24 20          	mov    0x20(%esp),%edi
f01020ce:	8b 74 24 24          	mov    0x24(%esp),%esi
f01020d2:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f01020d6:	85 d2                	test   %edx,%edx
f01020d8:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01020dc:	89 34 24             	mov    %esi,(%esp)
f01020df:	89 c8                	mov    %ecx,%eax
f01020e1:	75 35                	jne    f0102118 <__udivdi3+0x58>
f01020e3:	39 f1                	cmp    %esi,%ecx
f01020e5:	0f 87 bd 00 00 00    	ja     f01021a8 <__udivdi3+0xe8>
f01020eb:	85 c9                	test   %ecx,%ecx
f01020ed:	89 cd                	mov    %ecx,%ebp
f01020ef:	75 0b                	jne    f01020fc <__udivdi3+0x3c>
f01020f1:	b8 01 00 00 00       	mov    $0x1,%eax
f01020f6:	31 d2                	xor    %edx,%edx
f01020f8:	f7 f1                	div    %ecx
f01020fa:	89 c5                	mov    %eax,%ebp
f01020fc:	89 f0                	mov    %esi,%eax
f01020fe:	31 d2                	xor    %edx,%edx
f0102100:	f7 f5                	div    %ebp
f0102102:	89 c6                	mov    %eax,%esi
f0102104:	89 f8                	mov    %edi,%eax
f0102106:	f7 f5                	div    %ebp
f0102108:	89 f2                	mov    %esi,%edx
f010210a:	83 c4 10             	add    $0x10,%esp
f010210d:	5e                   	pop    %esi
f010210e:	5f                   	pop    %edi
f010210f:	5d                   	pop    %ebp
f0102110:	c3                   	ret    
f0102111:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0102118:	3b 14 24             	cmp    (%esp),%edx
f010211b:	77 7b                	ja     f0102198 <__udivdi3+0xd8>
f010211d:	0f bd f2             	bsr    %edx,%esi
f0102120:	83 f6 1f             	xor    $0x1f,%esi
f0102123:	0f 84 97 00 00 00    	je     f01021c0 <__udivdi3+0x100>
f0102129:	bd 20 00 00 00       	mov    $0x20,%ebp
f010212e:	89 d7                	mov    %edx,%edi
f0102130:	89 f1                	mov    %esi,%ecx
f0102132:	29 f5                	sub    %esi,%ebp
f0102134:	d3 e7                	shl    %cl,%edi
f0102136:	89 c2                	mov    %eax,%edx
f0102138:	89 e9                	mov    %ebp,%ecx
f010213a:	d3 ea                	shr    %cl,%edx
f010213c:	89 f1                	mov    %esi,%ecx
f010213e:	09 fa                	or     %edi,%edx
f0102140:	8b 3c 24             	mov    (%esp),%edi
f0102143:	d3 e0                	shl    %cl,%eax
f0102145:	89 54 24 08          	mov    %edx,0x8(%esp)
f0102149:	89 e9                	mov    %ebp,%ecx
f010214b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010214f:	8b 44 24 04          	mov    0x4(%esp),%eax
f0102153:	89 fa                	mov    %edi,%edx
f0102155:	d3 ea                	shr    %cl,%edx
f0102157:	89 f1                	mov    %esi,%ecx
f0102159:	d3 e7                	shl    %cl,%edi
f010215b:	89 e9                	mov    %ebp,%ecx
f010215d:	d3 e8                	shr    %cl,%eax
f010215f:	09 c7                	or     %eax,%edi
f0102161:	89 f8                	mov    %edi,%eax
f0102163:	f7 74 24 08          	divl   0x8(%esp)
f0102167:	89 d5                	mov    %edx,%ebp
f0102169:	89 c7                	mov    %eax,%edi
f010216b:	f7 64 24 0c          	mull   0xc(%esp)
f010216f:	39 d5                	cmp    %edx,%ebp
f0102171:	89 14 24             	mov    %edx,(%esp)
f0102174:	72 11                	jb     f0102187 <__udivdi3+0xc7>
f0102176:	8b 54 24 04          	mov    0x4(%esp),%edx
f010217a:	89 f1                	mov    %esi,%ecx
f010217c:	d3 e2                	shl    %cl,%edx
f010217e:	39 c2                	cmp    %eax,%edx
f0102180:	73 5e                	jae    f01021e0 <__udivdi3+0x120>
f0102182:	3b 2c 24             	cmp    (%esp),%ebp
f0102185:	75 59                	jne    f01021e0 <__udivdi3+0x120>
f0102187:	8d 47 ff             	lea    -0x1(%edi),%eax
f010218a:	31 f6                	xor    %esi,%esi
f010218c:	89 f2                	mov    %esi,%edx
f010218e:	83 c4 10             	add    $0x10,%esp
f0102191:	5e                   	pop    %esi
f0102192:	5f                   	pop    %edi
f0102193:	5d                   	pop    %ebp
f0102194:	c3                   	ret    
f0102195:	8d 76 00             	lea    0x0(%esi),%esi
f0102198:	31 f6                	xor    %esi,%esi
f010219a:	31 c0                	xor    %eax,%eax
f010219c:	89 f2                	mov    %esi,%edx
f010219e:	83 c4 10             	add    $0x10,%esp
f01021a1:	5e                   	pop    %esi
f01021a2:	5f                   	pop    %edi
f01021a3:	5d                   	pop    %ebp
f01021a4:	c3                   	ret    
f01021a5:	8d 76 00             	lea    0x0(%esi),%esi
f01021a8:	89 f2                	mov    %esi,%edx
f01021aa:	31 f6                	xor    %esi,%esi
f01021ac:	89 f8                	mov    %edi,%eax
f01021ae:	f7 f1                	div    %ecx
f01021b0:	89 f2                	mov    %esi,%edx
f01021b2:	83 c4 10             	add    $0x10,%esp
f01021b5:	5e                   	pop    %esi
f01021b6:	5f                   	pop    %edi
f01021b7:	5d                   	pop    %ebp
f01021b8:	c3                   	ret    
f01021b9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01021c0:	3b 4c 24 04          	cmp    0x4(%esp),%ecx
f01021c4:	76 0b                	jbe    f01021d1 <__udivdi3+0x111>
f01021c6:	31 c0                	xor    %eax,%eax
f01021c8:	3b 14 24             	cmp    (%esp),%edx
f01021cb:	0f 83 37 ff ff ff    	jae    f0102108 <__udivdi3+0x48>
f01021d1:	b8 01 00 00 00       	mov    $0x1,%eax
f01021d6:	e9 2d ff ff ff       	jmp    f0102108 <__udivdi3+0x48>
f01021db:	90                   	nop
f01021dc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01021e0:	89 f8                	mov    %edi,%eax
f01021e2:	31 f6                	xor    %esi,%esi
f01021e4:	e9 1f ff ff ff       	jmp    f0102108 <__udivdi3+0x48>
f01021e9:	66 90                	xchg   %ax,%ax
f01021eb:	66 90                	xchg   %ax,%ax
f01021ed:	66 90                	xchg   %ax,%ax
f01021ef:	90                   	nop

f01021f0 <__umoddi3>:
f01021f0:	55                   	push   %ebp
f01021f1:	57                   	push   %edi
f01021f2:	56                   	push   %esi
f01021f3:	83 ec 20             	sub    $0x20,%esp
f01021f6:	8b 44 24 34          	mov    0x34(%esp),%eax
f01021fa:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f01021fe:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0102202:	89 c6                	mov    %eax,%esi
f0102204:	89 44 24 10          	mov    %eax,0x10(%esp)
f0102208:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f010220c:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
f0102210:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0102214:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f0102218:	89 74 24 18          	mov    %esi,0x18(%esp)
f010221c:	85 c0                	test   %eax,%eax
f010221e:	89 c2                	mov    %eax,%edx
f0102220:	75 1e                	jne    f0102240 <__umoddi3+0x50>
f0102222:	39 f7                	cmp    %esi,%edi
f0102224:	76 52                	jbe    f0102278 <__umoddi3+0x88>
f0102226:	89 c8                	mov    %ecx,%eax
f0102228:	89 f2                	mov    %esi,%edx
f010222a:	f7 f7                	div    %edi
f010222c:	89 d0                	mov    %edx,%eax
f010222e:	31 d2                	xor    %edx,%edx
f0102230:	83 c4 20             	add    $0x20,%esp
f0102233:	5e                   	pop    %esi
f0102234:	5f                   	pop    %edi
f0102235:	5d                   	pop    %ebp
f0102236:	c3                   	ret    
f0102237:	89 f6                	mov    %esi,%esi
f0102239:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0102240:	39 f0                	cmp    %esi,%eax
f0102242:	77 5c                	ja     f01022a0 <__umoddi3+0xb0>
f0102244:	0f bd e8             	bsr    %eax,%ebp
f0102247:	83 f5 1f             	xor    $0x1f,%ebp
f010224a:	75 64                	jne    f01022b0 <__umoddi3+0xc0>
f010224c:	8b 6c 24 14          	mov    0x14(%esp),%ebp
f0102250:	39 6c 24 0c          	cmp    %ebp,0xc(%esp)
f0102254:	0f 86 f6 00 00 00    	jbe    f0102350 <__umoddi3+0x160>
f010225a:	3b 44 24 18          	cmp    0x18(%esp),%eax
f010225e:	0f 82 ec 00 00 00    	jb     f0102350 <__umoddi3+0x160>
f0102264:	8b 44 24 14          	mov    0x14(%esp),%eax
f0102268:	8b 54 24 18          	mov    0x18(%esp),%edx
f010226c:	83 c4 20             	add    $0x20,%esp
f010226f:	5e                   	pop    %esi
f0102270:	5f                   	pop    %edi
f0102271:	5d                   	pop    %ebp
f0102272:	c3                   	ret    
f0102273:	90                   	nop
f0102274:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0102278:	85 ff                	test   %edi,%edi
f010227a:	89 fd                	mov    %edi,%ebp
f010227c:	75 0b                	jne    f0102289 <__umoddi3+0x99>
f010227e:	b8 01 00 00 00       	mov    $0x1,%eax
f0102283:	31 d2                	xor    %edx,%edx
f0102285:	f7 f7                	div    %edi
f0102287:	89 c5                	mov    %eax,%ebp
f0102289:	8b 44 24 10          	mov    0x10(%esp),%eax
f010228d:	31 d2                	xor    %edx,%edx
f010228f:	f7 f5                	div    %ebp
f0102291:	89 c8                	mov    %ecx,%eax
f0102293:	f7 f5                	div    %ebp
f0102295:	eb 95                	jmp    f010222c <__umoddi3+0x3c>
f0102297:	89 f6                	mov    %esi,%esi
f0102299:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f01022a0:	89 c8                	mov    %ecx,%eax
f01022a2:	89 f2                	mov    %esi,%edx
f01022a4:	83 c4 20             	add    $0x20,%esp
f01022a7:	5e                   	pop    %esi
f01022a8:	5f                   	pop    %edi
f01022a9:	5d                   	pop    %ebp
f01022aa:	c3                   	ret    
f01022ab:	90                   	nop
f01022ac:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01022b0:	b8 20 00 00 00       	mov    $0x20,%eax
f01022b5:	89 e9                	mov    %ebp,%ecx
f01022b7:	29 e8                	sub    %ebp,%eax
f01022b9:	d3 e2                	shl    %cl,%edx
f01022bb:	89 c7                	mov    %eax,%edi
f01022bd:	89 44 24 18          	mov    %eax,0x18(%esp)
f01022c1:	8b 44 24 0c          	mov    0xc(%esp),%eax
f01022c5:	89 f9                	mov    %edi,%ecx
f01022c7:	d3 e8                	shr    %cl,%eax
f01022c9:	89 c1                	mov    %eax,%ecx
f01022cb:	8b 44 24 0c          	mov    0xc(%esp),%eax
f01022cf:	09 d1                	or     %edx,%ecx
f01022d1:	89 fa                	mov    %edi,%edx
f01022d3:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f01022d7:	89 e9                	mov    %ebp,%ecx
f01022d9:	d3 e0                	shl    %cl,%eax
f01022db:	89 f9                	mov    %edi,%ecx
f01022dd:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01022e1:	89 f0                	mov    %esi,%eax
f01022e3:	d3 e8                	shr    %cl,%eax
f01022e5:	89 e9                	mov    %ebp,%ecx
f01022e7:	89 c7                	mov    %eax,%edi
f01022e9:	8b 44 24 1c          	mov    0x1c(%esp),%eax
f01022ed:	d3 e6                	shl    %cl,%esi
f01022ef:	89 d1                	mov    %edx,%ecx
f01022f1:	89 fa                	mov    %edi,%edx
f01022f3:	d3 e8                	shr    %cl,%eax
f01022f5:	89 e9                	mov    %ebp,%ecx
f01022f7:	09 f0                	or     %esi,%eax
f01022f9:	8b 74 24 1c          	mov    0x1c(%esp),%esi
f01022fd:	f7 74 24 10          	divl   0x10(%esp)
f0102301:	d3 e6                	shl    %cl,%esi
f0102303:	89 d1                	mov    %edx,%ecx
f0102305:	f7 64 24 0c          	mull   0xc(%esp)
f0102309:	39 d1                	cmp    %edx,%ecx
f010230b:	89 74 24 14          	mov    %esi,0x14(%esp)
f010230f:	89 d7                	mov    %edx,%edi
f0102311:	89 c6                	mov    %eax,%esi
f0102313:	72 0a                	jb     f010231f <__umoddi3+0x12f>
f0102315:	39 44 24 14          	cmp    %eax,0x14(%esp)
f0102319:	73 10                	jae    f010232b <__umoddi3+0x13b>
f010231b:	39 d1                	cmp    %edx,%ecx
f010231d:	75 0c                	jne    f010232b <__umoddi3+0x13b>
f010231f:	89 d7                	mov    %edx,%edi
f0102321:	89 c6                	mov    %eax,%esi
f0102323:	2b 74 24 0c          	sub    0xc(%esp),%esi
f0102327:	1b 7c 24 10          	sbb    0x10(%esp),%edi
f010232b:	89 ca                	mov    %ecx,%edx
f010232d:	89 e9                	mov    %ebp,%ecx
f010232f:	8b 44 24 14          	mov    0x14(%esp),%eax
f0102333:	29 f0                	sub    %esi,%eax
f0102335:	19 fa                	sbb    %edi,%edx
f0102337:	d3 e8                	shr    %cl,%eax
f0102339:	0f b6 4c 24 18       	movzbl 0x18(%esp),%ecx
f010233e:	89 d7                	mov    %edx,%edi
f0102340:	d3 e7                	shl    %cl,%edi
f0102342:	89 e9                	mov    %ebp,%ecx
f0102344:	09 f8                	or     %edi,%eax
f0102346:	d3 ea                	shr    %cl,%edx
f0102348:	83 c4 20             	add    $0x20,%esp
f010234b:	5e                   	pop    %esi
f010234c:	5f                   	pop    %edi
f010234d:	5d                   	pop    %ebp
f010234e:	c3                   	ret    
f010234f:	90                   	nop
f0102350:	8b 74 24 10          	mov    0x10(%esp),%esi
f0102354:	29 f9                	sub    %edi,%ecx
f0102356:	19 c6                	sbb    %eax,%esi
f0102358:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f010235c:	89 74 24 18          	mov    %esi,0x18(%esp)
f0102360:	e9 ff fe ff ff       	jmp    f0102264 <__umoddi3+0x74>
