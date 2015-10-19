
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
f0100050:	e8 ee 09 00 00       	call   f0100a43 <cprintf>
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
f0100076:	e8 50 08 00 00       	call   f01008cb <mon_backtrace>
f010007b:	83 c4 10             	add    $0x10,%esp
	cprintf("leaving test_backtrace %d\n", x);
f010007e:	83 ec 08             	sub    $0x8,%esp
f0100081:	53                   	push   %ebx
f0100082:	68 9c 23 10 f0       	push   $0xf010239c
f0100087:	e8 b7 09 00 00       	call   f0100a43 <cprintf>
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
f01000ac:	e8 9d 15 00 00       	call   f010164e <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b1:	e8 8c 04 00 00       	call   f0100542 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000b6:	83 c4 08             	add    $0x8,%esp
f01000b9:	68 ac 1a 00 00       	push   $0x1aac
f01000be:	68 b7 23 10 f0       	push   $0xf01023b7
f01000c3:	e8 7b 09 00 00       	call   f0100a43 <cprintf>

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
f01000dc:	e8 f4 07 00 00       	call   f01008d5 <monitor>
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
f0100110:	e8 2e 09 00 00       	call   f0100a43 <cprintf>
	vcprintf(fmt, ap);
f0100115:	83 c4 08             	add    $0x8,%esp
f0100118:	53                   	push   %ebx
f0100119:	56                   	push   %esi
f010011a:	e8 fe 08 00 00       	call   f0100a1d <vcprintf>
	cprintf("\n");
f010011f:	c7 04 24 0e 24 10 f0 	movl   $0xf010240e,(%esp)
f0100126:	e8 18 09 00 00       	call   f0100a43 <cprintf>
	va_end(ap);
f010012b:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010012e:	83 ec 0c             	sub    $0xc,%esp
f0100131:	6a 00                	push   $0x0
f0100133:	e8 9d 07 00 00       	call   f01008d5 <monitor>
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
f0100152:	e8 ec 08 00 00       	call   f0100a43 <cprintf>
	vcprintf(fmt, ap);
f0100157:	83 c4 08             	add    $0x8,%esp
f010015a:	53                   	push   %ebx
f010015b:	ff 75 10             	pushl  0x10(%ebp)
f010015e:	e8 ba 08 00 00       	call   f0100a1d <vcprintf>
	cprintf("\n");
f0100163:	c7 04 24 0e 24 10 f0 	movl   $0xf010240e,(%esp)
f010016a:	e8 d4 08 00 00       	call   f0100a43 <cprintf>
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
f01002be:	e8 80 07 00 00       	call   f0100a43 <cprintf>
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
f0100466:	e8 30 12 00 00       	call   f010169b <memmove>
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
f010062b:	e8 13 04 00 00       	call   f0100a43 <cprintf>
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
f010066c:	e8 bb 16 00 00       	call   f0101d2c <calculator>
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
f010068d:	e8 b1 03 00 00       	call   f0100a43 <cprintf>
f0100692:	83 c4 0c             	add    $0xc,%esp
f0100695:	68 24 27 10 f0       	push   $0xf0102724
f010069a:	68 aa 2b 10 f0       	push   $0xf0102baa
f010069f:	68 a3 26 10 f0       	push   $0xf01026a3
f01006a4:	e8 9a 03 00 00       	call   f0100a43 <cprintf>
f01006a9:	83 c4 0c             	add    $0xc,%esp
f01006ac:	68 4c 27 10 f0       	push   $0xf010274c
f01006b1:	68 ca 26 10 f0       	push   $0xf01026ca
f01006b6:	68 a3 26 10 f0       	push   $0xf01026a3
f01006bb:	e8 83 03 00 00       	call   f0100a43 <cprintf>
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
f01006cd:	83 ec 28             	sub    $0x28,%esp
//		float* a=(float*)c;
//		out=(char*)a;
///////////////////////////////////////// */
char *arg=NULL;
float b=0;
	arg=readline("");
f01006d0:	68 0f 24 10 f0       	push   $0xf010240f
f01006d5:	e8 1d 0d 00 00       	call   f01013f7 <readline>
f01006da:	89 c3                	mov    %eax,%ebx
	int len=strlen(arg);
f01006dc:	89 04 24             	mov    %eax,(%esp)
f01006df:	e8 ec 0d 00 00       	call   f01014d0 <strlen>
f01006e4:	89 c7                	mov    %eax,%edi
	float a = 0;

	Float retval;
	retval.error=0;

	while (i<len)
f01006e6:	83 c4 10             	add    $0x10,%esp
float b=0;
	arg=readline("");
	int len=strlen(arg);
	short neg = 0;
	int i=0;
	float a = 0;
f01006e9:	d9 ee                	fldz   
f01006eb:	d9 5d e0             	fstps  -0x20(%ebp)
char *arg=NULL;
float b=0;
	arg=readline("");
	int len=strlen(arg);
	short neg = 0;
	int i=0;
f01006ee:	be 00 00 00 00       	mov    $0x0,%esi
///////////////////////////////////////// */
char *arg=NULL;
float b=0;
	arg=readline("");
	int len=strlen(arg);
	short neg = 0;
f01006f3:	66 c7 45 da 00 00    	movw   $0x0,-0x26(%ebp)
	float a = 0;

	Float retval;
	retval.error=0;

	while (i<len)
f01006f9:	e9 b8 00 00 00       	jmp    f01007b6 <first_lab+0xef>
	{
		if (*(arg) == '.')
f01006fe:	0f b6 03             	movzbl (%ebx),%eax
f0100701:	3c 2e                	cmp    $0x2e,%al
f0100703:	75 48                	jne    f010074d <first_lab+0x86>
		{
			if (!(arg+1))
f0100705:	83 fb ff             	cmp    $0xffffffff,%ebx
f0100708:	0f 84 ea 00 00 00    	je     f01007f8 <first_lab+0x131>
			{
				retval.error=1;
				return 0;
			}
			a = a + (*(arg+1) - '0') * 0.1;
f010070e:	0f be 43 01          	movsbl 0x1(%ebx),%eax
f0100712:	83 e8 30             	sub    $0x30,%eax
f0100715:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100718:	db 45 dc             	fildl  -0x24(%ebp)
f010071b:	dc 0d e8 28 10 f0    	fmull  0xf01028e8
f0100721:	d8 45 e0             	fadds  -0x20(%ebp)
f0100724:	d9 5d e4             	fstps  -0x1c(%ebp)
f0100727:	d9 45 e4             	flds   -0x1c(%ebp)
				if ((arg+2)!= NULL)
f010072a:	83 fb fe             	cmp    $0xfffffffe,%ebx
f010072d:	0f 84 c3 00 00 00    	je     f01007f6 <first_lab+0x12f>
				{
					a = a + (*(arg+2) - '0') * 0.1;
f0100733:	0f be 43 02          	movsbl 0x2(%ebx),%eax
f0100737:	83 e8 30             	sub    $0x30,%eax
f010073a:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010073d:	db 45 e0             	fildl  -0x20(%ebp)
f0100740:	dc 0d e8 28 10 f0    	fmull  0xf01028e8
f0100746:	de c1                	faddp  %st,%st(1)
f0100748:	d9 5d e0             	fstps  -0x20(%ebp)
				{
					retval.error=1; 
					return 0;
				}
			retval.number=a;
			goto ifnegative;
f010074b:	eb 71                	jmp    f01007be <first_lab+0xf7>
			return retval.number;
		}
		if (*(arg)=='-')
f010074d:	3c 2d                	cmp    $0x2d,%al
f010074f:	75 0b                	jne    f010075c <first_lab+0x95>
		{
			neg = 1;
			len--;
f0100751:	83 ef 01             	sub    $0x1,%edi
			goto ifnegative;
			return retval.number;
		}
		if (*(arg)=='-')
		{
			neg = 1;
f0100754:	66 c7 45 da 01 00    	movw   $0x1,-0x26(%ebp)
			len--;
			goto argplus;
f010075a:	eb 57                	jmp    f01007b3 <first_lab+0xec>
		}
		else if (*(arg) < '0' || (*(arg) > '9'))
f010075c:	83 e8 30             	sub    $0x30,%eax
f010075f:	3c 09                	cmp    $0x9,%al
f0100761:	76 10                	jbe    f0100773 <first_lab+0xac>
		{
			retval.error = 1;
			cprintf("Invalid Argument");
f0100763:	83 ec 0c             	sub    $0xc,%esp
f0100766:	68 ac 26 10 f0       	push   $0xf01026ac
f010076b:	e8 d3 02 00 00       	call   f0100a43 <cprintf>
f0100770:	83 c4 10             	add    $0x10,%esp
			//operation or invalid argument
		}
		// BUG: PowerBase has to be fixed
		// BUG: if power equals zero, the point disappears ?!
		a =  powerbase(10,len-i) / 10 * (*(arg) - '0') + a;
f0100773:	83 ec 08             	sub    $0x8,%esp
f0100776:	89 f8                	mov    %edi,%eax
f0100778:	89 f1                	mov    %esi,%ecx
f010077a:	29 c8                	sub    %ecx,%eax
f010077c:	0f be c0             	movsbl %al,%eax
f010077f:	50                   	push   %eax
f0100780:	6a 0a                	push   $0xa
f0100782:	e8 df 17 00 00       	call   f0101f66 <powerbase>
f0100787:	89 c1                	mov    %eax,%ecx
f0100789:	b8 67 66 66 66       	mov    $0x66666667,%eax
f010078e:	f7 e9                	imul   %ecx
f0100790:	c1 fa 02             	sar    $0x2,%edx
f0100793:	c1 f9 1f             	sar    $0x1f,%ecx
f0100796:	29 ca                	sub    %ecx,%edx
f0100798:	0f be 03             	movsbl (%ebx),%eax
f010079b:	83 e8 30             	sub    $0x30,%eax
f010079e:	0f af d0             	imul   %eax,%edx
f01007a1:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01007a4:	db 45 dc             	fildl  -0x24(%ebp)
f01007a7:	d8 45 e0             	fadds  -0x20(%ebp)
f01007aa:	d9 5d e0             	fstps  -0x20(%ebp)
		i++;
f01007ad:	83 c6 01             	add    $0x1,%esi
f01007b0:	83 c4 10             	add    $0x10,%esp
	argplus: arg=arg+1;
f01007b3:	83 c3 01             	add    $0x1,%ebx
	float a = 0;

	Float retval;
	retval.error=0;

	while (i<len)
f01007b6:	39 f7                	cmp    %esi,%edi
f01007b8:	0f 8f 40 ff ff ff    	jg     f01006fe <first_lab+0x37>
//		float* a=(float*)c;
//		float* a=(float*)c;
//		out=(char*)a;
///////////////////////////////////////// */
char *arg=NULL;
float b=0;
f01007be:	d9 ee                	fldz   
		a =  powerbase(10,len-i) / 10 * (*(arg) - '0') + a;
		i++;
	argplus: arg=arg+1;
	}
ifnegative:
	if (neg==1)
f01007c0:	66 83 7d da 01       	cmpw   $0x1,-0x26(%ebp)
f01007c5:	75 07                	jne    f01007ce <first_lab+0x107>
f01007c7:	dd d8                	fstp   %st(0)
	{
		b=-3648;
		b=a*-1;
f01007c9:	d9 45 e0             	flds   -0x20(%ebp)
f01007cc:	d9 e0                	fchs   
	else
	{
		retval.number=a;
	}
 
	cprintf("entered val %f",b);
f01007ce:	83 ec 0c             	sub    $0xc,%esp
f01007d1:	dd 1c 24             	fstpl  (%esp)
f01007d4:	68 bd 26 10 f0       	push   $0xf01026bd
f01007d9:	e8 65 02 00 00       	call   f0100a43 <cprintf>

	cprintf("entered val %f",a);
f01007de:	d9 45 e0             	flds   -0x20(%ebp)
f01007e1:	dd 5c 24 04          	fstpl  0x4(%esp)
f01007e5:	c7 04 24 bd 26 10 f0 	movl   $0xf01026bd,(%esp)
f01007ec:	e8 52 02 00 00       	call   f0100a43 <cprintf>
	return 0;
f01007f1:	83 c4 10             	add    $0x10,%esp
f01007f4:	eb 02                	jmp    f01007f8 <first_lab+0x131>
f01007f6:	dd d8                	fstp   %st(0)
}
f01007f8:	b8 00 00 00 00       	mov    $0x0,%eax
f01007fd:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100800:	5b                   	pop    %ebx
f0100801:	5e                   	pop    %esi
f0100802:	5f                   	pop    %edi
f0100803:	5d                   	pop    %ebp
f0100804:	c3                   	ret    

f0100805 <second_lab>:
	return 0;
}

int
second_lab(int argc, char **argv, struct Trapframe *tf)
{
f0100805:	55                   	push   %ebp
f0100806:	89 e5                	mov    %esp,%ebp
f0100808:	83 ec 14             	sub    $0x14,%esp
	/// Yassin call his calculator here;
	char *in= NULL;
	char *out;
	out = readline(in);
f010080b:	6a 00                	push   $0x0
f010080d:	e8 e5 0b 00 00       	call   f01013f7 <readline>
	int i=0;
	float a=0;
	while (out+i)
f0100812:	83 c4 10             	add    $0x10,%esp
f0100815:	85 c0                	test   %eax,%eax
f0100817:	75 fc                	jne    f0100815 <second_lab+0x10>
			//operation or invalid argument
		}
		float a;
	}	
	return 0;
}
f0100819:	c9                   	leave  
f010081a:	c3                   	ret    

f010081b <mon_kerninfo>:
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f010081b:	55                   	push   %ebp
f010081c:	89 e5                	mov    %esp,%ebp
f010081e:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100821:	68 cc 26 10 f0       	push   $0xf01026cc
f0100826:	e8 18 02 00 00       	call   f0100a43 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f010082b:	83 c4 08             	add    $0x8,%esp
f010082e:	68 0c 00 10 00       	push   $0x10000c
f0100833:	68 74 27 10 f0       	push   $0xf0102774
f0100838:	e8 06 02 00 00       	call   f0100a43 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010083d:	83 c4 0c             	add    $0xc,%esp
f0100840:	68 0c 00 10 00       	push   $0x10000c
f0100845:	68 0c 00 10 f0       	push   $0xf010000c
f010084a:	68 9c 27 10 f0       	push   $0xf010279c
f010084f:	e8 ef 01 00 00       	call   f0100a43 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100854:	83 c4 0c             	add    $0xc,%esp
f0100857:	68 55 23 10 00       	push   $0x102355
f010085c:	68 55 23 10 f0       	push   $0xf0102355
f0100861:	68 c0 27 10 f0       	push   $0xf01027c0
f0100866:	e8 d8 01 00 00       	call   f0100a43 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010086b:	83 c4 0c             	add    $0xc,%esp
f010086e:	68 00 43 11 00       	push   $0x114300
f0100873:	68 00 43 11 f0       	push   $0xf0114300
f0100878:	68 e4 27 10 f0       	push   $0xf01027e4
f010087d:	e8 c1 01 00 00       	call   f0100a43 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100882:	83 c4 0c             	add    $0xc,%esp
f0100885:	68 84 49 11 00       	push   $0x114984
f010088a:	68 84 49 11 f0       	push   $0xf0114984
f010088f:	68 08 28 10 f0       	push   $0xf0102808
f0100894:	e8 aa 01 00 00       	call   f0100a43 <cprintf>
f0100899:	b8 83 4d 11 f0       	mov    $0xf0114d83,%eax
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f010089e:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01008a3:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f01008a6:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01008ab:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f01008b1:	85 c0                	test   %eax,%eax
f01008b3:	0f 48 c2             	cmovs  %edx,%eax
f01008b6:	c1 f8 0a             	sar    $0xa,%eax
f01008b9:	50                   	push   %eax
f01008ba:	68 2c 28 10 f0       	push   $0xf010282c
f01008bf:	e8 7f 01 00 00       	call   f0100a43 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f01008c4:	b8 00 00 00 00       	mov    $0x0,%eax
f01008c9:	c9                   	leave  
f01008ca:	c3                   	ret    

f01008cb <mon_backtrace>:


int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01008cb:	55                   	push   %ebp
f01008cc:	89 e5                	mov    %esp,%ebp
	// Your code here.
	return 0;
}
f01008ce:	b8 00 00 00 00       	mov    $0x0,%eax
f01008d3:	5d                   	pop    %ebp
f01008d4:	c3                   	ret    

f01008d5 <monitor>:
}


void
monitor(struct Trapframe *tf)
{
f01008d5:	55                   	push   %ebp
f01008d6:	89 e5                	mov    %esp,%ebp
f01008d8:	57                   	push   %edi
f01008d9:	56                   	push   %esi
f01008da:	53                   	push   %ebx
f01008db:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01008de:	68 58 28 10 f0       	push   $0xf0102858
f01008e3:	e8 5b 01 00 00       	call   f0100a43 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01008e8:	c7 04 24 7c 28 10 f0 	movl   $0xf010287c,(%esp)
f01008ef:	e8 4f 01 00 00       	call   f0100a43 <cprintf>
f01008f4:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f01008f7:	83 ec 0c             	sub    $0xc,%esp
f01008fa:	68 e5 26 10 f0       	push   $0xf01026e5
f01008ff:	e8 f3 0a 00 00       	call   f01013f7 <readline>
f0100904:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100906:	83 c4 10             	add    $0x10,%esp
f0100909:	85 c0                	test   %eax,%eax
f010090b:	74 ea                	je     f01008f7 <monitor+0x22>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f010090d:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100914:	be 00 00 00 00       	mov    $0x0,%esi
f0100919:	eb 0a                	jmp    f0100925 <monitor+0x50>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f010091b:	c6 03 00             	movb   $0x0,(%ebx)
f010091e:	89 f7                	mov    %esi,%edi
f0100920:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100923:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100925:	0f b6 03             	movzbl (%ebx),%eax
f0100928:	84 c0                	test   %al,%al
f010092a:	74 63                	je     f010098f <monitor+0xba>
f010092c:	83 ec 08             	sub    $0x8,%esp
f010092f:	0f be c0             	movsbl %al,%eax
f0100932:	50                   	push   %eax
f0100933:	68 e9 26 10 f0       	push   $0xf01026e9
f0100938:	e8 d4 0c 00 00       	call   f0101611 <strchr>
f010093d:	83 c4 10             	add    $0x10,%esp
f0100940:	85 c0                	test   %eax,%eax
f0100942:	75 d7                	jne    f010091b <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f0100944:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100947:	74 46                	je     f010098f <monitor+0xba>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100949:	83 fe 0f             	cmp    $0xf,%esi
f010094c:	75 14                	jne    f0100962 <monitor+0x8d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f010094e:	83 ec 08             	sub    $0x8,%esp
f0100951:	6a 10                	push   $0x10
f0100953:	68 ee 26 10 f0       	push   $0xf01026ee
f0100958:	e8 e6 00 00 00       	call   f0100a43 <cprintf>
f010095d:	83 c4 10             	add    $0x10,%esp
f0100960:	eb 95                	jmp    f01008f7 <monitor+0x22>
			return 0;
		}
		argv[argc++] = buf;
f0100962:	8d 7e 01             	lea    0x1(%esi),%edi
f0100965:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100969:	eb 03                	jmp    f010096e <monitor+0x99>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f010096b:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010096e:	0f b6 03             	movzbl (%ebx),%eax
f0100971:	84 c0                	test   %al,%al
f0100973:	74 ae                	je     f0100923 <monitor+0x4e>
f0100975:	83 ec 08             	sub    $0x8,%esp
f0100978:	0f be c0             	movsbl %al,%eax
f010097b:	50                   	push   %eax
f010097c:	68 e9 26 10 f0       	push   $0xf01026e9
f0100981:	e8 8b 0c 00 00       	call   f0101611 <strchr>
f0100986:	83 c4 10             	add    $0x10,%esp
f0100989:	85 c0                	test   %eax,%eax
f010098b:	74 de                	je     f010096b <monitor+0x96>
f010098d:	eb 94                	jmp    f0100923 <monitor+0x4e>
			buf++;
	}
	argv[argc] = 0;
f010098f:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100996:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100997:	85 f6                	test   %esi,%esi
f0100999:	0f 84 58 ff ff ff    	je     f01008f7 <monitor+0x22>
f010099f:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01009a4:	83 ec 08             	sub    $0x8,%esp
f01009a7:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01009aa:	ff 34 85 c0 28 10 f0 	pushl  -0xfefd740(,%eax,4)
f01009b1:	ff 75 a8             	pushl  -0x58(%ebp)
f01009b4:	e8 fa 0b 00 00       	call   f01015b3 <strcmp>
f01009b9:	83 c4 10             	add    $0x10,%esp
f01009bc:	85 c0                	test   %eax,%eax
f01009be:	75 22                	jne    f01009e2 <monitor+0x10d>
			return commands[i].func(argc, argv, tf);
f01009c0:	83 ec 04             	sub    $0x4,%esp
f01009c3:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01009c6:	ff 75 08             	pushl  0x8(%ebp)
f01009c9:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01009cc:	52                   	push   %edx
f01009cd:	56                   	push   %esi
f01009ce:	ff 14 85 c8 28 10 f0 	call   *-0xfefd738(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01009d5:	83 c4 10             	add    $0x10,%esp
f01009d8:	85 c0                	test   %eax,%eax
f01009da:	0f 89 17 ff ff ff    	jns    f01008f7 <monitor+0x22>
f01009e0:	eb 20                	jmp    f0100a02 <monitor+0x12d>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f01009e2:	83 c3 01             	add    $0x1,%ebx
f01009e5:	83 fb 03             	cmp    $0x3,%ebx
f01009e8:	75 ba                	jne    f01009a4 <monitor+0xcf>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01009ea:	83 ec 08             	sub    $0x8,%esp
f01009ed:	ff 75 a8             	pushl  -0x58(%ebp)
f01009f0:	68 0b 27 10 f0       	push   $0xf010270b
f01009f5:	e8 49 00 00 00       	call   f0100a43 <cprintf>
f01009fa:	83 c4 10             	add    $0x10,%esp
f01009fd:	e9 f5 fe ff ff       	jmp    f01008f7 <monitor+0x22>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100a02:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100a05:	5b                   	pop    %ebx
f0100a06:	5e                   	pop    %esi
f0100a07:	5f                   	pop    %edi
f0100a08:	5d                   	pop    %ebp
f0100a09:	c3                   	ret    

f0100a0a <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100a0a:	55                   	push   %ebp
f0100a0b:	89 e5                	mov    %esp,%ebp
f0100a0d:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0100a10:	ff 75 08             	pushl  0x8(%ebp)
f0100a13:	e8 23 fc ff ff       	call   f010063b <cputchar>
f0100a18:	83 c4 10             	add    $0x10,%esp
	*cnt++;
}
f0100a1b:	c9                   	leave  
f0100a1c:	c3                   	ret    

f0100a1d <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100a1d:	55                   	push   %ebp
f0100a1e:	89 e5                	mov    %esp,%ebp
f0100a20:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0100a23:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100a2a:	ff 75 0c             	pushl  0xc(%ebp)
f0100a2d:	ff 75 08             	pushl  0x8(%ebp)
f0100a30:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100a33:	50                   	push   %eax
f0100a34:	68 0a 0a 10 f0       	push   $0xf0100a0a
f0100a39:	e8 9b 04 00 00       	call   f0100ed9 <vprintfmt>
	return cnt;
}
f0100a3e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100a41:	c9                   	leave  
f0100a42:	c3                   	ret    

f0100a43 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100a43:	55                   	push   %ebp
f0100a44:	89 e5                	mov    %esp,%ebp
f0100a46:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100a49:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100a4c:	50                   	push   %eax
f0100a4d:	ff 75 08             	pushl  0x8(%ebp)
f0100a50:	e8 c8 ff ff ff       	call   f0100a1d <vcprintf>
	va_end(ap);

	return cnt;
}
f0100a55:	c9                   	leave  
f0100a56:	c3                   	ret    

f0100a57 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100a57:	55                   	push   %ebp
f0100a58:	89 e5                	mov    %esp,%ebp
f0100a5a:	57                   	push   %edi
f0100a5b:	56                   	push   %esi
f0100a5c:	53                   	push   %ebx
f0100a5d:	83 ec 14             	sub    $0x14,%esp
f0100a60:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0100a63:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100a66:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100a69:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100a6c:	8b 1a                	mov    (%edx),%ebx
f0100a6e:	8b 01                	mov    (%ecx),%eax
f0100a70:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a73:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0100a7a:	e9 88 00 00 00       	jmp    f0100b07 <stab_binsearch+0xb0>
		int true_m = (l + r) / 2, m = true_m;
f0100a7f:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100a82:	01 d8                	add    %ebx,%eax
f0100a84:	89 c6                	mov    %eax,%esi
f0100a86:	c1 ee 1f             	shr    $0x1f,%esi
f0100a89:	01 c6                	add    %eax,%esi
f0100a8b:	d1 fe                	sar    %esi
f0100a8d:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0100a90:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100a93:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0100a96:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a98:	eb 03                	jmp    f0100a9d <stab_binsearch+0x46>
			m--;
f0100a9a:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a9d:	39 c3                	cmp    %eax,%ebx
f0100a9f:	7f 1f                	jg     f0100ac0 <stab_binsearch+0x69>
f0100aa1:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0100aa5:	83 ea 0c             	sub    $0xc,%edx
f0100aa8:	39 f9                	cmp    %edi,%ecx
f0100aaa:	75 ee                	jne    f0100a9a <stab_binsearch+0x43>
f0100aac:	89 45 e8             	mov    %eax,-0x18(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100aaf:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100ab2:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100ab5:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0100ab9:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100abc:	76 18                	jbe    f0100ad6 <stab_binsearch+0x7f>
f0100abe:	eb 05                	jmp    f0100ac5 <stab_binsearch+0x6e>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100ac0:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0100ac3:	eb 42                	jmp    f0100b07 <stab_binsearch+0xb0>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100ac5:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100ac8:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0100aca:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100acd:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100ad4:	eb 31                	jmp    f0100b07 <stab_binsearch+0xb0>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100ad6:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100ad9:	73 17                	jae    f0100af2 <stab_binsearch+0x9b>
			*region_right = m - 1;
f0100adb:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100ade:	83 e8 01             	sub    $0x1,%eax
f0100ae1:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100ae4:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100ae7:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100ae9:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100af0:	eb 15                	jmp    f0100b07 <stab_binsearch+0xb0>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100af2:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100af5:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100af8:	89 1e                	mov    %ebx,(%esi)
			l = m;
			addr++;
f0100afa:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0100afe:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100b00:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100b07:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100b0a:	0f 8e 6f ff ff ff    	jle    f0100a7f <stab_binsearch+0x28>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100b10:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0100b14:	75 0f                	jne    f0100b25 <stab_binsearch+0xce>
		*region_right = *region_left - 1;
f0100b16:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b19:	8b 00                	mov    (%eax),%eax
f0100b1b:	83 e8 01             	sub    $0x1,%eax
f0100b1e:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100b21:	89 06                	mov    %eax,(%esi)
f0100b23:	eb 2c                	jmp    f0100b51 <stab_binsearch+0xfa>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100b25:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b28:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100b2a:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100b2d:	8b 0e                	mov    (%esi),%ecx
f0100b2f:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100b32:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0100b35:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100b38:	eb 03                	jmp    f0100b3d <stab_binsearch+0xe6>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100b3a:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100b3d:	39 c8                	cmp    %ecx,%eax
f0100b3f:	7e 0b                	jle    f0100b4c <stab_binsearch+0xf5>
		     l > *region_left && stabs[l].n_type != type;
f0100b41:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0100b45:	83 ea 0c             	sub    $0xc,%edx
f0100b48:	39 fb                	cmp    %edi,%ebx
f0100b4a:	75 ee                	jne    f0100b3a <stab_binsearch+0xe3>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100b4c:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100b4f:	89 06                	mov    %eax,(%esi)
	}
}
f0100b51:	83 c4 14             	add    $0x14,%esp
f0100b54:	5b                   	pop    %ebx
f0100b55:	5e                   	pop    %esi
f0100b56:	5f                   	pop    %edi
f0100b57:	5d                   	pop    %ebp
f0100b58:	c3                   	ret    

f0100b59 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100b59:	55                   	push   %ebp
f0100b5a:	89 e5                	mov    %esp,%ebp
f0100b5c:	57                   	push   %edi
f0100b5d:	56                   	push   %esi
f0100b5e:	53                   	push   %ebx
f0100b5f:	83 ec 1c             	sub    $0x1c,%esp
f0100b62:	8b 7d 08             	mov    0x8(%ebp),%edi
f0100b65:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100b68:	c7 06 f0 28 10 f0    	movl   $0xf01028f0,(%esi)
	info->eip_line = 0;
f0100b6e:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0100b75:	c7 46 08 f0 28 10 f0 	movl   $0xf01028f0,0x8(%esi)
	info->eip_fn_namelen = 9;
f0100b7c:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f0100b83:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0100b86:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100b8d:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0100b93:	76 11                	jbe    f0100ba6 <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b95:	b8 d7 94 10 f0       	mov    $0xf01094d7,%eax
f0100b9a:	3d 11 78 10 f0       	cmp    $0xf0107811,%eax
f0100b9f:	77 19                	ja     f0100bba <debuginfo_eip+0x61>
f0100ba1:	e9 4c 01 00 00       	jmp    f0100cf2 <debuginfo_eip+0x199>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100ba6:	83 ec 04             	sub    $0x4,%esp
f0100ba9:	68 fa 28 10 f0       	push   $0xf01028fa
f0100bae:	6a 7f                	push   $0x7f
f0100bb0:	68 07 29 10 f0       	push   $0xf0102907
f0100bb5:	e8 2c f5 ff ff       	call   f01000e6 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100bba:	80 3d d6 94 10 f0 00 	cmpb   $0x0,0xf01094d6
f0100bc1:	0f 85 32 01 00 00    	jne    f0100cf9 <debuginfo_eip+0x1a0>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100bc7:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100bce:	b8 10 78 10 f0       	mov    $0xf0107810,%eax
f0100bd3:	2d 88 2d 10 f0       	sub    $0xf0102d88,%eax
f0100bd8:	c1 f8 02             	sar    $0x2,%eax
f0100bdb:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100be1:	83 e8 01             	sub    $0x1,%eax
f0100be4:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100be7:	83 ec 08             	sub    $0x8,%esp
f0100bea:	57                   	push   %edi
f0100beb:	6a 64                	push   $0x64
f0100bed:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100bf0:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100bf3:	b8 88 2d 10 f0       	mov    $0xf0102d88,%eax
f0100bf8:	e8 5a fe ff ff       	call   f0100a57 <stab_binsearch>
	if (lfile == 0)
f0100bfd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c00:	83 c4 10             	add    $0x10,%esp
f0100c03:	85 c0                	test   %eax,%eax
f0100c05:	0f 84 f5 00 00 00    	je     f0100d00 <debuginfo_eip+0x1a7>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100c0b:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100c0e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c11:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100c14:	83 ec 08             	sub    $0x8,%esp
f0100c17:	57                   	push   %edi
f0100c18:	6a 24                	push   $0x24
f0100c1a:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100c1d:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100c20:	b8 88 2d 10 f0       	mov    $0xf0102d88,%eax
f0100c25:	e8 2d fe ff ff       	call   f0100a57 <stab_binsearch>

	if (lfun <= rfun) {
f0100c2a:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100c2d:	83 c4 10             	add    $0x10,%esp
f0100c30:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f0100c33:	7f 31                	jg     f0100c66 <debuginfo_eip+0x10d>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100c35:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100c38:	c1 e0 02             	shl    $0x2,%eax
f0100c3b:	8d 90 88 2d 10 f0    	lea    -0xfefd278(%eax),%edx
f0100c41:	8b 88 88 2d 10 f0    	mov    -0xfefd278(%eax),%ecx
f0100c47:	b8 d7 94 10 f0       	mov    $0xf01094d7,%eax
f0100c4c:	2d 11 78 10 f0       	sub    $0xf0107811,%eax
f0100c51:	39 c1                	cmp    %eax,%ecx
f0100c53:	73 09                	jae    f0100c5e <debuginfo_eip+0x105>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100c55:	81 c1 11 78 10 f0    	add    $0xf0107811,%ecx
f0100c5b:	89 4e 08             	mov    %ecx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100c5e:	8b 42 08             	mov    0x8(%edx),%eax
f0100c61:	89 46 10             	mov    %eax,0x10(%esi)
f0100c64:	eb 06                	jmp    f0100c6c <debuginfo_eip+0x113>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100c66:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0100c69:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100c6c:	83 ec 08             	sub    $0x8,%esp
f0100c6f:	6a 3a                	push   $0x3a
f0100c71:	ff 76 08             	pushl  0x8(%esi)
f0100c74:	e8 b9 09 00 00       	call   f0101632 <strfind>
f0100c79:	2b 46 08             	sub    0x8(%esi),%eax
f0100c7c:	89 46 0c             	mov    %eax,0xc(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c7f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100c82:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100c85:	8d 04 85 88 2d 10 f0 	lea    -0xfefd278(,%eax,4),%eax
f0100c8c:	83 c4 10             	add    $0x10,%esp
f0100c8f:	eb 06                	jmp    f0100c97 <debuginfo_eip+0x13e>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100c91:	83 eb 01             	sub    $0x1,%ebx
f0100c94:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c97:	39 fb                	cmp    %edi,%ebx
f0100c99:	7c 1e                	jl     f0100cb9 <debuginfo_eip+0x160>
	       && stabs[lline].n_type != N_SOL
f0100c9b:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f0100c9f:	80 fa 84             	cmp    $0x84,%dl
f0100ca2:	74 6a                	je     f0100d0e <debuginfo_eip+0x1b5>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100ca4:	80 fa 64             	cmp    $0x64,%dl
f0100ca7:	75 e8                	jne    f0100c91 <debuginfo_eip+0x138>
f0100ca9:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0100cad:	74 e2                	je     f0100c91 <debuginfo_eip+0x138>
f0100caf:	eb 5d                	jmp    f0100d0e <debuginfo_eip+0x1b5>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100cb1:	81 c2 11 78 10 f0    	add    $0xf0107811,%edx
f0100cb7:	89 16                	mov    %edx,(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100cb9:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100cbc:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100cbf:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100cc4:	39 cb                	cmp    %ecx,%ebx
f0100cc6:	7d 60                	jge    f0100d28 <debuginfo_eip+0x1cf>
		for (lline = lfun + 1;
f0100cc8:	8d 53 01             	lea    0x1(%ebx),%edx
f0100ccb:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100cce:	8d 04 85 88 2d 10 f0 	lea    -0xfefd278(,%eax,4),%eax
f0100cd5:	eb 07                	jmp    f0100cde <debuginfo_eip+0x185>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100cd7:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0100cdb:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100cde:	39 ca                	cmp    %ecx,%edx
f0100ce0:	74 25                	je     f0100d07 <debuginfo_eip+0x1ae>
f0100ce2:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100ce5:	80 78 04 a0          	cmpb   $0xa0,0x4(%eax)
f0100ce9:	74 ec                	je     f0100cd7 <debuginfo_eip+0x17e>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100ceb:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cf0:	eb 36                	jmp    f0100d28 <debuginfo_eip+0x1cf>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100cf2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100cf7:	eb 2f                	jmp    f0100d28 <debuginfo_eip+0x1cf>
f0100cf9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100cfe:	eb 28                	jmp    f0100d28 <debuginfo_eip+0x1cf>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100d00:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d05:	eb 21                	jmp    f0100d28 <debuginfo_eip+0x1cf>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100d07:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d0c:	eb 1a                	jmp    f0100d28 <debuginfo_eip+0x1cf>
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100d0e:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100d11:	8b 14 85 88 2d 10 f0 	mov    -0xfefd278(,%eax,4),%edx
f0100d18:	b8 d7 94 10 f0       	mov    $0xf01094d7,%eax
f0100d1d:	2d 11 78 10 f0       	sub    $0xf0107811,%eax
f0100d22:	39 c2                	cmp    %eax,%edx
f0100d24:	72 8b                	jb     f0100cb1 <debuginfo_eip+0x158>
f0100d26:	eb 91                	jmp    f0100cb9 <debuginfo_eip+0x160>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
}
f0100d28:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100d2b:	5b                   	pop    %ebx
f0100d2c:	5e                   	pop    %esi
f0100d2d:	5f                   	pop    %edi
f0100d2e:	5d                   	pop    %ebp
f0100d2f:	c3                   	ret    

f0100d30 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100d30:	55                   	push   %ebp
f0100d31:	89 e5                	mov    %esp,%ebp
f0100d33:	57                   	push   %edi
f0100d34:	56                   	push   %esi
f0100d35:	53                   	push   %ebx
f0100d36:	83 ec 1c             	sub    $0x1c,%esp
f0100d39:	89 c7                	mov    %eax,%edi
f0100d3b:	89 d6                	mov    %edx,%esi
f0100d3d:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d40:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100d43:	89 d1                	mov    %edx,%ecx
f0100d45:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100d48:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100d4b:	8b 45 10             	mov    0x10(%ebp),%eax
f0100d4e:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100d51:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100d54:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0100d5b:	39 4d e4             	cmp    %ecx,-0x1c(%ebp)
f0100d5e:	72 05                	jb     f0100d65 <printnum+0x35>
f0100d60:	3b 45 d8             	cmp    -0x28(%ebp),%eax
f0100d63:	77 3e                	ja     f0100da3 <printnum+0x73>
                               
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100d65:	83 ec 0c             	sub    $0xc,%esp
f0100d68:	ff 75 18             	pushl  0x18(%ebp)
f0100d6b:	83 eb 01             	sub    $0x1,%ebx
f0100d6e:	53                   	push   %ebx
f0100d6f:	50                   	push   %eax
f0100d70:	83 ec 08             	sub    $0x8,%esp
f0100d73:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100d76:	ff 75 e0             	pushl  -0x20(%ebp)
f0100d79:	ff 75 dc             	pushl  -0x24(%ebp)
f0100d7c:	ff 75 d8             	pushl  -0x28(%ebp)
f0100d7f:	e8 2c 13 00 00       	call   f01020b0 <__udivdi3>
f0100d84:	83 c4 18             	add    $0x18,%esp
f0100d87:	52                   	push   %edx
f0100d88:	50                   	push   %eax
f0100d89:	89 f2                	mov    %esi,%edx
f0100d8b:	89 f8                	mov    %edi,%eax
f0100d8d:	e8 9e ff ff ff       	call   f0100d30 <printnum>
f0100d92:	83 c4 20             	add    $0x20,%esp
f0100d95:	eb 13                	jmp    f0100daa <printnum+0x7a>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100d97:	83 ec 08             	sub    $0x8,%esp
f0100d9a:	56                   	push   %esi
f0100d9b:	ff 75 18             	pushl  0x18(%ebp)
f0100d9e:	ff d7                	call   *%edi
f0100da0:	83 c4 10             	add    $0x10,%esp
	if (num >= base) {
                               
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100da3:	83 eb 01             	sub    $0x1,%ebx
f0100da6:	85 db                	test   %ebx,%ebx
f0100da8:	7f ed                	jg     f0100d97 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100daa:	83 ec 08             	sub    $0x8,%esp
f0100dad:	56                   	push   %esi
f0100dae:	83 ec 04             	sub    $0x4,%esp
f0100db1:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100db4:	ff 75 e0             	pushl  -0x20(%ebp)
f0100db7:	ff 75 dc             	pushl  -0x24(%ebp)
f0100dba:	ff 75 d8             	pushl  -0x28(%ebp)
f0100dbd:	e8 1e 14 00 00       	call   f01021e0 <__umoddi3>
f0100dc2:	83 c4 14             	add    $0x14,%esp
f0100dc5:	0f be 80 15 29 10 f0 	movsbl -0xfefd6eb(%eax),%eax
f0100dcc:	50                   	push   %eax
f0100dcd:	ff d7                	call   *%edi
f0100dcf:	83 c4 10             	add    $0x10,%esp
       
}
f0100dd2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100dd5:	5b                   	pop    %ebx
f0100dd6:	5e                   	pop    %esi
f0100dd7:	5f                   	pop    %edi
f0100dd8:	5d                   	pop    %ebp
f0100dd9:	c3                   	ret    

f0100dda <printnum2>:
static void
printnum2(void (*putch)(int, void*), void *putdat,
	 double num_float, unsigned base, int width, int padc)
{      
f0100dda:	55                   	push   %ebp
f0100ddb:	89 e5                	mov    %esp,%ebp
f0100ddd:	57                   	push   %edi
f0100dde:	56                   	push   %esi
f0100ddf:	53                   	push   %ebx
f0100de0:	83 ec 3c             	sub    $0x3c,%esp
f0100de3:	89 c7                	mov    %eax,%edi
f0100de5:	89 d6                	mov    %edx,%esi
f0100de7:	dd 45 08             	fldl   0x8(%ebp)
f0100dea:	dd 55 d0             	fstl   -0x30(%ebp)
f0100ded:	89 4d cc             	mov    %ecx,-0x34(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num_float >= base) { 
f0100df0:	89 4d c0             	mov    %ecx,-0x40(%ebp)
f0100df3:	c7 45 c4 00 00 00 00 	movl   $0x0,-0x3c(%ebp)
f0100dfa:	df 6d c0             	fildll -0x40(%ebp)
f0100dfd:	d9 c9                	fxch   %st(1)
f0100dff:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0100e02:	db e9                	fucomi %st(1),%st
f0100e04:	72 2d                	jb     f0100e33 <printnum2+0x59>
		printnum2(putch, putdat, num_float / base, base, width - 1, padc);
f0100e06:	ff 75 14             	pushl  0x14(%ebp)
f0100e09:	8b 45 10             	mov    0x10(%ebp),%eax
f0100e0c:	83 e8 01             	sub    $0x1,%eax
f0100e0f:	50                   	push   %eax
f0100e10:	de f1                	fdivp  %st,%st(1)
f0100e12:	8d 64 24 f8          	lea    -0x8(%esp),%esp
f0100e16:	dd 1c 24             	fstpl  (%esp)
f0100e19:	89 f8                	mov    %edi,%eax
f0100e1b:	e8 ba ff ff ff       	call   f0100dda <printnum2>
f0100e20:	83 c4 10             	add    $0x10,%esp
f0100e23:	eb 2c                	jmp    f0100e51 <printnum2+0x77>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100e25:	83 ec 08             	sub    $0x8,%esp
f0100e28:	56                   	push   %esi
f0100e29:	ff 75 14             	pushl  0x14(%ebp)
f0100e2c:	ff d7                	call   *%edi
f0100e2e:	83 c4 10             	add    $0x10,%esp
f0100e31:	eb 04                	jmp    f0100e37 <printnum2+0x5d>
f0100e33:	dd d8                	fstp   %st(0)
f0100e35:	dd d8                	fstp   %st(0)
	// first recursively print all preceding (more significant) digits
	if (num_float >= base) { 
		printnum2(putch, putdat, num_float / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100e37:	83 eb 01             	sub    $0x1,%ebx
f0100e3a:	85 db                	test   %ebx,%ebx
f0100e3c:	7f e7                	jg     f0100e25 <printnum2+0x4b>
f0100e3e:	8b 55 10             	mov    0x10(%ebp),%edx
f0100e41:	83 ea 01             	sub    $0x1,%edx
f0100e44:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e49:	0f 49 c2             	cmovns %edx,%eax
f0100e4c:	29 c2                	sub    %eax,%edx
f0100e4e:	89 55 10             	mov    %edx,0x10(%ebp)
			putch(padc, putdat);
	}
        int x =(int)num_float;
	// then print this (the least significant) digit
	putch("0123456789abcdef"[x % base], putdat);
f0100e51:	83 ec 08             	sub    $0x8,%esp
f0100e54:	56                   	push   %esi
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
	}
        int x =(int)num_float;
f0100e55:	d9 7d de             	fnstcw -0x22(%ebp)
f0100e58:	0f b7 45 de          	movzwl -0x22(%ebp),%eax
f0100e5c:	b4 0c                	mov    $0xc,%ah
f0100e5e:	66 89 45 dc          	mov    %ax,-0x24(%ebp)
f0100e62:	dd 45 d0             	fldl   -0x30(%ebp)
f0100e65:	d9 6d dc             	fldcw  -0x24(%ebp)
f0100e68:	db 5d d8             	fistpl -0x28(%ebp)
f0100e6b:	d9 6d de             	fldcw  -0x22(%ebp)
f0100e6e:	8b 45 d8             	mov    -0x28(%ebp),%eax
	// then print this (the least significant) digit
	putch("0123456789abcdef"[x % base], putdat);
f0100e71:	ba 00 00 00 00       	mov    $0x0,%edx
f0100e76:	f7 75 cc             	divl   -0x34(%ebp)
f0100e79:	0f be 82 15 29 10 f0 	movsbl -0xfefd6eb(%edx),%eax
f0100e80:	50                   	push   %eax
f0100e81:	ff d7                	call   *%edi
        if ( width == -3) {
f0100e83:	83 c4 10             	add    $0x10,%esp
f0100e86:	83 7d 10 fd          	cmpl   $0xfffffffd,0x10(%ebp)
f0100e8a:	75 0b                	jne    f0100e97 <printnum2+0xbd>
        putch('.',putdat);}
f0100e8c:	83 ec 08             	sub    $0x8,%esp
f0100e8f:	56                   	push   %esi
f0100e90:	6a 2e                	push   $0x2e
f0100e92:	ff d7                	call   *%edi
f0100e94:	83 c4 10             	add    $0x10,%esp
}
f0100e97:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e9a:	5b                   	pop    %ebx
f0100e9b:	5e                   	pop    %esi
f0100e9c:	5f                   	pop    %edi
f0100e9d:	5d                   	pop    %ebp
f0100e9e:	c3                   	ret    

f0100e9f <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100e9f:	55                   	push   %ebp
f0100ea0:	89 e5                	mov    %esp,%ebp
f0100ea2:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100ea5:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100ea9:	8b 10                	mov    (%eax),%edx
f0100eab:	3b 50 04             	cmp    0x4(%eax),%edx
f0100eae:	73 0a                	jae    f0100eba <sprintputch+0x1b>
		*b->buf++ = ch;
f0100eb0:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100eb3:	89 08                	mov    %ecx,(%eax)
f0100eb5:	8b 45 08             	mov    0x8(%ebp),%eax
f0100eb8:	88 02                	mov    %al,(%edx)
}
f0100eba:	5d                   	pop    %ebp
f0100ebb:	c3                   	ret    

f0100ebc <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100ebc:	55                   	push   %ebp
f0100ebd:	89 e5                	mov    %esp,%ebp
f0100ebf:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100ec2:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100ec5:	50                   	push   %eax
f0100ec6:	ff 75 10             	pushl  0x10(%ebp)
f0100ec9:	ff 75 0c             	pushl  0xc(%ebp)
f0100ecc:	ff 75 08             	pushl  0x8(%ebp)
f0100ecf:	e8 05 00 00 00       	call   f0100ed9 <vprintfmt>
	va_end(ap);
f0100ed4:	83 c4 10             	add    $0x10,%esp
}
f0100ed7:	c9                   	leave  
f0100ed8:	c3                   	ret    

f0100ed9 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100ed9:	55                   	push   %ebp
f0100eda:	89 e5                	mov    %esp,%ebp
f0100edc:	57                   	push   %edi
f0100edd:	56                   	push   %esi
f0100ede:	53                   	push   %ebx
f0100edf:	83 ec 2c             	sub    $0x2c,%esp
f0100ee2:	8b 75 08             	mov    0x8(%ebp),%esi
f0100ee5:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100ee8:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100eeb:	eb 12                	jmp    f0100eff <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100eed:	85 c0                	test   %eax,%eax
f0100eef:	0f 84 92 04 00 00    	je     f0101387 <vprintfmt+0x4ae>
				return;
			putch(ch, putdat);
f0100ef5:	83 ec 08             	sub    $0x8,%esp
f0100ef8:	53                   	push   %ebx
f0100ef9:	50                   	push   %eax
f0100efa:	ff d6                	call   *%esi
f0100efc:	83 c4 10             	add    $0x10,%esp
        double num_float;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100eff:	83 c7 01             	add    $0x1,%edi
f0100f02:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0100f06:	83 f8 25             	cmp    $0x25,%eax
f0100f09:	75 e2                	jne    f0100eed <vprintfmt+0x14>
f0100f0b:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0100f0f:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100f16:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100f1d:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0100f24:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100f29:	eb 07                	jmp    f0100f32 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f2b:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100f2e:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f32:	8d 47 01             	lea    0x1(%edi),%eax
f0100f35:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100f38:	0f b6 07             	movzbl (%edi),%eax
f0100f3b:	0f b6 d0             	movzbl %al,%edx
f0100f3e:	83 e8 23             	sub    $0x23,%eax
f0100f41:	3c 55                	cmp    $0x55,%al
f0100f43:	0f 87 23 04 00 00    	ja     f010136c <vprintfmt+0x493>
f0100f49:	0f b6 c0             	movzbl %al,%eax
f0100f4c:	ff 24 85 c0 29 10 f0 	jmp    *-0xfefd640(,%eax,4)
f0100f53:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100f56:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0100f5a:	eb d6                	jmp    f0100f32 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f5c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100f5f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f64:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100f67:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100f6a:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0100f6e:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0100f71:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0100f74:	83 f9 09             	cmp    $0x9,%ecx
f0100f77:	77 3f                	ja     f0100fb8 <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100f79:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0100f7c:	eb e9                	jmp    f0100f67 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100f7e:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f81:	8b 00                	mov    (%eax),%eax
f0100f83:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100f86:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f89:	8d 40 04             	lea    0x4(%eax),%eax
f0100f8c:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f8f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100f92:	eb 2a                	jmp    f0100fbe <vprintfmt+0xe5>
f0100f94:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100f97:	85 c0                	test   %eax,%eax
f0100f99:	ba 00 00 00 00       	mov    $0x0,%edx
f0100f9e:	0f 49 d0             	cmovns %eax,%edx
f0100fa1:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fa4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100fa7:	eb 89                	jmp    f0100f32 <vprintfmt+0x59>
f0100fa9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100fac:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0100fb3:	e9 7a ff ff ff       	jmp    f0100f32 <vprintfmt+0x59>
f0100fb8:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100fbb:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0100fbe:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100fc2:	0f 89 6a ff ff ff    	jns    f0100f32 <vprintfmt+0x59>
				width = precision, precision = -1;
f0100fc8:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100fcb:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100fce:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100fd5:	e9 58 ff ff ff       	jmp    f0100f32 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100fda:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fdd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100fe0:	e9 4d ff ff ff       	jmp    f0100f32 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fe5:	8b 45 14             	mov    0x14(%ebp),%eax
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100fe8:	83 45 14 04          	addl   $0x4,0x14(%ebp)
f0100fec:	83 ec 08             	sub    $0x8,%esp
f0100fef:	53                   	push   %ebx
f0100ff0:	ff 30                	pushl  (%eax)
f0100ff2:	ff d6                	call   *%esi
			break;
f0100ff4:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ff7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0100ffa:	e9 00 ff ff ff       	jmp    f0100eff <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100fff:	8b 45 14             	mov    0x14(%ebp),%eax
f0101002:	8d 78 04             	lea    0x4(%eax),%edi
f0101005:	8b 00                	mov    (%eax),%eax
f0101007:	99                   	cltd   
f0101008:	31 d0                	xor    %edx,%eax
f010100a:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010100c:	83 f8 07             	cmp    $0x7,%eax
f010100f:	7f 0b                	jg     f010101c <vprintfmt+0x143>
f0101011:	8b 14 85 20 2b 10 f0 	mov    -0xfefd4e0(,%eax,4),%edx
f0101018:	85 d2                	test   %edx,%edx
f010101a:	75 1b                	jne    f0101037 <vprintfmt+0x15e>
				printfmt(putch, putdat, "error %d", err);
f010101c:	50                   	push   %eax
f010101d:	68 2d 29 10 f0       	push   $0xf010292d
f0101022:	53                   	push   %ebx
f0101023:	56                   	push   %esi
f0101024:	e8 93 fe ff ff       	call   f0100ebc <printfmt>
f0101029:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f010102c:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010102f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0101032:	e9 c8 fe ff ff       	jmp    f0100eff <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0101037:	52                   	push   %edx
f0101038:	68 36 29 10 f0       	push   $0xf0102936
f010103d:	53                   	push   %ebx
f010103e:	56                   	push   %esi
f010103f:	e8 78 fe ff ff       	call   f0100ebc <printfmt>
f0101044:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0101047:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010104a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010104d:	e9 ad fe ff ff       	jmp    f0100eff <vprintfmt+0x26>
f0101052:	8b 45 14             	mov    0x14(%ebp),%eax
f0101055:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0101058:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f010105b:	89 4d cc             	mov    %ecx,-0x34(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f010105e:	83 45 14 04          	addl   $0x4,0x14(%ebp)
f0101062:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0101064:	85 ff                	test   %edi,%edi
f0101066:	b8 26 29 10 f0       	mov    $0xf0102926,%eax
f010106b:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f010106e:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0101072:	0f 84 90 00 00 00    	je     f0101108 <vprintfmt+0x22f>
f0101078:	85 c9                	test   %ecx,%ecx
f010107a:	0f 8e 96 00 00 00    	jle    f0101116 <vprintfmt+0x23d>
				for (width -= strnlen(p, precision); width > 0; width--)
f0101080:	83 ec 08             	sub    $0x8,%esp
f0101083:	52                   	push   %edx
f0101084:	57                   	push   %edi
f0101085:	e8 5e 04 00 00       	call   f01014e8 <strnlen>
f010108a:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f010108d:	29 c1                	sub    %eax,%ecx
f010108f:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0101092:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0101095:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0101099:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010109c:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f010109f:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01010a1:	eb 0f                	jmp    f01010b2 <vprintfmt+0x1d9>
					putch(padc, putdat);
f01010a3:	83 ec 08             	sub    $0x8,%esp
f01010a6:	53                   	push   %ebx
f01010a7:	ff 75 e0             	pushl  -0x20(%ebp)
f01010aa:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01010ac:	83 ef 01             	sub    $0x1,%edi
f01010af:	83 c4 10             	add    $0x10,%esp
f01010b2:	85 ff                	test   %edi,%edi
f01010b4:	7f ed                	jg     f01010a3 <vprintfmt+0x1ca>
f01010b6:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01010b9:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f01010bc:	85 c9                	test   %ecx,%ecx
f01010be:	b8 00 00 00 00       	mov    $0x0,%eax
f01010c3:	0f 49 c1             	cmovns %ecx,%eax
f01010c6:	29 c1                	sub    %eax,%ecx
f01010c8:	89 75 08             	mov    %esi,0x8(%ebp)
f01010cb:	8b 75 d0             	mov    -0x30(%ebp),%esi
f01010ce:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01010d1:	89 cb                	mov    %ecx,%ebx
f01010d3:	eb 4d                	jmp    f0101122 <vprintfmt+0x249>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f01010d5:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01010d9:	74 1b                	je     f01010f6 <vprintfmt+0x21d>
f01010db:	0f be c0             	movsbl %al,%eax
f01010de:	83 e8 20             	sub    $0x20,%eax
f01010e1:	83 f8 5e             	cmp    $0x5e,%eax
f01010e4:	76 10                	jbe    f01010f6 <vprintfmt+0x21d>
					putch('?', putdat);
f01010e6:	83 ec 08             	sub    $0x8,%esp
f01010e9:	ff 75 0c             	pushl  0xc(%ebp)
f01010ec:	6a 3f                	push   $0x3f
f01010ee:	ff 55 08             	call   *0x8(%ebp)
f01010f1:	83 c4 10             	add    $0x10,%esp
f01010f4:	eb 0d                	jmp    f0101103 <vprintfmt+0x22a>
				else
					putch(ch, putdat);
f01010f6:	83 ec 08             	sub    $0x8,%esp
f01010f9:	ff 75 0c             	pushl  0xc(%ebp)
f01010fc:	52                   	push   %edx
f01010fd:	ff 55 08             	call   *0x8(%ebp)
f0101100:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101103:	83 eb 01             	sub    $0x1,%ebx
f0101106:	eb 1a                	jmp    f0101122 <vprintfmt+0x249>
f0101108:	89 75 08             	mov    %esi,0x8(%ebp)
f010110b:	8b 75 d0             	mov    -0x30(%ebp),%esi
f010110e:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101111:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0101114:	eb 0c                	jmp    f0101122 <vprintfmt+0x249>
f0101116:	89 75 08             	mov    %esi,0x8(%ebp)
f0101119:	8b 75 d0             	mov    -0x30(%ebp),%esi
f010111c:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010111f:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0101122:	83 c7 01             	add    $0x1,%edi
f0101125:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0101129:	0f be d0             	movsbl %al,%edx
f010112c:	85 d2                	test   %edx,%edx
f010112e:	74 23                	je     f0101153 <vprintfmt+0x27a>
f0101130:	85 f6                	test   %esi,%esi
f0101132:	78 a1                	js     f01010d5 <vprintfmt+0x1fc>
f0101134:	83 ee 01             	sub    $0x1,%esi
f0101137:	79 9c                	jns    f01010d5 <vprintfmt+0x1fc>
f0101139:	89 df                	mov    %ebx,%edi
f010113b:	8b 75 08             	mov    0x8(%ebp),%esi
f010113e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101141:	eb 18                	jmp    f010115b <vprintfmt+0x282>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0101143:	83 ec 08             	sub    $0x8,%esp
f0101146:	53                   	push   %ebx
f0101147:	6a 20                	push   $0x20
f0101149:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f010114b:	83 ef 01             	sub    $0x1,%edi
f010114e:	83 c4 10             	add    $0x10,%esp
f0101151:	eb 08                	jmp    f010115b <vprintfmt+0x282>
f0101153:	89 df                	mov    %ebx,%edi
f0101155:	8b 75 08             	mov    0x8(%ebp),%esi
f0101158:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010115b:	85 ff                	test   %edi,%edi
f010115d:	7f e4                	jg     f0101143 <vprintfmt+0x26a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010115f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101162:	e9 98 fd ff ff       	jmp    f0100eff <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101167:	83 f9 01             	cmp    $0x1,%ecx
f010116a:	7e 19                	jle    f0101185 <vprintfmt+0x2ac>
		return va_arg(*ap, long long);
f010116c:	8b 45 14             	mov    0x14(%ebp),%eax
f010116f:	8b 50 04             	mov    0x4(%eax),%edx
f0101172:	8b 00                	mov    (%eax),%eax
f0101174:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101177:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010117a:	8b 45 14             	mov    0x14(%ebp),%eax
f010117d:	8d 40 08             	lea    0x8(%eax),%eax
f0101180:	89 45 14             	mov    %eax,0x14(%ebp)
f0101183:	eb 38                	jmp    f01011bd <vprintfmt+0x2e4>
	else if (lflag)
f0101185:	85 c9                	test   %ecx,%ecx
f0101187:	74 1b                	je     f01011a4 <vprintfmt+0x2cb>
		return va_arg(*ap, long);
f0101189:	8b 45 14             	mov    0x14(%ebp),%eax
f010118c:	8b 00                	mov    (%eax),%eax
f010118e:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101191:	89 c1                	mov    %eax,%ecx
f0101193:	c1 f9 1f             	sar    $0x1f,%ecx
f0101196:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0101199:	8b 45 14             	mov    0x14(%ebp),%eax
f010119c:	8d 40 04             	lea    0x4(%eax),%eax
f010119f:	89 45 14             	mov    %eax,0x14(%ebp)
f01011a2:	eb 19                	jmp    f01011bd <vprintfmt+0x2e4>
	else
		return va_arg(*ap, int);
f01011a4:	8b 45 14             	mov    0x14(%ebp),%eax
f01011a7:	8b 00                	mov    (%eax),%eax
f01011a9:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01011ac:	89 c1                	mov    %eax,%ecx
f01011ae:	c1 f9 1f             	sar    $0x1f,%ecx
f01011b1:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01011b4:	8b 45 14             	mov    0x14(%ebp),%eax
f01011b7:	8d 40 04             	lea    0x4(%eax),%eax
f01011ba:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f01011bd:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01011c0:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01011c3:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01011c8:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01011cc:	0f 89 66 01 00 00    	jns    f0101338 <vprintfmt+0x45f>
				putch('-', putdat);
f01011d2:	83 ec 08             	sub    $0x8,%esp
f01011d5:	53                   	push   %ebx
f01011d6:	6a 2d                	push   $0x2d
f01011d8:	ff d6                	call   *%esi
				num = -(long long) num;
f01011da:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01011dd:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01011e0:	f7 da                	neg    %edx
f01011e2:	83 d1 00             	adc    $0x0,%ecx
f01011e5:	f7 d9                	neg    %ecx
f01011e7:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f01011ea:	b8 0a 00 00 00       	mov    $0xa,%eax
f01011ef:	e9 44 01 00 00       	jmp    f0101338 <vprintfmt+0x45f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01011f4:	83 f9 01             	cmp    $0x1,%ecx
f01011f7:	7e 18                	jle    f0101211 <vprintfmt+0x338>
		return va_arg(*ap, unsigned long long);
f01011f9:	8b 45 14             	mov    0x14(%ebp),%eax
f01011fc:	8b 10                	mov    (%eax),%edx
f01011fe:	8b 48 04             	mov    0x4(%eax),%ecx
f0101201:	8d 40 08             	lea    0x8(%eax),%eax
f0101204:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0101207:	b8 0a 00 00 00       	mov    $0xa,%eax
f010120c:	e9 27 01 00 00       	jmp    f0101338 <vprintfmt+0x45f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0101211:	85 c9                	test   %ecx,%ecx
f0101213:	74 1a                	je     f010122f <vprintfmt+0x356>
		return va_arg(*ap, unsigned long);
f0101215:	8b 45 14             	mov    0x14(%ebp),%eax
f0101218:	8b 10                	mov    (%eax),%edx
f010121a:	b9 00 00 00 00       	mov    $0x0,%ecx
f010121f:	8d 40 04             	lea    0x4(%eax),%eax
f0101222:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0101225:	b8 0a 00 00 00       	mov    $0xa,%eax
f010122a:	e9 09 01 00 00       	jmp    f0101338 <vprintfmt+0x45f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f010122f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101232:	8b 10                	mov    (%eax),%edx
f0101234:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101239:	8d 40 04             	lea    0x4(%eax),%eax
f010123c:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f010123f:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101244:	e9 ef 00 00 00       	jmp    f0101338 <vprintfmt+0x45f>
			goto number;

               // signed float
		case 'f':
			num_float = va_arg(ap, double);
f0101249:	8b 45 14             	mov    0x14(%ebp),%eax
f010124c:	8d 78 08             	lea    0x8(%eax),%edi
                        num_float = num_float*100;
f010124f:	d9 05 40 2b 10 f0    	flds   0xf0102b40
f0101255:	dc 08                	fmull  (%eax)
f0101257:	d9 c0                	fld    %st(0)
f0101259:	dd 5d d8             	fstpl  -0x28(%ebp)
			if ( num_float < 0) {
f010125c:	d9 ee                	fldz   
f010125e:	df e9                	fucomip %st(1),%st
f0101260:	dd d8                	fstp   %st(0)
f0101262:	76 13                	jbe    f0101277 <vprintfmt+0x39e>
				putch('-', putdat);
f0101264:	83 ec 08             	sub    $0x8,%esp
f0101267:	53                   	push   %ebx
f0101268:	6a 2d                	push   $0x2d
f010126a:	ff d6                	call   *%esi
				num_float = - num_float;
f010126c:	dd 45 d8             	fldl   -0x28(%ebp)
f010126f:	d9 e0                	fchs   
f0101271:	dd 5d d8             	fstpl  -0x28(%ebp)
f0101274:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
                        
			printnum2(putch, putdat, num_float, base, width, padc);
f0101277:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f010127b:	50                   	push   %eax
f010127c:	ff 75 e0             	pushl  -0x20(%ebp)
f010127f:	ff 75 dc             	pushl  -0x24(%ebp)
f0101282:	ff 75 d8             	pushl  -0x28(%ebp)
f0101285:	b9 0a 00 00 00       	mov    $0xa,%ecx
f010128a:	89 da                	mov    %ebx,%edx
f010128c:	89 f0                	mov    %esi,%eax
f010128e:	e8 47 fb ff ff       	call   f0100dda <printnum2>
			break;
f0101293:	83 c4 10             	add    $0x10,%esp
			base = 10;
			goto number;

               // signed float
		case 'f':
			num_float = va_arg(ap, double);
f0101296:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101299:	8b 7d e4             	mov    -0x1c(%ebp),%edi
				num_float = - num_float;
			}
			base = 10;
                        
			printnum2(putch, putdat, num_float, base, width, padc);
			break;
f010129c:	e9 5e fc ff ff       	jmp    f0100eff <vprintfmt+0x26>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f01012a1:	83 ec 08             	sub    $0x8,%esp
f01012a4:	53                   	push   %ebx
f01012a5:	6a 58                	push   $0x58
f01012a7:	ff d6                	call   *%esi
			putch('X', putdat);
f01012a9:	83 c4 08             	add    $0x8,%esp
f01012ac:	53                   	push   %ebx
f01012ad:	6a 58                	push   $0x58
f01012af:	ff d6                	call   *%esi
			putch('X', putdat);
f01012b1:	83 c4 08             	add    $0x8,%esp
f01012b4:	53                   	push   %ebx
f01012b5:	6a 58                	push   $0x58
f01012b7:	ff d6                	call   *%esi
			break;
f01012b9:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01012bc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
f01012bf:	e9 3b fc ff ff       	jmp    f0100eff <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
f01012c4:	83 ec 08             	sub    $0x8,%esp
f01012c7:	53                   	push   %ebx
f01012c8:	6a 30                	push   $0x30
f01012ca:	ff d6                	call   *%esi
			putch('x', putdat);
f01012cc:	83 c4 08             	add    $0x8,%esp
f01012cf:	53                   	push   %ebx
f01012d0:	6a 78                	push   $0x78
f01012d2:	ff d6                	call   *%esi
			num = (unsigned long long)
f01012d4:	8b 45 14             	mov    0x14(%ebp),%eax
f01012d7:	8b 10                	mov    (%eax),%edx
f01012d9:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f01012de:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01012e1:	8d 40 04             	lea    0x4(%eax),%eax
f01012e4:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01012e7:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f01012ec:	eb 4a                	jmp    f0101338 <vprintfmt+0x45f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01012ee:	83 f9 01             	cmp    $0x1,%ecx
f01012f1:	7e 15                	jle    f0101308 <vprintfmt+0x42f>
		return va_arg(*ap, unsigned long long);
f01012f3:	8b 45 14             	mov    0x14(%ebp),%eax
f01012f6:	8b 10                	mov    (%eax),%edx
f01012f8:	8b 48 04             	mov    0x4(%eax),%ecx
f01012fb:	8d 40 08             	lea    0x8(%eax),%eax
f01012fe:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0101301:	b8 10 00 00 00       	mov    $0x10,%eax
f0101306:	eb 30                	jmp    f0101338 <vprintfmt+0x45f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0101308:	85 c9                	test   %ecx,%ecx
f010130a:	74 17                	je     f0101323 <vprintfmt+0x44a>
		return va_arg(*ap, unsigned long);
f010130c:	8b 45 14             	mov    0x14(%ebp),%eax
f010130f:	8b 10                	mov    (%eax),%edx
f0101311:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101316:	8d 40 04             	lea    0x4(%eax),%eax
f0101319:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f010131c:	b8 10 00 00 00       	mov    $0x10,%eax
f0101321:	eb 15                	jmp    f0101338 <vprintfmt+0x45f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0101323:	8b 45 14             	mov    0x14(%ebp),%eax
f0101326:	8b 10                	mov    (%eax),%edx
f0101328:	b9 00 00 00 00       	mov    $0x0,%ecx
f010132d:	8d 40 04             	lea    0x4(%eax),%eax
f0101330:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0101333:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101338:	83 ec 0c             	sub    $0xc,%esp
f010133b:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f010133f:	57                   	push   %edi
f0101340:	ff 75 e0             	pushl  -0x20(%ebp)
f0101343:	50                   	push   %eax
f0101344:	51                   	push   %ecx
f0101345:	52                   	push   %edx
f0101346:	89 da                	mov    %ebx,%edx
f0101348:	89 f0                	mov    %esi,%eax
f010134a:	e8 e1 f9 ff ff       	call   f0100d30 <printnum>
			break;
f010134f:	83 c4 20             	add    $0x20,%esp
f0101352:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101355:	e9 a5 fb ff ff       	jmp    f0100eff <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f010135a:	83 ec 08             	sub    $0x8,%esp
f010135d:	53                   	push   %ebx
f010135e:	52                   	push   %edx
f010135f:	ff d6                	call   *%esi
			break;
f0101361:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101364:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0101367:	e9 93 fb ff ff       	jmp    f0100eff <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f010136c:	83 ec 08             	sub    $0x8,%esp
f010136f:	53                   	push   %ebx
f0101370:	6a 25                	push   $0x25
f0101372:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101374:	83 c4 10             	add    $0x10,%esp
f0101377:	eb 03                	jmp    f010137c <vprintfmt+0x4a3>
f0101379:	83 ef 01             	sub    $0x1,%edi
f010137c:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0101380:	75 f7                	jne    f0101379 <vprintfmt+0x4a0>
f0101382:	e9 78 fb ff ff       	jmp    f0100eff <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0101387:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010138a:	5b                   	pop    %ebx
f010138b:	5e                   	pop    %esi
f010138c:	5f                   	pop    %edi
f010138d:	5d                   	pop    %ebp
f010138e:	c3                   	ret    

f010138f <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f010138f:	55                   	push   %ebp
f0101390:	89 e5                	mov    %esp,%ebp
f0101392:	83 ec 18             	sub    $0x18,%esp
f0101395:	8b 45 08             	mov    0x8(%ebp),%eax
f0101398:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010139b:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010139e:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01013a2:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01013a5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01013ac:	85 c0                	test   %eax,%eax
f01013ae:	74 26                	je     f01013d6 <vsnprintf+0x47>
f01013b0:	85 d2                	test   %edx,%edx
f01013b2:	7e 22                	jle    f01013d6 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01013b4:	ff 75 14             	pushl  0x14(%ebp)
f01013b7:	ff 75 10             	pushl  0x10(%ebp)
f01013ba:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01013bd:	50                   	push   %eax
f01013be:	68 9f 0e 10 f0       	push   $0xf0100e9f
f01013c3:	e8 11 fb ff ff       	call   f0100ed9 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01013c8:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01013cb:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01013ce:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01013d1:	83 c4 10             	add    $0x10,%esp
f01013d4:	eb 05                	jmp    f01013db <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01013d6:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01013db:	c9                   	leave  
f01013dc:	c3                   	ret    

f01013dd <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01013dd:	55                   	push   %ebp
f01013de:	89 e5                	mov    %esp,%ebp
f01013e0:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01013e3:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01013e6:	50                   	push   %eax
f01013e7:	ff 75 10             	pushl  0x10(%ebp)
f01013ea:	ff 75 0c             	pushl  0xc(%ebp)
f01013ed:	ff 75 08             	pushl  0x8(%ebp)
f01013f0:	e8 9a ff ff ff       	call   f010138f <vsnprintf>
	va_end(ap);

	return rc;
f01013f5:	c9                   	leave  
f01013f6:	c3                   	ret    

f01013f7 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01013f7:	55                   	push   %ebp
f01013f8:	89 e5                	mov    %esp,%ebp
f01013fa:	57                   	push   %edi
f01013fb:	56                   	push   %esi
f01013fc:	53                   	push   %ebx
f01013fd:	83 ec 0c             	sub    $0xc,%esp
f0101400:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0101403:	85 c0                	test   %eax,%eax
f0101405:	74 11                	je     f0101418 <readline+0x21>
		cprintf("%s", prompt);
f0101407:	83 ec 08             	sub    $0x8,%esp
f010140a:	50                   	push   %eax
f010140b:	68 36 29 10 f0       	push   $0xf0102936
f0101410:	e8 2e f6 ff ff       	call   f0100a43 <cprintf>
f0101415:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0101418:	83 ec 0c             	sub    $0xc,%esp
f010141b:	6a 00                	push   $0x0
f010141d:	e8 3a f2 ff ff       	call   f010065c <iscons>
f0101422:	89 c7                	mov    %eax,%edi
f0101424:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0101427:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f010142c:	e8 1a f2 ff ff       	call   f010064b <getchar>
f0101431:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0101433:	85 c0                	test   %eax,%eax
f0101435:	79 18                	jns    f010144f <readline+0x58>
			cprintf("read error: %e\n", c);
f0101437:	83 ec 08             	sub    $0x8,%esp
f010143a:	50                   	push   %eax
f010143b:	68 44 2b 10 f0       	push   $0xf0102b44
f0101440:	e8 fe f5 ff ff       	call   f0100a43 <cprintf>
			return NULL;
f0101445:	83 c4 10             	add    $0x10,%esp
f0101448:	b8 00 00 00 00       	mov    $0x0,%eax
f010144d:	eb 79                	jmp    f01014c8 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f010144f:	83 f8 7f             	cmp    $0x7f,%eax
f0101452:	0f 94 c2             	sete   %dl
f0101455:	83 f8 08             	cmp    $0x8,%eax
f0101458:	0f 94 c0             	sete   %al
f010145b:	08 c2                	or     %al,%dl
f010145d:	74 1a                	je     f0101479 <readline+0x82>
f010145f:	85 f6                	test   %esi,%esi
f0101461:	7e 16                	jle    f0101479 <readline+0x82>
			if (echoing)
f0101463:	85 ff                	test   %edi,%edi
f0101465:	74 0d                	je     f0101474 <readline+0x7d>
				cputchar('\b');
f0101467:	83 ec 0c             	sub    $0xc,%esp
f010146a:	6a 08                	push   $0x8
f010146c:	e8 ca f1 ff ff       	call   f010063b <cputchar>
f0101471:	83 c4 10             	add    $0x10,%esp
			i--;
f0101474:	83 ee 01             	sub    $0x1,%esi
f0101477:	eb b3                	jmp    f010142c <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101479:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010147f:	7f 20                	jg     f01014a1 <readline+0xaa>
f0101481:	83 fb 1f             	cmp    $0x1f,%ebx
f0101484:	7e 1b                	jle    f01014a1 <readline+0xaa>
			if (echoing)
f0101486:	85 ff                	test   %edi,%edi
f0101488:	74 0c                	je     f0101496 <readline+0x9f>
				cputchar(c);
f010148a:	83 ec 0c             	sub    $0xc,%esp
f010148d:	53                   	push   %ebx
f010148e:	e8 a8 f1 ff ff       	call   f010063b <cputchar>
f0101493:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0101496:	88 9e 80 45 11 f0    	mov    %bl,-0xfeeba80(%esi)
f010149c:	8d 76 01             	lea    0x1(%esi),%esi
f010149f:	eb 8b                	jmp    f010142c <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f01014a1:	83 fb 0d             	cmp    $0xd,%ebx
f01014a4:	74 05                	je     f01014ab <readline+0xb4>
f01014a6:	83 fb 0a             	cmp    $0xa,%ebx
f01014a9:	75 81                	jne    f010142c <readline+0x35>
			if (echoing)
f01014ab:	85 ff                	test   %edi,%edi
f01014ad:	74 0d                	je     f01014bc <readline+0xc5>
				cputchar('\n');
f01014af:	83 ec 0c             	sub    $0xc,%esp
f01014b2:	6a 0a                	push   $0xa
f01014b4:	e8 82 f1 ff ff       	call   f010063b <cputchar>
f01014b9:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f01014bc:	c6 86 80 45 11 f0 00 	movb   $0x0,-0xfeeba80(%esi)
			return buf;
f01014c3:	b8 80 45 11 f0       	mov    $0xf0114580,%eax
		}
	}
}
f01014c8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01014cb:	5b                   	pop    %ebx
f01014cc:	5e                   	pop    %esi
f01014cd:	5f                   	pop    %edi
f01014ce:	5d                   	pop    %ebp
f01014cf:	c3                   	ret    

f01014d0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01014d0:	55                   	push   %ebp
f01014d1:	89 e5                	mov    %esp,%ebp
f01014d3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01014d6:	b8 00 00 00 00       	mov    $0x0,%eax
f01014db:	eb 03                	jmp    f01014e0 <strlen+0x10>
		n++;
f01014dd:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01014e0:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01014e4:	75 f7                	jne    f01014dd <strlen+0xd>
		n++;
	return n;
}
f01014e6:	5d                   	pop    %ebp
f01014e7:	c3                   	ret    

f01014e8 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01014e8:	55                   	push   %ebp
f01014e9:	89 e5                	mov    %esp,%ebp
f01014eb:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01014ee:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01014f1:	ba 00 00 00 00       	mov    $0x0,%edx
f01014f6:	eb 03                	jmp    f01014fb <strnlen+0x13>
		n++;
f01014f8:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01014fb:	39 c2                	cmp    %eax,%edx
f01014fd:	74 08                	je     f0101507 <strnlen+0x1f>
f01014ff:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0101503:	75 f3                	jne    f01014f8 <strnlen+0x10>
f0101505:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0101507:	5d                   	pop    %ebp
f0101508:	c3                   	ret    

f0101509 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101509:	55                   	push   %ebp
f010150a:	89 e5                	mov    %esp,%ebp
f010150c:	53                   	push   %ebx
f010150d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101510:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101513:	89 c2                	mov    %eax,%edx
f0101515:	83 c2 01             	add    $0x1,%edx
f0101518:	83 c1 01             	add    $0x1,%ecx
f010151b:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010151f:	88 5a ff             	mov    %bl,-0x1(%edx)
f0101522:	84 db                	test   %bl,%bl
f0101524:	75 ef                	jne    f0101515 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101526:	5b                   	pop    %ebx
f0101527:	5d                   	pop    %ebp
f0101528:	c3                   	ret    

f0101529 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101529:	55                   	push   %ebp
f010152a:	89 e5                	mov    %esp,%ebp
f010152c:	53                   	push   %ebx
f010152d:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101530:	53                   	push   %ebx
f0101531:	e8 9a ff ff ff       	call   f01014d0 <strlen>
f0101536:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0101539:	ff 75 0c             	pushl  0xc(%ebp)
f010153c:	01 d8                	add    %ebx,%eax
f010153e:	50                   	push   %eax
f010153f:	e8 c5 ff ff ff       	call   f0101509 <strcpy>
	return dst;
}
f0101544:	89 d8                	mov    %ebx,%eax
f0101546:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101549:	c9                   	leave  
f010154a:	c3                   	ret    

f010154b <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010154b:	55                   	push   %ebp
f010154c:	89 e5                	mov    %esp,%ebp
f010154e:	56                   	push   %esi
f010154f:	53                   	push   %ebx
f0101550:	8b 75 08             	mov    0x8(%ebp),%esi
f0101553:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101556:	89 f3                	mov    %esi,%ebx
f0101558:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010155b:	89 f2                	mov    %esi,%edx
f010155d:	eb 0f                	jmp    f010156e <strncpy+0x23>
		*dst++ = *src;
f010155f:	83 c2 01             	add    $0x1,%edx
f0101562:	0f b6 01             	movzbl (%ecx),%eax
f0101565:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101568:	80 39 01             	cmpb   $0x1,(%ecx)
f010156b:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010156e:	39 da                	cmp    %ebx,%edx
f0101570:	75 ed                	jne    f010155f <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101572:	89 f0                	mov    %esi,%eax
f0101574:	5b                   	pop    %ebx
f0101575:	5e                   	pop    %esi
f0101576:	5d                   	pop    %ebp
f0101577:	c3                   	ret    

f0101578 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101578:	55                   	push   %ebp
f0101579:	89 e5                	mov    %esp,%ebp
f010157b:	56                   	push   %esi
f010157c:	53                   	push   %ebx
f010157d:	8b 75 08             	mov    0x8(%ebp),%esi
f0101580:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101583:	8b 55 10             	mov    0x10(%ebp),%edx
f0101586:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101588:	85 d2                	test   %edx,%edx
f010158a:	74 21                	je     f01015ad <strlcpy+0x35>
f010158c:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0101590:	89 f2                	mov    %esi,%edx
f0101592:	eb 09                	jmp    f010159d <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101594:	83 c2 01             	add    $0x1,%edx
f0101597:	83 c1 01             	add    $0x1,%ecx
f010159a:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f010159d:	39 c2                	cmp    %eax,%edx
f010159f:	74 09                	je     f01015aa <strlcpy+0x32>
f01015a1:	0f b6 19             	movzbl (%ecx),%ebx
f01015a4:	84 db                	test   %bl,%bl
f01015a6:	75 ec                	jne    f0101594 <strlcpy+0x1c>
f01015a8:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f01015aa:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01015ad:	29 f0                	sub    %esi,%eax
}
f01015af:	5b                   	pop    %ebx
f01015b0:	5e                   	pop    %esi
f01015b1:	5d                   	pop    %ebp
f01015b2:	c3                   	ret    

f01015b3 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01015b3:	55                   	push   %ebp
f01015b4:	89 e5                	mov    %esp,%ebp
f01015b6:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01015b9:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01015bc:	eb 06                	jmp    f01015c4 <strcmp+0x11>
		p++, q++;
f01015be:	83 c1 01             	add    $0x1,%ecx
f01015c1:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01015c4:	0f b6 01             	movzbl (%ecx),%eax
f01015c7:	84 c0                	test   %al,%al
f01015c9:	74 04                	je     f01015cf <strcmp+0x1c>
f01015cb:	3a 02                	cmp    (%edx),%al
f01015cd:	74 ef                	je     f01015be <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01015cf:	0f b6 c0             	movzbl %al,%eax
f01015d2:	0f b6 12             	movzbl (%edx),%edx
f01015d5:	29 d0                	sub    %edx,%eax
}
f01015d7:	5d                   	pop    %ebp
f01015d8:	c3                   	ret    

f01015d9 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01015d9:	55                   	push   %ebp
f01015da:	89 e5                	mov    %esp,%ebp
f01015dc:	53                   	push   %ebx
f01015dd:	8b 45 08             	mov    0x8(%ebp),%eax
f01015e0:	8b 55 0c             	mov    0xc(%ebp),%edx
f01015e3:	89 c3                	mov    %eax,%ebx
f01015e5:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01015e8:	eb 06                	jmp    f01015f0 <strncmp+0x17>
		n--, p++, q++;
f01015ea:	83 c0 01             	add    $0x1,%eax
f01015ed:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01015f0:	39 d8                	cmp    %ebx,%eax
f01015f2:	74 15                	je     f0101609 <strncmp+0x30>
f01015f4:	0f b6 08             	movzbl (%eax),%ecx
f01015f7:	84 c9                	test   %cl,%cl
f01015f9:	74 04                	je     f01015ff <strncmp+0x26>
f01015fb:	3a 0a                	cmp    (%edx),%cl
f01015fd:	74 eb                	je     f01015ea <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01015ff:	0f b6 00             	movzbl (%eax),%eax
f0101602:	0f b6 12             	movzbl (%edx),%edx
f0101605:	29 d0                	sub    %edx,%eax
f0101607:	eb 05                	jmp    f010160e <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101609:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f010160e:	5b                   	pop    %ebx
f010160f:	5d                   	pop    %ebp
f0101610:	c3                   	ret    

f0101611 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101611:	55                   	push   %ebp
f0101612:	89 e5                	mov    %esp,%ebp
f0101614:	8b 45 08             	mov    0x8(%ebp),%eax
f0101617:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010161b:	eb 07                	jmp    f0101624 <strchr+0x13>
		if (*s == c)
f010161d:	38 ca                	cmp    %cl,%dl
f010161f:	74 0f                	je     f0101630 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0101621:	83 c0 01             	add    $0x1,%eax
f0101624:	0f b6 10             	movzbl (%eax),%edx
f0101627:	84 d2                	test   %dl,%dl
f0101629:	75 f2                	jne    f010161d <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f010162b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101630:	5d                   	pop    %ebp
f0101631:	c3                   	ret    

f0101632 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101632:	55                   	push   %ebp
f0101633:	89 e5                	mov    %esp,%ebp
f0101635:	8b 45 08             	mov    0x8(%ebp),%eax
f0101638:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010163c:	eb 03                	jmp    f0101641 <strfind+0xf>
f010163e:	83 c0 01             	add    $0x1,%eax
f0101641:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0101644:	84 d2                	test   %dl,%dl
f0101646:	74 04                	je     f010164c <strfind+0x1a>
f0101648:	38 ca                	cmp    %cl,%dl
f010164a:	75 f2                	jne    f010163e <strfind+0xc>
			break;
	return (char *) s;
}
f010164c:	5d                   	pop    %ebp
f010164d:	c3                   	ret    

f010164e <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f010164e:	55                   	push   %ebp
f010164f:	89 e5                	mov    %esp,%ebp
f0101651:	57                   	push   %edi
f0101652:	56                   	push   %esi
f0101653:	53                   	push   %ebx
f0101654:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101657:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010165a:	85 c9                	test   %ecx,%ecx
f010165c:	74 36                	je     f0101694 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010165e:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101664:	75 28                	jne    f010168e <memset+0x40>
f0101666:	f6 c1 03             	test   $0x3,%cl
f0101669:	75 23                	jne    f010168e <memset+0x40>
		c &= 0xFF;
f010166b:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010166f:	89 d3                	mov    %edx,%ebx
f0101671:	c1 e3 08             	shl    $0x8,%ebx
f0101674:	89 d6                	mov    %edx,%esi
f0101676:	c1 e6 18             	shl    $0x18,%esi
f0101679:	89 d0                	mov    %edx,%eax
f010167b:	c1 e0 10             	shl    $0x10,%eax
f010167e:	09 f0                	or     %esi,%eax
f0101680:	09 c2                	or     %eax,%edx
f0101682:	89 d0                	mov    %edx,%eax
f0101684:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0101686:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0101689:	fc                   	cld    
f010168a:	f3 ab                	rep stos %eax,%es:(%edi)
f010168c:	eb 06                	jmp    f0101694 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010168e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101691:	fc                   	cld    
f0101692:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0101694:	89 f8                	mov    %edi,%eax
f0101696:	5b                   	pop    %ebx
f0101697:	5e                   	pop    %esi
f0101698:	5f                   	pop    %edi
f0101699:	5d                   	pop    %ebp
f010169a:	c3                   	ret    

f010169b <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010169b:	55                   	push   %ebp
f010169c:	89 e5                	mov    %esp,%ebp
f010169e:	57                   	push   %edi
f010169f:	56                   	push   %esi
f01016a0:	8b 45 08             	mov    0x8(%ebp),%eax
f01016a3:	8b 75 0c             	mov    0xc(%ebp),%esi
f01016a6:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01016a9:	39 c6                	cmp    %eax,%esi
f01016ab:	73 35                	jae    f01016e2 <memmove+0x47>
f01016ad:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01016b0:	39 d0                	cmp    %edx,%eax
f01016b2:	73 2e                	jae    f01016e2 <memmove+0x47>
		s += n;
		d += n;
f01016b4:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f01016b7:	89 d6                	mov    %edx,%esi
f01016b9:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01016bb:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01016c1:	75 13                	jne    f01016d6 <memmove+0x3b>
f01016c3:	f6 c1 03             	test   $0x3,%cl
f01016c6:	75 0e                	jne    f01016d6 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01016c8:	83 ef 04             	sub    $0x4,%edi
f01016cb:	8d 72 fc             	lea    -0x4(%edx),%esi
f01016ce:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f01016d1:	fd                   	std    
f01016d2:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01016d4:	eb 09                	jmp    f01016df <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01016d6:	83 ef 01             	sub    $0x1,%edi
f01016d9:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01016dc:	fd                   	std    
f01016dd:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01016df:	fc                   	cld    
f01016e0:	eb 1d                	jmp    f01016ff <memmove+0x64>
f01016e2:	89 f2                	mov    %esi,%edx
f01016e4:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01016e6:	f6 c2 03             	test   $0x3,%dl
f01016e9:	75 0f                	jne    f01016fa <memmove+0x5f>
f01016eb:	f6 c1 03             	test   $0x3,%cl
f01016ee:	75 0a                	jne    f01016fa <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01016f0:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f01016f3:	89 c7                	mov    %eax,%edi
f01016f5:	fc                   	cld    
f01016f6:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01016f8:	eb 05                	jmp    f01016ff <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01016fa:	89 c7                	mov    %eax,%edi
f01016fc:	fc                   	cld    
f01016fd:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01016ff:	5e                   	pop    %esi
f0101700:	5f                   	pop    %edi
f0101701:	5d                   	pop    %ebp
f0101702:	c3                   	ret    

f0101703 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0101703:	55                   	push   %ebp
f0101704:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0101706:	ff 75 10             	pushl  0x10(%ebp)
f0101709:	ff 75 0c             	pushl  0xc(%ebp)
f010170c:	ff 75 08             	pushl  0x8(%ebp)
f010170f:	e8 87 ff ff ff       	call   f010169b <memmove>
}
f0101714:	c9                   	leave  
f0101715:	c3                   	ret    

f0101716 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0101716:	55                   	push   %ebp
f0101717:	89 e5                	mov    %esp,%ebp
f0101719:	56                   	push   %esi
f010171a:	53                   	push   %ebx
f010171b:	8b 45 08             	mov    0x8(%ebp),%eax
f010171e:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101721:	89 c6                	mov    %eax,%esi
f0101723:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101726:	eb 1a                	jmp    f0101742 <memcmp+0x2c>
		if (*s1 != *s2)
f0101728:	0f b6 08             	movzbl (%eax),%ecx
f010172b:	0f b6 1a             	movzbl (%edx),%ebx
f010172e:	38 d9                	cmp    %bl,%cl
f0101730:	74 0a                	je     f010173c <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0101732:	0f b6 c1             	movzbl %cl,%eax
f0101735:	0f b6 db             	movzbl %bl,%ebx
f0101738:	29 d8                	sub    %ebx,%eax
f010173a:	eb 0f                	jmp    f010174b <memcmp+0x35>
		s1++, s2++;
f010173c:	83 c0 01             	add    $0x1,%eax
f010173f:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101742:	39 f0                	cmp    %esi,%eax
f0101744:	75 e2                	jne    f0101728 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0101746:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010174b:	5b                   	pop    %ebx
f010174c:	5e                   	pop    %esi
f010174d:	5d                   	pop    %ebp
f010174e:	c3                   	ret    

f010174f <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010174f:	55                   	push   %ebp
f0101750:	89 e5                	mov    %esp,%ebp
f0101752:	8b 45 08             	mov    0x8(%ebp),%eax
f0101755:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0101758:	89 c2                	mov    %eax,%edx
f010175a:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f010175d:	eb 07                	jmp    f0101766 <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f010175f:	38 08                	cmp    %cl,(%eax)
f0101761:	74 07                	je     f010176a <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0101763:	83 c0 01             	add    $0x1,%eax
f0101766:	39 d0                	cmp    %edx,%eax
f0101768:	72 f5                	jb     f010175f <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f010176a:	5d                   	pop    %ebp
f010176b:	c3                   	ret    

f010176c <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f010176c:	55                   	push   %ebp
f010176d:	89 e5                	mov    %esp,%ebp
f010176f:	57                   	push   %edi
f0101770:	56                   	push   %esi
f0101771:	53                   	push   %ebx
f0101772:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101775:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101778:	eb 03                	jmp    f010177d <strtol+0x11>
		s++;
f010177a:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010177d:	0f b6 01             	movzbl (%ecx),%eax
f0101780:	3c 09                	cmp    $0x9,%al
f0101782:	74 f6                	je     f010177a <strtol+0xe>
f0101784:	3c 20                	cmp    $0x20,%al
f0101786:	74 f2                	je     f010177a <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0101788:	3c 2b                	cmp    $0x2b,%al
f010178a:	75 0a                	jne    f0101796 <strtol+0x2a>
		s++;
f010178c:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f010178f:	bf 00 00 00 00       	mov    $0x0,%edi
f0101794:	eb 10                	jmp    f01017a6 <strtol+0x3a>
f0101796:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f010179b:	3c 2d                	cmp    $0x2d,%al
f010179d:	75 07                	jne    f01017a6 <strtol+0x3a>
		s++, neg = 1;
f010179f:	8d 49 01             	lea    0x1(%ecx),%ecx
f01017a2:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01017a6:	85 db                	test   %ebx,%ebx
f01017a8:	0f 94 c0             	sete   %al
f01017ab:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01017b1:	75 19                	jne    f01017cc <strtol+0x60>
f01017b3:	80 39 30             	cmpb   $0x30,(%ecx)
f01017b6:	75 14                	jne    f01017cc <strtol+0x60>
f01017b8:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01017bc:	0f 85 82 00 00 00    	jne    f0101844 <strtol+0xd8>
		s += 2, base = 16;
f01017c2:	83 c1 02             	add    $0x2,%ecx
f01017c5:	bb 10 00 00 00       	mov    $0x10,%ebx
f01017ca:	eb 16                	jmp    f01017e2 <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f01017cc:	84 c0                	test   %al,%al
f01017ce:	74 12                	je     f01017e2 <strtol+0x76>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01017d0:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01017d5:	80 39 30             	cmpb   $0x30,(%ecx)
f01017d8:	75 08                	jne    f01017e2 <strtol+0x76>
		s++, base = 8;
f01017da:	83 c1 01             	add    $0x1,%ecx
f01017dd:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f01017e2:	b8 00 00 00 00       	mov    $0x0,%eax
f01017e7:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01017ea:	0f b6 11             	movzbl (%ecx),%edx
f01017ed:	8d 72 d0             	lea    -0x30(%edx),%esi
f01017f0:	89 f3                	mov    %esi,%ebx
f01017f2:	80 fb 09             	cmp    $0x9,%bl
f01017f5:	77 08                	ja     f01017ff <strtol+0x93>
			dig = *s - '0';
f01017f7:	0f be d2             	movsbl %dl,%edx
f01017fa:	83 ea 30             	sub    $0x30,%edx
f01017fd:	eb 22                	jmp    f0101821 <strtol+0xb5>
		else if (*s >= 'a' && *s <= 'z')
f01017ff:	8d 72 9f             	lea    -0x61(%edx),%esi
f0101802:	89 f3                	mov    %esi,%ebx
f0101804:	80 fb 19             	cmp    $0x19,%bl
f0101807:	77 08                	ja     f0101811 <strtol+0xa5>
			dig = *s - 'a' + 10;
f0101809:	0f be d2             	movsbl %dl,%edx
f010180c:	83 ea 57             	sub    $0x57,%edx
f010180f:	eb 10                	jmp    f0101821 <strtol+0xb5>
		else if (*s >= 'A' && *s <= 'Z')
f0101811:	8d 72 bf             	lea    -0x41(%edx),%esi
f0101814:	89 f3                	mov    %esi,%ebx
f0101816:	80 fb 19             	cmp    $0x19,%bl
f0101819:	77 16                	ja     f0101831 <strtol+0xc5>
			dig = *s - 'A' + 10;
f010181b:	0f be d2             	movsbl %dl,%edx
f010181e:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0101821:	3b 55 10             	cmp    0x10(%ebp),%edx
f0101824:	7d 0f                	jge    f0101835 <strtol+0xc9>
			break;
		s++, val = (val * base) + dig;
f0101826:	83 c1 01             	add    $0x1,%ecx
f0101829:	0f af 45 10          	imul   0x10(%ebp),%eax
f010182d:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f010182f:	eb b9                	jmp    f01017ea <strtol+0x7e>
f0101831:	89 c2                	mov    %eax,%edx
f0101833:	eb 02                	jmp    f0101837 <strtol+0xcb>
f0101835:	89 c2                	mov    %eax,%edx

	if (endptr)
f0101837:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010183b:	74 0d                	je     f010184a <strtol+0xde>
		*endptr = (char *) s;
f010183d:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101840:	89 0e                	mov    %ecx,(%esi)
f0101842:	eb 06                	jmp    f010184a <strtol+0xde>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101844:	84 c0                	test   %al,%al
f0101846:	75 92                	jne    f01017da <strtol+0x6e>
f0101848:	eb 98                	jmp    f01017e2 <strtol+0x76>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f010184a:	f7 da                	neg    %edx
f010184c:	85 ff                	test   %edi,%edi
f010184e:	0f 45 c2             	cmovne %edx,%eax
}
f0101851:	5b                   	pop    %ebx
f0101852:	5e                   	pop    %esi
f0101853:	5f                   	pop    %edi
f0101854:	5d                   	pop    %ebp
f0101855:	c3                   	ret    

f0101856 <subtract_List_Operation>:
#include <inc/calculator.h>



void subtract_List_Operation(operantion op[])
{
f0101856:	55                   	push   %ebp
f0101857:	89 e5                	mov    %esp,%ebp
f0101859:	8b 55 08             	mov    0x8(%ebp),%edx
f010185c:	89 d0                	mov    %edx,%eax
f010185e:	83 c2 30             	add    $0x30,%edx
	int i;
	for (i = 0; i < 6; i++)
	{
		op[i].position = op[i].position - 1;
f0101861:	83 28 01             	subl   $0x1,(%eax)
f0101864:	83 c0 08             	add    $0x8,%eax


void subtract_List_Operation(operantion op[])
{
	int i;
	for (i = 0; i < 6; i++)
f0101867:	39 d0                	cmp    %edx,%eax
f0101869:	75 f6                	jne    f0101861 <subtract_List_Operation+0xb>
	{
		op[i].position = op[i].position - 1;
	}
}
f010186b:	5d                   	pop    %ebp
f010186c:	c3                   	ret    

f010186d <Isoperation>:

int Isoperation(char r)
{
f010186d:	55                   	push   %ebp
f010186e:	89 e5                	mov    %esp,%ebp
f0101870:	53                   	push   %ebx
f0101871:	83 ec 10             	sub    $0x10,%esp
f0101874:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("error inside is operation");
f0101877:	68 54 2b 10 f0       	push   $0xf0102b54
f010187c:	e8 c2 f1 ff ff       	call   f0100a43 <cprintf>
	if (r == '+' || r == '-' || r == '*' || r == '/' || r == '%')
f0101881:	89 d8                	mov    %ebx,%eax
f0101883:	83 e0 f7             	and    $0xfffffff7,%eax
f0101886:	83 c4 10             	add    $0x10,%esp
f0101889:	3c 25                	cmp    $0x25,%al
f010188b:	0f 94 c2             	sete   %dl
f010188e:	80 fb 2f             	cmp    $0x2f,%bl
f0101891:	0f 94 c0             	sete   %al
f0101894:	08 c2                	or     %al,%dl
f0101896:	75 08                	jne    f01018a0 <Isoperation+0x33>
f0101898:	83 eb 2a             	sub    $0x2a,%ebx
f010189b:	80 fb 01             	cmp    $0x1,%bl
f010189e:	77 17                	ja     f01018b7 <Isoperation+0x4a>
	{
				cprintf(" error inside isoperation : Return 1");
f01018a0:	83 ec 0c             	sub    $0xc,%esp
f01018a3:	68 44 2c 10 f0       	push   $0xf0102c44
f01018a8:	e8 96 f1 ff ff       	call   f0100a43 <cprintf>

		return 1;
f01018ad:	83 c4 10             	add    $0x10,%esp
f01018b0:	b8 01 00 00 00       	mov    $0x1,%eax
f01018b5:	eb 15                	jmp    f01018cc <Isoperation+0x5f>
	}
	else
	{
				cprintf(" error inside isoperation : Return 0");
f01018b7:	83 ec 0c             	sub    $0xc,%esp
f01018ba:	68 6c 2c 10 f0       	push   $0xf0102c6c
f01018bf:	e8 7f f1 ff ff       	call   f0100a43 <cprintf>

		return 0;
f01018c4:	83 c4 10             	add    $0x10,%esp
f01018c7:	b8 00 00 00 00       	mov    $0x0,%eax
	}
					cprintf(" error inside isoperation : Return 0");

	return 0;
}
f01018cc:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01018cf:	c9                   	leave  
f01018d0:	c3                   	ret    

f01018d1 <Isnumber>:


int Isnumber(char r)
{
f01018d1:	55                   	push   %ebp
f01018d2:	89 e5                	mov    %esp,%ebp
f01018d4:	53                   	push   %ebx
f01018d5:	83 ec 0c             	sub    $0xc,%esp
f01018d8:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("%c",r);
f01018db:	0f be c3             	movsbl %bl,%eax
f01018de:	50                   	push   %eax
f01018df:	68 a9 2b 10 f0       	push   $0xf0102ba9
f01018e4:	e8 5a f1 ff ff       	call   f0100a43 <cprintf>
	if (r >= '0' && r <= '9')
f01018e9:	83 eb 30             	sub    $0x30,%ebx
f01018ec:	83 c4 10             	add    $0x10,%esp
f01018ef:	80 fb 09             	cmp    $0x9,%bl
f01018f2:	77 17                	ja     f010190b <Isnumber+0x3a>
	{
		cprintf(" error inside isnumber : Return 1");
f01018f4:	83 ec 0c             	sub    $0xc,%esp
f01018f7:	68 94 2c 10 f0       	push   $0xf0102c94
f01018fc:	e8 42 f1 ff ff       	call   f0100a43 <cprintf>

		return 1;
f0101901:	83 c4 10             	add    $0x10,%esp
f0101904:	b8 01 00 00 00       	mov    $0x1,%eax
f0101909:	eb 15                	jmp    f0101920 <Isnumber+0x4f>
	}
	else
	{
	cprintf(" error inside isnumber : Return 0");
f010190b:	83 ec 0c             	sub    $0xc,%esp
f010190e:	68 b8 2c 10 f0       	push   $0xf0102cb8
f0101913:	e8 2b f1 ff ff       	call   f0100a43 <cprintf>

		return 0;
f0101918:	83 c4 10             	add    $0x10,%esp
f010191b:	b8 00 00 00 00       	mov    $0x0,%eax
	}
	return 0;

		cprintf(" error inside isnumber");
}
f0101920:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101923:	c9                   	leave  
f0101924:	c3                   	ret    

f0101925 <Isdot>:

int Isdot(char r)
{
f0101925:	55                   	push   %ebp
f0101926:	89 e5                	mov    %esp,%ebp
f0101928:	53                   	push   %ebx
f0101929:	83 ec 10             	sub    $0x10,%esp
f010192c:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("error inside isdot");
f010192f:	68 6e 2b 10 f0       	push   $0xf0102b6e
f0101934:	e8 0a f1 ff ff       	call   f0100a43 <cprintf>
	if (r == '.')
f0101939:	83 c4 10             	add    $0x10,%esp
f010193c:	80 fb 2e             	cmp    $0x2e,%bl
f010193f:	75 17                	jne    f0101958 <Isdot+0x33>
	{
				cprintf(" error inside Isdot : Return 1");
f0101941:	83 ec 0c             	sub    $0xc,%esp
f0101944:	68 dc 2c 10 f0       	push   $0xf0102cdc
f0101949:	e8 f5 f0 ff ff       	call   f0100a43 <cprintf>

		return 1;
f010194e:	83 c4 10             	add    $0x10,%esp
f0101951:	b8 01 00 00 00       	mov    $0x1,%eax
f0101956:	eb 15                	jmp    f010196d <Isdot+0x48>
	}
	else
	{
			cprintf(" error inside Isdot : Return 0");
f0101958:	83 ec 0c             	sub    $0xc,%esp
f010195b:	68 fc 2c 10 f0       	push   $0xf0102cfc
f0101960:	e8 de f0 ff ff       	call   f0100a43 <cprintf>

		return 0;
f0101965:	83 c4 10             	add    $0x10,%esp
f0101968:	b8 00 00 00 00       	mov    $0x0,%eax
	}
				cprintf(" error inside Isdot : Return 0");

	return 0;

}
f010196d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101970:	c9                   	leave  
f0101971:	c3                   	ret    

f0101972 <removeItem>:

void removeItem(float str[], int location)
{
f0101972:	55                   	push   %ebp
f0101973:	89 e5                	mov    %esp,%ebp
f0101975:	8b 55 08             	mov    0x8(%ebp),%edx
f0101978:	8b 45 0c             	mov    0xc(%ebp),%eax
	int i;

	for (i = location; i < 6; i++)
f010197b:	eb 0a                	jmp    f0101987 <removeItem+0x15>
	{
		str[i] = str[i + 1];
f010197d:	d9 44 82 04          	flds   0x4(%edx,%eax,4)
f0101981:	d9 1c 82             	fstps  (%edx,%eax,4)

void removeItem(float str[], int location)
{
	int i;

	for (i = location; i < 6; i++)
f0101984:	83 c0 01             	add    $0x1,%eax
f0101987:	83 f8 05             	cmp    $0x5,%eax
f010198a:	7e f1                	jle    f010197d <removeItem+0xb>
	{
		str[i] = str[i + 1];
	}

	str[6] = 0;
f010198c:	c7 42 18 00 00 00 00 	movl   $0x0,0x18(%edx)

}
f0101993:	5d                   	pop    %ebp
f0101994:	c3                   	ret    

f0101995 <clearnumber>:

void clearnumber(char * number)
{
f0101995:	55                   	push   %ebp
f0101996:	89 e5                	mov    %esp,%ebp
f0101998:	56                   	push   %esi
f0101999:	53                   	push   %ebx
f010199a:	8b 75 08             	mov    0x8(%ebp),%esi

	int i = 0;
	for (i = 0; i < strlen(number); i++)
f010199d:	bb 00 00 00 00       	mov    $0x0,%ebx
f01019a2:	eb 07                	jmp    f01019ab <clearnumber+0x16>
	{
		number[i] = '0';
f01019a4:	c6 04 1e 30          	movb   $0x30,(%esi,%ebx,1)

void clearnumber(char * number)
{

	int i = 0;
	for (i = 0; i < strlen(number); i++)
f01019a8:	83 c3 01             	add    $0x1,%ebx
f01019ab:	83 ec 0c             	sub    $0xc,%esp
f01019ae:	56                   	push   %esi
f01019af:	e8 1c fb ff ff       	call   f01014d0 <strlen>
f01019b4:	83 c4 10             	add    $0x10,%esp
f01019b7:	39 c3                	cmp    %eax,%ebx
f01019b9:	7c e9                	jl     f01019a4 <clearnumber+0xf>
	{
		number[i] = '0';
	}
	number[strlen(number)] = '\0';
f01019bb:	83 ec 0c             	sub    $0xc,%esp
f01019be:	56                   	push   %esi
f01019bf:	e8 0c fb ff ff       	call   f01014d0 <strlen>
f01019c4:	c6 04 06 00          	movb   $0x0,(%esi,%eax,1)
f01019c8:	83 c4 10             	add    $0x10,%esp
}
f01019cb:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01019ce:	5b                   	pop    %ebx
f01019cf:	5e                   	pop    %esi
f01019d0:	5d                   	pop    %ebp
f01019d1:	c3                   	ret    

f01019d2 <Getnumber>:


Float Getnumber(char* str, int *i)
{
f01019d2:	55                   	push   %ebp
f01019d3:	89 e5                	mov    %esp,%ebp
f01019d5:	57                   	push   %edi
f01019d6:	56                   	push   %esi
f01019d7:	53                   	push   %ebx
f01019d8:	81 ec 98 00 00 00    	sub    $0x98,%esp
f01019de:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01019e1:	8b 75 10             	mov    0x10(%ebp),%esi
	Float Value;
	int dot = 1;
	int y = 1;
	char number[100];
	number[strlen(str)] = '\0';
f01019e4:	53                   	push   %ebx
f01019e5:	e8 e6 fa ff ff       	call   f01014d0 <strlen>
f01019ea:	c6 44 05 84 00       	movb   $0x0,-0x7c(%ebp,%eax,1)
	clearnumber(number);
f01019ef:	8d 45 84             	lea    -0x7c(%ebp),%eax
f01019f2:	89 04 24             	mov    %eax,(%esp)
f01019f5:	e8 9b ff ff ff       	call   f0101995 <clearnumber>
	number[0] = str[*i];
f01019fa:	8b 06                	mov    (%esi),%eax
f01019fc:	0f b6 04 03          	movzbl (%ebx,%eax,1),%eax
f0101a00:	88 45 84             	mov    %al,-0x7c(%ebp)
	*i++;
	cprintf("%d",strlen(str));
f0101a03:	89 1c 24             	mov    %ebx,(%esp)
f0101a06:	e8 c5 fa ff ff       	call   f01014d0 <strlen>
f0101a0b:	83 c4 08             	add    $0x8,%esp
f0101a0e:	50                   	push   %eax
f0101a0f:	68 33 29 10 f0       	push   $0xf0102933
f0101a14:	e8 2a f0 ff ff       	call   f0100a43 <cprintf>
	while (*i < strlen(str))
f0101a19:	8b 7e 04             	mov    0x4(%esi),%edi
f0101a1c:	89 1c 24             	mov    %ebx,(%esp)
f0101a1f:	e8 ac fa ff ff       	call   f01014d0 <strlen>
f0101a24:	83 c4 10             	add    $0x10,%esp
f0101a27:	39 c7                	cmp    %eax,%edi
f0101a29:	0f 8d ec 00 00 00    	jge    f0101b1b <Getnumber+0x149>
	{
		cprintf("inside Getnumber loop");
f0101a2f:	83 ec 0c             	sub    $0xc,%esp
f0101a32:	68 81 2b 10 f0       	push   $0xf0102b81
f0101a37:	e8 07 f0 ff ff       	call   f0100a43 <cprintf>
		cprintf("Isnumber Argument %c",str[*i]);
f0101a3c:	83 c4 08             	add    $0x8,%esp
f0101a3f:	8b 46 04             	mov    0x4(%esi),%eax
f0101a42:	0f be 04 03          	movsbl (%ebx,%eax,1),%eax
f0101a46:	50                   	push   %eax
f0101a47:	68 97 2b 10 f0       	push   $0xf0102b97
f0101a4c:	e8 f2 ef ff ff       	call   f0100a43 <cprintf>
		if (Isnumber(str[*i]))
f0101a51:	8b 46 04             	mov    0x4(%esi),%eax
f0101a54:	0f be 04 03          	movsbl (%ebx,%eax,1),%eax
f0101a58:	89 04 24             	mov    %eax,(%esp)
f0101a5b:	e8 71 fe ff ff       	call   f01018d1 <Isnumber>
f0101a60:	83 c4 10             	add    $0x10,%esp
f0101a63:	85 c0                	test   %eax,%eax
f0101a65:	75 0a                	jne    f0101a71 <Getnumber+0x9f>
	int y = 1;
	char number[100];
	number[strlen(str)] = '\0';
	clearnumber(number);
	number[0] = str[*i];
	*i++;
f0101a67:	83 c6 04             	add    $0x4,%esi

Float Getnumber(char* str, int *i)
{
	Float Value;
	int dot = 1;
	int y = 1;
f0101a6a:	bf 01 00 00 00       	mov    $0x1,%edi
f0101a6f:	eb 22                	jmp    f0101a93 <Getnumber+0xc1>
	{
		cprintf("inside Getnumber loop");
		cprintf("Isnumber Argument %c",str[*i]);
		if (Isnumber(str[*i]))
		{
			cprintf("first number");
f0101a71:	83 ec 0c             	sub    $0xc,%esp
f0101a74:	68 ac 2b 10 f0       	push   $0xf0102bac
f0101a79:	e8 c5 ef ff ff       	call   f0100a43 <cprintf>
			number[y] = str[*i];
f0101a7e:	8b 46 04             	mov    0x4(%esi),%eax
f0101a81:	0f b6 04 03          	movzbl (%ebx,%eax,1),%eax
f0101a85:	88 45 85             	mov    %al,-0x7b(%ebp)
			y++;
			*i++;
f0101a88:	83 c6 08             	add    $0x8,%esi
f0101a8b:	83 c4 10             	add    $0x10,%esp
		cprintf("Isnumber Argument %c",str[*i]);
		if (Isnumber(str[*i]))
		{
			cprintf("first number");
			number[y] = str[*i];
			y++;
f0101a8e:	bf 02 00 00 00       	mov    $0x2,%edi
			*i++;
		}
		cprintf("is a dot error");
f0101a93:	83 ec 0c             	sub    $0xc,%esp
f0101a96:	68 b9 2b 10 f0       	push   $0xf0102bb9
f0101a9b:	e8 a3 ef ff ff       	call   f0100a43 <cprintf>
		if (Isdot((str[*i])) && dot)
f0101aa0:	8b 06                	mov    (%esi),%eax
f0101aa2:	0f be 04 03          	movsbl (%ebx,%eax,1),%eax
f0101aa6:	89 04 24             	mov    %eax,(%esp)
f0101aa9:	e8 77 fe ff ff       	call   f0101925 <Isdot>
f0101aae:	83 c4 10             	add    $0x10,%esp
f0101ab1:	85 c0                	test   %eax,%eax
f0101ab3:	0f 84 ce 00 00 00    	je     f0101b87 <Getnumber+0x1b5>
		{
			cprintf("is a dot");
f0101ab9:	83 ec 0c             	sub    $0xc,%esp
f0101abc:	68 c8 2b 10 f0       	push   $0xf0102bc8
f0101ac1:	e8 7d ef ff ff       	call   f0100a43 <cprintf>

			number[y] = str[*i];
f0101ac6:	8b 06                	mov    (%esi),%eax
f0101ac8:	0f b6 04 03          	movzbl (%ebx,%eax,1),%eax
f0101acc:	88 44 3d 84          	mov    %al,-0x7c(%ebp,%edi,1)
			dot--;
			y++;
			*i++;
		}
		cprintf("isoperation error");
f0101ad0:	c7 04 24 d1 2b 10 f0 	movl   $0xf0102bd1,(%esp)
f0101ad7:	e8 67 ef ff ff       	call   f0100a43 <cprintf>
		if ( Isoperation(str[*i]) )
f0101adc:	8b 46 04             	mov    0x4(%esi),%eax
f0101adf:	0f be 04 03          	movsbl (%ebx,%eax,1),%eax
f0101ae3:	89 04 24             	mov    %eax,(%esp)
f0101ae6:	e8 82 fd ff ff       	call   f010186d <Isoperation>
f0101aeb:	83 c4 10             	add    $0x10,%esp
f0101aee:	85 c0                	test   %eax,%eax
f0101af0:	0f 85 b8 00 00 00    	jne    f0101bae <Getnumber+0x1dc>
		         	number[y] = '.';
			    }
		            break;
			}

			cprintf("get number error inside Getnuber");
f0101af6:	83 ec 0c             	sub    $0xc,%esp
f0101af9:	68 1c 2d 10 f0       	push   $0xf0102d1c
f0101afe:	e8 40 ef ff ff       	call   f0100a43 <cprintf>
			Value.error = 1;
			Value.number = 1;
			return Value;
f0101b03:	8b 45 08             	mov    0x8(%ebp),%eax
f0101b06:	c7 00 00 00 80 3f    	movl   $0x3f800000,(%eax)
f0101b0c:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
f0101b13:	83 c4 10             	add    $0x10,%esp
f0101b16:	e9 a8 00 00 00       	jmp    f0101bc3 <Getnumber+0x1f1>
	}
	cprintf("*i > strlen(str)");
f0101b1b:	83 ec 0c             	sub    $0xc,%esp
f0101b1e:	68 e3 2b 10 f0       	push   $0xf0102be3
f0101b23:	e8 1b ef ff ff       	call   f0100a43 <cprintf>
	Value = char_to_float(number);
f0101b28:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
f0101b2e:	83 c4 08             	add    $0x8,%esp
f0101b31:	8d 55 84             	lea    -0x7c(%ebp),%edx
f0101b34:	52                   	push   %edx
f0101b35:	50                   	push   %eax
f0101b36:	e8 5d 04 00 00       	call   f0101f98 <char_to_float>
f0101b3b:	8b b5 74 ff ff ff    	mov    -0x8c(%ebp),%esi
f0101b41:	8b 9d 70 ff ff ff    	mov    -0x90(%ebp),%ebx
	cprintf("the returned float %f",Value.number);
f0101b47:	83 ec 10             	sub    $0x10,%esp
f0101b4a:	89 9d 6c ff ff ff    	mov    %ebx,-0x94(%ebp)
f0101b50:	d9 85 6c ff ff ff    	flds   -0x94(%ebp)
f0101b56:	dd 1c 24             	fstpl  (%esp)
f0101b59:	68 f4 2b 10 f0       	push   $0xf0102bf4
f0101b5e:	e8 e0 ee ff ff       	call   f0100a43 <cprintf>
	return Value;
f0101b63:	8b 45 08             	mov    0x8(%ebp),%eax
f0101b66:	89 18                	mov    %ebx,(%eax)
f0101b68:	89 70 04             	mov    %esi,0x4(%eax)
f0101b6b:	83 c4 20             	add    $0x20,%esp
f0101b6e:	eb 53                	jmp    f0101bc3 <Getnumber+0x1f1>
			*i++;
		}
		cprintf("isoperation error");
		if ( Isoperation(str[*i]) )
	        {
			    cprintf("is operation");
f0101b70:	83 ec 0c             	sub    $0xc,%esp
f0101b73:	68 61 2b 10 f0       	push   $0xf0102b61
f0101b78:	e8 c6 ee ff ff       	call   f0100a43 <cprintf>

				if (dot)
			    {
		         	number[y] = '.';
f0101b7d:	c6 44 3d 84 2e       	movb   $0x2e,-0x7c(%ebp,%edi,1)
f0101b82:	83 c4 10             	add    $0x10,%esp
f0101b85:	eb 94                	jmp    f0101b1b <Getnumber+0x149>
			number[y] = str[*i];
			dot--;
			y++;
			*i++;
		}
		cprintf("isoperation error");
f0101b87:	83 ec 0c             	sub    $0xc,%esp
f0101b8a:	68 d1 2b 10 f0       	push   $0xf0102bd1
f0101b8f:	e8 af ee ff ff       	call   f0100a43 <cprintf>
		if ( Isoperation(str[*i]) )
f0101b94:	8b 06                	mov    (%esi),%eax
f0101b96:	0f be 04 03          	movsbl (%ebx,%eax,1),%eax
f0101b9a:	89 04 24             	mov    %eax,(%esp)
f0101b9d:	e8 cb fc ff ff       	call   f010186d <Isoperation>
f0101ba2:	83 c4 10             	add    $0x10,%esp
f0101ba5:	85 c0                	test   %eax,%eax
f0101ba7:	75 c7                	jne    f0101b70 <Getnumber+0x19e>
f0101ba9:	e9 48 ff ff ff       	jmp    f0101af6 <Getnumber+0x124>
	        {
			    cprintf("is operation");
f0101bae:	83 ec 0c             	sub    $0xc,%esp
f0101bb1:	68 61 2b 10 f0       	push   $0xf0102b61
f0101bb6:	e8 88 ee ff ff       	call   f0100a43 <cprintf>
f0101bbb:	83 c4 10             	add    $0x10,%esp
f0101bbe:	e9 58 ff ff ff       	jmp    f0101b1b <Getnumber+0x149>
	}
	cprintf("*i > strlen(str)");
	Value = char_to_float(number);
	cprintf("the returned float %f",Value.number);
	return Value;
}
f0101bc3:	8b 45 08             	mov    0x8(%ebp),%eax
f0101bc6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101bc9:	5b                   	pop    %ebx
f0101bca:	5e                   	pop    %esi
f0101bcb:	5f                   	pop    %edi
f0101bcc:	5d                   	pop    %ebp
f0101bcd:	c2 04 00             	ret    $0x4

f0101bd0 <GetOperation>:

Char GetOperation(char* str, int i)
{
f0101bd0:	55                   	push   %ebp
f0101bd1:	89 e5                	mov    %esp,%ebp
f0101bd3:	53                   	push   %ebx
f0101bd4:	8b 45 08             	mov    0x8(%ebp),%eax
	Char operat;
	if (str[i] == '-' || str[i] == '+' || str[i] == '*' || str[i] == '/' || str[i] == '%')
f0101bd7:	8b 55 10             	mov    0x10(%ebp),%edx
f0101bda:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101bdd:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0101be1:	89 d1                	mov    %edx,%ecx
f0101be3:	83 e1 f7             	and    $0xfffffff7,%ecx
f0101be6:	80 f9 25             	cmp    $0x25,%cl
f0101be9:	0f 94 c3             	sete   %bl
f0101bec:	80 fa 2f             	cmp    $0x2f,%dl
f0101bef:	0f 94 c1             	sete   %cl
f0101bf2:	08 cb                	or     %cl,%bl
f0101bf4:	75 08                	jne    f0101bfe <GetOperation+0x2e>
f0101bf6:	8d 4a d6             	lea    -0x2a(%edx),%ecx
f0101bf9:	80 f9 01             	cmp    $0x1,%cl
f0101bfc:	77 0b                	ja     f0101c09 <GetOperation+0x39>
	{
		operat.error = 0;
		operat.value = str[i];
		return operat;
f0101bfe:	88 10                	mov    %dl,(%eax)
f0101c00:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
f0101c07:	eb 0a                	jmp    f0101c13 <GetOperation+0x43>
	}
	else
	{
		operat.error = 1;
		operat.value = '0';
		return operat;
f0101c09:	c6 00 30             	movb   $0x30,(%eax)
f0101c0c:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
	}

}
f0101c13:	5b                   	pop    %ebx
f0101c14:	5d                   	pop    %ebp
f0101c15:	c2 04 00             	ret    $0x4

f0101c18 <calc>:

void calc(float numbers[], operantion op[])
{
f0101c18:	55                   	push   %ebp
f0101c19:	89 e5                	mov    %esp,%ebp
f0101c1b:	57                   	push   %edi
f0101c1c:	56                   	push   %esi
f0101c1d:	53                   	push   %ebx
f0101c1e:	83 ec 1c             	sub    $0x1c,%esp
f0101c21:	8b 75 08             	mov    0x8(%ebp),%esi
f0101c24:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0101c27:	89 fb                	mov    %edi,%ebx
f0101c29:	8d 47 30             	lea    0x30(%edi),%eax
f0101c2c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101c2f:	89 da                	mov    %ebx,%edx
	int i;

	for (i = 0; i < 6; i++)
	{
		if (op[i].operant == '*')
f0101c31:	0f b6 43 04          	movzbl 0x4(%ebx),%eax
f0101c35:	3c 2a                	cmp    $0x2a,%al
f0101c37:	75 19                	jne    f0101c52 <calc+0x3a>
		{
			numbers[op[i].position - 1] = numbers[op[i].position - 1] * numbers[op[i].position];
f0101c39:	8b 03                	mov    (%ebx),%eax
f0101c3b:	8d 0c 85 fc ff ff ff 	lea    -0x4(,%eax,4),%ecx
f0101c42:	8d 04 0e             	lea    (%esi,%ecx,1),%eax
f0101c45:	d9 00                	flds   (%eax)
f0101c47:	d8 4c 0e 04          	fmuls  0x4(%esi,%ecx,1)
f0101c4b:	d9 18                	fstps  (%eax)
f0101c4d:	e9 90 00 00 00       	jmp    f0101ce2 <calc+0xca>

		}
		else if (op[i].operant == '/')
f0101c52:	3c 2f                	cmp    $0x2f,%al
f0101c54:	75 42                	jne    f0101c98 <calc+0x80>
		{
			if (numbers[op[i].position == 0])
f0101c56:	8b 0b                	mov    (%ebx),%ecx
f0101c58:	83 f9 01             	cmp    $0x1,%ecx
f0101c5b:	19 c0                	sbb    %eax,%eax
f0101c5d:	83 e0 04             	and    $0x4,%eax
f0101c60:	d9 04 06             	flds   (%esi,%eax,1)
f0101c63:	d9 ee                	fldz   
f0101c65:	d9 c9                	fxch   %st(1)
f0101c67:	df e9                	fucomip %st(1),%st
f0101c69:	dd d8                	fstp   %st(0)
f0101c6b:	7a 02                	jp     f0101c6f <calc+0x57>
f0101c6d:	74 15                	je     f0101c84 <calc+0x6c>
			{
				cprintf("error");
f0101c6f:	83 ec 0c             	sub    $0xc,%esp
f0101c72:	68 45 29 10 f0       	push   $0xf0102945
f0101c77:	e8 c7 ed ff ff       	call   f0100a43 <cprintf>
				return;
f0101c7c:	83 c4 10             	add    $0x10,%esp
f0101c7f:	e9 a0 00 00 00       	jmp    f0101d24 <calc+0x10c>
			}
			numbers[op[i].position - 1] = numbers[op[i].position - 1] / numbers[op[i].position];
f0101c84:	8d 0c 8d fc ff ff ff 	lea    -0x4(,%ecx,4),%ecx
f0101c8b:	8d 04 0e             	lea    (%esi,%ecx,1),%eax
f0101c8e:	d9 00                	flds   (%eax)
f0101c90:	d8 74 0e 04          	fdivs  0x4(%esi,%ecx,1)
f0101c94:	d9 18                	fstps  (%eax)
f0101c96:	eb 4a                	jmp    f0101ce2 <calc+0xca>
		}
		else if (op[i].operant == '%')
f0101c98:	3c 25                	cmp    $0x25,%al
f0101c9a:	74 09                	je     f0101ca5 <calc+0x8d>
		{
			if (numbers[op[i].position == 0])
f0101c9c:	d9 ee                	fldz   
f0101c9e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101ca3:	eb 61                	jmp    f0101d06 <calc+0xee>
f0101ca5:	8b 0b                	mov    (%ebx),%ecx
f0101ca7:	83 f9 01             	cmp    $0x1,%ecx
f0101caa:	19 c0                	sbb    %eax,%eax
f0101cac:	83 e0 04             	and    $0x4,%eax
f0101caf:	d9 04 06             	flds   (%esi,%eax,1)
f0101cb2:	d9 ee                	fldz   
f0101cb4:	d9 c9                	fxch   %st(1)
f0101cb6:	df e9                	fucomip %st(1),%st
f0101cb8:	dd d8                	fstp   %st(0)
f0101cba:	7a 02                	jp     f0101cbe <calc+0xa6>
f0101cbc:	74 12                	je     f0101cd0 <calc+0xb8>
			{
				cprintf("error");
f0101cbe:	83 ec 0c             	sub    $0xc,%esp
f0101cc1:	68 45 29 10 f0       	push   $0xf0102945
f0101cc6:	e8 78 ed ff ff       	call   f0100a43 <cprintf>
				return;
f0101ccb:	83 c4 10             	add    $0x10,%esp
f0101cce:	eb 54                	jmp    f0101d24 <calc+0x10c>
			}
		int y = (int)(numbers[op[i].position - 1] / numbers[op[i].position]);
		numbers[op[i].position - 1] = numbers[op[i].position - 1] / numbers[op[i].position];
f0101cd0:	8d 0c 8d fc ff ff ff 	lea    -0x4(,%ecx,4),%ecx
f0101cd7:	8d 04 0e             	lea    (%esi,%ecx,1),%eax
f0101cda:	d9 00                	flds   (%eax)
f0101cdc:	d8 74 0e 04          	fdivs  0x4(%esi,%ecx,1)
f0101ce0:	d9 18                	fstps  (%eax)
		}
		else{ break; }
		removeItem(numbers, op[i].position);
f0101ce2:	83 ec 08             	sub    $0x8,%esp
f0101ce5:	ff 32                	pushl  (%edx)
f0101ce7:	56                   	push   %esi
f0101ce8:	e8 85 fc ff ff       	call   f0101972 <removeItem>
		subtract_List_Operation(op);
f0101ced:	89 3c 24             	mov    %edi,(%esp)
f0101cf0:	e8 61 fb ff ff       	call   f0101856 <subtract_List_Operation>
f0101cf5:	83 c3 08             	add    $0x8,%ebx

void calc(float numbers[], operantion op[])
{
	int i;

	for (i = 0; i < 6; i++)
f0101cf8:	83 c4 10             	add    $0x10,%esp
f0101cfb:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f0101cfe:	0f 85 2b ff ff ff    	jne    f0101c2f <calc+0x17>
f0101d04:	eb 96                	jmp    f0101c9c <calc+0x84>
	}
	float result;
	result = 0;
	for (i = 0; i < sizeof(numbers); i++)
	{
		result = result + numbers[i];
f0101d06:	d8 04 86             	fadds  (%esi,%eax,4)
		removeItem(numbers, op[i].position);
		subtract_List_Operation(op);
	}
	float result;
	result = 0;
	for (i = 0; i < sizeof(numbers); i++)
f0101d09:	83 c0 01             	add    $0x1,%eax
f0101d0c:	83 f8 04             	cmp    $0x4,%eax
f0101d0f:	75 f5                	jne    f0101d06 <calc+0xee>
	{
		result = result + numbers[i];
	}
	cprintf("%f", result);
f0101d11:	83 ec 0c             	sub    $0xc,%esp
f0101d14:	dd 1c 24             	fstpl  (%esp)
f0101d17:	68 c9 26 10 f0       	push   $0xf01026c9
f0101d1c:	e8 22 ed ff ff       	call   f0100a43 <cprintf>
f0101d21:	83 c4 10             	add    $0x10,%esp

}
f0101d24:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101d27:	5b                   	pop    %ebx
f0101d28:	5e                   	pop    %esi
f0101d29:	5f                   	pop    %edi
f0101d2a:	5d                   	pop    %ebp
f0101d2b:	c3                   	ret    

f0101d2c <calculator>:

int calculator()
{
f0101d2c:	55                   	push   %ebp
f0101d2d:	89 e5                	mov    %esp,%ebp
f0101d2f:	57                   	push   %edi
f0101d30:	56                   	push   %esi
f0101d31:	53                   	push   %ebx
f0101d32:	81 ec 7c 01 00 00    	sub    $0x17c,%esp

	operantion oper;
	oper.operant = '0';
	oper.position = 0;

	for (i = 0; i < 6; i++)
f0101d38:	b8 00 00 00 00       	mov    $0x0,%eax
	{
		numericop[i].operant ='0';
f0101d3d:	c6 44 c5 a0 30       	movb   $0x30,-0x60(%ebp,%eax,8)
		numericop[i].position = 0 ;
f0101d42:	c7 44 c5 9c 00 00 00 	movl   $0x0,-0x64(%ebp,%eax,8)
f0101d49:	00 

	operantion oper;
	oper.operant = '0';
	oper.position = 0;

	for (i = 0; i < 6; i++)
f0101d4a:	83 c0 01             	add    $0x1,%eax
f0101d4d:	83 f8 05             	cmp    $0x5,%eax
f0101d50:	7e eb                	jle    f0101d3d <calculator+0x11>
f0101d52:	89 45 cc             	mov    %eax,-0x34(%ebp)
	{
		numericop[i].operant ='0';
		numericop[i].position = 0 ;
	}
	cprintf("Expression:");
f0101d55:	83 ec 0c             	sub    $0xc,%esp
f0101d58:	68 0a 2c 10 f0       	push   $0xf0102c0a
f0101d5d:	e8 e1 ec ff ff       	call   f0100a43 <cprintf>
	char *op  = readline("");
f0101d62:	c7 04 24 0f 24 10 f0 	movl   $0xf010240f,(%esp)
f0101d69:	e8 89 f6 ff ff       	call   f01013f7 <readline>
f0101d6e:	89 c6                	mov    %eax,%esi
	char number[256];
	number[strlen(op)] = '\0';
f0101d70:	89 04 24             	mov    %eax,(%esp)
f0101d73:	e8 58 f7 ff ff       	call   f01014d0 <strlen>
f0101d78:	c6 84 05 9c fe ff ff 	movb   $0x0,-0x164(%ebp,%eax,1)
f0101d7f:	00 
	clearnumber(number);
f0101d80:	8d 85 9c fe ff ff    	lea    -0x164(%ebp),%eax
f0101d86:	89 04 24             	mov    %eax,(%esp)
f0101d89:	e8 07 fc ff ff       	call   f0101995 <clearnumber>
	i = 0;
f0101d8e:	c7 45 cc 00 00 00 00 	movl   $0x0,-0x34(%ebp)
	if (!(op[0] != '-' || Isnumber(op[0])))
f0101d95:	83 c4 10             	add    $0x10,%esp
f0101d98:	80 3e 2d             	cmpb   $0x2d,(%esi)
f0101d9b:	75 2b                	jne    f0101dc8 <calculator+0x9c>
f0101d9d:	83 ec 0c             	sub    $0xc,%esp
f0101da0:	6a 2d                	push   $0x2d
f0101da2:	e8 2a fb ff ff       	call   f01018d1 <Isnumber>
f0101da7:	83 c4 10             	add    $0x10,%esp
f0101daa:	85 c0                	test   %eax,%eax
f0101dac:	75 1a                	jne    f0101dc8 <calculator+0x9c>
	{
		cprintf("error");
f0101dae:	83 ec 0c             	sub    $0xc,%esp
f0101db1:	68 45 29 10 f0       	push   $0xf0102945
f0101db6:	e8 88 ec ff ff       	call   f0100a43 <cprintf>
		return -1;
f0101dbb:	83 c4 10             	add    $0x10,%esp
f0101dbe:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101dc3:	e9 96 01 00 00       	jmp    f0101f5e <calculator+0x232>
	}
	if (!(Isnumber(op[strlen(op) - 1]) || Isdot(op[strlen(op) - 1])))
f0101dc8:	83 ec 0c             	sub    $0xc,%esp
f0101dcb:	56                   	push   %esi
f0101dcc:	e8 ff f6 ff ff       	call   f01014d0 <strlen>
f0101dd1:	0f be 44 06 ff       	movsbl -0x1(%esi,%eax,1),%eax
f0101dd6:	89 04 24             	mov    %eax,(%esp)
f0101dd9:	e8 f3 fa ff ff       	call   f01018d1 <Isnumber>
f0101dde:	83 c4 10             	add    $0x10,%esp
f0101de1:	85 c0                	test   %eax,%eax
f0101de3:	74 1a                	je     f0101dff <calculator+0xd3>

	operantion oper;
	oper.operant = '0';
	oper.position = 0;

	for (i = 0; i < 6; i++)
f0101de5:	c7 85 84 fe ff ff 00 	movl   $0x0,-0x17c(%ebp)
f0101dec:	00 00 00 
f0101def:	bf 01 00 00 00       	mov    $0x1,%edi
	}

	while (i < strlen(op))
	{
		cprintf("inside the main loop, no errors \n");
		Float answer_num = Getnumber(op, &i);
f0101df4:	8d 9d 90 fe ff ff    	lea    -0x170(%ebp),%ebx
f0101dfa:	e9 32 01 00 00       	jmp    f0101f31 <calculator+0x205>
	if (!(op[0] != '-' || Isnumber(op[0])))
	{
		cprintf("error");
		return -1;
	}
	if (!(Isnumber(op[strlen(op) - 1]) || Isdot(op[strlen(op) - 1])))
f0101dff:	83 ec 0c             	sub    $0xc,%esp
f0101e02:	56                   	push   %esi
f0101e03:	e8 c8 f6 ff ff       	call   f01014d0 <strlen>
f0101e08:	0f be 44 06 ff       	movsbl -0x1(%esi,%eax,1),%eax
f0101e0d:	89 04 24             	mov    %eax,(%esp)
f0101e10:	e8 10 fb ff ff       	call   f0101925 <Isdot>
f0101e15:	83 c4 10             	add    $0x10,%esp
f0101e18:	85 c0                	test   %eax,%eax
f0101e1a:	75 c9                	jne    f0101de5 <calculator+0xb9>
	{
		cprintf("error");
f0101e1c:	83 ec 0c             	sub    $0xc,%esp
f0101e1f:	68 45 29 10 f0       	push   $0xf0102945
f0101e24:	e8 1a ec ff ff       	call   f0100a43 <cprintf>
		return -1;
f0101e29:	83 c4 10             	add    $0x10,%esp
f0101e2c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101e31:	e9 28 01 00 00       	jmp    f0101f5e <calculator+0x232>
	}

	while (i < strlen(op))
	{
		cprintf("inside the main loop, no errors \n");
f0101e36:	83 ec 0c             	sub    $0xc,%esp
f0101e39:	68 40 2d 10 f0       	push   $0xf0102d40
f0101e3e:	e8 00 ec ff ff       	call   f0100a43 <cprintf>
		Float answer_num = Getnumber(op, &i);
f0101e43:	83 c4 0c             	add    $0xc,%esp
f0101e46:	8d 45 cc             	lea    -0x34(%ebp),%eax
f0101e49:	50                   	push   %eax
f0101e4a:	56                   	push   %esi
f0101e4b:	53                   	push   %ebx
f0101e4c:	e8 81 fb ff ff       	call   f01019d2 <Getnumber>
f0101e51:	8b 85 94 fe ff ff    	mov    -0x16c(%ebp),%eax
f0101e57:	89 85 8c fe ff ff    	mov    %eax,-0x174(%ebp)
f0101e5d:	d9 85 90 fe ff ff    	flds   -0x170(%ebp)
f0101e63:	d9 9d 88 fe ff ff    	fstps  -0x178(%ebp)
		cprintf("getnumber error solved");
f0101e69:	68 16 2c 10 f0       	push   $0xf0102c16
f0101e6e:	e8 d0 eb ff ff       	call   f0100a43 <cprintf>
		if (answer_num.error)
f0101e73:	83 c4 10             	add    $0x10,%esp
f0101e76:	83 bd 8c fe ff ff 00 	cmpl   $0x0,-0x174(%ebp)
f0101e7d:	74 15                	je     f0101e94 <calculator+0x168>
		{
			cprintf("error");
f0101e7f:	83 ec 0c             	sub    $0xc,%esp
f0101e82:	68 45 29 10 f0       	push   $0xf0102945
f0101e87:	e8 b7 eb ff ff       	call   f0100a43 <cprintf>
			return -1;
f0101e8c:	83 c4 10             	add    $0x10,%esp
f0101e8f:	e9 96 00 00 00       	jmp    f0101f2a <calculator+0x1fe>
		}
		else
		{
			cprintf("in else in calculator");
f0101e94:	83 ec 0c             	sub    $0xc,%esp
f0101e97:	68 2d 2c 10 f0       	push   $0xf0102c2d
f0101e9c:	e8 a2 eb ff ff       	call   f0100a43 <cprintf>
			A[numposition] = answer_num.number;
f0101ea1:	d9 85 88 fe ff ff    	flds   -0x178(%ebp)
f0101ea7:	d9 54 bd cc          	fsts   -0x34(%ebp,%edi,4)
			numposition++;
			cprintf("sucssecfuly got the float number %f",answer_num.number);
f0101eab:	dd 5c 24 04          	fstpl  0x4(%esp)
f0101eaf:	c7 04 24 64 2d 10 f0 	movl   $0xf0102d64,(%esp)
f0101eb6:	e8 88 eb ff ff       	call   f0100a43 <cprintf>
		}
		if (i == strlen(op))
f0101ebb:	89 34 24             	mov    %esi,(%esp)
f0101ebe:	e8 0d f6 ff ff       	call   f01014d0 <strlen>
f0101ec3:	8b 55 cc             	mov    -0x34(%ebp),%edx
f0101ec6:	83 c4 10             	add    $0x10,%esp
f0101ec9:	39 d0                	cmp    %edx,%eax
f0101ecb:	74 79                	je     f0101f46 <calculator+0x21a>
		{
			break;
		}
		Char answer_char = GetOperation(op, i);
f0101ecd:	83 ec 04             	sub    $0x4,%esp
f0101ed0:	52                   	push   %edx
f0101ed1:	56                   	push   %esi
f0101ed2:	53                   	push   %ebx
f0101ed3:	e8 f8 fc ff ff       	call   f0101bd0 <GetOperation>
f0101ed8:	8b 85 90 fe ff ff    	mov    -0x170(%ebp),%eax
		if (answer_char.error)
f0101ede:	83 c4 0c             	add    $0xc,%esp
f0101ee1:	83 bd 94 fe ff ff 00 	cmpl   $0x0,-0x16c(%ebp)
f0101ee8:	74 12                	je     f0101efc <calculator+0x1d0>
		{
			cprintf("error");
f0101eea:	83 ec 0c             	sub    $0xc,%esp
f0101eed:	68 45 29 10 f0       	push   $0xf0102945
f0101ef2:	e8 4c eb ff ff       	call   f0100a43 <cprintf>
			return -1;
f0101ef7:	83 c4 10             	add    $0x10,%esp
f0101efa:	eb 2e                	jmp    f0101f2a <calculator+0x1fe>
		}
		else
		{
			if (answer_char.value == '+')
f0101efc:	3c 2b                	cmp    $0x2b,%al
f0101efe:	75 06                	jne    f0101f06 <calculator+0x1da>
			{
				i++;
f0101f00:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
f0101f04:	eb 1f                	jmp    f0101f25 <calculator+0x1f9>
			}
			else if (!(answer_char.value == '-'))
f0101f06:	3c 2d                	cmp    $0x2d,%al
f0101f08:	74 1b                	je     f0101f25 <calculator+0x1f9>
			{
				numericop[operantnum].operant = answer_char.value;
f0101f0a:	8b 8d 84 fe ff ff    	mov    -0x17c(%ebp),%ecx
f0101f10:	88 44 cd a0          	mov    %al,-0x60(%ebp,%ecx,8)
				numericop[operantnum].position = Operation_Position;
f0101f14:	89 7c cd 9c          	mov    %edi,-0x64(%ebp,%ecx,8)
				operantnum++;
f0101f18:	83 c1 01             	add    $0x1,%ecx
f0101f1b:	89 8d 84 fe ff ff    	mov    %ecx,-0x17c(%ebp)
				i++;
f0101f21:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)

			}
			Operation_Position++;
f0101f25:	83 c7 01             	add    $0x1,%edi
f0101f28:	eb 07                	jmp    f0101f31 <calculator+0x205>
		Float answer_num = Getnumber(op, &i);
		cprintf("getnumber error solved");
		if (answer_num.error)
		{
			cprintf("error");
			return -1;
f0101f2a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101f2f:	eb 2d                	jmp    f0101f5e <calculator+0x232>
	{
		cprintf("error");
		return -1;
	}

	while (i < strlen(op))
f0101f31:	83 ec 0c             	sub    $0xc,%esp
f0101f34:	56                   	push   %esi
f0101f35:	e8 96 f5 ff ff       	call   f01014d0 <strlen>
f0101f3a:	83 c4 10             	add    $0x10,%esp
f0101f3d:	3b 45 cc             	cmp    -0x34(%ebp),%eax
f0101f40:	0f 8f f0 fe ff ff    	jg     f0101e36 <calculator+0x10a>
			Operation_Position++;
		}

	}

	calc(A, numericop);
f0101f46:	83 ec 08             	sub    $0x8,%esp
f0101f49:	8d 45 9c             	lea    -0x64(%ebp),%eax
f0101f4c:	50                   	push   %eax
f0101f4d:	8d 45 d0             	lea    -0x30(%ebp),%eax
f0101f50:	50                   	push   %eax
f0101f51:	e8 c2 fc ff ff       	call   f0101c18 <calc>
	return 0;
f0101f56:	83 c4 10             	add    $0x10,%esp
f0101f59:	b8 00 00 00 00       	mov    $0x0,%eax

}
f0101f5e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101f61:	5b                   	pop    %ebx
f0101f62:	5e                   	pop    %esi
f0101f63:	5f                   	pop    %edi
f0101f64:	5d                   	pop    %ebp
f0101f65:	c3                   	ret    

f0101f66 <powerbase>:
#include <kern/kdebug.h>



int powerbase(char base, char power)
{
f0101f66:	55                   	push   %ebp
f0101f67:	89 e5                	mov    %esp,%ebp
f0101f69:	53                   	push   %ebx
f0101f6a:	83 ec 04             	sub    $0x4,%esp
f0101f6d:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101f70:	8b 55 0c             	mov    0xc(%ebp),%edx
	if(power!=1)
		return (base*powerbase(base,power-1));
	return base;
f0101f73:	0f be c3             	movsbl %bl,%eax



int powerbase(char base, char power)
{
	if(power!=1)
f0101f76:	80 fa 01             	cmp    $0x1,%dl
f0101f79:	74 18                	je     f0101f93 <powerbase+0x2d>
		return (base*powerbase(base,power-1));
f0101f7b:	89 c3                	mov    %eax,%ebx
f0101f7d:	83 ec 08             	sub    $0x8,%esp
f0101f80:	83 ea 01             	sub    $0x1,%edx
f0101f83:	0f be d2             	movsbl %dl,%edx
f0101f86:	52                   	push   %edx
f0101f87:	50                   	push   %eax
f0101f88:	e8 d9 ff ff ff       	call   f0101f66 <powerbase>
f0101f8d:	83 c4 10             	add    $0x10,%esp
f0101f90:	0f af c3             	imul   %ebx,%eax
	return base;
}
f0101f93:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101f96:	c9                   	leave  
f0101f97:	c3                   	ret    

f0101f98 <char_to_float>:

Float char_to_float(char* arg)
{
f0101f98:	55                   	push   %ebp
f0101f99:	89 e5                	mov    %esp,%ebp
f0101f9b:	57                   	push   %edi
f0101f9c:	56                   	push   %esi
f0101f9d:	53                   	push   %ebx
f0101f9e:	83 ec 38             	sub    $0x38,%esp
f0101fa1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	int len=strlen(arg);
f0101fa4:	53                   	push   %ebx
f0101fa5:	e8 26 f5 ff ff       	call   f01014d0 <strlen>
f0101faa:	89 c7                	mov    %eax,%edi
	double a = 0;

	Float retval;
	retval.error=0;

	while (i<len)
f0101fac:	83 c4 10             	add    $0x10,%esp
	short neg = 0;
	int i=0;
	double a = 0;

	Float retval;
	retval.error=0;
f0101faf:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
Float char_to_float(char* arg)
{
	int len=strlen(arg);
	short neg = 0;
	int i=0;
	double a = 0;
f0101fb6:	d9 ee                	fldz   
f0101fb8:	dd 5d d8             	fstpl  -0x28(%ebp)

Float char_to_float(char* arg)
{
	int len=strlen(arg);
	short neg = 0;
	int i=0;
f0101fbb:	be 00 00 00 00       	mov    $0x0,%esi
f0101fc0:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101fc3:	89 f3                	mov    %esi,%ebx
f0101fc5:	8b 75 0c             	mov    0xc(%ebp),%esi
	double a = 0;

	Float retval;
	retval.error=0;

	while (i<len)
f0101fc8:	e9 a9 00 00 00       	jmp    f0102076 <char_to_float+0xde>
	{
		if (*(arg) == '.')
f0101fcd:	0f b6 06             	movzbl (%esi),%eax
f0101fd0:	3c 2e                	cmp    $0x2e,%al
f0101fd2:	75 3f                	jne    f0102013 <char_to_float+0x7b>
		{
//			after the point
			a = a + (*(arg+1) - '0') * 0.1;
f0101fd4:	0f be 46 01          	movsbl 0x1(%esi),%eax
f0101fd8:	83 e8 30             	sub    $0x30,%eax
f0101fdb:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101fde:	db 45 e0             	fildl  -0x20(%ebp)
f0101fe1:	dc 0d e8 28 10 f0    	fmull  0xf01028e8
f0101fe7:	dc 45 d8             	faddl  -0x28(%ebp)
			cprintf("entered val %f",a);
f0101fea:	83 ec 0c             	sub    $0xc,%esp
f0101fed:	dd 55 d8             	fstl   -0x28(%ebp)
f0101ff0:	dd 1c 24             	fstpl  (%esp)
f0101ff3:	68 bd 26 10 f0       	push   $0xf01026bd
f0101ff8:	e8 46 ea ff ff       	call   f0100a43 <cprintf>
			retval.number=a;
f0101ffd:	8b 45 08             	mov    0x8(%ebp),%eax
f0102000:	dd 45 d8             	fldl   -0x28(%ebp)
f0102003:	d9 18                	fstps  (%eax)
			return retval;
f0102005:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102008:	89 78 04             	mov    %edi,0x4(%eax)
f010200b:	83 c4 10             	add    $0x10,%esp
f010200e:	e9 8f 00 00 00       	jmp    f01020a2 <char_to_float+0x10a>
		}
		if (*(arg)=='-')
f0102013:	3c 2d                	cmp    $0x2d,%al
f0102015:	74 1e                	je     f0102035 <char_to_float+0x9d>
		{
			neg = 1;
		}
		else if (*(arg) < '0' || (*(arg) > '9'))
f0102017:	83 e8 30             	sub    $0x30,%eax
f010201a:	3c 09                	cmp    $0x9,%al
f010201c:	76 17                	jbe    f0102035 <char_to_float+0x9d>
		{
			retval.error = 1;
			cprintf("Invalid Argument");
f010201e:	83 ec 0c             	sub    $0xc,%esp
f0102021:	68 ac 26 10 f0       	push   $0xf01026ac
f0102026:	e8 18 ea ff ff       	call   f0100a43 <cprintf>
f010202b:	83 c4 10             	add    $0x10,%esp
		{
			neg = 1;
		}
		else if (*(arg) < '0' || (*(arg) > '9'))
		{
			retval.error = 1;
f010202e:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
			cprintf("Invalid Argument");
			//operation or invalid argument
		}
		// BUG: PowerBase has to be fixed
		// BUG: if power equals zero, the point disappears ?!
		a =  powerbase(10,len-i) / 10 * (*(arg) - '0') + a;
f0102035:	83 ec 08             	sub    $0x8,%esp
f0102038:	89 f8                	mov    %edi,%eax
f010203a:	29 d8                	sub    %ebx,%eax
f010203c:	0f be c0             	movsbl %al,%eax
f010203f:	50                   	push   %eax
f0102040:	6a 0a                	push   $0xa
f0102042:	e8 1f ff ff ff       	call   f0101f66 <powerbase>
f0102047:	83 c4 10             	add    $0x10,%esp
f010204a:	89 c1                	mov    %eax,%ecx
f010204c:	b8 67 66 66 66       	mov    $0x66666667,%eax
f0102051:	f7 e9                	imul   %ecx
f0102053:	c1 fa 02             	sar    $0x2,%edx
f0102056:	c1 f9 1f             	sar    $0x1f,%ecx
f0102059:	29 ca                	sub    %ecx,%edx
f010205b:	0f be 06             	movsbl (%esi),%eax
f010205e:	83 e8 30             	sub    $0x30,%eax
f0102061:	0f af d0             	imul   %eax,%edx
f0102064:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0102067:	db 45 e0             	fildl  -0x20(%ebp)
f010206a:	dc 45 d8             	faddl  -0x28(%ebp)
f010206d:	dd 5d d8             	fstpl  -0x28(%ebp)
		i++;
f0102070:	83 c3 01             	add    $0x1,%ebx
		arg=arg+1;
f0102073:	83 c6 01             	add    $0x1,%esi
	double a = 0;

	Float retval;
	retval.error=0;

	while (i<len)
f0102076:	39 fb                	cmp    %edi,%ebx
f0102078:	0f 8c 4f ff ff ff    	jl     f0101fcd <char_to_float+0x35>
		a =  powerbase(10,len-i) / 10 * (*(arg) - '0') + a;
		i++;
		arg=arg+1;
	}

	cprintf("entered val %f",a);
f010207e:	83 ec 04             	sub    $0x4,%esp
f0102081:	ff 75 dc             	pushl  -0x24(%ebp)
f0102084:	ff 75 d8             	pushl  -0x28(%ebp)
f0102087:	68 bd 26 10 f0       	push   $0xf01026bd
f010208c:	e8 b2 e9 ff ff       	call   f0100a43 <cprintf>
	retval.number=a;
f0102091:	8b 45 08             	mov    0x8(%ebp),%eax
f0102094:	dd 45 d8             	fldl   -0x28(%ebp)
f0102097:	d9 18                	fstps  (%eax)
	return retval;
f0102099:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010209c:	89 78 04             	mov    %edi,0x4(%eax)
f010209f:	83 c4 10             	add    $0x10,%esp
}
f01020a2:	8b 45 08             	mov    0x8(%ebp),%eax
f01020a5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01020a8:	5b                   	pop    %ebx
f01020a9:	5e                   	pop    %esi
f01020aa:	5f                   	pop    %edi
f01020ab:	5d                   	pop    %ebp
f01020ac:	c2 04 00             	ret    $0x4
f01020af:	90                   	nop

f01020b0 <__udivdi3>:
f01020b0:	55                   	push   %ebp
f01020b1:	57                   	push   %edi
f01020b2:	56                   	push   %esi
f01020b3:	83 ec 10             	sub    $0x10,%esp
f01020b6:	8b 54 24 2c          	mov    0x2c(%esp),%edx
f01020ba:	8b 7c 24 20          	mov    0x20(%esp),%edi
f01020be:	8b 74 24 24          	mov    0x24(%esp),%esi
f01020c2:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f01020c6:	85 d2                	test   %edx,%edx
f01020c8:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01020cc:	89 34 24             	mov    %esi,(%esp)
f01020cf:	89 c8                	mov    %ecx,%eax
f01020d1:	75 35                	jne    f0102108 <__udivdi3+0x58>
f01020d3:	39 f1                	cmp    %esi,%ecx
f01020d5:	0f 87 bd 00 00 00    	ja     f0102198 <__udivdi3+0xe8>
f01020db:	85 c9                	test   %ecx,%ecx
f01020dd:	89 cd                	mov    %ecx,%ebp
f01020df:	75 0b                	jne    f01020ec <__udivdi3+0x3c>
f01020e1:	b8 01 00 00 00       	mov    $0x1,%eax
f01020e6:	31 d2                	xor    %edx,%edx
f01020e8:	f7 f1                	div    %ecx
f01020ea:	89 c5                	mov    %eax,%ebp
f01020ec:	89 f0                	mov    %esi,%eax
f01020ee:	31 d2                	xor    %edx,%edx
f01020f0:	f7 f5                	div    %ebp
f01020f2:	89 c6                	mov    %eax,%esi
f01020f4:	89 f8                	mov    %edi,%eax
f01020f6:	f7 f5                	div    %ebp
f01020f8:	89 f2                	mov    %esi,%edx
f01020fa:	83 c4 10             	add    $0x10,%esp
f01020fd:	5e                   	pop    %esi
f01020fe:	5f                   	pop    %edi
f01020ff:	5d                   	pop    %ebp
f0102100:	c3                   	ret    
f0102101:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0102108:	3b 14 24             	cmp    (%esp),%edx
f010210b:	77 7b                	ja     f0102188 <__udivdi3+0xd8>
f010210d:	0f bd f2             	bsr    %edx,%esi
f0102110:	83 f6 1f             	xor    $0x1f,%esi
f0102113:	0f 84 97 00 00 00    	je     f01021b0 <__udivdi3+0x100>
f0102119:	bd 20 00 00 00       	mov    $0x20,%ebp
f010211e:	89 d7                	mov    %edx,%edi
f0102120:	89 f1                	mov    %esi,%ecx
f0102122:	29 f5                	sub    %esi,%ebp
f0102124:	d3 e7                	shl    %cl,%edi
f0102126:	89 c2                	mov    %eax,%edx
f0102128:	89 e9                	mov    %ebp,%ecx
f010212a:	d3 ea                	shr    %cl,%edx
f010212c:	89 f1                	mov    %esi,%ecx
f010212e:	09 fa                	or     %edi,%edx
f0102130:	8b 3c 24             	mov    (%esp),%edi
f0102133:	d3 e0                	shl    %cl,%eax
f0102135:	89 54 24 08          	mov    %edx,0x8(%esp)
f0102139:	89 e9                	mov    %ebp,%ecx
f010213b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010213f:	8b 44 24 04          	mov    0x4(%esp),%eax
f0102143:	89 fa                	mov    %edi,%edx
f0102145:	d3 ea                	shr    %cl,%edx
f0102147:	89 f1                	mov    %esi,%ecx
f0102149:	d3 e7                	shl    %cl,%edi
f010214b:	89 e9                	mov    %ebp,%ecx
f010214d:	d3 e8                	shr    %cl,%eax
f010214f:	09 c7                	or     %eax,%edi
f0102151:	89 f8                	mov    %edi,%eax
f0102153:	f7 74 24 08          	divl   0x8(%esp)
f0102157:	89 d5                	mov    %edx,%ebp
f0102159:	89 c7                	mov    %eax,%edi
f010215b:	f7 64 24 0c          	mull   0xc(%esp)
f010215f:	39 d5                	cmp    %edx,%ebp
f0102161:	89 14 24             	mov    %edx,(%esp)
f0102164:	72 11                	jb     f0102177 <__udivdi3+0xc7>
f0102166:	8b 54 24 04          	mov    0x4(%esp),%edx
f010216a:	89 f1                	mov    %esi,%ecx
f010216c:	d3 e2                	shl    %cl,%edx
f010216e:	39 c2                	cmp    %eax,%edx
f0102170:	73 5e                	jae    f01021d0 <__udivdi3+0x120>
f0102172:	3b 2c 24             	cmp    (%esp),%ebp
f0102175:	75 59                	jne    f01021d0 <__udivdi3+0x120>
f0102177:	8d 47 ff             	lea    -0x1(%edi),%eax
f010217a:	31 f6                	xor    %esi,%esi
f010217c:	89 f2                	mov    %esi,%edx
f010217e:	83 c4 10             	add    $0x10,%esp
f0102181:	5e                   	pop    %esi
f0102182:	5f                   	pop    %edi
f0102183:	5d                   	pop    %ebp
f0102184:	c3                   	ret    
f0102185:	8d 76 00             	lea    0x0(%esi),%esi
f0102188:	31 f6                	xor    %esi,%esi
f010218a:	31 c0                	xor    %eax,%eax
f010218c:	89 f2                	mov    %esi,%edx
f010218e:	83 c4 10             	add    $0x10,%esp
f0102191:	5e                   	pop    %esi
f0102192:	5f                   	pop    %edi
f0102193:	5d                   	pop    %ebp
f0102194:	c3                   	ret    
f0102195:	8d 76 00             	lea    0x0(%esi),%esi
f0102198:	89 f2                	mov    %esi,%edx
f010219a:	31 f6                	xor    %esi,%esi
f010219c:	89 f8                	mov    %edi,%eax
f010219e:	f7 f1                	div    %ecx
f01021a0:	89 f2                	mov    %esi,%edx
f01021a2:	83 c4 10             	add    $0x10,%esp
f01021a5:	5e                   	pop    %esi
f01021a6:	5f                   	pop    %edi
f01021a7:	5d                   	pop    %ebp
f01021a8:	c3                   	ret    
f01021a9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01021b0:	3b 4c 24 04          	cmp    0x4(%esp),%ecx
f01021b4:	76 0b                	jbe    f01021c1 <__udivdi3+0x111>
f01021b6:	31 c0                	xor    %eax,%eax
f01021b8:	3b 14 24             	cmp    (%esp),%edx
f01021bb:	0f 83 37 ff ff ff    	jae    f01020f8 <__udivdi3+0x48>
f01021c1:	b8 01 00 00 00       	mov    $0x1,%eax
f01021c6:	e9 2d ff ff ff       	jmp    f01020f8 <__udivdi3+0x48>
f01021cb:	90                   	nop
f01021cc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01021d0:	89 f8                	mov    %edi,%eax
f01021d2:	31 f6                	xor    %esi,%esi
f01021d4:	e9 1f ff ff ff       	jmp    f01020f8 <__udivdi3+0x48>
f01021d9:	66 90                	xchg   %ax,%ax
f01021db:	66 90                	xchg   %ax,%ax
f01021dd:	66 90                	xchg   %ax,%ax
f01021df:	90                   	nop

f01021e0 <__umoddi3>:
f01021e0:	55                   	push   %ebp
f01021e1:	57                   	push   %edi
f01021e2:	56                   	push   %esi
f01021e3:	83 ec 20             	sub    $0x20,%esp
f01021e6:	8b 44 24 34          	mov    0x34(%esp),%eax
f01021ea:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f01021ee:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01021f2:	89 c6                	mov    %eax,%esi
f01021f4:	89 44 24 10          	mov    %eax,0x10(%esp)
f01021f8:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f01021fc:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
f0102200:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0102204:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f0102208:	89 74 24 18          	mov    %esi,0x18(%esp)
f010220c:	85 c0                	test   %eax,%eax
f010220e:	89 c2                	mov    %eax,%edx
f0102210:	75 1e                	jne    f0102230 <__umoddi3+0x50>
f0102212:	39 f7                	cmp    %esi,%edi
f0102214:	76 52                	jbe    f0102268 <__umoddi3+0x88>
f0102216:	89 c8                	mov    %ecx,%eax
f0102218:	89 f2                	mov    %esi,%edx
f010221a:	f7 f7                	div    %edi
f010221c:	89 d0                	mov    %edx,%eax
f010221e:	31 d2                	xor    %edx,%edx
f0102220:	83 c4 20             	add    $0x20,%esp
f0102223:	5e                   	pop    %esi
f0102224:	5f                   	pop    %edi
f0102225:	5d                   	pop    %ebp
f0102226:	c3                   	ret    
f0102227:	89 f6                	mov    %esi,%esi
f0102229:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0102230:	39 f0                	cmp    %esi,%eax
f0102232:	77 5c                	ja     f0102290 <__umoddi3+0xb0>
f0102234:	0f bd e8             	bsr    %eax,%ebp
f0102237:	83 f5 1f             	xor    $0x1f,%ebp
f010223a:	75 64                	jne    f01022a0 <__umoddi3+0xc0>
f010223c:	8b 6c 24 14          	mov    0x14(%esp),%ebp
f0102240:	39 6c 24 0c          	cmp    %ebp,0xc(%esp)
f0102244:	0f 86 f6 00 00 00    	jbe    f0102340 <__umoddi3+0x160>
f010224a:	3b 44 24 18          	cmp    0x18(%esp),%eax
f010224e:	0f 82 ec 00 00 00    	jb     f0102340 <__umoddi3+0x160>
f0102254:	8b 44 24 14          	mov    0x14(%esp),%eax
f0102258:	8b 54 24 18          	mov    0x18(%esp),%edx
f010225c:	83 c4 20             	add    $0x20,%esp
f010225f:	5e                   	pop    %esi
f0102260:	5f                   	pop    %edi
f0102261:	5d                   	pop    %ebp
f0102262:	c3                   	ret    
f0102263:	90                   	nop
f0102264:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0102268:	85 ff                	test   %edi,%edi
f010226a:	89 fd                	mov    %edi,%ebp
f010226c:	75 0b                	jne    f0102279 <__umoddi3+0x99>
f010226e:	b8 01 00 00 00       	mov    $0x1,%eax
f0102273:	31 d2                	xor    %edx,%edx
f0102275:	f7 f7                	div    %edi
f0102277:	89 c5                	mov    %eax,%ebp
f0102279:	8b 44 24 10          	mov    0x10(%esp),%eax
f010227d:	31 d2                	xor    %edx,%edx
f010227f:	f7 f5                	div    %ebp
f0102281:	89 c8                	mov    %ecx,%eax
f0102283:	f7 f5                	div    %ebp
f0102285:	eb 95                	jmp    f010221c <__umoddi3+0x3c>
f0102287:	89 f6                	mov    %esi,%esi
f0102289:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0102290:	89 c8                	mov    %ecx,%eax
f0102292:	89 f2                	mov    %esi,%edx
f0102294:	83 c4 20             	add    $0x20,%esp
f0102297:	5e                   	pop    %esi
f0102298:	5f                   	pop    %edi
f0102299:	5d                   	pop    %ebp
f010229a:	c3                   	ret    
f010229b:	90                   	nop
f010229c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01022a0:	b8 20 00 00 00       	mov    $0x20,%eax
f01022a5:	89 e9                	mov    %ebp,%ecx
f01022a7:	29 e8                	sub    %ebp,%eax
f01022a9:	d3 e2                	shl    %cl,%edx
f01022ab:	89 c7                	mov    %eax,%edi
f01022ad:	89 44 24 18          	mov    %eax,0x18(%esp)
f01022b1:	8b 44 24 0c          	mov    0xc(%esp),%eax
f01022b5:	89 f9                	mov    %edi,%ecx
f01022b7:	d3 e8                	shr    %cl,%eax
f01022b9:	89 c1                	mov    %eax,%ecx
f01022bb:	8b 44 24 0c          	mov    0xc(%esp),%eax
f01022bf:	09 d1                	or     %edx,%ecx
f01022c1:	89 fa                	mov    %edi,%edx
f01022c3:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f01022c7:	89 e9                	mov    %ebp,%ecx
f01022c9:	d3 e0                	shl    %cl,%eax
f01022cb:	89 f9                	mov    %edi,%ecx
f01022cd:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01022d1:	89 f0                	mov    %esi,%eax
f01022d3:	d3 e8                	shr    %cl,%eax
f01022d5:	89 e9                	mov    %ebp,%ecx
f01022d7:	89 c7                	mov    %eax,%edi
f01022d9:	8b 44 24 1c          	mov    0x1c(%esp),%eax
f01022dd:	d3 e6                	shl    %cl,%esi
f01022df:	89 d1                	mov    %edx,%ecx
f01022e1:	89 fa                	mov    %edi,%edx
f01022e3:	d3 e8                	shr    %cl,%eax
f01022e5:	89 e9                	mov    %ebp,%ecx
f01022e7:	09 f0                	or     %esi,%eax
f01022e9:	8b 74 24 1c          	mov    0x1c(%esp),%esi
f01022ed:	f7 74 24 10          	divl   0x10(%esp)
f01022f1:	d3 e6                	shl    %cl,%esi
f01022f3:	89 d1                	mov    %edx,%ecx
f01022f5:	f7 64 24 0c          	mull   0xc(%esp)
f01022f9:	39 d1                	cmp    %edx,%ecx
f01022fb:	89 74 24 14          	mov    %esi,0x14(%esp)
f01022ff:	89 d7                	mov    %edx,%edi
f0102301:	89 c6                	mov    %eax,%esi
f0102303:	72 0a                	jb     f010230f <__umoddi3+0x12f>
f0102305:	39 44 24 14          	cmp    %eax,0x14(%esp)
f0102309:	73 10                	jae    f010231b <__umoddi3+0x13b>
f010230b:	39 d1                	cmp    %edx,%ecx
f010230d:	75 0c                	jne    f010231b <__umoddi3+0x13b>
f010230f:	89 d7                	mov    %edx,%edi
f0102311:	89 c6                	mov    %eax,%esi
f0102313:	2b 74 24 0c          	sub    0xc(%esp),%esi
f0102317:	1b 7c 24 10          	sbb    0x10(%esp),%edi
f010231b:	89 ca                	mov    %ecx,%edx
f010231d:	89 e9                	mov    %ebp,%ecx
f010231f:	8b 44 24 14          	mov    0x14(%esp),%eax
f0102323:	29 f0                	sub    %esi,%eax
f0102325:	19 fa                	sbb    %edi,%edx
f0102327:	d3 e8                	shr    %cl,%eax
f0102329:	0f b6 4c 24 18       	movzbl 0x18(%esp),%ecx
f010232e:	89 d7                	mov    %edx,%edi
f0102330:	d3 e7                	shl    %cl,%edi
f0102332:	89 e9                	mov    %ebp,%ecx
f0102334:	09 f8                	or     %edi,%eax
f0102336:	d3 ea                	shr    %cl,%edx
f0102338:	83 c4 20             	add    $0x20,%esp
f010233b:	5e                   	pop    %esi
f010233c:	5f                   	pop    %edi
f010233d:	5d                   	pop    %ebp
f010233e:	c3                   	ret    
f010233f:	90                   	nop
f0102340:	8b 74 24 10          	mov    0x10(%esp),%esi
f0102344:	29 f9                	sub    %edi,%ecx
f0102346:	19 c6                	sbb    %eax,%esi
f0102348:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f010234c:	89 74 24 18          	mov    %esi,0x18(%esp)
f0102350:	e9 ff fe ff ff       	jmp    f0102254 <__umoddi3+0x74>
