.include "m328Pdef.inc"

; Lab 5 - In-Lab Exercise 4: Function dispatch table (full 16-key map)
;
; Same 4-phase multiplexed REFRESH loop as Exercise 3 (display + debounced,
; edge-latched keypad scan interleaved on the shared PB2-PB5 pins), now with
; the complete Function Key Map:
;   R1  S1 inc first        S2 dec first        S3 inc second        S4 dec second
;   R2  S5 inc inc first    S6 dec dec first     S7 inc inc second    S8 dec dec second
;   R3  S9 first=first<<1   S10 first=first<<second  S11 second=second<<1  S12 second=second<<first
;   R4  S13 first=first+second  S14 first=first-second  S15 second=second-first  S16 second=second+first
;
; Register usage:
;   tmp        (r16) segment/port scratch
;   nib        (r17) hex_to_seg digit argument / general scratch (also used
;              as the shift-loop counter for S10/S12 -- free at that point,
;              its column-decode job is done before dispatch_key runs)
;   r18, r19   owned entirely by Delay1ms, never touched elsewhere
;   col_read   (r20) this-phase masked column reading (survives the debounce wait)
;   first      (r21)
;   second     (r22)
;   held_key   (r23) 0xFF = no key currently down, else the key_index (0-15)
;              of the key that's still being held -- this is what makes a
;              press act once instead of auto-repeating every refresh frame
;              for as long as it's held.
;   dcount     (r24) loop counter for the delay_dwell/delay_debounce wrappers
;   row_base   (r25) row * 4, passed into confirm_and_dispatch
.def tmp      = r16
.def nib      = r17
.def col_read = r20
.def first    = r21
.def second   = r22
.def held_key = r23
.def dcount   = r24
.def row_base = r25

; TODO: recompute these two from your own student ID (D = digit sum) --
; the defaults below are the PDF's worked example, not your target.
;   t_debounce = 15 + (D mod 10) * 1 ms
;   t_dwell    = 1.5 + (D mod 6) * 0.4 ms   (round to nearest ms)
.equ NO_KEY_SENTINEL = 0x0F
.equ T_DWELL_MS = 3
.equ T_DEBOUNCE_MS = 16

.org 0x0000
    rjmp reset

reset:
    ; Segment bus pins are always outputs.
    ldi tmp, (1 << 0) | (1 << 1)
    out DDRB, tmp
    ldi tmp, (1 << 2) | (1 << 3) | (1 << 5) | (1 << 6) | (1 << 7)
    out DDRD, tmp

    ; Keypad columns are inputs with pull-ups enabled.
    ldi tmp, 0x00
    out DDRC, tmp
    ldi tmp, 0x0F
    out PORTC, tmp

    ; Segment bus off; PB2-PB5 (rows/digit-select) start floating (DDR=0,
    ; the reset default) and stay that way until each phase toggles its
    ; own bit.
    ldi tmp, 0x00
    out PORTB, tmp
    out PORTD, tmp

    ldi first, 0x00       ; first  = 0x00
    ldi second, 0x00      ; second = 0x00
    ldi held_key, 0xFF    ; held_key = none

refresh:
    ; ---- Phase 1: first's high nibble, row 1 (key_index 0-3, R1) ----
    mov nib, first
    swap nib
    andi nib, 0x0F
    rcall hex_to_seg
    sbi DDRB, 2
    in tmp, PINC
    andi tmp, 0x0F
    cpi tmp, NO_KEY_SENTINEL
    breq p1_check_release
    cpi held_key, 0xFF
    brne p1_end              ; some other key already held -- ignore
    mov col_read, tmp
    rcall delay_debounce
    in tmp, PINC
    andi tmp, 0x0F
    cp tmp, col_read
    brne p1_end                ; didn't confirm -- bounce/noise
    ldi row_base, 0
    rcall confirm_and_dispatch
    rjmp p1_end
p1_check_release:
    mov nib, held_key
    lsr nib
    lsr nib
    cpi nib, 0
    brne p1_end
    ldi held_key, 0xFF
p1_end:
    rcall delay_dwell
    cbi DDRB, 2

    ; ---- Phase 2: first's low nibble, row 2 (key_index 4-7, R2) ----
    mov nib, first
    andi nib, 0x0F
    rcall hex_to_seg
    sbi DDRB, 3
    in tmp, PINC
    andi tmp, 0x0F
    cpi tmp, NO_KEY_SENTINEL
    breq p2_check_release
    cpi held_key, 0xFF
    brne p2_end
    mov col_read, tmp
    rcall delay_debounce
    in tmp, PINC
    andi tmp, 0x0F
    cp tmp, col_read
    brne p2_end
    ldi row_base, 4
    rcall confirm_and_dispatch
    rjmp p2_end
p2_check_release:
    mov nib, held_key
    lsr nib
    lsr nib
    cpi nib, 1
    brne p2_end
    ldi held_key, 0xFF
p2_end:
    rcall delay_dwell
    cbi DDRB, 3

    ; ---- Phase 3: second's high nibble, row 3 (key_index 8-11, R3) ----
    mov nib, second
    swap nib
    andi nib, 0x0F
    rcall hex_to_seg
    sbi DDRB, 4
    in tmp, PINC
    andi tmp, 0x0F
    cpi tmp, NO_KEY_SENTINEL
    breq p3_check_release
    cpi held_key, 0xFF
    brne p3_end
    mov col_read, tmp
    rcall delay_debounce
    in tmp, PINC
    andi tmp, 0x0F
    cp tmp, col_read
    brne p3_end
    ldi row_base, 8
    rcall confirm_and_dispatch
    rjmp p3_end
p3_check_release:
    mov nib, held_key
    lsr nib
    lsr nib
    cpi nib, 2
    brne p3_end
    ldi held_key, 0xFF
p3_end:
    rcall delay_dwell
    cbi DDRB, 4

    ; ---- Phase 4: second's low nibble, row 4 (key_index 12-15, R4) ----
    mov nib, second
    andi nib, 0x0F
    rcall hex_to_seg
    sbi DDRB, 5
    in tmp, PINC
    andi tmp, 0x0F
    cpi tmp, NO_KEY_SENTINEL
    breq p4_check_release
    cpi held_key, 0xFF
    brne p4_end
    mov col_read, tmp
    rcall delay_debounce
    in tmp, PINC
    andi tmp, 0x0F
    cp tmp, col_read
    brne p4_end
    ldi row_base, 12
    rcall confirm_and_dispatch
    rjmp p4_end
p4_check_release:
    mov nib, held_key
    lsr nib
    lsr nib
    cpi nib, 3
    brne p4_end
    ldi held_key, 0xFF
p4_end:
    rcall delay_dwell
    cbi DDRB, 5

    rjmp refresh

; ---- Column decode + latch + dispatch ----
; In:  col_read = confirmed masked column reading (0x0E/0x0D/0x0B/0x07)
;      row_base = row * 4
; Sets held_key and calls the matching operation on first/second.
confirm_and_dispatch:
    cpi col_read, 0x0E
    breq cad_c0
    cpi col_read, 0x0D
    breq cad_c1
    cpi col_read, 0x0B
    breq cad_c2
    ldi nib, 3
    rjmp cad_have_col
cad_c0:
    ldi nib, 0
    rjmp cad_have_col
cad_c1:
    ldi nib, 1
    rjmp cad_have_col
cad_c2:
    ldi nib, 2
cad_have_col:
    add nib, row_base
    mov held_key, nib
    rcall dispatch_key
    ret

; In: held_key = key_index (0-15) -- the full Function Key Map, S1-S16.
dispatch_key:
    cpi held_key, 0x00
    breq dk_s1
    cpi held_key, 0x01
    breq dk_s2
    cpi held_key, 0x02
    breq dk_s3
    cpi held_key, 0x03
    breq dk_s4
    cpi held_key, 0x04
    breq dk_s5
    cpi held_key, 0x05
    breq dk_s6
    cpi held_key, 0x06
    breq dk_s7
    cpi held_key, 0x07
    breq dk_s8
    cpi held_key, 0x08
    breq dk_s9
    cpi held_key, 0x09
    breq dk_s10
    cpi held_key, 0x0A
    breq dk_s11
    cpi held_key, 0x0B
    breq dk_s12
    cpi held_key, 0x0C
    breq dk_s13
    cpi held_key, 0x0D
    breq dk_s14
    cpi held_key, 0x0E
    breq dk_s15
    ; falls through to dk_s16 (held_key == 0x0F)

dk_s16:
    add second, first
    ret

dk_s1:
    rcall inc_first
    ret
dk_s2:
    rcall dec_first
    ret
dk_s3:
    rcall inc_second
    ret
dk_s4:
    rcall dec_second
    ret
dk_s5:
    rcall inc_first
    rcall inc_first
    ret
dk_s6:
    rcall dec_first
    rcall dec_first
    ret
dk_s7:
    rcall inc_second
    rcall inc_second
    ret
dk_s8:
    rcall dec_second
    rcall dec_second
    ret

; S9: first = first << 1
dk_s9:
    lsl first
    ret

; S10: first = first << second  (AVR has no shift-by-register opcode --
; repeat LSL "second" times; second itself is left unmodified.)
dk_s10:
    mov nib, second
    cpi nib, 0
    breq dk_s10_done
dk_s10_loop:
    lsl first
    dec nib
    brne dk_s10_loop
dk_s10_done:
    ret

; S11: second = second << 1
dk_s11:
    lsl second
    ret

; S12: second = second << first  (same repeated-LSL idea as S10)
dk_s12:
    mov nib, first
    cpi nib, 0
    breq dk_s12_done
dk_s12_loop:
    lsl second
    dec nib
    brne dk_s12_loop
dk_s12_done:
    ret

; S13: first = first + second
dk_s13:
    add first, second
    ret

; S14: first = first - second
dk_s14:
    sub first, second
    ret

; S15: second = second - first
dk_s15:
    sub second, first
    ret

inc_first:
    inc first
    ret
dec_first:
    dec first
    ret
inc_second:
    inc second
    ret
dec_second:
    dec second
    ret

; ---- Timing helpers ----
delay_dwell:
    ldi dcount, T_DWELL_MS
dwell_loop:
    rcall Delay1ms
    dec dcount
    brne dwell_loop
    ret

delay_debounce:
    ldi dcount, T_DEBOUNCE_MS
debounce_loop:
    rcall Delay1ms
    dec dcount
    brne debounce_loop
    ret

; ~1ms tick at 16MHz; call it N times for N ms.
Delay1ms:
    ldi r18, 21
dl1:
    ldi r19, 25
dl2:
    dec r19
    brne dl2
    dec r18
    brne dl1
    ret

; ---- hex_to_seg: nib = hex digit (0x0-0xF) in, segment bus written, tmp clobbered ----
hex_to_seg:
    cpi nib, 0x0
    brne hts_1
    ldi tmp, (1 << 1) | (1 << 0)
    out PORTB, tmp
    ldi tmp, (1 << 2) | (1 << 3) | (1 << 5) | (1 << 6)
    out PORTD, tmp
    cbi PORTD, 7
    ret

hts_1:
    cpi nib, 0x1
    brne hts_2
    ldi tmp, 0x00
    out PORTB, tmp
    ldi tmp, (1 << 2) | (1 << 3)
    out PORTD, tmp
    cbi PORTD, 7
    cbi PORTB, 0
    ret

hts_2:
    cpi nib, 0x2
    brne hts_3
    ldi tmp, (1 << 1)
    out PORTB, tmp
    ldi tmp, (1 << 2) | (1 << 5) | (1 << 6) | (1 << 7)
    out PORTD, tmp
    cbi PORTD, 3
    ret

hts_3:
    cpi nib, 0x3
    brne hts_4
    ldi tmp, (1 << 1)
    out PORTB, tmp
    ldi tmp, (1 << 2) | (1 << 3) | (1 << 5) | (1 << 7)
    out PORTD, tmp
    cbi PORTD, 6
    ret

hts_4:
    cpi nib, 0x4
    brne hts_5
    ldi tmp, (1 << 0)
    out PORTB, tmp
    ldi tmp, (1 << 2) | (1 << 3) | (1 << 7)
    out PORTD, tmp
    ret

hts_5:
    cpi nib, 0x5
    brne hts_6
    ldi tmp, (1 << 1) | (1 << 0)
    out PORTB, tmp
    ldi tmp, (1 << 3) | (1 << 5) | (1 << 7)
    out PORTD, tmp
    cbi PORTD, 6
    ret

hts_6:
    cpi nib, 0x6
    brne hts_7
    ldi tmp, (1 << 1) | (1 << 0)
    out PORTB, tmp
    ldi tmp, (1 << 3) | (1 << 5) | (1 << 6) | (1 << 7)
    out PORTD, tmp
    ret

hts_7:
    cpi nib, 0x7
    brne hts_8
    ldi tmp, (1 << 1)
    out PORTB, tmp
    ldi tmp, (1 << 2) | (1 << 3)
    out PORTD, tmp
    cbi PORTD, 5
    cbi PORTD, 6
    cbi PORTD, 7
    cbi PORTB, 0
    ret

hts_8:
    cpi nib, 0x8
    brne hts_9
    ldi tmp, (1 << 1) | (1 << 0)
    out PORTB, tmp
    ldi tmp, (1 << 2) | (1 << 3) | (1 << 5) | (1 << 6) | (1 << 7)
    out PORTD, tmp
    ret

hts_9:
    cpi nib, 0x9
    brne hts_A
    ldi tmp, (1 << 1) | (1 << 0)
    out PORTB, tmp
    ldi tmp, (1 << 2) | (1 << 3) | (1 << 5) | (1 << 7)
    out PORTD, tmp
    cbi PORTD, 6
    ret

hts_A:
    cpi nib, 0xA
    brne hts_b
    ldi tmp, (1 << 1) | (1 << 0)
    out PORTB, tmp
    ldi tmp, (1 << 2) | (1 << 3) | (1 << 5) | (1 << 6) | (1 << 7)
    out PORTD, tmp
    cbi PORTD, 5
    ret

hts_b:
    cpi nib, 0xB
    brne hts_C
    ldi tmp, (1 << 0)
    out PORTB, tmp
    ldi tmp, (1 << 2) | (1 << 3) | (1 << 5) | (1 << 6) | (1 << 7)
    out PORTD, tmp
    cbi PORTD, 2
    ret

hts_C:
    cpi nib, 0xC
    brne hts_d
    ldi tmp, (1 << 1) | (1 << 0)
    out PORTB, tmp
    ldi tmp, (1 << 5) | (1 << 6)
    out PORTD, tmp
    ret

hts_d:
    cpi nib, 0xD
    brne hts_E
    ldi tmp, 0x00
    out PORTB, tmp
    ldi tmp, (1 << 2) | (1 << 3) | (1 << 5) | (1 << 6) | (1 << 7)
    out PORTD, tmp
    ret

hts_E:
    cpi nib, 0xE
    brne hts_F
    ldi tmp, (1 << 1) | (1 << 0)
    out PORTB, tmp
    ldi tmp, (1 << 2) | (1 << 3) | (1 << 5) | (1 << 6) | (1 << 7)
    out PORTD, tmp
    cbi PORTD, 3
    cbi PORTD, 2
    ret

hts_F:
    ldi tmp, (1 << 1) | (1 << 0)
    out PORTB, tmp
    ldi tmp, (1 << 2) | (1 << 3) | (1 << 5) | (1 << 6) | (1 << 7)
    out PORTD, tmp
    cbi PORTD, 2
    cbi PORTD, 3
    cbi PORTD, 5
    ret
