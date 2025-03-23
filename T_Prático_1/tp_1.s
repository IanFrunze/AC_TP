    .equ STACK_SIZE, 64 ; Depois ver se é 64 ou não!
    
    .text
    b   program
    b . ; Reservado (ISR)

umull32:
    ;r0 M_ext(baixa)
    ;r1 M_ext(alta)
    ;r2 p(baixa)
    ;r3 p(alta)
    mov     r4, #0  ; p_1
umull32_for_init:
    mov     r5, #32
    mov     r6, #0  ; i
    b       for_cond
umull32_for:
    mov     r7,#1
    and     r7, r2, r7  ; p and 1
    bzc     else_if    ; != 0
    mov     r7,#1
    cmp     r7, r4
    bne     else_if
umull32_if:
    add     r3,r3,r0
    b if_end
umull32_else_if:
    mov     r7,#1
    and     r7,r2,r7
    bzs     if_end
    mov     r7,#1
    and     r7,r4,r4
    bzc     if_end
    sub     r3,r3,r0
umull32_if_end:
    mov     r7,#1
    and     r4,r2,r7
    lsr     r2,r2,#1
    ror     r3,r2,#1
    mov     r7,#1
    add     r6,r6,r7
umull32_for_cond:
    cmp     r6,r5
    blo     for
    ;return
    mov     r0,r2
    mov     r1,r3
    mov     r2, #0
    mov     r3, #0
    b .

program: 
    ldr sp, stack_top_addr
    b main
stack_top_addr:
    .word stack_top

main: 
    push    lr
    push    r0
    push    r1
    b .

   .data
; Variáveis globais
   .stack
   .space  STACK_SIZE
stack_top: 
            