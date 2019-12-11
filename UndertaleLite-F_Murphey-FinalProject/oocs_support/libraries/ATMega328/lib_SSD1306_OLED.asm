; --------------------------------------------------------------------------------
; --------------------------------------------------------------------------------
; lib_SSD1306_OLED
; Description: basic control for Adafruit SSD1306 OLED screen (via SPI only)
;     on ATMega328.
; Author: Kristof Aldenderfer (aldenderfer.github.io)
; --------------------------------------------------------------------------------
; --------------------------------------------------------------------------------

; --------------------------------------------------------------------------------
; Description: directives
; --------------------------------------------------------------------------------
.equ                        SPI_MOSI        = PORTB3 ; 11
.equ                        SPI_MISO        = PORTB4 ; 12
.equ                        SPI_CLK         = PORTB5 ; 13
.equ                        OLED_RST        = PORTB1 ; 9
.equ                        OLED_DC         = PORTB0 ; 8
.equ                        OLED_CS         = PORTB2 ; 10

.equ                        WIDTH           = 128                                   ; adjust your screen dimensions here
.equ                        HEIGHT          = 64                                    ; "

.include                    "lib_SPI.asm"                                           ; include SPI library

; --------------------------------------------------------------------------------
; Description: initialises OLED screen.
; Subroutine type:
;   - PUBLIC
; Dependencies:
;   - none
; --------------------------------------------------------------------------------
OLED_initialize:
                            rcall           SPI_master_initialize
                            ldi             r16, (1<<SPI_MOSI)|(1<<SPI_CLK)|(1<<OLED_RST)|(1<<OLED_DC)|(1<<OLED_CS)
                            out             DDRB, r16
                            ldi             r16, 0
                            out             PORTB, r16
                            
                            sbi             PORTB, OLED_RST
                            rcall           delay_1ms
                            cbi             PORTB, OLED_RST
                            rcall           delay_1ms
                            sbi             PORTB, OLED_RST
                            rcall           delay_1ms
                            ldi             ZL, low(array_OLED_init_commands<<1)
                            ldi             ZH, high(array_OLED_init_commands<<1)
    OLED_init_cmds:
                            lpm             r17, Z+
                            cpi             r17, 0xFF
                            breq            OLED_init_end
                            rcall           _OLED_write_command
                            rjmp            OLED_init_cmds
    OLED_init_end:
                            ret

; --------------------------------------------------------------------------------
; Description: writes a command to one of the screen's registers.
; Subroutine type:
;   - PRIVATE
; Dependencies:
;   - r17: command
; --------------------------------------------------------------------------------
_OLED_write_command:
                            cbi             PORTB, OLED_CS
                            cbi             PORTB, OLED_DC
                            rcall           SPI_master_transmit
                            sbi             PORTB, OLED_CS
                            ret

; --------------------------------------------------------------------------------
; Description: writes a byte of data to one of the screen's registers.
; Subroutine type:
;   - PRIVATE
; Dependencies:
;   - r17: data
; --------------------------------------------------------------------------------
_OLED_write_data:
                            cbi             PORTB, OLED_CS
                            sbi             PORTB, OLED_DC
                            rcall           SPI_master_transmit
                            sbi             PORTB, OLED_CS
                            ret

; --------------------------------------------------------------------------------
; Description: sets target x-y location on OLED. (This may be deprecated.)
; Subroutine type:
;   - PRIVATE
; Dependencies:
;   - r18: pixel grid x position [subroutine does not change this]
;   - r19: pixel grid y position [subroutine does not change this]
; --------------------------------------------------------------------------------
_OLED_set_screen_loc:
                            rcall           _OLED_set_page
                            rcall           _OLED_set_col
                            ret

; --------------------------------------------------------------------------------
; Description: sets target column. (This may be deprecated.)
; Subroutine type:
;   - PRIVATE
; Dependencies:
;   - r18: pixel grid x position [subroutine does not change this]
; --------------------------------------------------------------------------------
_OLED_set_col:               
                            ldi             r17, 0x21
                            rcall           _OLED_write_command
                            mov             r17, r18
                            rcall           _OLED_write_command
                            ldi             r17, WIDTH-1
                            rcall           _OLED_write_command
                            ret

; --------------------------------------------------------------------------------
; Description: sets target page. (This may be deprecated.)
; Subroutine type:
;   - PRIVATE
; Dependencies:
;   - r19: pixel grid y position [subroutine does not change this]
; --------------------------------------------------------------------------------
_OLED_set_page:
                            ldi             r17, 0x22
                            rcall           _OLED_write_command
                            lsr             r19
                            lsr             r19
                            lsr             r19
                            mov             r17, r19
                            rcall           _OLED_write_command
                            ldi             r17, (HEIGHT-1)/8
                            rcall           _OLED_write_command
                            ret

; --------------------------------------------------------------------------------
; Description: writes the entire pix array from dmem to OLED.
; Subroutine type:
;   - PUBLIC
; Dependencies:
;   - X pointer: set to start of array location
; --------------------------------------------------------------------------------
OLED_refresh_screen:
                            push            r18
                            push            r19
                            clr             r18
                            clr             r19
    OLED_refresh_screen_col:                                                        ; for each col
                            cpi             r19, HEIGHT/8
                            brcc            OLED_refresh_screen_done
        OLED_refresh_screen_row:                                                    ; for each row
                            cpi             r18, WIDTH
                            brcc            OLED_refresh_screen_nr
                            ld              r17, X+
                            rcall           _OLED_write_data
                            inc             r18
                            rjmp            OLED_refresh_screen_row
            OLED_refresh_screen_nr:                                                 ; move to next row
                            clr             r18
                            inc             r19
                            rjmp            OLED_refresh_screen_col
    OLED_refresh_screen_done:                                                       ; done drawing array
                            pop             r19
                            pop             r18
                            ret

; --------------------------------------------------------------------------------
; Description: initialisation sequence for screen.
; Nicked from https://github.com/adafruit/Adafruit_SSD1306/blob/master/Adafruit_SSD1306.cpp
; (Starts on line 543.)
; Comments below are on separate lines because Atmel Studio doesn't like inline comments on continued lines.
; --------------------------------------------------------------------------------
array_OLED_init_commands:   .db             0xAE, \
                                            0xD5, 0x80, \
                                            0xA8, 0x3F, \
                                            0xD3, 0x00, \
                                            0x40, \
                                            0x8D, 0x14, \
                                            0x20, 0x00, \
                                            0xA1, \
                                            0xC8, \
                                            0xDA, 0x12, \
                                            0x81, 0xCF, \
                                            0xD9, 0xF1, \
                                            0xDB, 0x40, \
                                            0xA4, \
                                            0xA6, \
                                            0x2E, \
                                            0xAF, \
                                            0xFF, 0xFF

                                            ; set disp (off),
                                            ; set disp clock div rat/osc freq
                                            ; set mux ratio
                                            ; set disp offset
                                            ; set disp start line (0)
                                            ; enable charge pump reg
                                            ; set mem addr mode - horiz
                                            ; set seg remap (remapped)
                                            ; set COM out scan dir (remapped)
                                            ; set com pins hw config
                                            ; set contrast ctrl
                                            ; set prechrg per
                                            ; set Vcom reg out
                                            ; entire disp (on)
                                            ; set inverse/normal (norm)
                                            ; deactivate scroll (deactivate)
                                            ; set disp (on)
                                            ; END COMMAND SET (author's marker)

; --------------------------------------------------------------------------------
.exit
; --------------------------------------------------------------------------------