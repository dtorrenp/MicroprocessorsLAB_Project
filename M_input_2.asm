#include p18f87k22.inc

    	extern	ADC_Setup, ADC_Read
	extern	Pad_Setup, Pad_Read, sampling_delay_input, SPI_MasterTransmitInput
	
	global	Input_store2, Store_Input_2_Setup,Storage_Clear2, fon, foff
	
acs0	udata_acs   ; reserve data space in access ram
in2_storage_low	    res 1
in2_storage_high    res 1
in2_storage_highest res 1
input_lower2	    res 1
input_upper2	    res 1  	    

MIC    code
    
Store_Input_2_Setup		;setup of serial output to write to 2nd section of FRAM
    movlw	0x00
    movwf	TRISF
    movwf	PORTF
    
    movlw	0x00		;set the initial memory address to 0x040000
    movwf	in2_storage_low
    movlw	0x00
    movwf	in2_storage_high
    movlw	0x04
    movwf	in2_storage_highest
    return
   
Input_store2			    ;stores the input data read in from the ADC
   call		sampling_delay_input;delay previously calculted such that the total time of the input code is 1/8000 seconds
   
   bcf		PORTE, RE1	    ;set cs pin low to active so can write
   
   movlw	0x06		    ;WREN Bus config bits
   call		SPI_MasterTransmitInput
   
   bsf		PORTE, RE1	    ;set cs pin high to seperate write commands
   
   call		ADC_Read	    ;read in the analog data using the 12 bit ADC
   movff	ADRESL,input_lower2
   movff	ADRESH,input_upper2
   
   bcf		PORTE, RE1	    ;set cs pin low to active so can write
   
   movlw	0x02			;sending config bits for writing data
   call		SPI_MasterTransmitInput
   movf		in2_storage_highest, W	;transmit highest byte of address
   call		SPI_MasterTransmitInput
   movf		in2_storage_high, W	;transmit high byte of address
   call		SPI_MasterTransmitInput
   movf		in2_storage_low, W	;transmit low byte of address
   call		SPI_MasterTransmitInput
   
   movf		input_upper2, W		;put upper byte into FRAM
   call		SPI_MasterTransmitInput
   movf		input_lower2, W		;put lower byte into FRAM
   call		SPI_MasterTransmitInput
   
   bsf		PORTE, RE1	    ;set cs pin high to inactive so cant write
   call		increment_file2	    ;have to increment file  number twice as two bytes written
   call		increment_file2
   call		File_check2	    ;check whether the end of the second section of FRAM memory has been reached
   return			    
  
increment_file2   
   infsnz	in2_storage_low, f	    ;increment number in lowest byte
   bra		inc_high_in2	    ;if not zero it will return else increment next byte
   return
   
inc_high_in2
   infsnz	in2_storage_high, f	    ;increment number in middle byte
   bra		inc_highest_in2	    ;if not zero it will return else increment next byte
   return

inc_highest_in2   
   infsnz	in2_storage_highest, f  ;increment number in highest byte and return
   retlw	0xFF
   return

File_check2			    ;compare current memory address against upper limit of the second section of the FRAM
    movlw	0xFD
    cpfsgt	in2_storage_low	    ;increments twice each time so just checks if greater than instead of equal to
    return
    movlw	0xFF
    cpfseq	in2_storage_high
    return
    movlw	0x07
    cpfseq	in2_storage_highest
    return
    movlw	0x04		    ;if the top of the section has been reached, reset the memory address again such that it can be looped over again
    movwf	in2_storage_highest
    movlw	0x00
    movwf	in2_storage_high
    movlw	0x00
    movwf	in2_storage_low
    return
   
Storage_Clear2			  ;subroutine to clear the second section of the FRAM
   call	fon
   call	clear_2setup
   call	clear_2
   call	foff
   return
   
clear_2setup			  ;set starting memory address
   movlw	0x04
   movwf	in2_storage_highest
   movlw	0x00
   movwf	in2_storage_high
   movlw	0x00
   movwf	in2_storage_low
   return
    
clear_2				   ;clear the second section of FRAM 
   bcf		PORTE, RE1	   ;set cs pin low to active so can write

   movlw	0x06		   ;WREN Bus config bits sent serially to FRAM
   call		SPI_MasterTransmitInput
   
   bsf		PORTE, RE1 
					    ;seperating write commands
   bcf		PORTE, RE1
   
   movlw	0x02			    ;sending config bits for writing data
   call		SPI_MasterTransmitInput
   movf		in2_storage_highest, W	    ;sending memory address to write to
   call		SPI_MasterTransmitInput
   movf		in2_storage_high, W
   call		SPI_MasterTransmitInput
   movf		in2_storage_low, W
   call		SPI_MasterTransmitInput
   
   movlw	0x00			    ;transmit 0x00 instead of data such that the entire FRAM section is now just zeros
   call		SPI_MasterTransmitInput
   movlw	0x00
   call		SPI_MasterTransmitInput
   
   bsf		PORTE, RE1	    ;set cs pin high to inactive so cant write
   
   call		increment_file2	    ;have to increment file  number twice as two bytes written
   call		increment_file2
   
   movlw	0xFD		    ;checks if reached end of memory partition it is clearing
   cpfsgt	in2_storage_low	    ;increments twice each time so just checks if greater than instead of equal to
   goto		clear_2
   movlw	0xFF
   cpfseq	in2_storage_high
   goto		clear_2
   movlw	0x07
   cpfseq	in2_storage_highest
   goto		clear_2
   
   movlw	0x04		    ;resets stored memory address for next write
   movwf	in2_storage_highest
   movlw	0x00
   movwf	in2_storage_high
   movlw	0x00
   movwf	in2_storage_low
   return
   
fon			    ;subroutines used as diagnostic and for telling when clear and add functions are working (as not instant)
   movlw	0xFF
   movwf	PORTF
   return
   
foff
   movlw	0x00
   movwf	PORTF
   return
    
    end