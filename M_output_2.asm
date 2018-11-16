#include p18f87k22.inc

    	extern	LCD_Write_Hex, ADC_Setup, ADC_Read, add_check_setup, eight_bit_by_sixteen,sixteen_bit_by_sixteen,eight_bit_by_twentyfour, ADC_convert		    ; external ADC routines
	extern	UART_Setup, UART_Transmit_Message  ; external UART subroutines
	extern  LCD_Setup, LCD_Write_Message, LCD_clear, LCD_move,LCD_delay_ms,LCD_Send_Byte_D,LCD_shiftright,LCD_delay_x4us	; external LCD subroutines
	extern	Pad_Setup, Pad_Read, sampling_delay_output
	
	extern first_storage_low,first_storage_high,first_storage_highest,last_storage_low,last_storage_high,last_storage_highest 
	
	global	Serial_Output_Setup, MIC_straight_output, Output_Storage
	
acs0	udata_acs   ; reserve data space in access ram
output_lower	    res 1   ; reserve one byte 
output_upper	    res 1   ; reserve one byte	
transmit_upper	    res 1
transmit_lower	    res 1
inbetween1	    res 1
output_storage_low	    res 1
output_storage_high	    res 1
output_storage_highest	    res 1
	
MicOutput CODE                      ; let linker place main program

Serial_Output_Setup	    ;setup of serial output
    movlw   0x00
    movwf   TRISD
    movwf   TRISE
    movwf   TRISF
    bsf	    PORTD, RD0	    ;setting bit for chip select of DAC
    
    movlw	0x00
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

Storage_Output_setup
    ;movff first_storage_highest,output_storage_highest
    ;movff first_storage_high,output_storage_high
    ;movff first_storage_low,output_storage_low
    return
    
MIC_straight_output
    call	ADC_Read
    movff	ADRESL,output_lower
    movff	ADRESH,output_upper
    call	Serial_Output
    return
    
Serial_Output
   
    
    bcf	    PORTD, RD0		;clear RD0/chip select so can write data
    
    movlw   0x50
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
    movf    SSP1BUF, W
    bcf PIR1, SSP1IF ; clear interrupt flag
    return

Output_Storage     
   call		sampling_delay_output
   
   bcf		PORTE, RE1		;set cs pin low to active so can read from FRAM
   ;bcf		TRISC, RC5
   bsf		TRISC, RC4
   
   movlw	0x03	    ;op code for reading FRAM
   call		SPI_MasterTransmitStore
   movf		output_storage_highest, W
   call		SPI_MasterTransmitStore
   movf		output_storage_high, W
   call		SPI_MasterTransmitStore
   movf		output_storage_low, W
   call		SPI_MasterTransmitStore
   
   movlw	0xFF
   call		SPI_MasterTransmitStore
   andlw	0x0F
   movwf	output_upper
   movlw	0x00
   call		SPI_MasterTransmitStore
   movwf	output_lower
   
   movff	output_storage_high, PORTF
   
   call		Increment
   call		Increment
   
   bsf		PORTE, RE1  ;set cs pin high to inactive so cant write
   
   bcf		PORTD, RD0		;clear RD0/chip select so can write data
   
   movlw   0x50
   iorwf   output_upper, W
   call    SPI_MasterTransmit	;transmit byte
    
   movf    output_lower, W
   call    SPI_MasterTransmit	
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
    
    END