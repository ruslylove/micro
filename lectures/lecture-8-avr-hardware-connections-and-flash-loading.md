---
theme: seriph
background: https://cover.sli.dev
transition: slide-left
layout: cover
title: Lecture 8 - AVR Hardware Connections and Flash Loading
---

# Lecture 8: AVR Hardware Connections and Flash Loading
## {{ $slidev.configs.subject }}
### Semester {{ $slidev.configs.semester }}
#### Presented by {{ $slidev.configs.presenter }}

---

## Lecture Outline

<div class="text-sm">

1.  **AVR Pins**
2.  AVR Simplest Connection
3.  Fuse Bits and Clock Source
4.  Fuse Bits and Startup Time
5.  What Is Inside a HEX File?
6.  Loading a HEX File into Flash

</div>

---

## Objectives

Upon completion of this chapter, you will be able to:

- Identify the power, oscillator, reset, and analog-reference pins of the ATmega32 and explain the role of each
- Draw the minimum external circuit needed to bring up an AVR chip
- Explain what fuse bits are, why they are separate from the user program, and the "golden rule" for handling them safely
- Select the clock-source and startup-time fuse settings appropriate for a given crystal
- Parse the structure of an Intel HEX file record by record
- Compare the four ways a HEX file can be loaded into Flash: parallel programming, ISP, JTAG, and a bootloader

---

## Section 8.1: AVR Pins

* Every feature the AVR core supports must ultimately connect to the outside world through 40 physical pins (on the DIP-40 ATmega32). Before writing another line of code, we need to know what each pin is *for*.

<div class="text-sm">

| Pin(s) | Function |
|---|---|
| `RESET` | Clears all registers and restarts program execution from address 0 |
| `VCC` / `GND` (×2 pairs) | Supply voltage — must be connected to +5 V and ground |
| `XTAL1` / `XTAL2` | Connect an external crystal or RC oscillator to generate the clock |
| `AREF` | Reference voltage for the on-chip ADC |
| `AVCC` | Supply voltage for the ADC and Port A — normally tied to `VCC` |
| `PORTA`–`PORTD` | 32 general-purpose I/O pins, many with alternate peripheral functions |

</div>

---
layout: image-right
backgroundSize: contain
image: /ch4_atmega32_pin_diagram.png
---

## Figure 8-1: The ATmega32 Pinout

* Ports A–D provide the 32 general-purpose I/O pins introduced in Chapter 4.
* Many pins double as peripheral signals once enabled — e.g. `PD2`/`PD3` become `INT0`/`INT1` (Ch. 10), `PB3` becomes `OC0` (Ch. 9), Port A doubles as the 8 ADC channels.
* Two `VCC`/`GND` pairs exist for stable power distribution around a 40-pin die — both pairs must be connected.

---

## Section 8.2: AVR Simplest Connection

The minimum circuit needed to bring an ATmega32 to life has four parts:

1. **Power**: both `VCC` pairs to +5 V, both `GND` pairs to ground.
2. **Reset**: `RESET` pulled high through a 10 kΩ resistor, with an optional push-button to ground for a manual reset.
3. **Clock**: a crystal across `XTAL1`/`XTAL2`, each leg also tied to ground through a small capacitor (e.g. 22 pF) — or, if the internal RC oscillator fuse is selected, `XTAL1`/`XTAL2` can be left unconnected.
4. **Analog supply**: `AVCC` tied to `VCC`, even if the ADC is unused.

The course's MDE AVR32 Trainer board wires exactly this circuit, plus an on-board ISP header, so the labs can focus on software.

---
layout: image-right
backgroundSize: contain
image: /ch8_minimum_connection.png
---

## Figure 8-2: Minimum Connection

* `VCC` and `AVCC` (pins 10, 30) both go to +5 V; `GND` (pins 11, 31) both go to ground.
* A 10 kΩ pull-up holds `RESET` (pin 9) high; the switch pulls it low on demand.
* The crystal sits across `XTAL1`/`XTAL2` (pins 13, 12), each leg decoupled to ground by a 22 pF capacitor.

---

## Lecture Outline

<div class="text-sm">

1.  AVR Pins
2.  AVR Simplest Connection
3.  **Fuse Bits and Clock Source**
4.  Fuse Bits and Startup Time
5.  What Is Inside a HEX File?
6.  Loading a HEX File into Flash

</div>

---

## Section 8.3: Fuse Bits

* Unlike the program in Flash, **fuse bits configure the chip's hardware behavior itself** — clock source, brown-out detection, boot section size, and more. They are not part of the user program and are untouched by ordinary Flash erase/reload.
* The ATmega32 has two fuse bytes — **High** and **Low** — plus 4 separate lock bits (code-protection, not covered here).

### The Golden Rule of Fuse Bits

* A fuse bit's *unprogrammed* (factory-default) state reads as **1**; programming ("burning") it sets it to **0** — the reverse of ordinary I/O bit conventions.
* **Always double-check a fuse setting before programming it.** For example, clearing `SPIEN` to 0 disables SPI/ISP programming mode entirely — the chip can no longer be reprogrammed by the everyday method, and recovery needs parallel (high-voltage) programming.

---
layout: two-cols-header
---

## Table 8-6 & 8-7: The Two Fuse Bytes (abbreviated)

::left::

**High Fuse Byte**

<div class="text-sm">

| Bit | Selects |
|---|---|
| `OCDEN` | On-chip debug |
| `JTAGEN` | JTAG interface |
| `SPIEN` | SPI/ISP programming |
| `CKOPT` | Oscillator swing |
| `EESAVE` | Keep EEPROM on chip erase |
| `BOOTSZ1:0` | Boot section size |
| `BOOTRST` | Reset vector |

</div>

::right::

**Low Fuse Byte**

<div class="text-sm">

| Bit | Selects |
|---|---|
| `BODLEVEL` | BOD trigger level |
| `BODEN` | Brown-out detection |
| `SUT1:0` | Startup time |
| `CKSEL3:0` | Clock source |

</div>

<div class="text-sm mt-4">

`SPIEN` ships **programmed** (0) so ISP works out of the box; almost everything else ships **unprogrammed** (1).

</div>

---

## Clock Source Selection — `CKSEL3:0`

* Four fuse bits, **CKSEL3:0**, select the clock source: internal RC oscillator, external RC network, low-frequency crystal, or full-swing external crystal/resonator — each with several sub-ranges.

<div class="text-sm">

| CKSEL3:0 | Source |
|---|---|
| `0001` | Internal RC oscillator |
| `0101`–`1000` | External RC network |
| `1001`–`1111` | Crystal / ceramic resonator (by frequency range) |

</div>

* For a standard external crystal **above 1 MHz** (this course's labs), the recommended setting is **`CKSEL3:1 = 111`**, **`CKOPT = 0`** (programmed) — a wider swing appropriate for full-speed crystal operation.

---
layout: image-right
backgroundSize: contain
image: /ch8_clock_sources.png
---

## Figure 8-4: ATmega32 Clock Sources

* A single clock multiplexer selects among five physical sources: external RC, external clock, crystal oscillator, low-frequency crystal, or the calibrated internal RC oscillator.
* `CKSEL3:0` is simply the multiplexer's select input — it decides which of these five feeds the CPU.

---

## Lecture Outline

<div class="text-sm">

1.  AVR Pins
2.  AVR Simplest Connection
3.  Fuse Bits and Clock Source
4.  **Fuse Bits and Startup Time**
5.  What Is Inside a HEX File?
6.  Loading a HEX File into Flash

</div>

---

## Section 8.4: Fuse Bits and Startup Time

* The most difficult moment for any digital system is **power-up**: the crystal oscillator needs time to stabilize before its output is a clean, reliable clock signal.
* The AVR does **not** start executing code the instant `RESET` is released. Instead, it waits a fixed startup delay — set by **`SUT1:0`** together with `CKSEL0` — before fetching the first instruction.
* This course's golden rule for an external crystal above 1 MHz: set `SUT1:0 = 11` (alongside `CKSEL3:1 = 111`, `CKOPT = 0`) — the longest startup delay, safest for a fast-rising, previously unpowered board.

---

## Brown-Out Detection (BOD)

* **Power-On Reset (POR)** holds the chip in reset while `VCC` is still rising toward its operating level.
* **Brown-Out Detection (BOD)** is an ongoing safeguard: it continuously compares `VCC` against a fuse-selected trigger level and forces a reset if `VCC` sags below it.
* `BODLEVEL` selects the threshold: **2.7 V** when unprogrammed (`1`), or **4.0 V** when programmed (`0`). `BODEN` (programmed = enabled) turns the whole circuit on or off.
* Once `VCC` rises back above the trigger level, BOD releases reset and the MCU resumes after the normal startup delay.

---

## Lecture Outline

<div class="text-sm">

1.  AVR Pins
2.  AVR Simplest Connection
3.  Fuse Bits and Clock Source
4.  Fuse Bits and Startup Time
5.  **What Is Inside a HEX File?**
6.  Loading a HEX File into Flash

</div>

---

## Section 8.5: The Intel HEX File Format

* The assembler/compiler does not write raw binary straight into Flash — it produces a **HEX file**, a plain-text, line-oriented format any programmer/loader tool can parse. Each line is one **record**, always starting with `:`.

```text
:10 0000 00 CFD8CF0000241FBECFEDCDBF...  A2
```

<div class="text-sm">

| Field | Meaning |
|---|---|
| Byte count | How many data bytes are on this line |
| Address (16-bit) | Where the loader places the *first* data byte (up to 64K) |
| Record type | `00` data, more lines follow · `01` end-of-file · `02` segment address |
| Data | The actual bytes to write into Flash |
| Checksum | Sum every byte on the line (drop carries), then two's complement — the **same technique** as Chapter 6.7's checksum byte |

</div>

Every record is independently verifiable: a programmer tool recomputes each line's checksum on load and rejects a corrupted file before it reaches the chip.

---

## Lecture Outline

<div class="text-sm">

1.  AVR Pins
2.  AVR Simplest Connection
3.  Fuse Bits and Clock Source
4.  Fuse Bits and Startup Time
5.  What Is Inside a HEX File?
6.  **Loading a HEX File into Flash**

</div>

---

## Section 8.6: Four Ways to Load a HEX File

<div class="text-sm">

| Method | How | Typical use |
|---|---|---|
| **Parallel** | High-voltage, many-pin interface | Production; recovery if fuses are misconfigured |
| **ISP** | SPI pins (`MOSI`/`MISO`/`SCK`/`RESET`) | Everyday reprogramming, chip stays on the board |
| **JTAG** | 4-wire debug + program interface | Debugging (breakpoints, single-step) plus programming |
| **Bootloader** | Resident Flash program reprograms the rest of Flash, over UART/USB | Field updates, no external programmer shipped |

</div>

ISP is the workhorse method for this course: no special voltages, only the chip's normal SPI pins, and it works with the chip already wired into its target circuit.

---

## Summary

* **AVR pins**: power, oscillator, `RESET`, and analog reference must all be connected correctly before any I/O pin can be expected to work — Figure 8-2 gives the minimum working circuit.
* **Fuse bits** configure hardware behavior (clock, startup time, BOD) separately from the user program, and follow the *counter-intuitive* rule "unprogrammed = 1, programmed = 0." Verify before programming — `SPIEN` in particular guards your ability to reprogram at all.
* This course's **rule of thumb** for a crystal above 1 MHz: `CKSEL3:1 = 111`, `SUT1:0 = 11`, `CKOPT = 0`.
* **BOD** resets the chip if `VCC` sags below a fuse-selected threshold (2.7 V or 4.0 V).
* A **HEX file** is a sequence of colon-prefixed, checksummed text records — the same sum-and-two's-complement technique as Chapter 6's EEPROM checksum.
* Flash loads via **parallel programming**, **ISP**, **JTAG**, or a **bootloader** — ISP is the standard method for day-to-day development.
