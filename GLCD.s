#include <xc.inc>

global  GLCD_Setup, GLCD_Draw_NC
extrn	NC_Board_1_1,NC_Board_1_2,NC_Board_1_3,NC_Board_2_1,NC_Board_2_2,NC_Board_2_3,NC_Board_3_1,NC_Board_3_2,NC_Board_3_3
    
psect	udata_acs  
GLCD_cnt_l:	ds 1	; Delay subroutine variable
GLCD_cnt_h:	ds 1	; Delay subroutine variable

col_location:	ds 1	; Column location / y address (in hex: 0x40 to 0x80)
page_address:	ds 1	; Row location / page / x address (in hex: 0xb8 to 0xbf)

col_range:	ds 1	;Used when looping over a range over columns (# cols to loop over)
page_range:	ds 1	;Used when looping over a range of pages(# pages to loop over)
    
; Note these do not refer to the 'grid lines', but rather the actual cols / rows where the symbols are drawn    
col_1:		ds 1	;Column location / y address of 1st (left) grid column
col_2:		ds 1	;Column location / y address of 2nd (central) grid column
col_3:		ds 1	;Column location / y address of 3rd (right) grid column
row_1:		ds 1	;Row / page location of 1st (top) grid row
row_2:		ds 1	;Row / page location of 2nd (central) grid row
row_3:		ds 1    ;Row / page location of 3rd (bottom) grid row
    
PSECT	udata_acs_ovr,space=1,ovrld,class=COMRAM
display_data:	ds 1	;Tempory var for holding data to be written
page_count:	ds 1	;Tempory var used in loops, tracks how many pages still to loop through
col_count:	ds 1	;Tempory var used in loops, tracks how many columns still to loop through
page_location:	ds 1	;Tempory var used in loops, tracks the 'current' page location / address
	; Labels for PORTB control lines
	GLCD_CS1 EQU 0	; Segment 1 (CS1)   high:segment 1 on
	GLCD_CS2 EQU 1	; Segement 2 (CS2)  high:segment 2 on
 	GLCD_RS  EQU 2	; Data or instruction (RS)  high:Data, low:instruction
 	GLCD_RW  EQU 3	; Read / Write (RW)       high:Read, low:write
	GLCD_E	 EQU 4	; Enable (E)	pulses high and low to latch data/instructions to GLCD
    	GLCD_RST EQU 5	; Reset (RST)	high:not reset, low:reset (==> keep high for normal operation)

psect	glcd_code,class=CODE
    
GLCD_Setup:
	clrf	TRISB, A    ;Port B Output
	clrf	TRISD, A    ;Port D Output
	clrf	LATB, A	    ;Set all B control pins low
	bsf	LATB, GLCD_RST, A   ; RST = 1 (not reset)
	bsf	LATB, GLCD_CS1, A   ;Select segment 1 (CS1 high)
	bcf	LATB, GLCD_CS2, A   ;keep CS2 low
	movlw	0x3f	;Instruction code for display = on
	call	GLCD_Send_I	;Send instruction to GLCD
	
	;Define column / row display addresses (useful later)
	movlw	0x46	;1st column location
	movwf	col_1, A    ;Set col_1
	movlw	0x5c	;2nd column location
	movwf	col_2, A
	movlw	0x72	;3rd column location
	movwf	col_3, A
	movlw	0xb9	;1st row location
	movwf	row_1, A
	movlw	0xbc	;2nd row location
	movwf	row_2, A
	movlw	0xbe	;3rd row location
	movwf	row_3, A

	
	movlw	0x40		
	movwf   col_location, A	; Set y address = 0
	movlw	0xb8	
	movwf   page_location, A ; Set x address = 0
	call	GLCD_Update_address ; Send address instructions to GLCD (subroutine since..
				    ;..this operation is needed often)
	
	movlw	0xc0
	call	GLCD_Send_I	; set z address = 0  - This only needs to happen once
				; hence isn't required in "GLCD_Update_address" subroutine
	
	
	call	GLCD_Clear  ;Clear GLCD Data Ram (now completely empty)
	call	GLCD_Grid   ; Draw grid (3x3)
	return
	
GLCD_Update_address:	;Update address subroutine: called frequently to point to required column and page
    	movf    page_location, W, A
	call	GLCD_Send_I ;Update Page location
	movf    col_location, W, A
	call	GLCD_Send_I ;Update Column location
	return
	
GLCD_Clear: ; Clears GLCD DATA RAM
	movlw	0xb8	; Start at page 0 (page address codes start at 0xb8 - this is defined at page 0)
	movwf	page_address, A
	movlw	0x00	; Data to write = 0x00
	movwf	display_data, A
	movlw	0x40	; Write to all columns (0x40 --> 64DEC)
	movwf	col_range,A
	movlw	0x08	; Write to all pages (0x08 --> 8DEC)
	movwf	page_range, A
	movlw	0x40	;Start at column 0 (column address codes start at 0x40, this is defined as y =0)
	movwf	col_location, A
	call	GLCD_Write_Data_Loop ; Write Data (loop over stated columns / pages required)
	
	return
	
GLCD_Grid:
	;Draw 1st horizontal grid line (upper line)
	movlw	0xba
	movwf	page_address, A
	movlw	0x18
	movwf	display_data, A
	movlw	0x40
	movwf	col_range,A
	movlw	0x01
	movwf	page_range, A
	movlw	0x40
	movwf	col_location, A
	call	GLCD_Write_Data_Loop
	
	;Draw 2nd horizontal grid line (lower line)
	movlw	0xbd
	movwf	page_address, A
	movlw	0x30
	movwf	display_data, A
	call	GLCD_Write_Data_Loop	
	
	;Draw 1st vertical grid line (left line)
	movlw	0xb8
	movwf	page_address, A
	movlw	0xff
	movwf	display_data, A
	movlw	0x02
	movwf	col_range,A
	movlw	0x08
	movwf	page_range, A	
	movlw	0x54
	movwf	col_location, A
	call	GLCD_Write_Data_Loop	
	
	;Draw 2nd vertical grid line (right line)
	movlw	0x6a
	movwf	col_location, A
	call	GLCD_Write_Data_Loop	
	
	return	
	
	
GLCD_Draw_NC: ; Use global NC_Board variables to identify and draw O, X or nothing
	movff	col_1, col_location, A	; Set column location equal to "column 1"
	movff	row_1, page_location, A ; Set row location equal to "row 1"
	movff	NC_Board_1_1,display_data, A	;Load top left cell data 
	call	GLCD_NC_O_or_X	;Identify (and then draw) O or X or nothing
	
	movff	col_2, col_location, A
	movff	row_1, page_location, A
	movff	NC_Board_1_2,display_data, A
	call	GLCD_NC_O_or_X	
	
	movff	col_3, col_location, A
	movff	row_1, page_location, A
	movff	NC_Board_1_3,display_data, A
	call	GLCD_NC_O_or_X	
	
	movff	col_1, col_location, A
	movff	row_2, page_location, A
	movff	NC_Board_2_1,display_data, A
	call	GLCD_NC_O_or_X
	
	movff	col_2, col_location, A
	movff	row_2, page_location, A
	movff	NC_Board_2_2,display_data, A
	call	GLCD_NC_O_or_X
	
	movff	col_3, col_location, A
	movff	row_2, page_location, A
	movff	NC_Board_2_3,display_data, A
	call	GLCD_NC_O_or_X
	
	movff	col_1, col_location, A
	movff	row_3, page_location, A
	movff	NC_Board_3_1,display_data, A
	call	GLCD_NC_O_or_X	

	movff	col_2, col_location, A
	movff	row_3, page_location, A
	movff	NC_Board_3_2,display_data, A
	call	GLCD_NC_O_or_X
	
	movff	col_3, col_location, A
	movff	row_3, page_location, A
	movff	NC_Board_3_3,display_data, A
	call	GLCD_NC_O_or_X	
	
	return
GLCD_NC_O_or_X:	;Identify (and then draw) O or X or nothing
	call	GLCD_Update_address ; Update column and page locations
NC_X:
	movlw	0x58	; Code for 'X'
	cpfseq	display_data, A	; Compare with data
	bra	NC_O	; If not =, then branch
	call	GLCD_Draw_X ; If =, then draw 'X' here
	return
NC_O:
	movlw	0x4f	;Code for 'O'
	cpfseq	display_data, A ; Compare with data
	bra	NC_clear_location   ;If not =, branch
	call	GLCD_Draw_O ;If =, draw 'O' here
	return
NC_clear_location:
	movlw	0x00	; Checks if variable is empty
	cpfseq	display_data, A
	return	;If not empty then variable code is unrecognised and can't be drawn --> return

	movff	page_location, page_address, A ; Copy page_location to page_address (this is only required since we're using "GLCD_Write_Data_Loop" subroutine)
	movlw	0x08
	movwf	col_range, A ; Specify column range (in this case 8 columns wide)
	movlw	0x01
	movwf	page_range, A	; Page range (=1)
	call	GLCD_Write_Data_Loop ; Write 0x00 at this location
	; We can use "GLCD_Write_Data_Loop" as the data to be written to the 8 columns is identical (all 0x00)
	; This is not the case for X and O, where the display data changes for each column --> must used different approach
	return
	
GLCD_Draw_X: ;Character is 8 bits by 8 bits. Therefore write 8 bits (height of page) at a time across 8 columns (left to right)
	; Therefore, a character is represented by a sequence of 8 bytes:
	movlw   0x81 ;left most column of X character
	call    GLCD_Write_Data
	movlw   0x42
	call    GLCD_Write_Data
	movlw   0x24
	call    GLCD_Write_Data
	movlw   0x18
	call    GLCD_Write_Data
	movlw   0x18
	call    GLCD_Write_Data
	movlw   0x24
	call    GLCD_Write_Data
	movlw   0x42
	call    GLCD_Write_Data
	movlw   0x81	; right most column of X character
	call    GLCD_Write_Data
	return
	
GLCD_Draw_O:;Different character code for O 
        movlw   0x3c
	call    GLCD_Write_Data
	movlw   0x42
	call    GLCD_Write_Data
	movlw   0x81
	call    GLCD_Write_Data
	movlw   0x81
	call    GLCD_Write_Data
	movlw   0x81
	call    GLCD_Write_Data
	movlw   0x81
	call    GLCD_Write_Data
	movlw   0x42
	call    GLCD_Write_Data
        movlw   0x3c
	call    GLCD_Write_Data	
	return
	
	
GLCD_Write_Data_Loop:	; This subroutine writes identical data over a specificed range of pages and columns
	movff	page_range, page_count, A   ;Use temporary variables which will be altered
	movff	page_address, page_location, A ;Use temporary variables which will be altered
Grid_page_loop:	; Loop over pages
	call	GLCD_Update_address ; Update new (page) address
	movff	col_range, col_count, A	; Reset column counter to original value (ready for next loop)
Grid_col_loop:	; Loop over columns
	movf	display_data, W, A
	call	GLCD_Write_Data	; Write data to display
	decfsz	col_count, A	;decrement column count
	bra	Grid_col_loop	; branch (if >0) back to column loop
	
	incf	page_location, A    ;increment page location
	decfsz	page_count, A	; decrement page counter
	bra	Grid_page_loop	; branch (if >0) back to page loop
	return
	
GLCD_Write_Data:
	movwf	LATD, A		; WREG --> PortD
	bcf	LATB, GLCD_RW, A    ; Set RW low (write)
	bsf	LATB, GLCD_RS, A    ;Set RS high (data)
	call	GLCD_Enable	; Pulse E high then low 
	return	
	
GLCD_Send_I:	
	movwf	LATD, A		; WREG --> PORTD
	bcf	LATB, GLCD_RS, A  ; Set RS low (instruction)
	call	GLCD_Enable ;Pulse E high then low
	return
	
GLCD_Enable:	    
	movlw	1		; wait 4us delay
	call	GLCD_delay_x4us
	
	bsf	LATB, GLCD_E, A	    ; Take E high
	
	movlw	1		; wait 4us delay
	call	GLCD_delay_x4us
	
	bcf	LATB, GLCD_E, A	    ; Take E low
	
	movlw	1		; wait 4us delay
	call	GLCD_delay_x4us
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


