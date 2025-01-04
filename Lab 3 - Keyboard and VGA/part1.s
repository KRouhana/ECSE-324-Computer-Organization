.global _start

.equ PIXEL_BUFFER, 0xC8000000
.equ CHAR_BUFFER, 0xC9000000




_start:
        bl      draw_test_screen
end:
        b       end


//From function prototype: R0 --> int x, R1 --> int y, R2 --> short c
VGA_draw_point_ASM:

        PUSH {V1,LR}
       
        LDR V1, =PIXEL_BUFFER
        ADD V1, V1, R0, LSL#1                   //Set correct X location
        ADD V1, V1, R1, LSL#10                  //Set correct Y location
        STRH R2, [V1]                           //Set the color
       
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
                        CMP R0, #320                    //Check if all x have been reset
                        BLLT VGA_draw_point_ASM
                        BLT clear_all_X

                        //If yes, increment y and start over
                        clear_all_Y:

                        ADD R1, R1, #1
                        CMP R1, #240
                        BLT reset_X
        POP {LR}
        BX LR


//From function prototype: R0 --> int x, R1 --> int y, R2 --> char c
VGA_write_char_ASM:
        
        PUSH {V1,LR}

        //Check conditions before proceeding

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
        ADD V1, V1, R0                          //Set correct X             
        ADD V1, V1, R1, LSL #7                  //Set correct Y 
        STRB R2, [V1]                           //Set correct ascii
        
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




//PROVIDED CODE




draw_test_screen:
        push    {r4, r5, r6, r7, r8, r9, r10, lr}
        bl      VGA_clear_pixelbuff_ASM
        bl      VGA_clear_charbuff_ASM
        mov     r6, #0
        ldr     r10, .draw_test_screen_L8
        ldr     r9, .draw_test_screen_L8+4
        ldr     r8, .draw_test_screen_L8+8
        b       .draw_test_screen_L2
.draw_test_screen_L7:
        add     r6, r6, #1
        cmp     r6, #320
        beq     .draw_test_screen_L4
.draw_test_screen_L2:
        smull   r3, r7, r10, r6
        asr     r3, r6, #31
        rsb     r7, r3, r7, asr #2
        lsl     r7, r7, #5
        lsl     r5, r6, #5
        mov     r4, #0
.draw_test_screen_L3:
        smull   r3, r2, r9, r5
        add     r3, r2, r5
        asr     r2, r5, #31
        rsb     r2, r2, r3, asr #9
        orr     r2, r7, r2, lsl #11
        lsl     r3, r4, #5
        smull   r0, r1, r8, r3
        add     r1, r1, r3
        asr     r3, r3, #31
        rsb     r3, r3, r1, asr #7
        orr     r2, r2, r3
        mov     r1, r4
        mov     r0, r6
        bl      VGA_draw_point_ASM
        add     r4, r4, #1
        add     r5, r5, #32
        cmp     r4, #240
        bne     .draw_test_screen_L3
        b       .draw_test_screen_L7
.draw_test_screen_L4:
        mov     r2, #72
        mov     r1, #5
        mov     r0, #20
        bl      VGA_write_char_ASM
        mov     r2, #101
        mov     r1, #5
        mov     r0, #21
        bl      VGA_write_char_ASM
        mov     r2, #108
        mov     r1, #5
        mov     r0, #22
        bl      VGA_write_char_ASM
        mov     r2, #108
        mov     r1, #5
        mov     r0, #23
        bl      VGA_write_char_ASM
        mov     r2, #111
        mov     r1, #5
        mov     r0, #24
        bl      VGA_write_char_ASM
        mov     r2, #32
        mov     r1, #5
        mov     r0, #25
        bl      VGA_write_char_ASM
        mov     r2, #87
        mov     r1, #5
        mov     r0, #26
        bl      VGA_write_char_ASM
        mov     r2, #111
        mov     r1, #5
        mov     r0, #27
        bl      VGA_write_char_ASM
        mov     r2, #114
        mov     r1, #5
        mov     r0, #28
        bl      VGA_write_char_ASM
        mov     r2, #108
        mov     r1, #5
        mov     r0, #29
        bl      VGA_write_char_ASM
        mov     r2, #100
        mov     r1, #5
        mov     r0, #30
        bl      VGA_write_char_ASM
        mov     r2, #33
        mov     r1, #5
        mov     r0, #31
        bl      VGA_write_char_ASM
        pop     {r4, r5, r6, r7, r8, r9, r10, pc}
.draw_test_screen_L8:
        .word   1717986919
        .word   -368140053
        .word   -2004318071