; --------------------------------------------------------------------------------
; --------------------------------------------------------------------------------
; lib_TWI
; Description: control of Two-Wire Interface on ATMega328PB without interrupts.
;     Heavily influenced by the datasheet.
; Author: Kristof Aldenderfer (aldenderfer.github.io)
; --------------------------------------------------------------------------------
; --------------------------------------------------------------------------------

; --------------------------------------------------------------------------------
; Description: equs for TWI return codes (not implemented)
; --------------------------------------------------------------------------------
.equ                        TWI_init_chk    = 0x08<<3
.equ                        TWI_ack_addr    = 0x18<<3
.equ                        TWI_ack_data    = 0x28<<3

; --------------------------------------------------------------------------------
; Description: initializes TWI device as master
; subroutine type:
;   - PUBLIC
; dependencies:
;   - none
; --------------------------------------------------------------------------------
TWI_master_intitialze:
                            in              r16, DDRC                               ; set up SDA/SCL as inputs
                            andi            r16, 0b11001111
                            out             DDRC, r16
                            ldi             r16, 0b00110000                         ; enable pullups on SDA/SCL
                            out             PORTC, r16
                            lds             r16, TWSR0                              ; set prescalar to 1 by clearing TWPS1 and TWPS0
                            andi            r16, 0b11111100
                            sts             TWSR0, r16
                            ldi             r16, 12                                 ; set freq to 400kHz
                            sts             TWBR0, r16                              ; TWBR = ((F_CPU / TWI_FREQ) - 16) / 2
                            ldi             r16, (1<<TWEN | 1<<TWIE)                ; turn on TWI
                            sts             TWCR0, r16
                            ret

; --------------------------------------------------------------------------------
; Description: generates a TWI START condition
; subroutine type:
;   - PUBLIC
; dependencies:
;   - none
; --------------------------------------------------------------------------------
TWI_gen_start:
                            ldi             r16, (1<<TWINT | 1<<TWSTA | 1<<TWEN)    ; generate START condition
                            sts             TWCR0, r16                              ; "
    TWI_gen_start_wait:
                            lds             r16, TWCR0
                            sbrs            r16, TWINT
                            rjmp            TWI_gen_start_wait
                            lds             r16, TWSR0                              ; check status of bus
                            andi            r16, 0b11111000
                            cpi             r16, TWI_init_chk
                            brne            TWI_error
                            ret

; --------------------------------------------------------------------------------
; Description: generates a TWI STOP condition
; subroutine type:
;   - PUBLIC
; dependencies:
;   - none
; --------------------------------------------------------------------------------
TWI_gen_stop:               
                            ldi             r16, (1<<TWINT | 1<<TWSTO | 1<<TWEN)
                            sts             TWCR0, r16                              ; generate STOP condition
                            ret

; --------------------------------------------------------------------------------
; Description: transmits TWI slave address
; subroutine type:
;   - PUBLIC
; dependencies:
;   - r18: slave address << 1 ORed with R/!W bit
; --------------------------------------------------------------------------------
TWI_transmit_slave_addr:
                            sts             TWDR0, r18                              ; write byte
                            ldi             r16, (1<<TWINT | 1<<TWEN)
                            sts             TWCR0, r16                              ; start transmiting
    TWI_transmit_slave_addr_wait:
                            lds             r16, TWCR0
                            sbrs            r16, TWINT
                            rjmp            TWI_transmit_slave_addr_wait
                            lds             r16, TWSR0                              ; did you get ACK?
                            andi            r16, 0b11111000
                            cpi             r16, TWI_ack_addr
                            brne            TWI_error
                            ret

; --------------------------------------------------------------------------------
; Description: transmits one byte of data over TWI
; subroutine type:
;   - PUBLIC
; dependencies:
;   - r18: byte to be sent
; --------------------------------------------------------------------------------
TWI_transmit_byte:
                            sts             TWDR0, r18                              ; write byte
                            ldi             r16, (1<<TWINT | 1<<TWEN)
                            sts             TWCR0, r16                              ; start transmiting
    TWI_transmit_byte_wait:
                            lds             r16, TWCR0
                            sbrs            r16, TWINT
                            rjmp            TWI_transmit_byte_wait
                            lds             r16, TWSR0                              ; did you get ACK?
                            andi            r16, 0b11111000
                            cpi             r16, TWI_ack_data
                            brne            TWI_error
                            ret

; --------------------------------------------------------------------------------
; Description: receives one byte of data over TWI. (This remains untested.)
; subroutine type:
;   - PUBLIC
; dependencies:
;   - r17: ACK or NACK (bit 0)
;   - r18: byte received ends up here
; --------------------------------------------------------------------------------
TWI_receive_byte:
                            ldi             r16, (1<<TWINT | 1<<TWEN)
                            or              r16, r17
                            sts             TWCR0, r16                              ; start transmiting
    TWI_receive_byte_wait:
                            lds             r16, TWCR0
                            sbrs            r16, TWINT
                            rjmp            TWI_receive_byte_wait
                            lds             r16, TWSR0                              ; did you get ACK?
                            andi            r16, 0b11111000
                            cpi             r16, TWI_ack_data
                            brne            TWI_error
                            lds             r18, TWDR0
                            ret

; --------------------------------------------------------------------------------
; Description: when TWI generates an error, you end up here. (Not implemented.)
; subroutine type:
;   - PRIVATE
; dependencies:
;   - none
; --------------------------------------------------------------------------------
_TWI_error:
                        nop
                        ret

; --------------------------------------------------------------------------------
.exit
; --------------------------------------------------------------------------------