#include p18f87k22.inc

    global  ADC_Setup, ADC_Read, eight_bit_by_sixteen,add_check_setup,sixteen_bit_by_sixteen,eight_bit_by_twentyfour, ADC_convert
    extern  LCD_delay_ms,LCD_Send_Byte_D
    
acs0	udata_acs   ; reserve data space in access ram
input_one_lower	    res 1   ; reserve one byte 
input_one_upper	    res 1   ; reserve one byte 
input_two_lower	    res 1   ; reserve one byte	    
input_two_upper	    res 1   ; reserve one byte 
input_one_super    res 1   ; reserve one byte
input_two_super   res 1   ; reserve one byte
   
result_lower	    res 1
result_mid	    res 1
result_upper	    res 1
result_super	    res 1
	    
convert_lower	    res 1
convert_upper	    res 1


ADC    code
    
add_check_setup
    movlw   0x00
    movwf   PORTD
    
    movlw	0xFF
    movwf	input_two_lower
    movlw	0xFF
    movwf	input_two_upper
    
    
    movlw	0xFE
    movwf	input_one_lower
    movlw	0xFF
    movwf	input_one_upper
    movlw	0xFF
    movwf	input_one_super
    return
    
eight_bit_by_sixteen		    ;multiplies sixteen bit number by an 8 bit
    movf  input_one_lower,W
    mulwf input_two_lower
    movff PRODL,result_lower
    movff PRODH, result_mid
    
    movf  input_one_upper,W
    mulwf input_two_lower
    movf PRODL,W
    addwf   result_mid,f
    
    movff PRODH, result_upper
    movlw 0x00
    addwfc result_upper,f
    
    movff   result_super, PORTD
    movff   result_upper, PORTD
    movff   result_mid, PORTD
    movff   result_lower, PORTD
    
    return
    
sixteen_bit_by_sixteen		;multiplies two sixteen bit numbers
    movf  input_one_lower,W	;moving lower bit one into w
    mulwf input_two_lower	;multiplying lower bytes of both
    movff PRODL,result_lower	;moving lowest byte result into file
    movff PRODH, result_mid	;moving 2nd byte into file
    
    movf  input_one_upper,W	;moving upper byte one into w
    mulwf input_two_lower	;multiply with lower byte two
    movf PRODL,W		;movwe lower result into w
    addwf   result_mid,f	;add lower result byte to 2nd storeed result byte
    movff PRODH, result_upper	;move 3rd byte result into file
    movlw 0x00			
    addwfc result_upper,f	;add any carry bit to 3rd byte result
    
    movf  input_one_upper,W
    mulwf input_two_upper
    movff   PRODH, result_super
    movf   PRODL,W
    addwf   result_upper,f
    movlw 0x00
    addwfc result_super,f
    
    movf  input_one_lower,W 	
    mulwf input_two_upper
    movf   PRODL,W
    addwf   result_mid,f
    movlw 0x00
    addwfc result_upper,f
    movf   PRODH,W
    addwf   result_upper,f
    movlw 0x00
    addwfc result_super,f
    
    movff   result_super, PORTD
    movff   result_upper, PORTD
    movff   result_mid, PORTD
    movff   result_lower, PORTD
    
    return
    
eight_bit_by_twentyfour		;multiplies an 8 bit number by a 24 bit
    
    movf  input_one_lower,W
    mulwf input_two_lower
    movff PRODL,result_lower
    movff PRODH, result_mid
    
    movf  input_one_upper,W
    mulwf input_two_lower
    movf PRODL,W
    addwf   result_mid,f
    movff PRODH, result_upper
    movlw 0x00
    addwfc result_upper,f
    
    movf  input_one_super,W
    mulwf input_two_lower
    movf PRODL,W
    addwf   result_upper,f
    movff PRODH,result_super
    movlw 0x00
    addwfc result_super,f
    
    movff   result_super, PORTD
    movff   result_upper, PORTD
    movff   result_mid, PORTD
    movff   result_lower, PORTD
    
    return
    
ADC_convert	;converts hex into decimal n=by returning ASCII character for display on LCD
    movff	ADRESL,input_one_lower
    movff	ADRESH,input_one_upper
    
    movlw	0x8A
    movwf	input_two_lower
    movlw	0x41
    movwf	input_two_upper
    
    call	sixteen_bit_by_sixteen
    call	ADC_compare
    call	LCD_Send_Byte_D
    movlw	.255
    call	LCD_delay_ms
    
    movlw	0x2E
    call	LCD_Send_Byte_D
    movlw	.255
    call	LCD_delay_ms
    
    
    movlw	0x0A
    movwf	input_two_lower
    
    movff	result_lower, input_one_lower
    movff	result_mid, input_one_upper
    movff	result_upper, input_one_super
    
    call	eight_bit_by_twentyfour
    call	ADC_compare
    call	LCD_Send_Byte_D
    movlw	.255
    call	LCD_delay_ms
    
    movff	result_lower, input_one_lower
    movff	result_mid, input_one_upper
    movff	result_upper, input_one_super
    
    call	eight_bit_by_twentyfour
    call	ADC_compare
    call	LCD_Send_Byte_D
    movlw	.255
    call	LCD_delay_ms
    
    movff	result_lower, input_one_lower
    movff	result_mid, input_one_upper
    movff	result_upper, input_one_super
    
    call	eight_bit_by_twentyfour
    call	ADC_compare
    call	LCD_Send_Byte_D
    movlw	.255
    call	LCD_delay_ms
    
    movlw	0x56
    call	LCD_Send_Byte_D
    movlw	.255
    call	LCD_delay_ms
    
    return


ADC_compare	;used to find the decimal number by comparing hex character with known values and returning ASCII
com_0
    movlw	0x00
    cpfseq	result_super
    bra		com_1
    retlw	0x30
com_1
    movlw	0x01
    cpfseq	result_super
    bra		com_2
    retlw	0x31
com_2
    movlw	0x02
    cpfseq	result_super
    bra		com_3
    retlw	0x32
com_3
    movlw	0x03
    cpfseq	result_super
    bra		com_4
    retlw	0x33
com_4
    movlw	0x04
    cpfseq	result_super
    bra		com_5
    retlw	0x34
com_5
    movlw	0x05
    cpfseq	result_super
    bra		com_6
    retlw	0x35
com_6
    movlw	0x06
    cpfseq	result_super
    bra		com_7
    retlw	0x36
com_7
    movlw	0x07
    cpfseq	result_super
    bra		com_8
    retlw	0x37
com_8
    movlw	0x08
    cpfseq	result_super
    bra		com_9
    retlw	0x38
com_9
    movlw	0x09
    cpfseq	result_super
    retlw	0xFF
    retlw	0x39
    
    
ADC_Setup
    bsf	    TRISA,RA0	    ; use pin A0(==AN0) for input
    bsf	    ANCON0,ANSEL0   ; set A0 to analog
    movlw   0x01	    ; select AN0 for measurement
    movwf   ADCON0	    ; and turn ADC on
    movlw   0x30	    ; Select 4.096V positive reference
    movwf   ADCON1	    ; 0V for -ve reference and -ve input
    movlw   0xF6	    ; Right justified output
    movwf   ADCON2	    ; Fosc/64 clock and acquisition times
    return

ADC_Read
    bsf	    ADCON0,GO	    ; Start conversion
adc_loop
    btfsc   ADCON0,GO	    ; check to see if finished
    bra	    adc_loop
    return

    end