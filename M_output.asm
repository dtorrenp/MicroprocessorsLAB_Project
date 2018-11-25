#include p18f87k22.inc

    	extern	ADC_Setup, ADC_Read
	extern	Pad_Setup, Pad_Read, sampling_delay_output, fon, foff
	global	Serial_Output_Setup, MIC_straight_output, Output_Storage1,SPI_MasterTransmitStore
	
acs0	udata_acs   ; reserve data space in access ram
output_lower	    res 1   ; reserve one byte 
output_upper	    res 1   ; reserve one byte	
	    
output_storage_low	    res 1;memory address used to keep track of location within FRAM
output_storage_high	    res 1
output_storage_highest	    res 1
	
MicOutput CODE                      ; let linker place main program

Serial_Output_Setup	    ;setup of serial output
    movlw   0x00; set PORTS D,E,F as outputs
    movwf   TRISD
    movwf   TRISE
    movwf   TRISF
    movwf   PORTF
    bsf	    PORTD, RD0	    ;setting bit for chip select of DAC
    
    movlw	0x00;set starting memory address
    movwf	output_storage_high
    movwf	output_storage_highest
    movlw	0x01
    movwf	output_storage_low
    
    bcf SSP2STAT, CKE	    
    ; MSSP enable; CKP=1; SPI master, clock=Fosc/64 (1MHz)
    movlw (1<<SSPEN)|(1<<CKP)|(0x02)
    movwf SSP2CON1
    ; SDO2 output; SCK2 output
    bcf TRISD, SDO2
    bcf TRISD, SCK2
    
    bcf SSP1STAT, CKE	    
    ; MSSP enable; CKP=1; SPI master, clock=Fosc/64 (1MHz)
    movlw (1<<SSPEN)|(1<<CKP)|(0x02)
    movwf SSP1CON1
    ; SDO2 output; SCK2 output
    bcf TRISC, SDO1
    bcf TRISC, SCK1
    return 
    
MIC_straight_output;outputs the input data immediatly, device acts like a speaker
    call	ADC_Read
    movff	ADRESL,output_lower
    movff	ADRESH,output_upper
    call	Serial_Output
    return
    
Serial_Output
    bcf	    PORTD, RD0		;clear RD0/chip select so can write data
    
    movlw   0x50;add config bits to the front of data as DAC required this format
    iorwf   output_upper, W
    call    SPI_MasterTransmit	;transmit byte
    
    movf    output_lower, W
    call    SPI_MasterTransmit	
    
    bsf	    PORTD, RD0		;set chip select to stop write
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
    movf    SSP1BUF, W	    ;moves read data into working register
    bcf PIR1, SSP1IF ; clear interrupt flag
    return

Output_Storage1;output data read from first section of FRAM
   call		sampling_delay_output
   ;call		fon
   ;call		foff
   bcf		PORTE, RE1		;set cs pin low to active so can read from FRAM
   bsf		TRISC, RC4
   
   movlw	0x03	    ;op code for reading FRAM
   call		SPI_MasterTransmitStore;transmit address in FRAM to be read out, in three separate bytes
   movf		output_storage_highest, W
   call		SPI_MasterTransmitStore
   movf		output_storage_high, W
   call		SPI_MasterTransmitStore
   movf		output_storage_low, W
   call		SPI_MasterTransmitStore
   
   movlw	0xFF;dummy data sent to FRAM, required in order to read out data
   call		SPI_MasterTransmitStore
   andlw	0x0F
   movwf	output_upper;move read value into variable
   movlw	0x00;dummy data sent to FRAM, required in order to read out data
   call		SPI_MasterTransmitStore
   movwf	output_lower;move read value into variable
   
   call		Increment
   call		Increment
   call		File_Check1_Out;check whether upper limit of first half of FRAM has been reached
   
   bsf		PORTE, RE1  ;set cs pin high to inactive so cant write
   
   bcf		PORTD, RD0		;clear RD0/chip select so can write data
   
   movlw   0x50;add config bits to the front of data as DAC required this format
   iorwf   output_upper, W
   call    SPI_MasterTransmit	;transmit upper byte
    
   movf    output_lower, W
   call    SPI_MasterTransmit;transmit lower byte	
   
   bcf	   TRISC, RC4
   bsf	   PORTD, RD0		;set chip select to stop write
   return
   
Increment   
   infsnz	output_storage_low, f	    ;increment number in lowest byte
   bra		inc_high	    ;if not zero it will return else increment next byte
   return
   
inc_high
   infsnz	output_storage_high, f	    ;increment number in middle byte
   bra		inc_highest	    ;if not zero it will return else increment next byte
   return

inc_highest   
   infsnz	output_storage_highest, f  ;increment number in highest byte and return
   retlw	0xFF
   return    
    
File_Check1_Out;check current memeory address variables against the upper limit of the first section of FRAM
    movlw	0xFD
    cpfsgt	output_storage_low
    return
    movlw	0xFF
    cpfseq	output_storage_high
    return
    movlw	0x03
    cpfseq	output_storage_highest
    return
    movlw	0x00;if the limit has been hit, reset the memory address to start of first section, so audio continuosly output
    movwf	output_storage_highest
    movwf	output_storage_high
    movlw	0x01
    movwf	output_storage_low
    return
   
    END