.global _start                // define entry point

result: .space 8

Na: .word 5
Nb: .word 10


_start:
	LDR R0, Na				//Set the value of Na in R0	
	PUSH {LR}
	BL func					//Call the function
	POP {LR}
	LDR R1, =result			//Set the address of R1
	STR R0, [R1]			//Store the result of the first call at result address
	//End of first call
	
	LDR R0, Nb				//Set the value of Nb in R0	
	PUSH {LR}
	BL func					//Call the function
	POP {LR}
	LDR R1, = result		//Set the address of R1
	STR R0,[R1, #4]			//Store the result of the second call at result address
	

//When all instructions are done (all the calls in this case), 
//go to end loop and terminate program
end:
	B end


func:
	MOV R1, #1           //Using R1 to store the result of the calculation
	B loop               //Go to loop branch
loop:
	CMP R0, #2          //If N < 2 
	BLT baseCase        //Go to base case branch   
	MUL R1, R1, R0      // Multiply result with N 
	SUB R0, R0, #1      // N = N-1 (down counter for the loop)
	
	PUSH {LR}
	BL loop              //Go back to loop branch
	POP {LR}
	
	BX LR
baseCase:
	MOV R0, R1          //Store result in R0
	BX LR               //Go back to main to enter end branch

