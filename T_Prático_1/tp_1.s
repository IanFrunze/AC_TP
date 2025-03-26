    .equ STACK_SIZE, 64 ; Depois ver se é 64 ou não!
    
    .text
    b   program
    b . ; Reservado (ISR)

program: 
    ldr sp, stack_top_addr
    b main
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
    mov     r7, r8 ; move p_1 temporariamente para r7
    and     r7, r7, r7 ; p_1 == 0
    bzc     umull32_if_end
    ; p -= M_ext << 32
    sub     r4, r4, r0
    sbc     r5, r5, r1
umull32_if_end:
    ; p_1 = p and 0x1
    mov     r7, #1
    and     r8, r7, r2
    ; p >>= 1
    lsr     r5, r5, #1
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
    mov     r0, r2
    mov     r1,r3
    mov     pc,lr
    b .

srand:
    ; r0 e r1 -> nseed
    mov     r2,sp
    ldr     r3,seed0_addr
    ldr     sp,[r3]
    pop     r3
    pop     r3
    push    r1
    push    r0
    mov     sp,r2
srand_ret:
    mov     pc,lr

rand:
    ldr     r0, seed0_addr
    ldr     r0, [r0]
    ldr     r1, seed1_addr
    ldr     r1, [r1]
    ; umull32(seed,214013) está em r0 e r
    mov     r2, #0xFD
    movt    r2, #0x43
    mov     r3, #0x03
    push    lr
    bl      umull32
    pop     lr
    ; (umull32(seed,214013) + 2531011)
    mov     r2, #0xC3
    movt    r2, #0x9E
    mov     r3, #0x26
    add     r0, r0, r2
    adc     r1, r1, r3
    ; ..% RAND_MAX
loopDivide_init:
    mov     r2, #0xFF
    movt    r2, #0xFF
    mov     r3, #0
    b       for_cond
loopDivide:
    sub     r0,r0,r2
    sbc     r1,r1,r3
loopDivide_cond:
    cmp     r0,r2
    sbc     r4,r1,r3
    bhs     for
    ; seed = ...
    mov     r4, sp
    ldr     r5, seed0_addr
    ldr     sp, [r5]
    pop     r5
    pop     r5
    mov     r7, r0
    push    r1
    push    r0
    mov     sp, r4
    ;seed >> 16
    mov     r0,r7
rand_ret:
    mov     pc,lr
    b .

main:
    push    lr
    push    r0 ; error
    push    r1 ; rand_number
    push    r2 ; i
    push    r3 ; N
    mov     r4, 0x152F
    mov     r5, 0x0000
    bl      srand
main_for_init:
    mov     r0, #0 ; error = 0
    mov     r2, #0 ; i = 0
    b       main_for_cond
main_for:
    ; como meter retorno do rand() no rand_number?
    bl       rand
;
main_if:

main_if_cond:
    cmp     r1, ; ?
    beq     main_if     
main_if_end:
    mov     r0, #1
;
main_for_cond:
    cmp     r3, r2
    bzc     main_for_end
    and     r0, r0, r0
    bzc     main_for_end
    add     r2, r2, #1 ; i++
    blo     main_for
main_for_end:
    pop     r3
    pop     r2
    pop     r1
    pop     r0
    pop     pc
    b .

    .data; Variáveis globais
result:
    .word 17747, 2055, 3664, 15611, 9816; result[N]
seed0:  .word 1; 16..0
seed1:  .word 0; 32..16
    .stack
    .space  STACK_SIZE
stack_top:
