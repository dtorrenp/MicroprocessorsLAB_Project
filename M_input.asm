#include p18f87k22.inc

    	extern	LCD_Write_Hex, ADC_Setup, ADC_Read, add_check_setup, eight_bit_by_sixteen,sixteen_bit_by_sixteen,eight_bit_by_twentyfour, ADC_convert		    ; external ADC routines
	extern  LCD_Setup, LCD_Write_Message, LCD_clear, LCD_move,LCD_delay_ms,LCD_Send_Byte_D,LCD_shiftright,LCD_delay_x4us	; external LCD subroutines
	extern	Pad_Setup, Pad_Read, sampling_delay_input, fon, foff
	
	global	Input_store, Store_Input_Setup, Storage_Clear1,SPI_MasterTransmitInput
	
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
	
    movlw	0x00		    ;setting initial memory location for 1st 
    movwf	storage_high	    ;sound bite
    movwf	storage_highest
    movlw	0x01
    movwf	storage_low
    
    bcf SSP1STAT, CKE	    
    ; MSSP enable; CKP=1; SPI master, clock=Fosc/64 (1MHz)
    movlw (1<<SSPEN)|(1<<CKP)|(0x02)
    movwf SSP1CON1
    ; SDO1 output; SCK1 output
    bcf TRISC, SDI1
    bcf TRISC, SCK1
    return
   
Input_store
   call		sampling_delay_input	;calls delay to get 8Khz sampling rate
   bcf		PORTE, RE1		;set cs pin low to active so can write
   
   movlw	0x06			;sending opcode to set WREN pin
   call		SPI_MasterTransmitInput
   
   bsf		PORTE, RE1		;set cs pin high to seperate two write cycles
   
   call		ADC_Read		;reads in data from mic input
   movff	ADRESL,input_lower	;transfers input from special file register
   movff	ADRESH,input_upper	;into dedicated file locations
   
   bcf		PORTE, RE1		;setting cs pin low again to write
   
   movlw	0x02			;sending opcode for write command to FRAM
   call		SPI_MasterTransmitInput	;sent through SPI1
   movf		storage_highest, W	;sending 6 byte address, msb first
   call		SPI_MasterTransmitInput
   movf		storage_high, W
   call		SPI_MasterTransmitInput
   movf		storage_low, W
   call		SPI_MasterTransmitInput
   
   movf		input_upper, W		;sending data to be stored at file address into FRAM
   call		SPI_MasterTransmitInput
   movf		input_lower, W		;sending second byte
   call		SPI_MasterTransmitInput	;file address increments automatically as cs pin still low
   
   bsf		PORTE, RE1	    ;set cs pin high to inactive so cant write
   call		increment_file	    ;have to increment file  number twice as two bytes written
   call		increment_file
   call		File_check1	    ;checks file address hasnt reach end of allotted space
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
   retlw	0xFF		    ;highest byte maximum is 0x03 so need not worry about higher
   return

SPI_MasterTransmitInput ; Start transmission of data (held in W)
    movwf SSP1BUF
Wait_TransmitInput ; Wait for transmission to complete
    btfss PIR1, SSP1IF
    bra Wait_TransmitInput
    bcf PIR1, SSP1IF ; clear interrupt flag
    return
    
File_check1			    ;subroutine for making program writing to 
    movlw	0xFD		    ;only allotted memory 
    cpfsgt	storage_low	    ;as file increments twice each time just checks if 
    return			    ;greater than instead of equal to
    movlw	0xFF
    cpfseq	storage_high
    return
    movlw	0x03
    cpfseq	storage_highest
    return
    movlw	0x00		    ;if at end of allotted memory loops back to 0
    movwf	storage_highest
    movwf	storage_high
    movlw	0x01
    movwf	storage_low
    return
    
Storage_Clear1			;subroutine for clearing sound bite
   call	fon			;PORTF lights up when running for easy way to tell when it finishes
   call	clear1_setup		;file address set to start so can increment over all
   call	clear_1
   call	foff
   return

clear1_setup			;setting file address to start of first bite
   movlw	0x00
   movwf	storage_high
   movwf	storage_highest
   movlw	0x01
   movwf	storage_low
   return
   
clear_1
   bcf		PORTE, RE1  ;set cs pin low to active so can write
   
   movlw	0x06			;sending opcode to set WREN pin
   call		SPI_MasterTransmitInput
   
   bsf		PORTE, RE1	;set cs pin high to seperate two write cycles
   
   bcf		PORTE, RE1
   
   movlw	0x02			;sending opcode for write command
   call		SPI_MasterTransmitInput
   movf		storage_highest, W	;sending 6 byte file address
   call		SPI_MasterTransmitInput
   movf		storage_high, W
   call		SPI_MasterTransmitInput
   movf		storage_low, W
   call		SPI_MasterTransmitInput
   
   movlw	0x00			;sends 0x00 to be written to file address, to 'clear' the byte
   call		SPI_MasterTransmitInput
   movlw	0x00
   call		SPI_MasterTransmitInput
   
   bsf		PORTE, RE1  ;set cs pin high to inactive so cant write
   
   call		increment_file	    ;have to increment file number twice as two bytes written
   call		increment_file
   
   movlw	0xFD		    ;checking if end of allotted memory reached
   cpfsgt	storage_low
   goto		clear_1
   movlw	0xFF
   cpfseq	storage_high
   goto		clear_1
   movlw	0x03
   cpfseq	storage_highest	    ;once its reached the end of allotted memory it stops looping 
   goto		clear_1
    
   movlw	0x00		    ;moves file address back to start for next write
   movwf	storage_high
   movwf	storage_highest
   movlw	0x01
   movwf	storage_low
   return

   
   end