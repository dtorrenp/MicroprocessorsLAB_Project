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
    
MIC_straight_output		    ;subroutine for outputting signal immediately without storing
    call	ADC_Read
    movff	ADRESL,output_lower
    movff	ADRESH,output_upper
    call	Serial_Output
    return
    
Serial_Output
    bcf	    PORTD, RD0		;clear RD0/chip select so can write data
    
    movlw   0x50		;sending DAC config bits, needed for DAC to work
    iorwf   output_upper, W	;combining config bits with upper byte 
    call    SPI_MasterTransmit	;transmit combined byte 
    
    movf    output_lower, W	;sending lower byte of sound to DAC
    call    SPI_MasterTransmit	
    
    bsf	    PORTD, RD0		;set chip select to stop write
    return
    
SPI_MasterTransmit ; Start transmission of data (held in W) through SPI2
    movwf   SSP2BUF
Wait_Transmit ; Wait for transmission to complete
    btfss   PIR2, SSP2IF
    bra	    Wait_Transmit
    bcf	    PIR2, SSP2IF ; clear interrupt flag
    return
    
SPI_MasterTransmitStore ; Start serial transmission of data (held in W) into FRAM using SPI1
    movwf   SSP1BUF
Wait_TransmitStore ; Wait for transmission to complete
    btfss   PIR1, SSP1IF
    bra	    Wait_TransmitStore
    movf    SSP1BUF, W	    ;moves read data into working register
    bcf	    PIR1, SSP1IF ; clear interrupt flag
    return

Output_Storage1				;subroutine for outputting sound bite 1
   call		sampling_delay_output	;delay needed for correct 8Khz sampling rate out
   bcf		PORTE, RE1		;set cs pin low to active so can read from FRAM
   bsf		TRISC, RC4		
   
   movlw	0x03			;op code for reading FRAM sent to FRAM
   call		SPI_MasterTransmitStore	
   movf		output_storage_highest, W   ;sending file address  to be read from to FRAM
   call		SPI_MasterTransmitStore
   movf		output_storage_high, W
   call		SPI_MasterTransmitStore
   movf		output_storage_low, W
   call		SPI_MasterTransmitStore
   
   movlw	0xFF			;dummy byte ignored as data is read out into SSP1BUF
   call		SPI_MasterTransmitStore	;clock needed to be sent for serial output
   andlw	0x0F			;making sure upper 4 bits of upper byte are 0 so conifg bitsb are correct later
   movwf	output_upper		
   movlw	0x00			;dummy byte ignored as data is read out into SSP1BUF
   call		SPI_MasterTransmitStore
   movwf	output_lower;move read value into variable
   
   call		Increment	    ;increments file twice as two data bytes read
   call		Increment
   call		File_Check1_Out	    ;checks file address of outputted files so only allotted space is outputted
   
   bsf		PORTE, RE1	    ;set cs pin high to inactive so cant write
   
   bcf		PORTD, RD0	    ;clear chip select so can write data
   
   movlw   0x50			    ;adds config bits for DAC onto upper data byte
   iorwf   output_upper, W
   call    SPI_MasterTransmit	    ;transmit byte through SPI2 into external circuit
    
   movf    output_lower, W	    ;transmits lower byte into external circuit
   call    SPI_MasterTransmit	
   
   bcf	   TRISC, RC4
   bsf	   PORTD, RD0		    ;set chip select to stop write
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
    
File_Check1_Out				;subroutine for checking if end of alloted memory is reached
    movlw	0xFD	
    cpfsgt	output_storage_low
    return
    movlw	0xFF
    cpfseq	output_storage_high
    return
    movlw	0x03
    cpfseq	output_storage_highest
    return
    movlw	0x00			;if reached then changes file address to start to loop around
    movwf	output_storage_highest
    movwf	output_storage_high
    movlw	0x01
    movwf	output_storage_low
    return
   
    END
