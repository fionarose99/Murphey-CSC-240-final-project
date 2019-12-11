; --------------------------------------------------------------------------------
; --------------------------------------------------------------------------------
; lib_GFX
; Description: controls higher-level functionaity for OLED screens.
; Author: Kristof Aldenderfer (aldenderfer.github.io)
; Dependencies:
;   - some lower-level screen library, such as lib_SSD1306_OLED
; --------------------------------------------------------------------------------
; --------------------------------------------------------------------------------

; --------------------------------------------------------------------------------
; Description: reserved space in data memory for pixel array (full screen) and.
;              sprite array (one 8pixel x 8pixel character)
; --------------------------------------------------------------------------------
.dseg
sprite:                     .byte           8                                       ; 8x8 pixel shape used to store sprite
pixel_array:                .byte           HEIGHT*WIDTH/8                          ; datamem array that is written to screen
.cseg                                                                               ; return to code segment
.include                    "character_map.asm"                                     ; table of ascii pixel char arrays

; --------------------------------------------------------------------------------
; Description: calculates exact location in pixel array (X-pointer).
;              Used to display something at that location.
;              Note - to find array location: loc = ((y)/8)*WIDTH) + x .
; Subroutine type:
;   - PUBLIC
; Dependencies:
;   - r18: pixel grid x position [subroutine does not change this value]
;   - r19: pixel grid y position [subroutine does not change this value]
;   - r20: location to store the remainder (for calculating y-offset)
; --------------------------------------------------------------------------------
GFX_set_array_pos:     
                            push            r0                                      ; push all used registers to preserve them
                            push            r1
                            push            r16
                            push            r17
                            ldi             XL, low(pixel_array<<1)
                            ldi             XH, high(pixel_array<<1)
                            mov             r16, r19                                ; copy y position
                            andi            r16, (HEIGHT-1)/8                       ; get remainder (for vert byte position)
                            ldi             r20, 0x80                               ; load a single bit to be rshifted into place (bit order reversed, which is function of the screen)
    GFX_set_array_pos_bit_place:
                            cpi             r16, 0x00                               ; are we done shifting?
                            breq            GFX_set_array_pos_cont
                            dec             r16                                     ; sub 1 from number of shifts
                            lsr             r20                                     ; shift bit by one
                            rjmp            GFX_set_array_pos_bit_place
    GFX_set_array_pos_cont:
                            mov             r16, r19                                ; copy y position; will hold result
                            lsr             r16                                     ; i = y/8
                            lsr             r16
                            lsr             r16
                            ldi             r17, WIDTH                              ; prep WIDTH
                            mul             r16, r17                                ; j = i*W

                            add             r0, r18                                 ; loc = j + x
                            brcc            GFX_set_array_pos_end                   ; if a carry, must inc the result's high byte
                            inc             r1
    GFX_set_array_pos_end:
                            add             XL, r0                                  ; add calculated location to pointer
                            adc             XH, r1
                            pop             r17                                     ; reinstate all pushed registers
                            pop             r16
                            pop             r1
                            pop             r0
                            ret

; --------------------------------------------------------------------------------
; Description: blanks an 8pix by 8pix block.
; Subroutine type:
;   - PUBLIC
; Dependencies:
;   - X-pointer loaded with pixel_array location to draw
; --------------------------------------------------------------------------------
GFX_draw_blank:
                            push            r16
                            push            r17
                            clr             r16
                            clr             r17
    GFX_draw_blank_loop:
                            st              X+, r17
                            inc             r16
                            cpi             r16, 8
                            breq            GFX_draw_blank_end
                            rjmp            GFX_draw_blank_loop
    GFX_draw_blank_end:
                            pop             r17
                            pop             r16
                            ret

; --------------------------------------------------------------------------------
; Description: draws character to the array (8pix x 8pix).
; Subroutine type:
;   - PUBLIC
; Dependencies:
;   - X-pointer loaded with pixel_array location to draw
; --------------------------------------------------------------------------------
GFX_draw_shape:
                            push            r16
                            push            r17
                            clr             r16
                            ldi             YL, low(sprite<<1)
                            ldi             YH, high(sprite<<1)
    GFX_draw_shape_loop:
                            ld              r17, Y+
                            st              X+, r17
                            inc             r16
                            cpi             r16, 8
                            breq            GFX_draw_shape_end
                            rjmp            GFX_draw_shape_loop
    GFX_draw_shape_end:
                            pop             r17
                            pop             r16
                            ret

; --------------------------------------------------------------------------------
; Description: sets sprite to whatever char the Z pointer was prepped to.
;              This should used when you're using the supplied character_map.asm
;              byte table.
; Subroutine type:
;   - PUBLIC
; Dependencies:
;   - Z-pointer: loaded with program-memory character location
; --------------------------------------------------------------------------------
GFX_set_shape:
                            push            r16
                            push            r17
                            clr             r16
                            ldi             YL, low(sprite<<1)
                            ldi             YH, high(sprite<<1)
    GFX_set_shape_loop:
                            lpm             r17, Z+
                            st              Y+, r17
                            inc             r16
                            cpi             r16, 8
                            breq            GFX_set_shape_end
                            rjmp            GFX_set_shape_loop
    GFX_set_shape_end:
                            pop             r17
                            pop             r16
                            ret

; --------------------------------------------------------------------------------
; Description: clears array of all information (equivalent to clearing the screen).
; Subroutine type:
;   - PUBLIC
; Dependencies:
;   - none
; --------------------------------------------------------------------------------
GFX_clear_array:
                            push            r17
                            push            r18
                            push            r19
                            clr             r17
                            clr             r18
                            clr             r19
                            ldi             XL, low(pixel_array<<1)
                            ldi             XH, high(pixel_array<<1)
    GFX_clear_col:                                                                  ; for each col
                            cpi             r19, HEIGHT/8
                            brcc            GFX_clear_done
        GFX_clear_row:                                                              ; for each row
                            cpi             r18, WIDTH
                            brcc            GFX_clear_nr
                            st              X+, r17
                            inc             r18
                            rjmp            GFX_clear_row
            GFX_clear_nr:                                                           ; move to next row
                            clr             r18
                            inc             r19
                            rjmp            GFX_clear_col
    GFX_clear_done:                                                                 ; done clearing
                            pop             r19
                            pop             r18
                            pop             r17
                            ret

; --------------------------------------------------------------------------------
.exit
; --------------------------------------------------------------------------------