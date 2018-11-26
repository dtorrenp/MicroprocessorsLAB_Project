#include p18f87k22.inc

    	extern	ADC_Setup, ADC_Read
	extern	Pad_Setup, Pad_Read, sampling_delay_input, fon, foff
	global	Input_store, Store_Input_Setup, Storage_Clear1,SPI_MasterTransmitInput
	
acs0	udata_acs   ; reserve data space in access ram
storage_low	    res 1   ;memory address low byte
storage_high	    res 1   ;memory address high byte
storage_highest	    res 1   ;memory address highest byte
input_lower	    res 1   ;lower byte to input to storage
input_upper	    res 1   ;upper byte to input to storage	    

MIC    code
    
Store_Input_Setup	    ;setup of serial output to write to FRAM
    bsf		PORTE, RE1  ;set cs pin high so cant write
    bsf		PORTA, RA4  ;set WP pin on, write protect on
    bsf		PORTC, RC2  ;set hold pin off so doesnt hold
	
    movlw	0x00	    ;set the inital memory address to 0x000001
    movwf	storage_high
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
   
Input_store			    ;stores the input data read in from the ADC
   call		sampling_delay_input;delay previously calculted such that the total time of the input code is 1/8000 seconds
   bcf		PORTE, RE1	    ;set cs pin low to active so can write
   
   movlw	0x06			;sending opcode to set WREN pin
   call		SPI_MasterTransmitInput
   
   bsf		PORTE, RE1		;set cs pin high to seperate two write cycles
   
   call		ADC_Read		;calls ADC to read in data from mic input
   movff	ADRESL,input_lower	;transfers input from special file register into dedicated file locations
   movff	ADRESH,input_upper	
   
   bcf		PORTE, RE1		;setting cs pin low again to write
   
   movlw	0x02			;sending opcode for write command to FRAM
   call		SPI_MasterTransmitInput	;sent through SPI1
   movf		storage_highest, W	;sending 6 byte address, msb first
   call		SPI_MasterTransmitInput
   movf		storage_high, W		;transmit high byte of address
   call		SPI_MasterTransmitInput
   movf		storage_low, W		;transmit low byte of address
   call		SPI_MasterTransmitInput
   
   movf		input_upper, W		;sending data to be stored at file address into FRAM
   call		SPI_MasterTransmitInput
   movf		input_lower, W		;sending second byte
   call		SPI_MasterTransmitInput	;file address increments automatically as cs pin still low
   
   bsf		PORTE, RE1		;set cs pin high to inactive so cant write
   call		increment_file		;have to increment file  number twice as two bytes written
   call		increment_file
   call		File_check1		;check whether the end of the first section of FRAM memory has been reached
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

SPI_MasterTransmitInput		    ;Start transmission of data (held in W)
    movwf SSP1BUF
Wait_TransmitInput		    ;Wait for transmission to complete
    btfss PIR1, SSP1IF
    bra Wait_TransmitInput
    bcf PIR1, SSP1IF		    ;clear interrupt flag
    return
    
File_check1			    ;subroutine for making program writing to only allotted memory as file 
    movlw	0xFD		    ;increments twice each time just checks if greater than instead of equal to
    cpfsgt	storage_low	    
    return			    
    movlw	0xFF
    cpfseq	storage_high
    return
    movlw	0x03
    cpfseq	storage_highest
    return
    movlw	0x00		;if one of the last addresses of the section has been reached reset the memory address again such that it can be looped over again
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
   
clear_1					;clear the first section of FRAM 
   bcf		PORTE, RE1		;set cs pin low to active so can write
   
   movlw	0x06			;sending opcode to set WREN pin
   call		SPI_MasterTransmitInput
   
   bsf		PORTE, RE1		;set cs pin high to seperate two write cycles
   
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
   
   bsf		PORTE, RE1		;set cs pin high to inactive so cant write
   
   call		increment_file		;have to increment file number twice as two bytes written
   call		increment_file
   
   movlw	0xFD			;compare current memory address against upper limit of the first section of the FRAM 
   cpfsgt	storage_low
   goto		clear_1
   movlw	0xFF
   cpfseq	storage_high
   goto		clear_1
   movlw	0x03
   cpfseq	storage_highest		;once its reached the end of allotted memory it stops looping 
   goto		clear_1
    
   movlw	0x00			;moves file address back to start for next write
   movwf	storage_high
   movwf	storage_highest
   movlw	0x01
   movwf	storage_low
   return

   
   end
