---
theme: seriph
background: https://cover.sli.dev
transition: slide-left
layout: cover
title: Lecture 6 - AVR Advanced Assembly Language Programming
---

# Lecture 6: AVR Advanced Assembly Language Programming
## {{ $slidev.configs.subject }}
### Semester {{ $slidev.configs.semester }}
#### Presented by {{ $slidev.configs.presenter }}

---

## Lecture Outline

<div class="text-sm">

1.  **Assembler Directives Recap** (operators, `.EQU`, `HIGH`/`LOW`)
2.  Register and Direct Addressing Modes
3.  Register Indirect Addressing Mode (Pointers X, Y, Z)
4.  Look-Up Tables and Table Processing (`LPM`)
5.  Bit-Addressability
6.  Accessing EEPROM in the AVR
7.  Checksum and ASCII Subroutines
8.  Macros

</div>

---

## Objectives

Upon completion of this chapter, you will be able to:

- List and use the 13 addressing modes of the AVR
- Use register indirect addressing with the X, Y, and Z pointer registers, including auto-increment and auto-decrement
- Access look-up tables and fixed data stored in program (Flash) ROM using the `LPM` instruction
- Manipulate individual bits of GPRs, I/O registers, and the status register
- Read from and write to the AVR's on-chip EEPROM
- Calculate and test a checksum byte to detect data corruption
- Write and use assembler macros, and contrast them with subroutines

---

## Section 6.1: A Few More Assembler Directives

* In Chapter 2, we introduced the assembler directives `.ORG`, `.SET`, and `.INCLUDE`. The AVR Studio IDE also supports **arithmetic and logic expressions** between constants defined with `.EQU`, evaluated **at assembly time** — zero runtime cost.

```asm
.EQU ALFA = 50
.EQU BETA = 40
LDI  R23, ALFA                ;R23 = ALFA = 50
LDI  R24, ((ALFA-BETA)*2)+9   ;R24 = ((50-40)*2)+9 = 29
```

---
layout: two-cols
---

## Table 6-1: Arithmetic Operators

| Symbol | Action |
|---|---|
| `+` | Addition |
| `-` | Subtraction |
| `*` | Multiplication |
| `/` | Division |
| `%` | Modulo |

::right::

## Table 6-2: Logic Operators

| Symbol | Action |
|---|---|
| `&` | Bitwise AND |
| `\|` | Bitwise OR |
| `^` | Bitwise XOR |
| `~` | Bitwise NOT |

```asm
.EQU C1 = 0x50
.EQU C2 = 0x10
.EQU C3 = 0x04
LDI R21,(C1&C2)|C3  ;R21=(0x10)|0x04 = 0x14
```

---

## Table 6-3: Shift Operators

| Symbol | Action | Example |
|---|---|---|
| `<<` | Shifts the left expression left by the number of places given by the right expression | `LDI R16,0b00000111<<1 ;R16=0b00001110` |
| `>>` | Shifts the left expression right by the number of places given by the right expression | `LDI R20,0b100>>1 ;R20=0b010` |

<br>

These operators are heavily used together with bit names to build a byte for `SREG` or an I/O register without having to remember bit positions.

---
layout: two-cols-header
---

## Figure 6-1: Bits of the Status Register (`SREG`)

::left::

| D7 | | | | | | | D0 |
|---|---|---|---|---|---|---|---|
| I | T | H | S | V | N | Z | C |

* Suppose we want to set the Z and C bits and clear the rest:

```asm
LDI R20,0b00000011  ;Z=1, C=1
OUT SREG,R20
```

::right::

* `M32DEF.INC` defines names for every `SREG` bit:

```asm
.equ SREG_C = 0   ;carry flag
.equ SREG_Z = 1   ;zero flag
.equ SREG_N = 2   ;negative flag
.equ SREG_V = 3   ;overflow flag
.equ SREG_S = 4   ;sign bit
.equ SREG_H = 5   ;half carry flag
.equ SREG_T = 6   ;bit copy storage
.equ SREG_I = 7   ;global interrupt enable
```

* So we can set Z without memorizing bit positions:

```asm
LDI R16,1<<SREG_Z          ;R16=0b00000010
OUT SREG,R16
LDI R16,(1<<SREG_V)|(1<<SREG_S)  ;set V and S
OUT SREG,R16
```

---

## Example 6-1: Setting I/O Pins With and Without Directives

Set PB2 and PB4 of `PORTB` to 1 and clear the other pins.

```asm {*}{lines:true}
; (a) without directives
LDI  R20,0x14        ;R20 = 0x14 (0b00010100)
OUT  PORTB,R20

; (b) using directives
LDI  R20,(1<<4)|(1<<2)   ;R20 = (0b10000|0b00100) = 0b10100
OUT  PORTB,R20

; (c) using the register-bit names from M32DEF.INC
LDI  R20,(1<<PB4)|(1<<PB2)  ;set the PB4 and PB2 bits
OUT  PORTB,R20
```

Since the assembler substitutes every directive with its equivalent value at assembly time, using directives has **no effect on performance** — it only makes the code more readable and portable.

---

## `.EQU`, `.INCLUDE`, and `HIGH()`/`LOW()`

* `.EQU` assigns a constant a name, and the assembler substitutes the value wherever the name is used:

```asm
.equ C1 = 2
.equ C2 = 3
LDI R20,C1|(1<<C2)   ;R20 = 2|(1<<3) = 0b00001010
```

* `.INCLUDE "M32DEF.INC"` is equivalent to copying the whole header file to the top of the program, which is how PBx bit names, register names, and `RAMEND` become available.
* `HIGH()` and `LOW()` split a 16-bit value into its high and low bytes — essential because most AVR registers are 8 bits wide:

```asm
LDI R16,LOW(0x4455)   ;R16 = 0x55
LDI R17,HIGH(0x4455)  ;R17 = 0x44

; classic stack pointer init (RAMEND = 0x085F on ATmega32)
LDI R16,HIGH(RAMEND)  ;R16 = 0x08
OUT SPH,R16
LDI R16,LOW(RAMEND)   ;R16 = 0x5F
OUT SPL,R16
```

---

## Lecture Outline

<div class="text-sm">

1.  Assembler Directives Recap
2.  **Register and Direct Addressing Modes**
3.  Register Indirect Addressing Mode (Pointers X, Y, Z)
4.  Look-Up Tables and Table Processing (`LPM`)
5.  Bit-Addressability
6.  Accessing EEPROM in the AVR
7.  Checksum and ASCII Subroutines
8.  Macros

</div>

---

## Section 6.2: The AVR's 13 Addressing Modes

*Addressing modes* are the various ways the CPU can access an operand: in a register, in memory, or as an immediate value. They are fixed by the CPU's designer — the programmer cannot invent new ones. The AVR provides 13 addressing modes, grouped into six categories:

1. Single-Register (Immediate)
2. Register
3. Direct
4. Register Indirect
5. Flash Direct
6. Flash Indirect

This lecture covers all six groups: immediate, two-register, and direct addressing in this section; register indirect (RAM) in Section 6.3; and Flash addressing (look-up tables) in Section 6.4.

---

## Single-Register (Immediate) Addressing Mode

* The operand is a single register:

```asm
NEG R18   ;negate the contents of R18
COM R19   ;complement the contents of R19
INC R20   ;increment R20
DEC R21   ;decrement R21
ROR R22   ;rotate right R22
```

* Some instructions also carry a constant (*immediate data*) alongside the register operand — the letter "I" in `LDI`, `ANDI`, `SUBI` stands for **immediate**:

```asm
LDI  R19,0x25             ;load 0x25 into R19
SUBI R19,0x6              ;subtract 0x6 from R19
ANDI R19,0b01000000       ;AND R19 with 0x40
```

* `Figure 6-2a` (12-bit opcode + 4-bit Rd) encodes plain single-register instructions; `Figure 6-2b` (4-bit opcode + 8-bit immediate + 4-bit Rd) encodes the immediate form. Immediate addressing can only target R16–R31.

---

## Two-Register Addressing Mode

Two-register addressing mode uses two registers to hold the data being manipulated — 6-bit opcode, 5-bit `Rr`, 5-bit `Rd` (Figure 6-3).

```asm
ADD R20,R23   ;add R23 to R20
SUB R29,R20   ;subtract R20 from R29
AND R16,R17   ;AND R16 with R17
MOV R23,R19   ;copy the contents of R19 to R23
```

---
layout: two-cols-header
---

## Direct Addressing Mode

::left::

* The operand's RAM address is embedded directly in the instruction (16-bit address field, $0000–$FFFF):

```asm
LDS R19,0x560  ;R19 = mem[0x560]
STS 0x40,R19   ;mem[0x40] = R19
```

* Data memory does **not** support immediate addressing — to store an immediate value in RAM you must first load it into a GPR, then use `STS`:

```asm
LDI R19,0x95
STS 0x520,R19  ;store 0x95 into 0x520
```

::right::

* **I/O direct addressing mode** is a special case for the 64 standard I/O registers, using `IN`/`OUT` with a 6-bit address ($00–$3F):

```asm
IN  R18,0x16   ;R18 = PINB
OUT 0x15,R18   ;PORTC = R18

; equivalent, more readable forms
IN  R26,PINB
OUT PORTC,R19
```

* `IN`/`OUT` are more efficient than `LDS`/`STS` for these 64 registers, since the I/O address is only 6 bits vs. a full 16-bit direct address.

---

## Table 6-4: Selected ATmega32 I/O Register Addresses

| Symbol | Name | I/O Address | Data Memory Addr. |
|---|---|---|---|
| PIND | Port D input pins | $10 | $30 |
| DDRD | Data Direction, Port D | $11 | $31 |
| PORTD | Port D data register | $12 | $32 |
| PINC | Port C input pins | $13 | $33 |
| DDRC | Data Direction, Port C | $14 | $34 |
| PORTC | Port C data register | $15 | $35 |
| PINB | Port B input pins | $16 | $36 |
| DDRB | Data Direction, Port B | $17 | $37 |
| PORTB | Port B data register | $18 | $38 |
| SPL / SPH | Stack Pointer Low/High | $3D / $3E | $5D / $5E |

Every standard I/O register has **two** addresses: the I/O address (used by `IN`/`OUT`) and the data-memory address, which is always `I/O address + 0x20`. Chips with more than 64 I/O registers place the extras in *extended I/O memory*, reachable only via direct addressing (`STS`/`LDS`), never `IN`/`OUT`.

<div class="text-sm">

Register addresses can differ across AVR family members (e.g. I/O address $2 is `TWAR` on ATmega32 but `DDRE` on ATmega128) — always prefer register **names** over raw addresses for portability.

</div>

---

## Example 6-4: Three Ways to Write $55 to Port B

```asm {*}{lines:true}
; (a) using register names
LDI R20,0xFF
OUT DDRB,R20      ;Port B = output
LDI R20,0x55
OUT PORTB,R20     ;Port B = 0x55

; (b) using I/O addresses (DDRB=$17, PORTB=$18)
OUT 0x17,R20
OUT 0x18,R20

; (c) using data memory addresses (DDRB=$37, PORTB=$38)
STS 0x37,R20
STS 0x38,R20
```

All three forms are functionally identical — the assembler resolves names to addresses at assembly time. Names are strongly preferred for readability and portability.

---

## Lecture Outline

<div class="text-sm">

1.  Assembler Directives Recap
2.  Register and Direct Addressing Modes
3.  **Register Indirect Addressing Mode (Pointers X, Y, Z)**
4.  Look-Up Tables and Table Processing (`LPM`)
5.  Bit-Addressability
6.  Accessing EEPROM in the AVR
7.  Checksum and ASCII Subroutines
8.  Macros

</div>

---
layout: image-right
backgroundSize: contain
image: /ch6_xyz_pointer_registers.png
---

## Section 6.3: Register Indirect Addressing Mode

* A register holds a **pointer** to the data memory location instead of the address being embedded in the instruction.
* Three dedicated 16-bit pointer registers — **X**, **Y**, **Z** — cover the entire 64 KB data space.
* Each is built from two GPRs:
  * X = R27:R26 (`XH:XL`)
  * Y = R29:R28 (`YH:YL`)
  * Z = R31:R30 (`ZH:ZL`)
* `LDI XL,0x31` is identical to `LDI R26,0x31`, since `XL` is just another name for `R26`.
* The big win: this makes addressing **dynamic** rather than static — a pointer can be moved in a loop, unlike a fixed `LDS`/`STS` address.

---

## Using X, Y, Z: `LD` and `ST`

```asm {*}{lines:true}
LD  R24,X     ;load into R24 from the location pointed to by X

; example: load the contents of location 0x130 into R18
LDI XL,0x30   ;low byte of X
LDI XH,0x01   ;high byte of X  (X = 0x0130)
LD  R18,X     ;R18 = mem[0x130]

; ST writes through any of X, Y, Z
LDI ZL,0x9F
LDI ZH,0x13         ;Z = 0x139F
ST  Z,R23           ;store R23 into location 0x139F
```

Because `X`, `Y`, `Z` are ordinary 16-bit registers, there is no `INC Y` instruction — to advance the pointer you must increment its low byte, e.g. `INC YL`, or use the auto-increment addressing modes on the next slide.

---

## Table 6-5: Auto-Increment / Auto-Decrement (for `LD`)

$$
\begin{array}{|l|l|}
\hline
\textbf{Instruction} & \textbf{Function} \\
\hline
\texttt{LD Rn,X} & \text{After loading via X, X stays the same} \\
\hline
\texttt{LD Rn,X+} & \text{After loading via X, X is } \textbf{incremented} \\
\hline
\texttt{LD Rn,-X} & \text{X is } \textbf{decremented} \text{, then the location is loaded} \\
\hline
\texttt{LD Rn,Y / Rn,Y+ / Rn,-Y} & \text{Same pattern for Y} \\
\hline
\texttt{LDD Rn,Y+q} & \text{Loads Y+q; Y stays the same} \\
\hline
\texttt{LD Rn,Z / Rn,Z+ / Rn,-Z} & \text{Same pattern for Z} \\
\hline
\texttt{LDD Rn,Z+q} & \text{Loads Z+q; Z stays the same} \\
\hline
\end{array}
$$

This syntax is shown for `LD`, but it applies to `ST` as well. The auto-inc/dec affects the **whole 16-bit** pointer and does **not** touch any SREG flag — wrap-around from `$FFFF` to `$0000` raises no flag.

---
layout: image-right
backgroundSize: contain
image: /ch6_indirect_inc_dec.png
---

## Why Auto-Increment Exists

* Using `INC XL` to step the pointer can silently break when the low byte overflows (e.g. `$5FF → $600`) — `INC XL` does **not** propagate a carry into `XH`.
* The auto-increment/-decrement addressing modes (`X+`, `-X`, …) add or subtract 1 from the **entire 16-bit register**, so the carry into the high byte is handled correctly in hardware.
* **Post-increment** (`X+`): use the pointer, *then* add 1.
* **Pre-decrement** (`-X`): subtract 1 from the pointer, *then* use it.

---

## Example 6-5: Copying `$55` into `$140`–`$144`, Three Ways

```asm {*|2-7|9-19|21-28}{lines:true,maxHeight:'320px'}
; (a) direct addressing -- static, no loop possible
LDI R17,0x55
STS 0x140,R17
STS 0x141,R17
STS 0x142,R17
STS 0x143,R17
STS 0x144,R17

; (b) register indirect -- still no loop, but dynamic
LDI R16,0x55
LDI YL,0x40
LDI YH,0x1
ST  Y,R16      ;mem[0x140]=R16
INC YL
ST  Y,R16      ;mem[0x141]=R16
INC YL
ST  Y,R16      ;mem[0x142]=R16
; ... (repeats)

; (c) register indirect WITH a loop -- only possible because of (b)
LDI R16,0x5     ;counter
LDI R20,0x55    ;value to copy
LDI YL,0x40
LDI YH,0x1
L1: ST  Y,R20
    INC YL
    DEC R16
    BRNE L1
```

Solution (c) is the most efficient, and it is possible **only** because register indirect addressing makes the destination dynamic.

---

## Example 6-7: Clearing 16 Locations — `INC` vs. Auto-Increment

```asm {*|1-8|10-16}{lines:true}
; (a) manual INC XL
LDI R16,16
LDI XL,0x60
LDI XH,0x00
LDI R20,0x0
L1: ST  X,R20
    INC XL
    DEC R16
    BRNE L1

; (b) auto-increment -- one instruction fewer per iteration
LDI R16,16
LDI XL,0x60
LDI XH,0x00
LDI R20,0x0
L1: ST  X+,R20
    DEC R16
    BRNE L1
```

---

## Using X, Y, and Z Together

Example 6-10 adds two 4-byte numbers (`$130–$133` and `$150–$153`) using **all three** pointer registers at once — X and Y walk the two source operands while Z walks the destination:

```asm {*|1-10|11-17}{lines:true}
.INCLUDE "M32DEF.INC"
LDI R16,4          ;counter = 4 bytes
LDI XL,0x30
LDI XH,0x1         ;X = $130
LDI YL,0x50
LDI YH,0x1         ;Y = $150
LDI ZL,0x60
LDI ZH,0x1         ;Z = $160
CLC                ;clear carry before the loop
L1: LD  R18,X+     ;R18 = mem[X], X++
    LD  R19,Y+     ;R19 = mem[Y], Y++
    ADC R18,R19    ;R18 = R18+R19+carry
    ST  Z+,R18     ;mem[Z] = R18, Z++
    DEC R16
    BRNE L1
```

Notice the little-endian convention throughout: the low byte lives at the low address, the high byte at the high address.

---

## Register Indirect with Displacement

* Sometimes we want a byte a few positions away from where Z currently points, without moving Z. `LDD`/`STD` add a fixed displacement `q` (0–63) to Y or Z **without changing the pointer**.

```asm
LDD Rd,Z+q    ;load from Z+q into Rd, Z unchanged
STD Z+q,Rr    ;store Rr into Z+q, Z unchanged

; example
LDD R20,Z+5   ;read the byte 5 positions after where Z points
STD Z+5,R20   ;write R20 five positions after where Z points
```

---

## Example 6-11: `ADD3LOC` — Sum Three Consecutive Locations

```asm {*}{lines:true}
ADD3LOC:
    LDI  R21,0
    LD   R20,Z        ;R20 = mem[Z]
    LDD  R16,Z+1       ;R16 = mem[Z+1]
    ADD  R20,R16
    BRCC L1
    INC  R21           ;carry occurred
L1: LDD  R16,Z+2       ;R16 = mem[Z+2]
    ADD  R20,R16
    BRCC L2
    INC  R21
L2: ST   Z,R20         ;store the low byte back into Z
    STD  Z+1,R21       ;store the carry-accumulator into Z+1
    RET
```

The Z register must point at the first of the three locations **before** this function is called.

---

## Lecture Outline

<div class="text-sm">

1.  Assembler Directives Recap
2.  Register and Direct Addressing Modes
3.  Register Indirect Addressing Mode (Pointers X, Y, Z)
4.  **Look-Up Tables and Table Processing (`LPM`)**
5.  Bit-Addressability
6.  Accessing EEPROM in the AVR
7.  Checksum and ASCII Subroutines
8.  Macros

</div>

---

## Section 6.4: `.DB`/`.DW` — Fixed Data in Program ROM

* `.DB` (define byte) allocates ROM in byte-sized chunks — decimal, binary, hex, a single ASCII char (`'Y'`), or an ASCII string (`"Hello ALI"`).
* Since each Flash location is **2 bytes wide**, `.DB` bytes are packed two-per-location; an odd count is padded with a zero high byte on the last location.
* `.DW` (define word) does the same for 16-bit values (up to 65,535).

```asm {*}{lines:true}
;MY DATA IN FLASH ROM
        .ORG $500
DATA1:  .DB 1,8,5,3          ;$500L=01 $500H=08 $501L=05 $501H=03
DATA2:  .DB 28               ;decimal (0x1C); $502L=1C $502H=00 (padded)
DATA3:  .DB 0b00110101       ;binary (0x35)
DATA4:  .DB 0x39             ;hex
        .ORG 0x510
DATA5:  .DB 'Y'              ;single ASCII char
DATA6:  .DB "Hello ALI"      ;ASCII string
```

```asm
; .DW example -- little endian: low byte of 0x1234 (0x34) -> low byte of $600
.ORG $600
DATA1: .DW 0x1234,0x1122
DATA2: .DW 28          ;0x001C
```

---
layout: image-right
backgroundSize: contain
image: /ch6_lpm_addressing.png
---

## Reading Table Elements: `LPM`

* `LPM` loads the program (Flash) ROM byte pointed to by **Z** into a register — this is *register indirect flash addressing*.
* Two variants, shown in Table 6-6:

| Instruction | Function |
|---|---|
| `LPM Rn,Z` | Constant addressing: Z is unchanged after the read |
| `LPM Rn,Z+` | Post-increment: reads, then increments Z |

* Each Flash location holds 2 bytes. The **LSB of Z** selects which byte: `LSB=0` → low byte, `LSB=1` → high byte. Bits 15:1 of Z select the word address.

---

## Addressing Bytes with Z

* To read the low byte of word address `0x0002`, load Z with `0x0004`; for the high byte, load Z with `0x0005` (shift the word address left 1 bit, then set bit 0 for the high byte):

```asm
LDI ZH,HIGH(0x0005)
LDI ZL,LOW(0x0005)
LPM R16,Z          ;high byte of word 0x0002

; using the << shift operator directly on a label
LDI ZH,HIGH($100<<1)      ;low byte of location $100
LDI ZL,LOW($100<<1)
LPM R16,Z

LDI ZH,HIGH(($100<<1)|1)  ;high byte of location $100
LDI ZL,LOW(($100<<1)|1)
LPM R16,Z
```

The `<<1` shift is why every `MYDATA<<1` you will see in the examples that follow is necessary: labels are word addresses, but `Z` needs a byte address.

---

## Example 6-14/6-15: Sending `"WORLD PEACE."` to Port B

```asm {*|1-10|12-20}{lines:true}
.ORG $0000
LDI R20,0xFF
OUT DDRB,R20
LDI ZH,HIGH(MYDATA<<1)
LDI ZL,LOW(MYDATA<<1)
LPM R20,Z          ;R20 = 'W'
OUT PORTB,R20
INC ZL             ;point to next byte
LPM R20,Z          ;R20 = 'O'
OUT PORTB,R20
; ... repeats for each character (manual method)

; -- counter-driven loop version --
LDI R16,11             ;11 characters incl. '.'
LDI ZH,HIGH(MYDATA<<1)
LDI ZL,LOW(MYDATA<<1)
L1: LPM R20,Z
    OUT PORTB,R20
    INC ZL
    DEC R16
    BRNE L1
HERE: RJMP HERE
.ORG $500
MYDATA: .DB "WORLD PEACE."
```

---

## Auto-Increment for Z, and a Null Terminator

Manually doing `INC ZL` can break at a page boundary (no carry into `ZH`). `LPM Rn,Z+` fixes this in hardware. Combine it with a null-terminated string to avoid needing a counter at all:

```asm {*|1-11}{lines:true}
.ORG $0000
LDI R20,0xFF
OUT DDRB,R20
LDI ZH,HIGH(MYDATA<<1)
LDI ZL,LOW(MYDATA<<1)
L1: LPM  R20,Z+       ;read byte, auto-increment Z
    CPI  R20,0
    BREQ HERE         ;stop at the null terminator
    OUT  PORTB,R20
    RJMP L1
HERE: RJMP HERE
.ORG $500
MYDATA: .DB "WORLD PEACE",0   ;notice the null
```

### Example 6-17: Copying a ROM Message into RAM

```asm {*}{lines:true}
LDI ZH,HIGH(MYDATA<<1)
LDI ZL,LOW(MYDATA<<1)
LDI XH,HIGH(RAM_BUF)      ;RAM_BUF = 0x140
LDI XL,LOW(RAM_BUF)
L1: LPM  R20,Z+
    CPI  R20,0
    BREQ HERE
    ST   X+,R20           ;copy into RAM and advance X
    RJMP L1
HERE: RJMP HERE
MYDATA: .DB "The Promise of World Peace",0
```

---

## Look-Up Tables for Computed Values

A look-up table trades a calculation for a memory read: instead of computing `4 + x²`, store all the results and index into them with `x`.

### Example 6-19: `x²` Look-Up Table (Port B → Port C)

```asm {*}{lines:true}
LDI ZH,HIGH(XSQR_TABLE<<1)
L1: LDI ZL,LOW(XSQR_TABLE<<1)
    IN   R16,PINB
    ANDI R16,0x0F        ;mask to keep x = 0-9
    ADD  ZL,R16          ;index into the table
    LPM  R18,Z           ;R18 = x^2
    OUT  PORTC,R18
    RJMP L1

.ORG 0x10
XSQR_TABLE:
    .DB 0,1,4,9,16,25,36,49,64,81
```

If Port B = 9, Port C receives `$51` (decimal 81 = 9²). The same pattern (mask → add to `ZL` → `LPM`) works for any function of a small integer input, e.g. Example 6-20's `x²+2x+3` table (`.DB 3,6,11,18,27,38,51,66,83,102`).

Look-up tables can also live in **RAM** instead of ROM when their contents must change at run time; the AVR's `SPM` instruction can write to Flash, but see the datasheet for details.

---

## Lecture Outline

<div class="text-sm">

1.  Assembler Directives Recap
2.  Register and Direct Addressing Modes
3.  Register Indirect Addressing Mode (Pointers X, Y, Z)
4.  Look-Up Tables and Table Processing (`LPM`)
5.  **Bit-Addressability**
6.  Accessing EEPROM in the AVR
7.  Checksum and ASCII Subroutines
8.  Macros

</div>

---

## Section 6.5: Bit-Addressability

Unlike CPUs such as the 386 or Pentium, which only access registers/ports a byte at a time, the AVR provides dedicated single-bit instructions. All of them use the direct addressing mode only — there is no register-indirect or Flash form of a bit-oriented instruction.

## Table 6-7: Single-Bit (Bit-Oriented) Instructions

$$
\begin{array}{|l|l|}
\hline
\textbf{Instruction} & \textbf{Function} \\
\hline
\texttt{SBI A,b} & \text{Set Bit b in I/O register} \\
\hline
\texttt{CBI A,b} & \text{Clear Bit b in I/O register} \\
\hline
\texttt{SBIC A,b} & \text{Skip next instruction if Bit b in I/O register is Cleared} \\
\hline
\texttt{SBIS A,b} & \text{Skip next instruction if Bit b in I/O register is Set} \\
\hline
\texttt{BST Rr,b} & \text{Bit store from register Rr to T} \\
\hline
\texttt{BLD Rd,b} & \text{Bit load from T to Rd} \\
\hline
\texttt{SBRC Rr,b} & \text{Skip next instruction if Bit b in Register is Cleared} \\
\hline
\texttt{SBRS Rr,b} & \text{Skip next instruction if Bit b in Register is Set} \\
\hline
\texttt{BRBS s,k} & \text{Branch if Bit s in status register is Set} \\
\hline
\texttt{BRBC s,k} & \text{Branch if Bit s in status register is Cleared} \\
\hline
\end{array}
$$

*Note: `A` can be any location of the I/O register.*

---

## Manipulating Bits of a GPR

* **`SBR Rd,K`** (Set Bits in Register) — sets every bit of `Rd` where the corresponding bit of `K` is 1. It is just another name for `ORI`.
* **`CBR Rd,K`** (Clear Bits in Register) — clears every bit of `Rd` where the corresponding bit of `K` is 1.

```asm
LDI R17,0b01011001   ;R17 = 0x59
SBR R17,0b01100100   ;set bits 2, 5, 6  -> R17 = 0x7D
CBR R17,0b01100100   ;clear bits 2, 5, 6 -> R17 = 0x19
```

* **`BST Rd,b`** / **`BLD Rr,b`** — copy a single bit through the `T` flag of `SREG`. `BST` stores bit `b` of `Rd` into `T`; `BLD` loads `T` into bit `b` of `Rr`.

```asm
BST R17,3   ;T = bit 3 of R17
BLD R19,5   ;bit 5 of R19 = T
```

### Example 6-21: Save a Switch's State into RAM Bit D0

```asm
.EQU MYREG = 0x200
CBI  DDRB,0
IN   R17,PINB
BST  R17,4       ;T = PINB.4
LDI  R16,0x00
BLD  R16,0       ;R16.0 = T
STS  MYREG,R16
```

---

## Checking a Bit: `SBRS` / `SBRC`

```asm
SBRS Rd,b   ;skip next instruction if bit b in Rd is SET
SBRC Rd,b   ;skip next instruction if bit b in Rd is CLEARED
```

### Example 6-22: Switch on PC7 → 'Y' or 'N' on Port D

```asm {*}{lines:true}
.INCLUDE "M32DEF.INC"
        CBI  DDRC,7
        LDI  R16,0xFF
        OUT  DDRD,R16
AGAIN:  IN   R20,PINC
        SBRS R20,7        ;skip next line if bit PC7 is SET
        RJMP OVER         ;it must be LOW
        LDI  R16,'Y'
        OUT  PORTD,R16
        RJMP AGAIN
OVER:   LDI  R16,'N'
        OUT  PORTD,R16
        RJMP AGAIN
```

---

## Manipulating I/O Register Bits

For the **lower 32** I/O registers (addresses 0–31) we can set/clear/test single bits directly:

```asm
SBI PORTA,1   ;set Bit 1 in PORTA
CBI PORTB,4   ;clear Bit 4 in PORTB
```

### Example 6-23: Toggle PB2 200 Times

```asm {*}{lines:true}
        LDI R16,200
        SBI DDRB,2
AGAIN:  SBI PORTB,2     ;set   (toggle) PB2
        CBI PORTB,2     ;clear (toggle) PB2
        DEC R16
        BRNE AGAIN
```

`SBIS`/`SBIC` test a bit of the lower 32 I/O registers the same way `SBRS`/`SBRC` test a GPR bit — Examples 6-24/6-25 rewrite Example 6-22 using `SBIC PINC,7` and `SBIS PINC,7` respectively, directly on the port, with no `IN` needed first.

---
layout: image-right
backgroundSize: contain
image: /ch6_sreg_bits.png
---

## Status Register Bit-Addressability

* The bits of `SREG` carry the flags C, Z, N, V, S, H, T, and I.
* Two families of instructions manipulate them directly:
  * `BRBS s,k` / `BRBC s,k` — branch if flag bit `s` is set/cleared
  * `BSET s` / `BCLR s` — set/clear flag bit `s`
* Because remembering bit positions (`s`) is error-prone, the AVR also provides mnemonic aliases for both families (next slide).

---

## Tables 6-8 & 6-9: Flag-Oriented Instruction Aliases

**Table 6-8 — Conditional Branches** (aliases for `BRBS`/`BRBC`)

$$
\begin{array}{|l|l|l|l|}
\hline
\textbf{Set (=1)} & \textbf{Clear (=0)} & \textbf{Set (=1)} & \textbf{Clear (=0)} \\
\hline
\texttt{BRCS (C)} & \texttt{BRCC} & \texttt{BRVS (V)} & \texttt{BRVC} \\
\hline
\texttt{BREQ (Z)} & \texttt{BRNE} & \texttt{BRLT (S)} & \texttt{BRGE} \\
\hline
\texttt{BRMI (N)} & \texttt{BRPL} & \texttt{BRHS (H)} & \texttt{BRHC} \\
\hline
\texttt{BRTS (T)} & \texttt{BRTC} & \texttt{BRIE (I)} & \texttt{BRID} \\
\hline
\end{array}
$$

**Table 6-9 — Flag set/clear** (aliases for `BSET`/`BCLR`)

$$
\begin{array}{|l|l|l|l|}
\hline
\textbf{Set} & \textbf{Clear} & \textbf{Set} & \textbf{Clear} \\
\hline
\texttt{SEC (C=1)} & \texttt{CLC} & \texttt{SEV (V=1)} & \texttt{CLV} \\
\hline
\texttt{SEZ (Z=1)} & \texttt{CLZ} & \texttt{SES (S=1)} & \texttt{CLS} \\
\hline
\texttt{SEN (N=1)} & \texttt{CLN} & \texttt{SEH (H=1)} & \texttt{CLH} \\
\hline
\texttt{SET (T=1)} & \texttt{CLT} & \texttt{SEI (I=1)} & \texttt{CLI} \\
\hline
\end{array}
$$

```asm
BRCS L1     ;branch if carry flag is set     (same as BRBS 0,L1)
```

---

## Internal RAM Is *Not* Bit-Addressable

Unlike I/O registers, internal RAM has no bit-oriented instructions. To test or change a single bit of a RAM location, you must first bring it into a GPR, manipulate it there, then store it back.

### Example 6-26: Round a RAM Value Up to Even, Send to Port B

```asm {*}{lines:true}
.EQU MYREG = 0x195
        LDI  R16,0xFF
        OUT  DDRB,R16
AGAIN:  LDS  R16,MYREG
        SBRS R16,0        ;bit test D0, skip if SET (odd)
        RJMP OVER         ;already even
        CBR  R16,0b00000001   ;clear D0 -> make it even
OVER:   OUT  PORTB,R16
        JMP  AGAIN
```

---

## Lecture Outline

<div class="text-sm">

1.  Assembler Directives Recap
2.  Register and Direct Addressing Modes
3.  Register Indirect Addressing Mode (Pointers X, Y, Z)
4.  Look-Up Tables and Table Processing (`LPM`)
5.  Bit-Addressability
6.  **Accessing EEPROM in the AVR**
7.  Checksum and ASCII Subroutines
8.  Macros

</div>

---

## Section 6.6: EEPROM Overview

* EEPROM retains its contents **even when power is removed** — unlike SRAM, which loses its data.
* Every AVR chip has some on-chip EEPROM:

| Chip | Bytes | Chip | Bytes | Chip | Bytes |
|---|---|---|---|---|---|
| ATmega8 | 512 | ATmega16 | 512 | ATmega32 | 1024 |
| ATmega64 | 2048 | ATmega128 | 4096 | ATmega256RZ | 4096 |
| ATmega640 | 4096 | ATmega1280 | 4096 | ATmega2560 | 4096 |

* Three I/O registers control it:
  * **EEARH:EEARL** — EEPROM Address Register (16-bit; only 10 bits used on ATmega32, since 1024 bytes need 10 address bits)
  * **EEDR** — EEPROM Data Register (the bridge between EEPROM and the CPU for both reads and writes)
  * **EECR** — EEPROM Control Register

---
layout: image-right
backgroundSize: contain
image: /ch6_eeprom_registers.png
---

## EEPROM Registers

* **EEARH:EEARL** together form a 16-bit address register; on ATmega32 only bits `EEAR9:EEAR0` are implemented (10 bits → 1024 locations).
* **EECR** bit layout (bits 7–4 reserved):

| Bit | 3 | 2 | 1 | 0 |
|---|---|---|---|---|
| Name | EERIE | EEMWE | EEWE | EERE |

* **EERE** (Read Enable) — set to 1 to start a read (if `EEWE=0`); the byte lands in `EEDR`.
* **EEWE / EEMWE** (Write/Master-Write Enable) — with `EEMWE=1`, setting `EEWE` within 4 clock cycles starts a write. If `EEMWE=0`, setting `EEWE` alone has no effect. Hardware auto-clears `EEMWE` after 4 clocks, guarding against accidental writes.
* **EERIE** — EEPROM Ready Interrupt Enable (covered in Chapter 10).

---

## Writing to EEPROM (5 Steps)

1. Wait until `EEWE` becomes zero (EEPROM is not busy).
2. Write the new EEPROM address to `EEAR` (optional).
3. Write the new EEPROM data to `EEDR` (optional).
4. Set the `EEMWE` bit to one (in `EECR`).
5. **Within 4 clock cycles** after setting `EEMWE`, set `EEWE` to one.

Steps 2–3 are optional and order doesn't matter, but **nothing may happen between steps 4 and 5** — the hardware clears `EEMWE` back to zero after 4 clock cycles.

### Example 6-28: Store `'G'` into EEPROM Location `0x005F`

```asm {*}{lines:true}
WAIT:  SBIC EECR,EEWE      ;check EEWE -- last write finished?
       RJMP WAIT
       LDI  R18,0
       LDI  R17,0x5F
       OUT  EEARH,R18
       OUT  EEARL,R17
       LDI  R16,'G'
       OUT  EEDR,R16
       SBI  EECR,EEMWE     ;master write enable
       SBI  EECR,EEWE      ;write enable -- must be within 4 clocks
```

---

## Reading from EEPROM (4 Steps)

1. Wait until `EEWE` becomes zero.
2. Write the new EEPROM address to `EEAR` (optional).
3. Set the `EERE` bit to one.
4. Read the EEPROM data from `EEDR`.

### Example 6-29: Read EEPROM Location `0x005F` into Port B

```asm {*}{lines:true}
       LDI  R16,0xFF
       OUT  DDRB,R16
WAIT:  SBIC EECR,EEWE
       RJMP WAIT
       LDI  R18,0
       LDI  R17,0x5F
       OUT  EEARH,R18
       OUT  EEARL,R17
       SBI  EECR,EERE      ;set Read Enable
       IN   R16,EEDR       ;R16 = EEPROM data
       OUT  PORTB,R16
```

---

## Initializing EEPROM: `.ESEG` / `.CSEG`

* `.CSEG` (default) places subsequent data in **program (code) memory**.
* `.ESEG` places subsequent data in **EEPROM**, and initializes it directly with `.DB`:

```asm
.ESEG
.ORG $10
DATA1: .DB $95
DATA2: .DB $19
```

### Example 6-30: Power-Up Counter (EEPROM Survives Reset)

```asm {*}{lines:true}
        LDI  XH,HIGH(COUNTER)
        LDI  XL,LOW(COUNTER)
        CALL LOAD_FROM_EEPROM   ;R20 = current COUNTER value
        INC  R20
        CALL STORE_IN_EEPROM    ;write it back
HERE:   RJMP HERE
;-------EEPROM-------
.ESEG
.ORG 0
COUNTER: .DB 0
```

`COUNTER` starts at 0 and is incremented on **every power-up**, because EEPROM — unlike SRAM — survives a power cycle. `LOAD_FROM_EEPROM`/`STORE_IN_EEPROM` are just the read/write sequences from the previous two slides, wrapped as reusable subroutines.

---

## Lecture Outline

<div class="text-sm">

1.  Assembler Directives Recap
2.  Register and Direct Addressing Modes
3.  Register Indirect Addressing Mode (Pointers X, Y, Z)
4.  Look-Up Tables and Table Processing (`LPM`)
5.  Bit-Addressability
6.  Accessing EEPROM in the AVR
7.  **Checksum and ASCII Subroutines**
8.  Macros

</div>

---

## Section 6.7: Checksum Byte

A **checksum byte** protects a block of ROM/EEPROM data against corruption (e.g. from a power-current surge).

* **Calculate**: (1) add all the data bytes, dropping any carries; (2) take the 2's complement of the sum — that is the checksum byte, appended to the end of the series.
* **Test**: add all the bytes **including** the checksum byte, dropping carries. If the result is zero, the data is intact; otherwise it is corrupted.

### Example 6-31: Worked Checksum

```asm {*|1-4|6-9|11-15}{lines:true}
; (a) calculate the checksum byte for $25, $62, $3F, $52
  $25 + $62 + $3F + $52 = $118
  drop the carry -> $18
  2's complement of $18 = $E8   <- checksum byte

; (b) test: sum all bytes INCLUDING the checksum byte
  $25 + $62 + $3F + $52 + $E8 = $200
  drop carries -> $00           <- not corrupted

; (c) suppose $62 was corrupted to $22
  $25 + $22 + $3F + $52 + $E8 = $1C0
  drop the carry -> $C0         <- nonzero: DATA IS CORRUPTED
```

Program 6-1 in the book packages this as five reusable subroutines: `LOAD_FROM_EEPROM`/`STORE_IN_EEPROM` (per-byte EEPROM access), `LOAD_OPTIONS`/`STORE_OPTIONS` (bulk EEPROM ↔ RAM copy), `INIT_OPTIONS` (Flash defaults → RAM), `CAL_CHKSUM`, and `TEST_CHKSUM`.

---

## BCD-to-ASCII and Binary-to-ASCII Subroutines

* **BCD → ASCII**: many real-time clock (RTC) chips report time/date in packed BCD (one nibble per digit). To show a packed BCD byte on an LCD/PC screen, split it into two nibbles and `OR` each with `0x30`:

```asm
ANDI R21,0x0F   ;isolate the low nibble
ORI  R21,0x30   ;turn it into an ASCII digit
; ... SWAP the byte and repeat for the high nibble
```

* **Binary (hex) → ASCII**: many ADC chips return an 8-bit binary value (0–255). To display it in decimal, repeatedly divide by 10 to peel off digits (the same divide-by-10 algorithm from Chapter 5), then `OR` each digit with `0x30`. Digits are stored **little-endian** — lowest digit at the lowest address — matching AVR convention throughout.

Both conversions are used heavily once we reach LCD and real-time-clock interfacing later in the course.

---

## Lecture Outline

<div class="text-sm">

1.  Assembler Directives Recap
2.  Register and Direct Addressing Modes
3.  Register Indirect Addressing Mode (Pointers X, Y, Z)
4.  Look-Up Tables and Table Processing (`LPM`)
5.  Bit-Addressability
6.  Accessing EEPROM in the AVR
7.  Checksum and ASCII Subroutines
8.  **Macros**

</div>

---

## Section 6.8: What Is a Macro?

* A **macro** lets a programmer write a repeated block of code **once** and invoke it by name wherever it is needed — the assembler pastes the body in at every call site.
* Every macro definition has three parts:

```asm
.MACRO name
      ...           ; the body
.ENDMACRO
```

* A macro can take up to 10 parameters, referenced as `@0` through `@9` in the body.

```asm
.MACRO LOADIO
      LDI R20,@1
      OUT @0,R20
.ENDMACRO
```

```asm
LOADIO PORTA,0x20      ;send 0x20 to PORTA
.EQU   VAL_1 = 0xFF
LOADIO DDRC,VAL_1
LOADIO SPL,0x55         ;send 0x55 to SPL
```

---

## Program 6-4: Using Macros in a Program

```asm {*|1-4|6-13|15-24}{lines:true,maxHeight:'420px'}
.INCLUDE "M32DEF.INC"
.MACRO LOADIO
      LDI R20,@1
      OUT @0,R20
.ENDMACRO

;--------------------- time-delay macro
.MACRO DELAY
      LDI @0,@1
BACK: NOP
      NOP
      NOP
      NOP
      DEC @0
      BRNE BACK
.ENDMACRO

;--------------------- program starts
.ORG 0
LOADIO DDRB,0xFF        ;make Port B an output
L1: LOADIO PORTB,0x55
    DELAY  R18,0x70
    LOADIO PORTB,0xAA
    DELAY  R18,0x70
    RJMP L1
```

---

## `.INCLUDE` and `.LISTMAC` Directives

* **`.INCLUDE`** lets a set of frequently used macros be written once, saved to a file (e.g. `MYMACRO1.MAC`), and pulled into any `.asm` file — no need to retype them:

```asm
.INCLUDE "MYMACRO1.MAC"   ;brings in LOADIO, DELAY, etc.
```

* By default, the `.lst` listing file shows only the macro **invocation**, not its expanded body — which makes debugging awkward.
* **`.LISTMAC`** turns on full expansion in the listing. Expanded lines are marked with a leading `+`:

```asm
.LISTMAC
LOADIO PORTA,0x20
```
```
+LDI R20,0x20
+OUT PORTA,R20
        LOADIO   PORTA,0x20
```

---

## Macros vs. Subroutines

| | Macros | Subroutines |
|---|---|---|
| **Code size** | Grows with every invocation — a 10-instruction macro called 10 times adds 100 instructions | Fixed — the code exists once, regardless of call count |
| **Call overhead** | None — the body is pasted inline | `CALL` costs 3–4 clocks, `RET` costs 4 clocks (~8 cycles/call) |
| **Stack usage** | None | Uses the stack for the return address |
| **Best for** | Short, hot, timing-critical sequences | Larger blocks of logic reused many times |

Both tools reduce the time it takes to write code and the chance of copy-paste errors — the choice between them is a size-vs-speed trade-off.

---

## Summary

* **Addressing modes**: the AVR provides 13 addressing modes across six families — immediate, register, direct, register indirect, Flash direct, and Flash indirect.
* **Register indirect addressing** (X, Y, Z, with auto-increment/-decrement) makes RAM access *dynamic*, enabling loops that direct addressing cannot support.
* **Look-up tables** live in Flash and are read with `LPM`, using `Z` as a byte-granular pointer (`<<1` to convert a word address to a byte address).
* **Bit-addressability**: GPRs, the lower 32 I/O registers, and `SREG` all support dedicated single-bit set/clear/test instructions; internal RAM does not.
* **EEPROM** (`EEARH:EEARL`, `EEDR`, `EECR`) survives power loss and is accessed through a strict wait–address–data–enable sequence for both reads and writes.
* **Checksum bytes** detect data corruption via a sum-and-2's-complement / sum-and-test pattern.
* **Macros** (`.MACRO`/`.ENDMACRO`, `@0`–`@9` parameters) trade code size for zero call overhead — the opposite trade-off from subroutines.
