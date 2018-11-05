#include p18f87k22.inc

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