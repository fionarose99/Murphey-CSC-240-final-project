; --------------------------------------------------------------------------------
; --------------------------------------------------------------------------------
; lib_SPI
; Description: control of Serial Peripherl Interface on ATMega328 without interrupts.
;     Heavily influenced by the datasheet.
; Author: Kristof Aldenderfer (aldenderfer.github.io)
; --------------------------------------------------------------------------------
; --------------------------------------------------------------------------------

; --------------------------------------------------------------------------------
; Description: initializes SPI device as master
; subroutine type:
;   - PUBLIC
; dependencies:
;   - none
; --------------------------------------------------------------------------------
SPI_master_initialize:
                            ldi             r16, (1<<SPE)|(1<<MSTR)                 ; enable SPI to master mode, disable interrupt, set shift
                            out             SPCR0, r16                              ; rate to 4 MHz, shift data on rising edge, MSB first, SCK idle low
                            in              r16, SPSR0                              ; clear flags and disable double baud rate
                            in              r16, SPDR0                              ; "
                            ldi             r16, 0                                  ; clear SPI2X bit
                            out             SPSR0, r16                              ; "
                            ret

; --------------------------------------------------------------------------------
; Description: initializes SPI device as slave
; subroutine type:
;   - PUBLIC
; dependencies:
;   - none
; --------------------------------------------------------------------------------
SPI_slave_initialize:
                            ldi             r16, (1<<SPE)|(0<<MSTR)                 ; enable SPI to slave mode, disable interrupt, set shift
                            out             SPCR0, r16                              ; rate to 4 MHz, shift data on rising edge, MSB first, SCK idle low
                            in              r16, SPSR0                              ; clear flags and disable double baud rate
                            in              r16, SPDR0                              ; "
                            ldi             r16, 0                                  ; clear SPI2X bit
                            out             SPSR0, r16                              ; "
                            ret

; --------------------------------------------------------------------------------
; Description: sends a byte of information from the master
; subroutine type:
;   - PUBLIC
; dependencies:
;   - r17: byte to be sent
; --------------------------------------------------------------------------------
SPI_master_transmit:
                            out             SPDR0, r17                              ; Start transmission of data
    SPI_master_transmit_wait:
                            in              r16, SPSR0
                            sbrs            r16, SPIF                               ; wait until SPIF is set
                            rjmp            SPI_master_transmit_wait                ; "
                            in              r16, SPDR0                              ; clear the SPIF flag
                            ret

; --------------------------------------------------------------------------------
; Description: receives a byte of information from the slave
; Subroutine type:
;   - PUBLIC
; Dependencies:
;   - r17: byte received ends up here
; --------------------------------------------------------------------------------
SPI_master_receive:
                            out             SPDR0, r16                              ; Start transmission of data
    SPI_slave_receive_wait:
                            in              r16, SPSR0
                            sbrs            r16, SPIF                               ; wait until SPIF is set
                            rjmp            SPI_slave_receive_wait                  ; "
                            in              r17, SPDR0                              ; fetch data and clear SPIF flag
                            ret

; --------------------------------------------------------------------------------
; Description: sends a byte of infomation from the slave
; Subroutine type:
;   - PUBLIC
; Dependencies:
;   - r17: byte to be sent
; --------------------------------------------------------------------------------
SPI_slave_transmit:
                            out             SPDR0, r17                              ; Start transmission of data
    SPI_slave_transmit_wait:
                            in              r16, SPSR0
                            sbrs            r16, SPIF                               ; wait until SPIF is set
                            rjmp            SPI_slave_transmit_wait                 ; "
                            in              r16, SPDR0                              ; clear the SPIF flag
                            ret

; --------------------------------------------------------------------------------
; Description: receives a byte of infomation from the master
; Subroutine type:
;   - PUBLIC
; Dependencies:
;   - r17: byte received ends up here
; --------------------------------------------------------------------------------
SPI_slave_receive:
                            in              r16, SPSR0
                            sbrs            r16, SPIF                               ; wait until SPIF is set
                            rjmp            SPI_slave_receive                       ; "
                            in              r17, SPDR0                              ; clear the SPIF flag
                            ret

; --------------------------------------------------------------------------------
.exit
; --------------------------------------------------------------------------------