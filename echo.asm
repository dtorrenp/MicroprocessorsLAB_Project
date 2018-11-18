#include p18f87k22.inc
	global Add_Start, Add_Main_loop
acs0	udata_acs   ; reserve data space in access ram  

storage_low_start			    res 1
storage_high_start			    res 1
storage_highest_start			    res 1	
	
storage_low_og				    res 1
storage_high_og				    res 1
storage_highest_og			    res 1	
	
storage_low_echo			    res 1
storage_high_echo			    res 1
storage_highest_echo			    res 1
			    
output_lower_echo			    res 1
output_upper_echo			    res 1			    

input_lower_echo			    res 1
input_upper_echo			    res 1
			    
multiplier				    res 1
				    
MIC    code

Echo_Start
    call Setup_echo				;setup code, simply set starting filre register numbers
    movlw 0x08
    movwf multiplier
    
Echo_Main_loop 
    ;Assume the audio has already been recorded
    ;select first 8 seconds
    ;put the 8 seconds at a specific file register at the end
    ;read the bytes, multiply them
    ;write them back to the FRAM
    ;loop over to the end of the 8 seconds
    ;move on to the next block, back to top but with a differnt multiplier
    
    call move_og_to_end
    
move_og_to_end
    call Read_Setup
    call Read_og
    
    movff output_lower_echo,input_lower_echo
    movff output_upper_echo,input_upper_echo
    
    call Write_Setup				
    call Write_result_end
   
    call Increment_og
    call Increment_og
    call Increment_echo
    call Increment_echo
    
    movlw	0x00				;check whether the first half register has reached 256KB, if so return
    cpfseq	storage_low_og
    bra		Read_and_write
    movlw	0xD0
    cpfseq	storage_high_og
    bra		Read_and_write
    movlw	0x07
    cpfseq	storage_highest_og
    bra		Read_and_write
    return
    
Read_and_write
    call Read_Setup
    call Read_out_og
    
    movff multiplier,W
    mulwf output_lower_echo,input_lower_echo
    mulwf output_upper_echo,input_upper_echo
    
    call Write_Setup				
    call Write_result_1
   
    call Increment_og
    call Increment_og
    call Increment_echo
    call Increment_echo
    
    movlw	0x00				;check whether the first half register has reached 256KB, if so return
    cpfseq	storage_low_og
    bra		Read_and_write
    movlw	0xD0
    cpfseq	storage_high_og
    bra		Read_and_write
    movlw	0x07
    cpfseq	storage_highest_og
    bra		Read_and_write
    return
    
Echo_Setup;set starting position of file registers to read the FRAM from			    
    movlw	0x00
    movwf	storage_highest_og
    movlw	0xD0
    movwf	storage_high_og
    movlw	0x07
    movwf	storage_low_og
   
    movlw	0x00
    movwf	storage_highest_echo
    movlw	0x00
    movwf	storage_high_echo
    movlw	0x01
    movwf	storage_low_echo
      
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

Read_out_og;Read the value from the 1st clip     
   bcf		PORTE, RE1		;set cs pin low to active so can read from FRAM
   ;bcf		TRISC, RC5
   bsf		TRISC, RC4
   
   movlw	0x03	    ;op code for reading FRAM
   call		SPI_MasterTransmitStore
   movf		storage_highest_og, W
   call		SPI_MasterTransmitStore
   movf		storage_high_og, W
   call		SPI_MasterTransmitStore
   movf		storage_low_og, W
   call		SPI_MasterTransmitStore
   
   movlw	0xFF
   call		SPI_MasterTransmitStore
   andlw	0x0F
   movwf	output_upper_echo
   movlw	0x00
   call		SPI_MasterTransmitStore
   movwf	output_lower_echo
   
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

Write_result_og;write to the FRAM 1st half, the second half is left untouched
   bcf		PORTE, RE1  ;set cs pin low to active so can write
   
   bcf		PORTE, RE1  ;set cs pin low to active so can write
   
   movlw	0x06
   call		SPI_MasterTransmitInput
   
   bsf		PORTE, RE1 
   bcf		PORTE, RE1
   
   movlw	0x02
   call		SPI_MasterTransmitInput
   movf		storage_highest_echo, W
   call		SPI_MasterTransmitInput
   movf		storage_high_echo, W
   call		SPI_MasterTransmitInput
   movf		storage_low_echo, W
   call		SPI_MasterTransmitInput
   
   movf		input_upper_echo, W
   call		SPI_MasterTransmitInput
   movf		input_lower_echo, W
   call		SPI_MasterTransmitInput
   
   bsf		PORTE, RE1  ;set cs pin high to inactive so cant write
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