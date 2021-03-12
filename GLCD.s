#include <xc.inc>

global  GLCD_Setup, GLCD_Write_Data, GLCD_Status, GLCD_Read

psect	udata_acs   ; Most of these vars are used in Delay subroutines
GLCD_cnt_l:	ds 1	
GLCD_cnt_h:	ds 1	
GLCD_cnt_ms:	ds 1	
GLCD_tmp:	ds 1	
GLCD_counter:	ds 1	

PSECT	udata_acs_ovr,space=1,ovrld,class=COMRAM
	GLCD_CS1 EQU 0	; Label Port B control pins
	GLCD_CS2 EQU 1	    
 	GLCD_RS  EQU 2	    
 	GLCD_RW  EQU 3	       
	GLCD_E	 EQU 4	
    	GLCD_RST EQU 5

psect	glcd_code,class=CODE
    
GLCD_Setup:
	clrf	TRISB, A    ;Port B Output
	clrf	TRISD, A    ;Port D Output
	clrf	LATB, A	    ;Set all B control pins low
	
	bsf	LATB, GLCD_CS1, A   ;Select segment 1 (CS1 high)
	bcf	LATB, GLCD_CS2, A   ;keep CS2 low
	
	bcf	LATB, GLCD_RST, A  ; RST = 0 (reset)
	movlw   40		;40ms delay
	call	GLCD_delay_ms
	
	bsf	LATB, GLCD_RST, A   ; RST = 1 (not reset)
	
	movlw   40		;40ms delay
	call	GLCD_delay_ms
		
	movlw	0x3e
	call	GLCD_Send_I	;display off
	movlw	0x40		
	call	GLCD_Send_I	; Set y address = 0
	movlw	0xb8	
	call	GLCD_Send_I	; Set x address = 0
	movlw	0xc0
	call	GLCD_Send_I	; set z address = 0
	movlw	0x3f
	call	GLCD_Send_I	;display on
	return
	
GLCD_Status:
    
	movlw	0x40		
	call	GLCD_Send_I	; Set y address = 0
	movlw	0xb8	
	call	GLCD_Send_I	; Set x address = 0
	movlw	0xc0
	call	GLCD_Send_I	; set z address = 0
    
	bcf	LATB, GLCD_RS, A 
	bsf	LATB, GLCD_RW, A
	clrf	LATD, A
	clrf	PORTD, A
	clrf	LATF, A
	movlw	0xff
	movwf	TRISD, A
	movlw	0x00
	movwf	TRISF, A
	
	movlw	10		; wait 40us delay
	call	GLCD_delay_x4us
	
	bsf	LATB, GLCD_E, A	    ; Take E high
	
	movlw	1		; wait 4us delay
	call	GLCD_delay_x4us
	
	movf	PORTD, W, A
	movwf	LATF, A	
	
	bcf	LATB, GLCD_E, A	    ; Take E low
	
	movlw	10		; wait 40us delay
	call	GLCD_delay_x4us
	return
	
	
GLCD_Read:
    
	movlw	0x40		
	call	GLCD_Send_I	; Set y address = 0
	movlw	0xb8	
	call	GLCD_Send_I	; Set x address = 0
	movlw	0xc0
	call	GLCD_Send_I	; set z address = 0
    
	bsf	LATB, GLCD_RS, A 
	bsf	LATB, GLCD_RW, A
	clrf	LATD, A
	clrf	PORTD, A
	clrf	LATE, A
	movlw	0xff
	movwf	TRISD, A
	movlw	0x00
	movwf	TRISE, A
	
	movlw	10		; wait 40us delay
	call	GLCD_delay_x4us
	
	bsf	LATB, GLCD_E, A	    ; Take E high
	
	movlw	1		; wait 4us delay
	call	GLCD_delay_x4us
	
	movf	PORTD, W, A
	movwf	LATE, A	
	
	bcf	LATB, GLCD_E, A	    ; Take E low
	
	movlw	10		; wait 40us delay
	call	GLCD_delay_x4us
	return	
	
GLCD_Write_Data:
	movwf	LATD, A		; WREG --> PortD
	bcf	LATB, GLCD_RW, A    
	bsf	LATB, GLCD_RS, A    ;Set RS high (data)
	call	GLCD_Enable	; Pulse E high then low 
	return	
	
GLCD_Send_I:	
	movwf	LATD, A		; WREG --> PORTD
	bcf	LATB, GLCD_RS, A  ; Set RS low (instruction)
	call	GLCD_Enable ;Pulse E high then low
	return
	
GLCD_Enable:	    
	movlw	10		; wait 40us delay
	call	GLCD_delay_x4us
	
	bsf	LATB, GLCD_E, A	    ; Take E high
	
	movlw	1		; wait 4us delay
	call	GLCD_delay_x4us
	
	bcf	LATB, GLCD_E, A	    ; Take E low
	
	movlw	10		; wait 40us delay
	call	GLCD_delay_x4us
	return
	
	
	
	
GLCD_delay_ms:		    ; delay given in ms in W
	movwf	GLCD_cnt_ms, A
lcdlp2:	movlw	250	    ; 1 ms delay
	call	GLCD_delay_x4us	
	decfsz	GLCD_cnt_ms, A
	bra	lcdlp2
	return
    
GLCD_delay_x4us:		    ; delay given in chunks of 4 microsecond in W
	movwf	GLCD_cnt_l, A	; now need to multiply by 16
	swapf   GLCD_cnt_l, F, A	; swap nibbles
	movlw	0x0f	    
	andwf	GLCD_cnt_l, W, A ; move low nibble to W
	movwf	GLCD_cnt_h, A	; then to LCD_cnt_h
	movlw	0xf0	    
	andwf	GLCD_cnt_l, F, A ; keep high nibble in LCD_cnt_l
	call	GLCD_delay
	return

GLCD_delay:			; delay routine	4 instruction loop == 250ns	    
	movlw 	0x00		; W=0
lcdlp1:	decf 	GLCD_cnt_l, F, A	; no carry when 0x00 -> 0xff
	subwfb 	GLCD_cnt_h, F, A	; no carry when 0x00 -> 0xff
	bc 	lcdlp1		; carry, then loop again
	return			; carry reset so return

end