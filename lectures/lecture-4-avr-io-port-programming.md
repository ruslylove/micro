---
theme: seriph
background: https://cover.sli.dev
transition: slide-left
layout: cover
title: Lecture 4 - AVR I/O Port Programming
---

# Lecture 4: AVR I/O Port Programming
## {{ $slidev.configs.subject }}
### Semester {{ $slidev.configs.semester }}
#### Presented by {{ $slidev.configs.presenter }}

---

## Objectives

Upon completion of this chapter, you will be able to:

* Describe the I/O ports of the AVR family and the three registers associated with each port: **DDRx**, **PORTx**, and **PINx**
* Configure any pin of Port A, B, C, or D of the ATmega32 as an input or an output
* Contrast the four electrical states of an I/O pin, including the role of the internal **pull-up resistor**
* Code AVR programs that use the `OUT` and `IN` instructions for 8-bit-wide port I/O
* Explain **single-bit addressability** and code the AVR bit-oriented instructions `SBI`, `CBI`, `SBIC`, and `SBIS`
* Write AVR assembly programs that read switches and drive LEDs and other simple output devices one bit at a time

---

## Lecture Outline

<div class="text-sm">

1.  **I/O Port Programming in AVR**
    * AVR Ports and Their Three Registers (DDRx, PORTx, PINx)
    * Configuring Pins for Input vs. Output
    * Internal Pull-Up Resistors and the Four Pin States
    * Port A, B, C, and D and Their Alternate Functions
2.  I/O Bit Manipulation Programming
    * Single-Bit Addressability of I/O Ports
    * The SBI and CBI Instructions
    * The SBIC and SBIS Instructions
    * Worked Examples: Switches, LEDs, and a Buzzer

</div>

---
hideInToc: true
---

# Part 1
## I/O Port Programming in AVR

---
layout: image-right
backgroundSize: contain
image: /ch4_atmega32_pin_diagram.png
---

## Figure 4-1: The ATmega32 Pin Diagram

* 40 pins total; **32** of them are the general-purpose I/O pins of **Port A, B, C, and D** (8 pins each).
* The remaining 8 pins are power/clock/reset: **VCC, GND, XTAL1, XTAL2, RESET, AREF, AGND, AVCC**.
* Many port pins double as an **alternate function** in parentheses, e.g. `(MOSI) PB5`, `(RXD) PD0` -- covered in later chapters.

---

## AVR I/O Ports: How Many, How Wide

* Every AVR chip brings some number of its internal signals out to the pins as general-purpose I/O ports, named **PORTA, PORTB, PORTC, ...**
* Not every family member has all the ports, and not every port has a full 8 bits (e.g., Port C on the ATmega8 has only 7 pins).
* Besides simple I/O, most port pins have an **alternate function** — ADC input, timer, serial interface, and so on. This chapter focuses only on the simple I/O function; alternate functions are covered in later chapters.

**Table 4-1: Number of Ports in Some AVR Family Members**

<div class="text-sm">

| Pins | 8-pin | 28-pin | 40-pin | 64-pin | 100-pin |
|---|---|---|---|---|---|
| **Chip** | ATtiny25/45/85 | ATmega8/48/88 | ATmega32/16 | ATmega64/128 | ATmega1280 |
| Port A | | | X | X | X |
| Port B | 6 bits | X | X | X | X |
| Port C | | 7 bits | X | X | X |
| Port D | | X | X | X | X |
| Port E | | | | X | X |
| Port F | | | | X | X |
| Port G | | | | 5 bits | 6 bits |
| Port H / J / K / L | | | | | X |

</div>

---
layout: two-cols-header
---

## Three I/O Registers per Port

Each port has **three** I/O registers associated with it, each 8 bits wide, one bit per pin:

::left::

* **DDRx** — Data Direction Register: sets each pin as input (0) or output (1)
* **PORTx** — writes data out to the pins (output mode), or activates the internal pull-up resistor (input mode)
* **PINx** — reads the data actually present at the pins (**P**ort **IN**put)

For Port B, this gives us `DDRB`, `PORTB`, and `PINB`.

::right::

**Table 4-2: Register Addresses for ATmega32 Ports**

<div class="text-sm">

| Port | Address | Usage |
|---|---|---|
| PORTA | $3B | output |
| DDRA | $3A | direction |
| PINA | $39 | input |
| PORTB | $38 | output |
| DDRB | $37 | direction |
| PINB | $36 | input |
| PORTC | $35 | output |
| DDRC | $34 | direction |
| PINC | $33 | input |
| PORTD | $32 | output |
| DDRD | $31 | direction |
| PIND | $30 | input |

</div>

---
layout: image-right
backgroundSize: contain
image: /ch4_port_pin_circuit.png
---

## DDRx: Setting the Direction

* Each of Ports A–D can be used for input or output. The **DDRx** register decides which, one bit per pin.
* To make a pin **output**, write a **1** to its DDRx bit.
* To make a pin **input**, write a **0** to its DDRx bit.
* Unless the DDRx bit is set to 1, data written to PORTx never reaches the physical pin — it just sits in the CPU's I/O register.

```asm {*|1-2|3-9}{lines:true}
;toggle all bits of PORTB
.INCLUDE "M32DEF.INC"
LDI   R16,0xFF     ;R16 = 0xFF = 0b11111111
OUT   DDRB,R16      ;make Port B an output port (1111 1111)
L1:   LDI   R16,0x55     ;R16 = 0x55 = 0b01010101
      OUT   PORTB,R16    ;put 0x55 on port B pins
      CALL  DELAY
      LDI   R16,0xAA     ;R16 = 0xAA = 0b10101010
      OUT   PORTB,R16    ;put 0xAA on port B pins
      CALL  DELAY
      RJMP  L1
```

---

## DDRx Role in Inputting Data

* To make a port **input**, put **0s** into its DDRx register, then read the data present at the pins.
* Memory aid: imagine a person who has **0 dollars** — they can only *get* money, not give it. Likewise, when DDR bits are 0, the port only *gets* data.
* **Upon reset, every port's DDR register contains `0x00`** — so all AVR ports come up configured as **input** by default.

```asm {*}{lines:true}
.INCLUDE "M32DEF.INC"
.EQU  MYTEMP 0x100        ;save it here
LDI   R16,0x00            ;R16 = 00000000 (binary)
OUT   DDRA,R16            ;make Port A an input port (0 for In)
NOP                       ;synchronizer delay
IN    R16,PINA            ;move from pins of Port A to R16
STS   MYTEMP,R16          ;save it in MYTEMP
```

* We read the **PINx** register (never PORTx) to bring data from the pins into the CPU; we write to **PORTx** to send data out.

---
layout: image-right
backgroundSize: contain
image: /ch4_pullup_resistor.png
---

## PORTx as Input: Internal Pull-Ups

* There is a pull-up resistor built in for every AVR pin.
* If DDRx = 0 (input) and we write a **1** to PORTx, the pull-up is **activated** — useful when nothing, or a high-impedance device, is connected to the pin.
* If we write a **0** to PORTx while DDRx = 0, the pull-up is **inactive** and the pin floats (high impedance).

```asm {*}{lines:true,maxHeight:'260px'}
.INCLUDE "M32DEF.INC"
LDI   R16,0xFF     ;R16 = 11111111 (binary)
OUT   DDRB,R16     ;make Port B an output port
OUT   PORTC,R16    ;make the pull-up resistors of C active
LDI   R16,0x00     ;R16 = 00000000 (binary)
OUT   DDRC,R16     ;Port C an input port (0 for I)
L2:   IN    R16,PINC     ;move data from Port C to R16
      LDI   R17,5
      ADD   R16,R17      ;add some value to it
      OUT   PORTB,R16    ;send it to Port B
      RJMP  L2           ;continue forever
```

---

## The Four States of an AVR Pin

Depending on the combination of PORTx and DDRx, every AVR pin can be in one of **four** distinct states:

**Figure 4-5: Different States of a Pin in the AVR Microcontroller**

| PORTx \ DDRx | 0 | 1 |
|---|---|---|
| **0** | Input & high impedance | Out 0 |
| **1** | Input & pull-up | Out 1 |

* This is one of the powerful features of the AVR — most other microcontrollers (e.g., the 8051) offer fewer pin states.

---
layout: two-cols-header
---

## Port A

::left::

* Port A occupies 8 pins, **PA0–PA7**.
* To use Port A pins as input or output, each bit of `DDRA` must be set to the proper value — same pattern as Port B.

```asm {*}{lines:true,maxHeight:'220px'}
;toggle all bits of PORTA
.INCLUDE "M32DEF.INC"
LDI   R16,0xFF     ;R16 = 11111111 (binary)
OUT   DDRA,R16     ;make Port A an output port
L1:   LDI   R16,0x55     ;R16 = 0x55
      OUT   PORTA,R16    ;put 0x55 on Port A pins
      CALL  DELAY
      LDI   R16,0xAA     ;R16 = 0xAA
      OUT   PORTA,R16    ;put 0xAA on Port A pins
      CALL  DELAY
      RJMP  L1
```

::right::

**Table 4-3: Port A Alternate Functions**

<div class="text-sm">

| Bit | Function |
|---|---|
| PA0–PA7 | ADC0–ADC7 |

</div>

* The ATmega32 multiplexes an **8-channel ADC** onto Port A (Chapter 13). Because many projects use the ADC, Port A is often reserved and not used for simple I/O.

---

## Port B, C, and D Follow the Same Pattern

Ports B, C, and D behave exactly like Port A — only the register names change. Each has its own alternate functions, multiplexed to save pins:

<div class="text-sm">

| Port | Pins | Alternate functions (Table 4-4 / 4-5 / 4-6) |
|---|---|---|
| **Port B** (PB0–PB7) | 8 | XCK/T0, T1, INT2/AIN0, OC0/AIN1, SS, MOSI, MISO, SCK |
| **Port C** (PC0–PC7) | 8 | SCL, SDA, TCK, TMS, TDO, TDI, TOSC1, TOSC2 |
| **Port D** (PD0–PD7) | 8 | PSP0/C1IN+, PSP1/C1IN-, PSP2/C2IN+, PSP3/C2IN-, PSP4/ECCP1/P1A, PSP5/P1B, PSP6/P1C, PSP7/P1D |

</div>

* To toggle Port C: substitute `DDRC` / `PORTC` for `DDRB` / `PORTB` in the same code pattern. Same for Port D with `DDRD` / `PORTD`.
* To configure any of them as **input**: clear the DDRx register (all 0s), then `IN Rn, PINx` — identical to the Port A input example.
* We will use these alternate functions (ADC, timers, USART, SPI, I²C/TWI, JTAG) in future chapters.

---

## Synchronizer Delay

* The AVR's input circuitry has a delay of **1 clock cycle**: the PINx register reflects the data that was present at the pins *one clock ago*.
* That is why a `NOP` is placed immediately before `IN R16,PINA` — if the `NOP` is omitted, the value read may still reflect the pin's state from when the port was configured as output.

```asm
OUT   DDRA,R16     ;make Port A an input port (0 for In)
NOP                ;synchronizer delay
IN    R16,PINA     ;now safe to read the pins
```

* See Appendix C, Section C-2, for the full internal circuitry of the AVR I/O port.

---

## Worked Example 4-1: Toggling Three Ports Together

**Problem:** Toggle all the bits of PORTB, PORTC, and PORTD every 1/4 second. Assume a 1 MHz crystal.

```asm {*}{lines:true,maxHeight:'340px'}
;tested with AVR Studio for the ATmega32 and XTAL = 1 MHz
.INCLUDE "M32DEF.INC"
      LDI   R16, HIGH(RAMEND)
      OUT   SPH, R16
      LDI   R16, LOW(RAMEND)
      OUT   SPL, R16          ;initialize stack pointer

      LDI   R16, 0xFF
      OUT   DDRB, R16         ;make Port B an output port
      OUT   DDRC, R16         ;make Port C an output port
      OUT   DDRD, R16         ;make Port D an output port

      LDI   R16, 0x55         ;R16 = 0x55
L3:   OUT   PORTB, R16        ;put 0x55 on Port B pins
      OUT   PORTC, R16        ;put 0x55 on Port C pins
      OUT   PORTD, R16        ;put 0x55 on Port D pins
      CALL  QDELAY            ;quarter of a second delay
      COM   R16               ;complement R16
      RJMP  L3
```

**Calculation:** 1/1 MHz = 1 µs. Delay = 200 × 250 × 5 MC × 1 µs = 250,000 µs (≈ 1/4 second, ignoring call/return overhead).

---

## Lecture Outline

<div class="text-sm">

1.  **I/O Port Programming in AVR**
    * AVR Ports and Their Three Registers (DDRx, PORTx, PINx)
    * Configuring Pins for Input vs. Output
    * Internal Pull-Up Resistors and the Four Pin States
    * Port A, B, C, and D and Their Alternate Functions
2.  I/O Bit Manipulation Programming
    * Single-Bit Addressability of I/O Ports
    * The SBI and CBI Instructions
    * The SBIC and SBIS Instructions
    * Worked Examples: Switches, LEDs, and a Buzzer

</div>

---
hideInToc: true
---

# Part 2
## I/O Bit Manipulation Programming

---
layout: two-cols-header
---

## Single-Bit Addressability

::left::

* Sometimes we need to access just 1 or 2 bits of a port, not the whole byte.
* A powerful AVR feature: we can set, clear, or test **any single bit** of the lower 32 I/O registers **without disturbing the other bits**.
* This applies to all of PORTA–D, DDRA–D, and PINA–D, since their I/O addresses all fall in the 0–31 range.

**Table 4-7: Single-Bit (Bit-Oriented) Instructions**

| Instruction | Function |
|---|---|
| `SBI ioReg,bit` | Set Bit in I/O register (bit = 1) |
| `CBI ioReg,bit` | Clear Bit in I/O register (bit = 0) |
| `SBIC ioReg,bit` | Skip next instruction if Bit is Cleared (bit = 0) |
| `SBIS ioReg,bit` | Skip next instruction if Bit is Set (bit = 1) |

::right::

**I/O Addresses of the AVR Ports** (subset of Table 4-8 — required to be in range 0–31 for `SBI`/`CBI`/`SBIC`/`SBIS`)

<div class="text-sm">

| I/O Addr | Name | I/O Addr | Name |
|---|---|---|---|
| $10 | PIND | $16 | PINB |
| $11 | DDRD | $17 | DDRB |
| $12 | PORTD | $18 | PORTB |
| $13 | PINC | $19 | PINA |
| $14 | DDRC | $1A | DDRA |
| $15 | PORTC | $1B | PORTA |

</div>

---

## SBI — Set Bit in I/O Register

**Syntax:** `SBI ioReg, bit_num` &nbsp;→&nbsp; `ioReg.bit = 1`

* `ioReg` is one of the lower 32 I/O registers (address 0–31); `bit_num` ranges 0–7.

```text
SBI a,b   ->  1001 1010 aaaa abbb        0 <= a <= 31,  0 <= b <= 7
```

Example — set bit 5 of Port B HIGH:

```asm
SBI   PORTB, 5
```

Other examples:

```asm
SBI   PORTD,0    ;PORTD.0 = 1
SBI   DDRC,5     ;DDRC.5 = 1
```

---

## CBI — Clear Bit in I/O Register

**Syntax:** `CBI ioReg, bit_number` &nbsp;→&nbsp; `ioReg.bit = 0`

```text
CBI a,b   ->  1001 1000 aaaa abbb        0 <= a <= 31,  0 <= b <= 7
```

The following code toggles pin **PB2** continuously, without touching any other bit of Port B:

```asm {*}{lines:true}
SBI    DDRB, 2       ;bit = 1, make PB2 an output pin
AGAIN: SBI    PORTB, 2       ;bit set (PB2 = high)
       CALL   DELAY
       CBI    PORTB, 2       ;bit clear (PB2 = low)
       CALL   DELAY
       RJMP   AGAIN
```

* Remember: for I/O ports we must still set the corresponding **DDRx** bit if we want that pin to be an output.
* Notice PB2 is the **third** bit of Port B (PB0 is first, PB1 second, ...) — see Table 4-9 next.

---
layout: image-right
backgroundSize: contain
image: /ch4_led_chain_example.png
---

## Worked Example 4-2: LED Chain on Port D

**Problem:** An LED is connected to each pin of Port D. Turn on each LED in turn, D0 through D7, with a delay between each.

```asm {*}{lines:true,maxHeight:'320px'}
.INCLUDE "M32DEF.INC"
LDI   R20, HIGH(RAMEND)
OUT   SPH, R20
LDI   R20, LOW(RAMEND)
OUT   SPL, R20      ;initialize stack pointer
LDI   R20, 0xFF
OUT   PORTD, R20    ;make PORTD an output port
SBI   PORTD,0       ;set bit PD0
CALL  DELAY         ;delay before next one
SBI   PORTD,1       ;turn on PD1
CALL  DELAY
SBI   PORTD,2       ;turn on PD2
CALL  DELAY
SBI   PORTD,3
CALL  DELAY
SBI   PORTD,4
CALL  DELAY
SBI   PORTD,5
CALL  DELAY
SBI   PORTD,6
CALL  DELAY
SBI   PORTD,7
CALL  DELAY
```

Notice unused portions of a port stay **undisturbed** — this single-bit addressability is one of the AVR's most powerful features.

---

## Table 4-9: Single-Bit Addressability of Ports

<div class="text-sm">

| PORT | PORTB | PORTC | PORTD | Port Bit |
|---|---|---|---|---|
| PA0 | PB0 | PC0 | PD0 | D0 |
| PA1 | PB1 | PC1 | PD1 | D1 |
| PA2 | PB2 | PC2 | PD2 | D2 |
| PA3 | PB3 | PC3 | PD3 | D3 |
| PA4 | PB4 | PC4 | PD4 | D4 |
| PA5 | PB5 | PC5 | PD5 | D5 |
| PA6 | PB6 | PC6 | PD6 | D6 |
| PA7 | PB7 | PC7 | PD7 | D7 |

</div>

* Each bit position (D0–D7) lines up identically across all four ports — bit 2 of Port A is PA2, bit 2 of Port B is PB2, and so on.

---
layout: two-cols
---

## Worked Example 4-3: Square Waves with SBI/CBI

**(a) 50% duty cycle on PC0** — "on" and "off" states have equal length:

```asm {*}{lines:true}
SBI    DDRC, 0     ;set bit 0 of DDRC (PC0 = out)
HERE:  SBI    PORTC, 0    ;PC0 = 1
       CALL   DELAY
       CBI    PORTC, 0    ;PC0 = 0
       CALL   DELAY
       RJMP   HERE        ;keep doing it
```

::right::

**(b) 66% duty cycle on PC3** — the "on" state is twice the "off" state:

```asm {*}{lines:true}
SBI    DDRC, 3     ;set bit 3 of DDRC (PC3 = out)
HERE:  SBI    PORTC, 3    ;PC3 = 1
       CALL   DELAY
       CALL   DELAY       ;on-time = 2 delays
       CBI    PORTC, 3    ;PC3 = 0
       CALL   DELAY       ;off-time = 1 delay
       RJMP   HERE
```

Doubling the number of `CALL DELAY`s before clearing the bit doubles the "on" portion of the period, changing the duty cycle from 50% to 66%.

---

## Checking an Input Pin: SBIC and SBIS

To branch based on the status of a single pin, use `SBIC` and `SBIS` — widely used for I/O decisions.

**SBIS (Skip if Bit in I/O register Set)** — tests the bit; skips the next instruction if it is HIGH:

```text
SBIS a,b   ->  1001 1011 aaaa abbb        0 <= a <= 31,  0 <= b <= 7
```

```asm
SBIS  PINB,2    ;skip next instruction if PB2 is HIGH
```

**SBIC (Skip if Bit in I/O register Cleared)** — tests the bit; skips the next instruction if it is LOW:

```text
SBIC a,b   ->  1001 1001 aaaa abbb        0 <= a <= 31,  0 <= b <= 7
```

```asm
SBIC  PINB,2    ;skip next instruction if PB2 is LOW
```

* Both instructions can test any bit of the lower 32 I/O registers — not just PINx — but I/O port operations are by far their most common use.

---

## Worked Example 4-4: SBIS — Monitor and Respond

**Problem:** (a) Keep monitoring PB2 until it goes HIGH. (b) When it does, write `$45` to Port C and send a HIGH-to-LOW pulse on PD3.

```asm {*}{lines:true,maxHeight:'320px'}
.INCLUDE "M32DEF.INC"
       CBI    DDRB, 2       ;make PB2 an input
       LDI    R16, 0xFF
       OUT    DDRC, R16     ;make Port C an output port
       SBI    DDRD, 3       ;make PD3 an output
AGAIN: SBIS   PINB, 2       ;skip if Bit PB2 is HIGH
       RJMP   AGAIN         ;keep checking if LOW
       LDI    R16, 0x45
       OUT    PORTC, R16    ;write 0x45 to Port C
       SBI    PORTD, 3      ;set bit PD3 (H-to-L)
       CBI    PORTD, 3      ;clear bit PD3
HERE:  RJMP   HERE
```

`SBIS PINB,2` stays in the loop as long as PB2 is LOW; once it goes HIGH, execution falls through to write `$45` to Port C and pulse PD3.

---
layout: image-right
backgroundSize: contain
image: /ch4_switch_buzzer_example.png
---

## Worked Example 4-5: SBIC — Door Alarm

**Problem:** Bit PB3 is an input representing a door sensor; LOW means the door is open. Whenever it goes LOW, send a HIGH-to-LOW pulse to PC5 to sound a buzzer.

```asm {*}{lines:true,maxHeight:'280px'}
.INCLUDE "M32DEF.INC"
       CBI    DDRB, 3     ;make PB3 an input
       SBI    DDRC, 5     ;make PC5 an output
HERE:  SBIC   PINB, 3     ;keep monitoring PB3 for HIGH
       RJMP   HERE        ;stay in the loop
       SBI    PORTC,5     ;make PC5 HIGH
       CBI    PORTC,5     ;make PC5 LOW (H-to-L pulse)
       RJMP   HERE
```

`SBIC` skips the branch back to `HERE` only once PB3 reads LOW (door open) — the opposite polarity from the SBIS example.

---

## Reading a Single Bit: Switch to LED

**Problem:** A switch is connected to PB0, an LED to PB7. Get the status of the switch and send it directly to the LED.

```asm {*}{lines:true}
.INCLUDE "M32DEF.INC"
       CBI    DDRB, 0    ;make PB0 an input
       SBI    DDRB, 7    ;make PB7 an output
AGAIN: SBIC   PINB,0     ;skip next if PB0 is clear
       RJMP   OVER       ;(JMP is OK too)
       CBI    PORTB,7
       RJMP   AGAIN
OVER:  SBI    PORTB,7
       RJMP   AGAIN
```

* A closely related variant (Example 4-9) instead **saves** the bit's status to a RAM location with `STS`, rather than mirroring it to an output pin — same `SBIC`/branch skeleton, different destination.

---

## Instruction Summary

<div class="text-sm">

| Instruction | Syntax | Effect |
|---|---|---|
| `OUT` | `OUT ioReg,Rn` | Write register `Rn` to an I/O register (8 bits at once) |
| `IN` | `IN Rn,ioReg` | Read an I/O register into register `Rn` (8 bits at once) |
| `SBI` | `SBI ioReg,bit` | Set one bit of a lower-32 I/O register HIGH |
| `CBI` | `CBI ioReg,bit` | Clear one bit of a lower-32 I/O register LOW |
| `SBIC` | `SBIC ioReg,bit` | Skip next instruction if the bit is 0 |
| `SBIS` | `SBIS ioReg,bit` | Skip next instruction if the bit is 1 |

</div>

* `SBI`/`CBI`/`SBIC`/`SBIS` never disturb any other bit of the register they operate on.
* They only work on I/O addresses **0–31** — which conveniently covers every `DDRx`, `PORTx`, and `PINx` register.

---

## Lecture Outline

<div class="text-sm">

1.  I/O Port Programming in AVR
    * AVR Ports and Their Three Registers (DDRx, PORTx, PINx)
    * Configuring Pins for Input vs. Output
    * Internal Pull-Up Resistors and the Four Pin States
    * Port A, B, C, and D and Their Alternate Functions
2.  **I/O Bit Manipulation Programming**
    * Single-Bit Addressability of I/O Ports
    * The SBI and CBI Instructions
    * The SBIC and SBIS Instructions
    * Worked Examples: Switches, LEDs, and a Buzzer

</div>

---
layout: default
---

## Summary

* Each AVR port has **three** registers: **DDRx** sets direction (1 = output, 0 = input), **PORTx** writes output data (or enables the pull-up when the pin is input), and **PINx** reads the actual pin state.
* Upon reset, all `DDRx` registers are `0x00`, so every AVR pin starts out as an **input**.
* The combination of PORTx/DDRx gives each pin **four states**: high-impedance input, pull-up input, output-0, and output-1.
* Ports A–D each occupy 8 pins and follow the identical DDRx/PORTx/PINx pattern; each also multiplexes alternate functions (ADC, timers, SPI, I²C, JTAG, USART, ...) that later chapters will use.
* The AVR's **single-bit addressability** — via `SBI`, `CBI`, `SBIC`, and `SBIS` — lets a program set, clear, or test one pin without disturbing the rest of the port; this only works on the lower 32 I/O registers.
* A 1-clock **synchronizer delay** means a `NOP` should precede an `IN` from a pin that was just reconfigured as input.

> **Caution (from the textbook):** Study the internal I/O circuitry (Appendix C, Section C-2) before wiring any external hardware to an AVR — using the wrong instruction or connection to a port pin can damage the chip.
