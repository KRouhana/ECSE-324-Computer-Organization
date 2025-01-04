.equ HEXZeroToThree, 0xFF200020
.equ HEXFourAndFive, 0xFF200030

.equ SW_ADDR, 0xFF200040 
.equ LED_ADDR, 0xFF200000
.equ PB_DATA, 0xFF200050
.equ PB_MASK, 0xFF200058
.equ PB_EDGE, 0xFF20005C

TEMP: .SPACE

.global _start
_start:
	
	
	MOV R0, #0b111111				// I first start by clearing all the HEX displays and the edgecap bits
	BL HEX_clear_ASM
	BL PB_clear_edgecp_ASM
	
	
Loop:
	
	
	PUSH {R1}	
	BL read_slider_switches_ASM 	// I start by reading the values of the switches SW
	POP {R1}
	MOV R1, R0						// And move the value stored into R1
	
	PUSH {R1}
	BL write_LEDs_ASM				// I turn ON the appropriate LEDs
	POP {R1}
	
	PUSH {R1}
	BL read_slider_switches_ASM		// I check if SW9 is no ON 
	POP {R1}
	
	TST R0, #0b1000000000			// If it is, we go to this subroutine
	BLNE Nine_Pressed

	
	BL read_PB_edgecp_ASM			// Then, I read which pushbuttons PB were pressed 

	BL HEX_write_ASM				// And turn ON the appropriate displays with the appropriate value

	BL PB_clear_edgecp_ASM			// Without forgetting to clear the edgecaps so I don't read the same thing twice
	
	MOV R0, #0x30					// Finally, I flood HEX4 & HEX5
	BL HEX_flood_ASM
		
	
	
	B Loop							// And I come back to the beginning of the loop

	
	
	
HEX_clear_ASM:

	//have to check which bits to work on
	check_index_CLEAR:		
		PUSH {R4-LR}			
		MOV V1, #1			//Counter for the 1 hot encoding, it will be shifted left
		MOV V2, #0			//Counter to check if we need to go to the next HEX displays value (will go up to 32)
		
		
		loop_check_index_CLEAR:
			TST R0, V1		//Since R0 has the HEX display index, we check the one hot encoding with the counter
			PUSH {LR}
			BLNE check_which_HEX_to_clear		//If AND(R0,V1) == 1, then we need to change the HEX display index
			POP {LR}							//Else, continue the loop by incrementing the counters
			LSL V1, #1		//Left shift, (x2) 					
			ADD V2, V2, #8	//Move to the next HEX index, +8 because we have 32 bits and each address is 8 bits
			CMP V1, #64		//If we still have not checked all the indices, stay in loop (64 is 2^6, and we have 6 displays)
			BNE loop_check_index_CLEAR
		
		POP {R4-LR}
		BX LR
	
			check_which_HEX_to_clear:
				CMP V2, #31				//If the counter is greater than 32, then we are at HEX4-5
				BLE clear_HEXZeroToThree
				B   clear_HEXFourAndFive
				
					
					clear_HEXZeroToThree:
						PUSH {V1-V4,LR}
						LDR R1, =HEXZeroToThree		//Load the corresponding address
						LDR V3, [R1]				//Load the value at the HEX displays
						ROR V3, V3, V2				//I rotate the value at the HEX by V2 bits, which is the counter of the index of the bits
													//  so now the 8 LSBs are the one we want to change
						AND V3, V3, #0xFFFFFF00		//I now clear them by AND(V3, 11...1 00000000)	
						NEG V4, V2					//I will need to rotate back the bits, and since there's only 1 rotate instruction, 
													//  I have to get the negative value of the index of the hex we're working at
						ROR V3, V3, V4				//I now rotate back to where the bits need to be
						LDR V4, [R1]				//I reload the correct value of The Hex
						AND V4, V4, V3				//And I and it with my cleared bits
						STR V4, [R1]				//Store it back at the address
						POP {V1-V4, LR}
						BX LR
						
					clear_HEXFourAndFive:
						PUSH {V1-V4, LR}
						LDR R1, =HEXFourAndFive		//Load the corresponding address
						LDR V3, [R1]				//Load the value at the HEX displays
						SUB V2, V2, #32				//I sub the counter by 32 to get the correct position of the index
						ROR V3, V3, V2				//I rotate the value at the HEX by V2 bits, which is the counter of the index of the bits
													//  so now the 8 LSBs are the one we want to change
						AND V3, V3, #0xFFFFFF00		//I now clear them by AND(V3, 11...1100000000)	
						NEG V4, V2					//I will need to rotate back the bits, and since there's only 1 rotate instruction, 
													//  I have to get the negative value of the index of the hex we're working at
						ROR V3, V3, V4				//I now rotate back to where the bits need to be
						LDR V4, [R1]				//I reload the correct value of The Hex
						AND V4, V4, V3				//And I and it with my cleared bits
						STR V4, [R1]				//Store it back at the address
						POP {V1-V4, LR}
						BX LR
	
	
	


HEX_flood_ASM:				// This subroutine has the exact same logic as HEX_clear_ASM, but instead of just clearing them, we also flood them after
	
	
		check_flood_index:			// We also find the indexes that we need to flood exaclty the same way we did for HEX_clear_ASM
		
		PUSH {R4-LR}
		MOV V1, #1			//Counter for the 1 hot encoding, it will be shifted left
		MOV V2, #0			//Counter to check if we need to go to the next HEX displays value (will go up to 32)
		
		loop_check_index_FLOOD:
			TST R0, V1		//Since R0 has the HEX display index, we check the one hot encoding with the counter
			PUSH {LR}
			BLNE check_which_HEX_to_flood		//If AND(R0,V1) == 1, then we need to change the HEX display index
			POP {LR}							//Else, continue the loop by incrementing the counters
			LSL V1, #1							//Left shift, (x2) 					
			ADD V2, V2, #8						//Move to the next HEX index, +8 because we have 32 bits and each address is 8 bits
			CMP V1, #64							//If we still have not checked all the indices, stay in loop (64 is 2^6, and we have 6 displays)
			BNE loop_check_index_FLOOD
		
		POP {R4-LR}
		BX LR 

				check_which_HEX_to_flood:
				CMP V2, #31						//If the counter is greater than 31, then we are at HEX4-5
				BLE flood_HEXZeroToThree
				B   flood_HEXFourAndFive
				



	flood_HEXZeroToThree:
		PUSH {R1-LR}
		LDR R1, =HEXZeroToThree			//Load the corresponding address
		LDR V3, [R1]					//Load the value at the HEX displays
		ROR V3, V3, V2					//I rotate the value at the HEX by V2 bits, which is the counter of the index of the bits
										//  so now the 8 LSBs are the one we want to change
		
		AND V3, V3, #0xFFFFFF00			// Clear the bits just like we did in HEX_clear_ASM, but now we also write on them
		NEG V4, V2						//I will need to rotate back the bits, and since there's only 1 rotate instruction, 
										//  I have to get the negative value of the index of the hex we're working at
		
		ROR V3, V3, V4					//I now rotate back to where the bits need to be
		LDR V4, [R1]					//I reload the correct value of The HEX
		
		AND V4, V4, V3					// Now that V4 has a vacant 8 bits, the one we want to change
		LDR V3, =0x7F					// We will fill them up with a full HEX display (0x7F is the 8 on the display)
		LSL V3, V2						// By moving 0x7F to the right placement due to shifting by the right index
		EOR V4, V4, V3					// OR(R2, R6) since R2 has a 'vacancy' where we need to place the bits
		STR V4, [R1]					// Store the modified bits of the HEX back to their address
		POP {R1-LR}
		BX LR
	
	flood_HEXFourAndFive:						// Same logic, we just need to subtract R3 by 32
		PUSH {R1-LR}
		LDR R1, =HEXFourAndFive			//Load the corresponding address
		LDR V3, [R1]					//Load the value at the HEX displays
		
		SUB V2, V2, #32					//I sub the counter by 32 to get the correct position of the index
		
		ROR V3, V3, V2					//I rotate the value at the HEX by V2 bits, which is the counter of the index of the bits
										//  so now the 8 LSBs are the one we want to change
		
		AND V3, V3, #0xFFFFFF00			// Clear the bits just like we did in HEX_clear_ASM, but now we also write on them
		NEG V4, V2						//I will need to rotate back the bits, and since there's only 1 rotate instruction, 
										//  I have to get the negative value of the index of the hex we're working at
										
		ROR V3, V3, V4					//I now rotate back to where the bits need to be
		LDR V4, [R1]					//I reload the correct value of The HEX
		
		AND V4, V4, V3					// Now that V4 has a vacant 8 bits, the one we want to change
		LDR V3, =0x7F					// We will fill them up with a full HEX display (0x7F is the 8 on the display)
		LSL V3, V2						// By moving 0x7F to the right placement due to shifting by the right index
		EOR V4, V4, V3					// OR(R2, R6) since R2 has a 'vacancy' where we need to place the bits
		STR V4, [R1]					// Store the modified bits of the HEX back to their address
		POP {R1-LR}
		BX LR




HEX_write_ASM:
	
	//have to check which bits to work on
	check_index_WRITE:
		PUSH {R4-LR}
		MOV V1, #1		//Counter for the 1 hot encoding, it will be shifted left
		MOV V2, #0		//Counter to check if we need to go to the next HEX displays value (will go up to 32)
		
		loop_check_index_WRITE:
			TST R0, V1						//Since R0 has the HEX display index, we check the one hot encoding with the counter
			PUSH {LR}
			BLNE check_which_HEX_to_write	//If AND(R0,V1) == 1, then we need to change the HEX display index
			POP {LR}						//Else, continue the loop by incrementing the counters
			LSL V1, #1						//Left shift, (x2) 					
			ADD V2, V2, #8					//Move to the next HEX index, +8 because we have 32 bits and each address is 8 bits
			CMP V1, #64						//If we still have not checked all the indices, stay in loop (64 is 2^6, and we have 6 displays)
			BNE loop_check_index_WRITE
		
		POP {R4-LR}
		BX LR
	
			check_which_HEX_to_write:
				CMP V2, #31					//If the counter is greater than 32, then we are at HEX4-5
				BLE write_HEXZeroToThree
				B   write_HEXFourAndFive
				
					
					write_HEXZeroToThree:
						PUSH {V2-V6, LR}
						LDR V5, =TEMP		// We use this Temp memory space to store the bit combination that we have found in the subroutine find_number
						PUSH {R1,LR}
						BL find_which_number		//Get the correct number we want to write using the value passed in R1
						POP {R1,LR}
						
						
						LDR V6, =HEXZeroToThree		//Load the corresponding address
						LDR V3, [V6]				//Load the value at the HEX displays
						ROR V3, V3, V2				//I rotate the value at the HEX by V2 bits, which is the counter of the index of the bits
													//  so now the 8 LSBs are the one we want to change
						AND V3, V3, #0xFFFFFF00		//I now clear them by AND(V3, 11...1 00000000)	
						NEG V4, V2					//I will need to rotate back the bits, and since there's only 1 rotate instruction, 
													//  I have to get the negative value of the index of the hex we're working at
						
						ROR V3, V3, V4				//I now rotate back to where the bits need to be
						LDR V4, [V6]				//I reload the correct value of The Hex
						AND V4, V4, V3				//And I AND it with my cleared bits, now V4 has 8 empty bits we need to fill
						
						LDR V3, [V5]				// We load the bit value that we have found from the find_number subroutine
						
						LSL V3, V2					// Moving the right placement due to shifting by the right index
						EOR V4, V4, V3				// OR(V3, V4) since V4 has a vacancy where we need to place the bits
						STR V4, [V6]				// Store the result in the HEX address
						
						POP {V2-V6, LR}
						BX LR
						
					write_HEXFourAndFive:
						PUSH {V2-V6, LR}
						LDR V5, =TEMP		// We use this Temp memory space to store the bit combination that we have found in the subroutine find_number
						PUSH {R1,LR}
						BL find_which_number		//Get the correct number we want to write using the value passed in R1
						POP {R1,LR}
						
						
						LDR V6, =HEXFourAndFive		//Load the corresponding address
						LDR V3, [V6]				//Load the value at the HEX displays
						SUB V2, V2, #32
						ROR V3, V3, V2				//I rotate the value at the HEX by V2 bits, which is the counter of the index of the bits
													//  so now the 8 LSBs are the one we want to change
						AND V3, V3, #0xFFFFFF00		//I now clear them by AND(V3, 11...1 00000000)	
						NEG V4, V2					//I will need to rotate back the bits, and since there's only 1 rotate instruction, 
													//  I have to get the negative value of the index of the hex we're working at
						
						ROR V3, V3, V4				//I now rotate back to where the bits need to be
						LDR V4, [V6]				//I reload the correct value of The Hex
						AND V4, V4, V3				//And I AND it with my cleared bits, now V4 has 8 empty bits we need to fill
						
						LDR V3, [V5]				// We load the bit value that we have found from the find_number subroutine
						
						LSL V3, V2					// Moving the right placement due to shifting by the right index
						EOR V4, V4, V3				// OR(V3, V4) since V4 has a vacancy where we need to place the bits
						STR V4, [V6]				// Store the result in the HEX address
						
						POP {V2-V6, LR}
						BX LR
						
						
							find_which_number:
								CMP R1, #0
								BEQ Zero
								CMP R1, #1
								BEQ One
								CMP R1, #2
								BEQ Two
								CMP R1, #3
								BEQ Three
								CMP R1, #4
								BEQ Four
								CMP R1, #5
								BEQ Five
								CMP R1, #6
								BEQ Six
								CMP R1, #7
								BEQ Seven
								CMP R1, #8
								BEQ Eight
								CMP R1, #9
								BEQ Nine
								CMP R1, #10
								BEQ Ten
								CMP R1, #11
								BEQ Eleven
								CMP R1, #12
								BEQ Twelve
								CMP R1, #13
								BEQ Thirteen
								CMP R1, #14
								BEQ Fourteen
								CMP R1, #15
								BEQ Fifteen

								B Loop					// If none of these are the value of R1, we just go back to the main loop until we gave a value that is acceptable

								Zero:					// Depending on the value of R1, we get to the appropriate subroutine, which will store the specific bit combination into the R0 temporary space
								LDR R1, =0x3F			// then go back to the HEX_write_ASM to use these bits and input them into the HEX Displays
								STR R1, [V5]
								BX LR

								One:
								LDR R1, =0x06
								STR R1, [V5]
								BX LR

								Two:
								LDR R1, =0x5B
								STR R1, [V5]
								BX LR

								Three:
								LDR R1, =0x4F
								STR R1, [V5]
								BX LR

								Four:
								LDR R1, =0x66
								STR R1, [V5]
								BX LR

								Five:
								LDR R1, =0x6D
								STR R1, [V5]
								BX LR

								Six:
								LDR R1, =0x7D
								STR R1, [V5]
								BX LR

								Seven:
								LDR R1, =0x7
								STR R1, [V5]
								BX LR

								Eight:
								LDR R1, =0x7F
								STR R1, [V5]
								BX LR

								Nine:
								LDR R1, =0x6F
								STR R1, [V5]
								BX LR

								Ten:
								LDR R1, =0x77
								STR R1, [V5]
								BX LR

								Eleven:
								LDR R1, =0x7C
								STR R1, [V5]
								BX LR

								Twelve:
								LDR R1, =0x39
								STR R1, [V5]
								BX LR

								Thirteen:
								LDR R1, =0x5E
								STR R1, [V5]
								BX LR

								Fourteen:
								LDR R1, =0x79
								STR R1, [V5]
								BX LR

								Fifteen:
								LDR R1, =0x71
								STR R1, [V5]
								BX LR




read_PB_data_ASM:					// We access the Data Register of the PB
	PUSH {R3}
	LDR R3, =PB_DATA				  
	LDR R0, [R3]				      // And load their value into R0 
	POP {R3}
	BX LR


PB_data_is_pressed_ASM:	 // Check if the index of the PB in R0 is ON 
							  // R0 contains the one-hot encoding of the PB that we want to check 
	PUSH {R2-R3}
	LDR R3, =PB_DATA	
	LDR R2, [R3]				      // So, we load the value of the data register
	AND R2, R2, R0                    // And AND it with R0, to see if it is '0' or '1'
	CMP R2, R0
	MOVEQ R0, #1				      // If PB_i is pressed, R0 = 1
	MOVNE R0, #0				      // If PB_i is not, R0 = 0 
	POP {R2-R3}
	BX LR


read_PB_edgecp_ASM:		  // Return the value of the edge-capture register
	PUSH {R3}
	LDR R3, =PB_EDGE	
	LDR R0, [R3]		  			  // Load its value into R0
	AND R0, R0, #0xF			   	  // R0 = 4 LSB of Edge Register -> by doing AND(Edge, 00…0001111)
	POP {R3}
	BX LR							


PB_edgecp_is_pressed_ASM:	// Check if the edgecap bit of the PB specified in R0 is '1'
	PUSH {R2-R3}
	LDR R3, =PB_EDGE	
	LDR R2, [R3]				      // Load its value  
	AND R2, R2, R0                    // AND it with R0
	CMP R2, R0
	MOVEQ R0, #1				      // If index was pressed, R0 = 1
	MOVNE R0, #0				      // If not, R0 = 0
	POP {R2-R3}
	BX LR


PB_clear_edgecp_ASM:		// Set all bits of Edge Register to 0 by storing any number in it		        
	PUSH {R2-R3}
	LDR R3, =PB_EDGE	     
	LDR R2, [R3]
	STR R2, [R3]
	POP {R2-R3}
	BX LR


enable_PB_INT_ASM:   		// R0 contains which button to enable interupt mask
	PUSH {R2-R3}
	LDR R3, =PB_MASK
	AND R2, R0, #0xF			   	  // R2 = 4 LSB of Edge Register -> by doing AND(Edge, 00…0001111)
	STR R2, [R3]				  	  // store it back into location to enable interrupt
	POP {R2-R3}
	BX LR


disable_PB_INT_ASM:			// R0 contains which button to disable interupt mask
	PUSH {R2-R3}
	LDR R3, =PB_MASK
	LDR R2, [R3]				  
	BIC R2, R2, R0				  	  //AND on the complement of R0 to disable the button you need, since R0 will be 1 at the button you need
	STR R2, [R3]				      //store it back into the mask
	POP {R2-R3}
	BX LR




// Slider Switches Driver
// returns the state of slider switches in R0 
// post- A1: slide switch state
read_slider_switches_ASM:
LDR A2, =SW_ADDR 	// load the address of slider switch state
LDR A1, [A2]		// read slider switch state
BX LR

// LEDs Driver
// writes the state of LEDs (On/Off state) in A1 to the LEDs’ memory location
// pre-- A1: data to write to LED state
write_LEDs_ASM:

LDR A2, =LED_ADDR 	// load the address of the LEDs’ state
STR A1, [A2] 		// update LED state with the contents of A1 

BX LR


Nine_Pressed:						// In the case SW9 is pressed
	PUSH {R0, R1, LR}
	MOV R0, #0b1111				 	// I clear the HEX displays by passing 1111 to R0 before going into HEX_clear_ASM
	PUSH {R0, R1, LR}
	BL HEX_clear_ASM
	POP {R0, R1, LR}
	
	PUSH {R1, LR}
	BL read_slider_switches_ASM		// I then check back the values of the SW to see if SW9 is still ON
	POP {R1, LR}	
	TST R0, #0b1000000000			// If this instruction results in a '1', then SW9 is still ON, and we need to be kept in this loop

	POP {R0, R1, LR}
	PUSHEQ {LR}
	BLEQ PB_clear_edgecp_ASM		// Clear edgecap if we get out 
	POPEQ {LR}
	BXEQ LR							// We get out only if AND(R0, #0b1000000000) = 0
	BNE Nine_Pressed






