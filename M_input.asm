#include p18f87k22.inc

    	extern	LCD_Write_Hex, ADC_Setup, ADC_Read, add_check_setup, eight_bit_by_sixteen,sixteen_bit_by_sixteen,eight_bit_by_twentyfour, ADC_convert		    ; external ADC routines
	extern	UART_Setup, UART_Transmit_Message  ; external UART subroutines
	extern  LCD_Setup, LCD_Write_Message, LCD_clear, LCD_move,LCD_delay_ms,LCD_Send_Byte_D,LCD_shiftright,LCD_delay_x4us	; external LCD subroutines
	extern	Pad_Setup, Pad_Read, sampling_delay_input
	
	global	Input_store, Store_Input_Setup, Storage_Clear
	global  storage_low,storage_high,storage_highest,first_storage_low,first_storage_high,first_storage_highest,last_storage_low,last_storage_high,last_storage_highest  
	
acs0	udata_acs   ; reserve data space in access ram
storage_low	    res 1
storage_high	    res 1
storage_highest	    res 1
input_lower	    res 1
input_upper	    res 1 
	    
first_storage_low   res 1 	    
first_storage_high	res 1     
first_storage_highest	res 1     
last_storage_low   res 1 	    
last_storage_high	res 1     
last_storage_highest	res 1  	    

MIC    code
    
Store_Input_Setup	    ;setup of serial output
    bsf		PORTE, RE1  ;set cs pin high so cant write
    bsf		PORTA, RA4  ;set WP pin on, write protect on
    bsf		PORTC, RC2  ;set hold pin off so doesnt hold
	
    movlw	0x00
    movwf	storage_high
    movwf	storage_highest
    movlw	0x01
    movwf	storage_low
    
    movlw	0x00
    movwf	first_storage_high
    movwf	first_storage_highest
    movlw	0x01
    movwf	first_storage_low
    
    bcf SSP1STAT, CKE	    
    ; MSSP enable; CKP=1; SPI master, clock=Fosc/64 (1MHz)
    movlw (1<<SSPEN)|(1<<CKP)|(0x02)
    movwf SSP1CON1
    ; SDO2 output; SCK2 output
    bcf TRISC, SDI1
    bcf TRISC, SCK1
    return
   
Input_store
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
   movf		storage_highest, W
   call		SPI_MasterTransmitInput
   movf		storage_high, W
   call		SPI_MasterTransmitInput
   movf		storage_low, W
   call		SPI_MasterTransmitInput
   
   movf		input_upper, W
   call		SPI_MasterTransmitInput
   movf		input_lower, W
   call		SPI_MasterTransmitInput
   
   bsf		PORTE, RE1  ;set cs pin high to inactive so cant write
   call		increment_file	    ;have to increment file  number twice as two bytes written
   call		increment_file
   return
  
increment_file   
   infsnz	storage_low, f	    ;increment number in lowest byte
   bra		inc_high	    ;if not zero it will return else increment next byte
   return
   
inc_high
   infsnz	storage_high, f	    ;increment number in middle byte
   bra		inc_highest	    ;if not zero it will return else increment next byte
   return

inc_highest   
   infsnz	storage_highest, f  ;increment number in highest byte and return
   retlw	0xFF
   return

SPI_MasterTransmitInput ; Start transmission of data (held in W)
    movwf SSP1BUF
Wait_TransmitInput ; Wait for transmission to complete
    btfss PIR1, SSP1IF
    bra Wait_TransmitInput
    bcf PIR1, SSP1IF ; clear interrupt flag
    return
    
    
Storage_Clear
   movlw	0x00
   movwf	storage_high
   movwf	storage_highest
   movlw	0x01
   movwf	storage_low
   
   bcf		PORTE, RE1  ;set cs pin low to active so can write
   
   movlw	0x06
   call		SPI_MasterTransmitInput
   
   bsf		PORTE, RE1 
   
   bcf		PORTE, RE1
   
   movlw	0x02
   call		SPI_MasterTransmitInput
   movf		storage_highest, W
   call		SPI_MasterTransmitInput
   movf		storage_high, W
   call		SPI_MasterTransmitInput
   movf		storage_low, W
   call		SPI_MasterTransmitInput
   
   movlw	0x00
   call		SPI_MasterTransmitInput
   movlw	0x00
   call		SPI_MasterTransmitInput
   
   bsf		PORTE, RE1  ;set cs pin high to inactive so cant write
   
   call		increment_file	    ;have to increment file  number twice as two bytes written
   call		increment_file
   
   movlw	0x00
   cpfseq	storage_low
   bra		Storage_Clear
   movlw	0xE8
   cpfseq	storage_high
   bra		Storage_Clear
   movlw	0x03
   cpfseq	storage_highest
   bra		Storage_Clear
   return
    
_    
    end