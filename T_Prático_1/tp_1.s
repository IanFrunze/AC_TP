; ---------------------------------------------------------------------------------------
; Ficheiro : tp_1.s
; Descricao : Este codigo implementa um programa para o P16 que gera numeros 
;             pseudo-aleatorios e os multiplica por uma constante, comparando o resultado
;             com uma outra constante. (?)
; Autor : Ian Frunze (A52867@alunos.isel.pt), Tito Silva (A53118@alunos.isel.pt)
; Data : 27/03/2025
; ---------------------------------------------------------------------------------------

    .equ STACK_SIZE, 20 ; Nao usa mais de 20 bytes
    .equ N, 5
    .equ RAND_MAX, 0xFF
    
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
    mov     r4, #0
    mov     r5, #0
    mov     r8, #1
    mov     r6, #0 ; p_1
umull32_for_init:
    mov     r9, #32
    mov     r7, #0 ; i
    b       umull32_for_cond
umull32_for:
umull32_if:
    ; condição
    and     r10, r2, r8 ; p and 0x1 == 0
    bzc     umull32_else_if
    cmp     r6, r8 ; p_1 == 1
    bzc     umull32_else_if
    ; p += M_ext << 32
    add     r4, r4, r0 ; p3 += M_ext 15..0
    adc     r5, r5, r1 ; p4 += M_ext 32..16
    b       umull32_if_end
umull32_else_if:
    ; condição
    and     r10, r2, r8 ; p and 0x1 == 1
    bzs     umull32_if_end
    and     r6, r6, r6 ; p_1 == 0
    bzc     umull32_if_end
    ; p -= M_ext << 32
    sub     r4, r4, r0 ; 
    sbc     r5, r5, r1
umull32_if_end:
    ; p_1 = p and 0x1
    and     r6, r2, r8
    ; p >>= 1
    asr     r5, r5, #1
    rrx     r4, r4
    rrx     r3, r3
    rrx     r2, r2
    ; i++
    add     r7, r7, r8
umull32_for_cond:
    cmp     r7, r9 ; i < 32
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
    ldr     r2,seed_addr
    str     r0,[r2]
    str     r1,[r2,#2]
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
    ldr     r2, seed_addr
    ; seed em r0 e r1
    ldr     r0, [r2]
    ldr     r1, [r2,#2]
    ; umull32(seed,214013)
    mov     r2, #0xFD
    movt    r2, #0x43
    mov     r3, #0x03
    bl      umull32 ; retorna em r0 e r1
    ; (umull32(seed,214013) + 2531011)
    mov     r2, #0xC3
    movt    r2, #0x9E
    mov     r3, #0x26 ; 2531011
    add     r0, r0, r2
    adc     r1, r1, r3
    ; (umull32(seed,214013) + 2531011) % RAND_MAX
loopDivide_init:
    mov     r2, #RAND_MAX
    movt    r2, #RAND_MAX
    mov     r3, #RAND_MAX
    movt    r3, #RAND_MAX
    b       loopDivide_cond
loopDivide:
    ; A - B 
    sub     r0, r0, r2
    sbc     r1, r1, r3
loopDivide_cond:
    ; quando A < B ele para o loop
    cmp     r0, r2
    sbc     r4, r1, r3
    bhs     loopDivide 
    ; resto da divisão fica em r0 e r1
    ; seed = r0 e r1
    ldr     r5, seed_addr
    str     r0,[r5]
    str     r1,[r5,#2]
rand_ret:
    ; seed >> 16 
    mov     r0,r1
    pop     r5
    pop     r4
    pop     pc

seed_addr:
    .word   seed

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
    ; r6 = i
    ; r5 = N
    ; r7 = result[i]
    /*
    error é usado apenas para dar break no loop,
    então em vez de guardar o error num registo, 
    fazer uma verificação e só depois dar break, 
    aplica-se um break diretamente
    */
    mov     r5, #N
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
main_if:
    ; condição
    ldr     r7, result_addr
    lsl     r9,r6,#1 ; i * 2
    ldr     r7, [r7, r9]; r7 = result[i]
    cmp     r4, r7 ; rand_number != result[i]
    ; error = 1
    bne     main_ret ; dá break no loop (ou seja error = 1)
main_if_end:
    add     r6, r6, #1 ; i++
main_for_cond:
    cmp     r6, r5 ; i < N
    blo     main_for
main_ret:
    b .

result_addr:
    .word result

    .data ; Variaveis globais
result:
    .word 17747, 2055, 3664, 15611, 9816; result[N]
seed:   .word 1,0
    .stack
    .space  STACK_SIZE
stack_top:
