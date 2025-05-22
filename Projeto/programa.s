; Ficheiro:  programa.s
; Descrição: Programa para a realizacao do Trabalho de Projeto de Arquitetura de Computadores.
; Autor:     Ian Frunze (A52867@alunos.isel.pt), Tito Silva (A53118@alunos.isel.pt)
; Data:      XX-05-2025

; while( I != 0 ) {
;	 read o sides
;    mostrar uma face do dado selecionado no seg7
; }
; 
; M = 1
; I = 0
; mov ilr, pc
; mov pc, 0x0002
; 
; 
; 
; 
; Roll animation: BCDEFA
; 
; 


; Definição dos valores dos símbolos utilizados no programa

	.equ	STACK_SIZE, 64                ; Dimensao do stack, em bytes

	.equ	ENABLE_EXTINT, 0x10		; --------00 0(M) 1(I) 0(N) 0(V) 0(C) 0(Z)
	; Mete a Flag I (Interrupt Enable) a 1 e a Flag M (Mode) a 0

    .equ    INPORT_ADDRESS, 0xFF80 ; Endereco do porto de entrada
	.equ	OUTPORT_ADDRESS, 0xFFC0 ; Endereco do porto de saida

	.equ 	SIDES_MASK, #0x0C ; Máscara para os bits que controlam lados do dado
	.equ 	SIDES_POS, #0x02 ; Quantidade de right-shifts

	.equ 	FED_ADDRESS, 0xFF40

;	.equ	VAR_INIT_VAL, 0               ; Valor inicial de var

; Secção:    text
; Descrição: a
;
	.text
	b 		program
	b 		interrupt_routine
program:
	ldr		sp, stack_top_addr
    b   	main

stack_top_addr:
	.word	stack_top

interrupt_routine:
	push 	r0
	mov		r0, #FED_ADDRESS & 0xFF
	movt	r0, #(FED_ADDRESS >> 8) & 0xFF

	pop 	r0
	movs	pc, lr

; preservar o roll antes dos sides em r4
; não é necessário escrever o número de lados  no display antes do roll
main:
	b 		inport_read
	b 		sides_read
; exibir no porto de saída uma face do dado selecionado

	ldr 	r0, [r1, #0]
	b 		outport_write
	b 		main

; função folha
; lê e retorna o porto de entrada
inport_read:
	ldr		r0, #INPORT_ADDRESS
	ldrb 	r0, [r0, #0]
	mov		pc, lr

; função folha
; recebe r0 como parâmetro (porto de entrada)
sides_read:
	mov 	r1, #SIDES_MASK
	and 	r0, r0, r1
	lsr 	r0, r0, #SIDES_POS
	ldr 	r1, die_sides_addr
	ldrb 	r0, [r1, r0]
	mov 	pc, lr
; retorna com o número de lados em r0

die_sides_addr:
	.word	die_sides


var_addr_startup:
	.word	var

seg7_values_addr:
	.word	seg7_values




; Rotina:    outport_write
; Descricao: Escreve num porto de saida a 8 bits o valor passado como argumento.
;            Interface exemplo: void outport_write( uint8_t value );
; Entradas:  r0 - valor a escrever no porto de saida
; Saidas:    -
; Efeitos:   r1 - guarda o endereco do porto alvo da escrita
outport_write:
	mov		r1, #OUTPORT_ADDRESS & 0xFF
	movt	r1, #(OUTPORT_ADDRESS >> 8) & 0xFF
	strb	r0, [r1, #0]
	mov		pc, lr

	.data
var:
	.space	1

die_sides:
	.byte 0x04 ; 4 lados 
	.byte 0x06 ; 6 lados
	.byte 0x08 ; 8 lados
	.byte 0x0C ; 12 lados

seg7_values:
	.byte 0x06 ; 1
    .byte 0x5B ; 2
    .byte 0x4F ; 3
    .byte 0x66 ; 4
    .byte 0x6D ; 5
    .byte 0x7D ; 6
    .byte 0x07 ; 7
    .byte 0x7F ; 8
    .byte 0x6F ; 9
    .align 1

	.stack
	.space	STACK_SIZE
stack_top:
