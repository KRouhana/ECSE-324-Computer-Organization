.global _start                // define entry point

result: .space 8

Xa: .word 1
Na: .word 0

Xb: .word -5
Nb: .word 5



_start:
	
	LDR R0, Xa				//Set the value of Xa in R0
	LDR R1, Na      		//Set the value of Na in R1     
	
	PUSH {LR}
	BL func					//Call the function
	POP {LR}
	
	LDR R2, =result			//Set the address of R2
	STR R0, [R2]			//Store the result of the first call at result address
	//End of first call
	
	LDR R0, Xb				//Set the value of Xb in R0
	LDR R1, Nb				//Set the value of Nb in R1
	
	PUSH {LR}
	BL func					//Call the function
	POP {LR}
	
	LDR R2, =result			//Set the address of R2
	STR R0, [R2,#4]			//Store the result of the second call at result address
	
	
	
	
//When all instructions are done (all the calls in this case), 
//go to end loop and terminate program
end:
	B end


func: 
	MOV R2, #1         //Using R2 to store the result of the calculation
	
	
	
loop:
    CMP R1, #0   		//Check if N is 0
    BGT calculation   	//If N > 0 continue to calculate by going to branch
    
	//When N = 0 the instructions will break 
	//out of the loop and store the value

    MOV R0, R2     		// Store return value in R0 (as per manual)
    BX LR 		   		// Go back to main to enter end branch

calculation:
	SUB R1, R1, #1		// N = N-1 (down counter for the loop)
	MUL R2, R2, R0      // Multiply result with X 
	
	PUSH {LR}
	BL loop				//Go back to loop branch
	POP {LR}
	BX LR