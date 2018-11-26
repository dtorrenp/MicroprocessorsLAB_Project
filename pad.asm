#include p18f87k22.inc
    
    global Pad_Setup, Pad_Read, sampling_delay_input, Pad_Check,sampling_delay_output
    extern Input_store, Storage_Clear1,Storage_Clear2, Setup_add
    extern  Output_Storage1, Output_Storage2, Input_store2, Add_Main_loop
    
acs0    udata_acs   ; named variables in access ram
PAD_cnt_l   res 1   ; reserve 1 byte for variable PAD_cnt_l
PAD_cnt_h   res 1   ; reserve 1 byte for variable PAD_cnt_h
PAD_cnt_ms  res 1   ; reserve 1 byte for ms counter
pad_row res 1	    ;reserving bytes to store keypad input
pad_column res 1
pad_final res 1

pad	    code

Pad_Setup
    banksel PADCFG1		    ;setting pullup resistors, sets pins as high
    bsf	    PADCFG1, RJPU, BANKED
    clrf    LATJ		    ;clears latch J for keypad input
    movlw   0x0F
    movwf   TRISJ, A		    ;sets initial TRIS of PORTJ for input
    movlw   .10
    call    PAD_delay_x4us	    ;delay to allow voltage to settle
    return

Pad_Read
    movlw   0x0F		    ;sets rows as inputs
    movwf   TRISJ, A
    movlw   .1
    call    PAD_delay_x4us
    movff   PORTJ, pad_row	    ;copies value of row read to variable
    movlw   0xF0
    movwf   TRISJ, A		    ;sets columns as inputs
    movlw   .1
    call    PAD_delay_x4us
    movff   PORTJ, pad_column	    ;copies value of column read to variable
    movf    pad_row,W
    iorwf   pad_column, W	    ;combines column and row value for total input
    movwf   pad_final		    ; moves value to own variable for comparison
    return
    
Pad_Check
    call    Pad_Read		;reads keypad input
    movlw   b'11111111'		;checks if any button is pressed, if not returns
    cpfslt  pad_final	    
    return

    movlw   b'01110111'		;checks if button '1' is pressed    
    cpfseq  pad_final			
    bra	    check_if_out_1	;if not then moves to next check
    call    Input_store		;if it is then the input signal is stored first half of FRAM
    return
    
check_if_out_1			;checks if button '4' is pressed  
    movlw   b'01111011'
    cpfseq  pad_final
    bra	    check_if_in_2	;if not then moves to next check
    call    Output_Storage1	;if it is then the 1st sound bite is played
    return
    
check_if_in_2			;checks if button '2' is pressed 
    movlw   b'10110111'
    cpfseq  pad_final	
    bra	    check_if_out2	;if not then moves to next check
    call    Input_store2	;if it is then the input signal is stored into latter half of FRAM
    return
    
check_if_out2			;checks if button '5' is pressed 
    movlw   b'10111011'
    cpfseq  pad_final
    bra	    check_if_clear1	;if not then moves to next check
    call    Output_Storage2	;if it is then the 2nd sound bite is played
    return
    
check_if_clear1
    movlw   b'01111101'		;checks if button '7' is pressed 
    cpfseq  pad_final
    bra	    check_if_clear_2	;if not then moves to next check
    call    Storage_Clear1	;if it is then the 1st sound bite is cleared
    return
    
check_if_clear_2
    movlw   b'10111101'		;checks if button '8' is pressed 
    cpfseq  pad_final
    bra	    check_if_add	;if not then moves to next check
    call    Storage_Clear2	;if it is then the 2nd sound bite is cleared
    return
    
check_if_add			;checks if button 'A' is pressed 
    movlw   b'01111110'		;if not then returns
    cpfseq  pad_final
    return
    call    Setup_add		;if it is then the sound bites addressed are reset and the two bites are added
    call    Add_Main_loop	
    return		
    
PAD_delay_x4us			; delay given in chunks of 4 microsecond in W
    movwf	PAD_cnt_l	; now need to multiply by 16
    swapf	PAD_cnt_l,F	; swap nibbles
    movlw	0x0f	    
    andwf	PAD_cnt_l,W	; move low nibble to W
    movwf	PAD_cnt_h	; then to PAD_cnt_h
    movlw	0xf0	    
    andwf	PAD_cnt_l,F	; keep high nibble in PAD_cnt_l
    call	PAD_delay
    return

PAD_delay			; delay routine	4 instruction loop == 250ns	    
    movlw 	0x00		; W=0
PADlp1	
    decf 	PAD_cnt_l,F	; no carry when 0x00 -> 0xff
    subwfb 	PAD_cnt_h,F	; no carry when 0x00 -> 0xff
    bc 	PADlp1			; carry, then loop again
    return			; carry reset so return
    
sampling_delay_input		;setting delays used for sampling input to get 8KHz rate
    movlw      .4
    call	PAD_delay_x4us	;using already defined subroutine to help
    return
	    
sampling_delay_output		;setting delays used for sampling output to get 8KHz rate
    movlw      .10
    call	PAD_delay_x4us
    return
    end