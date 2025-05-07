    .equ    OUTPORT_ADDR, 0xF800 ; addr do config do stor, alterar depois 
    .equ    INPORT_ADDR, 0xFC00 ; addr do config do stor, alterar depois
    
    .text
    b   programa
    b .
programa:
    b   main

inport_read:
    ldr     r0, inport_addr
    ldr     r0, [r0]
    mov     pc, lr
inport_addr:
    .word   INPORT_ADDR

;recebe um byte em r0 e retorna em r0 apenas os 3 primeiros bits
get_bits:
    mov     r1, #0x7
    and     r0, r0, r1
    mov     pc, lr

;recebe uma valor no registo r0, e controi um byte 
;em que o bit com indice r0 fica a 0 e tudos os outros bits ficam a 1
construct_out:
    ;r1 = 0xFE -> 1111 1110
    mov     r1, #0xFE
loop_init:
    and     r0,r0,r0
    bzs     loop_end
loop:
    lsl     r1, r1, #1
    add     r1, r1, #1
    sub     r0, r0, #1
    and     r0, r0, r0
    bzc     loop
loop_end:
    mov     r0, r1
    mov     pc, lr

;recebe em r0 um byte, e escreve o que está em r0 no porto de saída
outport_write:
    ldr     r1, outport_addr
    strb    r0, [r1,#1]
    mov     pc, lr

outport_addr:
    .word   OUTPORT_ADDR

main:

main_loop:
    bl      inport_read
    bl      get_bits
    bl      construct_out
    bl      outport_write
    b       main_loop
    b .





