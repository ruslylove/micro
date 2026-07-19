---
theme: seriph
background: https://cover.sli.dev
transition: slide-left
layout: cover
title: Lecture 1 - The AVR Microcontroller - History and Features
---

# Lecture 1: The AVR Microcontroller
## History and Features
### {{ $slidev.configs.subject }}
#### Semester {{ $slidev.configs.semester }}
##### Presented by {{ $slidev.configs.presenter }}

---

## Objectives

Upon completion of this chapter, you will be able to:

* Compare and contrast **microprocessors** and **microcontrollers**
* Describe the advantages of microcontrollers for some applications
* Explain the concept of **embedded systems**
* Discuss criteria for considering a microcontroller
* Explain the variations of speed, packaging, memory, and cost per unit and how these affect choosing a microcontroller
* Compare and contrast the various members of the **AVR family**
* Compare the AVR with microcontrollers offered by other manufacturers

---

## Lecture Outline

<div class="text-sm">

1.  **Microcontrollers and Embedded Processors**
    * Microprocessor vs. Microcontroller
    * Embedded systems
    * Criteria for choosing a microcontroller
2.  Overview of the AVR Family
    * A brief history of AVR
    * AVR features
    * Classic / Mega / Tiny / Special-purpose AVR
    * AVR product number scheme
    * Other 8-bit microcontrollers

</div>

---
hideInToc: true
---

# Part 1
## Microcontrollers and Embedded Processors

---
layout: image-right
backgroundSize: contain
image: /ch1_micro_vs_microcontroller.png
---

## Microprocessor vs. Microcontroller

* A **microprocessor** (Intel x86 family, Motorola PowerPC, ...) contains no RAM, no ROM, and no I/O ports on the chip itself.
    * These are called **general-purpose microprocessors**.
    * The system designer must add RAM, ROM, and I/O externally to make it functional.
    * More versatile, but bulkier and more expensive.
* A **microcontroller** has a CPU (a microprocessor) **plus** a fixed amount of RAM, ROM, I/O ports, and a timer, all on a single chip.
    * The designer cannot add external memory, I/O, or a timer.
    * The fixed, embedded resources make microcontrollers ideal where **cost and space are critical**.

---

## Why Not Just Use a Microprocessor?

* Consider a **TV remote control** — it does not need the computing power of an 8086 or a 486.
* For many applications, what matters most is:
    * Space used on the board
    * Power consumed
    * Price per unit
* These applications mostly need simple I/O: read a signal, turn a bit on or off.
    * Such processors are sometimes nicknamed **IBP** — "itty-bitty processors."
* Many microcontroller makers go further and integrate an **ADC** (analog-to-digital converter) and other peripherals right onto the chip.

---
layout: two-cols-header
---

## Microcontrollers for Embedded Systems

::left::

* An **embedded system** is controlled by its own internal processor, as opposed to an external controller.
* Typically the microcontroller's ROM is burned once, for one specific purpose.
* Example: a **printer** — the processor inside does one task only: get the data and print it.
* Contrast with a Pentium-based PC: it has RAM + an OS that loads *any* application software, so it can do word processing, gaming, networking, and more.

::right::

**Table 1-1: Some Embedded Products Using Microcontrollers**

<div class="text-sm">

| Home | Office | Auto |
|---|---|---|
| Appliances | Telephones | Trip computer |
| Security systems | Computers | Engine control |
| Garage door openers | Fax machine | Air bag / ABS |
| TVs, VCR, Camcorder | Microwave | Instrumentation |
| Remote controls | Copier | Transmission control |
| Video games | Laser/color printer | Climate control |
| Cellular phones | Paging | Keyless entry |

</div>

*An x86 PC itself is also surrounded by embedded products: keyboard, mouse, modem, disk controller, sound card — each with its own microcontroller inside.*

---

## x86 PCs as High-End Embedded Processors

* Microcontrollers are the preferred choice for most embedded systems, but sometimes they are **not powerful enough** for the task.
* Manufacturers of general-purpose microprocessors (Intel, Freescale, AMD) have targeted their chips at the **high end** of the embedded market.
    * Apple used the PowerPC (604, 603, 620...) in Macintosh computers from the early 1990s until switching to x86 in 2007.
    * When a general-purpose processor is optimized for embedded use, it is called a **high-end embedded processor**.
    * The **ARM** (Advanced RISC Machine) is another chip widely used at the high end of embedded design.
* The terms *embedded processor* and *microcontroller* are very often used interchangeably.
* A key embedded-system goal is to **decrease power consumption and space** — achieved by integrating more functions onto a single chip.
* Because Linux and Windows are so widely understood, many embedded systems now use x86 PCs simply to reuse the vast existing software library and shorten development time.

---

## Choosing a Microcontroller

There are five major 8-bit microcontroller families:

| Family | Manufacturer |
|---|---|
| **AVR** | Atmel |
| **8051** | Intel (and many second-source vendors) |
| **68HC08 / 68HC11** | Freescale Semiconductor (formerly Motorola) |
| **PIC** | Microchip Technology |
| **Z8** | Zilog |

There are also 16-bit and 32-bit microcontrollers. Each family has its own instruction set and register set — **they are not compatible with each other**; a program written for one will not run on another.

**Three criteria** guide the choice: (1) meeting the computing needs of the task efficiently and cost-effectively, (2) availability of development tools, (3) wide and reliable availability of the chip itself.

---

## Criterion 1: Meeting the Task Efficiently

First decide whether an 8-bit, 16-bit, or 32-bit microcontroller best fits the job. Then consider:

* **(a) Speed** — the highest clock speed the microcontroller supports.
* **(b) Packaging** — DIP (dual inline package) vs. QFP (quad flat package) vs. others; matters for space, assembly, and prototyping.
* **(c) Power consumption** — especially critical for battery-powered products.
* **(d) On-chip RAM and ROM** — the amount available.
* **(e) I/O pins and timers** — the number available on the chip.
* **(f) Ease of upgrade** — to higher-performance or lower-power versions.
* **(g) Cost per unit** — critical to the final product cost. Some microcontrollers cost as little as **50 cents/unit** when purchased 100,000 at a time.

---

## Criteria 2 and 3: Tools and Availability

**Criterion 2 — Ease of development**

* Availability of an assembler, a debugger, a code-efficient C compiler, and an emulator.
* Technical support, plus in-house and outside expertise.
* Third-party (non-manufacturer) vendor support is often as good as, or better than, support from the chip maker itself.

**Criterion 3 — Ready availability, now and in the future**

* For some designers this outweighs the first two criteria combined.
* The **8051** family currently has the largest number of diversified (multiple) suppliers — a *supplier* is any producer besides the originator.
* Freescale, Atmel, Zilog, and Microchip all dedicate massive resources to guarantee wide, timely availability because their products are stable, mature, and single-sourced.
* FPGA and ASIC libraries are now also available for many microcontroller families.

---

## Aside: Mechatronics

* The microcontroller plays a major role in the emerging field of **mechatronics** — the integration of mechanics, electronics, and information processing.
* Mechatronic systems balance:
    * Mechanical structure
    * Sensor and actuator implementation
    * Automatic digital information processing and control
* This synergy requires multidisciplinary expertise: mechanical engineering, electronics, information technology, and decision-making theory.

---

## Lecture Outline

<div class="text-sm">

1.  Microcontrollers and Embedded Processors
    * Microprocessor vs. Microcontroller
    * Embedded systems
    * Criteria for choosing a microcontroller
2.  **Overview of the AVR Family**
    * A brief history of AVR
    * AVR features
    * Classic / Mega / Tiny / Special-purpose AVR
    * AVR product number scheme
    * Other 8-bit microcontrollers

</div>

---
hideInToc: true
---

# Part 2
## Overview of the AVR Family

---

## A Brief History of the AVR Microcontroller

* The basic AVR architecture was designed by two students at the **Norwegian Institute of Technology (NTH)**: **Alf-Egil Bogen** and **Vegard Wollan**.
* It was bought and developed by **Atmel** starting in **1996**.
* What does "AVR" stand for? Atmel says it is simply a product name — but it is widely believed to stand for **Advanced Virtual RISC**, or **Alf and Vegard's RISC** (after its designers).
* Except for **AVR32** (a 32-bit microcontroller), all AVRs are **8-bit** — the CPU works on only 8 bits of data at a time; larger data must be broken into 8-bit pieces.
* AVR families are **not 100% software-compatible** with each other. Moving code from an ATtiny25 to an ATmega64 requires recompiling and possibly changing register locations.
* AVRs are generally classified into **four broad groups**: Classic, Mega, Tiny, and Special Purpose.
* This book focuses on the **Mega family**, especially the **ATmega32** — powerful, widely available, and offered in a DIP package ideal for education.

---
layout: image-right
backgroundSize: contain
image: /ch1_avr_simplified_block.png
---

## AVR Features

The AVR is an **8-bit RISC** single-chip microcontroller with **Harvard architecture**, coming standard with:

* On-chip program (code) **ROM**
* Data **RAM**
* Data **EEPROM**
* **Timers** and **I/O ports**

Most AVRs add: **ADC**, **PWM**, and serial interfaces such as **USART, SPI, I²C (TWI), CAN, USB**.

**Program ROM:** the AVR architecture supports up to 8M of program space, though actual chips ship from **1K to 256K**, depending on family member. AVR was one of the first microcontrollers to use on-chip **Flash memory** for program storage — Flash erases in seconds vs. 20+ minutes for UV-EPROM.

---

## AVR Data RAM, EEPROM, and I/O

* **Data RAM:** the AVR architecture supports up to **64K bytes**, though not every family member ships with that much. Data RAM space has three components:
    * 32 **general-purpose registers** (present in every AVR)
    * **I/O memory**
    * Internal **SRAM** (the read/write scratchpad)
* **Data EEPROM:** a small amount of EEPROM stores critical data that rarely changes.
* **I/O pins:** from **3 to 86** pins, depending on the package (packages range from 8 to 100 pins).
    * 8-pin AT90S2323 → 3 I/O pins
    * 100-pin ATmega1280 → up to 86 I/O pins
* **Peripherals:** most AVRs include a **10-bit ADC** (up to 16 channels) and up to **6 timers** (plus the watchdog timer). The USART peripheral connects an AVR system to a serial port such as an x86 PC's COM port. Most family members also include I²C and SPI; some add USB or CAN.

---
layout: image-right
backgroundSize: contain
image: /ch1_atmega32_block.png
---

## Focus Chip: the ATmega32

* This course (and book) focuses on the **ATmega32** because it is:
    * Powerful — over 120 instructions and a rich peripheral set
    * Widely available
    * Offered in a **DIP package**, which is ideal for breadboarding and educational use
* The block diagram shows the AVR CPU core (program counter, register file, ALU, status register) surrounded by its peripherals: **ports A–D, ADC, TWI, timers/counters, USART, SPI, analog comparator, EEPROM,** and the oscillator/reset circuitry.
* Once you master the Mega family, understanding the Tiny, Classic, and Special Purpose families is straightforward — the core concepts carry over.

---

## AVR Family Overview: Four Groups

AVR can be classified into four groups:

| Group | Part prefix | Notes |
|---|---|---|
| **Classic** | AT90Sxxxx | The original AVR chip; **not recommended for new designs** |
| **Mega** | ATmegaxxxx | Powerful, rich peripherals, 120+ instructions — this book's focus |
| **Tiny** | ATtinyxxxx | Fewer instructions, smaller packages, low cost/power |
| **Special Purpose** | varies | Subset of other groups with special capabilities |

---

## Classic AVR (AT90Sxxxx)

The original AVR chip, superseded by newer families — shown here for historical comparison.

**Table 1-2: Some Members of the Classic Family**

| Part Num. | Code ROM | Data RAM | Data EEPROM | I/O pins | ADC | Timers | Pin numbers & Package |
|---|---|---|---|---|---|---|---|
| AT90S2313 | 2K | 128 | 128 | 15 | 0 | 2 | SOIC20, PDIP20 |
| AT90S2323 | 2K | 128 | 128 | 3 | 0 | 1 | SOIC8, PDIP8 |
| AT90S4433 | 4K | 128 | 256 | 20 | 6 | 2 | TQFP32, PDIP28 |

*All ROM, RAM, and EEPROM figures are in bytes. Data RAM is the general-purpose scratchpad RAM available, in addition to the register space.*

---

## Mega AVR (ATmegaxxxx)

Powerful microcontrollers with **120+ instructions** and extensive peripheral capability:

* Program memory: **4K to 256K bytes**
* Package: **28 to 100 pins**
* Extensive peripheral set and a rich, extended instruction set

**Table 1-3: Some Members of the ATmega Family**

| Part Num. | Code ROM | Data RAM | Data EEPROM | I/O pins | ADC | Timers | Pin numbers & Package |
|---|---|---|---|---|---|---|---|
| ATmega8 | 8K | 1K | 0.5K | 23 | 8 | 3 | TQFP32, PDIP28 |
| ATmega16 | 16K | 1K | 0.5K | 32 | 8 | 3 | TQFP44, PDIP40 |
| **ATmega32** | **32K** | **2K** | **1K** | **32** | **8** | **3** | **TQFP44, PDIP40** |
| ATmega64 | 64K | 4K | 2K | 54 | 8 | 4 | TQFP64, MLF64 |
| ATmega1280 | 128K | 8K | 4K | 86 | 16 | 6 | TQFP100, CBGA |

*All members shown also include a USART for serial data transfer.*

---

## Tiny AVR (ATtinyxxxx)

As the name suggests, this group has fewer instructions and smaller packages than the Mega family — good for low-cost, low-power designs:

* Program memory: **1K to 8K bytes**
* Package: **8 to 28 pins**
* Limited peripheral set and limited instruction set (e.g., some lack a multiply instruction)

**Table 1-4: Some Members of the Tiny Family**

| Part Num. | Code ROM | Data RAM | Data EEPROM | I/O pins | ADC | Timers | Pin numbers & Package |
|---|---|---|---|---|---|---|---|
| ATtiny13 | 1K | 64 | 64 | 6 | 4 | 1 | SOIC8, PDIP8 |
| ATtiny25 | 2K | 128 | 128 | 6 | 4 | 2 | SOIC8, PDIP8 |
| ATtiny44 | 4K | 256 | 256 | 12 | 8 | 2 | SOIC14, PDIP14 |
| ATtiny84 | 8K | 512 | 512 | 12 | 8 | 2 | SOIC14, PDIP14 |

---

## Special Purpose AVR

* This group can be viewed as a subset of the other groups, but with capabilities built for **specific applications**:
    * USB controller
    * CAN controller
    * LCD controller
    * Zigbee
    * Ethernet controller
    * FPGA
    * Advanced PWM

**Table 1-5: Some Members of the Special Purpose Family**

| Part Num. | Code ROM | Data RAM | Data EEPROM | Max I/O pins | Special Capability | Timers | Pin numbers & Package |
|---|---|---|---|---|---|---|---|
| AT90CAN128 | 128K | 4K | 4K | 53 | CAN | 4 | LQFP64 |
| AT90USB1287 | 128K | 8K | 4K | 48 | USB Host | 4 | TQFP64 |
| AT90PWM216 | 16K | 1K | 0.5K | 19 | Advanced PWM | 2 | SOIC24 |
| ATmega169 | 16K | 1K | 0.5K | 54 | LCD | 3 | TQFP64, MLF64 |

---

## AVR Product Number Scheme

* All AVR product numbers start with **AT**, which stands for **Atmel**.
* Read the number at the end of the part name, left to right, and find the **biggest power of 2** contained in it — this most often gives the microcontroller's **ROM size**.
* **Example:** ATmega**1280** → the biggest power of 2 is 128 → 128K bytes of ROM.
* **Example:** ATtiny**44** → 4K of ROM.
* There are exceptions — e.g., **AT90PWM216** actually has **16K** of ROM, not 2K — but the rule works most of the time.

---

## Other 8-bit Microcontrollers

Besides the AVR, several other 8-bit microcontroller families are widely used:

**Table 1-6: Companies Producing Widely Used 8-bit Microcontrollers**

| Company | Architecture |
|---|---|
| Atmel | AVR and 8051 |
| Microchip | PIC16xxx / 18xxx |
| Intel | 8051 |
| Philips/Signetics | 8051 |
| Zilog | Z8 and Z80 |
| Dallas Semi/Maxim | 8051 |
| Freescale Semi | 68HC11 / HCS08 |

*See microcontroller.com for a complete list.*

---

## Comparing the ATmega32 with 8052 and PIC18F452

**Table 1-7: Comparison of 8051, PIC18 Family, and AVR (40-pin package)**

| Feature | 8052 | PIC18F452 | ATmega32 |
|---|---|---|---|
| Program ROM | 8K | 32K | 32K |
| Data RAM (max space) | 256 bytes | 2K | 2K |
| EEPROM | 0 bytes | 256 bytes | 1K |
| Timers | 3 | 4 | 3 |
| I/O pins | 32 | 35 | 32 |

* The AVR is not 100% compatible with the 8051 or PIC — each has its own instruction set and register set.
* Programs are not portable across families; comparisons like this help designers pick the right tool for the task and budget.

---

## Lecture Outline

<div class="text-sm">

1.  Microcontrollers and Embedded Processors
    * Microprocessor vs. Microcontroller
    * Embedded systems
    * Criteria for choosing a microcontroller
2.  Overview of the AVR Family
    * A brief history of AVR
    * AVR features
    * Classic / Mega / Tiny / Special-purpose AVR
    * AVR product number scheme
    * Other 8-bit microcontrollers

</div>

---
layout: default
---

## Summary

* **Microprocessor vs. microcontroller:** a microprocessor needs external RAM, ROM, and I/O; a microcontroller has a fixed amount of each embedded on a single chip — ideal where cost and space are critical.
* **Embedded systems** run one dedicated application burned into ROM, unlike a general-purpose PC that loads varied software into RAM.
* **Choosing a microcontroller** comes down to three criteria: meeting the task's computing needs (speed, packaging, power, RAM/ROM, I/O pins, upgrade path, cost per unit), availability of development tools, and reliable long-term availability of the chip.
* **AVR** was designed by two NTH students (Bogen and Wollan) and developed by Atmel from 1996; it is an 8-bit RISC, Harvard-architecture microcontroller with on-chip Flash program memory.
* AVR splits into four families — **Classic** (legacy), **Mega** (this course's focus, especially **ATmega32**), **Tiny** (small/low-power), and **Special Purpose** (USB, CAN, LCD, etc.).
* The AVR product number's trailing digits usually hint at the **ROM size** (biggest power of 2).
* Other 8-bit families — **8051, PIC, 68HC11/HCS08, Z8** — use different, incompatible instruction sets; AVR compares favorably against 8052 and PIC18F452 in a 40-pin package.
