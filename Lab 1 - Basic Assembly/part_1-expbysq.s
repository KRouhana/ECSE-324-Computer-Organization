.global _start                // define entry point

result: .space 8

Xa: .word 2
Na: .word 10

Xb: .word -5
Nb: .word 5


_start:
	
	LDR R0, Xa				//Set the value of Xa in R0
	LDR R1, Na				//Set the value of Na in R1   

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
	STR R0, [R2, #4]		//Store the result of the second call at result address
	
	
	

//When all instructions are done (2 call of main), 
//go to end loop and terminate program
end:
	B end


func:
	MOV R2, #1		//Using R2 to store the result of the calculation

baseCases:

	CMP R1, #1		//Check if N is 1
	BEQ base		//Go to base case

	CMP R1, #0		//Check if N is 0
	BEQ caseOfZero	//End the program


loop:
	AND R3, R1, #1		//Leave all bits of R1 (N) except the LSB to check if even or odd
	
	//Check if even	and go to even
	CMP R3, #0			
	BEQ evenCase		
	
	//Else, number is odd and go to odd		
	B oddCase



evenCase:
	MUL R0, R0, R0		// X*X	
	LSR R1, R1, #1		// N >> 1
	
	PUSH {LR}
	BL baseCases			//Go back to loop
	POP {LR} 
	BX LR
	
oddCase:
	MUL R2, R2, R0		//result * X
	MUL R0, R0, R0		// X*X
	LSR R1, R1, #1		//N >> 1
	
	PUSH {LR}
	BL baseCases			//Go back to loop
	POP {LR} 
	BX LR


base:				//Final case (n = 1)
	
	MUL R2, R2, R0	//result * X
	MOV R0, R2		//Store result in R0
	BX LR			//Go back

caseOfZero:			//Initial case (n = 0)
	MOV R0, #1		//Set the result to 1 and store it in R0
	BX LR			//Go back
	