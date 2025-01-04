.global _start


numbers: .word 68, -22, -31, 75, -10, -61, 39, 92, 94, -55

length: .word 10


_start:

	LDR R0, =numbers		//Get address of array
	LDR R1, length		    //Get length
	
	MOV R2, #0				//start variable
	SUB R3, R1, #1  		//length - 1 --> end variable
	
	PUSH {R0-R3, LR}
	
	BL func					//Call function
	
	POP {R0-R3, LR}
	
end:
	B end
	
func:
	PUSH {R4-LR}
	CMP R2, R3				//start < end 
	
	POPGE {R4-LR}			//Pop what we pushed if we have to exit
	BXGE LR					//If start > = end, Go back to where function was called

	//if start < end
	MOV R4, R2				// set R4 to pivot = start
	MOV R5, R2				// set R5 to i = start
	MOV R6, R3				// set R6 to j = end


startOfWhile:
	CMP R5, R6				//i < j

	BLT whileLoop			//If i < j, go into while loop
	
	//Exit of whileLoop
	PUSH {R0-R5, LR}
	MOV R1, R4				//Setting the input to swap a = pivot
	MOV R2, R6				//Setting the input to swap b = j
	BL swap
	POP {R0-R5, LR}
	
	PUSH {R3, LR}			//Save the old value of R3 (end)
	SUB R3, R6, #1			//new end = j--
	BL func					//recursive call with new end
	POP {R3, LR}			//Get back the old end value
	
	
	ADD R2, R6, #1			// new start = j++
	BL func					//recursive call with new start
	
	POP {R4-LR}				//Pop what we pushed at beggining of function call
	BX LR					//Go back to function call 

whileLoop:

	B while_i					//Go to while i loop

iLessThanj:

	CMP R5, R6				// i < j
	PUSHLT {R0-R6, LR}
	MOVLT R1, R5			//Setting the input to swap a = i
	MOVLT R2, R6			//Setting the input to swap b = j
	BLLT swap				//if i < j swap them
	POPLT {R0-R6, LR}
	
	B startOfWhile			//Go back to start of while

while_i:
	PUSH {R7, R8}
	
	CMP R5, R3				// i < end
		
	POPGE {R7, R8}
	BGE while_j				//If i >= end, go to next while loop
	
	LDR R7, [R0, R5, LSL#2]	// Load array[i] 

	LDR R8, [R0, R4, LSL#2]	// Load array[pivot]
	CMP R7,R8				// array[i] <= array[pivot]
	
	POPGT {R7, R8}
	
	BGT while_j				//If array[i] > array[pivot], go to next while loop
	
	ADD R5, R5, #1			// Else, i++
	POP {R7, R8}
	B while_i				// Stay in while i


while_j:
	PUSH {R7, R8}
	
	LDR R7, [R0, R6, LSL#2]		// Load array[j]
	LDR R8, [R0, R4, LSL#2]		// Load array[pivot]
	CMP R7, R8					// array[j] > array[pivot]
	
	POPLE {R7, R8}
	BLE iLessThanj				// If array[j] <= array[pivot], go to next part of while loop
	
	SUB R6, R6, #1				// Else, j--
	POP {R7, R8}
	B while_j					// Stay in while j


swap:
	
	PUSH {R4}
	LDR R3, [R0, R1, LSL#2] 	// temp1 = array[a]
	LDR R4, [R0, R2, LSL#2]		// temp2 = array[b]
	STR R4, [R0, R1, LSL#2] 	// array[b] = temp1
	STR R3, [R0, R2, LSL#2]		// array[a] = temp2	
	POP {R4}
	
	BX LR						// Go back to where function was called
	
	
	