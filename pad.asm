#include p18f87k22.inc
    
    global Pad_Setup, Pad_Read, sampling_delay_input, Pad_Check,sampling_delay_output
    extern  LCD_clear, Input_store
    extern storage_low,storage_high,storage_highest,last_storage_low,last_storage_high,last_storage_highest
    extern  Output_Storage
    
acs0    udata_acs   ; named variables in access ram
PAD_cnt_l   res 1   ; reserve 1 byte for variable PAD_cnt_l
PAD_cnt_h   res 1   ; reserve 1 byte for variable PAD_cnt_h
PAD_cnt_ms  res 1   ; reserve 1 byte for ms counter
PAD_tmp	    res 1   ; reserve 1 byte for temporary use
PAD_counter res 1   ; reserve 1 byte for counting through nessage
pad_row res 1
pad_column res 1
pad_final res 1
button_pressed	res 1

pad	    code

Pad_Setup
    banksel PADCFG1
    bsf	    PADCFG1, RJPU, BANKED
    clrf    LATJ
    movlw   0x0F
    movwf   TRISJ, A
    movlw   .10
    call    PAD_delay_x4us
    return

Pad_Read
    movlw   0x0F
    movwf   TRISJ, A
    movlw   .1
    call    PAD_delay_x4us
    movff   PORTJ, pad_row
    movlw   0xF0
    movwf   TRISJ, A
    movlw   .1
    call    PAD_delay_x4us
    movff   PORTJ, pad_column
    movf    pad_row,W
    iorwf   pad_column, W
    movwf   pad_final
    return
    
Pad_Check
    call    Pad_Read
    movlw   b'11111111'		    
    cpfslt  pad_final
    return
    
    movlw   b'01110111'		    
    cpfseq  pad_final			
    bra	    check_if_out
    
    call    file_check_1
    call    Input_store
    movlw   0x01
    movwf   button_pressed
    return

    movlw   b'01110111'		    
    cpfseq  pad_final			
    bra	    check_if_out
    call    Input_store
    movlw   0x01
    movwf   button_pressed
    return
    
    
check_if_out
    movlw   b'10110111'
    cpfseq  pad_final
    return
    
    call    Output_Storage
    movlw   0x02
    movwf   button_pressed
    return
    
File_check_1
    
    movlw	0x03
    cpfseq	storage_highest
    bra		
    movlw	0x00
    movwf	storage_highest
    
    movlw	0x70
    
    movwf	storage_low
    movlw	0xFF
    movwf	storage_high

    movwf	storage_highest
    cpfseq
    
Reset_1_file    
    movlw	0x01
    movwf	storage_low
    movlw	0x00
    movwf	storage_high
    movlw	0x00
    movwf	storage_highest
    
Reset_2_file
    movlw	0x70
    movwf	storage_low
    movlw	0xFF
    movwf	storage_high
    movlw	0x03
    movwf	storage_highest
    
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
    
sampling_delay_input
    movlw      .6
    call	PAD_delay_x4us
    return
    
sampling_delay_output
    movlw      .13
    call	PAD_delay_x4us
    return
    end