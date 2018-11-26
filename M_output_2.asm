#include p18f87k22.inc

    	extern	ADC_Setup, ADC_Read
	extern	Pad_Setup, Pad_Read, sampling_delay_output
	global	Serial_Output2_Setup, Output_Storage2
	
acs0 udata_acs			    ;reserve data space in access ram
output_lower2	    res 1	    ;reserve one byte for upper byte of ouput
output_upper2	    res 1	    ;reserve one byte for lower byte of ouput
output_storage_low2	    res 1   ;reserve variables to store memory address used to keep track of location within FRAM
output_storage_high2	    res 1   
output_storage_highest2	    res 1
	
MicOutput CODE                      ;let linker place main program

Serial_Output2_Setup		    ;setup of serial output
    
    movlw	0x00		    ;set starting memory address of second partition
    movwf	output_storage_high2
    movlw	0x04
    movwf	output_storage_highest2
    movlw	0x00
    movwf	output_storage_low2
    return 
    
SPI_MasterTransmit		    ;Start transmission of data (held in W) for output through SPI2 (PORTD)
    movwf SSP2BUF
Wait_Transmit			    ;Wait for transmission to complete
    btfss PIR2, SSP2IF
    bra Wait_Transmit
    bcf PIR2, SSP2IF		    ;clear interrupt flag
    return
    
SPI_MasterTransmitStore		    ;Start transmission of data (held in W) for output through SPI1 (PORTC into FRAM)
    movwf SSP1BUF
Wait_TransmitStore		    ;Wait for transmission to complete
    btfss PIR1, SSP1IF
    bra Wait_TransmitStore
    movf    SSP1BUF, W		    ;moves read data from FRAM into workign register before cleared from SSP1BUF
    bcf PIR1, SSP1IF		    ;clear interrupt flag
    return

Output_Storage2			    ;output data read from second section of FRAM
   call		sampling_delay_output
   
   bcf		PORTE, RE1	    ;set cs pin low to active so can read from FRAM
   bsf		TRISC, RC4	    ;set MISO pin high as an input
   
   movlw	0x03			;sending op code for reading FRAM
   call		SPI_MasterTransmitStore	;transmit address to FRAM to be read out, in three separate bytes
   movf		output_storage_highest2, W
   call		SPI_MasterTransmitStore
   movf		output_storage_high2, W
   call		SPI_MasterTransmitStore
   movf		output_storage_low2, W
   call		SPI_MasterTransmitStore
   
   movlw	0xFF			;dummy data sent to FRAM, required in order to read out data
   call		SPI_MasterTransmitStore
   andlw	0x0F			;making sure upper 4 bits of upper byte are 0 so conifg bits are correct later
   movwf	output_upper2		;move read value into variable
   movlw	0x00			;dummy data sent to FRAM, required in order to read out data
   call		SPI_MasterTransmitStore
   movwf	output_lower2		;move read value into variable
   
   bsf		PORTE, RE1		;set cs pin high to inactive so cant write
   bcf		PORTD, RD0		;clear RD0/chip select so can write data
   
   movlw	0x50
   iorwf	output_upper2, W	;add config bits to the front of upper byte as DAC requires this format to work
   call		SPI_MasterTransmit	;transmit upper byte
    
   movf		output_lower2, W
   call		SPI_MasterTransmit	;transmit lower byte
   
   call		Increment2		;increments file address twice and checks hasnt reached end of allotted space
   call		Increment2
   call		File_Check2_Out
   
   bcf		TRISC, RC4		;clears MISO bit to an output
   bsf		PORTD, RD0		;set chip select to stop write
   return
   
Increment2
   infsnz	output_storage_low2, f	;increment number in lowest byte
   bra		inc_high2		;if not zero it will return else increment next byte
   return
   
inc_high2
   infsnz	output_storage_high2, f	;increment number in middle byte
   bra		inc_highest2		;if not zero it will return else increment next byte
   return

inc_highest2   
   infsnz	output_storage_highest2, f  ;increment number in highest byte and return
   retlw	0xFF
   return    
    
File_Check2_Out				;check current memeory address variables against the upper limit of the second section of FRAM
    movlw	0xFD
    cpfsgt	output_storage_low2
    return
    movlw	0xFF
    cpfseq	output_storage_high2
    return
    movlw	0x07
    cpfseq	output_storage_highest2
    return
    movlw	0x04			;if the limit has been hit, reset the memory address to start of second section, so audio continuosly output
    movwf	output_storage_highest2
    movlw	0x00
    movwf	output_storage_high2
    movlw	0x00
    movwf	output_storage_low2
    return
    END