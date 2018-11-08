#include p18f87k22.inc

    	extern	LCD_Write_Hex, ADC_Setup, ADC_Read, add_check_setup, eight_bit_by_sixteen,sixteen_bit_by_sixteen,eight_bit_by_twentyfour, ADC_convert		    ; external ADC routines
	extern	UART_Setup, UART_Transmit_Message  ; external UART subroutines
	extern  LCD_Setup, LCD_Write_Message, LCD_clear, LCD_move,LCD_delay_ms,LCD_Send_Byte_D,LCD_shiftright,LCD_delay_x4us	; external LCD subroutines
	extern	Pad_Setup, Pad_Read
	
acs0	udata_acs   ; reserve data space in access ram
output_lower	    res 1   ; reserve one byte 
output_upper	    res 1   ; reserve one byte 
	
MIC    code
   call	ADC_Setup
   
MIC_Setup
   movlw 0x00
   movwf TRISD
   movwf TRISE
   
sampling   
   movlw    .32
   call	    LCD_delay_x4us
   call	    ADC_Read
   call	    MIC_output
   bra	    sampling
   
sound_clip_1_sec
   movlw    .32
   call	    LCD_delay_x4us
   call	    ADC_Read
   movff	ADRESL,output_lower
   movff	ADRESH,output_upper
   
   
   
MIC_output
    movff	ADRESL,output_lower
    movff	ADRESH,output_upper
    
    movff	ADRESL,PORTD
    movff	ADRESH,PORTE
    


    end