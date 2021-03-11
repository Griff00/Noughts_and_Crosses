#include <xc.inc>

global  Keypad_Setup, Keypad_Read

psect	udata_acs   ; named variables in access ram
Keypad_Row_Code:	ds 1   ; reserve 1 byte for the code on the row
Keypad_Col_Code:	ds 1   ; reserve 1 byte for the code on the column
Keypad_output_char:	ds 1   ; reserve 1 byte for the output character
Keypad_cnt_l:	ds 1   ; reserve 1 byte for delay counter var
Keypad_cnt_h:	ds 1   ; reserve 1 byte for delay counter var
Keypad_cnt_ms:	ds 1   ; reserve 1 byte for delay counter var


psect	keypad_code,class=CODE
    
Keypad_Setup:
        movlb 0x0F
	bsf	REPU ;to pull all input values high - not doing that
	clrf    LATE, A	; make sure these are blank before reading from them
	movlw	0x00
	movwf	TRISD, A ;set up port d for outputs
	return

Keypad_Read:
    call Keypad_Read_Row
    call Keypad_Read_Col
    movf Keypad_Row_Code, W,A
    call Keypad_Validate_Pattern    ;leaves the relevnt char code in W
    movwf Keypad_output_char, A
    movff Keypad_output_char, PORTD, A	;Display output char code on PORTD LEDs
    movf Keypad_output_char, W, A   ;move output back to W
    return
    
Keypad_Read_Row: ;reads the row of the button being pressed
    movlw   10
    call    Keypad_delay_x4us	;40us delay- for the tris to sink in
    movlw   0x0F
    movwf   TRISE, A		;set E0-3 inputs, E4-7 outputs    
    movlw   10
    call    Keypad_delay_x4us	;40us delay- for the tris to sink in
    movf    PORTE, W, A		;Read value from keypad
    movwf   Keypad_Row_Code, A	;Store value    
    return

Keypad_Read_Col: ;reads the column of the button being pressed
    movlw   10
    call    Keypad_delay_x4us	;40us delay- for the tris to sink in
    movlw   0xF0
    movwf   TRISE, A		;set E0-3 outputs, E4-7 inputs    
    movlw   10
    call    Keypad_delay_x4us	;40us delay- for the tris to sink in
    movf    PORTE, W, A		;Read value from keypad
    movwf   Keypad_Col_Code, A	;Store value
    return

Keypad_Validate_Pattern: 
    movlw   0x0F
    cpfseq  Keypad_Row_Code, A	    
    goto    check_r1		    ;if there is a row pressed, go to main code
    movlw   0xF0
    cpfseq  Keypad_Col_Code, A	    ; if not, check if the col is zero too
    retlw   0xFF		    ;there's an error- a column is pressed but a row is not
    retlw   0x00		    ;there is nothing pressed
check_r1:
    movlw   00001110B
    cpfseq  Keypad_Row_Code, A	    ;see if row 1 is pressed
    bra	    check_r2
    bra	    check_c1_1
check_r2:
    movlw   00001101B
    cpfseq  Keypad_Row_Code, A	    ;see if row 2 is pressed
    bra	    check_r3
    bra	    check_c1_2
check_r3:
    movlw   00001011B
    cpfseq  Keypad_Row_Code, A	    ;see if row 3 is pressed
    bra	    check_r4
    bra	    check_c1_3
check_r4:   
    movlw   00000111B
    cpfseq  Keypad_Row_Code, A	    ;see if row 4 is pressed
    retlw   0xFF		    ;there's an error- multiple rows have been pressed
    bra	    check_c1_4

check_c1_1:
    movlw 11100000B
    cpfseq  Keypad_Col_Code, A	    ;see if column 1, row 1 is pressed
    bra	    check_c2_1
    retlw   '1'
check_c2_1:
    movlw 11010000B
    cpfseq  Keypad_Col_Code, A	    ;see if column 2, row 1 is pressed
    bra	    check_c3_1
    retlw   '4'
check_c3_1:
    movlw 10110000B
    cpfseq  Keypad_Col_Code, A	    ;see if column 3, row 1 is pressed
    bra	    check_c4_1
    retlw   '7'
check_c4_1:
    movlw 01110000B
    cpfseq  Keypad_Col_Code, A	    ;see if column 4, row 1 is pressed
    retlw   0xFF		    ;error: multiple columns pressed
    retlw   'A'

check_c1_2:
    movlw 11100000B
    cpfseq  Keypad_Col_Code, A	    ;see if column 1, row 2 is pressed
    bra	    check_c2_2
    retlw   '2'
check_c2_2:
    movlw 11010000B
    cpfseq  Keypad_Col_Code, A	    ;see if column 2, row 2 is pressed
    bra	    check_c3_2
    retlw   '5'
check_c3_2:
    movlw 10110000B
    cpfseq  Keypad_Col_Code, A	    ;see if column 3, row 2 is pressed
    bra	    check_c4_2
    retlw   '8'
check_c4_2:
    movlw 01110000B
    cpfseq  Keypad_Col_Code, A	    ;see if column 4, row 2 is pressed
    retlw   0xFF		    ;error: multiple columns pressed
    retlw   '0'

check_c1_3:
    movlw 11100000B
    cpfseq  Keypad_Col_Code, A	    ;see if column 1, row 3 is pressed
    bra	    check_c2_3
    retlw   '3'
check_c2_3:
    movlw 11010000B
    cpfseq  Keypad_Col_Code, A	    ;see if column 2, row 3 is pressed
    bra	    check_c3_3
    retlw   '6'
check_c3_3:
    movlw 10110000B
    cpfseq  Keypad_Col_Code, A	    ;see if column 3, row 3 is pressed
    bra	    check_c4_3
    retlw   '9'
check_c4_3:
    movlw 01110000B
    cpfseq  Keypad_Col_Code, A	    ;see if column 4, row 3 is pressed
    retlw   0xFF		    ;error: multiple columns pressed
    retlw   'B'

check_c1_4:
    movlw 11100000B
    cpfseq  Keypad_Col_Code, A	    ;see if column 1, row 4 is pressed
    bra	    check_c2_4
    retlw   'F'
check_c2_4:
    movlw 11010000B
    cpfseq  Keypad_Col_Code, A	    ;see if column 2, row 4 is pressed
    bra	    check_c3_4
    retlw   'E'
check_c3_4:
    movlw 10110000B
    cpfseq  Keypad_Col_Code, A	    ;see if column 3, row 4 is pressed
    bra	    check_c4_4
    retlw   'D'
check_c4_4:
    movlw 01110000B
    cpfseq  Keypad_Col_Code, A	    ;see if column 4, row 4 is pressed
    retlw   0xFF		    ;error: multiple columns pressed
    retlw   'C'
    
; ** a few delay routines below here that have been stolen from the LCD code <3 ****
Keypad_delay_x4us:		    ; delay given in chunks of 4 microsecond in W
	movwf	Keypad_cnt_l, A	; now need to multiply by 16
	swapf   Keypad_cnt_l, F, A	; swap nibbles
	movlw	0x0f	    
	andwf	Keypad_cnt_l, W, A ; move low nibble to W
	movwf	Keypad_cnt_h, A	; then to LCD_cnt_h
	movlw	0xf0	    
	andwf	Keypad_cnt_l, F, A ; keep high nibble in Keypad_cnt_l
	call	Keypad_delay
	return

Keypad_delay:			; delay routine	4 instruction loop == 250ns	    
	movlw 	0x00		; W=0
kpdlp1:	decf 	Keypad_cnt_l, F, A	; no carry when 0x00 -> 0xff
	subwfb 	Keypad_cnt_h, F, A	; no carry when 0x00 -> 0xff
	bc 	kpdlp1		; carry, then loop again
	return			; carry reset so return


    end





