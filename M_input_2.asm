#include p18f87k22.inc

    	extern	LCD_Write_Hex, ADC_Setup, ADC_Read, add_check_setup, eight_bit_by_sixteen,sixteen_bit_by_sixteen,eight_bit_by_twentyfour, ADC_convert		    ; external ADC routines
	extern  LCD_Setup, LCD_Write_Message, LCD_clear, LCD_move,LCD_delay_ms,LCD_Send_Byte_D,LCD_shiftright,LCD_delay_x4us	; external LCD subroutines
	extern	Pad_Setup, Pad_Read, sampling_delay_input, SPI_MasterTransmitInput
	
	global	Input_store2, Store_Input_2_Setup,Storage_Clear2, fon, foff
	
acs0	udata_acs   ; reserve data space in access ram
in2_storage_low	    res 1
in2_storage_high	    res 1
in2_storage_highest	    res 1
input_lower2	    res 1
input_upper2	    res 1 
	    
first_storage_low   res 1 	    
first_storage_high	res 1     
first_storage_highest	res 1     
last_storage_low   res 1 	    
last_storage_high	res 1     
last_storage_highest	res 1  	    

MIC    code
    
Store_Input_2_Setup	    ;setup of serial output
    movlw	0x00
    movwf	TRISF
    movwf	PORTF
    
    movlw	0x02
    movwf	in2_storage_low
    movlw	0xE8
    movwf	in2_storage_high
    movlw	0x03
    movwf	in2_storage_highest
    return
   
Input_store2
   call		sampling_delay_input
   
   bcf		PORTE, RE1  ;set cs pin low to active so can write
   
   movlw	0x06
   call		SPI_MasterTransmitInput
   
   bsf		PORTE, RE1 
   
   call		ADC_Read
   movff	ADRESL,input_lower2
   movff	ADRESH,input_upper2
   
   bcf		PORTE, RE1
   
   movlw	0x02
   call		SPI_MasterTransmitInput
   movf		in2_storage_highest, W
   call		SPI_MasterTransmitInput
   movf		in2_storage_high, W
   call		SPI_MasterTransmitInput
   movf		in2_storage_low, W
   call		SPI_MasterTransmitInput
   
   movf		input_upper2, W
   call		SPI_MasterTransmitInput
   movf		input_lower2, W
   call		SPI_MasterTransmitInput
   
   bsf		PORTE, RE1  ;set cs pin high to inactive so cant write
   call		increment_file2	    ;have to increment file  number twice as two bytes written
   call		increment_file2
   call		File_check2
   return
  
increment_file2   
   infsnz	in2_storage_low, f	    ;increment number in lowest byte
   bra		inc_high_in2	    ;if not zero it will return else increment next byte
   return
   
inc_high_in2
   infsnz	in2_storage_high, f	    ;increment number in middle byte
   bra		inc_highest_in2	    ;if not zero it will return else increment next byte
   return

inc_highest_in2   
   infsnz	in2_storage_highest, f  ;increment number in highest byte and return
   retlw	0xFF
   return

File_check2
    movlw	0xFC
    cpfsgt	in2_storage_low
    return
    movlw	0xFF
    cpfseq	in2_storage_high
    return
    movlw	0x07
    cpfseq	in2_storage_highest
    return
    movlw	0x03
    movwf	in2_storage_highest
    movlw	0xE8
    movwf	in2_storage_high
    movlw	0x02
    movwf	in2_storage_low
    return
   
Storage_Clear2
   call	fon
   call	clear_2setup
   call	clear_2
   call	foff
   return
   
clear_2setup
   movlw	0x03
   movwf	in2_storage_highest
   movlw	0xE8
   movwf	in2_storage_high
   movlw	0x02
   movwf	in2_storage_low
   return
    
clear_2 
   bcf		PORTE, RE1  ;set cs pin low to active so can write

   movlw	0x06
   call		SPI_MasterTransmitInput
   
   bsf		PORTE, RE1 
    
   bcf		PORTE, RE1
   
   movlw	0x02
   call		SPI_MasterTransmitInput
   movf		in2_storage_highest, W
   call		SPI_MasterTransmitInput
   movf		in2_storage_high, W
   call		SPI_MasterTransmitInput
   movf		in2_storage_low, W
   call		SPI_MasterTransmitInput
   
   movlw	0x00
   call		SPI_MasterTransmitInput
   movlw	0x00
   call		SPI_MasterTransmitInput
   
   bsf		PORTE, RE1  ;set cs pin high to inactive so cant write
   
   call		increment_file2	    ;have to increment file  number twice as two bytes written
   call		increment_file2
   
   movlw	0xFC
   cpfsgt	in2_storage_low
   goto		clear_2
   movlw	0xFF
   cpfseq	in2_storage_high
   goto		clear_2
   movlw	0x07
   cpfseq	in2_storage_highest
   goto		clear_2
   
   movlw	0x03
   movwf	in2_storage_highest
   movlw	0xE8
   movwf	in2_storage_high
   movlw	0x02
   movwf	in2_storage_low
   return
   
fon
   movlw	0xFF
   movwf	PORTF
   return
   
foff
   movlw	0x00
   movwf	PORTF
   return
    
    end