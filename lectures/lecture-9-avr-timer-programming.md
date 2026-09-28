---
theme: seriph
background: https://cover.sli.dev
transition: slide-left
layout: cover
title: Lecture 9 - AVR Timer Programming
---

# Lecture 9: AVR Timer Programming
## {{ $slidev.configs.subject }}
### Semester {{ $slidev.configs.semester }}
#### Presented by {{ $slidev.configs.presenter }}

---

## Lecture Outline

<div class="text-sm">

1.  **What Is a Timer/Counter?**
2.  Timers in the AVR
3.  Timer0: Normal Mode
4.  Prescaler and Large Delays
5.  Timer0: CTC Mode
6.  Timer2 vs. Timer0
7.  Timer1 (16-Bit Timer)
8.  Counting External Events

</div>

---

## Objectives

Upon completion of this chapter, you will be able to:

- Explain what a timer/counter register is and the four things it is generally used for
- List the timers available on the ATmega32 and their associated registers
- Program Timer0 in Normal mode to generate an accurate time delay
- Use the prescaler to reach delays far longer than a single 8-bit count allows
- Program Timer0 in CTC mode and explain why it is simpler than reloading `TCNT0` by hand
- Contrast Timer0, Timer1, and Timer2, including the 16-bit write hazard unique to Timer1
- Reconfigure a timer as an external event counter

---
layout: image-right
backgroundSize: contain
image: /ch9_timer_counter_concept.png
---

## Section 9.1: What Is a Timer/Counter?

* At its core, a timer/counter is a **register that increments by one on every input pulse**. What makes it useful is *where that pulse comes from*.

### A Simple Design: Counting People

* **First design**: a switch is pressed each time a person walks through a door — a pure event counter.
* **Second design**: feed the counter a pulse from the CPU's own clock instead — now it measures **elapsed time**, since a known pulse rate means a known count corresponds to a known duration.

Both designs use the identical hardware (Figure 9-1) — only the pulse source changes.

---

## The Four Uses of a Generic Timer/Counter

| Use | How |
|---|---|
| **Delay generating** | Feed it the CPU clock; wait for it to reach (or roll over past) a target value |
| **Counting** | Feed it pulses from an external pin; read the accumulated count |
| **Wave-form generating** | Toggle or set an output pin automatically each time the count reaches a target value |
| **Capturing** | Latch the current count the instant an external event occurs, to measure *when* it happened |

This chapter covers delay generation, counting, and simple waveform generation; input capture returns when we revisit Timer1 in a later chapter.

---

## Lecture Outline

<div class="text-sm">

1.  What Is a Timer/Counter?
2.  **Timers in the AVR**
3.  Timer0: Normal Mode
4.  Prescaler and Large Delays
5.  Timer0: CTC Mode
6.  Timer2 vs. Timer0
7.  Timer1 (16-Bit Timer)
8.  Counting External Events

</div>

---

## Section 9.2: Timers in the AVR

* Different AVR family members provide 1 to 6 timers. The **ATmega32** provides **3**: two 8-bit timers (**Timer0**, **Timer2**) and one 16-bit timer (**Timer1**).

## The Five Registers of Every AVR Timer

| Register | Role |
|---|---|
| `TCNTn` | **Timer/Counter register** — the counter itself; read or write it directly |
| `TCCRn` | **Control register** — clock source, prescaler, waveform-generation mode |
| `TOVn` | **Overflow flag** (in `TIFR`) — set when the counter rolls past its maximum |
| `OCRn` | **Output Compare Register** — a target value compared continuously against `TCNTn` |
| `OCFn` | **Compare Match flag** (in `TIFR`) — set when `TCNTn` equals `OCRn` |

All are ordinary, byte-addressable I/O registers — every bit-addressability trick from Chapter 6 applies directly. Bit *positions* differ between `TCCR0`, `TCCR1A/B`, and `TCCR2`, as the next sections show.

---

## Lecture Outline

<div class="text-sm">

1.  What Is a Timer/Counter?
2.  Timers in the AVR
3.  **Timer0: Normal Mode**
4.  Prescaler and Large Delays
5.  Timer0: CTC Mode
6.  Timer2 vs. Timer0
7.  Timer1 (16-Bit Timer)
8.  Counting External Events

</div>

---

## Section 9.3: Timer0 — Normal Mode

* In **Normal mode**, `TCNT0` counts up from whatever value it holds, all the way to `0xFF`, then rolls over to `0x00` and sets **`TOV0`** in `TIFR`. Software polls (or later, takes an interrupt on) `TOV0` to detect the rollover.

---

## Figure 9-5: `TCCR0` Bit Layout

$$
\begin{array}{|c|c|c|c|c|c|c|c|}
\hline
7 & 6 & 5 & 4 & 3 & 2 & 1 & 0 \\
\hline
\texttt{FOC0} & \texttt{WGM00} & \texttt{COM01} & \texttt{COM00} & \texttt{WGM01} & \texttt{CS02} & \texttt{CS01} & \texttt{CS00} \\
\hline
\end{array}
$$

<div class="text-sm">

| CS02:00 | Clock | · | WGM01:00 | Mode |
|---|---|---|---|---|
| `001` | `clk` (no prescale) | · | `00` | Normal |
| `010` / `011` | `clk/8` / `clk/64` | · | `01` | CTC |
| `100` / `101` | `clk/256` / `clk/1024` | · | `10` / `11` | PWM (Ch. 16) |
| `110` / `111` | External `T0` pin, falling/rising edge | · | | |

</div>

---

## Finding the Value to Load into `TCNT0`

1. Find the timer clock period: `T = 1 / F_timer` (with no prescaler, `F_timer = F_oscillator`).
2. Divide the desired delay by `T` — this is how many clocks are needed, `n`.
3. Load `TCNT0 = 256 - n`, so it overflows exactly after `n` counts.

```text
  $100
- $0E    (14 decimal = $0E)
------
  $F2    <- value to load into TCNT0
```

At `XTAL = 8 MHz`, `T = 0.125 µs`; a 14-clock wait needs `TCNT0 = 256 - 14 = 0xF2`.

---

## Example 9-1: A 14-Clock Wait, Normal Mode

```asm {*}{lines:true}
.INCLUDE "M32DEF.INC"
LDI  R16,0x20
OUT  DDRB,R16       ;PB5 as an output
LDI  R17,0
OUT  PORTB,R17
BEGIN:
LDI  R20,0xF2
OUT  TCNT0,R20       ;load Timer0
LDI  R20,0x01
OUT  TCCR0,R20       ;Timer0, Normal mode, internal clk, no prescale
AGAIN:
IN   R20,TIFR
SBRS R20,TOV0        ;skip next instruction if TOV0 is set
RJMP AGAIN
LDI  R20,(1<<TOV0)
OUT  TIFR,R20         ;clear TOV0 (write 1 to clear)
EOR  R17,R16          ;toggle bit 5
OUT  PORTB,R17
RJMP BEGIN
```

The timer-only delay is `14 × 0.125 µs = 1.75 µs`; surrounding instructions add further overhead not counted here.

---
layout: image-right
backgroundSize: contain
image: /ch9_timer0_normal_mode.png
---

## Figure 9-7: Timer0 Normal Mode

* `TCNT0` counts up linearly from its loaded value to `0xFF`, then rolls over to `0` and raises `TOV0`.
* Reloading the **same** starting value every round produces an evenly spaced train of overflow events — the basis of a repeating square wave.

### Example 9-7: A 12.5 µs Period on `PORTB.3`

At `XTAL = 8 MHz`, a 12.5 µs period needs a 6.25 µs half-period = 50 clocks, so `TCNT0 = 256 − 50 = 206 = 0xCE`.

---

## Example 9-9: Largest Delay, No Prescaler

* To get the *largest possible* delay with no prescaler, load `TCNT0 = 0` — it then counts the full range, `0x00`–`0xFF`, before overflowing.
* At `XTAL = 8 MHz`: `256 × 0.125 µs = 32 µs`, giving a square wave of `1 / (2 × 32 µs) = 15.625 kHz`.

Anything longer needs either the prescaler (next section) or a software loop wrapped around the timer.

---

## Lecture Outline

<div class="text-sm">

1.  What Is a Timer/Counter?
2.  Timers in the AVR
3.  Timer0: Normal Mode
4.  **Prescaler and Large Delays**
5.  Timer0: CTC Mode
6.  Timer2 vs. Timer0
7.  Timer1 (16-Bit Timer)
8.  Counting External Events

</div>

---

## Section 9.4: Prescaler and Generating a Large Time Delay

* An 8-bit timer with no prescaler maxes out at 256 clock periods — far too short for most real delays. The **prescaler** (`CS02:00`) divides the clock by 8, 64, 256, or 1024 *before* it reaches `TCNT0`, multiplying the maximum achievable delay by the same factor.
* Even the prescaler has a ceiling. For arbitrarily **large** delays, wrap the timer in a **software counting loop**, exactly as Chapter 3 wrapped `NOP`s in a loop — each pass contributes one fixed timer "quantum," and the outer loop counter multiplies it as many times as needed.

```asm {*}{lines:true}
LDI  R18,100          ;outer loop count -- multiplies the timer delay by 100
AGAIN2:
LDI  R20,206
OUT  TCNT0,R20
LDI  R20,0x01
OUT  TCCR0,R20
WAIT:
IN   R20,TIFR
SBRS R20,TOV0
RJMP WAIT
LDI  R20,(1<<TOV0)
OUT  TIFR,R20
DEC  R18
BRNE AGAIN2
```

---

## Lecture Outline

<div class="text-sm">

1.  What Is a Timer/Counter?
2.  Timers in the AVR
3.  Timer0: Normal Mode
4.  Prescaler and Large Delays
5.  **Timer0: CTC Mode**
6.  Timer2 vs. Timer0
7.  Timer1 (16-Bit Timer)
8.  Counting External Events

</div>

---

## Section 9.5: CTC (Clear Timer on Compare Match) Mode

* In Normal mode, software must reload `TCNT0` by hand after every overflow. **CTC mode** removes that step: `TCNT0` still counts from 0, but compares against **`OCR0`** instead of a fixed `0xFF`. The moment `TCNT0 == OCR0`, hardware sets **`OCF0`** and *automatically resets `TCNT0` to 0* — no manual reload, ever.
* Selected via `WGM01:00 = 01`.

### Example: Rewriting the 12.5 µs Period with CTC

At `XTAL = 8 MHz`, a 6.25 µs half-period needs 50 counts from 0, i.e. `OCR0 = 49` (CTC counts `OCR0 + 1` total states).

```asm {*}{lines:true}
.INCLUDE "M32DEF.INC"
LDI  R16,0x08
OUT  DDRB,R16         ;PB3 as an output
LDI  R17,0
OUT  PORTB,R17
LDI  R20,49
OUT  OCR0,R20          ;compare target
BEGIN:
LDI  R20,0x09
OUT  TCCR0,R20         ;Timer0, CTC mode, internal clk, no prescale
AGAIN:
IN   R20,TIFR
SBRS R20,OCF0
RJMP AGAIN
LDI  R20,(1<<OCF0)
OUT  TIFR,R20          ;clear OCF0
EOR  R17,R16
OUT  PORTB,R17
RJMP BEGIN
```

---

## The Same Example, in C

```c {*}{lines:true}
DDRB |= 1 << 3;
PORTB &= ~(1 << 3);
while (1) {
    OCR0 = 49;
    TCCR0 = 0x09;
    while ((TIFR & (1 << OCF0)) == 0);
    TIFR = (1 << OCF0);
    PORTB ^= (1 << 3);
}
```

The two versions produce equivalent Flash code; the C compiler generates the same poll-and-clear sequence from the `while` loop.

---

## Lecture Outline

<div class="text-sm">

1.  What Is a Timer/Counter?
2.  Timers in the AVR
3.  Timer0: Normal Mode
4.  Prescaler and Large Delays
5.  Timer0: CTC Mode
6.  **Timer2 vs. Timer0**
7.  Timer1 (16-Bit Timer)
8.  Counting External Events

</div>

---

## Section 9.6: Timer2 vs. Timer0

* **Timer2** is register-for-register the same shape as Timer0 — `TCNT2`, `TCCR2`, `TOV2`, `OCR2`, `OCF2` — with the identical bit layout (`FOC2`, `WGM20`, `COM21:20`, `WGM21`, `CS22:20`) and the same Normal/CTC/PWM modes.

## Two Differences from Timer0

| | Timer0 | Timer2 |
|---|---|---|
| Prescaler options | `/8, /64, /256, /1024` | `/8, /32, /64, /128, /256, /1024` |
| External clock role of `CS_2:0 = 110/111` | Selects an **external event** on the `T0` pin (counter mode) | Selects the **async RTC** clock source instead (via `AS2` in `ASSR`) |

* Setting `AS2 = 1` in the **`ASSR`** register feeds Timer2 from a 32.768 kHz watch crystal on `TOSC1`/`TOSC2`, letting it keep real-time-clock-accurate time completely independently of the main system clock — a capability Timer0 does not have.

---

## Lecture Outline

<div class="text-sm">

1.  What Is a Timer/Counter?
2.  Timers in the AVR
3.  Timer0: Normal Mode
4.  Prescaler and Large Delays
5.  Timer0: CTC Mode
6.  Timer2 vs. Timer0
7.  **Timer1 (16-Bit Timer)**
8.  Counting External Events

</div>

---

## Section 9.7: Timer1 — the 16-Bit Timer

* Timer1's registers are 16 bits, split into high/low byte pairs: `TCNT1H:TCNT1L`, `OCR1AH:OCR1AL`, `OCR1BH:OCR1BL`. It has *two* independent output-compare units, `A` and `B`, plus an auxiliary 16-bit **`ICR1`** register used for input capture.
* Clock selection uses the same bit pattern as Timer0, via `CS12:10` in `TCCR1B`.
* Being 16 bits wide, Timer1 alone can time delays up to 65,536 clocks — no software loop needed for delays that would overflow an 8-bit timer many times over.

---
layout: image-right
backgroundSize: contain
image: /ch9_temp_register.png
---

## Figure 9-22: The Shared `TEMP` Register

* The AVR's internal data bus is only 8 bits wide, so a 16-bit register cannot be written atomically in one step. A hidden **`TEMP`** register bridges the gap:
  1. Write the **high byte** first — latched silently into `TEMP`.
  2. Write the **low byte** next — this triggers hardware to write **both** bytes into the real register **together**.
* **Always write high byte, then low byte** — the reverse order silently corrupts the value.
* Reading follows the mirror rule: read the **low** byte first (it copies the high byte into `TEMP`), then read the high byte from `TEMP`.

---

## Example: Toggle `PB5` Every 1 ms, Normal Mode (`XTAL = 8 MHz`)

* 1 ms at 8 MHz = 8000 clocks. `TCNT1` must be loaded with `65536 − 8000 = 57536 = 0xE0C0`.

```asm {*}{lines:true}
.INCLUDE "M32DEF.INC"
LDI  R16,HIGH(RAMEND)
OUT  SPH,R16
LDI  R16,LOW(RAMEND)
OUT  SPL,R16
SBI  DDRB,5               ;PB5 as an output
BEGIN:
SBI  PORTB,5               ;PB5 = 1
RCALL DELAY_1ms
CBI  PORTB,5               ;PB5 = 0
RCALL DELAY_1ms
RJMP BEGIN

DELAY_1ms:
LDI  R20,HIGH(65536-8000)
OUT  TCNT1H,R20            ;high byte -> TEMP
LDI  R20,LOW(65536-8000)
OUT  TCNT1L,R20            ;low byte -> triggers the 16-bit write
LDI  R20,0x00
OUT  TCCR1A,R20            ;Normal mode
LDI  R20,0x01
OUT  TCCR1B,R20            ;clk, no prescale
AGAIN:
IN   R20,TIFR
SBRS R20,TOV1
RJMP AGAIN
LDI  R20,(1<<TOV1)
OUT  TIFR,R20               ;clear TOV1
RET
```

---

## CTC Mode on Timer1

* Instead of reloading `TCNT1` every period, CTC mode holds a fixed target in `OCR1A` and never needs a reload — the 16-bit counterpart of Timer0's CTC mode.

```asm {*}{lines:true}
LDI  R20,HIGH(7811)
OUT  OCR1AH,R20
LDI  R20,LOW(7811)
OUT  OCR1AL,R20            ;OCR1A = 7811
LDI  R20,0x00
OUT  TCCR1A,R20
LDI  R20,0x0D
OUT  TCCR1B,R20            ;CTC mode, prescaler 1:1024
AGAIN:
IN   R20,TIFR
SBRS R20,OCF1A
RJMP AGAIN
LDI  R20,(1<<OCF1A)
OUT  TIFR,R20               ;clear OCF1A
```

At `XTAL = 8 MHz` with a 1:1024 prescaler, `T_clock = 128 µs`, so `1 s / 128 µs ≈ 7812` clocks, giving `OCR1A = 7811`. Because a 16-bit `OCR1A` can directly hold much longer periods than `OCR0`/`OCR2` ever could, long precise waveforms are normally generated on Timer1.

---

## Lecture Outline

<div class="text-sm">

1.  What Is a Timer/Counter?
2.  Timers in the AVR
3.  Timer0: Normal Mode
4.  Prescaler and Large Delays
5.  Timer0: CTC Mode
6.  Timer2 vs. Timer0
7.  Timer1 (16-Bit Timer)
8.  **Counting External Events**

</div>

---

## Section 9.8: Counting External Events

* Selecting the **external clock** options of `CS02:00` (or `CS12:10`) reconfigures a timer from a *time-measuring* device into an *event counter*: every pulse on the timer's dedicated input pin (`T0` for Timer0, `T1` for Timer1) increments `TCNTn` instead of the internal clock.

### Counting Pulses on `T0`, Displaying on `PORTC`

```asm {*}{lines:true}
.INCLUDE "M32DEF.INC"
CBI  DDRB,0            ;make T0 (PB0) an input
LDI  R20,0xFF
OUT  DDRC,R20            ;make PORTC an output
LDI  R20,0x06
OUT  TCCR0,R20            ;external clock on T0, falling edge (counter mode)
AGAIN:
IN   R20,TCNT0
OUT  PORTC,R20            ;PORTC always shows the live pulse count
RJMP AGAIN
```

---

## Counter 1 in CTC Mode — a Pulse Every 100 Input Events

```asm {*}{lines:true}
.INCLUDE "M32DEF.INC"
CBI  DDRB,1              ;make T1 (PB1) an input
SBI  DDRC,0               ;PC0 as an output
LDI  R20,0x0
OUT  TCCR1A,R20
LDI  R20,0x0E
OUT  TCCR1B,R20            ;CTC mode, external clock on T1, falling edge
LDI  R20,0
OUT  OCR1AH,R20
LDI  R20,99
OUT  OCR1AL,R20            ;OCR1A = 99 -> compare match every 100 pulses
AGAIN:
IN   R20,TIFR
SBRS R20,OCF1A
RJMP AGAIN
LDI  R20,(1<<OCF1A)
OUT  TIFR,R20               ;clear OCF1A
SBI  PORTC,0
CBI  PORTC,0                ;a brief pulse on PC0 every 100 input events
RJMP AGAIN
```

---

## Summary

* A **timer/counter** is just a register that increments on every input pulse; the pulse source (internal clock vs. an external pin) is what turns it into a *delay generator* or an *event counter*.
* The ATmega32 has **three timers**: 8-bit **Timer0**, 8-bit **Timer2**, and 16-bit **Timer1**, sharing the same five-register pattern (`TCNTn`, `TCCRn`, `TOVn`, `OCRn`, `OCFn`) — but each `TCCRn`'s bit *positions* differ.
* **Normal mode** counts to the top and rolls over, setting `TOVn`; software reloads the count by hand each round.
* The **prescaler** extends the achievable delay; a software loop around the timer extends it further still.
* **CTC mode** compares `TCNTn` against `OCRn` and auto-resets on a match — no manual reload, the simpler choice for a fixed, repeating period.
* **Timer2** mirrors Timer0 but adds an asynchronous, watch-crystal-driven RTC mode (`AS2`) that Timer0 lacks.
* **Timer1** is 16 bits wide; writing any of its registers **must** go high byte, then low byte, because of the shared internal `TEMP` latch.
* Any timer becomes a **pulse counter** by selecting the external-clock option of its clock-select bits.
