    .equ    OUTPORT_ADDR, 0xAFFF
    .equ    INPORT_ADDR, 0xA000
    .equ    FRIST_3_BITS, 0x7

    .text
    b       main
    b .

main:
main_loop:
    bl      inport_read
    mov     r4, #FRIST_3_BITS
    and     r0, r0, r4
    bl      construct_out
    bl      outport_write
    b       main_loop

    ; Lê o que está no porto de entrada, e recebe uma word em r0.
inport_read:
    ldr     r0, inport_addr
    ldr     r0, [r0]
    mov     pc, lr

    ; Recebe uma valor no registo r0, e constroi um byte 
    ; em que o bit com indice r0 fica a 0 e todos os outros bits ficam a 1.
construct_out:
    ; r1 = 1 -> 0000 0001
    mov     r1, #1
loop_init:
    b       loop_cond
loop:
    lsl     r1, r1, #1
    sub     r0, r0, #1
loop_cond:
    and     r0, r0, r0
    bzc     loop
    mov     r0, #0xFF
    eor     r0, r1, r0
    mov     pc, lr

    ; Recebe em r0 um byte, e escreve o que está em r0 no porto de saída
outport_write:
    ldr     r1, outport_addr
    strb    r0, [r1, #0]
    mov     pc, lr

inport_addr:
    .word   INPORT_ADDR
outport_addr:
    .word   OUTPORT_ADDR
