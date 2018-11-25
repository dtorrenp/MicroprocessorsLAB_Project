#include p18f87k22.inc

    	extern	ADC_Setup, ADC_Read
	extern	Pad_Setup, Pad_Read, sampling_delay_output
	global	Serial_Output2_Setup, Output_Storage2
	
acs0 udata_acs   ; reserve data space in access ram
output_lower2	    res 1   ; reserve one byte 
output_upper2	    res 1   ; reserve one byte
output_storage_low2	    res 1;memory address used to keep track of location within FRAM
output_storage_high2	    res 1
output_storage_highest2	    res 1
	
MicOutput CODE                      ; let linker place main program

Serial_Output2_Setup	    ;setup of serial output
    
    movlw	0x00;set starting memory address
    movwf	output_storage_high2
    movlw	0x04
    movwf	output_storage_highest2
    movlw	0x00
    movwf	output_storage_low2
    return 
    
SPI_MasterTransmit ; Start transmission of data (held in W)
    movwf SSP2BUF
Wait_Transmit ; Wait for transmission to complete
    btfss PIR2, SSP2IF
    bra Wait_Transmit
    bcf PIR2, SSP2IF ; clear interrupt flag
    return
    
SPI_MasterTransmitStore ; Start transmission of data (held in W)
    movwf SSP1BUF
Wait_TransmitStore ; Wait for transmission to complete
    btfss PIR1, SSP1IF
    bra Wait_TransmitStore
    movf    SSP1BUF, W
    bcf PIR1, SSP1IF ; clear interrupt flag
    return

Output_Storage2;output data read from second section of FRAM
   call		sampling_delay_output
   
   bcf		PORTE, RE1		;set cs pin low to active so can read from FRAM
   bsf		TRISC, RC4
   
   movlw	0x03	    ;op code for reading FRAM
   call		SPI_MasterTransmitStore;transmit address in FRAM to be read out, in three separate bytes
   movf		output_storage_highest2, W
   call		SPI_MasterTransmitStore
   movf		output_storage_high2, W
   call		SPI_MasterTransmitStore
   movf		output_storage_low2, W
   call		SPI_MasterTransmitStore
   
   movlw	0xFF;dummy data sent to FRAM, required in order to read out data
   call		SPI_MasterTransmitStore
   andlw	0x0F
   movwf	output_upper2;move read value into variable
   movlw	0x00;dummy data sent to FRAM, required in order to read out data
   call		SPI_MasterTransmitStore
   movwf	output_lower2;move read value into variable
   
   bsf		PORTE, RE1  ;set cs pin high to inactive so cant write
   
   bcf		PORTD, RD0		;clear RD0/chip select so can write data
   
   movlw   0x50
   iorwf   output_upper2, W ;add config bits to the front of data as DAC required this format
   call    SPI_MasterTransmit	;transmit upper byte
    
   movf    output_lower2, W
   call    SPI_MasterTransmit;transmit lower byte
   
   call		Increment2
   call		Increment2
   call		File_Check2_Out
   
   bcf	   TRISC, RC4
   bsf	   PORTD, RD0		;set chip select to stop write
   return
   
Increment2
   infsnz	output_storage_low2, f	    ;increment number in lowest byte
   bra		inc_high2	    ;if not zero it will return else increment next byte
   return
   
inc_high2
   infsnz	output_storage_high2, f	    ;increment number in middle byte
   bra		inc_highest2	    ;if not zero it will return else increment next byte
   return

inc_highest2   
   infsnz	output_storage_highest2, f  ;increment number in highest byte and return
   retlw	0xFF
   return    
    
File_Check2_Out;check current memeory address variables against the upper limit of the second section of FRAM
    movlw	0xFD
    cpfsgt	output_storage_low2
    return
    movlw	0xFF
    cpfseq	output_storage_high2
    return
    movlw	0x07
    cpfseq	output_storage_highest2
    return
    movlw	0x04;if the limit has been hit, reset the memory address to start of second section, so audio continuosly output
    movwf	output_storage_highest2
    movlw	0x00
    movwf	output_storage_high2
    movlw	0x00
    movwf	output_storage_low2
    return
    END