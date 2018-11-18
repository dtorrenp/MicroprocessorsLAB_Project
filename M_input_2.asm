#include p18f87k22.inc

    	extern	LCD_Write_Hex, ADC_Setup, ADC_Read, add_check_setup, eight_bit_by_sixteen,sixteen_bit_by_sixteen,eight_bit_by_twentyfour, ADC_convert		    ; external ADC routines
	extern	UART_Setup, UART_Transmit_Message  ; external UART subroutines
	extern  LCD_Setup, LCD_Write_Message, LCD_clear, LCD_move,LCD_delay_ms,LCD_Send_Byte_D,LCD_shiftright,LCD_delay_x4us	; external LCD subroutines
	extern	Pad_Setup, Pad_Read, sampling_delay_input
	
	global	Input_store2, Store_Input_2_Setup,Storage_Clear2
	;global  in2_storage_low,in2_storage_high,in2_storage_highest,first_storage_low,first_storage_high,first_storage_highest,last_storage_low,last_storage_high,last_storage_highest  
	
acs0	udata_acs   ; reserve data space in access ram
in2_storage_low	    res 1
in2_storage_high	    res 1
in2_storage_highest	    res 1
input_lower	    res 1
input_upper	    res 1 
	    
first_storage_low   res 1 	    
first_storage_high	res 1     
first_storage_highest	res 1     
last_storage_low   res 1 	    
last_storage_high	res 1     
last_storage_highest	res 1  	    

MIC    code
    
Store_Input_2_Setup	    ;setup of serial output
    bsf		PORTE, RE1  ;set cs pin high so cant write
    bsf		PORTA, RA4  ;set WP pin on, write protect on
    bsf		PORTC, RC2  ;set hold pin off so doesnt hold
    
    movlw	0x01
    movwf	in2_storage_low
    movlw	0xE8
    movwf	in2_storage_high
    movlw	0x03
    movwf	in2_storage_highest
    
    bcf SSP1STAT, CKE	    
    ; MSSP enable; CKP=1; SPI master, clock=Fosc/64 (1MHz)
    movlw (1<<SSPEN)|(1<<CKP)|(0x02)
    movwf SSP1CON1
    ; SDO2 output; SCK2 output
    bcf TRISC, SDI1
    bcf TRISC, SCK1
    return
   
Input_store2
   call		sampling_delay_input
   
   bcf		PORTE, RE1  ;set cs pin low to active so can write
   
   movlw	0x06
   call		SPI_MasterTransmitInput
   
   bsf		PORTE, RE1 
   
   call		ADC_Read
   movff	ADRESL,input_lower
   movff	ADRESH,input_upper
   
   bcf		PORTE, RE1
   
   movlw	0x02
   call		SPI_MasterTransmitInput
   movf		in2_storage_highest, W
   call		SPI_MasterTransmitInput
   movf		in2_storage_high, W
   call		SPI_MasterTransmitInput
   movf		in2_storage_low, W
   call		SPI_MasterTransmitInput
   
   movf		input_upper, W
   call		SPI_MasterTransmitInput
   movf		input_lower, W
   call		SPI_MasterTransmitInput
   
   bsf		PORTE, RE1  ;set cs pin high to inactive so cant write
   call		increment_file	    ;have to increment file  number twice as two bytes written
   call		increment_file
   call		File_check2
   return
  
increment_file   
   infsnz	in2_storage_low, f	    ;increment number in lowest byte
   bra		inc_high	    ;if not zero it will return else increment next byte
   return
   
inc_high
   infsnz	in2_storage_high, f	    ;increment number in middle byte
   bra		inc_highest	    ;if not zero it will return else increment next byte
   return

inc_highest   
   infsnz	in2_storage_highest, f  ;increment number in highest byte and return
   retlw	0xFF
   return

SPI_MasterTransmitInput ; Start transmission of data (held in W)
    movwf SSP1BUF
Wait_TransmitInput ; Wait for transmission to complete
    btfss PIR1, SSP1IF
    bra Wait_TransmitInput
    bcf PIR1, SSP1IF ; clear interrupt flag
    return

File_check2
    movlw	0x00
    cpfseq	in2_storage_low
    return
    movlw	0xD0
    cpfseq	in2_storage_high
    return
    movlw	0x07
    cpfseq	in2_storage_highest
    return
    movlw	0x03
    movwf	in2_storage_highest
    movlw	0xE8
    movwf	in2_storage_high
    movlw	0x01
    movwf	in2_storage_low
    return
   
Storage_Clear2;THIS PROBABLY DOESNT WORK
    movlw	0x03
    movwf	in2_storage_highest
    movlw	0xE8
    movwf	in2_storage_high
    movlw	0x01
    movwf	in2_storage_low
   
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
   
   call		increment_file	    ;have to increment file  number twice as two bytes written
   call		increment_file
   
   movlw	0xE0;WILL IT LOOP BACK AROUND?;NUMBERS CORRESPOND TO THE MAX FILE I THINK
   cpfseq	in2_storage_low
   bra		Storage_Clear1
   movlw	0xFE
   cpfseq	in2_storage_high
   bra		Storage_Clear1
   movlw	0x07
   cpfseq	in2_storage_highest
   bra		Storage_Clear1
   return
    
    
    end