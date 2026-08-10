.include "m328Pdef.inc"

.def tmp = r16   ; scratch
.def row = r17   ; current key_index / digit to display
.def key = r19   ; scan result, 0xFF = no key

.equ NO_KEY_SENTINEL = 0x0F

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

    ; Start with the segment bus off and row pins floating.
    ldi tmp, 0x00
    out PORTB, tmp
    out PORTD, tmp

main_loop:
    rcall scan_keypad
    cpi key, 0xFF
    breq main_loop
    mov row, key
    rcall hex_to_seg
    rjmp main_loop

scan_keypad:
    ; Row 1
    sbi DDRB, 2
    in tmp, PINC
    andi tmp, 0x0F
    cpi tmp, NO_KEY_SENTINEL
    breq scan_row2
    cpi tmp, 0x0E
    breq key_r1_c1
    cpi tmp, 0x0D
    breq key_r1_c2
    cpi tmp, 0x0B
    breq key_r1_c3
    ldi key, 0x03
    rjmp scan_done

key_r1_c1:
    ldi key, 0x00
    rjmp scan_done

key_r1_c2:
    ldi key, 0x01
    rjmp scan_done

key_r1_c3:
    ldi key, 0x02
    rjmp scan_done

scan_row2:
    cbi DDRB, 2
    sbi DDRB, 3
    in tmp, PINC
    andi tmp, 0x0F
    cpi tmp, NO_KEY_SENTINEL
    breq scan_row3
    cpi tmp, 0x0E
    breq key_r2_c1
    cpi tmp, 0x0D
    breq key_r2_c2
    cpi tmp, 0x0B
    breq key_r2_c3
    ldi key, 0x07
    rjmp scan_done

key_r2_c1:
    ldi key, 0x04
    rjmp scan_done

key_r2_c2:
    ldi key, 0x05
    rjmp scan_done

key_r2_c3:
    ldi key, 0x06
    rjmp scan_done

scan_row3:
    cbi DDRB, 3
    sbi DDRB, 4
    in tmp, PINC
    andi tmp, 0x0F
    cpi tmp, NO_KEY_SENTINEL
    breq scan_row4
    cpi tmp, 0x0E
    breq key_r3_c1
    cpi tmp, 0x0D
    breq key_r3_c2
    cpi tmp, 0x0B
    breq key_r3_c3
    ldi key, 0x0B
    rjmp scan_done

key_r3_c1:
    ldi key, 0x08
    rjmp scan_done

key_r3_c2:
    ldi key, 0x09
    rjmp scan_done

key_r3_c3:
    ldi key, 0x0A
    rjmp scan_done

scan_row4:
    cbi DDRB, 4
    sbi DDRB, 5
    in tmp, PINC
    andi tmp, 0x0F
    cpi tmp, NO_KEY_SENTINEL
    breq no_key
    cpi tmp, 0x0E
    breq key_r4_c1
    cpi tmp, 0x0D
    breq key_r4_c2
    cpi tmp, 0x0B
    breq key_r4_c3
    ldi key, 0x0F
    rjmp scan_done

key_r4_c1:
    ldi key, 0x0C
    rjmp scan_done

key_r4_c2:
    ldi key, 0x0D
    rjmp scan_done

key_r4_c3:
    ldi key, 0x0E
    rjmp scan_done

no_key:
    ldi key, 0xFF

scan_done:
    cbi DDRB, 2
    cbi DDRB, 3
    cbi DDRB, 4
    cbi DDRB, 5
    ret

hex_to_seg:
    ; row = hex digit to display (0x0-0xF); r17 is aliased to row, tmp clobbered.
    cpi row, 0x0
    brne hts_1
    ldi tmp, (1 << 1) | (1 << 0)
    out PORTB, tmp
    ldi tmp, (1 << 2) | (1 << 3) | (1 << 5) | (1 << 6)
    out PORTD, tmp
    cbi PORTD, 7
    ret

hts_1:
    cpi row, 0x1
    brne hts_2
    ldi tmp, 0x00
    out PORTB, tmp
    ldi tmp, (1 << 2) | (1 << 3)
    out PORTD, tmp
    cbi PORTD, 7
    cbi PORTB, 0
    ret

hts_2:
    cpi row, 0x2
    brne hts_3
    ldi tmp, (1 << 1)
    out PORTB, tmp
    ldi tmp, (1 << 2) | (1 << 5) | (1 << 6) | (1 << 7)
    out PORTD, tmp
    cbi PORTD, 3
    ret

hts_3:
    cpi row, 0x3
    brne hts_4
    ldi tmp, (1 << 1)
    out PORTB, tmp
    ldi tmp, (1 << 2) | (1 << 3) | (1 << 5) | (1 << 7)
    out PORTD, tmp
    cbi PORTD, 6
    ret

hts_4:
    cpi row, 0x4
    brne hts_5
    ldi tmp, (1 << 0)
    out PORTB, tmp
    ldi tmp, (1 << 2) | (1 << 3) | (1 << 7)
    out PORTD, tmp
    ret

hts_5:
    cpi row, 0x5
    brne hts_6
    ldi tmp, (1 << 1) | (1 << 0)
    out PORTB, tmp
    ldi tmp, (1 << 3) | (1 << 5) | (1 << 7)
    out PORTD, tmp
    cbi PORTD, 6
    ret

hts_6:
    cpi row, 0x6
    brne hts_7
    ldi tmp, (1 << 1) | (1 << 0)
    out PORTB, tmp
    ldi tmp, (1 << 3) | (1 << 5) | (1 << 6) | (1 << 7)
    out PORTD, tmp
    ret

hts_7:
    cpi row, 0x7
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
    cpi row, 0x8
    brne hts_9
    ldi tmp, (1 << 1) | (1 << 0)
    out PORTB, tmp
    ldi tmp, (1 << 2) | (1 << 3) | (1 << 5) | (1 << 6) | (1 << 7)
    out PORTD, tmp
    ret

hts_9:
    cpi row, 0x9
    brne hts_A
    ldi tmp, (1 << 1) | (1 << 0)
    out PORTB, tmp
    ldi tmp, (1 << 2) | (1 << 3) | (1 << 5) | (1 << 7)
    out PORTD, tmp
    cbi PORTD, 6
    ret

hts_A:
    cpi row, 0xA
    brne hts_b
    ldi tmp, (1 << 1) | (1 << 0)
    out PORTB, tmp
    ldi tmp, (1 << 2) | (1 << 3) | (1 << 5) | (1 << 6) | (1 << 7)
    out PORTD, tmp
    cbi PORTD, 5
    ret

hts_b:
    cpi row, 0xB
    brne hts_C
    ldi tmp, (1 << 0)
    out PORTB, tmp
    ldi tmp, (1 << 2) | (1 << 3) | (1 << 5) | (1 << 6) | (1 << 7)
    out PORTD, tmp
    cbi PORTD, 2
    ret

hts_C:
    cpi row, 0xC
    brne hts_d
    ldi tmp, (1 << 1) | (1 << 0)
    out PORTB, tmp
    ldi tmp, (1 << 5) | (1 << 6)
    out PORTD, tmp
    ret

hts_d:
    cpi row, 0xD
    brne hts_E
    ldi tmp, 0x00
    out PORTB, tmp
    ldi tmp, (1 << 2) | (1 << 3) | (1 << 5) | (1 << 6) | (1 << 7)
    out PORTD, tmp
    ret

hts_E:
    cpi row, 0xE
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
