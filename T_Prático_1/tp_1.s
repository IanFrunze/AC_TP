    .equ STACK_SIZE, 7 ; Não usa mais de 7 words
    .equ N, 5
    
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

srand:
    ; r0 e r1 -> nseed
    mov     r2, sp
    ldr     r3, seed0_addr
    ldr     sp, [r3]
    pop     r3
    pop     r3
    push    r1
    push    r0
    mov     sp, r2
srand_ret:
    mov     pc, lr

rand:
    push    lr
    push    r4
    push    r5
    ldr     r0, seed0_addr
    ldr     r0, [r0]
    ldr     r1, seed1_addr
    ldr     r1, [r1]
    ; umull32(seed,214013) está em r0 e r
    mov     r2, #0xFD
    movt    r2, #0x43
    mov     r3, #0x03
    bl      umull32
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
    mov     r3, #0xFF
    movt    r3, #0xFF
    b       loopDivide_cond
loopDivide:
    sub     r0, r0, r2
    sbc     r1, r1, r3
loopDivide_cond:
    cmp     r0, r2
    sbc     r4, r1, r3
    bhs     loopDivide
    ; seed = ...
    mov     r4, sp
    ldr     r5, seed0_addr
    ldr     sp, [r5]
    pop     r5
    pop     r5
    mov     r5, r0
    push    r1
    push    r0
    mov     sp, r4
    ;seed >> 16
    mov     r0, r5
rand_ret:
    pop     r5
    pop     r4
    pop     pc

seed0_addr:
    .word   seed0  
seed1_addr:
    .word   seed1

/*
int main( void ) {
    uint8_t error = 0;
    uint16_t rand_number;
    uint16_t i;
    srand( 5423 );
    for( i = 0; error == 0 && i < N; i++ ) {
        rand_number = rand();
        if( rand_number != result[i] ) {
            error = 1;
        }
    }
    return 0;
}
*/

main:
    ; r4 = rand_number
    ; r5 = error
    ; r6 = i
    ; r7 = N
    mov     r5, #0  ; error = 0
    mov     r0, #0x2F 
    movt    r0, #0x15 ; r8 = 5423
    mov     r1, #0x0 ; r9 = 0, para 5423 ser a 32 bits
    bl      srand
main_for_init:
    mov     r6, #0 ; i = 0
    b       main_for_cond
main_for:
    bl      rand
    mov     r4, r0 ; rand_number = retorno do rand()
main_if_cond:
    ldr     r8, result_addr
    ldr     r8, [r6, r8]; r10 = result[i]
    cmp     r4, r8
    beq     main_if_end  
main_if:
    mov     r5, #1  
main_if_end:
    add     r6, r6, #1 ; i++
main_for_cond:
    mov     r7, #N ; N
    and     r5, r5, r5 ; Verifica error == 0
    bzc     main_ret
    cmp     r6, r7 ; i < N
    bhs     main_ret
    b       main_for
main_ret:
    b .

result_addr:
    .word result

    .data ; Variáveis globais
result:
    .word 17747, 2055, 3664, 15611, 9816; result[N]
seed0:  .word 1; 16..0
seed1:  .word 0; 32..16
    .stack
    .space  STACK_SIZE
stack_top:
