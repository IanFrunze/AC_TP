; Ficheiro:  lab03.s
; Descricao: Programa para a realização da 3a atividade laboratorial de
;            Arquitetura de Computadores.
; Autor:     Tiago M Dias (tiago.dias@isel.pt)
; Data:      29-04-2025

; Definicao dos valores dos simbolos utilizados no programa
;
	.equ	STACK_SIZE, 64                ; Dimensao do stack, em bytes

	.equ	ALL_ONES, 0xFFFF              ; Palavra com todos os bits a 1
	.equ	ALL_ZEROS, 0x0000             ; Palavra com todos os bits a 0

	.equ	INPORT_ADDRESS, 0xFF80        ; *Justificar Resposta*
	.equ	OUTPORT_ADDRESS, 0xFFC0      ; *Justificar Resposta*

; Seccao:    text
; Descricao: Guarda o código do programa
;
	.text
	b	program
	b	.		; Reservado para a ISR
program:        
	ldr	sp, stack_top_addr
	b	main

stack_top_addr:
	.word	stack_top

; Rotina:    main
; Descricao: *** Para completar ***
; Entradas:  *** Para completar ***
; Saidas:    *** Para completar ***
; Efeitos:   *** Para completar ***
main:
	mov	r0, #ALL_ONES & 0xFF
	bl	outport_write
	mov	r0, #ALL_ZEROS & 0xFF
	bl	outport_write
loop:
	bl	inport_read
	bl	outport_write
	b	loop

; Rotina:    inport_read
; Descricao: *** Para completar ***
; Entradas:  -
; Saidas:    r0 - *** Para completar ***
; Efeitos:   r1 - *** Para completar ***
inport_read:
	mov	r1, INPORT_ADDRESS & 0xFF
	movt	r1, (INPORT_ADDRESS >> 8) & 0xFF
	ldrb	r0, [r1, #0]
	mov	pc, lr

; Rotina:    outport_write
; Descricao: *** Para completar ***
; Entradas:  r0 - *** Para completar ***
; Saidas:    -
; Efeitos:   r1 - *** Para completar ***
outport_write:
	mov	r1, OUTPORT_ADDRESS & 0xFF ; FFC0 & 00FF = C0
	movt	r1, (OUTPORT_ADDRESS >> 8) & 0xFF ; FF 			r1 = FFC0
	strb	r0, [r1, #0] 
	mov	pc, lr

; Rotina:    sleep
; Descricao: Verifica inicialmente se r0 = 0 por meio de um AND consigo mesmo;
;			 Se r0 = 0, efetua um salto para sleep_end;
;			 Se r0 != 0 , inicia r1 com o valor 0x033E (830 em DEC);
;			 Em seguida é iniciado um loop onde r1 vai ser decrementado por 1, até r1 = 0;
; 			 Por sua vez, r0 é decrementado por 1, e se r0 != 0 é efetuado um salto para sleep_outer_loop, assim repetindo-se os processos anteriores até r0 = 0,
;			 onde a rotina acaba.
;			 Em suma, esta rotina comporta-se como um loop dentro de outro loop, dando ao programa o efeito de, como sugere o nome, sleep. 
; Entradas:  r0
; Saidas:    void
; Efeitos:   Altera os registos r0 e r1. Não utiliza variáveis globais, nem portos.
sleep:
	and	r0, r0, r0	; r0 = r0 && r0
	beq	sleep_end 	; if 0 sleep_end else sleep_outer_loop
sleep_outer_loop:
	mov	r1, #0x3E
	movt r1, #0x03	; r1 = 033E (830)
sleep_inner_loop:
	sub	r1, r1, #1	; r1 = r1 - 1
	bne	sleep_inner_loop	; if !=0 sleep_inner_loop else continue
	sub	r0, r0, #1	; r0 = r0 - 1
	bne	sleep_outer_loop	; if !=0 sleep_outer_loop else sleep_end
sleep_end:
	mov	pc, lr	; retorna

; Seccao:    data
; Descricao: Guarda as variáveis globais
;
	.data

; Seccao:    stack
; Descricao: Implementa a pilha com a dimensao definida pelo simbolo STACK_SIZE
;
	.stack
	.space	STACK_SIZE
stack_top:
