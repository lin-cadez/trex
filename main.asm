setup:

	
		
	  LDI   R16, 0xFF
      OUT   DDRD, R16         ;set port D o/p for data
      LDI   R16, 0b11110111
      OUT   DDRB, R16         ;set port B o/p for command
      CBI   PORTB, 0          ;EN = 0
      RCALL delay_ms          ;wait for LCD power on
      ;-----------------------------------------------------
      RCALL LCD_init          ;subroutine to initialize LCD
      ;-----------------------------------------------------
      LDI   R16, 0x01         ;clear LCD
      RCALL command_wrt       ;send command code
      RCALL delay_ms
      ;-----------------------------------------------------

loop:
	  //init values
	  SBI PORTB, 2 //BACKLIGHT ON
	  ldi r18, 1  //trex position r0
	  mov r0, r18
	  ldi r19, 13 //cactus poistion r1
	  mov r1, r19
	  ldi r20, 0x01 //vrstica_setter r2 trex
	  mov r2, r20

	  ldi r22, 0x00 //render_counter_total
	  ldi r23, 0 //last_jump_render
	  ldi r24, 0x00 //jump-length(temp)
	  clr r3 //score counter

	  ldi r16, 255 //nastavimo r4 na 0xFF
	  mov r4, r16  //r4 cactus speed register

	  clr r16
	  sts 0x0200, r16 //beleženje KIND and Enemy characterjev
	  clr r16 inc r16 //nastavi na 1
	  sts 0x0201, r16 //beleženje BACKLIGHT ON/OFF


	  render:
			dec r4 dec r4 dec r4; ZManjšamo za 3
			mov r16, r4
			RCALL render_delay
		  logic:
			
			dec r1
			inc r22

			//you won check
			game_won_check:
				mov r16, r0
				cpi r16, 14
				brne game_over_check
				rjmp GAME_ON

			//game-over check
			game_over_check:
				mov r16, r2
				cpi r16, 0x00
				breq  button_pressed_check

				mov r16, r0
				dec r16
				cp r16, r1
				breq game_over_bus

					
			//check for jump
			button_pressed_check:

				in_jump_check:
					cpi r24, 0x02
					breq set_second_row
					cpi r24, 0x01
					breq set_second_row

					cpi r24, 0x00
					breq button_pressed_check_bridge
					dec r24
					rjmp set_first_row

			button_pressed_check_bridge:
				sbic PINb,4
				rjmp button_press_jump
				rjmp set_second_row

			game_over_bus:
				lds r16, 0x0200
				cpi r16, 0b0000_0100
				breq kind_character_touch
				rjmp game_over

			kind_character_touch:
				inc r0
				rjmp button_pressed_check

			button_press_jump:
				ldi r24, 0x04 //nastavimo dolžino JUMPA
				rjmp set_first_row
			
			set_first_row:
				//set first row
				mov r23, r22
				ldi r20, 0x00
				mov r2, r20
				rjmp render_trex

				fall_down:
					clr r24
					rjmp set_second_row


			set_second_row:
				clr r24
				ldi r20, 0x01
				mov r2, r20
				rjmp render_trex
	
		  render_trex:
			mov r16, r2
			cpi r16, 0x00
			brne clear_first_row

			clear_second_row:
				mov r16, r0
				ldi r17, 0x01
				RCALL set_cursor_position
				ldi r16, ' ' //costum character
				RCALL data_wrt
				rjmp render_trex_char

			clear_first_row:
				mov r16, r0
				ldi r17, 0x00
				RCALL set_cursor_position
				ldi r16, ' ' //costum character
				RCALL data_wrt

				mov r16, r0
				subi r16, 1
				ldi r17, 0x00
				RCALL set_cursor_position
				ldi r16, ' ' //costum character
				RCALL data_wrt

				rjmp render_trex_char

			render_trex_char:
				mov r16, r0
				mov r17, r2
				RCALL set_cursor_position
				ldi r16, 0b11111100 //TREX
				RCALL data_wrt


		  render_cactus:

			ldi r17, 0x01
			mov r16, r1
			RCALL set_cursor_position


			//izbira costum characterja:

			lds r16, 0x0200
			cpi r16, 0b0000_0100
			breq kind_char

			enemy_char:
				ldi r16, 0b0111_1111 
				RCALL data_wrt
				rjmp render_cactus_bridge

			kind_char:
				ldi r16, 0b1111_1111
				RCALL data_wrt
				rjmp render_cactus_bridge

			render_cactus_bridge:
			ldi r17, 0x01
			mov r16, r1
			inc r16
			RCALL set_cursor_position
			ldi r16, ' ' //costum character
			RCALL data_wrt
			



		//check if backlight turned on/off
		mov r16, r0
		call remainder5
		cpi r16, 0x00
		brne backlight_on
		cbi   PORTB, 2 //BACKLIGHT OFF
		rjmp offscreen_check
		

		backlight_on:
			sbi   PORTB, 2 //BACKLIGHT ON



		//check if offscreen
		offscreen_check:
		mov r16, r1
		cpi r16, 0x00
		breq set_cactus_position_onscreen
		rjmp render

		set_cactus_position_onscreen:
			ldi r16, 15
			mov r1, r16 
		
			lds r16, 0x0200
			inc r16
			andi r16, 0b0000_0111
			sts 0x0200, r16

			ldi r17, 0x01
			ldi r16, 0x00
			RCALL set_cursor_position
			ldi r16, ' '
			RCALL data_wrt
			inc r3  //poveèamo score



      RJMP  render 

	  game_over:
		call game_over_sign

		call print_score

		aftermath:
			//delayamo, za long press
			ldi r17, 14
			long_press_detection_loop:
				ldi r16, 0xFF
				call render_delay
				dec r17
				tst r17
				brne long_press_detection_loop

			button_pressed_reset_activation:
				sbic PINb,4
				rjmp execute_reset
				rjmp aftermath

			execute_reset:
				//Èe dost èasa držimo:
				rjmp 0x00

			rjmp aftermath

		GAME_ON:
			call game_on_sign
			rjmp aftermath



;================================================================
LCD_init:
	  push r16
      LDI   R16, 0x33         ;init LCD for 4-bit data
      RCALL command_wrt       ;send to command register
      LDI   R16, 0x32         ;init LCD for 4-bit data
      RCALL command_wrt
      LDI   R16, 0x28         ;LCD 2 lines, 5x7 matrix
      RCALL command_wrt
      LDI   R16, 0x0C         ;disp ON, cursor OFF
      RCALL command_wrt
      LDI   R16, 0x01         ;clear LCD
      RCALL command_wrt
      LDI   R16, 0x06         ;shift cursor right
      RCALL command_wrt
	  pop r16
      RET  
;================================================================
command_wrt:
	  push r16
	  push r27
      MOV   R27, R16
      ANDI  R27, 0xF0         ;mask low nibble & keep high nibble
      OUT   PORTD, R27        ;o/p high nibble to port D
      CBI   PORTB, 1          ;RS = 0 for command
      SBI   PORTB, 0          ;EN = 1
      RCALL delay_short       ;widen EN pulse
      CBI   PORTB, 0          ;EN = 0 for H-to-L pulse
      RCALL delay_us          ;delay in micro seconds
      ;----------------------------------------------------
      MOV   R27, R16
      SWAP  R27               ;swap nibbles
      ANDI  R27, 0xF0         ;mask low nibble & keep high nibble
      OUT   PORTD, R27        ;o/p high nibble to port D
      SBI   PORTB, 0          ;EN = 1
      RCALL delay_short       ;widen EN pulse
      CBI   PORTB, 0          ;EN = 0 for H-to-L pulse
      RCALL delay_us          ;delay in micro seconds
	  ;---------------------------------------------------
	  pop r27
	  pop r16
      RET
;================================================================
data_wrt:
	  push  r16
	  push r27
      MOV   R27, R16
      ANDI  R27, 0xF0         ;mask low nibble & keep high nibble
      OUT   PORTD, R27        ;o/p high nibble to port D
      SBI   PORTB, 1          ;RS = 1 for data
      SBI   PORTB, 0          ;EN = 1
      RCALL delay_short       ;make wide EN pulse
      CBI   PORTB, 0          ;EN = 0 for H-to-L pulse
      RCALL delay_us          ;delay in micro seconds
      ;----------------------------------------------------
      MOV   R27, R16
      SWAP  R27               ;swap nibbles
      ANDI  R27, 0xF0         ;mask low nibble & keep high nibble
      OUT   PORTD, R27        ;o/p high nibble to port D
      SBI   PORTB, 0          ;EN = 1
      RCALL delay_short       ;widen EN pulse
      CBI   PORTB, 0          ;EN = 0 for H-to-L pulse
      RCALL delay_us          ;delay in micro seconds
	  pop r27
	  pop r16
      RET
;================================================================
delay_short:
      NOP
      NOP
      RET
;------------------------
delay_us:
	  push r20
      LDI   R20, 90
l3:   RCALL delay_short
      DEC   R20
      BRNE  l3
	  pop r20
      RET
;-----------------------
delay_ms:
	  push r21
      LDI   R21, 40
l4:   RCALL delay_us
      DEC   R21
      BRNE  l4
	  pop r21
      RET
;================================================================
render_delay:
//input v r16 (0-255)

	one_ms:
			ldi  r18, 10
			ldi  r19, 15
		L1: dec  r19
			brne L1
			dec  r18
			brne L1

			dec r16
			brne one_ms
	ret
;================================================================
set_cursor_position:
	push r16
	push r17

	mov r18, r17
	mov r17, r16
	cpi r18, 0x00
	brne second_row
	rjmp first_row
	
	second_row:
		ldi r16, 0xC0
		RCALL command_wrt
		RCALL delay_ms
		rjmp set_cursor_position_compare
	first_row:
		ldi r16, 0x80
		RCALL command_wrt
		RCALL delay_ms
		rjmp set_cursor_position_compare

	set_cursor_position_compare:
		cpi r17, 0x00
		breq set_cursor_position_end


	cursor_position_loop:
		ldi r16, 0x14
		RCALL command_wrt
		RCALL delay_ms
		dec r17
		brne cursor_position_loop
		rjmp set_cursor_position_end

	set_cursor_position_end:
		pop r17
		pop r16
		ret

;--------------------------------------------
random_number:
	add r16, r19
	swap r16
	adc r16, r20
	swap r16
	adc r16, r21
	swap r16
	adc r16, r22
	swap r16
	adc r16, r23
	adc r16, r0
	swap r16
	adc r16, r1
	lsl r16
	swap r16
	ror r16
	swap r16
	andi r16, 0b0000_1111
	ret
	
;--------------------------------------------
game_over_sign:
	ldi r16, 0
		RCALL set_cursor_position
		ldi r16, 'G'
		RCALL data_wrt
		ldi r16, 1
		RCALL set_cursor_position
		ldi r16, 'a'
		RCALL data_wrt
		ldi r16, 2
		RCALL set_cursor_position
		ldi r16, 'm'
		RCALL data_wrt
		ldi r16, 3
		RCALL set_cursor_position
		ldi r16, 'e'
		RCALL data_wrt
		ldi r16, 4
		RCALL set_cursor_position
		ldi r16, ' '
		RCALL data_wrt
		ldi r16, 5
		RCALL set_cursor_position
		ldi r16, 'o'
		RCALL data_wrt
		ldi r16, 6
		RCALL set_cursor_position
		ldi r16, 'v'
		RCALL data_wrt
		ldi r16, 7
		RCALL set_cursor_position
		ldi r16, 'e'
		RCALL data_wrt
		ldi r16, 8
		RCALL set_cursor_position
		ldi r16, 'r'
		RCALL data_wrt
		ldi r16, 9
		RCALL set_cursor_position
		ldi r16, '!'
		RCALL data_wrt
		ret

;--------------------------------------------
print_score:
		clr r17
		ldi r16, 0
		RCALL set_cursor_position

		ldi r16, 'S'
		RCALL data_wrt
		ldi r16, 'c'
		RCALL data_wrt
		ldi r16, 'o'
		RCALL data_wrt
		ldi r16, 'r'
		RCALL data_wrt
		ldi r16, 'e'
		RCALL data_wrt
		ldi r16, ' '
		RCALL data_wrt


		mov r16, r3
		RCALL convert_to_ascii
		mov r16, r19
		RCALL data_wrt
		RCALL delay_ms

		mov r16, r3
		RCALL convert_to_ascii
		mov r16, r18
		RCALL data_wrt
		RCALL delay_ms

		mov r16, r3
		RCALL convert_to_ascii
		mov r16, r17
		RCALL data_wrt
		RCALL delay_ms

		ldi r16, ' '
		RCALL data_wrt
		RCALL delay_ms
	
		ldi r17, 0x01
		ret

;--------------------------------------------

game_on_sign:
	ldi r16, 0
		RCALL set_cursor_position
		ldi r16, 'G'
		RCALL data_wrt
		ldi r16, 1
		RCALL set_cursor_position
		ldi r16, 'a'
		RCALL data_wrt
		ldi r16, 2
		RCALL set_cursor_position
		ldi r16, 'm'
		RCALL data_wrt
		ldi r16, 3
		RCALL set_cursor_position
		ldi r16, 'e'
		RCALL data_wrt
		ldi r16, 4
		RCALL set_cursor_position
		ldi r16, ' '
		RCALL data_wrt
		ldi r16, 5
		RCALL set_cursor_position
		ldi r16, 'O'
		RCALL data_wrt
		ldi r16, 6
		RCALL set_cursor_position
		ldi r16, 'N'
		RCALL data_wrt
		ldi r16, 7
		RCALL set_cursor_position
		ldi r16, ';'
		RCALL data_wrt
		ldi r16, 8
		RCALL set_cursor_position
		ldi r16, ')'
		RCALL data_wrt
		ret


;--------------------------------------------
convert_to_ascii:
	push r0
	push r1
	mov r17, r16
	call div
	call div
	push r19
	mov r17, r16
	ldi r18, 10
	mul r18, r19
	mov r20, r0
	call div
	sub r17, r20
	push r17
	mov r17, r16
	call div
	ldi r18, 10
	mul r17, r18
	mov r18, r0
	mov r19, r16
	sub r19, r18
	push r19
	clr r17
	clr r18
	clr r19
	ldi r20, '0'
	pop r17 //lsb
	pop r18
	pop r19 //msb
	add r17, r20
	add r18, r20
	add r19, r20
	clr r20
	pop r1
	pop r0
	ret

	div:
		clr r19
		ldi r18, 10
		div_loop:
			sub r17, r18
			brcs terminate
			inc r19	
			rjmp div_loop

	terminate:
		mov r17, r19
		ret
		
;--------------------------------------------
remainder5:
		push r17
		clr r17

	remainder5_loop:
		subi r16, 0x05
		brcs remainder5_test
		rjmp remainder5_loop

		remainder5_test:
			ldi r17, 0x05
			add r16, r17
			subi r16, 0x05
			breq remainder5_true
			rjmp remainder5_false
		remainder5_true:
			ldi r16, 0x00
			pop r17
			ret
		remainder5_false:
			ldi r17, 0x05
			add r16, r17
			pop r17
			ret
		