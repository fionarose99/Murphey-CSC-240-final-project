# Alpha
## OUTLINE
pre-setup:
- initialize OLED height
- initialize OLED width
- set up libraries

setup:
- initialize OLED screen
- initialize pointer array(s) for OLED
- refresh screen
- set port for potentiometer
- configure ADC
    + enable
    + set number of samples to 1 (ADC0_CTRL)
    + set prescaler
    + set multiplexer
- zero out a register for determining x-positions
- draw Flowey

game_loop:
- move player
    + zero out x-position array
    + sample from ADC/potentiometer
    + configure resulting value to work as 4-bit input
    + erase previous player sprite
    + set x-position based on adjusted potentiometer value
    + draw sprite at x-position, fixed y-position
- generate bullets
    + generate random number
    + instantiate bullet at x-position = random number, y-position 0
    + increase y-position by 1 for each loop
    + generate next bullet
- refresh screen
- loop

## SCHEMATIC
- middle pin of potentiometer to PB4
- potentiometer grounded, powered to 5V on attiny416
- DATA of OLED to PA1
- CLK of OLED to PA3
- DC of OLED to PA6
- RST of OLED to PA5
- CS to PA4

## OLED has been functioning