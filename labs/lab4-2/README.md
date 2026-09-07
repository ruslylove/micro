# Lab 4-2 KiCad Project

`kicad/lab4_2_shield.{kicad_pro,kicad_sch,kicad_pcb}` is a generated starting point for the
Lab 4-2 shield: the exact Lab 4-1 circuit (buttons, LEDs, multiplexed 7-segment displays,
digit-select transistors) captured as a schematic and laid out on a real Arduino Uno R3
shield outline. It was built programmatically (not drawn by hand in the KiCad GUI), using
dimensions and symbol/footprint geometry pulled from KiCad's own official libraries rather
than guessed, for exactly the reason the lab warns about: the shield header gap is a
real, documented quirk, not something to eyeball.

No KiCad installation was available while generating this, so **nothing here has been
opened in real KiCad, run through ERC/DRC, or plotted**. Treat it as a strong, verified
head start -- not a finished, fab-ready board. See "What to check first" below.

## What's authoritative vs. generated

- **Board outline, 4 mounting holes, and the 4 shield header positions** (including the
  famous non-0.1"-pitch gap between the Digital(0-7) and Digital(8-13) headers) come
  directly from KiCad's own official `Arduino_As_Uno_R3` PCB template
  (`kicad-library` repo) and the `Arduino_UNO_R3_WithMountingHoles` footprint
  (`kicad-footprints` repo) -- the same authoritative sources the lab tells you to use
  instead of a plain 0.1" header. The gap works out to 4.064 mm pin-to-pin (0.16"), i.e.
  1.524 mm (0.06") more than the standard 2.54 mm (0.1") pitch.
- All symbols (`Device:R`, `Device:LED`, `Device:Q_NPN`, `Switch:SW_Push`, `power:GND`,
  `Connector_Generic:Conn_01x0N`) and footprints (`Resistor_THT`, `LED_THT`,
  `Button_Switch_THT`, `Package_TO_SOT_THT`, `Resistor_THT` axial vertical) were copied
  from KiCad's current official symbol/footprint libraries, so they match what a real
  KiCad 10 install ships.
- **The 7-segment display symbol/footprint (`lab4_2_shield:DISPLAY_7SEG_CC`) is a
  hand-made placeholder.** KiCad's official symbol library ships no 7-segment display at
  all (confirmed by checking the library index), which is exactly why the lab tells you to
  search for one and verify it. This project's version has 10 pins (`a`-`g`, `cc1`, `cc2`,
  `dp`) with an arbitrary-but-documented pin order, and a footprint pad pattern borrowed
  from a real compact THT display (Broadcom HDSP-7401-style, 2x5 pins, 2.54 mm pitch).
  **Before you build: get your actual display's datasheet, confirm its real pin-out, and
  update the symbol pin names/footprint pad map to match** -- do not assume this one is
  right for your part. This is the single most important manual check in this repo.

## Circuit captured (identical to Lab 4-1)

| Signal | Uno pin | Net name(s) in the files |
|---|---|---|
| SW1-SW4 | D8-D11 | `D8`..`D11` |
| LED1-LED5 (through 330R) | D3-D7 | `D3_R1`..`D7_R5`, `LED1_A`..`LED5_A` |
| Segments a-f (through 330R) | A0-A5 | `SEGBUS_A`..`SEGBUS_F`, `A0_R6`..`A5_R11` |
| Segment g (through 330R) | D2 | `SEGBUS_G`, `D2_R12` |
| Digit-select bases (through 1k) | D12, D13 | `D12_R13`/`Q1_BASE`, `D13_R14`/`Q2_BASE` |
| Common ground return | Digital(8-13) header pin 2 | `GND` |

The Power header (J3) is placed for mechanical shield compliance but is **fully
unconnected** electrically, matching the lab's own note that only one GND path
(Digital(8-13) here) is needed. `AREF`, `D0`/`D1` (USB-serial), and the Power header's
`IOREF`/`RESET`/`3V3`/`5V`/`VIN`/`GND` pins are marked no-connect, same as Lab 4-1.

## What's routed on the PCB, and what's deliberately left for you

- The **board outline, mounting holes, and all four header footprints** are placed at the
  verified authoritative positions.
- **Every other footprint** (both displays, all 4 buttons, all 5 LEDs, both transistors,
  all 14 resistors) is placed with a verified-by-script non-overlapping layout, and every
  pad already carries its correct net -- so opening the PCB shows a full, correct ratsnest.
- A **GND copper zone** on the bottom layer (`B.Cu`) is defined covering most of the board
  interior; it should pick up every ground pad (button commons, LED cathodes, transistor
  emitters, the header's GND pin) once you fill zones (`B`, or Edit > Fill All Zones) --
  no manual GND routing needed.
- **No signal traces are pre-routed.** That's intentional, not an oversight: the lab's own
  Exercise 3 callout asks you to look at the ratsnest and predict which net is hardest to
  route (its own suggested answer is the 7-segment shared-segment bus -- 7 nets fanning out
  to 14 pads across two displays) *before* routing it yourself. Handing you a fully-routed
  board would remove exactly the exercise the lab is testing. Everything you need to route
  it correctly -- outline, headers, footprints, and a correct netlist -- is already here.

## What to check first (in order)

1. Open the project in KiCad 10. In the **Schematic Editor**, run **Tools > Annotate
   Schematic** if asked (power symbol references were pre-numbered `#PWR001..#PWR011`,
   but let KiCad confirm), then run **ERC**. Expect it to be clean except possibly
   "input pin not driven" warnings on the header nets -- that's expected and not a wiring
   bug: this schematic deliberately has no Arduino/MCU symbol (it's a peripheral-only
   shield, per the lab), so nothing in-sheet "drives" the header pins. You can lower that
   rule's severity in Schematic Setup if it's noisy.
2. Fix the 7-segment display pin-out (see above) against your actual part's datasheet.
3. In the **PCB Editor**, confirm the board outline and header positions visually match
   an authoritative Arduino Uno shield drawing, then **Fill Zones** and run **DRC**.
4. Route the remaining nets, using the lab's own trace/predict exercise as your guide.
   Then re-run DRC until clean.
5. Gerbers/drill files are **not** included -- that requires KiCad's own plot engine,
   which wasn't available while generating this project. Use File > Fabrication Outputs
   in the PCB Editor once routing is done.

## Viewing it in 3D

All resistors, LEDs, push buttons, and the two transistors have KiCad's stock 3D models
attached (from `Resistor_THT`, `LED_THT`, `Button_Switch_THT`, `Package_TO_SOT_THT`), so
`View > 3D Viewer` (Alt+3) in the PCB Editor will render them. The two shield headers and
the 7-segment displays are custom footprints with no stock 3D shape, so they'll show as
bare pads/outline in the 3D view -- that's expected, not a missing step.

## Files

```
kicad/lab4_2_shield.kicad_pro   project settings (net classes: 0.2mm clearance, 0.3mm track)
kicad/lab4_2_shield.kicad_sch   schematic (self-contained; all symbols embedded)
kicad/lab4_2_shield.kicad_pcb   PCB (self-contained; all footprints embedded)
```
