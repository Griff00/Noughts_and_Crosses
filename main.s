#include <xc.inc>
extrn NC_Run_Game, Keypad_Setup, Keypad_Read

psect	code, abs
rst:	org	0x0000	; reset vector
	goto	start


	
start:	;movlw	0x00
;	movwf	TRISD, A
;	movlw	0xff
;	movwf	LATD, A
	call Keypad_Setup
    game_loop:
	call NC_Run_Game
	
	goto	game_loop	; Sit in infinite loop

	end	rst
