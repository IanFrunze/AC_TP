    .text
    b   program
    b . ; Reservado (ISR)

program: 
    ldr sp, stack_top_addr
    b   main
stack_top_addr:
    .word stack_top
umull32:
    ; 32 bits menor peso do M_ext:
    ; r0 M_ext 16..0
    ; r1 M_ext 32..16
    ; 32 bits menor peso do p:
    ; r2 p 16..0
    ; r3 p 32..16
    ; 32 bits maior peso do p:
    ; r4 p 48..32 
    ; r5 p 64..48
    push    r4
    push    r5
    push    r6
    push    r7
    push    r8
    push    r9
    push    r10
    mov     r4,#0
    mov     r5,#0
    mov     r8, #0 ; p_1
umull32_for_init:
    mov     r9, #32
    mov     r6, #0 ; i
    b       umull32_for_cond
umull32_for:
umull32_if:
    ; cond
    mov     r7, #1 ; r7 = p_1
    and     r10, r2, r7 ; p and 0x1
    bzc     umull32_else_if
    cmp     r7, r8 ; p_1 == 1
    bzc     umull32_else_if
    ; p += M_ext << 32
    add     r4, r4, r0  
    adc     r5, r5, r1
    b       umull32_if_end
umull32_else_if:
    ; cond
    mov     r7, #1
    and     r10, r2, r7
    bzs     umull32_if_end
    mov     r7, r8 ; Move p_1 temporariamente para r7
    and     r7, r7, r7 ; p_1 == 0
    bzc     umull32_if_end
    ; p -= M_ext << 32
    sub     r4, r4, r0 ; 
    sbc     r5, r5, r1
umull32_if_end:
    ; p_1 = p and 0x1
    mov     r7, #1
    and     r8, r7, r2
    ; p >>= 1
    asr     r5, r5, #1
    rrx     r4, r4
    rrx     r3, r3
    rrx     r2, r2
    ; i++
    mov     r7, #1
    add     r6, r6, r7
umull32_for_cond:
    cmp     r6, r9 ; i < 32
    blo     umull32_for
umull32_ret:
    mov    r0, r2
    mov    r1, r3
    pop    r10
    pop    r9
    pop    r8
    pop    r7
    pop    r6
    pop    r5
    pop    r4
    mov    pc, lr

main:
    mov     r0,#0x00
    movt    r0,#0xFF
    mov     r1,#0x00
    movt    r1,#0xF0
    mov     r2,#0xFF
    movt    r2,#0xFF
    mov     r3,#0xFF
    movt    r3,#0xFF
    bl      umull32

    b   .
