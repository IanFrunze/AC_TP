    .equ STACK_SIZE, 64 ; depois ver se é 64 ou não
    
    .text
    b   program
    b . ; Reservado (ISR)

program: 
    ldr sp, stack_top_addr
    b main
stack_top_addr:
    .word stack_top

main: 
; Código aplicacional
    b .

   .data
; Variáveis globais
   .stack
   .space  STACK_SIZE
stack_top: 
            