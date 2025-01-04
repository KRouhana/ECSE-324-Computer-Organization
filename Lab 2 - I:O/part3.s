

	.equ HEXZeroToThree, 0xFF200020
	.equ HEXFourAndFive, 0xFF200030
	.equ INTERRUPT_STATUS, 0xFFFEC60C
	.equ CONTROL, 0xFFFEC608
	.equ COUNTER, 0xFFFEC604
	.equ LOAD, 0xFFFEC600
	.equ LED,0xFF200000
	.equ SW, 0xFF200040
	.equ PB_DATA, 0xFF200050
	.equ PB_MASK, 0xFF200058
	.equ PB_EDGE, 0xFF20005C

	tim_int_flag: .word 0
	PB_int_flag:  .word 0
	
	digits: .word 0, 0, 0, 0, 0, 0
	TEMP: .space
	
	.section .vectors, "ax"
	B _start
	B SERVICE_UND // undefined instruction vector 
	B SERVICE_SVC // software interrupt vector
	B SERVICE_ABT_INST // aborted prefetch vector
	B SERVICE_ABT_DATA // aborted data vector
	.word 0 // unused vector
	B SERVICE_IRQ // IRQ interrupt vector
	B SERVICE_FIQ // FIQ interrupt vector

.text
.global _start

_start:
    MOV        R1, #0b11010010      // interrupts masked, MODE = IRQ
    MSR        CPSR_c, R1           // change to IRQ mode
    LDR        SP, =0xFFFFFFFF - 3  // set IRQ stack to A9 onchip memory
    MOV        R1, #0b11010011      // interrupts masked, MODE = SVC
    MSR        CPSR, R1             // change to supervisor mode
    LDR        SP, =0x3FFFFFFF - 3  // set SVC stack to top of DDR3 memory
    BL     CONFIG_GIC           // configure the ARM GIC
	
//TODO 

	LDR R0, =#2000000			// Start by configuring the ARM Timer with a load
	BL ARM_TIM_config_ASM
	BL enable_PB_INT_ASM		// Also enable the Interrupt of the PB
	
	BL reset_all 
	
//End TODO

	LDR        R0, =0xFF200050 
    MOV        R1, #0xF            
    STR        R1, [R0, #0x8]       
    MOV        R0, #0b01010011      
    MSR        CPSR_c, R0


Wait:						
  LDR R0, =PB_int_flag
  LDR R1, [R0]
  TST R1, #1
  BEQ Wait
  BNE IDLE
 



IDLE:   
 

 
 
  LDR R0, =tim_int_flag			  // I continuously check if the tim_int_flag is not 0
  LDR R1, [R0]
  TST R1, #1
  BLNE StopWatch

  LDR R0, =PB_int_flag			   // And if the PB_int_flag is not 0
  LDR R1, [R0]
  CMP R1, #0
  BEQ IDLE	
    
  LDR R0, =PB_int_flag			   // As soon as it is not 0 anymore, we check which button was pressed
  LDR R1, [R0]
  
  TST R1, #1					   // If it is PB0, then we shall Resume the Timer
  BLNE RESUME
  
  TST R1, #2					   // If it is PB1, then we shall Stop the Timer
  BLNE STOP
  
  TST R1, #4					   // If it is PB2, then we shall Reset the Timer
  BLNE RESET
  
  
  B IDLE 




						


enable_PB_INT_ASM:   		// R0 contains which button to enable interupt mask
	
	PUSH {V1-V2}
	LDR V1, =PB_MASK
	AND V2, R0, #0xF			  // R2 = 4 LSB of Edge Register -> by doing AND(Edge, 00…0001111)
	STR V2, [V1]				  // store it back into location to enable interrupt
	POP {V1-V2}
	BX LR


ARM_TIM_ISR:				


// If this subroutine is called, then we need to sore 1 in tim int flag
	PUSH {V1-V2}
	LDR V1, =tim_int_flag
	MOV V2, #1
	STR V2, [V1]				// We store in tim_int_flag '1' to say that there is an interrupt
	
	LDR V1, =INTERRUPT_STATUS
	STR V2, [V1]				// And we set F back to 0

	POP {V1-V2}
	BX LR

KEY_ISR:					

	
	PUSH {V1-V2}
	LDR V1, =PB_EDGE
	LDR V2, [V1]
	STR V2, [V1]
	
	LDR V1, =PB_int_flag
	STR V2, [V1]
	
	POP {V1-V2}
	
	BX LR
	
	
	
/*********************************************************

Here are the subroutines for the ARM Timer

**********************************************************/	
	
ARM_TIM_read_INT_ASM:
	
	PUSH {V1}
	LDR V1, =INTERRUPT_STATUS
	LDR R0, [V1]						//Load byte of status
	AND R0, R0, #0x1				  // get the last bit
	POP {V1}
	BX LR
	
	
	
ARM_TIM_config_ASM:
	PUSH {R0, V1-V2}
	
	
	// 1- Load
	LDR V1, =LOAD
	STR R0, [V1]			// moved the Load into the Load register
	
	// 2.1- Enabler 
	LDR V1, =CONTROL
	LDR V2, [V1]
	AND V2, V2, #0xFFFFFF8 	// clearing the last bit to be able to set it to 1, no matter what it was
	ORR V2, V2, #0x7		// to store a 1 into A, I & E
	STR V2, [V1]			// store it back to Control Register
	
	POP {R0, V1-V2}
	BX LR
	





StopWatch:						
	
	PUSH {R1-LR}
	
	LDR R0, =tim_int_flag
  	MOV R1, #0
  	STR R1, [R0]

	// I start by loading back all the values from memory
	LDR V1, =digits				
	LDR V2, [V1]
	LDR V3, [V1, #4]
	LDR V4, [V1, #8]
	LDR V5, [V1, #12]
	LDR V6, [V1, #16]	
	LDR V7, [V1, #20]

	ADD V2, V2, #1				// Add 1 to the first digit
	CMP V2, #10					// And check if V2 (HEX0) reaches 10, 
	ADDEQ V3, V3, #1			// In which case, V3 (HEX1) is incremented by 1
	MOVEQ V2, #0				// Restart the millisecs if we need to
	
	MOV R1, V2					//Update the value of R1 with the value we need to show on the display
	MOV R0, #0					//We then update HEX 0
	PUSH {LR}
	BL HEX_write_ASM			//By calling the function
	POP {LR}
	
	CMP V3, #10					//Check if V3 has reached 10 
	MOVEQ V3, #0				//If it has, restart the unit seconds
	ADDEQ V4, #1				//In which case V4 (HEX2) is incremented by 1 (represents the 10 secs)
	
	MOV R1, V3					// And update HEX1 with the counter value
	MOV R0, #1					//Hex 1 index
	PUSH {LR}
	BL HEX_write_ASM
	POP {LR}

								// We do the exact same thing for the remaining digits,
	CMP V4, #10					//If we have reached 10 secs
	MOVEQ V4, #0				//reset
	ADDEQ V5, #1				//and add 1 to the "dizaine"
	
	MOV R1, V4					//Get the number we want to show
	MOV R0, #2					//The index of hex we want to update
	PUSH {LR}
	BL HEX_write_ASM
	POP {LR}
		
	
	CMP V5, #6				//If we have reached 60 seconds
	MOVEQ V5, #0			//reset
	ADDEQ V6, #1			//Add 1 minute
	
	MOV R1, V5				//Get the value we want to show
	MOV R0, #4				//get the hex index we want to update
	PUSH {LR}
	BL HEX_write_ASM
	POP {LR}


	CMP V6, #10				//If we have reached 10 mins
	MOVEQ V6, #0			//Reset the mins
	ADDEQ V7, #1			//Add 1 to the dizaines
	
	MOV R1, V6				//Get the value we need to update
	MOV R0, #8				//Get the hex index value 
	PUSH {LR}
	BL HEX_write_ASM
	POP {LR}


	CMP V7, #6				//Check if we're at 60 mins
	MOVEQ V7, #0			//Reset
	ADDEQ V8, #1			//Add 1 h
	
	MOV R1, V7				//Get the value we need
	MOV R0, #16				//Get the index of HEX we need
	PUSH {LR}
	BL HEX_write_ASM		//Write the HEX
	POP {LR}
	



	// Finally, we store back the updated valued into the memory
	LDR V1, =digits					
	STR V2, [V1]
	STR V3, [V1, #4]
	STR V4, [V1, #8]
	STR V5, [V1, #12]
	STR V6, [V1, #16]	
	STR V7, [V1, #20]

	POP {R1-LR}
	BX LR
	

RESUME:

	
	PUSH {V1-V2}
	LDR V1, =PB_int_flag		//clearing the int PB
	MOV V2, #0
	STR V2, [V1]
	POP {V1-V2}
	
	PUSH {V1-V2}
	
	// enabling it back
	// Then, enable back the timer that was disabled by the Stop subroutine
	// set E=1 to resume the counter	
	LDR V1, =CONTROL			// Then, disable the timer by setting E to 0
	
	// set E=0 to stop the counter	
	MOV V2, #0x7
	STR V2, [V1]

	POP {V1-V2}

	BX LR

	
	
	
							
RESET:
	
	PUSH {V1-V2}
	LDR V1, =PB_int_flag		//clearing the int PB
	MOV V2, #0
	STR V2, [V1]
	POP {V1-V2}
	
	
	
	PUSH {V1-V2}
	
	// enabling it back
	// Then, enable back the timer that was disabled by the Stop subroutine
	// set E=1 to resume the counter	
	LDR V1, =CONTROL			// Then, disable the timer by setting E to 0
	 // set E=0 to stop the counter	
	MOV V2, #0x3
	STR V2, [V1]

	POP {V1-V2}
	

	
	PUSH {V1-V2,LR}

	LDR V1, =digits				// Then, load all the digits of the timer from memory and store 0 in them
	MOV V2, #0
	STR V2, [V1]
	STR V2, [V1, #4]
	STR V2, [V1, #8]
	STR V2, [V1, #12]
	STR V2, [V1, #16]	
	STR V2, [V1, #20]

	PUSH {LR}
	BL reset_all				// And also, set all the HEX display to 0's
	POP {LR}
	
	POP {V1-V2, LR}
	
	
	BX LR
	


reset_all:					   // Reset all HEX Display to 0's
	PUSH {R0, R1, LR}
	MOV R0, #0xFF				// Set R0 to be 111111 so that all HEX are cleared
	MOV R1, #0
	BL HEX_write_ASM
	POP {R0, R1, LR}
	BX LR




STOP:						
	

	PUSH {V1-V2}
	LDR V1, =PB_int_flag		//clearing the int PB
	MOV V2, #0
	STR V2, [V1]
	POP {V1-V2}

	PUSH {V1-V2}

	// disabling it
	LDR V1, =CONTROL			
	// Then, disable the timer by setting E to 0
	
	// set E=0 to stop the counter	
	LDR V2, [V1]
	AND V2, V2, #0xFFFFFFFE 	// set E=0 to stop the counter
	STR V2, [V1]

	POP {V1-V2}

	BX LR

SERVICE_UND:
    B SERVICE_UND
SERVICE_SVC:
    B SERVICE_SVC
SERVICE_ABT_DATA:
    B SERVICE_ABT_DATA
SERVICE_ABT_INST:
    B SERVICE_ABT_INST


SERVICE_IRQ:
    PUSH {R0-R7, LR}
    LDR R4, =0xFFFEC100
    LDR R5, [R4, #0x0C] 
						// checking which interrupt it is
	CMP R5, #73		 	// I compare to 73, 
	CMPNE R5, #29		// Then 29 if it is not the former 

UNEXPECTED:				
    BNE UNEXPECTED		// If it is none of the above, then we got something unexpected, and we go into an infinite loop
	
	CMP R5, #73			// I then recheck to see which ISR to call
	BLEQ KEY_ISR
	
	CMP R5, #29
	BLEQ ARM_TIM_ISR

EXIT_IRQ:
    STR R5, [R4, #0x10] // write to ICCEOIR
    POP {R0-R7, LR}
	SUBS PC, LR, #4
SERVICE_FIQ:
    B SERVICE_FIQ	
		
CONFIG_GIC:
    PUSH {LR}

    MOV R0, #73            // KEY port (Interrupt ID = 73)
    MOV R1, #1             // this field is a bit-mask; bit 0 targets cpu0
    BL CONFIG_INTERRUPT
	
	MOV R0, #29				// ARM Timer (Interrupt ID = 29)
	MOV R1, #1
	BL CONFIG_INTERRUPT


    LDR R0, =0xFFFEC100   
    LDR R1, =0xFFFF        
    STR R1, [R0, #0x04]
    MOV R1, #1
    STR R1, [R0]
    LDR R0, =0xFFFED000
    STR R1, [R0]
    POP {PC}

CONFIG_INTERRUPT:
    PUSH {R4-R5, LR}
    LSR R4, R0, #3    // calculate reg_offset
    BIC R4, R4, #3    // R4 = reg_offset
    LDR R2, =0xFFFED100
    ADD R4, R2, R4    // R4 = address of ICDISER
    AND R2, R0, #0x1F // N mod 32
    MOV R5, #1        // enable
    LSL R2, R5, R2    // R2 = value
    LDR R3, [R4]      // read current register value
    ORR R3, R3, R2    // set the enable bit
    STR R3, [R4]      // store the new register value
    BIC R4, R0, #3    // R4 = reg_offset
    LDR R2, =0xFFFED800
    ADD R4, R2, R4    // R4 = word address of ICDIPTR
    AND R2, R0, #0x3  // N mod 4
    ADD R4, R2, R4    // R4 = byte address in ICDIPTR
    STRB R1, [R4]
    POP {R4-R5, PC}
	

	



	
	
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

								B IDLE					// If none of these are the value of R1, we just go back to the main loop until we gave a value that is acceptable

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

	
	
	