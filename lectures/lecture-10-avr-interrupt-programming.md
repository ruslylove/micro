---
theme: seriph
background: https://cover.sli.dev
transition: slide-left
layout: cover
title: Lecture 10 - AVR Interrupt Programming
---

# Lecture 10: AVR Interrupt Programming
## {{ $slidev.configs.subject }}
### Semester {{ $slidev.configs.semester }}
#### Presented by {{ $slidev.configs.presenter }}

---

## Lecture Outline

<div class="text-sm">

1.  **Polling vs. Interrupt**
2.  The Interrupt Vector Table
3.  Steps in Executing an Interrupt
4.  Programming Timer Interrupts
5.  External Hardware Interrupts
6.  Interrupt Priority and Nested Interrupts
7.  Task Switching, Resource Conflict, and Context Saving
8.  Interrupt Programming in C

</div>

---

## Objectives

Upon completion of this chapter, you will be able to:

- Contrast polling and interrupts, and explain when each is the better choice
- Read the AVR interrupt vector table and describe the hardware steps taken when an interrupt fires
- Enable a timer interrupt and write its ISR, in place of polling a flag
- Configure an external interrupt for edge- or level-triggered operation
- Explain interrupt priority and why "interrupt inside an interrupt" does not happen by default
- Identify register-conflict hazards between an ISR and the main program, and fix them with context saving
- Write interrupt-driven C programs using `avr/interrupt.h`

---

## Section 10.1: Polling vs. Interrupt

* Every prior chapter used **polling**: sit in a tight loop, repeatedly checking a flag bit, until it becomes true.

```c
while (1) {
    if (PIND & (1 << 2))
        ;   // do something
}
```

* Polling **ties down the CPU** — it can do nothing else while waiting, and if two events need servicing, one may be missed while the CPU is busy polling for the other.
* An **interrupt** flips this: the CPU runs its normal `main()` work, and hardware itself notifies the CPU — interrupts it — exactly when the event of interest occurs.
* Interrupts are efficient (no CPU time wasted waiting), can be given a **priority** relative to one another, and can be individually **masked** — none of which polling offers.

---

## Lecture Outline

<div class="text-sm">

1.  Polling vs. Interrupt
2.  **The Interrupt Vector Table**
3.  Steps in Executing an Interrupt
4.  Programming Timer Interrupts
5.  External Hardware Interrupts
6.  Interrupt Priority and Nested Interrupts
7.  Task Switching, Resource Conflict, and Context Saving
8.  Interrupt Programming in C

</div>

---

## Section 10.2: The Interrupt Vector Table

* Every interrupt source has a **fixed address** near the bottom of Flash — its **interrupt vector**. When that interrupt fires, the CPU jumps there automatically; no software lookup is involved.

---

## Table 10-1: ATmega32 Interrupt Vector Table

<div class="text-sm grid grid-cols-2 gap-x-8">

| Interrupt | Addr. |
|---|---|
| Reset | `0000` |
| `INT0` | `0002` |
| `INT1` | `0004` |
| `INT2` | `0006` |
| Timer2 Compare | `0008` |
| Timer2 Overflow | `000A` |
| Timer1 Capture | `000C` |
| Timer1 Compare A | `000E` |

| Interrupt | Addr. |
|---|---|
| Timer1 Compare B | `0010` |
| Timer1 Overflow | `0012` |
| Timer0 Compare | `0014` |
| Timer0 Overflow | `0016` |
| SPI Transfer | `0018` |
| USART RX/UDRE/TX | `001A–001E` |
| ADC Conversion | `0020` |
| EEPROM Ready | `0022` |

</div>

Since only 2 words (4 bytes) sit between vectors, an ISR is normally too big to fit in place — so a `JMP` to the real handler is placed at the vector instead (Program 10-1, next section).

---

## Lecture Outline

<div class="text-sm">

1.  Polling vs. Interrupt
2.  The Interrupt Vector Table
3.  **Steps in Executing an Interrupt**
4.  Programming Timer Interrupts
5.  External Hardware Interrupts
6.  Interrupt Priority and Nested Interrupts
7.  Task Switching, Resource Conflict, and Context Saving
8.  Interrupt Programming in C

</div>

---

## Section 10.3: Steps in Executing an Interrupt

When an enabled interrupt fires, the AVR hardware automatically:

1. **Finishes** the instruction currently in progress.
2. **Pushes** the current Program Counter onto the stack.
3. **Jumps** to the interrupt's fixed vector address.
4. **Clears the global interrupt flag** (`I`, bit 7 of `SREG`) — disabling further interrupts while this one is serviced.
5. Executes the **Interrupt Service Routine (ISR)**.
6. **`RETI`** at the end pops the saved PC back off the stack *and* **re-sets `I`**, resuming the interrupted program.

Step 4 is why a second interrupt normally cannot preempt the first: the global enable turns off automatically on entry, and stays off until `RETI`.

---
layout: image-right
backgroundSize: contain
image: /ch6_sreg_bits.png
---

## Enabling Interrupts

Two independent switches must both be "on" for an interrupt to fire:

1. **The global flag `I`** (bit 7 of `SREG`) — `SEI`/`sei()` to set, `CLI`/`cli()` to clear.
2. **The source's own enable bit** — in `GICR` (external interrupts) or `TIMSK` (timer interrupts).

Forgetting either is the most common interrupt bug.

---

## Figure 10-3: `TIMSK` Bit Layout

$$
\begin{array}{|c|c|c|c|c|c|c|c|}
\hline
7 & 6 & 5 & 4 & 3 & 2 & 1 & 0 \\
\hline
\texttt{OCIE2} & \texttt{TOIE2} & \texttt{TICIE1} & \texttt{OCIE1A} & \texttt{OCIE1B} & \texttt{TOIE1} & \texttt{OCIE0} & \texttt{TOIE0} \\
\hline
\end{array}
$$

Each bit enables one timer event: `TOIEn` = overflow, `OCIEn` = compare match, `TICIE1` = Timer1 input capture. All must still be combined with the global `I` flag (`SEI`) to actually fire.

---

## Lecture Outline

<div class="text-sm">

1.  Polling vs. Interrupt
2.  The Interrupt Vector Table
3.  Steps in Executing an Interrupt
4.  **Programming Timer Interrupts**
5.  External Hardware Interrupts
6.  Interrupt Priority and Nested Interrupts
7.  Task Switching, Resource Conflict, and Context Saving
8.  Interrupt Programming in C

</div>

---
layout: image-right
backgroundSize: contain
image: /ch10_toie0_gate.png
---

## Section 10.4: Programming Timer Interrupts

* Figure 10-4 shows the actual logic: `TOV0` **AND** `TOIE0` produces the request; that request **AND** the global `I` flag is what finally routes control to vector `$0016`.
* This replaces `SBRS ..,TOV0` polling with hardware notification — the CPU is free to do other work (Program 10-1, next slide) until the vector fires.

---

## Program 10-1: Timer0 Overflow, Interrupt-Driven

The same square-wave-plus-background-task pattern from Chapter 9, now interrupt-driven: Timer0 toggles `PORTB.5` in the background while `main()` continuously copies `PINC` to `PORTD`.

```asm {*}{lines:true}
.INCLUDE "M32DEF.INC"
.ORG 0x000
        JMP MAIN
.ORG 0x016                 ;vector for Timer0 overflow
        JMP T0_OV_ISR

.ORG 0x100
MAIN:   LDI  R20,HIGH(RAMEND)
        OUT  SPH,R20
        LDI  R20,LOW(RAMEND)
        OUT  SPL,R20
        SBI  DDRB,5             ;PB5 = output
        LDI  R20,(1<<TOIE0)
        OUT  TIMSK,R20          ;enable Timer0 overflow interrupt
        SEI                      ;set I (enable interrupts globally)
        LDI  R20,-32             ;short demonstration period
        OUT  TCNT0,R20
        LDI  R20,0x01
        OUT  TCCR0,R20           ;Normal mode, internal clk
        LDI  R20,0x00
        OUT  DDRC,R20            ;PORTC input
        LDI  R20,0xFF
        OUT  DDRD,R20            ;PORTD output
HERE:   IN   R20,PINC
        OUT  PORTD,R20           ;background task -- runs continuously
        JMP  HERE
```

---

## Program 10-1: the ISR

```asm {*}{lines:true}
.ORG 0x200
T0_OV_ISR:
        IN   R16,PORTB
        LDI  R17,0x20
        EOR  R16,R17             ;toggle bit 5
        OUT  PORTB,R16
        LDI  R16,-32
        OUT  TCNT0,R16           ;reload for next round
        RETI
```

`RETI` — not `RET` — must end an ISR: it also re-sets the `I` flag so the AVR accepts further interrupts. The AVR clears `TOV0` automatically on entry, so the ISR needs no explicit flag-clear.

---

## Compare-Match Interrupt — No Manual Reload Needed

CTC mode's automatic `TCNT0` reset (Chapter 9.5) carries over to interrupts too — the ISR only has to toggle the pin:

```asm {*}{lines:true}
.ORG 0x000
        JMP MAIN
.ORG 0x014                  ;vector for Timer0 compare match
        JMP T0_CM_ISR

.ORG 0x100
MAIN:   LDI  R20,HIGH(RAMEND)
        OUT  SPH,R20
        LDI  R20,LOW(RAMEND)
        OUT  SPL,R20
        LDI  R20,39
        OUT  OCR0,R20
        LDI  R20,0x09
        OUT  TCCR0,R20            ;CTC mode, internal clk -- starts Timer0
        SBI  DDRB,5                 ;PB5 as an output
        LDI  R20,(1<<OCIE0)
        OUT  TIMSK,R20              ;enable Timer0 compare-match interrupt
        SEI
HERE:   JMP  HERE

T0_CM_ISR:
        IN   R16,PORTB
        LDI  R17,0x20
        EOR  R16,R17
        OUT  PORTB,R16
        RETI
```

---

## Lecture Outline

<div class="text-sm">

1.  Polling vs. Interrupt
2.  The Interrupt Vector Table
3.  Steps in Executing an Interrupt
4.  Programming Timer Interrupts
5.  **External Hardware Interrupts**
6.  Interrupt Priority and Nested Interrupts
7.  Task Switching, Resource Conflict, and Context Saving
8.  Interrupt Programming in C

</div>

---

## Section 10.5: External Interrupts — Edge vs. Level Triggering

* Pins `PD2`, `PD3`, and `PB2` double as `INT0`, `INT1`, and `INT2` once enabled in `GICR`.

## `MCUCR` — `INT0`/`INT1` Sense Control (`ISCn1:n0`)

| ISC_1 | ISC_0 | Triggers on |
|---|---|---|
| 0 | 0 | Low level (fires continuously while the pin is low) |
| 0 | 1 | Any logical change |
| 1 | 0 | Falling edge |
| 1 | 1 | Rising edge |

* **Level-triggered**: keeps firing as long as the pin stays at the active level. **Edge-triggered**: fires exactly once per transition — the usual choice for a one-shot event such as a button press.

---

## Example: Toggle `PORTC.3` on Every Low Level of `INT0`

`INT0` (`PD2`) is normally high, wired to a switch that pulls it low; level-triggered mode.

```asm {*}{lines:true}
.INCLUDE "M32DEF.INC"
.ORG 0x000
        JMP MAIN
.ORG 0x002               ;vector for external INT0
        JMP EX0_ISR

.ORG 0x100
MAIN:   LDI  R20,HIGH(RAMEND)
        OUT  SPH,R20
        LDI  R20,LOW(RAMEND)
        OUT  SPL,R20
        SBI  DDRC,3            ;PC3 as an output
        SBI  PORTD,2           ;pull-up activated on INT0 pin
        LDI  R20,1<<INT0
        OUT  GICR,R20          ;enable INT0
        SEI                     ;set I (globally enable interrupts)
HERE:   JMP  HERE

EX0_ISR:
        IN   R21,PORTC
        LDI  R22,0x08
        EOR  R21,R22           ;toggle bit 3
        OUT  PORTC,R21
        RETI
```

---

## The Same Example, in C

```c {*}{lines:true}
GICR = (1 << INT0);   // enable external interrupt 0, level-triggered
sei();

ISR(INT0_vect)
{
    PORTC ^= (1 << 3);   // toggle PORTC.3
}
```

---

## Lecture Outline

<div class="text-sm">

1.  Polling vs. Interrupt
2.  The Interrupt Vector Table
3.  Steps in Executing an Interrupt
4.  Programming Timer Interrupts
5.  External Hardware Interrupts
6.  **Interrupt Priority and Nested Interrupts**
7.  Task Switching, Resource Conflict, and Context Saving
8.  Interrupt Programming in C

</div>

---

## Section 10.6: Interrupt Priority

* When two or more interrupts are pending at the same instant, the AVR services them in a **fixed priority order set by their position in the vector table** — the lower the address, the **higher** the priority.
* From Table 10-1: `INT0` (`0002`) outranks Timer0 Compare (`0014`), which outranks Timer0 Overflow (`0016`). If several become pending simultaneously, the lowest-address one runs first.

## Interrupt Inside an Interrupt

* Step 4 of Section 10.3 means entering *any* ISR automatically clears `I` — so **by default, an ISR cannot itself be interrupted**. A second, even higher-priority interrupt simply waits until the current ISR's `RETI`.
* Nesting is possible only if the ISR *explicitly* re-enables interrupts with `SEI` partway through — an advanced technique that reintroduces exactly the re-entrancy concerns the automatic `I`-clear was protecting against.

---

## Lecture Outline

<div class="text-sm">

1.  Polling vs. Interrupt
2.  The Interrupt Vector Table
3.  Steps in Executing an Interrupt
4.  Programming Timer Interrupts
5.  External Hardware Interrupts
6.  Interrupt Priority and Nested Interrupts
7.  **Task Switching, Resource Conflict, and Context Saving**
8.  Interrupt Programming in C

</div>

---

## Section 10.7: Task Switching and Resource Conflict

* An ISR runs *asynchronously* to `main()` — it can interrupt at literally any instruction. If both `main()` and an ISR use the **same register** for unrelated purposes, the ISR silently corrupts whatever `main()` was keeping there.
* Example: if `main()` is mid-calculation in `R20` when a Timer0 ISR that also uses `R20` fires, `main()` resumes with garbage in `R20` — an intermittent, timing-dependent bug that is notoriously hard to reproduce.

## Two Solutions

* **Different registers per task** — simplest, but the AVR has only 32 GPRs shared across every task and ISR in the program.
* **Context saving** — `PUSH` every register the ISR uses at its start, `POP` them back before `RETI`. The ISR's register use becomes invisible to the interrupted code.

---

## Context Saving in Practice

```asm {*}{lines:true}
T0_CM_ISR:
        PUSH R20          ;save R20 -- context saving begins
        IN   R20,PIND
        OUT  PORTD,R20
        POP  R20          ;restore R20 -- context saving ends
        RETI
```

* An ISR that changes **flags** (arithmetic, `CP`, `AND`, …) must also save **`SREG`**, or it silently corrupts flags `main()` still depends on right after the interrupted instruction.

```asm {*}{lines:true}
T0_CM_ISR:
        PUSH R20
        IN   R20,SREG
        PUSH R20          ;SREG is now safely on the stack
        ; ... ISR body, free to use flags ...
        POP  R20
        OUT  SREG,R20     ;restore SREG exactly as it was
        POP  R20
        RETI
```

**Order matters**: save `SREG` *after* the register holding it is itself saved, and restore it *before* that register is popped back.

---

## Lecture Outline

<div class="text-sm">

1.  Polling vs. Interrupt
2.  The Interrupt Vector Table
3.  Steps in Executing an Interrupt
4.  Programming Timer Interrupts
5.  External Hardware Interrupts
6.  Interrupt Priority and Nested Interrupts
7.  Task Switching, Resource Conflict, and Context Saving
8.  **Interrupt Programming in C**

</div>

---

## Section 10.8: Interrupt Programming in C

* `<avr/interrupt.h>` replaces manual `.ORG`-and-`JMP` vector placement with one macro: **`ISR(vector_name)`**. The compiler places the routine at the correct vector automatically, and generates the register/`SREG` save-and-restore prologue and epilogue for you.
* `sei()`/`cli()` are the C equivalents of `SEI`/`CLI`.

## Table 10-3: Selected WinAVR Vector Names

<div class="text-sm">

| Interrupt | Vector name |
|---|---|
| External `INT0` / `INT1` / `INT2` | `INT0_vect` / `INT1_vect` / `INT2_vect` |
| Timer0 Overflow / Compare | `TIMER0_OVF_vect` / `TIMER0_COMP_vect` |
| Timer1 Overflow / Compare A | `TIMER1_OVF_vect` / `TIMER1_COMPA_vect` |

</div>

---

## Example: Timer1, CTC Mode, Toggle `PB5` Every Second (`XTAL = 8 MHz`)

Reusing Chapter 9's Timer1 CTC calculation directly: `T_clock = 128 µs` at prescaler 1:1024, so `OCR1A = 7811` for a 1-second interval.

```c {*}{lines:true}
#include <avr/io.h>
#include <avr/interrupt.h>

int main(void)
{
    DDRB |= (1 << 5);             // PB5 as an output
    OCR1A  = 7811;                 // 1 s at 8 MHz, prescaler 1:1024
    TCCR1A = 0x00;
    TCCR1B = 0x0D;                 // CTC mode, prescaler 1:1024
    TIMSK |= (1 << OCIE1A);        // enable Timer1 compare-match A interrupt
    sei();
    DDRC = 0x00;
    DDRD = 0xFF;
    while (1)
        PORTD = PINC;               // background task
}

ISR(TIMER1_COMPA_vect)
{
    PORTB ^= (1 << 5);              // toggle PORTB.5 once per second
}
```

---

## Summary

* **Polling** wastes CPU time waiting in a loop; **interrupts** let hardware notify the CPU exactly when an event occurs.
* Every interrupt source has a **fixed vector address** (Table 10-1); the hardware jumps there automatically, clears `I`, and `RETI` both returns and re-enables interrupts.
* Both the **global enable** (`SEI`/`sei()`) and the **source's own enable bit** (`GICR`/`TIMSK`) must be set for an interrupt to fire.
* Timer overflow/compare-match interrupts move Chapter 9's polling loops into an `ISR`, freeing `main()` for other work; external interrupts add **edge-** vs. **level-triggered** sensing via `MCUCR`.
* **Priority** follows vector address order; an ISR cannot be interrupted by default, since entering it clears `I` — true nesting needs an explicit `SEI` inside the ISR.
* Registers (and `SREG`, if flags are touched) shared between `main()` and an ISR need **`PUSH`/`POP`-based context saving**, in the correct save/restore order.
* `avr-libc`'s `ISR()` macro and `sei()`/`cli()` handle vector placement and context saving automatically.
