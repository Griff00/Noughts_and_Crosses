#include <xc.inc>
extrn	Keypad_Setup, Keypad_Read

global  NC_Run_Game
    
psect	udata_acs   ; named variables in access ram
NC_Game_Status: ds 1 ;status byte- last bit is 1 if game has been won
NC_Current_Player: ds 1 ;stores the character code (X or O) of the player playing
    
NC_Loop_Counter_tmp: ds 1 ;a temporary loop counter for general use

NC_Keypad_Button_Pressed: ds 1 ;to store the button pressed in each turn
    
NC_Loop_Counter_delay: ds 1 ;a temporary loop counter for use in delays
NC_cnt_l: ds 1 ;counter variable for delay fn
NC_cnt_h: ds 1 ;counter variable for delay fn
    
NC_Board_1_1: ds 1 ;the top-left corner of the board
NC_Board_1_2: ds 1 ;the top-centre place on the board
NC_Board_1_3: ds 1 ;the top-right corner of the board
NC_Board_2_1: ds 1 ;the centre-left place on the board
NC_Board_2_2: ds 1 ;the central place on the board
NC_Board_2_3: ds 1 ;the centre-right place on the board
NC_Board_3_1: ds 1 ;the bottom-left corner of the board
NC_Board_3_2: ds 1 ;the bottom-centre place on the board
NC_Board_3_3: ds 1 ;the bottom-right corner of the board

psect	nc_code, class=CODE
    
NC_Run_Game: 
	call NC_Setup_Game
    nc_game_loop:
	call NC_Switch_Player
	call NC_Take_Turn
	call NC_Check_Win
	movlw NC_Game_Status & 00000001B
	tstfsz WREG, A  ;test the last bit of the status register- if it's zero, keep playing
	goto nc_game_loop
	goto nc_end_game
    nc_end_game: 
	call NC_Show_Winner
	return 

NC_Setup_Game: 
	call Keypad_Setup ;Set up the keypad for use
	movlw 0x00
	movwf NC_Game_Status, A ;new game, the 'game still running?' flag should be 1
	movlw 0x58
	movwf NC_Current_Player, A ;move the code for X into current_turn- the first thing the game does is switch to O, so O moves first	
	call NC_Clear_Board
	return 
    
NC_Switch_Player:
	;if currently O, switch to X
	movlw   0x4F ;code for O 
	cpfseq NC_Current_Player, A 
	bra nc_switch_X
	;if currently X, switch to O
	movlw   0x58 ;code for X
	cpfseq NC_Current_Player, A 
	bra nc_switch_O
    nc_switch_X:
	movlw 0x58
	movwf NC_Current_Player, A
	return
    nc_switch_O:	
	movlw 0x4F
	movwf NC_Current_Player, A
	return

NC_Take_Turn:
    nc_kpd_read_loop:
	movlw 0x00
	call KeypadRead
	tstfsz WREG, A  
	bra nc_input_detected
	bra nc_kpd_read_loop
    nc_input_detected: 
	movwf NC_Keypad_Button_Pressed, A
	movlw 0xFF	
	cpfslt NC_Keypad_Button_Pressed, A ;if the pattern is 0xFF
	bra nc_kpd_read_loop	;there's been an error- go back to read loop
	
    ; start checking through possible inputs
    nc_check_1:
	movlw '1'
	cpfseq NC_Keypad_Button_Pressed, A
	bra nc_check_2	;key pressed is not 1- check the next
	tstfsz NC_Board_1_1, A
	bra nc_kpd_read_loop  ;space is already filled
	movff NC_Current_Player, NC_Board_1_1, A
	return
	
    nc_check_2:
	movlw '2'
	cpfseq NC_Keypad_Button_Pressed, A
	bra nc_check_3 ;key pressed is not 2- check the next
	tstfsz NC_Board_1_2, A
	bra nc_kpd_read_loop  ;space is already filled
	movff NC_Current_Player, NC_Board_1_2, A
	return
	
    nc_check_3:
	movlw '3'
	cpfseq NC_Keypad_Button_Pressed, A
	bra nc_check_4 ;key pressed is not 3- check the next
	tstfsz NC_Board_1_3, A
	bra nc_kpd_read_loop  ;space is already filled
	movff NC_Current_Player, NC_Board_1_3, A
	return
	
    nc_check_4:
	movlw '4'
	cpfseq NC_Keypad_Button_Pressed, A
	bra nc_check_5 ;key pressed is not 4- check the next
	tstfsz NC_Board_2_1, A
	bra nc_kpd_read_loop  ;space is already filled
	movff NC_Current_Player, NC_Board_2_1, A
	return
	
    nc_check_5:
	movlw '5'
	cpfseq NC_Keypad_Button_Pressed, A
	bra nc_check_6 ;key pressed is not 5- check the next
	tstfsz NC_Board_2_2, A
	bra nc_kpd_read_loop  ;space is already filled
	movff NC_Current_Player, NC_Board_2_2, A
	return
	
    nc_check_6:
	movlw '6'
	cpfseq NC_Keypad_Button_Pressed, A
	bra nc_check_7 ;key pressed is not 6- check the next
	tstfsz NC_Board_2_3, A
	bra nc_kpd_read_loop  ;space is already filled
	movff NC_Current_Player, NC_Board_2_3, A
	return
	
    nc_check_7:
	movlw '7'
	cpfseq NC_Keypad_Button_Pressed, A
	bra nc_check_8 ;key pressed is not 7- check the next
	tstfsz NC_Board_3_1, A
	bra nc_kpd_read_loop  ;space is already filled
	movff NC_Current_Player, NC_Board_3_1, A
	return
	
    nc_check_8:
	movlw '8'
	cpfseq NC_Keypad_Button_Pressed, A
	bra nc_check_9 ;key pressed is not 8- check the next
	tstfsz NC_Board_3_2, A
	bra nc_kpd_read_loop  ;space is already filled
	movff NC_Current_Player, NC_Board_3_2, A
	return
	
    nc_check_9:
	movlw '9'
	cpfseq NC_Keypad_Button_Pressed, A
	bra nc_kpd_read_loop	;error- unplayable key used. go back to reading
	tstfsz NC_Board_3_3, A
	bra nc_kpd_read_loop  ;space is already filled
	movff NC_Current_Player, NC_Board_3_3, A
	return

    
NC_Check_Win: 
    ;not written yet
    return 
    
NC_Show_Winner:
	movlw 0x04
	movwf NC_Loop_Counter_tmp, A    
    nc_flashing_loop:    
	;display every square as the winners
	movff NC_Current_Player, NC_Board_1_1, A
	movff NC_Current_Player, NC_Board_1_2, A
	movff NC_Current_Player, NC_Board_1_3, A
	movff NC_Current_Player, NC_Board_2_1, A
	movff NC_Current_Player, NC_Board_2_2, A
	movff NC_Current_Player, NC_Board_2_3, A
	movff NC_Current_Player, NC_Board_3_1, A
	movff NC_Current_Player, NC_Board_3_2, A
	movff NC_Current_Player, NC_Board_3_3, A

	; add call to update the board

	movlw 0xFA ;250 
	call NC_delay_x1ms ;delay for 0.25s

	;wipe board
	call NC_Clear_Board

	movlw 0xFA ;250 
	call NC_delay_x1ms ;delay for 0.25s

	decfsz NC_Loop_Counter_tmp
	return 
	goto nc_flashing_loop
    
NC_Clear_Board: 
	movlw 0x00
	movwf NC_Board_1_1, A
	movwf NC_Board_1_2, A
	movwf NC_Board_1_3, A
	movwf NC_Board_2_1, A
	movwf NC_Board_2_2, A
	movwf NC_Board_2_3, A
	movwf NC_Board_3_1, A
	movwf NC_Board_3_2, A
	movwf NC_Board_3_3, A
	;add call to update the board
	return 
    
    
; delay fns 
    
NC_delay_x1ms:
    movwf NC_Loop_Counter_delay, A 
nc_delay_loop_1ms: 
    movlw 0xFA ;250 
    call NC_delay_x4us   ;250 * 4us = 1ms
    decfsz NC_Loop_Counter_delay
    return 
    goto nc_delay_loop_1ms
    
NC_delay_x4us:		    ; delay given in chunks of 4 microsecond in W (taken from LCD code)
	movwf	NC_cnt_l, A	; now need to multiply by 16
	swapf   NC_cnt_l, F, A	; swap nibbles
	movlw	0x0f	    
	andwf	NC_cnt_l, W, A ; move low nibble to W
	movwf	NC_cnt_h, A	; then to NC_cnt_h
	movlw	0xf0	    
	andwf	NC_cnt_l, F, A ; keep high nibble in NC_cnt_l
	call	NC_delay
	return

NC_delay:			; delay routine	4 instruction loop == 250ns (taken from LCD code)    
	movlw 	0x00		; W=0
nclp1:	decf 	NC_cnt_l, F, A	; no carry when 0x00 -> 0xff
	subwfb 	NC_cnt_h, F, A	; no carry when 0x00 -> 0xff
	bc 	nclp1		; carry, then loop again
	return			; carry reset so return
end
