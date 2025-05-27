; Ficheiro:  programa.s
; Descrição: Programa para a realizacao do Trabalho de Projeto de Arquitetura de Computadores.
; Autor:     Ian Frunze (A52867@alunos.isel.pt), Tito Silva (A53118@alunos.isel.pt)
; Data:      XX-05-2025

; Roll animation available:
; Roulette - BCDEFA 
; Spin - (Mostra sequencialmente as faces do dado)(Opcional)

; Definição dos valores dos símbolos utilizados no programa

	.equ	STACK_SIZE, 64 ; Dimensao do stack, em bytes

	.equ	ENABLE_INTERRUPT, 0x10 ; --------00 0(M) 1(I) 0(N) 0(V) 0(C) 0(Z) , Mete a Flag I (Interrupt Enable) a 1 e a Flag M (Mode) a 0

	.equ    INPORT_ADDRESS, 0xFF80 ; Endereco do porto de entrada
	.equ	OUTPORT_ADDRESS, 0xFFC0 ; Endereco do porto de saida

	.equ 	SIDES_MASK, 0x0C ; Máscara para os bits que controlam lados do dado
	.equ 	SIDES_POS, 0x02 ; Quantidade de right-shifts

	.equ 	ROLL_MASK, 0x01 ; Máscara para o bits de controlo do roll

	.equ 	FED_ADDRESS, 0xFF40

	.equ 	SLEEP_DURATION, 0x10 ; 2 segundos de sleep

; Secção:    text

	.text
	b 		program
	b 		interrupt_routine_addr
program:
	ldr		sp, stack_top_addr
    b   	main

stack_top_addr:
	.word	stack_top

interrupt_routine_addr:
	.word 	interrupt_routine

main:
;	Ativa interrupt_routine
	mrs		r0, cpsr
	mov 	r1, #ENABLE_INTERRUPT
	orr 	r0, r0, r1
	msr 	cpsr, r0
main_loop:
	b 		inport_read
	b		roll_check
	b 		sides_read
;	se o dado atual == dado anterior itera de novo
if:
	cmp 	r4, r0
	bzs 	if_end
	mov 	r4, r0
;	b		random_face (esperar pelo stor)
if_end:
 	b		outport_write
	b		main

; Rotina:    import_read
; Descricao: Lê o porto de entrada a 8 bits o valor passado como argumento. Função folha.
; Entradas:  -
; Saidas:    r0 - valor do porto de saida
; Efeitos:   -
inport_read:
	ldr		r0, [INPORT_ADDRESS, #0]
	ldrb 	r0, [r0, #0]
	mov		pc, lr

; Verifica se o roll é 0, caso seja, usa esse sinal diretamente para ativar o FED, e por sua vez a rotina de interrupção
roll_check:
	mov 	r1, #ROLL_MASK
	and 	r0, r0, r1
	mov 	r1, #FED_ADDRESS
	movt 	r1, #FED_ADDRESS
	str		r0, [r1, #0]
	mov		pc, lr

; recebe r0 (porto de entrada) como parâmetro
select_die:
	ldr 	r1, die_addr
	ldrb 	r0, [r1, r0]
	mov 	pc, lr
; retorna com o número de lados em r0 e r4

die_addr:
	.word	die

seg7_values_addr:
	.word	seg7_values

interrupt_routine: ; Faz efeito luminoso (2s, 1s por spin) e mede tempos
	push 	r0
	mov		r0, #FED_ADDRESS & 0xFF
	movt	r0, #(FED_ADDRESS >> 8) & 0xFF

	b		animation

	b 		outport_write
;	b 		(uma função que observe o valor var proveniente do atb "oscilator" para fazer os 10s com uma frequência alta)
	pop 	r0
	movs	pc, lr

animation:
	; fzr loop para o roulete
	
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
animation_seq: ; Roullete Style
	.byte 	0x02 ; B
	.byte 	0x04 ; C
	.byte 	0x08 ; D
	.byte 	0x10 ; E
	.byte 	0x20 ; F
	.byte   0x01 ; A

die_sides:
	.byte 	0x04 ; 4 lados 
	.byte 	0x06 ; 6 lados
	.byte 	0x08 ; 8 lados
	.byte 	0x0C ; 12 lados

; Dado 4 faces = {2,4,6,8} (Pares)
die_4:
	.byte 	0x02 ; 2
	.byte 	0x04 ; 4
	.byte 	0x06 ; 6
	.byte 	0x08 ; 8

; Dado 6 faces = {1,2,3,5,7,9} (Primos, mais o 9)
die_6:
	.byte 	0x01 ; 1
	.byte 	0x02 ; 2
	.byte 	0x03 ; 3
	.byte 	0x05 ; 5
	.byte 	0x07 ; 7
	.byte 	0x09 ; 9

; Dado 8 faces = {1,2,3,4,5,6,7,8} (1-8)
die_8:
	.byte 	0x01 ; 1
	.byte 	0x02 ; 2
	.byte 	0x03 ; 3
	.byte 	0x04 ; 4
	.byte 	0x05 ; 5
	.byte 	0x06 ; 6
	.byte 	0x07 ; 7
	.byte 	0x08 ; 8

; DADO VICIADO, O DADO DE 12 FACES DEVE SER O DE 6, 2 VEZES

; Dado 12 faces = {1,2,2,3,4,4,5,6,6,7,8,8} (Ímpares 1 vez e Pares 2 vezes, exceto o 9)
die_12:
	.byte 	0x01 ; 1
	.byte 	0x02 ; 2
	.byte 	0x02 ; 2
	.byte 	0x03 ; 3
	.byte 	0x04 ; 4
	.byte 	0x04 ; 4
	.byte 	0x05 ; 5
	.byte 	0x06 ; 6
	.byte 	0x06 ; 6
	.byte 	0x07 ; 7
	.byte 	0x08 ; 8
	.byte 	0x08 ; 8

seg7_values:
	.byte	0x06 ; 1
    .byte 	0x5B ; 2
    .byte	0x4F ; 3
    .byte	0x66 ; 4
    .byte	0x6D ; 5
    .byte	0x7D ; 6
    .byte	0x07 ; 7
    .byte	0x7F ; 8
    .byte	0x6F ; 9
    .align 	1

	.stack
	.space	STACK_SIZE
stack_top:
