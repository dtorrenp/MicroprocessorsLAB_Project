#include p18f87k22.inc

    	extern	LCD_Write_Hex, ADC_Setup, ADC_Read, add_check_setup, eight_bit_by_sixteen,sixteen_bit_by_sixteen,eight_bit_by_twentyfour, ADC_convert		    ; external ADC routines
	extern	UART_Setup, UART_Transmit_Message  ; external UART subroutines
	extern  LCD_Setup, LCD_Write_Message, LCD_clear, LCD_move,LCD_delay_ms,LCD_Send_Byte_D,LCD_shiftright,LCD_delay_x4us	; external LCD subroutines
	extern	Pad_Setup, Pad_Read

MicOutput CODE                      ; let linker place main program

serial_output_setup	    ;setup of serial output
    bsf	    PORTD, RD0	    ;setting bit for chip select of DAC
    bsf	    PORTD, RD2	    ;setting bit to prevent shutdown of DAC
    bcf	    PORTD, RD1	    ;clearing bit for sychronisatio input
	
    bcf SSP2STAT, CKE	    
    ; MSSP enable; CKP=1; SPI master, clock=Fosc/64 (1MHz)
    movlw (1<<SSPEN)|(1<<CKP)|(0x02)
    movwf SSP2CON1
    ; SDO2 output; SCK2 output
    bcf TRISD, SDO2
    bcf TRISD, SCK2
    return 

MIC_output
    movff	ADRESL,output_lower
    movff	ADRESH,output_upper
    ;movff       output_upper,PORTC ;put upper byte of signal into PORTC for ref
    
serial_output
    bcf	    PORTD, RD0		;clear RD0/chip select so can write data
    
    movlw   0xF0
    andwf   output_upper, W
    movwf   transmit_upper
    swapf   transmit_upper
    movlw   0x50
    iorwf   transmit_upper, f
    movf    transmit_upper, w
    call    SPI_MasterTransmit	;transmit byte
    
    movlw   0x0F
    andwf   output_upper, w
    movwf   transmit_upper
    movlw   0xF0
    andwf   output_lower, w
    iorwf   inbetween1, w
    movwf   transmit_lower
    swapf   transmit_lower
    call    SPI_MasterTransmit	;transmit byte
    
    bsf	    PORTD, RD0		;set chip select to stop write
    return
    
SPI_MasterTransmit ; Start transmission of data (held in W)
    movwf SSP2BUF
Wait_Transmit ; Wait for transmission to complete
    btfss PIR2, SSP2IF
    bra Wait_Transmit
    bcf PIR2, SSP2IF ; clear interrupt flag
   
    return

Output_Storage    
   bcf		PORTE, RE1  ;set cs pin low to active so can write
   
   movlw	0x03
   call		SPI_MasterTransmit
   movf		storage_highest, W
   call		SPI_MasterTransmit
   movf		storage_high, W
   call		SPI_MasterTransmit
   movf		storage_low, W
   call		SPI_MasterTransmit
   
   
   bsf	PORTE, RE1  ;set cs pin high to inactive so cant write
   
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