#include p18f87k22.inc
	global Add_Start, Add_Main_loop
acs0	udata_acs   ; reserve data space in access ram  
					    
storage_low_1				    res 1
storage_high_1				    res 1
storage_highest_1			    res 1
			    
storage_low_2				    res 1
storage_high_2				    res 1
storage_highest_2			    res 1

output_lower_1				    res 1
output_upper_1				    res 1			    
output_lower_2				    res 1
output_upper_2				    res 1

input_lower_1				    res 1
input_upper_1				    res 1
				    
MIC    code

Add_Start
    call Setup_add				;setup code, simply set starting filre register numbers

Add_Main_loop 
    call Read_Setup				;reading from the FRAM setup
    call Read_out_1				;read from the first half of the FRAM
    call Read_out_2				;read from the second half of the FRAM, equivalent to a shift of 256KB
    
    movf output_lower_1,W			;DO I NEED TO CLEAR THE CARRY FLAG???
    addwf output_lower_2,input_lower_1		;add lower byte 
    
    movf output_upper_1,W
    addwfc output_upper_2,input_upper_1		;add upper byte with carry from lower byte addition
    
    call Write_Setup				;setup to read
    call Write_result_1				;write the result back to the first half og the FRAM
    
    call		Increment_1		;increase the value of the register counters
    call		Increment_1
    call		Increment_2
    call		Increment_2
    
    movlw	0x01				;check whether the first half register has reached 256KB, if so return
    cpfseq	storage_low_1
    bra		Add_Main_loop
    movlw	0xE8
    cpfseq	storage_high_1
    bra		Add_Main_loop
    movlw	0x03
    cpfseq	storage_highest_1
    bra		Add_Main_loop
    return
    
Setup_add;set starting position of file registers to read the FRAM from			    
    movlw	0x00
    movwf	storage_highest_1
    movlw	0x00
    movwf	storage_high_1
    movlw	0x01
    movwf	storage_low_1
   
    movlw	0x03
    movwf	storage_highest_2
    movlw	0xE8
    movwf	storage_high_2
    movlw	0x02
    movwf	storage_low_2
      
Read_Setup;setup to read from the FRAM
    movlw   0x00
    movwf   TRISD
    movwf   TRISE
    movwf   TRISF
    bsf	    PORTD, RD0	    ;setting bit for chip select of DAC
    
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
    
Read_out_1;Read the value from the 1st clip     
   bcf		PORTE, RE1		;set cs pin low to active so can read from FRAM
   ;bcf		TRISC, RC5
   bsf		TRISC, RC4
   
   movlw	0x03	    ;op code for reading FRAM
   call		SPI_MasterTransmitStore
   movf		storage_highest_1, W
   call		SPI_MasterTransmitStore
   movf		storage_high_1, W
   call		SPI_MasterTransmitStore
   movf		storage_low_1, W
   call		SPI_MasterTransmitStore
   
   movlw	0xFF
   call		SPI_MasterTransmitStore
   andlw	0x0F
   movwf	output_upper_1
   movlw	0x00
   call		SPI_MasterTransmitStore
   movwf	output_lower_1
   
   bsf		PORTE, RE1  ;set cs pin high to inactive so cant write
   bcf	   TRISC, RC4
   return
   
Read_out_2;read from the second clip   
   bcf		PORTE, RE1		;set cs pin low to active so can read from FRAM
   ;bcf		TRISC, RC5
   bsf		TRISC, RC4
   
   movlw	0x03	    ;op code for reading FRAM
   call		SPI_MasterTransmitStore
   movf		storage_highest_2, W
   call		SPI_MasterTransmitStore
   movf		storage_high_2, W
   call		SPI_MasterTransmitStore
   movf		storage_low_2, W
   call		SPI_MasterTransmitStore
   
   movlw	0xFF
   call		SPI_MasterTransmitStore
   andlw	0x0F
   movwf	output_upper_2
   movlw	0x00
   call		SPI_MasterTransmitStore
   movwf	output_lower_2
   
   bsf		PORTE, RE1  ;set cs pin high to inactive so cant write
   bcf	   TRISC, RC4
   return

Write_Setup;setup to write back to the FRAM
    bsf		PORTE, RE1  ;set cs pin high so cant write
    bsf		PORTA, RA4  ;set WP pin on, write protect on
    bsf		PORTC, RC2  ;set hold pin off so doesnt hold
    
    bcf SSP1STAT, CKE	    
    ; MSSP enable; CKP=1; SPI master, clock=Fosc/64 (1MHz)
    movlw (1<<SSPEN)|(1<<CKP)|(0x02)
    movwf SSP1CON1
    ; SDO2 output; SCK2 output
    bcf TRISC, SDI1
    bcf TRISC, SCK1
    return
    
Write_result_1;write to the FRAM 1st half, the second half is left untouched
   bcf		PORTE, RE1  ;set cs pin low to active so can write
   
   bcf		PORTE, RE1  ;set cs pin low to active so can write
   
   movlw	0x06
   call		SPI_MasterTransmitInput
   
   bsf		PORTE, RE1 
   bcf		PORTE, RE1
   
   movlw	0x02
   call		SPI_MasterTransmitInput
   movf		storage_highest_1, W
   call		SPI_MasterTransmitInput
   movf		storage_high_1, W
   call		SPI_MasterTransmitInput
   movf		storage_low_1, W
   call		SPI_MasterTransmitInput
   
   movf		input_upper_1, W
   call		SPI_MasterTransmitInput
   movf		input_lower_1, W
   call		SPI_MasterTransmitInput
   
   bsf		PORTE, RE1  ;set cs pin high to inactive so cant write
   return 
   
Increment_1;increment the value of the registers for the first half of the FRAM     
   infsnz	storage_low_1, f	    ;increment number in lowest byte
   bra		inc_high_1	    ;if not zero it will return else increment next byte
   return
   
inc_high_1
   infsnz	storage_high_1, f	    ;increment number in middle byte
   bra		inc_highest_1	    ;if not zero it will return else increment next byte
   return

inc_highest_1   
   infsnz	storage_highest_1, f  ;increment number in highest byte and return
   retlw	0xFF
   return
   
Increment_2;increment the value of the registers for the second half of the FRAM       
   infsnz	storage_low_2, f	    ;increment number in lowest byte
   bra		inc_high_2	    ;if not zero it will return else increment next byte
   return
   
inc_high_2
   infsnz	storage_high_2, f	    ;increment number in middle byte
   bra		inc_highest_2	    ;if not zero it will return else increment next byte
   return

inc_highest_2   
   infsnz	storage_highest_2, f  ;increment number in highest byte and return
   retlw	0xFF
   return
   
    end