#include <xc.inc>

extrn	GLCD_Setup, GLCD_Write_Data, GLCD_Status, GLCD_Read

psect	code, abs
rst:	org	0x0000	; reset vector
	goto	start

start:	call	GLCD_Setup ; GLCD Setup
	movlw	0xaa
	call	GLCD_Write_Data 
	movlw	0xaa
	call	GLCD_Write_Data 
	movlw	0xaa
	call	GLCD_Write_Data 
	movlw	0x00
	call	GLCD_Write_Data 
	movlw	0xff
	call	GLCD_Write_Data 
	movlw	0x00
	call	GLCD_Write_Data 
	movlw	0xaa
	call	GLCD_Write_Data 
	movlw	0xaa
	call	GLCD_Write_Data 
	movlw	0xaa
	call	GLCD_Write_Data 
	movlw	0x00
	call	GLCD_Write_Data 
	movlw	0xff
	call	GLCD_Write_Data 
	movlw	0x00
	call	GLCD_Write_Data 

	call	GLCD_Status
	call	GLCD_Read
	
	goto	$	; Sit in infinite loop

	end	rst
