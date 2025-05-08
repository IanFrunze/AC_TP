    .equ    OUTPORT_ADDR, 0xF800 ; addr do config do stor, alterar depois 
    .equ    INPORT_ADDR, 0xFC00 ; addr do config do stor, alterar depois
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

inport_read:
    ldr     r0, inport_addr
    ldr     r0, [r0]
    mov     pc, lr

;recebe uma valor no registo r0, e controi um byte 
;em que o bit com indice r0 fica a 0 e tudos os outros bits ficam a 1
construct_out:
    ;r1 = 1 -> 0000 0001
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

;recebe em r0 um byte, e escreve o que está em r0 no porto de saída
outport_write:
    ldr     r1, outport_addr
    strb    r0, [r1,#1]
    mov     pc, lr

inport_addr:
    .word   INPORT_ADDR
outport_addr:
    .word   OUTPORT_ADDR
