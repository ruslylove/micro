---
theme: seriph
background: https://cover.sli.dev
transition: slide-left
layout: cover
title: Lecture 3 - Branch, Call, and Time Delay Loop
---

# Lecture 3: Branch, Call, and Time Delay Loop
## {{ $slidev.configs.subject }}
### Semester {{ $slidev.configs.semester }}
#### Presented by {{ $slidev.configs.presenter }}

---

## Objectives

Upon completion of this chapter, you will be able to:

* Code AVR Assembly loops using **DEC**/**INC** with conditional branch instructions such as **BRNE**
* List the AVR conditional branch instructions and the status-register flags each one tests
* Calculate the target address of a short (relative) branch instruction from its machine code
* Code the AVR unconditional jump instructions **RJMP**, **JMP**, and **IJMP**, and explain when each is preferred
* Explain the role of the **stack** and the **stack pointer (SP)** in supporting **CALL** and **RET**
* Code subroutines using **CALL**, **RCALL**, **ICALL**, **PUSH**, and **POP**
* Explain **instruction pipelining** and the **branch penalty** in the AVR
* Calculate the **time delay** produced by a software loop for a given crystal frequency

---

## Lecture Outline

<div class="text-sm">

1.  **Branch Instructions and Looping**
    *   Looping with `DEC`/`INC` and `BRNE`
    *   Conditional branch instructions and status flags
    *   Short branch address calculation
    *   Unconditional jumps: `RJMP`, `JMP`, `IJMP`
2.  Call Instructions and Stack
    *   `CALL`, `RCALL`, `ICALL`, `EICALL`
    *   The stack and the stack pointer (SP)
    *   `PUSH`, `POP`, and `RET`
    *   Calling subroutines from a main program
3.  AVR Time Delay and Instruction Pipeline
    *   Instruction pipelining and branch penalty
    *   Instruction cycle time from crystal frequency
    *   Calculating software time delays
    *   Single loops vs. nested loops vs. `NOP` padding

</div>

---
hideInToc: true
---

# Part 1
## Section 3.1: Branch Instructions and Looping

---

## Control Transfer: Why We Need It

* Normally, the CPU executes instructions **sequentially**, one after another, in the order they appear in memory.
* Sometimes the CPU must execute an instruction **other than the next one**. This happens when:
    * We use a **conditional** instruction (an `if`-like decision)
    * We build a **loop** (repeat a set of instructions)
    * We **call a function/subroutine**
* Assembly language provides two families of control-transfer instructions:
    * **Branch (jump)** instructions -- used for loops and conditions
    * **Call** instructions -- used for subroutine calls

---
layout: two-cols
---

## Why Not Just Repeat the Code?

One (bad) way to add 3 to R16 six times: just repeat the instruction six times.

```asm
LDI  R16, 0      ; R16 = 0
LDI  R17, 3      ; R17 = 3
ADD  R16, R17    ; add 3 (R16 = 0x03)
ADD  R16, R17    ; add 3 (R16 = 0x06)
ADD  R16, R17    ; add 3 (R16 = 0x09)
ADD  R16, R17    ; add 3 (R16 = 0x0C)
ADD  R16, R17    ; add 3 (R16 = 0x0F)
ADD  R16, R17    ; add 3 (R16 = 0x12)
```

::right::

* Six additions of 3: 6 x 3 = 18 = `0x12` -- correct, but...
* Repeating this by hand to get 50 or 100 repetitions would waste huge amounts of code space.
* A **loop** solves this: repeat a *small* block of code many times instead of writing it out longhand.

---

## Looping with `DEC` and `BRNE`

* A common way to repeat a block of code a fixed number of times:
    1. Load a register with the **count**.
    2. Perform the repeated action(s).
    3. **`DEC`** the counter register -- this updates the flags (Z is set when the result is 0).
    4. **`BRNE target`** -- branch if `Z = 0` (i.e., counter is *not yet* zero).
    5. When the counter reaches 0, `Z = 1`, so the branch falls through to the instruction below it.
* This is exactly the mechanism behind `for`-style counting loops in Assembly.

---
layout: image-right
backgroundSize: contain
image: /ch3_loop_flowchart.png
---

## Example 3-1: Counted Loop

Clear R20, then add 3 to it ten times, and send the sum to `PORTB`.

```asm {*|2|3-4|5-7|*}{lines:true}
        LDI   R16, 10     ; R16 = 10 (decimal), the counter
        LDI   R20, 0      ; R20 = 0
        LDI   R21, 3      ; R21 = 3
AGAIN:  ADD   R20, R21    ; add 3 to R20 (R20 = sum)
        DEC   R16         ; decrement R16 (counter), sets flags
        BRNE  AGAIN       ; repeat until counter = 0
        OUT   PORTB, R20  ; send sum to PORTB
```

* `DEC R16` sets the flags according to the result. While `Z = 0`, `BRNE AGAIN` keeps jumping back.
* When `R16` becomes 0, `Z = 1`, so the CPU falls through and executes `OUT PORTB, R20`.

---

## Example 3-2: Maximum Loop Count

**Question:** What is the maximum number of times the loop in Example 3-1 can repeat?

**Solution:** Because `R16` is an 8-bit register, it can hold a maximum of `0xFF` (255 decimal). Therefore, the loop can repeat **at most 255 times** using a single register as the counter.

* To repeat an action **more than 255 times**, we need a **loop inside a loop** -- a *nested loop* -- using two (or more) registers to hold the count.

---

## Loop Inside a Loop (Nested Loop)

* In a nested loop, an **inner loop** runs to completion once for every single iteration of an **outer loop**.
* Two registers are used: one for the outer count, one for the inner count.

```asm {*|3-4|5-6|7-8|9-10}{lines:true}
        LDI    R16, 0x55
        OUT    PORTB, R16
        LDI    R20, 10        ; outer loop count
LOP_1:  LDI    R21, 70        ; inner loop count (reloaded every outer pass)
LOP_2:  COM    R16            ; complement R16
        OUT    PORTB, R16     ; load PORTB SFR with complemented value
        DEC    R21            ; dec R21 (inner loop)
        BRNE   LOP_2          ; repeat it 70 times
        DEC    R20            ; dec R20 (outer loop)
        BRNE   LOP_1          ; repeat it 10 times
```

* Example 3-3: this complements `PORTB` a total of **10 &times; 70 = 700** times, well beyond the 255 limit of a single register.
* Whenever `R21` reaches 0, control falls through to `DEC R20`; if `R20` is not zero, `LOP_1` reloads the inner counter and the inner loop starts again.

---

## Looping 100,000 Times

* Two registers give a maximum of `255 x 255 = 65,025` iterations.
* Using **three** registers allows more than 16 million (2<sup>24</sup>) iterations. The code below repeats an action exactly **100,000** times:

```asm {*}{lines:true}
        LDI     R16, 0x55
        OUT     PORTB, R16
        LDI     R23, 10
LOP_3:  LDI     R22, 100
LOP_2:  LDI     R21, 100
LOP_1:  COM     R16
        DEC     R21
        BRNE    LOP_1
        DEC     R22
        BRNE    LOP_2
        DEC     R23
        BRNE    LOP_3
```

* `10 x 100 x 100 = 100,000` -- three nested loops, one register each.

---

## Conditional Branch Instructions

* Table 3-1 lists some AVR conditional branch instructions. Each jumps **only if** a specific status-register flag matches the condition; otherwise the CPU falls through to the next instruction.

| Instruction | Action |
|---|---|
| `BRLO` | Branch if C = 1 |
| `BRSH` | Branch if C = 0 |
| `BREQ` | Branch if Z = 1 |
| `BRNE` | Branch if Z = 0 |
| `BRMI` | Branch if N = 1 |
| `BRPL` | Branch if N = 0 |
| `BRVS` | Branch if V = 1 |
| `BRVC` | Branch if V = 0 |

*Table 3-1: AVR Conditional Branch (Jump) Instructions*

---

## `BREQ`: Branch if Equal (Z = 1)

* `BREQ` checks the **Z flag**. If it is high (`Z = 1`), the CPU jumps to the target address.

```asm {*|1-2|3}{lines:true}
OVER:  IN    R20, PINB    ; read PINB and put it in R20
       TST   R20          ; set the flags according to R20
       BREQ  OVER         ; jump if R20 is zero
```

* If `PINB` is zero, the CPU jumps back to `OVER` and stays in the loop until `PINB` becomes non-zero.
* **`TST Rd`** examines a register and sets the flags **without** performing an arithmetic operation such as `DEC`:
    * Sets `Z` if the register is zero; clears it otherwise.
    * Sets `N` if bit D7 of the register is high; clears it otherwise.

---

## `BRSH`/`BRLO`: Branch on Carry

* **`BRSH label`** (branch if same or higher): the CPU examines the carry flag `C`. If `C = 0`, it branches; if `C = 1`, it falls through to the next instruction.
* **`BRLO label`**: the opposite -- if `C = 1`, the CPU jumps to the target address.
* These are used to detect a carry-out when adding numbers larger than 8 bits (multi-byte addition).

### Example 3-5: Sum of 0x79 + 0xF5 + 0xE2 (low byte in R20, high byte in R21)

```asm {*|4-6}{lines:true}
        LDI   R21, 0     ; clear high byte
        LDI   R20, 0     ; clear low byte
        LDI   R16, 0x79
        ADD   R20, R16   ; R20 = 0x79, C = 0
        BRSH  N_1        ; if C = 0, add next number
        INC   R21        ; C = 1, increment high byte
N_1:    LDI   R16, 0xF5
        ADD   R20, R16   ; R20 = 0x6E, C = 1
        BRSH  N_2
        INC   R21
N_2:    LDI   R16, 0xE2
        ADD   R20, R16   ; R20 = 0x50, C = 1
        BRSH  OVER
        INC   R21
OVER:
```

---

## Tracing Example 3-5

| After the execution of | R21 (high byte) | R20 (low byte) |
|---|---|---|
| At first | $0 | $00 |
| Before `LDI R16, 0xF5` | $0 | $79 |
| Before `LDI R16, 0xE2` | $1 | $6E |
| At the end | $2 | $50 |

* Final result: low byte = `0x50`, high byte = `0x02` -- i.e., the 16-bit sum is `0x0250`.
* Every time `ADD` produces a carry (`C = 1`), `BRSH` falls through and `INC R21` bumps the high byte.

---

## All Conditional Branches Are Short Jumps

* Every conditional branch is a **2-byte instruction**: 9 bits of opcode + **7 bits** of signed relative address (`k`).
* This means the target must be within **-64 to +63** words of the program counter (PC) -- a *short jump*.
* **Target address = relative address (k) + PC of the next instruction.**
    * Positive `k` &rarr; jump **forward**.
    * Negative `k` &rarr; jump **backward**.

```
15                                    0
+------------------------------------+
| 1111 | 01kk | kkkk | k000 |
+------------------------------------+
```

* We add the displacement to the **address of the next instruction** (not the branch instruction itself) because, by the time the branch executes, it has already been fetched -- so PC is already pointing at the next instruction.

---

## Example 3-6: Calculating a Forward Branch

```
LINE  ADDRESS    Machine  Mnemonic  Operand
7:    +00000004: F408     BRSH      N_1     ; if C=0, add next number
8:    +00000005: 9543     INC       R21
```

* Machine code `F408` in binary: `1111 0100 0000 1000`.
* Comparing with the `BRSH` format (`1111 01kk kkkk k000`): opcode = `111101000`, operand (k) = `0000001` = **+1**.
* The relative address (+1) is added to the PC of the *next* instruction (`000005`, i.e. the address of `INC R21`):

$$ \text{target} = 1 + 5 = 6 $$

* Address `000006` is exactly the label `N_1` -- confirming the forward-jump calculation.

---

## Example 3-7: Calculating a Backward Branch

```
LINE  ADDRESS    Machine  Mnemonic  Operand
8:    +00000005: F7E9     BRNE      AGAIN   ; repeat until COUNT = 0
```

* Machine code `F7E9` in binary: `1111 0111 1110 1001`.
* Opcode = `111101001`; operand (k) = `1111101`.
* `1111101` is a **negative** number (two's complement) equal to **-3**.
* Target address = displacement + PC of next instruction = `-3 + 000006 = 000003` (the carry out of the addition is dropped).
* Address `000003` is the label `AGAIN` -- the branch correctly jumps **backward**.

---

## Unconditional Branch Instructions

* An unconditional branch always transfers control to the target -- no flag is checked. AVR provides **three**:

| Instruction | Size | Range |
|---|---|---|
| `JMP` (long jump) | 4 bytes (32-bit) | Anywhere in the 4M-word address space (`0` to `$3FFFFF`) |
| `RJMP` (relative jump) | 2 bytes (16-bit) | -2048 to +2047 words relative to PC |
| `IJMP` (indirect jump) | 2 bytes (16-bit) | Anywhere in the lowest 64K words, via the Z register |

* Choosing which one to use depends entirely on **how far away** the target address is.

---

## `JMP`: Long Jump

* `JMP` is a 4-byte instruction. 10 bits are used for the opcode, and the other **22 bits** (`k`) represent the target address.
* This 22-bit address allows a jump anywhere in the AVR's full **4M-word** program memory (`0x000000`-`$3FFFFF`).

```
1001010k21   k20...k17110k16   k15...k8   k7...k0        0 <= k < 4M
```

* Because `JMP` is 4 bytes, it is comparatively expensive in ROM space -- and many AVR chips have only 4K-32K of on-chip ROM. This motivates the smaller **`RJMP`**.

---

## `RJMP`: Relative Jump

* `RJMP` is a 2-byte instruction: 4 bits of opcode, and **12 bits** (`k`) of signed relative address.

```
1100  kkkk kkkk kkkk        -2048 <= n <= +2047
```

* The target is within **-2048 to +2047 words** relative to the current PC.
* Like the conditional branches, a positive `k` jumps forward and a negative `k` jumps backward -- but with 12 offset bits instead of 7, giving much greater reach.
* `RJMP` is **preferred over `JMP`** whenever the target is in range, because it saves 2 bytes of ROM every time it is used.

---

## `IJMP`: Indirect Jump

* `IJMP` is a 2-byte instruction with **no operand**. When it executes, the **PC is loaded with the contents of the Z register**.
* Because Z is a 16-bit register, `IJMP` can jump within the lowest **64K words** of program memory.

```
PC(15:0)  <- Z(15:0)
PC(21:16) <- 0
```

* Unlike `JMP`/`RJMP`, whose target is **static** (fixed at assembly time), `IJMP`'s target is **dynamic** -- the program can change where it jumps simply by changing the contents of Z at run time.

---

## Lecture Outline

<div class="text-sm">

1.  Branch Instructions and Looping
    *   Looping with `DEC`/`INC` and `BRNE`
    *   Conditional branch instructions and status flags
    *   Short branch address calculation
    *   Unconditional jumps: `RJMP`, `JMP`, `IJMP`
2.  **Call Instructions and Stack**
    *   `CALL`, `RCALL`, `ICALL`, `EICALL`
    *   The stack and the stack pointer (SP)
    *   `PUSH`, `POP`, and `RET`
    *   Calling subroutines from a main program
3.  AVR Time Delay and Instruction Pipeline
    *   Instruction pipelining and branch penalty
    *   Instruction cycle time from crystal frequency
    *   Calculating software time delays
    *   Single loops vs. nested loops vs. `NOP` padding

</div>

---
hideInToc: true
---

# Part 2
## Section 3.2: Call Instructions and Stack

---

## Subroutine Call Instructions

* A **subroutine (function)** performs a task that must be executed frequently, making a program more structured while also saving ROM space.
* The AVR has **four** instructions for calling a subroutine -- the choice depends on the target address:

| Instruction | Meaning |
|---|---|
| `CALL` | Long call -- anywhere in the 4M address space |
| `RCALL` | Relative call -- within &plusmn;2K words of PC |
| `ICALL` | Indirect call -- to the address in the Z register |
| `EICALL` | Extended indirect call -- to Z plus the `EIND` register (chips with >64K program memory) |

* Every subroutine **must** end with a `RET` instruction.

---

## `CALL`: Long Call

* `CALL` is a 4-byte (32-bit) instruction. 10 bits are the opcode, and the other **22 bits** (`k21`-`k0`) hold the target subroutine address -- exactly like `JMP`.
* It can call a subroutine anywhere in the AVR's 4M-word address space (`0`-`$3FFFFF`).

```
1001  010k21   k20k19k18k17  111k16
k15k14k13k12   k11k10k9k8    k7k6k5k4   k3k2k1k0
```

* To know where to resume afterward, the AVR **automatically pushes onto the stack** the address of the instruction immediately below the `CALL`. Control transfers to the subroutine, and when the subroutine finishes, **`RET`** pops that address back into the PC.

---

## The Stack and Stack Pointer

* The **stack** is a section of RAM the CPU uses to temporarily store information (data or an address) -- needed because there are only a limited number of registers.
* The **SP (stack pointer)** register points into this RAM region. In I/O space it is implemented as **two registers**: `SPH` (high byte) and `SPL` (low byte).

```
        8-bit          8-bit
SP:  [   SPH   ][   SPL   ]
```

* In chips with more than 256 bytes of RAM, both `SPH` and `SPL` are used; in chips with 256 bytes or fewer, only `SPL` is needed (an 8-bit register can already address 256 bytes).
* In the AVR, the stack **grows downward**: pushing decrements SP, popping increments SP.

---

## `PUSH` and `POP`

* **Pushing**: the stack pointer (SP) points to the **top of the stack (TOS)**. As data is pushed, it is saved where SP points, and then SP is **decremented** by one.

```asm
PUSH  Rr    ; Rr can be any general purpose register (R0-R31)
PUSH  R10   ; store R10 onto the stack, and decrement SP
```

* **Popping**: the reverse process. When `POP` executes, SP is **incremented**, and the top location of the stack is copied back into the given register.

```asm
POP   Rr    ; Rr can be any general purpose register (R0-R31)
POP   R16   ; increment SP, then load the top of stack into R16
```

* Because the last item pushed is the first popped, the stack is **LIFO** (Last-In-First-Out) memory.

---

## Initializing the Stack Pointer

* On power-up, SP contains **0** -- the address of R0. We **must** initialize SP before using the stack, so it points somewhere valid in internal SRAM.
* The stack must **not** be placed in register memory or I/O memory, so SP must be set to point **above `0x60`**.
* Because the stack grows downward, it is common to initialize SP to the **uppermost** RAM address -- the assembler constant **`RAMEND`**.

```asm {*}{lines:true}
        LDI   R16, HIGH(RAMEND)   ; load SPH
        OUT   SPH, R16
        LDI   R16, LOW(RAMEND)    ; load SPL
        OUT   SPL, R16
```

* The AVR's stack can be as large as its entire RAM, and it is used for **both** subroutine calls **and** interrupts -- so its contents must be manipulated carefully.

---

## `CALL`/`RET` and the Stack

* **On `CALL`:** the processor saves the address of the instruction *just below* the `CALL` onto the stack, then transfers control to the subroutine.
    * For AVRs whose PC is 16 bits or less: the PC is broken into **2 bytes** -- the **high byte is pushed first**, then the low byte.
    * For AVRs whose PC is longer than 16 bits (up to 24 bits): the PC is broken into **3 bytes** -- highest byte first, then middle, then lowest.
* **On `RET`:** the top of the stack is popped back into the PC, and SP is incremented. Because `CALL` pushed the address *below itself*, `RET` resumes execution exactly there.

---
layout: two-cols
---

## Example 3-9: `CALL`/`RET` with a Delay Subroutine

Toggle Port B between `$55`/`$AA` continuously, with a time delay between each write.

```asm {*|4|7|11-18}{lines:true}
BACK:
    LDI  R16, 0x55
    OUT  PORTB, R16
    CALL DELAY       ; time delay
    LDI  R16, 0xAA
    OUT  PORTB, R16
    CALL DELAY       ; time delay
    RJMP BACK         ; repeat forever
;----- delay subroutine -----
    .ORG 0x300
DELAY:
    LDI  R20, 0xFF    ; R20 = 255
AGAIN:
    NOP               ; wastes clock cycles
    NOP
    DEC  R20
    BRNE AGAIN
    RET               ; return to caller
```

::right::

* After the **first** `CALL DELAY`, the address of `LDI R16, 0xAA` (the instruction right below the call) is pushed onto the stack.
* Inside `DELAY`, counter `R20 = 255`, so the loop repeats 255 times.
* When `R20` reaches 0, control falls to `RET`, which pops the saved address off the stack back into PC, resuming right after the `CALL`.
* The exact delay time depends on the crystal frequency -- calculated in Section 3.3.

---

## Example 3-10: Tracing the Stack Through Two `CALL`s

<img src="/ch3_call_stack_frames.png" style="width:100%">

* Before the first `CALL`, `SP = 0x85F`. The first `CALL DELAY` pushes the return address (`0008`) onto the stack: SP becomes `0x85D` (2 bytes pushed).
* After `RET`, SP returns to `0x85F` and execution resumes at address `0008`.
* The second `CALL` repeats the same pattern with return address `000C`, then `RET` restores `SP = 0x85F` again.

---

## Calling Many Subroutines from Main

* A common Assembly pattern: **one main program** that calls **many subroutines**.
* Each subroutine becomes a separate, independently testable **module** -- and in large projects, different modules can be assigned to different programmers.

```asm {*}{lines:true}
MAIN:    CALL  SUBR_1
         CALL  SUBR_2
         CALL  SUBR_3
         CALL  SUBR_4
HERE:    RJMP  HERE        ; stay here
;----------- end of MAIN
SUBR_1:  ....
         RET
SUBR_2:  ....
         RET
SUBR_3:  ....
         RET
SUBR_4:  ....
         RET
```

* With `CALL`, the target subroutine can be **anywhere** in the 4M-word address space -- unlike `RCALL`, discussed next.

---

## `RCALL`: Relative Call

* `RCALL` is a **2-byte** instruction, versus 4 bytes for `CALL`. Only **12 bits** of the 2 bytes encode the address, so the target subroutine must be within **-2048 to +2047 words** of the current PC.
* There is **no functional difference** between `RCALL` and `CALL` regarding how the PC is saved on the stack or how `RET` works -- the only difference is **range**.
* On chips with only **4K of on-chip ROM** (common among AVR variants), using `RCALL` instead of `CALL` saves **2 bytes every time** a call is made -- a meaningful savings when ROM is scarce.

```asm
RCALL  DELAY   ; saves 2 bytes vs. CALL DELAY, if in range
```

---

## `ICALL` and `EICALL`: Indirect Calls

* **`ICALL`** (2 bytes): the **Z register** specifies the target address. When executed, the address of the next instruction is pushed onto the stack (like `CALL`/`RCALL`), and PC is loaded from Z.
    * Because Z is 16 bits, `ICALL` can call subroutines within the lowest **64K words** of program memory.

```
PC(15:0)  <- Z(15:0)      PC(21:16) <- 0
```

* **`EICALL`** (AVRs with >64K words of program memory): loads Z into the lower 16 bits of PC and the **`EIND`** register (I/O memory) into the upper 6 bits of PC.

```
PC(15:0)  <- Z(15:0)      PC(21:16) <- EIND(5:0)
```

* `ICALL`/`EICALL` support **pointer-to-function**-style programming, since the target is *dynamic* rather than fixed at assembly time.

---

## Lecture Outline

<div class="text-sm">

1.  Branch Instructions and Looping
    *   Looping with `DEC`/`INC` and `BRNE`
    *   Conditional branch instructions and status flags
    *   Short branch address calculation
    *   Unconditional jumps: `RJMP`, `JMP`, `IJMP`
2.  Call Instructions and Stack
    *   `CALL`, `RCALL`, `ICALL`, `EICALL`
    *   The stack and the stack pointer (SP)
    *   `PUSH`, `POP`, and `RET`
    *   Calling subroutines from a main program
3.  **AVR Time Delay and Instruction Pipeline**
    *   Instruction pipelining and branch penalty
    *   Instruction cycle time from crystal frequency
    *   Calculating software time delays
    *   Single loops vs. nested loops vs. `NOP` padding

</div>

---
hideInToc: true
---

# Part 3
## Section 3.3: AVR Time Delay and Instruction Pipeline

---

## What Determines a Time Delay?

Two factors affect the accuracy of a software-generated time delay:

1. **The crystal frequency**: the oscillator connected to `XTAL1`/`XTAL2` sets the duration of one instruction cycle -- a function of this frequency.
2. **The AVR's design**: modern microcontrollers execute an instruction in as little as one cycle thanks to three techniques:
    * **Harvard architecture** -- maximizes the amount of code and data reachable by the CPU
    * **RISC features** -- e.g., fixed-size instructions
    * **Pipelining** -- overlaps the fetching and execution of instructions

---

## Pipelining

* In early microprocessors (e.g., the 8085), the CPU could either **fetch** or **execute** at any given moment -- never both.
* **Pipelining** allows the CPU to fetch the *next* instruction while it executes the *current* one, dramatically improving throughput.

<img src="/ch3_pipeline_diagram.png" style="width:100%">

* One limitation: overall speed is limited to the **slowest stage** of the pipeline -- just as a pizza-making assembly line is limited by the baking stage, no matter how fast the other stages run.

---

## AVR Multistage Execution Pipeline

* Each AVR instruction executes in **3 stages**:

| Stage 1 | Stage 2 | Stage 3 |
|---|---|---|
| Read Operands | Process (ALU operation) | Write Back (result to destination) |

* Step 1: the operand is fetched. Step 2: the operation (e.g., adding two numbers) is performed. Step 3: the result is written into the destination register.
* Because fetch and execute overlap, by the time instruction *N* is in its **Process** stage, instruction *N+1* is already being **fetched**, and instruction *N-1* is being **written back**.
* (Some texts call the *process* stage **execute**, and *write back* simply **write**.)

---

## Instruction Cycle Time

* All AVR instructions are either 1-word (2-byte) or 2-word (4-byte), so most take only **one or two** machine cycles (some, like `JMP`/`CALL`, take up to **three or four**).
* In the AVR, **one machine cycle = one oscillator period**. So:

$$ \text{machine cycle} = \frac{1}{\text{crystal frequency}} $$

### Example 3-14

| Crystal frequency | Instruction cycle |
|---|---|
| 8 MHz | 1/8 MHz = 0.125 &micro;s = 125 ns |
| 16 MHz | 1/16 MHz = 0.0625 &micro;s = 62.5 ns |
| 10 MHz | 1/10 MHz = 0.1 &micro;s = 100 ns |
| 1 MHz | 1/1 MHz = 1 &micro;s |

---

## Branch Penalty

* Pipelining requires a queue in which the next instruction is prefetched, ready to execute.
* When a **branch** instruction is executed, the CPU must fetch code from a **new** memory location -- so the queued (prefetched) instruction is **discarded**, and the execution unit must wait for the new fetch. This extra cycle is the **branch penalty**.
* Most AVR instructions take **1 cycle**. Instructions that can take **2, 3, or 4** cycles: `JMP`, `CALL`, `RET`, and **all conditional branches** (`BRNE`, `BRLO`, etc.).
* A conditional branch takes only **1 cycle if it does *not* jump** (falls through), but **2 cycles if it *does* jump** -- e.g., `BRNE` takes 2 cycles when `Z = 0` (jumps) and 1 cycle when `Z = 1` (falls through).

---

## Example 3-15: Cycle Counts at 1 MHz

At 1 MHz, the machine cycle is 1 &micro;s (Example 3-14). From Appendix A:

| Instruction | Cycles | Time to execute |
|---|---|---|
| `LDI` | 1 | 1 &times; 1 &micro;s = 1 &micro;s |
| `DEC` | 1 | 1 &micro;s |
| `OUT` | 1 | 1 &micro;s |
| `ADD` | 1 | 1 &micro;s |
| `NOP` | 1 | 1 &micro;s |
| `JMP` | 3 | 3 &micro;s |
| `CALL` | 4 | 4 &micro;s |
| `BRNE` | 2/1 | 2 &micro;s taken, 1 &micro;s if it falls through |
| `.DEF` | 0 | (directive -- produces no machine instruction) |

---

## Delay Calculation Method

* A delay subroutine has two parts: **(1)** setting a counter, and **(2)** a loop. Most of the delay comes from the **body of the loop**.
* We usually calculate the delay from the instructions **inside** the loop, and ignore the (small) overhead outside it.
* General pattern for a single counted loop of `N` iterations, where the loop body totals `C` cycles per pass (including the branch when it jumps):

$$ \text{delay} = \big[\, 1 + (C \times N) - 1 + 4 \,\big] \times T_{\text{cyc}} $$

* The `-1` corrects for the **last** pass, where the branch **falls through** (1 cycle) instead of jumping (2 cycles); the leading `1` accounts for loading the counter, and the `4` accounts for the closing `RET`.

---

## Example 3-17: Delay of a `NOP`-Padded Loop

At 1 MHz, find the delay of the `DELAY` subroutine:

```asm {*}{lines:true}
DELAY:  LDI   R20, 0xFF   ; 1 cycle -- R20 = 255, the counter
AGAIN:  NOP               ; 1 cycle -- wastes clock cycles
        NOP               ; 1 cycle
        DEC   R20         ; 1 cycle
        BRNE  AGAIN       ; 2/1 cycles
        RET               ; 4 cycles
```

* Loop body = `NOP + NOP + DEC + BRNE` = `1+1+1+2` = **5 cycles/pass** (2 for `BRNE` while still jumping).

$$ \big[\,1 + (255 \times 5) - 1 + 4\,\big] \times 1\ \mu s = 1279\ \mu s $$

* (Example 3-16 shows the same subroutine at 10 MHz: `[1 + ((1+1+1+2) x 255) + 4] x 0.1 us = 128.0 us`, or **127.9 &micro;s** once the last `BRNE` fall-through is accounted for.)

---

## Example 3-18: Delay of a Nested Loop

For a 1 &micro;s cycle, find the delay of this nested-loop `DELAY` subroutine:

```asm {*}{lines:true}
DELAY:  LDI   R16, 200    ; 1
AGAIN:  LDI   R17, 250    ; 1
HERE:   NOP               ; 1
        NOP               ; 1
        DEC   R17         ; 1
        BRNE  HERE        ; 2/1
        DEC   R16         ; 1
        BRNE  AGAIN       ; 2/1
        RET               ; 4
```

* **Inner (`HERE`) loop:** `[(5 x 250) - 1] x 1 us = 1249 us`.
* **Outer (`AGAIN`) loop** repeats the inner loop 200 times: `200 x 1249 us = 249,800 us`.
* Outer-loop overhead (`LDI R17,250` / `DEC R16` / `BRNE AGAIN`): `[(4 x 200) - 1] x 1 us = 799 us`.
* **Total: `249,800 + 799 = 250,599 us`** (approximate -- ignores the very first `LDI R16,200` and the final `RET`).
* ROM cost: 9 instructions, all 2-byte, for **22 bytes** of code space.

---

## Example 3-19: The Disadvantage of `NOP` Padding

Compare using 12 `NOP`s in a single loop against the nested-loop approach of Example 3-18 (same 1 MHz clock):

```asm {*}{lines:true}
DELAY:  LDI   R16, 200
AGAIN:  NOP                   ; 12 NOPs total, 1 cycle each
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        DEC   R16
        BRNE  AGAIN
        RET
```

* Delay inside the loop: `[200(13 + 2)] x 1 us = 3000 us`.
* 16 instructions, all 2 bytes &rarr; **32 bytes of ROM**, for only **3000 &micro;s** of delay.
* Compare Example 3-18: **22 bytes** of ROM produced **250,599 &micro;s** -- far more delay per byte of code.
* **Conclusion:** padding a loop with many `NOP`s is an inefficient way to build a large delay; a **nested loop** is much more effective. (Chapter 9 shows how AVR hardware **timers** create delays even more efficiently.)

---

## Example 3-20: Toggling `PORTB` Every 1 Second

For an ATmega32 at **8 MHz**, toggle all bits of `PORTB` once every 1 second.

```asm {*|1-4|6-18}{lines:true}
BACK:   COM    R16
        OUT    PORTB, R16
        CALL   DELAY_1S
        RJMP   BACK

DELAY_1S:
        LDI    R20, 32
L1:     LDI    R21, 200
L2:     LDI    R22, 250
L3:     NOP
        NOP
        DEC    R22
        BRNE   L3
        DEC    R21
        BRNE   L2
        DEC    R20
        BRNE   L1
        RET
```

* Machine cycle = 1 / 8 MHz = **125 ns**.
* Delay = `32 x 200 x 250 x 5 x 125 ns` = `1,000,000,000 ns` = **1,000,000 &micro;s = 1 s** (ignoring the small overhead of the two outer loops).

---

## Verifying Delays in Practice

* These hand calculations are **approximations** -- they typically ignore overhead instructions outside the innermost loop.
* To verify precisely:
    * Use the **AVR Studio simulator** to verify the delay and the number of cycles used.
    * Use an **oscilloscope** to measure the exact time delay on real hardware.
* Because instruction-based delays depend on exact cycle counts, they are **not the most reliable method** for precise timing. Chapter 9 introduces AVR hardware **timers**, which generate delays far more accurately and efficiently.

---

## Lecture Outline

<div class="text-sm">

1.  Branch Instructions and Looping
    *   Looping with `DEC`/`INC` and `BRNE`
    *   Conditional branch instructions and status flags
    *   Short branch address calculation
    *   Unconditional jumps: `RJMP`, `JMP`, `IJMP`
2.  Call Instructions and Stack
    *   `CALL`, `RCALL`, `ICALL`, `EICALL`
    *   The stack and the stack pointer (SP)
    *   `PUSH`, `POP`, and `RET`
    *   Calling subroutines from a main program
3.  AVR Time Delay and Instruction Pipeline
    *   Instruction pipelining and branch penalty
    *   Instruction cycle time from crystal frequency
    *   Calculating software time delays
    *   Single loops vs. nested loops vs. `NOP` padding

</div>

---
layout: default
---

## Summary

<Transform scale="0.9">

*   **Control Transfer:** Program flow is sequential unless a control-transfer instruction (branch or call) executes.
*   **Looping:** Built from a counter register, a `DEC` (or `INC`), and a conditional branch such as `BRNE`. A single register limits the count to 255; nested loops (two or three registers) reach far higher counts.
*   **Conditional Branches:** Instructions like `BREQ`, `BRNE`, `BRSH`, `BRLO` test specific status flags (Z, C, N, V, ...) and are always 2-byte, short (&plusmn;64-word) jumps, with the target computed as PC-of-next-instruction plus a signed displacement.
*   **Unconditional Jumps:** `JMP` (4 bytes, full 4M range), `RJMP` (2 bytes, &plusmn;2K range -- preferred to save ROM), and `IJMP` (2 bytes, dynamic target via the Z register).
*   **Call and Stack:** `CALL`/`RCALL`/`ICALL`/`EICALL` push the return address onto the stack; `RET` pops it back into the PC. The stack pointer (SP = SPH:SPL) must be initialized (commonly to `RAMEND`) before any `CALL` or `PUSH`.
*   **Time Delay:** Delay = cycles-per-loop-pass &times; iterations &times; machine-cycle-time, where machine cycle = 1 / crystal frequency. Nested loops give far more delay per byte of ROM than long runs of `NOP`; hardware timers (Chapter 9) are more accurate still.

</Transform>
