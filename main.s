#include <xc.inc>

extrn	DAC_Setup, DAC_Int_Hi

psect	code, abs
rst:	org	0x0000	;reset vector
	goto	start

;When interupt flagged, this is branched to
int_hi:	org	0x0008	; high vector, no low vector
	goto	DAC_Int_Hi
	
start:	call	DAC_Setup
	goto	$	; Sit in infinite loop waiting for interrupt

	end	rst

	
