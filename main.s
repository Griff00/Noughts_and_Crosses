#include <xc.inc>


psect	code, abs
rst:	org	0x0000	; reset vector
	goto	start


	
start:	movlw	0x00
	movwf	TRISD, A
	movlw	0xff
	movwf	LATD, A
	goto	$	; Sit in infinite loop

	end	rst
