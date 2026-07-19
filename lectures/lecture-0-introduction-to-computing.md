---
theme: seriph
background: https://cover.sli.dev
transition: slide-left
layout: cover
title: Lecture 0 - Introduction to Computing
---

# Lecture 0: Introduction to Computing
## {{ $slidev.configs.subject }}
### Semester {{ $slidev.configs.semester }}
#### Presented by {{ $slidev.configs.presenter }}

---

## Lecture Outline

<div class="text-sm">

1.  **Numbering and Coding Systems**
2.  Digital Primer (Logic Gates)
3.  Semiconductor Memory
4.  CPU Architecture: Harvard vs. von Neumann

</div>

---
layout: two-cols-header
---

## Chapter Objectives

::left::

Upon completion of this chapter, you will be able to:

* Convert any number between base 2, base 10, and base 16
* Describe AND, OR, NOT, XOR, NAND, and NOR
* Use logic gates to diagram simple circuits
* Explain the difference between a bit, nibble, byte, and word
* Define *kilobyte*, *megabyte*, *gigabyte*, and *terabyte*
* Describe the purpose of the major components of a computer system

::right::

* Contrast SRAM, NV-RAM, DRAM, PROM, EPROM, EEPROM, Flash, and mask ROM
* Describe the relationship between address pins, data pins, and chip capacity
* List the steps a CPU follows in memory address decoding
* List the three types of buses and the purpose of each
* Describe the role of the CPU and its major components
* Understand Harvard vs. von Neumann architecture

---

## Lecture Outline

<div class="text-sm">

1.  **Numbering and Coding Systems**
2.  Digital Primer (Logic Gates)
3.  Semiconductor Memory
4.  CPU Architecture: Harvard vs. von Neumann

</div>

---

## Decimal and Binary Number Systems

* Human beings use base 10 (**decimal**) arithmetic -- likely because we have 10 fingers.
* Computers use base 2 (**binary**) arithmetic, because the two digits 0 and 1 map naturally onto the two voltage levels *on* and *off*.
* Base 10 has 10 distinct symbols: `0`-`9`. Base 2 has only 2: `0` and `1`.
* Each binary digit (0 or 1) is called a **bit**.

---
layout: two-cols
---

## Converting Decimal to Binary

* Divide the decimal number by 2 repeatedly, keeping track of the remainders, until the quotient becomes 0.
* The remainders, read in **reverse order**, form the binary number.

**Example 0-1:** Convert 25<sub>10</sub> to binary.

::right::

| Division | Quotient | Remainder |     |
| -------- | -------- | --------- | --- |
| 25 / 2   | 12       | 1         | LSB |
| 12 / 2   | 6        | 0         |     |
| 6 / 2    | 3        | 0         |     |
| 3 / 2    | 1        | 1         |     |
| 1 / 2    | 0        | 1         | MSB |

**Therefore, 25<sub>10</sub> = 11001<sub>2</sub>.**

---
layout: two-cols
---

## Converting Binary to Decimal

* Each bit position in a binary number has a **weight**: 1, 2, 4, 8, 16, 32, ... (powers of 2).
* Multiply each bit by its weight and sum the results.

**Example 0-2:** Convert 11001<sub>2</sub> to decimal.

::right::

| Weight | 16  | 8   | 4   | 2   | 1   |
| ------ | --- | --- | --- | --- | --- |
| Digit  | 1   | 1   | 0   | 0   | 1   |

Sum: 16 + 8 + 0 + 0 + 1 = **25<sub>10</sub>**

<div class="mt-8"/>

**Example 0-3:** Convert 39<sub>10</sub> to binary directly using weights.

| Weight | 32  | 16  | 8   | 4   | 2   | 1   |
| ------ | --- | --- | --- | --- | --- | --- |
| Digit  | 1   | 0   | 0   | 1   | 1   | 1   |

32 + 4 + 2 + 1 = 39, so 39<sub>10</sub> = **100111<sub>2</sub>**

---

## The Hexadecimal System

* Base 16 (**hex**) is a compact, human-friendly way to represent binary strings.
* It is much easier for a person to read `896H` than `100010010110`.
* Hex uses 16 digits: `0`-`9` are the same as decimal; `A`-`F` represent 10-15.

**Table 0-1: Base 16 Number System**

| Decimal | Binary | Hex | &nbsp; | Decimal | Binary | Hex |
| :-----: | :----: | :-: | ------ | :-----: | :----: | :-: |
| 0 | 0000 | 0 | | 8  | 1000 | 8 |
| 1 | 0001 | 1 | | 9  | 1001 | 9 |
| 2 | 0010 | 2 | | 10 | 1010 | A |
| 3 | 0011 | 3 | | 11 | 1011 | B |
| 4 | 0100 | 4 | | 12 | 1100 | C |
| 5 | 0101 | 5 | | 13 | 1101 | D |
| 6 | 0110 | 6 | | 14 | 1110 | E |
| 7 | 0111 | 7 | | 15 | 1111 | F |

---
layout: two-cols
---

## Converting Between Binary and Hex

* **Binary → Hex:** group bits into 4s starting from the right; replace each group with its hex digit.
* **Hex → Binary:** replace each hex digit with its 4-bit binary equivalent.

**Example 0-4:** Represent binary `100111110101` in hex.

```text
1001 1111 0101
 9    F    5
```
100111110101<sub>2</sub> = **9F5** hex

::right::

**Example 0-5:** Convert hex `29B` to binary.

```text
 2     9     B
0010  1001  1011
```

Dropping leading zeros: 29B<sub>16</sub> = **1010011011<sub>2</sub>**

---

## Converting Decimal to Hex (Example 0-6)

Convert via binary first, grouping into 4-bit nibbles.

**(a)** 45<sub>10</sub>: weights 32+8+4+1 = 45 → `0010 1101` → **2D** hex

**(b)** 629<sub>10</sub>: weights 512+64+32+16+4+1 = 629 → `0010 0111 0101` → **275** hex

**(c)** 1714<sub>10</sub>: weights 1024+512+128+32+16+2 = 1714 → `0110 1011 0010` → **6B2** hex

---

## Converting Hex to Decimal (Example 0-7)

Convert to binary, then sum the weight of each `1` bit.

**(a)** 6B2<sub>16</sub> = `0110 1011 0010`<sub>2</sub>

1024 + 512 + 128 + 32 + 16 + 2 = **1714<sub>10</sub>**

**(b)** 9F2D<sub>16</sub> = `1001 1111 0010 1101`<sub>2</sub>

32768 + 4096 + 2048 + 1024 + 512 + 256 + 32 + 8 + 4 + 1 = **40,749<sub>10</sub>**

---
layout: two-cols
---

## Binary Addition

* Adding binary numbers is straightforward -- there's no separate subtractor circuitry; computers use adders plus **2's complement** to implement subtraction.

**Table 0-3: Binary Addition**

| A + B | Carry | Sum |
| :---: | :---: | :-: |
| 0 + 0 | 0     | 0   |
| 0 + 1 | 0     | 1   |
| 1 + 0 | 0     | 1   |
| 1 + 1 | 1     | 0   |

::right::

**Example 0-8:** Add 1101<sub>2</sub> + 1001<sub>2</sub>.

```text
  Binary    Decimal
  1101      13
+ 1001      + 9
-----       ----
 10110       22
```

Checks out against the decimal equivalents (13 + 9 = 22).

---

## 2's Complement

* To get the 2's complement of a binary number: **invert all bits** (the *1's complement*), then **add 1**.

**Example 0-9:** Take the 2's complement of `10011101`.

```text
10011101   binary number
01100010   1's complement (invert all bits)
+      1
--------
01100011   2's complement
```

---
layout: two-cols
---

## Addition of Hex Numbers

* Add digit by digit from the right. If a sum ≥ 16, subtract 16 and carry 1.

**Example 0-10:** 23D9 + 94BE

```text
  23D9
+ 94BE
------
  B897
```
* LSD: 9 + 14(E) = 23 → 23-16=7, carry 1
* 1 + 13(D) + 11(B) = 25 → 25-16=9, carry 1
* 1 + 3 + 4 = 8
* MSD: 2 + 9 = B

::right::

## Subtraction of Hex Numbers

* If the second digit is greater than the first, **borrow 16** from the preceding digit.

**Example 0-11:** 59F − 2B8

```text
  59F
- 2B8
------
  2E7
```
* LSD: 8 from 15(F) = 7
* 11(B) from 25 (9+16) = 14 (E)
* 2 from 4 (5-1 borrow) = 2

---

## ASCII Code

* All information in a computer must be represented as 0s and 1s, so binary patterns must be assigned to letters and characters.
* **ASCII** (American Standard Code for Information Interchange), established in the 1960s, uses **7 bits** per character (often padded to 8 bits with a leading 0).
* Digits `0`-`9` map to codes `30`-`39` hex, letting software mask off the "3" to convert ASCII to decimal.
* Uppercase letters use codes `41`-`5A` hex; lowercase use `61`-`7A` hex -- they differ by exactly **bit 5**, so upper/lowercase conversion is just a single-bit flip.

**Figure 0-1: Selected ASCII Codes**

| Hex | Symbol | &nbsp; | Hex | Symbol |
| :-: | :----: | ------ | :-: | :----: |
| 41 | A | | 61 | a |
| 42 | B | | 62 | b |
| 43 | C | | 63 | c |
| 44 | D | | 64 | d |
| ... | ... | | ... | ... |
| 59 | Y | | 79 | y |
| 5A | Z | | 7A | z |

---

## Lecture Outline

<div class="text-sm">

1.  Numbering and Coding Systems
2.  **Digital Primer (Logic Gates)**
3.  Semiconductor Memory
4.  CPU Architecture: Harvard vs. von Neumann

</div>

---

## Binary Logic

* Digital signals have two distinct voltage levels. A common convention: **0 V = logic 0**, **+5 V = logic 1**.
* Real systems allow tolerance bands around each level -- a valid signal must fall within one of the two defined ranges, not in between.
* **Logic gates** are simple circuits that take one or more input signals and produce one output signal.

---
layout: two-cols
---

## AND Gate

* Output is 1 **only if all inputs are 1**; otherwise 0.

**Logical AND Function**

| X | Y | X AND Y |
| :-: | :-: | :-----: |
| 0 | 0 | 0 |
| 0 | 1 | 0 |
| 1 | 0 | 0 |
| 1 | 1 | 1 |

* Symbol: two inputs (X, Y) feed a D-shaped AND gate, producing output `X AND Y`.

::right::

## OR Gate

* Output is 1 **if one or more inputs is 1**; output is 0 only if all inputs are 0.

**Logical OR Function**

| X | Y | X OR Y |
| :-: | :-: | :----: |
| 0 | 0 | 0 |
| 0 | 1 | 1 |
| 1 | 0 | 1 |
| 1 | 1 | 1 |

* Symbol: two inputs (X, Y) feed a curved-back OR gate, producing output `X OR Y`.

---
layout: two-cols
---

## Inverter (NOT)

* Also called **NOT**. Outputs the opposite of the input: 1 in → 0 out, 0 in → 1 out.

**Logical Inverter**

| X | NOT X |
| :-: | :---: |
| 0 | 1 |
| 1 | 0 |

::right::

## XOR Gate

* **Exclusive-OR**: output is 1 if the inputs *differ*; output is 0 if the inputs are the *same*.
* Useful for comparing two bits to see if they match.

**Logical XOR Function**

| X | Y | X XOR Y |
| :-: | :-: | :-----: |
| 0 | 0 | 0 |
| 0 | 1 | 1 |
| 1 | 0 | 1 |
| 1 | 1 | 0 |

---
layout: two-cols
---

## NAND Gate

* Behaves like an AND gate followed by an inverter.
* Output is 0 only when **all** inputs are 1; otherwise 1.

**Logical NAND Function**

| X | Y | X NAND Y |
| :-: | :-: | :------: |
| 0 | 0 | 1 |
| 0 | 1 | 1 |
| 1 | 0 | 1 |
| 1 | 1 | 0 |

::right::

## NOR Gate

* Behaves like an OR gate followed by an inverter.
* Output is 1 only when **all** inputs are 0; otherwise 0.

**Logical NOR Function**

| X | Y | X NOR Y |
| :-: | :-: | :-----: |
| 0 | 0 | 1 |
| 0 | 1 | 0 |
| 1 | 0 | 0 |
| 1 | 1 | 0 |

* NAND and NOR are used extensively in digital design because they are cheap and easy to fabricate -- **any** circuit built from AND/OR/XOR/inverter gates can be rebuilt from NAND and NOR gates alone.

---
layout: image-right
backgroundSize: contain
image: /ch0_half_adder_gates.png
---

## Logic Design: The Half-Adder

* Adding two bits has four possible outcomes: `0+0=00`, `0+1=01`, `1+0=01`, `1+1=10` (Sum, Carry).
* The **Sum** column matches the output of an XOR gate.
* The **Carry** column matches the output of an AND gate.
* Figure 0-3 shows two equivalent implementations of a half-adder:
    * (a) directly with an XOR gate and an AND gate
    * (b) using only AND, OR, and inverter gates

---

## From Half-Adder to Full-Adder

* A **half-adder** takes two input bits (X, Y) and produces a Sum and a Carry-out.
* A **full-adder** adds *three* bits (X, Y, and a Carry-in), which is what's needed to add multi-bit numbers column by column.
* Two half-adders plus an OR gate combine to build one full-adder: the first half-adder adds X and Y; the second adds that result to Carry-in; the OR gate combines the two carry outputs into the Final Carry.
* Chaining three full-adders together builds a 3-bit adder -- and this pattern extends to build adders of any width.

---
layout: two-cols
---

## Decoders

* A **decoder** is another common application of logic gates, widely used for **address decoding** in computer design.
* Using inverters and an AND gate, a decoder's output goes to 1 **only when** its inputs match one specific binary pattern.
* Example: a decoder for binary `1001` (9) uses inverters on the two 0-bits so the AND gate only outputs 1 when the input is exactly 1001.

::right::

## Flip-Flops

* A **flip-flop** is a widely used component for storing (latching) a single bit of data.
* The **D flip-flop (D-FF)** is the most common: it grabs the value at its D input the moment the clock is activated, and holds that value as long as power remains on.

**D-FF Truth Table**

| Clk | D | Q |
| :-: | :-: | :--------: |
| No edge | x | no change |
| ↑ | 0 | 0 |
| ↑ | 1 | 1 |

`x = don't care`

---

## Lecture Outline

<div class="text-sm">

1.  Numbering and Coding Systems
2.  Digital Primer (Logic Gates)
3.  **Semiconductor Memory**
4.  CPU Architecture: Harvard vs. von Neumann

</div>

---

## Key Terminology

* **Bit**: a single binary digit, 0 or 1.
* **Nibble**: half a byte, or **4 bits**.
* **Byte**: **8 bits**.
* **Word**: two bytes, or **16 bits**.

| Unit | Size |
| ----- | ---------------------------------------- |
| Bit | 0 |
| Nibble | 0000 |
| Byte | 0000 0000 |
| Word | 0000 0000 0000 0000 |

* **Kilobyte (K)** = 2<sup>10</sup> bytes = 1,024 bytes
* **Megabyte** = 2<sup>20</sup> bytes = 1,048,576 bytes (a little over 1 million)
* **Gigabyte** = 2<sup>30</sup> bytes (over 1 billion)
* **Terabyte** = 2<sup>40</sup> bytes (over 1 trillion)

*Example: 16 megabytes = 16 × 2<sup>20</sup> = 2<sup>4</sup> × 2<sup>20</sup> = **2<sup>24</sup> bytes**.*

---

## RAM vs. ROM

* **RAM** ("random access memory," also called *read/write memory*) holds programs the computer is currently running.
    * Its contents are **lost** when power is turned off → **volatile** memory.
* **ROM** ("read-only memory") holds information essential to the computer's operation.
    * Its contents are **permanent**, cannot be changed by the user, and survive power-off → **nonvolatile** memory.
* RAM and ROM are together called **primary memory**; disks are **secondary memory**. The CPU always looks to primary memory first, since disks are far too slow to access directly.

---
layout: image-right
backgroundSize: contain
image: /ch0_internal_organization.png
---

## Internal Organization of a Computer

* Every computer's internals break down into three parts: **CPU**, **memory**, and **I/O** devices.
* The CPU connects to memory and I/O through strips of wire called a **bus** -- like a street that carries information from place to place.
* Every device (memory or I/O) must be assigned a **unique address**.
* The CPU places an address on the address bus; decoding circuitry finds the matching device; the data bus then carries data to/from it.

---

## The Three Buses

* **Address bus:** carries the address of the memory/IO location the CPU wants. **Unidirectional** -- the CPU only ever *sends* addresses.
* **Data bus:** carries the actual information back and forth. **Bidirectional**, since the CPU both sends and receives data. Typical widths: 8 to 64 bits (Apple II used 8-bit; Cray supercomputers used 64-bit). A wider data bus is faster (a 16-bit bus moves 2 bytes at once -- twice as fast as an 8-bit bus) but more expensive.
* **Control bus:** carries read/write signals (e.g., `MEMR`, `MEMW`, `IORD`, `IOWR`) telling a device whether the CPU is asking for or sending information.

<div class="text-sm mt-4">

The number of address lines determines the number of addressable locations: **2<sup>x</sup>**, where *x* is the number of address lines -- regardless of data bus width. A 16-line address bus addresses 65,536 (64K) locations; the IBM PC AT's 24 address lines address 2<sup>24</sup> = 16 megabytes.

</div>

---
layout: two-cols
---

## Memory Capacity & Organization

* **Capacity**: total bits a chip can store (chip capacity is always given in **bits**; system memory is always given in **bytes**).
* **Organization**: a memory chip contains **2<sup>x</sup> locations**, where *x* = number of address pins.
* Each location holds **y bits**, where *y* = number of data pins.
* Total chip capacity = **2<sup>x</sup> × y** bits.

::right::

**Table 0-4: Powers of 2 (excerpt)**

| x | 2<sup>x</sup> |
| :-: | :----: |
| 10 | 1K |
| 12 | 4K |
| 14 | 16K |
| 16 | 64K |
| 18 | 256K |
| 20 | 1M |
| 24 | 16M |
| 27 | 128M |

---
layout: two-cols
---

## Worked Example: Memory Organization

**Example 0-12:** A memory chip has 12 address pins and 4 data pins. Find (a) the organization, (b) the capacity.

* (a) 2<sup>12</sup> = 4,096 locations, each holding 4 bits → organization **4K × 4**.
* (b) Capacity = 4,096 × 4 = **16K bits**.

::right::

**Example 0-13:** A 512K memory chip has 8 data pins. Find (a) the organization, (b) the number of address pins.

* (a) 512K / 8 = 64K locations → organization **64K × 8**.
* (b) 2<sup>16</sup> = 64K, so the chip has **16 address pins**.

---

## ROM: PROM (Programmable ROM)

* **ROM** does not lose its contents when powered off → **nonvolatile**.
* Types of ROM: **PROM**, **EPROM**, **EEPROM**, **Flash EPROM**, and **mask ROM**.
* **PROM** is user-programmable: every bit has a fuse, and programming ("burning") means blowing fuses with a **ROM burner**.
* Because fuses are blown permanently, a PROM programmed with wrong data must be **discarded** -- hence PROM is also called **OTP** (one-time programmable).

---

## EPROM and UV-EPROM

* **EPROM** allows the contents of a PROM to be changed *after* burning -- it can be programmed and erased thousands of times.
* The most widely used EPROM is **UV-EPROM**, erased by shining **ultraviolet (UV) light** through a window on the chip package.
* Erasing a UV-EPROM can take up to **20 minutes**, and it erases the **entire chip's** contents.

**Steps to program a UV-EPROM:**
1. **Erase**: remove the chip from its socket, place it in EPROM erasure equipment for 15-20 minutes of UV exposure.
2. **Program**: place the chip in a ROM burner, which uses **12.5 V or higher (V<sub>PP</sub>)** to burn the code.
3. Place the chip back into its socket on the system board.

* Main disadvantage: it **cannot** be erased/programmed while still in the system board.

---

## UV-EPROM Part Numbers (Table 0-5, excerpt)

* Part numbers encode capacity and access time, e.g., **27128-25** = UV-EPROM, 128K bits, 250 ns access. `27XX` always denotes a UV-EPROM; `C` denotes CMOS technology.

| Part # | Capacity | Org. | Access | Pins |
| ------ | -------- | ------- | ------ | :--: |
| 2716 | 16K | 2K × 8 | 450 ns | 24 |
| 2764-20 | 64K | 8K × 8 | 200 ns | 28 |
| 27128-25 | 128K | 16K × 8 | 250 ns | 28 |
| 27256-25 | 256K | 32K × 8 | 250 ns | 28 |
| 27512-25 | 512K | 64K × 8 | 250 ns | 28 |

**Example 0-14:** For ROM chip **27128**: capacity 128K bits, organization 16K × 8 (all ROMs have 8 data pins) → **8 data pins**, and since 2<sup>14</sup> = 16K → **14 address pins**.

---

## EEPROM and Flash Memory

**EEPROM (Electrically Erasable PROM)**
* Erasure is **electrical** and **instant** -- no 20-minute wait.
* A **single byte** can be erased at a time (unlike UV-EPROM, which erases everything).
* Can be programmed and erased **while still in the system board** -- no external programmer/eraser needed.
* Cost per bit is much higher than UV-EPROM.

**Flash Memory EPROM**
* Popular since the early 1990s. Erasure of the **entire chip** takes less than a second ("in a flash").
* Erasure is electrical (sometimes called Flash EEPROM), but unlike EEPROM there is **no single-byte erase** -- the whole device (or block) is erased at once.
* Widely used to upgrade a PC's BIOS ROM in-circuit.

---
layout: two-cols
---

## EEPROM / Flash Chips (Table 0-6, excerpt)

| Part No. | Capacity | Org. | Speed |
| -------- | -------- | ------- | ----- |
| 2864A | 64K | 8K × 8 | 250 ns |
| 28C256-15 | 256K | 32K × 8 | 150 ns |
| 28F010-15 | 1024K | 128K × 8 | 150 ns |
| 28F020-15 | 2048K | 256K × 8 | 150 ns |

* **Program/erase cycle** = number of times a chip can be erased & reprogrammed before it wears out: **100,000** for Flash/EEPROM, **1,000** for UV-EPROM, and **infinite** for RAM and disks.

::right::

## Mask ROM

* Programmed **by the IC manufacturer** at fabrication time using a costly photographic "mask" -- **not** user-programmable.
* Used only when volume is high (hundreds of thousands of units) and the contents are absolutely final.
* Common practice: develop/prototype with UV-EPROM or Flash, then order the mask ROM version once the code is finalized.
* Main advantage: **lowest cost per unit**. Main risk: if an error is found, the **entire batch** must be discarded.
* **All ROM types have 8 data pins** -- organization is always ×8.

---

## RAM Overview

* **RAM** is *volatile* -- data is lost when power is cut. Also called **RAWM** (read and write memory).
* Three types of RAM:
    * **SRAM** (Static RAM)
    * **DRAM** (Dynamic RAM)
    * **NV-RAM** (Nonvolatile RAM)

---
layout: image-right
backgroundSize: contain
image: /ch0_sram_pins.png
---

## SRAM (Static RAM)

* Storage cells are built from **flip-flops** (at least 6 transistors per bit, or 4 with CMOS), so they need **no refresh**.
* **Advantages:** faster, no refresh circuitry needed.
* **Disadvantages:** higher power consumption, more expensive, lower density than DRAM.
* Example (6116, 2K × 8 SRAM): `A0-A10` address (11 lines → 2<sup>11</sup> = 2K), `WE` write enable (active low), `OE` output enable (active low), `CS` chip select, `I/O0-I/O7` data (8 bits → org. 2K × 8).

---

## NV-RAM (Nonvolatile RAM)

* Combines the **read/write speed of RAM** with the **nonvolatility of ROM**.
* Every NV-RAM chip internally contains three things:
    1. Extremely power-efficient **SRAM cells** built of CMOS.
    2. An internal **lithium battery** as a backup energy source.
    3. **Intelligent control circuitry** that constantly monitors V<sub>CC</sub>; if power falls out of tolerance, it switches automatically to the lithium battery.
* Can retain contents for **up to 10 years** after power loss, and reads/writes exactly like SRAM.
* Because all this circuitry is packed onto one chip, NV-RAM is **expensive** per bit.

---

## DRAM (Dynamic RAM)

* Introduced by Intel in **1970** (1,024-bit density). Each bit is stored as charge on a **capacitor**, which needs far fewer transistors per cell than SRAM's flip-flops.
* **Advantages:** high density (capacity), cheaper cost per bit, lower power consumption per bit.
* **Disadvantages:** slower, and must be **refreshed periodically** since the capacitor's charge leaks away -- data cannot be accessed while refreshing.
* Capacity growth: 1K (1970) → 4K (1973) → 16K (1976) → 64K/256K/1M/4M (1980s) → 16M/64M/256M/1G (1990s) → 2G+ (2000s).

---

## DRAM Packaging: Address Multiplexing

* Fitting a huge number of cells onto a chip while keeping the pin count low is a challenge -- a 64K × 1 DRAM would otherwise need 16 address pins.
* Solution: **multiplex/demultiplex** the address. The chip's internal array is arranged as a square of **rows and columns**.
    * The first half of the address (the **row**) is sent in and latched by **RAS** (Row Address Strobe).
    * The second half (the **column**) is sent through the *same* pins and latched by **CAS** (Column Address Strobe).
* Result: only **8 address pins + RAS + CAS = 10 pins**, instead of 16.
* Requires an external 2-to-1 multiplexer and complicates interfacing -- many small microcontroller projects (under 64K of RAM) use SRAM, EEPROM, or NV-RAM instead of DRAM to avoid this complexity.

**Example 0-15:** For a 16K × 4 memory (2<sup>14</sup> = 16K), both chips need 4 data pins, but:
* **DRAM**: 7 address pins (A0-A6, half of 14) + RAS + CAS.
* **SRAM**: 14 address pins, no RAS/CAS needed.

---
layout: image-right
backgroundSize: contain
image: /ch0_address_decoder.png
---

## Memory Address Decoding

* The CPU supplies the address; **decoding circuitry** locates the correct memory block. Every memory chip has one or more **CS** (chip select) pins that must be activated before its contents can be accessed.
* Three common ways to build decoding circuitry:
    1. Simple logic gates (NAND + inverters)
    2. The 74LS138 3-to-8 decoder
    3. Programmable logic (PAL, GAL, FPGA)
* **Simple gate decoder:** a NAND gate's output is active-low, matching an active-low CS pin perfectly.
* Figure 0-16 example: A15-A12 must equal `0011` to select the chip, giving it the address range **3000H-3FFFH**.

---
layout: two-cols
---

## The 74LS138 3-to-8 Decoder

* 3 select inputs **A, B, C** generate **8 active-low outputs Y0-Y7**, each wired to the CS of one memory block -- one chip can control 8 memory blocks.
* 3 enable inputs: **G2A**, **G2B** (active low) and **G1** (active high). *All three* must be asserted for any output to activate.
* Unused enable inputs must be tied permanently to V<sub>CC</sub> or GND depending on their active level.

::right::

**Example 0-16** (from Figure 0-18: A12-A14 → A,B,C; A15 → G2A; GND → G2B; V<sub>CC</sub> → G1):

* **Y4** range: A15=0, A14A13A12 = 100 (4) → **4000H-4FFFH**
* **Y2** range: A14A13A12 = 010 (2) → **2000H-2FFFH**
* **Y7** range: A14A13A12 = 111 (7) → **7000H-7FFFH**

* Programmable logic (PAL/GAL/FPGA) offers more inputs (10+) and full flexibility, at the cost of needing dedicated software and a burner.

---

## Lecture Outline

<div class="text-sm">

1.  Numbering and Coding Systems
2.  Digital Primer (Logic Gates)
3.  Semiconductor Memory
4.  **CPU Architecture: Harvard vs. von Neumann**

</div>

---
layout: image-right
backgroundSize: contain
image: /ch0_cpu_block_diagram.png
---

## Inside the CPU

* A program stored in memory provides instructions; the CPU's job is to **fetch** and **execute** them.
* **Registers**: temporary storage inside the CPU (8, 16, 32, or 64-bit). More/bigger registers generally mean a better -- and more expensive -- CPU.
* **ALU** (Arithmetic/Logic Unit): performs arithmetic (add, subtract, multiply, divide) and logic (AND, OR, NOT) operations.
* **Program Counter (PC)**: holds the address of the *next* instruction to fetch; increments automatically after each fetch. (Called the **IP**, instruction pointer, in the IBM PC/x86 world.)
* **Instruction Decoder**: interprets the fetched instruction, like a dictionary -- the more instructions a CPU understands, the more transistors its decoder needs.

---

## Worked Example: Fetch-Decode-Execute

* Imaginary CPU: registers A, B, C, D; **8-bit data bus**, **16-bit address bus** (addresses 0000H-FFFFH).
* Task: move 21H into register A, then add 42H, then add 12H.
* Instruction codes: `B0H` = "move next byte into register A"; `04H` = "add next byte to register A"; `F4H` = halt.

Program stored starting at address 1400H:

| Address | Contents |
| :-----: | -------------------------------- |
| 1400 | B0 -- code: move value to register A |
| 1401 | 21 -- value to be moved |
| 1402 | 04 -- code: add value to register A |
| 1403 | 42 -- value to be added |
| 1404 | 04 -- code: add value to register A |
| 1405 | 12 -- value to be added |
| 1406 | F4 -- code for halt |

---

## Worked Example: Step by Step

1. The **program counter** is loaded with `1400H`, the address of the first instruction.
2. The CPU puts `1400H` on the address bus and activates READ. Memory returns `B0` on the data bus.
3. The CPU **decodes** `B0`: "bring the next byte into register A." It fetches `21H` from `1401H` into register A. PC advances to `1402H`.
4. The CPU fetches and decodes `04H` at `1402H`: "add the next byte to register A." It fetches `42H` from `1403H`, and the ALU computes **21H + 42H = 63H**, stored back into register A. PC advances to `1404H`.
5. The CPU fetches `04H` again at `1404H`, fetches `12H` from `1405H`, and the ALU computes **63H + 12H = 75H** into register A. PC advances to `1406H`.
6. The CPU fetches `F4H` (**HALT**) and stops incrementing the program counter -- without it, the CPU would keep fetching and executing whatever follows in memory.

---
layout: image-right
backgroundSize: contain
image: /ch0_vonneumann_vs_harvard.png
---

## Harvard vs. von Neumann Architecture

* Every microprocessor needs memory space for **code** (instructions) and **data**.
* **von Neumann (Princeton) architecture**: one shared bus accesses both code and data. Simpler, but code and data fetches can conflict, each waiting on the other -- slowing the CPU.
* **Harvard architecture**: **separate** buses for code and data -- 4 bus sets in total (address + data, for each of code and data). Code and data can be fetched **simultaneously**, which is faster.

---

## Harvard vs. von Neumann (cont.)

* Harvard architecture is easy to implement **on-chip**, where ROM code and RAM data are both internal and distances are measured in microns -- this is exactly how **microcontrollers** like the AVR work internally.
* It is far more **expensive** to implement off-chip: a Pentium-class CPU (64-bit data, 32-bit address) needs roughly 100 wire traces on the motherboard for von Neumann, but that number would **double to ~200** for Harvard -- plus many more CPU pins. This is why you never see Harvard architecture used on PC/workstation motherboards.
* **AVR microcontrollers use Harvard architecture internally**, but fall back to a von Neumann-style shared bus if the design needs *external* memory for code or data space.
* von Neumann architecture was developed at **Princeton University**; Harvard architecture was the work of **Harvard University**.

---
layout: default
---

## Summary

* **Numbering & Coding Systems:** Converting between binary, decimal, and hexadecimal; binary/hex addition and subtraction; 2's complement; the ASCII code.
* **Digital Primer:** AND, OR, NOT, XOR, NAND, and NOR gates; building half-adders and full-adders from gates; decoders and D flip-flops.
* **Semiconductor Memory:** Bit/nibble/byte/word and kilo-/mega-/giga-/terabyte; RAM vs. ROM; memory capacity, organization, and access time; PROM, EPROM, EEPROM, Flash, and mask ROM; SRAM, DRAM, and NV-RAM; memory address decoding with logic gates and the 74LS138.
* **CPU Architecture:** Registers, ALU, program counter, and instruction decoder; a step-by-step fetch-decode-execute trace; Harvard vs. von Neumann architecture, and why microcontrollers like the AVR use Harvard internally.
