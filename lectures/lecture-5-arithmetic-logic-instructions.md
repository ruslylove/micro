---
theme: seriph
background: https://cover.sli.dev
transition: slide-left
layout: cover
title: Lecture 5 - Arithmetic, Logic Instructions, and Programs
---

# Lecture 5: Arithmetic, Logic Instructions, and Programs
## {{ $slidev.configs.subject }}
### Semester {{ $slidev.configs.semester }}
#### Presented by {{ $slidev.configs.presenter }}

---

## Lecture Outline

<div class="text-sm">

1.  **Arithmetic Instructions**
2.  Signed Numbers and Overflow
3.  Logic and Compare Instructions
4.  Rotate, Shift Instructions and Data Serialization
5.  BCD and ASCII Conversion

</div>

---

## Objectives

* Understand the concept of signed numbers and 2's complement representation.
* Use the AVR addition and subtraction instructions (`ADD`, `ADC`, `SUB`, `SBC`, `SUBI`, `SBCI`, `SBIW`).
* Distinguish between the **carry** and **overflow** flags and know when each applies.
* Use logical instructions (`AND`, `OR`, `EOR`, `COM`, `NEG`) for masking and bit manipulation.
* Use the compare instruction (`CP`/`CPI`) together with conditional branches.
* Use `ROL`, `ROR`, `LSL`, `LSR`, `ASR`, and `SWAP` for shifting, rotating, and serializing data.
* Convert between BCD, packed BCD, and ASCII representations of decimal digits.

---

## SECTION 5.1: Arithmetic Instructions

### The `ADD` instruction

```asm
ADD  Rd, Rr    ;Rd = Rd + Rr
```

* `ADD` performs an 8-bit register-to-register addition; the result is placed in `Rd`.
* Only the **register direct** addressing mode is supported — there is **no immediate or direct-memory** form of `ADD` in the AVR.
* `ADD` affects flags **H, S, V, N, Z, C** in the status register (SREG).

---

## Example 5-1: How `ADD` Affects the Flags

Show how the flag register is affected by the following instructions.

```asm
LDI  R21, 0xF5    ;R21 = F5H
LDI  R22, 0x0B    ;R22 = 0BH
ADD  R21, R22     ;R21 = R21+R22 = F5+0B = 00 and C = 1
```

**Solution:**

```
  F5H        1111 0101
+ 0BH      + 0000 1011
------     -----------
 100H        0000 0000
```

After the addition, register R21 contains `00` and the flags are:
* **C = 1** because there is a carry out from D7.
* **Z = 1** because the result in the destination register (R21) is zero.
* **H = 1** because there is a carry from D3 to D4.

---

## Example 5-2: A Simple `ADD`

Assume RAM location `0x400` holds `33H`. Add it to `55H` and leave the sum in R21.

```asm {*|1-2|3|*}{lines:true}
LDS   R2, 0x400    ;R2 = 33H  (location 0x400 of RAM)
LDI   R21, 0x55    ;R21 = 55
ADD   R21, R2      ;R21 = R21 + R2 = 55H + 33H = 88H, C = 0
```

* `LDS` loads a byte from a data-memory address into a register.
* `LDI` loads an immediate value — but only into a register, never directly with `ADD`.

---
layout: two-cols-header
---

## `ADC`: Addition of 16-bit Numbers

::left::

* Adding two 16-bit operands requires propagating the **carry** from the low byte into the high byte — this is *multi-byte addition*.
* `ADC` (add with carry) is used for the upper byte:

```asm
ADC  Rd, Rr    ;Rd = Rd + Rr + C
```

* Adding `3CE7H + 3B8DH`:
  * Low byte: `E7 + 8D = 74H`, **C = 1**
  * High byte: `3C + 3B + 1(carry) = 78H`
  * Result: `78 74H`

::right::

**Example 5-3** — R1=8D, R2=3B, R3=E7, R4=3C. Place the sum in R3:R4 (R3 = low byte).

```asm {*|1|2-4|*}{lines:true}
ADD   R3, R1   ;R3 = R3+R1 = E7+8D = 74, C=1
ADC   R4, R2   ;R4 = R4+R2+carry
               ;R4 = 3C + 3B + 1 = 78H
```

Use `ADD` for the **lowest** byte and `ADC` for every byte above it.

---

## Subtraction Instructions

The AVR has five instructions for subtraction (Figure 5-1):

| Instruction | Operation |
|---|---|
| `SUB Rd, Rr` | Rd = Rd − Rr |
| `SBC Rd, Rr` | Rd = Rd − Rr − C |
| `SUBI Rd, K` | Rd = Rd − K |
| `SBCI Rd, K` | Rd = Rd − K − C |
| `SBIW Rd:Rd+1, K` | Rd+1:Rd = Rd+1:Rd − K |

* `SBC`/`SBCI` are **subtract with borrow** — the AVR uses the **C flag as the borrow** flag.
* `SBIW` subtracts a 6-bit immediate (0–63) from a **register pair**, and only works on the last four register pairs: `R24:R25`, `R26:R27`, `R28:R29`, `R30:R31`.

---

## How `SUB` Works Internally

Like all modern CPUs, the AVR performs subtraction using its **adder** circuitry and 2's complement — there is no separate subtractor. For `SUB Rd, Rr` (with C = 0 beforehand):

1. Take the **2's complement** of the subtrahend (`Rr`).
2. **Add** it to the minuend (`Rd`).
3. **Invert the carry** out of the addition.

<div class="text-sm">

**Example 5-4:** `R21 = 3FH`, `R20 = 23H`, then `SUB R21, R20`

```
    R21 =  3F   0011 1111        0011 1111
  - R20 =  23   0010 0011      + 1101 1101   (2's complement of 23H)
                                --------------
                  1C                1 0001 1100
                              C = 0, D7 = N = 0  (result is positive)
```

</div>

Flags: **N = 0, C = 0** — there *was* a carry out of D7, but the CPU inverts it, so C = 0 means the result is positive.

---

## The C Flag After Subtraction

* After a `SUB`/`SBC` instruction, the AVR **inverts the carry** produced by the internal addition.
* Consequence: after subtraction, **C = 1 means the result is negative**, and **C = 0 means the result is positive** — the opposite convention from addition.
* The AVR does **not** invert the carry after `ADD`/`ADC`.

**Example 5-7:** Subtract two 16-bit numbers, `2762H − 1296H` (R26=62, R27=27; low byte in R28=96H, high byte in R29=12H):

```asm {*|1|2|*}{lines:true}
SUB   R26, R28   ;R26 = 62-96 = CCH, C(borrow) = 1, N = 1
SBC   R27, R29   ;R27 = 27 - 12 - C = 27-12-1 = 14H
```

Result: `2762H − 1296H = 14CCH`.

---

## Multiplication of Unsigned Numbers

`MUL` is a byte-by-byte multiply: operands must be in registers, and the 16-bit product is always placed in **R1:R0** (R1 = high byte, R0 = low byte).

**Table 5-1: Multiplication Summary**

| Instruction | Application | Byte1 | Byte2 | High byte | Low byte |
|---|---|---|---|---|---|
| `MUL Rd, Rr` | Unsigned × Unsigned | Rd | Rr | R1 | R0 |
| `MULS Rd, Rr` | Signed × Signed | Rd | Rr | R1 | R0 |
| `MULSU Rd, Rr` | Signed × Unsigned | Rd | Rr | R1 | R0 |

```asm
LDI   R23, 0x25   ;load 25H
LDI   R24, 0x65   ;load 65H
MUL   R23, R24    ;25H * 65H = E99H -> R1 = 0EH, R0 = 99H
```

`MUL` affects only the **Z** and **C** flags. If either operand is R0 or R1, that register is overwritten by the product.

---

## Division of Unsigned Numbers

The AVR has **no hardware divide instruction**. Division is done in software by **repeated subtraction**: subtract the denominator from the numerator until it would go negative; the count of subtractions is the quotient, and what remains is the remainder.

```asm {*|1-3|5-7|9-13|15-17|*}{lines:true}
.DEF  NUM = R20
.DEF  DENOMINATOR = R21
.DEF  QUOTIENT = R22

LDI   NUM, 95            ;NUM = 95
LDI   DENOMINATOR, 10    ;DENOMINATOR = 10
CLR   QUOTIENT           ;QUOTIENT = 0

L1: INC   QUOTIENT
    SUB   NUM, DENOMINATOR
    BRCC  L1              ;branch if C is zero

    DEC   QUOTIENT         ;once too many
    ADD   NUM, DENOMINATOR ;add back to it

HERE: JMP HERE             ;stay here forever
```

*Program 5-1: Divide Function.* When the subtraction finally makes `C = 1` (a borrow), we've subtracted once too many — so we `DEC QUOTIENT` and add the denominator back to recover the true remainder.

---

## Application: Hex-to-Decimal Conversion

An 8-bit ADC gives readings 00–FFH that must be displayed in decimal. Dividing repeatedly by 10 (saving each remainder) converts hex/binary to decimal digits.

**Example 5-9:** Convert `FDH` (253 decimal) using repeated division by 10:

| Step | Quotient | Remainder |
|---|---|---|
| 253 / 10 | 25 | **3** (low digit) |
| 25 / 10 | 2 | **5** (middle digit) |
| — | — | **2** (high digit, = quotient < 10) |

So `FDH = 253`. Example 5-8 stores these three digits into consecutive RAM locations (`0x322`, `0x323`, `0x324`) using two back-to-back copies of Program 5-1's divide loop.

---

## Flags Affected: Arithmetic & Logic Summary

$$
\begin{array}{|l|c|c|c|c|c|c|}
\hline
\textbf{Instruction} & Z & C & N & V & S & H \\
\hline
\texttt{ADD, ADC} & \checkmark & \checkmark & \checkmark & \checkmark & \checkmark & \checkmark \\
\hline
\texttt{SUB, SUBI, SBC, SBCI} & \checkmark & \checkmark & \checkmark & \checkmark & \checkmark & \checkmark \\
\hline
\texttt{CP, CPI, CPC} & \checkmark & \checkmark & \checkmark & \checkmark & \checkmark & \checkmark \\
\hline
\texttt{NEG} & \checkmark & \checkmark & \checkmark & \checkmark & \checkmark & \checkmark \\
\hline
\texttt{INC, DEC} & \checkmark & - & \checkmark & \checkmark & \checkmark & - \\
\hline
\texttt{AND, ANDI, OR, ORI, EOR} & \checkmark & - & \checkmark & 0 & \checkmark & - \\
\hline
\texttt{COM} & \checkmark & 1 & \checkmark & 0 & \checkmark & - \\
\hline
\texttt{MUL, MULS, MULSU} & \checkmark & \checkmark & - & - & - & - \\
\hline
\texttt{ROL, ROR, LSL, LSR, ASR} & \checkmark & \checkmark & \checkmark & \checkmark & \checkmark & - \\
\hline
\texttt{SWAP} & - & - & - & - & - & - \\
\hline
\end{array}
$$

*C = carry/borrow, Z = zero, N = negative (D7), V = overflow, S = N⊕V (true sign), H = half-carry.*

---

## Lecture Outline

<div class="text-sm">

1.  Arithmetic Instructions
2.  **Signed Numbers and Overflow**
3.  Logic and Compare Instructions
4.  Rotate, Shift Instructions and Data Serialization
5.  BCD and ASCII Conversion

</div>

---
layout: image-right
backgroundSize: contain
image: /ch5_signed_operand.png
---

## SECTION 5.2: Signed Numbers

* All data so far has been **unsigned** — the entire 8-bit operand is magnitude.
* For **signed** numbers, D7 (MSB) is the sign bit; D0–D6 hold the magnitude.
  * D7 = 0 → positive number
  * D7 = 1 → negative number (stored in 2's complement)
* The **N flag** in SREG always equals the D7 bit of the result.
* Range of positive numbers: 0 to +127. Larger positive values need a 16-bit operand.

---

## Representing Negative Numbers (2's Complement)

To find the 2's complement representation of a negative number:

1. Write the magnitude in 8-bit binary.
2. Invert every bit (1's complement).
3. Add 1.

**Example 5-10: represent −5**

```
1.  0000 0101    5 in 8-bit binary
2.  1111 1010    invert each bit
3.  1111 1011    add 1  ->  FBH
```

`−5 = FBH`, and D7 = N = 1 shows the number is negative.

**Example 5-12: represent −128** → `1000 0000` → invert → `0111 1111` → +1 → `1000 0000` = `80H`. Notice +128 and −128 share the same bit pattern in an 8-bit signed operand — 128 itself cannot be represented as a positive signed byte.

---

## Range of Signed Byte Operands

<div class="text-sm">

| Decimal | Binary | Hex |
|---|---|---|
| −128 | 1000 0000 | 80 |
| −127 | 1000 0001 | 81 |
| ... | ... | ... |
| −2 | 1111 1110 | FE |
| −1 | 1111 1111 | FF |
| 0 | 0000 0000 | 00 |
| +1 | 0000 0001 | 01 |
| +2 | 0000 0010 | 02 |
| ... | ... | ... |
| +127 | 0111 1111 | 7F |

</div>

A signed byte covers **−128 to +127**; unsigned covers **0 to 255**.

---

## The Overflow Problem

* The CPU only understands 0s and 1s — it has no idea whether you intend a byte as signed or unsigned.
* If the true (signed) result of an operation is too large to fit, an **overflow** has occurred, and the CPU sets the **V flag** to warn the programmer.

**Example 5-13:** `R20 = 0x60 (+96)`, `R21 = 0x46 (+70)`, `ADD R20, R21`

```
   +96   0110 0000
 + +70   0100 0110
 -----   ---------
  +166   1010 0110    N = 1 (negative!) and V = 1
```

`+96 + +70` should be `+166`, but a signed byte tops out at `+127`. The CPU reports the sum as `A6H = −90`, and **N = 1** is wrong — the **V = 1** flag is what tells us the result is invalid.

---

## When Is the V Flag Set?

For 8-bit signed addition, **V = 1** if either:

1. There is a carry from D6 into D7, but **no** carry out of D7 (C = 0); or
2. There **is** a carry out of D7 (C = 1), but no carry from D6 into D7.

In other words: V = 1 if a carry occurs into D7 **or** out of D7, but **not both**.

$$V = Rd7 \cdot Rr7 \cdot \overline{R7} \;+\; \overline{Rd7} \cdot \overline{Rr7} \cdot R7$$

* Overflow on `ADD` can **only** happen when adding two operands **with the same sign** — adding operands of different signs can never overflow, since the result's magnitude must be smaller than at least one operand.
* The same idea extends to `SUB`, since `a − b = a + (−b)`.

---

## V Flag: More Examples

**Example 5-14:** `(−128) + (−2)` → `1000 0000 + 1111 1110 = 0111 1110` → CPU reports `+126` (wrong!). N = 0, **V = 1** (carry out of D7 with no carry from D6 to D7).

**Example 5-15:** `(−2) + (−5) = −7` → `1111 1110 + 1111 1011 = 1111 1001`. N = 1, **V = 0** — correct.

**Example 5-16:** `(+7) + (+18) = +25` → `0000 0111 + 0001 0010 = 0001 1001`. N = 0, **V = 0** — correct.

**Rule of thumb:** in **unsigned** addition, watch the **C** flag; in **signed** addition, watch the **V** flag. `BRCS`/`BRCC` react to C; `BRVS`/`BRVC` react to V.

---

## N vs. S: Which Flag Shows the *Real* Sign?

* **N** is simply bit D7 of the result — if overflow occurred, N shows the sign of the **corrupted** result, not the true answer.
* **S** corrects for this: `S = N ⊕ V`. If V = 0 (no overflow), S = N. If V = 1 (overflow), S is the **opposite** of N — i.e. the true sign.

| Example | Real sign | N | V | S = N⊕V | S matches N? |
|---|---|---|---|---|---|
| 5-13: (+96)+(+70) | positive (S=0) | 1 | 1 | 0 | No (overflow) |
| 5-14: (−128)+(−2) | negative (S=1) | 0 | 1 | 1 | No (overflow) |
| 5-15: (−2)+(−5) | negative (S=1) | 1 | 0 | 1 | Yes |
| 5-16: (+7)+(+18) | positive (S=0) | 0 | 0 | 0 | Yes |

The AVR has a dedicated **`NEG`** instruction to form the 2's complement of a register directly (covered in Section 5.3).

---

## Lecture Outline

<div class="text-sm">

1.  Arithmetic Instructions
2.  Signed Numbers and Overflow
3.  **Logic and Compare Instructions**
4.  Rotate, Shift Instructions and Data Serialization
5.  BCD and ASCII Conversion

</div>

---
layout: two-cols-header
---

## SECTION 5.3: `AND` / `ANDI`

::left::

```asm
AND   Rd, Rr    ;Rd = Rd AND Rr
ANDI  Rd, K     ;Rd = Rd AND K
```

* Performs a bitwise AND; result goes in `Rd`.
* `ANDI` allows an immediate (constant) right operand.
* Affects **Z, S, N** (N = D7 of result, Z = 1 if result is zero).
* Commonly used to **mask** (clear) specific bits.

::right::

**Logical AND**

| X | Y | X AND Y |
|---|---|---|
| 0 | 0 | 0 |
| 0 | 1 | 0 |
| 1 | 0 | 0 |
| 1 | 1 | 1 |

**Example 5-18**

```asm
LDI   R20, 0x35   ;R20 = 35H
ANDI  R20, 0x0F   ;mask upper nibble

  0011 0101
& 0000 1111
-----------
  0000 0101   = 05H
```

---
layout: two-cols-header
---

## `OR` / `ORI`

::left::

```asm
OR   Rd, Rr    ;Rd = Rd OR Rr
ORI  Rd, K     ;Rd = Rd OR K
```

* Bitwise OR; affects **Z, S, N**.
* Used to **set** specific bits to 1.

**Example 5-19(a):** `R20=04H`; `ORI R20, 0x30` → `R20 = 34H`

::right::

**Example 5-19(b):** turn **on** an outdoor light on PB2, turn **off** an inside light on PB5 (both outputs of Port B):

```asm {*|4-9|10-11|*}{lines:true}
SBI  DDRB, 2
SBI  DDRB, 5
IN   R20, PORTB          ;read back last output latch
ORI  R20, 0b00000100     ;set bit 2 (turn light ON)
ANDI R20, 0b11011111     ;clear bit 5 (turn light OFF)
OUT  PORTB, R20
```

Reading back **PORTB** (not `PINB`) preserves the other output bits we aren't changing.

---
layout: two-cols-header
---

## `EOR` (Exclusive-OR)

::left::

```asm
EOR  Rd, Rs    ;Rd = Rd XOR Rs
```

Affects **Z, S, N**. No immediate form exists.

**Example 5-20:** `54H XOR 78H`

```
  0101 0100
^ 0111 1000
-----------
  0010 1100  = 2CH
```

::right::

**Logical XOR**

| A | B | A XOR B |
|---|---|---|
| 0 | 0 | 0 |
| 0 | 1 | 1 |
| 1 | 0 | 1 |
| 1 | 1 | 0 |

**Two handy tricks:**
* **Equality test:** `EOR Rd, Rr` gives `0` (Z=1) exactly when `Rd == Rr`.
* **Toggle bits:** `EOR Rd, 0xFF` flips every bit of `Rd`.

---

## `EOR` for Testing Equality

**Example 5-21/5-22:** Poll `PORTB` until it equals `0x45`, then output `0x99` to `PORTC` (else clear it):

```asm {*|1-2|7-9|*}{lines:true}
LDI    R21, 0x45
HERE:
  IN    R20, PINB
  EOR   R20, R21        ;R20 = 0 (Z=1) only if PINB was 0x45
  BRNE  HERE             ;loop while not equal

  LDI   R20, 0x99
  OUT   PORTC, R20
```

`EOR`-with-itself always yields zero with Z = 1 — a classic way to clear a register and set Z simultaneously.

---
layout: two-cols
---

## `COM` and `NEG`

**`COM` — 1's complement**

```asm
COM  Rd    ;Rd = NOT Rd  (11111111 - Rd)
```

Flips every bit. Affects Z, N, S; **C is always set to 1**; V is always cleared.

```asm
LDI  R20, 0xAA   ;R20 = AA
COM  R20         ;R20 = 55H
```

::right::

**`NEG` — 2's complement**

```asm
NEG  Rd    ;Rd = 2's complement of Rd (00000000 - Rd)
```

**Example 5-23:** find the 2's complement of `85H` (= −123 decimal)

```
85H  = 1000 0101
1's  = 0111 1010
       +       1
     = 0111 1011 = 7BH
```

`NEG` affects H, S, V, N, Z, C — exactly like a `SUB` from zero.

---

## Compare Instruction: `CP` / `CPI`

```asm
CP   Rd, Rr    ;Rd - Rr  (only flags are set, operands unchanged)
CPI  Rd, K     ;Rd - K   (only flags are set)
```

`CP` is really a subtraction whose result is thrown away — only the flags matter. It's paired with conditional branches:

**Table 5-2: AVR Conditional Branch Instructions**

$$
\begin{array}{|l|l|l|}
\hline
\textbf{Mnemonic} & \textbf{Meaning} & \textbf{Condition} \\
\hline
\texttt{BREQ} & \text{Branch if equal} & Z = 1 \\
\hline
\texttt{BRNE} & \text{Branch if not equal} & Z = 0 \\
\hline
\texttt{BRSH} & \text{Branch if same or higher (unsigned)} & C = 0 \\
\hline
\texttt{BRLO} & \text{Branch if lower (unsigned)} & C = 1 \\
\hline
\texttt{BRLT} & \text{Branch if less than (signed)} & S = 1 \\
\hline
\texttt{BRGE} & \text{Branch if greater or equal (signed)} & S = 0 \\
\hline
\texttt{BRVS} & \text{Branch if overflow set} & V = 1 \\
\hline
\texttt{BRVC} & \text{Branch if overflow clear} & V = 0 \\
\hline
\end{array}
$$

`BRSH`/`BRLO` compare **unsigned** numbers; `BRGE`/`BRLT` compare **signed** numbers.

---

## Example 5-25: Find the Greater of Two Values

```asm {*|3-4|5|6-7|*}{lines:true}
.EQU  VAL_1 = 27
.EQU  VAL_2 = 54

LDI   R20, VAL_1
LDI   R21, VAL_2
CP    R21, R20     ;compare R21 and R20
BRLO  NEXT          ;if R21 < R20 (unsigned), keep R20
LDI   R20, VAL_2    ;else R20 = VAL_2
NEXT:
```

`BREQ`/`BRNE` work for **both** signed and unsigned numbers, since equality doesn't depend on sign interpretation. Use `BRSH`/`BRLO` only for unsigned, and `BRGE`/`BRLT` only for signed comparisons.

---

## Example 5-27: Overflow-Checked Signed Addition

Add two signed numbers in R21 and R22; if the addition overflows, flag it by writing `0xAA` to PORTA and clearing R21:

```asm {*|5|6-9|*}{lines:true}
LDI   R21, 0xFA     ;R21 = -6
LDI   R22, 0x05     ;R22 = +5
LDI   R23, 0xFF
OUT   DDRA, R23     ;Port A is output
ADD   R21, R22      ;R21 = R21 + R22
BRVC  NEXT           ;if V = 0 (no error), skip ahead
LDI   R23, 0xAA
OUT   PORTA, R23     ;signal the overflow error
LDI   R21, 0x00      ;clear R21
NEXT: ...
```

This is the standard idiom for **detecting signed overflow** immediately after an arithmetic instruction.

---

## Lecture Outline

<div class="text-sm">

1.  Arithmetic Instructions
2.  Signed Numbers and Overflow
3.  Logic and Compare Instructions
4.  **Rotate, Shift Instructions and Data Serialization**
5.  BCD and ASCII Conversion

</div>

---
layout: image-right
backgroundSize: contain
image: /ch5_rotate_ror_rol.png
---

## SECTION 5.4: Rotate Through Carry

```asm
ROR  Rd    ;rotate Rd right through carry
ROL  Rd    ;rotate Rd left through carry
```

* Both instructions treat **C** as if it were a 9th bit of the register.
* **ROR:** C moves into the MSB; the old LSB moves into C.
* **ROL:** C moves into the LSB; the old MSB moves into C.

**ROR example:**
```asm
CLC              ;C = 0
LDI  R20, 0x26   ;R20 = 0010 0110
ROR  R20         ;R20 = 0001 0011, C = 0
ROR  R20         ;R20 = 0000 1001, C = 1
ROR  R20         ;R20 = 1000 0100, C = 1
```

---

## Serializing Data: Sending a Byte Out

Serializing sends a byte one bit at a time through a single pin — used by SPI-style devices such as serial LCDs, ADCs, and EEPROMs.

**Example 5-28:** Send `41H` out pin PB1, LSB first, with a high start/stop bit:

```asm {*|6-9|11-16|*}{lines:true}
SBI   DDRB, 1
LDI   R20, 0x41
CLC
LDI   R16, 8
SBI   PORTB, 1        ;start bit = 1

AGAIN:
  ROR  R20             ;send LSB of R20 into C
  BRCS ONE
  CBI  PORTB, 1
  JMP  NEXT
  ONE: SBI PORTB, 1
NEXT:
  DEC  R16
  BRNE AGAIN
  SBI  PORTB, 1        ;stop bit = 1
```

---

## Serializing Data: Reading a Byte In

**Example 5-29:** Read a byte serially from pin RC7 (LSB first) into R20:

```asm {*|5-9|*}{lines:true}
CBI   DDRC, 7
LDI   R16, 8
LDI   R20, 0
AGAIN:
  SBIC PINC, 7    ;skip next line if bit 7 of Port C is 0
  SEC
  SBIS PINC, 7    ;skip next line if bit 7 of Port C is 1
  CLC
  ROR  R20        ;shift the received bit into R20's MSB
  DEC  R16
  BRNE AGAIN
```

**Example 5-30 (counting set bits):** `ROR` each bit into C, then `BRCC`/`INC` a counter — a classic use of rotate to inspect one bit at a time without disturbing the others.

---
layout: image-left
backgroundSize: contain
image: /ch5_shift_lsl_lsr_asr.png
---

## Shift Instructions

```asm
LSL  Rd   ;logical shift left  (x2, if C unset before)
LSR  Rd   ;logical shift right (unsigned /2, remainder in C)
ASR  Rd   ;arithmetic shift right (signed /2, sign preserved)
```

* **LSL:** 0 enters the LSB; the old MSB exits to C. Multiplies by 2 (if C was clear beforehand).
* **LSR:** 0 enters the MSB; the old LSB exits to C, which holds the remainder.
* **ASR:** the sign bit (D7) is **held constant** and re-copied in; the old LSB exits to C.

```asm
LDI  R20, 0x26   ;38
LSL  R20         ;76,  C=0
LSR  R20         ;19,  C=0  (0x26 again)
```

---

## `LSR` vs. `ASR` for Signed Numbers

**Example 5-31:** `R20 = 0xFA` (−6). `LSR R20` gives `0111 1101` = **+125** — **wrong!** `LSR` shifts a 0 into the sign bit, corrupting negative numbers.

**Example 5-32:** dividing an unsigned `48` by **8** using `ROR` three times (clearing C before each rotate, since there's no `LSR`-by-N instruction):

```asm {*|2-3|4-5|6-7|*}{lines:true}
LDI  R20, 0x30   ;48
CLC
ROR  R20         ;24
CLC
ROR  R20         ;12
CLC
ROR  R20         ;6   (48 / 8 = 6, correct)
```

**Rule:** use `LSR` only for **unsigned** division by 2; use `ASR` for **signed** division by 2.

---
layout: image-right
backgroundSize: contain
image: /ch5_swap_nibble.png
---

## `SWAP` Instruction

```asm
SWAP  Rd   ;swap nibbles of Rd
```

* Works on any register R0–R31.
* Exchanges the **upper nibble** (D7–D4) with the **lower nibble** (D3–D0).
* Does **not** affect any flags.

**Example 5-33(a):**

```asm
LDI   R20, 0x72
SWAP  R20        ;R20 = 0x27
```

Without a `SWAP` instruction, the same result takes four `ROL`s on the byte plus a second register to catch the bits shifted out through carry — `SWAP` does it in one cycle.

---

## Lecture Outline

<div class="text-sm">

1.  Arithmetic Instructions
2.  Signed Numbers and Overflow
3.  Logic and Compare Instructions
4.  Rotate, Shift Instructions and Data Serialization
5.  **BCD and ASCII Conversion**

</div>

---
layout: two-cols-header
---

## SECTION 5.5: BCD Number System

::left::

* **BCD** (binary coded decimal) represents each decimal digit 0–9 in 4 bits.
* **Unpacked BCD:** lower nibble = the digit, upper nibble = 0000. Needs 1 whole byte per digit.
  * e.g. `0000 1001` = unpacked BCD for 9.
* **Packed BCD:** two digits share one byte — one in each nibble. Twice as memory-efficient.
  * e.g. `0101 1001` = packed BCD for 59.

::right::

**Figure 5-3: BCD Code**

<div style="font-size:0.8em">

$$
\begin{array}{|c|c|}
\hline
\textbf{Digit} & \textbf{BCD} \\
\hline
0 & 0000 \\
\hline
1 & 0001 \\
\hline
2 & 0010 \\
\hline
3 & 0011 \\
\hline
4 & 0100 \\
\hline
5 & 0101 \\
\hline
6 & 0110 \\
\hline
7 & 0111 \\
\hline
8 & 1000 \\
\hline
9 & 1001 \\
\hline
\end{array}
$$

</div>

---

## ASCII and BCD Codes for Digits 0–9

On an ASCII keyboard, pressing "0" sends `30H`; "1" sends `31H`; and so on — ASCII digits are just unpacked BCD **tagged** with the upper nibble `0011`.

**Table 5-3**

$$
\begin{array}{|c|c|c|c|}
\hline
\textbf{Key} & \textbf{ASCII (hex)} & \textbf{Binary} & \textbf{BCD (unpacked)} \\
\hline
0 & 30 & 011\ 0000 & 0000\ 0000 \\
\hline
1 & 31 & 011\ 0001 & 0000\ 0001 \\
\hline
2 & 32 & 011\ 0010 & 0000\ 0010 \\
\hline
\ldots & \ldots & \ldots & \ldots \\
\hline
8 & 38 & 011\ 1000 & 0000\ 1000 \\
\hline
9 & 39 & 011\ 1001 & 0000\ 1001 \\
\hline
\end{array}
$$

BCD itself is universal across systems; **ASCII** is the standard used by keyboards, printers, and monitors — so conversion between the two is a routine embedded-systems task.

---

## Packed BCD to ASCII Conversion

To display packed BCD (e.g. from a real-time clock chip) on an LCD or printer, convert it to **unpacked BCD** first, then **OR each nibble with `0011 0000` (30H)**.

```
Packed BCD        Unpacked BCD          ASCII
   29H       ->    02H  &  09H    ->    32H  &  39H
0010 1001        0000 0010 &         0011 0010 &
                  0000 1001           0011 1001
```

**Example 5-34:** convert packed BCD in R20 to two ASCII digits in R21/R22:

```asm {*|1-3|5-8|*}{lines:true}
LDI   R20, 0x29
MOV   R21, R20
ANDI  R21, 0x0F    ;mask upper nibble -> 09H
ORI   R21, 0x30    ;tag as ASCII -> 39H

MOV   R22, R20
SWAP  R22           ;92H
ANDI  R22, 0x0F    ;mask upper nibble -> 02H
ORI   R22, 0x30    ;tag as ASCII -> 32H
```

---

## ASCII to Packed BCD Conversion

To go the other way — e.g. converting keyboard input back to packed BCD — mask off the ASCII tag from each digit, then combine the two nibbles.

For keys "4" and "7" (ASCII `34H`, `37H`), the goal is `47H` (packed BCD):

```asm {*|1-4|5-7|*}{lines:true}
LDI   R21, '4'
LDI   R22, '7'
ANDI  R21, 0x0F     ;strip ASCII tag -> 04H
SWAP  R21            ;move into upper nibble -> 40H
ANDI  R22, 0x0F     ;strip ASCII tag -> 07H
OR    R22, R21      ;combine nibbles -> 47H
MOV   R20, R22       ;R20 = 47H (packed BCD)
```

After this conversion, arithmetic on the digits can be done directly in packed BCD form.

---

## Summary

* **Arithmetic:** `ADD`/`ADC` and `SUB`/`SBC`/`SUBI`/`SBCI`/`SBIW` handle 8-bit and multi-byte unsigned arithmetic; the AVR has no hardware divide, so division is done by repeated subtraction.
* **Signed numbers:** use 2's complement; the **V** flag (not C) signals an invalid signed result, and **S = N⊕V** always reports the true sign even after overflow.
* **Logic instructions** (`AND`, `OR`, `EOR`, `COM`, `NEG`) mask, set, toggle, and complement bits, and pair with `CP`/`CPI` and conditional branches (`BREQ`, `BRSH`, `BRLO`, `BRGE`, `BRLT`, `BRVS`, `BRVC`) for decision-making.
* **Rotate/shift** (`ROL`, `ROR`, `LSL`, `LSR`, `ASR`, `SWAP`) move bits through the carry flag, enabling serialization, fast multiply/divide by powers of two, and nibble swapping.
* **BCD/ASCII conversion** bridges human-readable decimal digits (keyboards, displays) and the packed BCD used by real-time clocks and other peripherals.
