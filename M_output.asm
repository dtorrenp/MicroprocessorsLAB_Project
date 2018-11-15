#include p18f87k22.inc

    	extern	LCD_Write_Hex, ADC_Setup, ADC_Read, add_check_setup, eight_bit_by_sixteen,sixteen_bit_by_sixteen,eight_bit_by_twentyfour, ADC_convert		    ; external ADC routines
	extern	UART_Setup, UART_Transmit_Message  ; external UART subroutines
	extern  LCD_Setup, LCD_Write_Message, LCD_clear, LCD_move,LCD_delay_ms,LCD_Send_Byte_D,LCD_shiftright,LCD_delay_x4us	; external LCD subroutines
	extern	Pad_Setup, Pad_Read
	
	extern first_storage_low,first_storage_high,first_storage_highest,last_storage_low,last_storage_high,last_storage_highest 
	
	global	Serial_Output_Setup, MIC_straight_output, Output_Storage
	
acs0	udata_acs   ; reserve data space in access ram
output_lower	    res 1   ; reserve one byte 
output_upper	    res 1   ; reserve one byte	
transmit_upper	    res 1
transmit_lower	    res 1
inbetween1	    res 1
storage_low	    res 1
storage_high	    res 1
storage_highest	    res 1
	
MicOutput CODE                      ; let linker place main program

Serial_Output_Setup	    ;setup of serial output
    bsf	    PORTD, RD0	    ;setting bit for chip select of DAC
	
    bcf SSP2STAT, CKE	    
    ; MSSP enable; CKP=1; SPI master, clock=Fosc/64 (1MHz)
    movlw (1<<SSPEN)|(1<<CKP)|(0x02)
    movwf SSP2CON1
    ; SDO2 output; SCK2 output
    bcf TRISD, SDO2
    bcf TRISD, SCK2
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
    bcf PIR1, SSP1IF ; clear interrupt flag
    return

Output_Storage    
   bcf		PORTD, RD0		;clear RD0/chip select so can write data
   bcf		PORTE, RE1		;set cs pin low to active so can read from FRAM
   
   movlw	0x03	    ;op code for reading FRAM
   call		SPI_MasterTransmitStore
   ;movf		output_storage_highest, W
   call		SPI_MasterTransmitStore
   ;movf		output_storage_high, W
   call		SPI_MasterTransmitStore
   ;movf		output_storage_low, W
   call		SPI_MasterTransmitStore
   
   
   
   bsf		PORTE, RE1  ;set cs pin high to inactive so cant write
   bsf		PORTD, RD0		;clear RD0/chip select so can write data
    
    
    movlw   0x50
    iorwf   output_upper, W
    call    SPI_MasterTransmit	;transmit byte
    
    movf    output_lower, W
    call    SPI_MasterTransmit	
    
    bsf	    PORTD, RD0		;set chip select to stop write
   
inc_low   
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
    
    END