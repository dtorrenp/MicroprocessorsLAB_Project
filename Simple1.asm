	#include p18f87k22.inc

	extern	ADC_Setup	    
	extern	Pad_Setup, Pad_Check
	extern	Store_Input_Setup
	extern	Serial_Output_Setup, MIC_straight_output, Serial_Output2_Setup, Store_Input_2_Setup
	extern  Add_Start
	
acs0	udata_acs   ; reserve data space in access ram
	
rst	code	0    ; reset vector
	goto	setup
	
main	code
	; ******* Programme FLASH read Setup Code ***********************
setup	bcf	EECON1, CFGS	; point to Flash program memory  
	bsf	EECON1, EEPGD 	; access Flash program memory
	call	ADC_Setup	; setup ADC 
	call	Pad_Setup	; setup keypad entry
	call	Serial_Output_Setup ; setup the serial data tranfer for DAC
	call	Serial_Output2_Setup
	call	Store_Input_Setup;setup code to store mic input
	call	Store_Input_2_Setup
	call    Add_Start       ;setup for adding clips 1 and 2
	goto	start
	
	; ******* Main programme ****************************************
start 	call	MIC_straight_output
	;call    Pad_Check
	bra	start	    
	
	end
