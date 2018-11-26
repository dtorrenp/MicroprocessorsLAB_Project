# Microprocessors
Repository for Microprocessors Lab project building an Audio Playback device

In order to run the device in speaker mode, uncomment the "MIC_straight_output" call in Simple1, and comment out "Pad_Check"

To record to the first half of the FRAM, hold 1 button on keypad, this is handled by the M_input module
To record to the second half of the FRAM, hold 2 button on keypad, this is handled by the M_input_2 module

To play back the data in the first half of the FRAM, hold 4 button on keypad, this is handled by the M_output module
To play back the data in the second half of the FRAM, hold 5 button on keypad, this is handled by the M_output_2 module

To clear the data in the first half of the FRAM, press 7 button on keypad
To clear the data in the second half of the FRAM, press 8 button on keypad

To layer track two onto track two, press A button on the keypad, this is handled by the add_to module

The pad module register the user input and execute the asssigned function, it also includes the sapling delays used

The ADC module handles reading data in from the ADC to the ADRESH and ADRESL registers
