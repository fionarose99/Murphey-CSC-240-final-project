Make Ball Appear on OLED (thanks Anthony):

.cseg ; start of code segment
.org 0x0000
rjmp setup
.org 0x0100


.equ OLED_WIDTH = 128;
.equ OLED_HEIGHT = 64;

;libraries
.include "lib_delay.asm"
.include "lib_SSD1306_OLED.asm"
.include "lib_GFX.asm"

setup:
rcall OLED_initialize
rcall GFX_clear_array
rcall GFX_refresh_screen

///////////////////////////////////

gameLoop:
shootBall:
;set location to add letter
ldi r18 , 1
ldi r19, 0
rcall GFX_set_array_pos

;draw the letter
ldi r20, 7
st X, r20

rcall GFX_refresh_screen
rjmp moveBall



//moveBall is called to move ball across the screen. It will need a starting location to be changedd
moveBall:
rcall delay_100ms
cpi r18,15
breq score
//I will erase old ball right here
rcall GFX_set_array_pos
ldi r20, 00
st X, r20

inc r18
rcall GFX_set_array_pos
ldi r20, 7
st X, r20
rcall GFX_refresh_screen
rjmp moveBall

score:
rcall GFX_set_array_pos
ldi r20, 00
st X, r20
rcall GFX_refresh_screen
ret