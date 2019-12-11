; UndertaleLite-F_Murphey-FinalProject.asm
;
; Created: 12/6/2019 9:09:40 AM
; Author : Fiona Murphey
; Lab Partner: Anthony Baron

; ------ Directives ------
.cseg		; start of Code Segment
.def		io_set = r16 ; Used to set up outputs on ports B, D
.def		workhorse = r17 ; multi-purpose register used to move bytes to/from ADCSRA and ADMUX (multiplexer)
.def		adc_value_low = r21 ; used to manipulate the low byte of the result of the ADC conversion
.def		adc_value_high = r22 ; used to manipulate high byte of the result of the ADC conversion
.def		y_val = r25 ; storage for incrementing bullets y-val
.def		player_x = r24 ; storage for x-val of player for rudimentary collision detection
.def		x_pos = r18 ; create alias for translated x-pos to be used by Kristof's libraries

.org		0x0000
rjmp		setup
.org		0x0100


.equ		OLED_WIDTH = 128;
.equ		OLED_HEIGHT = 64;

; libraries
.include		"lib_delay.asm"
.include		"lib_SSD1306_OLED.asm"
.include		"lib_GFX.asm"

; ------ Setup ------
setup:
	; OLED & GFX setup
	rcall		OLED_initialize
	rcall		GFX_clear_array
	rcall		GFX_refresh_screen

	; Potentiometer setup
	ldi			io_set, 0b00000000
	sts			PORTB_DIR, io_set ; set PORTDIR to input for B since potentiometer is set to PORTB (PB4)

	; Configure ADC
	ldi			workhorse, 0b00000001 ; use workhorse to store values to set up ADC
	sts			ADC0_CTRLA, workhorse ; set ADC enable

	ldi			workhorse, 0b00000000
	sts			ADC0_CTRLB, workhorse ; set ADC sample accumulation number to 0; 1 sample taken

	mov			x_pos, workhorse ; set x_pos to all 0's for future and operations

	ldi			workhorse, 0b00010001 ; set ADC prescaler to 4 (bit 0). Set voltage reference selection to VDD (bit 4).
	sts			ADC0_CTRLC, workhorse

	ldi			workhorse, 0b00001001 ; set MUX to AIN9 reading PB4 (set MUXPOS to 9 in binary)
	sts			ADC0_MUXPOS, workhorse ; selects which single-ended analog input is connected to the ADC

	ldi			y_val, 0b00000000 ; clear out y_val register (used to increment bullets y-coords)

	; Draw Flowey Head
	ldi			x_pos, 8
	ldi			r19, 0
	rcall		GFX_set_array_pos
	ldi			r20, 2
	st			X, r20
	; Draw Flowey Body
	ldi			r19, 1
	rcall		GFX_set_array_pos
	ldi			r20, 24
	st			X, r20

; ------ Loop ------
game_loop:
	rcall		gen_bullets
	rcall		move_player
	rcall		GFX_refresh_screen
	rjmp		game_loop

	; ADC store value in register (lab)
	; set port to input, listen for value at pin, set as analog, pass voltage into ADC
	; shift 10-bit value so that highest-order bits are the ones stored
	; break 0-1023 into 4 big categories
	; that should be x-direction position
	; One subroutine (change_x): read potentiometer, convert to ADC, shift, change                                                                                                           r18 (x-position)

; ------ change_x subroutine ------
; Potentiometer
change_x:
	;ldi			workhorse, 0b00000000
	;mov			x_pos, workhorse ; set x_pos to all 0's for future and operations

	ldi			workhorse, 0b00000001 ; use workhorse to store values into ADCSRA (ADC status register A)
	sts			ADC0_COMMAND, workhorse ; start conversion (ADSC)
	
		; Wait for ADC to finish
		wait_adc:
			lds		workhorse, ADC0_INTFLAGS ; load the value of INTFLAGS into workhorse - checks if measurement is complete
			cpi		workhorse, 0b00000001 ; test the interrupt flag
			breq	show
			rjmp	wait_adc ; if interrupt flag, which says it's done reading, isn't set, keep waiting

		show:
			lds		workhorse, ADC0_RES ; load ADC-ed values into general purpose registers
			mov		adc_value_low, workhorse ; ADC0_RES contains low byte we want, copy into adc_value_low
			lds		workhorse, ADC0_TEMP
			mov		adc_value_high, workhorse ; ADC0_TEMP contains high byte we want, copy into adc_value_high
			rcall	shift_and_change
			ret

		shift_and_change:
			rol			adc_value_low ; left shift low byte with carry--put MSB of low into carry bit
			rol			adc_value_high ; left shift high byte with carry--put MSB of low into LSB of high, LSB of high into carry bit (this is a status register thing)
			rol			adc_value_low ; left shift low byte with carry--put old LSB of high into LSB of low, put new MSB of low into carry bit
			rol			adc_value_high; left shift high byte with carry--put new MSB of low from carry bit into LSB of high--high now represents the 4 digits we want to use
			mov			x_pos, adc_value_high
				; copy shifted value into x_pos (position register (r18) used by Kristof's libraries) from potentiometer, i.e. adc_value_high which has now been shifted
			mov			player_x, x_pos
				; from -- .def		x_pos = r18 ; create alias for translated x-pos to be used by Kristof's libraries
			ret

	ret

; ------ gen_bullets subroutine (and related) ------
jmp_to_game_over1:
	rjmp game_over

jmp_to_check_y1:
	rjmp check_y

check_y:
	cpi			y_val, 0b00000110 ; throws the carry flag if y_val equals 6, i.e. that of the player
	breq		jmp_to_game_over1
	ret

gen_bullets:
	; Bullet 1 (x = 0)
	ldi			x_pos, 0 ; set x-pos
	mov			r19, y_val ; set y-pos
	cp			player_x, x_pos
	breq		jmp_to_check_y1
	;cpc			player_x, x_pos
	rcall		GFX_set_array_pos ; push to array handler
	ldi			r20, 15
	st			X, r20
	; Bullet 2 (x = 3)
	ldi			x_pos, 3 ; set x-pos
	mov			r19, y_val ; set y-pos
	;cpc			player_x, x_pos
	cp			player_x, x_pos
	breq		jmp_to_check_y1
	rcall		GFX_set_array_pos ; push to array handler
	ldi			r20, 15
	st			X, r20
	; Bullet 3 (x = 5)
	ldi			x_pos, 5 ; set x-pos
	mov			r19, y_val ; set y-pos
	;cpc			player_x, x_pos
	cp			player_x, x_pos
	breq		jmp_to_check_y1
	rcall		GFX_set_array_pos ; push to array handler
	ldi			r20, 15
	st			X, r20
	; Bullet 4 (x = 6)
	ldi			x_pos, 6 ; set x-pos
	mov			r19, y_val ; set y-pos
	;cpc			player_x, x_pos
	cp			player_x, x_pos
	breq		jmp_to_check_y1
	rcall		GFX_set_array_pos ; push to array handler
	ldi			r20, 15
	st			X, r20
	; Bullet 5 (x = 9)
	ldi			x_pos, 9 ; set x-pos
	mov			r19, y_val ; set y-pos
	;cpc			player_x, x_pos
	cp			player_x, x_pos
	breq		jmp_to_check_y2
	rcall		GFX_set_array_pos ; push to array handler
	ldi			r20, 15
	st			X, r20
	; Bullet 6 (x = 11)
	ldi			x_pos, 11 ; set x-pos
	mov			r19, y_val ; set y-pos
	;cpc			player_x, x_pos
	cp			player_x, x_pos
	breq		jmp_to_check_y2
	rcall		GFX_set_array_pos ; push to array handler
	ldi			r20, 15
	st			X, r20
	; Bullet 7 (x = 13)
	ldi			x_pos, 13 ; set x-pos
	mov			r19, y_val ; set y-pos
	;cpc			player_x, x_pos
	cp			player_x, x_pos
	breq		jmp_to_check_y2
	rcall		GFX_set_array_pos ; push to array handler
	ldi			r20, 15
	st			X, r20
	; Bullet 8 (x = 15)
	ldi			x_pos, 15 ; set x-pos
	mov			r19, y_val ; set y-pos
	;cpc			player_x, x_pos
	cp			player_x, x_pos
	breq		jmp_to_check_y2
	rcall		GFX_set_array_pos ; push to array handler
	ldi			r20, 15
	st			X, r20
	; Done generating

	; See if y_val has reached bottom without other flags getting thrown
	cpi			y_val, 0b00001111
	breq		reached_bottom
	
	inc			y_val
	rcall		delay_100ms
	rcall		delay_100ms
	rcall		delay_100ms
	ret

jmp_to_game_over2:
	rjmp game_over

jmp_to_check_y2:
	rjmp check_y

reached_bottom:
	; Print "DETERMINED"
	rcall	GFX_refresh_screen
	; D
	ldi		x_pos, 3
	ldi		r19, 4
	rcall	GFX_set_array_pos
	ldi		r20, 68
	st		X, r20
	; E
	ldi		x_pos, 4
	ldi		r19, 4
	rcall	GFX_set_array_pos
	ldi		r20, 69
	st		X, r20
	; T
	ldi		x_pos, 5
	ldi		r19, 4
	rcall	GFX_set_array_pos
	ldi		r20, 84
	st		X, r20
	; E
	ldi		x_pos, 6
	ldi		r19, 4
	rcall	GFX_set_array_pos
	ldi		r20, 69
	st		X, r20
	; R
	ldi		x_pos, 7
	ldi		r19, 4
	rcall	GFX_set_array_pos
	ldi		r20, 82
	st		X, r20
	; M
	ldi		x_pos, 8
	ldi		r19, 4
	rcall	GFX_set_array_pos
	ldi		r20, 77
	st		X, r20
	; I
	ldi		x_pos, 9
	ldi		r19, 4
	rcall	GFX_set_array_pos
	ldi		r20, 73
	st		X, r20
	; N
	ldi		x_pos, 10
	ldi		r19, 4
	rcall	GFX_set_array_pos
	ldi		r20, 78
	st		X, r20
	; E
	ldi		x_pos, 11
	ldi		r19, 4
	rcall	GFX_set_array_pos
	ldi		r20, 69
	st		X, r20
	; D
	ldi		x_pos, 12
	ldi		r19, 4
	rcall	GFX_set_array_pos
	ldi		r20, 68
	st		X, r20
	rcall	delay_1s
	rcall	delay_1s
	;rcall	GFX_clear_array
	;rcall	GFX_refresh_screen
	; exit game

game_over:
	; print "GAME OVER"
	rcall	GFX_refresh_screen
	; Invert Flowey Head
	ldi			x_pos, 8
	ldi			r19, 0
	rcall		GFX_set_array_pos
	ldi			r20, 1
	st			X, r20
	; G
	ldi		x_pos, 6
	ldi		r19, 3
	rcall	GFX_set_array_pos
	ldi		r20, 71
	st		X, r20
	; A
	ldi		x_pos, 7
	ldi		r19, 3
	rcall	GFX_set_array_pos
	ldi		r20, 65
	st		X, r20
	; M
	ldi		x_pos, 8
	ldi		r19, 3
	rcall	GFX_set_array_pos
	ldi		r20, 77
	st		X, r20
	; E
	ldi		x_pos, 9
	ldi		r19, 3
	rcall	GFX_set_array_pos
	ldi		r20, 69
	st		X, r20

	; O
	ldi		x_pos, 6
	ldi		r19, 5
	rcall	GFX_set_array_pos
	ldi		r20, 79
	st		X, r20
	; V
	ldi		x_pos, 7
	ldi		r19, 5
	rcall	GFX_set_array_pos
	ldi		r20, 86
	st		X, r20
	; E
	ldi		x_pos, 8
	ldi		r19, 5
	rcall	GFX_set_array_pos
	ldi		r20, 69
	st		X, r20
	; R
	ldi		x_pos, 9
	ldi		r19, 5
	rcall	GFX_set_array_pos
	ldi		r20, 82
	st		X, r20
	rcall	delay_1s
	rcall	delay_1s
	rcall	delay_1s
	;rcall	GFX_clear_array
	;rcall	GFX_refresh_screen
	; exit game

; ------ move_player subroutine ------
move_player:
		; Draw empty sprite on old location
		; x-pos already set
		mov			x_pos, player_x ; set x-pos to old x-pos
		ldi			r19, 6 ; set y-pos
		rcall		GFX_set_array_pos ; push coordinates to array handler

		; Draw empty sprite
		ldi			r20, 0 
		st			X, r20

		; Set new position
		rcall		change_x ; set new x-pos, y-pos doesn't change
		rcall		GFX_set_array_pos

		; Draw heart sprite
		ldi			r20, 3
		st			X, r20

		; refresh and loop
		;rcall		delay_1s
		;rcall		GFX_clear_array
		;rcall		GFX_refresh_screen

		ret

; ------ Old Code ------

; For shift_and_change
	;mov		workhorse, adc_value_low ; copy low-order byte of 10-bit ADC conversion into workhorse
	;lsr		workhorse ; 1
	;lsr		workhorse ; 2
	;lsr		workhorse ; 3
	;lsr		workhorse ; 4
	;lsr		workhorse ; 5
	;lsr		workhorse ; 6
	;or		x_pos_val, workhorse ; combine shifted low-order bit and finalized shift
	;mov		workhorse, adc_value_high ; copy high-order byte of 10-bit ADC conversion into workhorse
	;lsl		workhorse ; 1
	;lsl		workhorse ; 2
	;or		x_pos_val, workhorse ; combine shifted high-order bit and finalized shift
	;mov		x_pos_val, x_pos ; copy shifted value of x_pos from potentiometer into position register (r18) used by Kristof's libraries--r18 now has alias 
	;; what is OR?

; For game logic, OLED & GFX
			; set location to add letter
			;ldi			r18, 2
			;ldi			r19, 3
			;rcall		GFX_set_array_pos

			; draw the letter
			;ldi			r20, 70
			;st			X, r20

			; refresh and loop
			;rcall		GFX_refresh_screen
			;rjmp		loop