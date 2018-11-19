	#include p18f87k22.inc

	extern	LCD_Write_Hex, ADC_Setup, ADC_Read, add_check_setup, eight_bit_by_sixteen,sixteen_bit_by_sixteen,eight_bit_by_twentyfour, ADC_convert		    ; external ADC routines
	extern  LCD_Setup, LCD_Write_Message, LCD_clear, LCD_move,LCD_delay_ms,LCD_Send_Byte_D,LCD_shiftright, LCD_delay_x4us	; external LCD subroutines
	extern	Pad_Setup, Pad_Read, Pad_Check
	extern	Input_store, Store_Input_Setup
	extern	Serial_Output_Setup, MIC_straight_output
	extern  Add_Start

rst	code	0    ; reset vector
	goto	setup
	
main	code
	; ******* Programme FLASH read Setup Code ***********************
setup	bcf	EECON1, CFGS	; point to Flash program memory  
	bsf	EECON1, EEPGD 	; access Flash program memory
	call	LCD_Setup	; setup LCD
	call	ADC_Setup	; setup ADC
	call	LCD_move	; moves LCD  if wanted, not set currently 
	call	Pad_Setup	; setup keypad entry
	call	Serial_Output_Setup ; setup the serial data tranfer for DAC
	call	Store_Input_Setup;setup code to store mic input
	call    Add_Start       ;setup for adding clips 1 and 2
	goto	start
	
	; ******* Main programme ****************************************
start 	;call	MIC_straight_output
	call    Pad_Check
	bra	start	    
	
	end
