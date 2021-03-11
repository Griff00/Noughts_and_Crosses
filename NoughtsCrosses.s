#include <xc.inc>

global  NCSwitchTurn
    
psect	udata_acs   ; named variables in access ram
NCCurrentTurn: ds 1

psect	nc_code, class=CODE
    
NCSwitchTurn:
	;if currently O, switch to X
	movlw   0x4F ;code for O 
	cpfseq NCCurrentTurn, A 
	bra switchtoX
	;if currently X, switch to O
	movlw   0x58 ;code for X
	cpfseq NCCurrentTurn, A 
	bra switchtoO
    switchtoX:
	movlw 0x58
	movwf NCCurrentTurn, A
	return
    switchtoO:	
	movlw 0x4F
	movwf NCCurrentTurn, A
	return

end
