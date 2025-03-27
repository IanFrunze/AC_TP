; ---------------------------------------------------------------------------------------
; Ficheiro : tp_1.s
; Descricao : Este codigo implementa um programa para o P16 que gera numeros 
;             pseudo-aleatorios e os multiplica por uma constante, comparando o resultado
;             com uma outra constante. (?)
; Autor : Ian Frunze (A52867@alunos.isel.pt), Tito Silva (A53118@alunos.isel.pt)
; Data : 27/03/2025
; ---------------------------------------------------------------------------------------

    .equ STACK_SIZE, 64 ; Nao usa mais de 7 words (14 bytes) de stack
    .equ N, 5 ; N = 5
    
    .text
    b   program
    b . ; Reservado (ISR)

program: 
    ldr sp, stack_top_addr
    b   main
stack_top_addr:
    .word stack_top

; ---------------------------------------------------------------------------------------
; Rotina : umull32
; Descricao : Multiplicacao entre 2 operandos de 32 bits (bit a bit), com 32 bits de resultado
; Entradas : r0, r1, r2, r3
; Saidas : r0, r1
; Efeitos : (descricao das alteracoes feitas pela rotina em registos, memoria e portos)?
; ---------------------------------------------------------------------------------------

umull32:
    ; 32 bits menor peso do M_ext:
    ; r0 M_ext 15..0
    ; r1 M_ext 32..16
    ; 32 bits menor peso do p:
    ; r2 p 15..0 (p1)
    ; r3 p 32..16 (p2)
    ; 32 bits maior peso do p:
    ; r4 p 48..32 (p3)
    ; r5 p 64..48 (p4)
    push    r4
    push    r5
    push    r6
    push    r7
    push    r8
    push    r9
    push    r10
    mov     r4,#0 ; p3 = 0
    mov     r5,#0 ; p4 = 0
    mov     r8, #0 ; p_1 = 0
umull32_for_init:
    mov     r9, #32 ; r9 = 0x32
    mov     r6, #0 ; i = 0
    b       umull32_for_cond
umull32_for:
umull32_if:
    ; cond_1
    mov     r7, #1 ; r7 = 1
    and     r10, r2, r7 ; p and 0x1
    bzc     umull32_else_if
    cmp     r7, r8 ; p_1 == 1
    bzc     umull32_else_if
    ; p += M_ext << 32
    add     r4, r4, r0 ; p3 += M_ext 15..0
    adc     r5, r5, r1 ; p4 += M_ext 32..16
    b       umull32_if_end
umull32_else_if:
    ; cond_2
    mov     r7, #1 ; r7 = 1
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
    mov     r7, #1 ; i = 1
    add     r6, r6, r7 ; i++
umull32_for_cond:
    cmp     r6, r9 ; i < 32
    blo     umull32_for
umull32_ret:
    mov    r0, r2 ; r0 = p1
    mov    r1, r3 ; r1 = p2
    pop    r10
    pop    r9
    pop    r8
    pop    r7
    pop    r6
    pop    r5
    pop    r4
    mov    pc, lr

; ---------------------------------------------------------------------------------------
; Rotina : srand
; Descricao : Inicializa a "seed" a 32 bits para a geracao de numeros pseudo-aleatorios
; Entradas : r0, r1
; Saidas : r0 ?
; Efeitos : (descricao das alteracoes feitas pela rotina em registos, memoria e portos)?
; ---------------------------------------------------------------------------------------

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

; ---------------------------------------------------------------------------------------
; Rotina : rand
; Descricao : (?)
; Entradas : (void?)
; Saidas : r0 (?)
; Efeitos : (descricao das alteracoes feitas pela rotina em registos, memoria e portos)?
; ---------------------------------------------------------------------------------------

rand:
    push    lr
    push    r4
    push    r5
    ldr     r0, seed0_addr
    ldr     r0, [r0]
    ldr     r1, seed1_addr
    ldr     r1, [r1]
    ; umull32(seed,214013) esta em r0 e r (?)
    mov     r2, #0xFD
    movt    r2, #0x43
    mov     r3, #0x03 ; 214013
    bl      umull32
    ; (umull32(seed,214013) + 2531011)
    mov     r2, #0xC3
    movt    r2, #0x9E
    mov     r3, #0x26 ; 2531011
    add     r0, r0, r2
    adc     r1, r1, r3
    ; (umull32(seed,214013) + 2531011) % RAND_MAX
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

; ---------------------------------------------------------------------------------------
; Rotina : main
; Descricao : Inicializa a "seed" e gera N numeros pseudo-aleatorios, comparando-os com
;             os valores de "result". Se algum dos valores gerados for igual a um dos
;             valores de result, a variavel error e' incrementada.
;             No final, se error for diferente de 0, o programa termina.
; Entradas : (void)
; Saidas : r0
; Efeitos : (descricao das alteracoes feitas pela rotina em registos, memoria e portos)?
; ---------------------------------------------------------------------------------------

main:
    ; r4 = rand_number
    ; r5 = error
    ; r6 = i
    ; r7 = N
    mov     r5, #0  ; error = 0
    mov     r0, #0x2F 
    movt    r0, #0x15 ; r0 = 5423
    mov     r1, #0x0 ; r1 = 0, para 5423 ser a 32 bits
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

    .data ; Variaveis globais
result:
    .word 17747, 2055, 3664, 15611, 9816; result[N]
seed0:  .word 1; 16..0
seed1:  .word 0; 32..16

    .stack ; Memoria em stack
    .space  STACK_SIZE
stack_top:
