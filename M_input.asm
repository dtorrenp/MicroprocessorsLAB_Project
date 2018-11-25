#include p18f87k22.inc

    	extern	ADC_Setup, ADC_Read
	extern	Pad_Setup, Pad_Read, sampling_delay_input, fon, foff
	global	Input_store, Store_Input_Setup, Storage_Clear1,SPI_MasterTransmitInput
	
acs0	udata_acs   ; reserve data space in access ram
storage_low	    res 1;memory address low byte
storage_high	    res 1;memory address high byte
storage_highest	    res 1;memory address highest byte
input_lower	    res 1;lower byte to input to storage
input_upper	    res 1;upper byte to input to storage	    

MIC    code
    
Store_Input_Setup	    ;setup of serial output
    bsf		PORTE, RE1  ;set cs pin high so cant write
    bsf		PORTA, RA4  ;set WP pin on, write protect on
    bsf		PORTC, RC2  ;set hold pin off so doesnt hold
	
    movlw	0x00;set the initla memory address to 0x000001
    movwf	storage_high
    movwf	storage_highest
    movlw	0x01
    movwf	storage_low
    
    bcf SSP1STAT, CKE	    
    ; MSSP enable; CKP=1; SPI master, clock=Fosc/64 (1MHz)
    movlw (1<<SSPEN)|(1<<CKP)|(0x02)
    movwf SSP1CON1
    ; SDO2 output; SCK2 output
    bcf TRISC, SDI1
    bcf TRISC, SCK1
    return
   
Input_store;stores the input data read in from the ADC
   call		sampling_delay_input;delay previously calculted such that the total time of the input code is 1/8000 seconds
   bcf		PORTE, RE1  ;set cs pin low to active so can write
   
   movlw	0x06;WREN Bus config bits
   call		SPI_MasterTransmitInput
   
   bsf		PORTE, RE1 
   
   call		ADC_Read;read in the analog data using the 12 bit ADC
   movff	ADRESL,input_lower
   movff	ADRESH,input_upper
   
   bcf		PORTE, RE1
   
   movlw	0x02;config bits for writing data
   call		SPI_MasterTransmitInput
   movf		storage_highest, W;transmit highest byte of address
   call		SPI_MasterTransmitInput
   movf		storage_high, W;transmit high byte of address
   call		SPI_MasterTransmitInput
   movf		storage_low, W;transmit low byte of address
   call		SPI_MasterTransmitInput
   
   movf		input_upper, W;put upper byte into FRAM
   call		SPI_MasterTransmitInput
   movf		input_lower, W;put lower byte into FRAM
   call		SPI_MasterTransmitInput
   
   bsf		PORTE, RE1  ;set cs pin high to inactive so cant write
   call		increment_file	    ;have to increment file  number twice as two bytes written
   call		increment_file
   call		File_check1;check whether the end of the first section of FRAM memory has been reached
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
    
File_check1;compare current memory address against upper limit of the first section of the FRAM 
    movlw	0xFD 
    cpfsgt	storage_low
    return
    movlw	0xFF
    cpfseq	storage_high
    return
    movlw	0x03
    cpfseq	storage_highest
    return
    movlw	0x00;if the top of the section has been reached reset the memory address again such that it can be looped over again
    movwf	storage_highest
    movwf	storage_high
    movlw	0x01
    movwf	storage_low
    return
    
Storage_Clear1;clear the first section of the memory
   call	fon
   call	clear1_setup
   call	clear_1
   call	foff
   return

clear1_setup;set starting memory address
   movlw	0x00
   movwf	storage_high
   movwf	storage_highest
   movlw	0x01
   movwf	storage_low
   return
   
clear_1;clear the first section of FRAM 
   bcf		PORTE, RE1  ;set cs pin low to active so can write
   
   movlw	0x06;WREN Bus config bits
   call		SPI_MasterTransmitInput
   
   bsf		PORTE, RE1 
   
   bcf		PORTE, RE1
   
   movlw	0x02;config bits for writing data
   call		SPI_MasterTransmitInput
   movf		storage_highest, W
   call		SPI_MasterTransmitInput
   movf		storage_high, W
   call		SPI_MasterTransmitInput
   movf		storage_low, W
   call		SPI_MasterTransmitInput
   
   movlw	0x00;transmit 0x00 instead of data such that the entire FRAM section is now just zeros
   call		SPI_MasterTransmitInput
   movlw	0x00
   call		SPI_MasterTransmitInput
   
   bsf		PORTE, RE1  ;set cs pin high to inactive so cant write
   
   call		increment_file	    ;have to increment file  number twice as two bytes written
   call		increment_file
   
   movlw	0xFD;compare current memory address against upper limit of the first section of the FRAM 
   cpfsgt	storage_low
   goto		clear_1
   movlw	0xFF
   cpfseq	storage_high
   goto		clear_1
   movlw	0x03
   cpfseq	storage_highest
   goto		clear_1
   
   movlw	0x00;if the top of the section has been reached reset the memory address again such that it can be looped over again
   movwf	storage_high
   movwf	storage_highest
   movlw	0x01
   movwf	storage_low
   return

   
   end