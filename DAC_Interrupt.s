#include <xc.inc>
	
global	DAC_tune, DAC_Int_Hi ,DAC_Load_Table
    
psect	udata_acs   ; named variables in access ram
delay_count:	ds 1    
    
DAC_cnt_l:	ds 1	; Delay variables for the DAC
DAC_cnt_h:	ds 1	; 
DAC_cnt_ms:	ds 1	; 
DAC_tmp:	ds 1	; 
DAC_counter:	ds 1	; 
DAC_long_delay: ds 1	;
    
Int_cnt_l:	ds 1	; Delay variables for the Interrupt service routine
Int_cnt_h:	ds 1	; 
Int_cnt_ms:	ds 1	; 
Int_tmp:	ds 1	; 
Int_counter:	ds 1	; 
Int_long_delay: ds 1
    
table_counter:	ds 1	; Length of sine-wave lookup table still to iterate through
counter:	ds 1
DAC_freq_calibration: ds 1  ;This allows fine adjustment of the frequency of the sinewave
    
    

psect	udata_bank4 ; reserve space in RAM for sine-wave lookup table
myArray:    ds 0x80 ; 128 bytes for lookup table (currently only uses 100 bytes)
	
psect	data    
	; ******* Sine wave lookup table in programme memory (PM)  *****
myTable:
	db	0x80,0x88,0x8f,0x97,0x9f,0xa7,0xae,0xb6,0xbd,0xc4,0xca,0xd1,0xd7,0xdc,0xe2,0xe7,0xeb,0xef,0xf3,0xf6,0xf9,0xfb,0xfd,0xfe,0xff,0xff,0xff,0xfe,0xfd,0xfb,0xf9,0xf6,0xf3,0xef,0xeb,0xe7,0xe2,0xdc,0xd7,0xd1,0xca,0xc4,0xbd,0xb6,0xae,0xa7,0x9f,0x97,0x8f,0x88,0x80,0x77,0x70,0x68,0x60,0x58,0x51,0x49,0x42,0x3b,0x35,0x2e,0x28,0x23,0x1d,0x18,0x14,0x10,0xc,0x9,0x6,0x4,0x2,0x1,0x0,0x0,0x0,0x1,0x2,0x4,0x6,0x9,0xc,0x10,0x14,0x18,0x1d,0x23,0x28,0x2e,0x35,0x3b,0x42,0x49,0x51,0x58,0x60,0x68,0x70,0x77,0x80
					
		
	myTable_l EQU 100   ;100 values long (this is the resolution of the wave)

    
psect	dac_code, class=CODE
	
    
DAC_Int_Hi:			;Interrupt Service Routine (ISR) (triggered by timer0)
	btfss	TMR0IF		; check that this is timer0 interrupt
	retfie	f		; if not then return
	
	movf    POSTINC2, W, A	;Move next value from lookup table (Pointed to by FSR2) into PORTJ
	movwf	LATJ, F, A
	

	
	decfsz  table_counter, A    ;Decrement table_counter (initially length of lookup table)
	bra	Exit_Int    ; If > 0, then exit the ISR
	lfsr	2, myArray  ; If = 0, then reached the end of current wave -> need to reset back to start of lookup table. Do this by reloading lookup table into FSR2.
	movlw	myTable_l	; move length of looktable -> WREG
	movwf 	table_counter, A    ; reset table_counter to lookup table length

Exit_Int:
	;This latches the new data on PORTJ to the DAC
	clrf	LATF, A	; Pulse PortD low (WR low)
	movlw	0x01 ; Delay
	call	Int_delay_x4us ; Separate Interrupt delay subroutine to avoid any variables being overwritten
	movlw	0xff	; Pulse PortD high (WR high)
	movwf	LATF, A
	
	bcf	TMR0IF		; clear interrupt flag
	movf	DAC_freq_calibration, W, A  ;This sets an initial (non-zero) value in timer0, shortening the time between data points. This finely adjusts frequency.
	movwf	TMR0, A	; Move to TMR0 (the data register for timer0)
	retfie	f		; fast return from interrupt


DAC_tune:   ; This is the highest level subroutine. Calling this will ouput a tune on the speaker. (Current tune: C,D,E,D,C,E,C)
	    ; This can be greatly modified to get different tunes.
    	call	DAC_off	;Start with DAC off 
	movlw	0x02	
	movwf	DAC_freq_calibration, A	; Set frequency = ~260Hz (approx middle C note)
	call	DAC_Setup; Setup (turn on) DAC 
	call	DAC_Long_delay	; Long delay (this is the duration of the C note - can be altered by changing Long_delay time)
	movlw	0x28
	movwf	DAC_freq_calibration, A	; Set frequency = ~298Hz (approx D note)
	call	DAC_Long_delay
	movlw	0x48
	movwf	DAC_freq_calibration, A ; Set frequency = ~330Hz (approx E note)
	call	DAC_Long_delay
	movlw	0x28
	movwf	DAC_freq_calibration, A
	call	DAC_Long_delay
	movlw	0x02
	movwf	DAC_freq_calibration, A
	call	DAC_Long_delay
	movlw	0x48
	movwf	DAC_freq_calibration, A
	call	DAC_Long_delay
	movlw	0x02
	movwf	DAC_freq_calibration, A
	call	DAC_Long_delay

	call	DAC_off	; Tune has ended - need to turn off DAC to stop output
	return
	
DAC_off:
	bcf	TMR0IF	;Clear timer0 interrupt flag (incase it hasn't been reset)
	bcf	TMR0IE	; Disable timer0 interrupts
	bcf	GIE ; Disable all interrupts
	clrf	LATJ, A	; Clear LATJ - need to do this to stop audio output
	movlw	00000000B
	movwf	T0CON, A    ;Turn off timer0
	return
	
DAC_Setup:
	clrf	TRISJ, A	; Set PORTJ as all outputs (for data)
	movlw	0xff
	movwf	LATF, A	; Set PORTF lines high (WR signal)
	clrf	TRISF, A; Set PORTF output
	clrf	LATJ, A		; Clear PORTJ outputs
	
	movlw	11000000B	; Set timer0 to 8 bit, 8 MHz clock rate
	movwf	T0CON, A	
	bsf	TMR0IE		; Enable timer0 interrupt
	bsf	GIE		; Enable all interrupts
	return
	
DAC_Load_Table:	; Loads sine wave lookup table into RAM
 	lfsr	0, myArray	; Load FSR0 with address in RAM	
	movlw	low highword(myTable)	; address of data in PM
	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
	movlw	high(myTable)	; address of data in PM
	movwf	TBLPTRH, A		; load high byte to TBLPTRH
	movlw	low(myTable)	; address of data in PM
	movwf	TBLPTRL, A		; load low byte to TBLPTRL
	movlw	myTable_l	; bytes to read
	movwf 	counter, A		; our counter register
loop: 	tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0; move data from TABLAT to (FSR0), inc FSR0	
	decfsz	counter, A		; count down to zero
	bra	loop		; keep going until finished	
	
	lfsr	2, myArray	; Use FSR2 to point to lookup table location
	movlw	myTable_l	
	movwf 	table_counter, A    ; Set table_counter equal to length of lookup table
	return

DAC_Long_delay:
	movlw	0x01	
	movwf	DAC_long_delay, A
long_delay_loop:
	movlw	200; wait 2ms
	;movlw	150
	call	DAC_delay_ms
	
	decfsz  DAC_long_delay, A
	bra	long_delay_loop  
	
	return

DAC_delay_ms:		    ; delay given in ms in W
	movwf	DAC_cnt_ms, A
lcdlp2:	movlw	250	    ; 1 ms delay
	call	DAC_delay_x4us	
	decfsz	DAC_cnt_ms, A
	bra	lcdlp2
	return
    
DAC_delay_x4us:		    ; delay given in chunks of 4 microsecond in W
	movwf	DAC_cnt_l, A	; now need to multiply by 16
	swapf   DAC_cnt_l, F, A	; swap nibbles
	movlw	0x0f	    
	andwf	DAC_cnt_l, W, A ; move low nibble to W
	movwf	DAC_cnt_h, A	; then to DAC_cnt_h
	movlw	0xf0	    
	andwf	DAC_cnt_l, F, A ; keep high nibble in DAC_cnt_l
	call	DAC_delay
	return

DAC_delay:			; delay routine	4 instruction loop == 250ns	    
	movlw 	0x00		; W=0
lcdlp1:	decf 	DAC_cnt_l, F, A	; no carry when 0x00 -> 0xff
	subwfb 	DAC_cnt_h, F, A	; no carry when 0x00 -> 0xff
	bc 	lcdlp1		; carry, then loop again
	return
	
Int_delay_x4us:		    ; delay given in chunks of 4 microsecond in W
	movwf	Int_cnt_l, A	; now need to multiply by 16
	swapf   Int_cnt_l, F, A	; swap nibbles
	movlw	0x0f	    
	andwf	Int_cnt_l, W, A ; move low nibble to W
	movwf	Int_cnt_h, A	; then to DAC_cnt_h
	movlw	0xf0	    
	andwf	Int_cnt_l, F, A ; keep high nibble in DAC_cnt_l
	call	Int_delay
	return

Int_delay:			; delay routine	4 instruction loop == 250ns	    
	movlw 	0x00		; W=0
Intlp1:	decf 	Int_cnt_l, F, A	; no carry when 0x00 -> 0xff
	subwfb 	Int_cnt_h, F, A	; no carry when 0x00 -> 0xff
	bc 	Intlp1		; carry, then loop again
	return


	
	end


