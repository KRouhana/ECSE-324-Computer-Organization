.global _start

.equ PIXEL_BUFFER, 0xC8000000
.equ CHAR_BUFFER, 0xC9000000
.equ PS2_DATA, 0xff200100



_start:
        bl      input_loop
end:
        b       end





read_PS2_data_ASM:
        
        PUSH {V1-V3, LR}
        
        LDR V1, =PS2_DATA
        LDR V2, [V1]
        LDR V3, =32768          //1000000000000000      to keep the bit we want to read
        
        TST V2, V3
        BNE VALID               
        MOV R0, #0        //if not valid return 0
        POP {V1-V3, LR}
        BX LR
        
         VALID:
                STRB V2, [R0]    //if valid set correct data at location       
                MOV R0, #1       //and return 1           
                POP {V1-V3, LR}
                BX LR






//From function prototype: R0 --> int x, R1 --> int y, R2 --> short c
VGA_draw_point_ASM:

        PUSH {V1,LR}
       
        LDR V1, =PIXEL_BUFFER
        ADD V1, V1, R0, LSL#1
        ADD V1, V1, R1, LSL#10
        STRH R2, [V1]
       
        POP {V1,LR}
        BX LR


VGA_clear_pixelbuff_ASM:
        
        PUSH {LR}

        MOV R2, #0              //reset color
        MOV R1, #0              //reset Y
        
        
                reset_X:
                MOV R0, #0              //reset X

                        clear_all_X:

                        ADD R0, R0, #1
                        CMP R0, #320
                        BLLT VGA_draw_point_ASM
                        BLT clear_all_X


                        clear_all_Y:

                        ADD R1, R1, #1
                        CMP R1, #240
                        BLT reset_X
        POP {LR}
        BX LR


//From function prototype: R0 --> int x, R1 --> int y, R2 --> char c
VGA_write_char_ASM:
        
        PUSH {V1,LR}

        CMP R0, #0                      
        POPLT {V1,LR}
        BXLT LR                         
        CMP R0, #79
        POPGT {V1,LR}
        BXGT LR
        
        CMP R1, #0
        POPLT {V1,LR}
        BXLT LR
        CMP R1, #59
        POPGT {V1,LR}
        BXGT LR

        LDR V1, =CHAR_BUFFER
        ADD V1, V1, R0                  
        ADD V1, V1, R1, LSL #7          
        STRB R2, [V1]                  
        
        POP {V1,LR}
        BX LR


VGA_clear_charbuff_ASM:

 PUSH {LR}

        MOV R2, #0              //reset color
        MOV R1, #0              //reset Y
        
        
                reset_X_CHAR:
                MOV R0, #0              //reset X

                        clear_all_X_CHAR:

                        ADD R0, R0, #1
                        CMP R0, #79
                        BLLT VGA_write_char_ASM
                        BLT clear_all_X_CHAR


                        clear_all_Y_CHAR:

                        ADD R1, R1, #1
                        CMP R1, #59
                        BLT reset_X_CHAR
        POP {LR}
        BX LR



//Given code



write_hex_digit:
        push    {r4, lr}
        cmp     r2, #9
        addhi   r2, r2, #55
        addls   r2, r2, #48
        and     r2, r2, #255
        bl      VGA_write_char_ASM
        pop     {r4, pc}
write_byte:
        push    {r4, r5, r6, lr}
        mov     r5, r0
        mov     r6, r1
        mov     r4, r2
        lsr     r2, r2, #4
        bl      write_hex_digit
        and     r2, r4, #15
        mov     r1, r6
        add     r0, r5, #1
        bl      write_hex_digit
        pop     {r4, r5, r6, pc}
input_loop:
        push    {r4, r5, lr}
        sub     sp, sp, #12
        bl      VGA_clear_pixelbuff_ASM
        bl      VGA_clear_charbuff_ASM
        mov     r4, #0
        mov     r5, r4
        b       .input_loop_L9
.input_loop_L13:
        ldrb    r2, [sp, #7]
        mov     r1, r4
        mov     r0, r5
        bl      write_byte
        add     r5, r5, #3
        cmp     r5, #79
        addgt   r4, r4, #1
        movgt   r5, #0
.input_loop_L8:
        cmp     r4, #59
        bgt     .input_loop_L12
.input_loop_L9:
        add     r0, sp, #7
        bl      read_PS2_data_ASM
        cmp     r0, #0
        beq     .input_loop_L8
        b       .input_loop_L13
.input_loop_L12:
        add     sp, sp, #12
        pop     {r4, r5, pc}
