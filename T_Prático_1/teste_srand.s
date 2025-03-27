    .text
    b   program
    b . ; Reservado (ISR)

program: 
    ldr sp, stack_top_addr
    b   main
stack_top_addr:
    .word stack_top
    
srand:
    ; r0 e r1 -> nseed
    ldr     r2,seed_addr
    str     r0,[r2]
    str     r1,[r2,#2]
srand_ret:
    mov     pc, lr



main:
    ldr     r4,seed_addr
    ldr     r5,[r4]
    ldr     r6,[r4,#2]
    mov     r0, #0x2F 
    movt    r0, #0x15 ; r8 = 5423
    mov     r1, #0x0 ; r9 = 0, para 5423 ser a 32 bits
    bl      srand
    b       .
seed_addr:
    .word   seed

    .data
seed:   .word 1,0
    
    seed:   .word 1,0
    .stack
    .space  STACK_SIZE
stack_top:
