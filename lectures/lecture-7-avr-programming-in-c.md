---
theme: seriph
background: https://cover.sli.dev
transition: slide-left
layout: cover
title: Lecture 7 - AVR Programming in C
---

# Lecture 7: AVR Programming in C
## {{ $slidev.configs.subject }}
### Semester {{ $slidev.configs.semester }}
#### Presented by {{ $slidev.configs.presenter }}

---

## Lecture Outline

<div class="text-sm">

1.  **Data Types**
2.  Time Delays in C
3.  I/O Programming in C
4.  Logical vs. Bit-Wise Operators
5.  Setting, Clearing, and Checking a Bit
6.  Data Serialization in C
7.  Memory Types in the AVR

</div>

---

## Objectives

Upon completion of this chapter, you will be able to:

- Choose C data types that match the AVR's 8-bit register width, and explain why this matters for code size and speed
- Explain why a plain `for`-loop time delay is unreliable, and generate portable delays with `_delay_ms`/`_delay_us`
- Perform byte- and bit-level I/O port programming in C using masking
- Distinguish logical operators (`&&`, `||`, `!`) from bit-wise operators (`&`, `|`, `~`, `^`)
- Set, clear, and check individual bits of a variable using bit-wise idioms
- Explain why serial protocols not yet covered in hardware must be "bit-banged" in C
- Compare Flash, EEPROM, and RAM and choose the right one for a given kind of data

---

## Section 7.1: Why C, and Why Care About Data Types?

* Assembly gives full control of the hardware but is slow to write and hard to maintain; C trades a small amount of control for portability and productivity — the compiler generates the assembly for you.
* The AVR is an **8-bit** machine: every ALU operation, and every GPR, is natively 8 bits wide. A C data type wider than 8 bits costs *extra instructions* on every operation, because the compiler must synthesize multi-byte arithmetic from 8-bit pieces.
* **Rule of thumb: use `unsigned char` instead of `int` whenever the value fits in a byte and is never negative.**

---

## Table 7-1: Common AVR-GCC Data Type Sizes

| Data Type | Size (bytes) | Range |
|---|---|---|
| `unsigned char` | 1 | 0 to 255 |
| `char` (signed) | 1 | -128 to +127 |
| `unsigned int` | 2 | 0 to 65,535 |
| `int` (signed) | 2 | -32,768 to +32,767 |
| `unsigned long` | 4 | 0 to 4,294,967,295 |
| `long` (signed) | 4 | -2,147,483,648 to +2,147,483,647 |
| `float` | 4 | (IEEE-754 single precision) |

Every byte beyond the first means more `LD`/`ADD`/`ADC`-style multi-byte instruction sequences behind the scenes. A loop counter, a port value, or an ADC channel index should almost always be `unsigned char`.

---

## Example 7-1: Picking the Right Type

```c
unsigned char x;   // 1 byte -- ideal for a loop counter 0-255 or a port value
int y;             // 2 bytes -- needlessly wide if y never exceeds 255
unsigned long z;   // 4 bytes -- only for values that truly need this range

for (x = 0; x < 100; x++)   // GOOD: single-byte compare and increment
{
    ;
}
```

Using `int` for `x` above compiles correctly, but every loop iteration now costs a 16-bit compare/increment instead of an 8-bit one — wasted Flash and wasted clock cycles for no benefit.

---

## Lecture Outline

<div class="text-sm">

1.  Data Types
2.  **Time Delays in C**
3.  I/O Programming in C
4.  Logical vs. Bit-Wise Operators
5.  Setting, Clearing, and Checking a Bit
6.  Data Serialization in C
7.  Memory Types in the AVR

</div>

---

## Section 7.2: Time Delays in C — the `for`-Loop Trap

* A naive delay loop looks harmless:

```c
unsigned int i;
for (i = 0; i < 40000; i++)
    ;   // waste time
```

* This is **unreliable** for two independent reasons:
  1. **Clock frequency dependence** — the same loop takes a different amount of real time on a 1 MHz part vs. an 8 MHz part, since it is counting *instructions*, not *time*.
  2. **Compiler/optimizer dependence** — an empty loop body has no observable effect, so an optimizing compiler is free to **delete the entire loop**. The delay silently disappears.

* You **must** set the compiler's optimization level to **`-O0`** (no optimization) if you insist on writing a raw counting loop — otherwise there is no guarantee the loop survives compilation at all.

---

## Setting Optimization Level to `-O0`

In AVR Studio / WinAVR, the optimization level is a per-project build setting:

**Project → Configuration Options → Optimization → `-O0` (no optimization)**

<div class="text-sm">

* `-O0` keeps the delay loop's instructions in the final binary, but it is still clock-frequency dependent — the loop must be re-tuned (or recalculated) for every target clock speed.
* Higher optimization levels (`-O1`, `-O2`, `-Os`) are preferred for real firmware, which is exactly why raw counting loops are a poor way to generate a delay in C.

</div>

---

## A Portable Alternative: `<util/delay.h>`

* WinAVR (and modern avr-gcc) ship built-in, **compiler-provided** delay functions that do not depend on hand-tuned loop counts:

```c
#include <util/delay.h>

_delay_ms(1000);   // busy-wait ~1000 milliseconds
_delay_us(1000);   // busy-wait ~1000 microseconds
```

* These functions use `F_CPU` (a macro defining the clock frequency in Hz) to compute the correct number of cycles to burn, so the *same source line* produces the correct delay at any clock speed — as long as `F_CPU` is defined correctly for the project.
* They are **compiler-dependent, not hardware-dependent**: `_delay_ms` is a WinAVR/avr-libc feature, not an AVR chip feature. Porting the project to a different toolchain may require a different delay API entirely.

---

## Portability: Wrap the Compiler-Specific Call

* Because `_delay_ms`/`_delay_us` are tied to one toolchain, professional code isolates them behind a **wrapper function or macro**. Switching compilers then means editing *one* function instead of hunting through the whole codebase:

```c
void MSDelay(unsigned int itime)
{
    unsigned int i;
    unsigned char j;
    for (i = 0; i < itime; i++)
        for (j = 0; j < 100; j++)
            ;   // tuned busy-wait, or call the compiler's delay_ms here
}

// call site never needs to change, regardless of compiler:
MSDelay(500);   // ~500 ms
```

This is the same "isolate the volatile part behind one interface" principle used throughout embedded C: hardware and toolchain details stay in one place, and the rest of the program stays portable.

---

## Lecture Outline

<div class="text-sm">

1.  Data Types
2.  Time Delays in C
3.  **I/O Programming in C**
4.  Logical vs. Bit-Wise Operators
5.  Setting, Clearing, and Checking a Bit
6.  Data Serialization in C
7.  Memory Types in the AVR

</div>

---

## Section 7.3: I/O Programming in C

* Every AVR I/O register (`DDRx`, `PORTx`, `PINx`) is exposed to C as a memory-mapped variable with the same name, declared in the device header (`<avr/io.h>`).

### Byte-Size I/O — the Easy Case

```c
DDRB  = 0xFF;   // all of Port B = output
PORTB = 0x55;   // write 0x55 to Port B
unsigned char x = PINC;   // read all 8 pins of Port C
```

### Bit-Size I/O — Compiler-Dependent Syntax

* Some compilers offer a convenient `PORTB.2` bit-field-style syntax; others do not support it at all. Relying on it makes code **non-portable** across toolchains.
* **Masking works on every C compiler for every target** — it is the one technique guaranteed to be portable, and is the standard idiom used throughout this course.

---

## Lecture Outline

<div class="text-sm">

1.  Data Types
2.  Time Delays in C
3.  I/O Programming in C
4.  **Logical vs. Bit-Wise Operators**
5.  Setting, Clearing, and Checking a Bit
6.  Data Serialization in C
7.  Memory Types in the AVR

</div>

---

## Section 7.4: Logical Operators — `&&`, `||`, `!`

* Logical operators treat their **entire operand** as a single true/false value (zero = false, nonzero = true), and produce a single `1` or `0` result — they do **not** operate bit-by-bit.

```text
1110 1111 && 0000 0001  =  True  AND True   =  True   (result: 1)
1110 1111 || 0000 0000  =  True  OR  False  =  True   (result: 1)
!(1110 1111)             =  NOT(True)                 =  False  (result: 0)
```

* Logical operators are used to combine **conditions**, e.g. `if (x > 0 && y < 10)`.

---

## Table 7-2: Bit-Wise Operators — `&`, `|`, `~`, `^`

Bit-wise operators act independently on **every corresponding bit pair** of their operands and return a full-width result — this is the tool for manipulating port bits.

```text
  1110 1111          1110 1111          1110 1011
& 0000 0001        | 0000 0001        ~ ----------
------------       ------------         0001 0100
  0000 0001          1110 1111
   (AND: masks)      (OR: sets bits)     (NOT: complements every bit)
```

| Operator | Name | Effect on each bit pair |
|---|---|---|
| `&` | AND | 1 only if **both** bits are 1 — used to **mask/clear** |
| `\|` | OR | 1 if **either** bit is 1 — used to **set** |
| `~` | NOT | flips every bit of a single operand |
| `^` | XOR | 1 if the bits **differ** — used to **toggle** |

---

## Table 7-3: Shift Operators — `>>`, `<<`

```text
data >> n   ; shifts data right by n bit positions (0-fill from the left)

  1110 0000 >> 3
  --------------
  0001 1100

data << n   ; shifts data left by n bit positions (0-fill from the right)

  0000 0001 << 2
  --------------
  0000 0100
```

Shifting `1 << n` is the standard idiom for building a mask with a single bit `n` set — it appears in almost every bit set/clear/check expression, exactly as `1<<SREG_Z` did in the assembler directives of Chapter 6.

---

## Lecture Outline

<div class="text-sm">

1.  Data Types
2.  Time Delays in C
3.  I/O Programming in C
4.  Logical vs. Bit-Wise Operators
5.  **Setting, Clearing, and Checking a Bit**
6.  Data Serialization in C
7.  Memory Types in the AVR

</div>

---

## Section 7.5: Setting a Bit to 1 — `|`

```text
   xxxx xxxx                xxxx xxxx
 | 0001 0000     -- or --  | (1 << 4)
 -----------                -----------
  xxx1 xxxx                  xxx1 xxxx
```

```c
PORTB |= 0x10;     // set bit 4 of PORTB, leave every other bit unchanged
PORTB |= (1 << 4); // identical, but self-documenting -- prefer this form
```

`(1 << n)` reads as "the mask with only bit `n` set," which is clearer and less error-prone than spelling out the hex/binary literal by hand, especially when `n` is itself a named constant.

---

## Section 7.6: Clearing a Bit to 0 — `&` with `~`

```text
    xxxx xxxx                 xxxx xxxx
&   1110 1111    -- or --   &  ~(1 << 4)
------------                ------------
   xxx0 xxxx                  xxx0 xxxx
```

```c
PORTB &= 0xEF;         // clear bit 4 of PORTB, leave every other bit unchanged
PORTB &= ~(1 << 4);    // identical, and self-documenting -- prefer this form
```

### Example 7-18: Clearing a Bit

```c
PORTB &= ~(1 << 3);   // PORTB.3 = 0, all other Port B bits untouched
```

The `~` inverts `0000 1000` into `1111 0111` before the `AND`, so every bit **except** bit 3 passes through unchanged, and bit 3 is forced to 0. This mirrors `CBR` from Chapter 6's assembly, but is now portable C.

---

## Section 7.7: Checking a Bit — `&`

```text
    xxxx xxxx                 xxxx xxxx
&   0001 0000    -- or --   &  (1 << 4)
------------                ------------
   000x 0000                  00x0 0000
```

```c
if (PINB & 0x10)          // true if bit 4 of PINB is 1
    ;
if (PINB & (1 << 4))      // identical, and self-documenting -- prefer this form
    ;
```

The `&` isolates bit `n` and leaves every other bit forced to 0; the result of the whole expression is nonzero (true) exactly when bit `n` was set. **Set → `|`, Clear → `& ~`, Check → `&`** is worth memorizing as a single pattern — it is used constantly in port and flag-register manipulation.

---

## Lecture Outline

<div class="text-sm">

1.  Data Types
2.  Time Delays in C
3.  I/O Programming in C
4.  Logical vs. Bit-Wise Operators
5.  Setting, Clearing, and Checking a Bit
6.  **Data Serialization in C**
7.  Memory Types in the AVR

</div>

---

## Section 7.8: Data Serialization in C

* The AVR has several dedicated **serial peripherals** — USART, SPI, I2C, JTAG, among others — each with its own hardware shift register and control bits.
* This course has not yet covered any of that dedicated hardware (it begins in later chapters). Until then, if a program needs to shift data out or in one bit at a time, **it must be done manually**, bit by bit, using ordinary I/O pins:
  * Set a data pin high or low for the current bit.
  * Pulse a clock pin to signal "data ready."
  * Repeat for every bit, then move to the next byte.
* This manual technique is often called **bit-banging**, and it is exactly the same set/clear-a-bit idioms from Section 7.5–7.7, applied in a loop over each bit of a byte — "do it yourself" until real serial hardware is introduced.

---

## Lecture Outline

<div class="text-sm">

1.  Data Types
2.  Time Delays in C
3.  I/O Programming in C
4.  Logical vs. Bit-Wise Operators
5.  Setting, Clearing, and Checking a Bit
6.  Data Serialization in C
7.  **Memory Types in the AVR**

</div>

---

## Section 7.9: Memory Types in the AVR

| Memory | Survives power-off? | Size | Best for |
|---|---|---|---|
| **Flash** | Yes | Large | Program code, look-up tables, and other fixed data that never changes at run time |
| **EEPROM** | Yes | Small | Small data that *can* change, but must not be lost when power is removed (e.g. a saved setting, a power-up counter) |
| **RAM (SRAM)** | No | Small, but fast | Working data the program actively reads and modifies — variables, the stack, buffers |

* This table is a direct C-level restatement of Chapter 6's assembly-level view of the same three memories (`.CSEG`/`.ESEG`, `LPM`, and the EEPROM read/write sequence) — in C, the compiler and `avr-libc` (e.g. `eeprom_read_byte`/`eeprom_write_byte`, `PROGMEM`) hide most of those register-level details, but the underlying hardware trade-off is identical: choose the memory whose lifetime and access speed matches what the data actually needs.

---

## Summary

* **Data types**: match the C type to the AVR's native 8-bit width — prefer `unsigned char` over `int` to save code size and execution time.
* **Time delays**: a raw `for`-loop delay is clock- and optimizer-dependent and can even be optimized away entirely; prefer `_delay_ms`/`_delay_us` from `<util/delay.h>`, and wrap compiler-specific calls behind your own function for portability.
* **I/O programming**: byte-wide I/O is direct register assignment; bit-wide I/O should use **masking** (`|`, `&~`, `&`) rather than compiler-specific bit-field syntax.
* **Logical vs. bit-wise operators**: `&&`/`||`/`!` collapse an operand to a single true/false value; `&`/`|`/`~`/`^` act independently on every bit and are the tools for port manipulation.
* **Set / Clear / Check a bit**: `x |= (1<<n)` / `x &= ~(1<<n)` / `if (x & (1<<n))` — one pattern, used everywhere.
* **Data serialization**: without dedicated serial hardware, shifting data one bit at a time must be bit-banged manually with the same set/clear idioms.
* **Memory types**: Flash (big, fixed), EEPROM (small, persistent, writable), RAM (fast, volatile) — pick based on how the data needs to behave, not just where it is convenient to put it.
