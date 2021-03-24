#include <xc.inc>
extrn NC_Run_Game, Keypad_Setup, Keypad_Read
extrn	DAC_Setup, DAC_Int_Hi
psect	code, abs
rst:	org	0x0000	; reset vector
	goto	start

int_high: org 0x0008 ;the place to go when interrupts happen
	call DAC_Int_Hi
start:	
	call Keypad_Setup
	call DAC_Setup
	goto $ 
	
    game_loop:
	call NC_Run_Game
	
	goto	game_loop	; Sit in infinite loop

	end	rst
