#include p18f87k22.inc
	global Setup_add, Add_Main_loop
	extern SPI_MasterTransmitStore,SPI_MasterTransmitInput
	
acs0	udata_acs				;reserve data space in access ram  
					    
storage_low_1				    res 1;memory of address corresponding to first section of FRAM
storage_high_1				    res 1
storage_highest_1			    res 1
			    
storage_low_2				    res 1;memory of address corresponding to second section of FRAM
storage_high_2				    res 1
storage_highest_2			    res 1

output_lower_1				    res 1;store data read from FRAM
output_upper_1				    res 1			    
output_lower_2				    res 1
output_upper_2				    res 1

input_lower_1				    res 1;store data to be input back into first half of FRAM
input_upper_1				    res 1
				    
MIC    code
    
Setup_add			    ;set starting position of FRAM address variables to read the:			    
    movlw	0x00			;first section
    movwf	storage_highest_1
    movlw	0x00
    movwf	storage_high_1
    movlw	0x01
    movwf	storage_low_1
   
    movlw	0x04			;second section
    movwf	storage_highest_2
    movlw	0x00
    movwf	storage_high_2
    movlw	0x00
    movwf	storage_low_2
    return
    
Add_Main_loop 
    call	Read_Setup		;calls setup routine to read from FRAM
    call	Read_out_1		;read from the first half of the FRAM
    call	Read_out_2		;read from the second half of the FRAM, equivalent to a shift of 256KB
    
    movf	output_lower_1,W
    addwf	output_lower_2,W	;add the two lower bytes
    movwf	input_lower_1		;move result into variable
    
    movf	output_upper_1,W
    addwfc	output_upper_2, W	;add the two upper bytes with the carry from the addition of the lower bytes
    movwf	input_upper_1		;move result into variable
    
    rrcf	input_upper_1,f		;rotate upper byte with carry, such that its LSB will set carry bit if necessary 
    rrcf	input_lower_1,f		;rotates lower byte with carry so if LSD from uppper was set it will carry to MSB of this byte, lose LSB though
    
    call	Write_Setup		;setup to read
    call	Write_result_1		;write the result back to the first half of the FRAM
    
    call	Increment_1		;increase the value of the both address variables
    call	Increment_1
    call	Increment_2
    call	Increment_2
    
    movlw	0xFD			;check whether the first partitions address varible has reached the end of its allotted space, if so return (addition is complete)
    cpfsgt	storage_low_1
    bra		Add_Main_loop
    movlw	0xFF
    cpfseq	storage_high_1
    bra		Add_Main_loop
    movlw	0x03
    cpfseq	storage_highest_1
    bra		Add_Main_loop
    return
    

      
Read_Setup				;setup to read from the FRAM
    movlw   0x00			
    movwf   TRISF			;clear TRISF for output
    bsf	    PORTD, RD0			;setting bit for chip select of DAC
    
    bcf SSP2STAT, CKE	    
					;MSSP enable; CKP=1; SPI master, clock=Fosc/64 (1MHz)
    movlw (1<<SSPEN)|(1<<CKP)|(0x02)
    movwf SSP2CON1
					;SDO2 output; SCK2 output
    bcf TRISD, SDO2
    bcf TRISD, SCK2
    
    bcf SSP1STAT, CKE	    
					;MSSP enable; CKP=1; SPI master, clock=Fosc/64 (1MHz)
    movlw (1<<SSPEN)|(1<<CKP)|(0x02)
    movwf SSP1CON1
					;SDO1 output; SCK1 output
    bcf TRISC, SDO1
    bcf TRISC, SCK1
    return
    
Read_out_1				;Read the value from the 1st audio clip     
   bcf		PORTE, RE1		;set cs pin low to active so can read from FRAM
   bsf		TRISC, RC4		;set MISO pin high as an input
   
   movlw	0x03			;sending op code for reading FRAM
   call		SPI_MasterTransmitStore	;memory addresses transmitted to FRAM
   movf		storage_highest_1, W
   call		SPI_MasterTransmitStore
   movf		storage_high_1, W
   call		SPI_MasterTransmitStore
   movf		storage_low_1, W
   call		SPI_MasterTransmitStore
   
   movlw	0xFF			;dummy data sent to FRAM (necessary for read)
   call		SPI_MasterTransmitStore
   andlw	0x0F
   movwf	output_upper_1		;move read data in the working register to the variable
   movlw	0x00			;dummy data sent to FRAM (necessary for read)
   call		SPI_MasterTransmitStore
   movwf	output_lower_1		;move read data in the working register to the variable
   
   bsf		PORTE, RE1		;set cs pin high to inactive so cant write
   bcf		TRISC, RC4		;clears MISO bit to an output
   return
   
Read_out_2				;read from the second half of FRAM  
   bcf		PORTE, RE1		;set cs pin low to active so can read from FRAM
   bsf		TRISC, RC4		;set MISO pin high as an input
   
   movlw	0x03			;sending op code for reading FRAM
   call		SPI_MasterTransmitStore	;memory addresses transmitted to FRAM
   movf		storage_highest_2, W
   call		SPI_MasterTransmitStore
   movf		storage_high_2, W
   call		SPI_MasterTransmitStore
   movf		storage_low_2, W
   call		SPI_MasterTransmitStore
   
   movlw	0xFF			;dummy data sent to FRAM (necessary for read)
   call		SPI_MasterTransmitStore
   andlw	0x0F			;making sure upper 4 bits of upper byte are 0 so conifg bits are correct later
   movwf	output_upper_2		;move read data in the working register to the variable
   movlw	0x00			;dummy data sent to FRAM (necessary for read)
   call		SPI_MasterTransmitStore
   movwf	output_lower_2		;move read data in the working register to the variable
   
   bsf		PORTE, RE1		;set cs pin high to inactive so cant write
   bcf		TRISC, RC4		;clears MISO bit to an output
   return

Write_Setup				;setup to write back to the FRAM
    bsf		PORTE, RE1		;set cs pin high so cant write
    bsf		PORTA, RA4		;set WP pin on, write protect on
    bsf		PORTC, RC2		;set hold pin off so doesnt hold
    
    bcf SSP1STAT, CKE	    
					; MSSP enable; CKP=1; SPI master, clock=Fosc/64 (1MHz)
    movlw (1<<SSPEN)|(1<<CKP)|(0x02)
    movwf SSP1CON1
					;SDO1 output; SCK1 output
    bcf TRISC, SDI1
    bcf TRISC, SCK1
    return
    
Write_result_1				;write to the FRAM 1st half, the second half is left untouched
   bcf		PORTE, RE1		;set cs pin low to active so can write
   
   movlw	0x06			;sends WREN bus congfiguration byte to FRAM
   call		SPI_MasterTransmitInput
   
   bsf		PORTE, RE1
					;necessary seperation of write cycles to FRAM
   bcf		PORTE, RE1
   
   movlw	0x02			;sends opcode to FRAM, to write to FRAM
   call		SPI_MasterTransmitInput	;memory address to write to transmitted to FRAM
   movf		storage_highest_1, W
   call		SPI_MasterTransmitInput
   movf		storage_high_1, W
   call		SPI_MasterTransmitInput
   movf		storage_low_1, W
   call		SPI_MasterTransmitInput
   
   movf		input_upper_1, W	;upper byte result of addition written to the FRAM
   call		SPI_MasterTransmitInput
   movf		input_lower_1, W	;lower byte result of addition written to the FRAM
   call		SPI_MasterTransmitInput
   
   bsf		PORTE, RE1		;set cs pin high to inactive so cant write
   return 
   
Increment_1				;increment the value of the registers for the first half of the FRAM     
   infsnz	storage_low_1, f	;increment number in lowest byte
   bra		inc_high_1		;if not zero it will return else increment next byte
   return
   
inc_high_1
   infsnz	storage_high_1, f	;increment number in middle byte
   bra		inc_highest_1		;if not zero it will return else increment next byte
   return

inc_highest_1   
   infsnz	storage_highest_1, f	;increment number in highest byte and return
   retlw	0xFF
   return
   
Increment_2				;increment the value of the registers for the second half of the FRAM       
   infsnz	storage_low_2, f	;increment number in lowest byte
   bra		inc_high_2		;if not zero it will return else increment next byte
   return
   
inc_high_2
   infsnz	storage_high_2, f	;increment number in middle byte
   bra		inc_highest_2		;if not zero it will return else increment next byte
   return

inc_highest_2   
   infsnz	storage_highest_2, f	;increment number in highest byte and return
   retlw	0xFF
   return
   
    end