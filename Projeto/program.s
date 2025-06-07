; Ficheiro:  programa.s
; Descrição: Programa para a realizacao do Trabalho de Projeto de Arquitetura de Computadores.
; Autor:     Ian Frunze (A52867@alunos.isel.pt), Tito Silva (A53118@alunos.isel.pt)
; Data:      XX-05-2025


; Roll animation available:
; Roullete - BCDEFA 
; Spin - (Mostra sequencialmente as faces do dado)

; Definição dos valores dos símbolos utilizados no programa
;=================================== Constants ===================================;
	.equ	STACK_SIZE, 64 ; Dimensao do stack, em bytes

	.equ	RAND_MAX_L, 0xFFFF		; Corresponde ao maior valor inteiro
	.equ	RAND_MAX_H, 0xFFFF		; sem sinal codificavel com 32 bits
	.equ	N, 5

	.equ	TIME_LAP, 0x01 	; tempo de uma volta completa da animação
	.equ	LAPS, 0x03     ; número de voltas completas feitas

	.equ	ENABLE_INTERRUPT, 0x10 ; --------00 0(M) 1(I) 0(N) 0(V) 0(C) 0(Z) , Mete a Flag I (Interrupt Enable) a 1 e a Flag M (Mode) a 0

    .equ    INPORT_ADDRESS, 0xFF80; Endereco do porto de entrada
	.equ	OUTPORT_ADDRESS, 0xFFC0 ; Endereco do porto de saida

	.equ 	SIDES_MASK, 0x0C ; Máscara para os bits do dado, no inport read
	.equ 	SIDES_POS, 0x02 ; Quantidade de right-shifts

	.equ 	ROLL_MASK, 0x01 ; Máscara para o bits de controlo do roll

	.equ 	FED_ADDRESS, 0xFF40
	.equ    SIZE_ANIMATION_SEQ, 6 ; Último índice da lista da sequência da animação

	.equ	FRAME_TIME, 0x02 ; Tempo de cada frame da animação, correponde a +- 0,2 s
	.equ 	WAIT_FOR_NEXT_ROLL, 120 ; Tempo a esperar após um rolamento, até ser possível o próximo +- 10s

; Secção:    text
	.text
	b 		program
	b 		isr
program:
	ldr		sp, stack_top_addr
    b   	main

stack_top_addr:
	.word	stack_top


main:
;=================================== lobby ===================================;
;fase inicial antes de iniciar o jogo
;fase de seleção de dados
lobby:
	;inicializa o lobby com o dado 4 como padrão
	mov		r0, #0
	bl		select_die
	mov		r5, r0
	bl 		inport_read
	mov 	r1, #ROLL_MASK
	and 	r8, r1, r0 
	b 		if_lobby
lobby_loop:
	;r4 -> ultimo dado alterado, 
	;r5 -> dado escolhido
	;r4 e r5 guardam mais expecificamente o endereço da lista do dado
	;r6 -> porto de entrada
	;r7 -> face atual
	;r8 -> last roll
	bl 		inport_read
	mov 	r6, r0
	;retira o dado do porto de saída
	mov 	r1, #SIDES_MASK
	and 	r0, r6, r1
	lsr 	r0, r0, #SIDES_POS
	;busca o endereço do dado escolhido
	bl		select_die
	mov		r5, r0

if_lobby_cond:
	cmp 	r5, r4 ; compara o dado lido com o último dado alterado
	bzs		end_if_lobby ; Se forem iguais, ou seja o dado não mudou, não faz nada
if_lobby: 
	;se o dado foi alterado 
	;atualiza o dado escolhido
	mov		r4, r5
	;calcula um indice válido, de uma face aleatoria do dado escolhido
	mov		r0, r4
	bl		random_face
	mov		r7, r0
	sub		r7, r7, #1  
end_if_lobby:
	;escreve no porto de saída a face correspondente ao indice presente em r7
	mov		r0, #seg7_values_addr
	ldr		r0, [r0]
	ldrb	r0, [r0,r7]
	bl		outport_write
roll_check:
	;verifica se ouve um flanco descendente do bit do roll
	mov 	r1, #ROLL_MASK
	and		r0, r6, r1
	mov		r1, r8
	cmp		r0, r1
	beq		lobby_lopp_end ; se não houver alteração no roll vai para lobby_loop_end
	;verifica se a mudança no valor do bit roll foi descendente, 1 para 0
	mov		r1, #0
	cmp		r0, r1
	bne		lobby_lopp_end 
	;houve um roll então vai para o game
	beq		game
lobby_lopp_end:
	mov		r8, r0
	b 		lobby_loop


;=================================== Game ===================================;
;loop do jogo em si
;onde ocorre a animação e o rolamento do dado
game:
;Rolamento do dado
	bl		inport_read
	;lê qual dado foi rolado
	mov 	r1, #SIDES_MASK
	and 	r0, r0, r1
	lsr 	r0, r0, #SIDES_POS
	;busca o tamanho do dado rolado
	bl		select_die
	;calcula um indice de 0..tamanho do dado, aleatoriamente
	bl		random_face
	;obtem a face correspondenete ao índice calculado
	mov		r7, r0
	sub		r7, r7, #1  
	mov		r0, #seg7_values_addr
	ldr		r0, [r0]
	ldrb	r4, [r0,r7]
	;executa a animação
	mov		r0, #LAPS
	mov		r1, #TIME_LAP
	bl 		animation
	;após a animação escreve no porto de saída a face do dado calculada
	mov		r0, r4
	bl		outport_write
	;deixa o var com valor 0
	mov		r1, #0
	ldr		r0, var_addr_game
    ldr    r0, [r0]
	strb		r1, [r0]
; 	Diz ao CPU que está pronto para interrupções, ou seja,
;	para incrementar a variável var por 1.
	mrs		r0, cpsr
	mov		r5, #ENABLE_INTERRUPT
	orr		r0, r0, r5
	msr		cpsr, r0
;espera os 10 segundos até ser possivel rolar de novo
wait_10:
	;
	ldr		r0, var_addr_game
    ldrb    r0, [r0]
	mov		r1, #WAIT_FOR_NEXT_ROLL

	cmp		r0, r1
	blo		wait_10
	;após passarem os 10 s
	;Diz ao CPU que não está pronto para interrupções
	mrs		r0, cpsr
	mov		r5, #ENABLE_INTERRUPT
	eor		r0, r0, r5 ; desabilita o precessador de aceitar interrupção
	msr		cpsr, r0
;verifica se houve um flanco descendente do roll, 1 para 0
wait_check_off:
	;espera o roll estar a 1
	bl 		inport_read
	mov 	r6, r0
	mov 	r0, #ROLL_MASK
	and 	r0, r6, r0
	bzs		wait_check_off
wait_new_roll:
	;espera até o roll ir de 1 para 0
	bl 		inport_read
	mov 	r6, r0
	mov 	r0, #ROLL_MASK
	and 	r0, r6, r0
	bzc		wait_new_roll
;após um novo rolamento volta para o game e faz tudo de novo
	b		game


seg7_values_addr:
	.word	seg7_values

var_addr_game:
	.word	var

;---------------------------------------------------------------------------------;
;---------------------------------- Random_face ----------------------------------;
; 	Description: calcula um indice de 0..tamanho do dado, aleatoriamente
; 	Parametros:  r0 - o endereço do dado desejado
; 	Retorna:   	 r0 - Um indice aleatorio da lista do endereço do dado recebido
random_face:
	push	lr
	push	r4
	;vai buscar ao endereço do dado o primeiro elemento,
	; que corresponde ao tamanho do dado
	mov		r1, r0
	ldrb	r0, [r1, #0]

	push	r1
	bl		rand
	pop		r1
	;retorna a face gerada aleatoriamente
	add		r2, r0, #1
	ldrb	r0,[r1,r2]

	pop		r4
	pop		pc
	
;---------------------------------------------------------------------------------;
;---------------------------------- isr ----------------------------------;
; 	Description: incrementa 1 a variavel var
isr:
	push	r2
	push	r1
	push	r0

	ldr	r0, var_addr_isr
	ldrb	r1, [r0, #0]
	add	r1, r1, #1
	strb	r1, [r0, #0]

	mov		r0, #FED_ADDRESS & 0xFF
	movt	r0, #(FED_ADDRESS >> 8) & 0xFF
	strb	r0, [r0, #0]

	pop	r0
	pop	r1
	pop	r2
	movs	pc, lr

var_addr_isr:
	.word	var

;--------------------------------- select_die ---------------------------------;
; 	Description: Seleciona um dado com base no bits 2 e 3 do porto de entrada.
; 	Parametros: 		 r0 - dado selecionado no porto de entrada
; 	Retorna:   	 r0 - Endereço do dado selecionado
select_die:
	mov		r2, #0
	mov		r3, #2
	b 		loop_calcule_index_cond
	;calcula o indice na lista dos dados existente, o dado selecionado
loop_calcule_index:
	add		r2, r2, r3
	sub		r0, r0, #1
loop_calcule_index_cond:
	and		r0, r0, r0
	bzc		loop_calcule_index
	;retorna o endereço do dado selecionado
	ldr 	r1, die_addr
	ldr 	r0, [r1, r2]
	mov 	pc, lr

die_addr:
	.word	die

;--------------------------------- animation---------------------------------;
; 	Description: Faz a animação de rolamento
; 	Parametros: r0 - número de voltas feitas durante a animação 
;				r1 - tempo a dar uma volta completa
animation:
	push	lr
	push	r4
	push	r5
    push    r6
	; r4 - número de voltas feitas durante a animação
	; r1 - tempo de uma volta completa
	; r3 - indice do frame atual da animação
	mov		r4, r0 

	and		r4, r4, r4
	beq		sleep_end 	; if 0 sleep_end else sleep_outer_loop
sleep_outer_loop:
	mov		r3, #SIZE_ANIMATION_SEQ
;escreve no porto de saída o frame da animação
frame_animation:
	;vai buscar a lista da sequencia da animação o frame correspondente
	ldr 	r0, animation_seq_addr
	ldrb	r0, [r0, r3]
	;escreve no porto de saída
	push	r1
	push	r2
	push	r3
	bl		outport_write
	pop		r3
	pop		r2
	pop		r1
	;verifica se este foi o último frame
	and		r3,r3,r3
	bzc		wait_frame_time ; if (último frame/indice = 0) sleep_end else (wait_frame_time)
	b 		sleep_end
;esepra o tempo de um frame
wait_frame_time:
	mov		r2, r1
	;mete var a 0
	mov		r5, #0
	ldr		r0, var_addr_animation
	strb	r5, [r0]
; 	Diz ao CPU que está pronto para interrupções, ou seja,
;	para incrementar a variável var por 1.
	mrs		r0, cpsr
	mov		r5, #ENABLE_INTERRUPT
	orr		r0, r0, r5
	msr		cpsr, r0
;espera o FED incrementar 1 em var até que esta seja igual ou mair ao tempo de cada frame
wait_FED:
	ldr		r0, var_addr_animation
    ldrb    r0, [r0]
	mov		r5, #FRAME_TIME
	cmp		r0, r5
    blo     wait_FED
	;Diz ao CPU que não está pronto para interrupções
	mrs		r0, cpsr
	mov		r5, #ENABLE_INTERRUPT
	eor		r0, r0, r5 ; desabilita o precessador de aceitar interrupção
	msr		cpsr, r0
	;verifica o tempo por volta chegou a 0 ou não
	sub		r2, r2, #1
	; if(tempo por volta = 0) continua else wait_frame_time(espera mais um tempo por frame)
	bzc		wait_frame_time 
	
	;após passar o tempo necessário por 1 frame, passa para o próximo frame
	sub		r3, r3, #1
	bzc		frame_animation
;após 1 volta completa verifica quantas voltas são necessárias e repete o processo antrior
frame_animation_end:
	sub		r4, r4, #1	; número de voltas totais
	bzc		sleep_outer_loop	; if !=0 sleep_outer_loop else sleep_end
;retorna
sleep_end:
    pop     r6     
	pop		r5
	pop		r4
	pop		pc	

var_addr_animation:
	.word	var

;---------------------------------------------------------------------------------;
;---------------------------------- Inport Read ----------------------------------;
; 	Description: Retorna o que é lido no porto de entrada.
; 	Retorna:   	 r0 - Valor lido no porto de entrada
inport_read:
	mov		r1, #INPORT_ADDRESS & 0xFF
	movt	r1, #(INPORT_ADDRESS >> 8) & 0xFF
	ldrb	r0, [r1, #0]
	mov	pc, lr


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

animation_seq_addr:
	.word animation_seq
; -------------------------------------------------------------------
; 							Geração pseudo-aleatorios
;--------------------------------------------------------------------

	; Rotina:    umull32
; Descricao: Realiza a multiplicacao de dois numeros naturais codificados com
;            32 bits.
;            Interface exemplo: uint32_t umull( uint32_t M, uint32_t m );
; Entradas:  R1:R0 - Valor do multiplicando (M)
;            R3:R2 - Valor do multiplicador (m)
; Saidas:    R1:R0 - Valor do produto
; Efeitos:   R5:R4 - Parte alta (bits 63..32) do produto (p), pois R3:R2 contem
;                    a parte baixa (bits 31..0)
;            R6    - Mapeia a variavel p_1
;            R7    - guarda o valor da iteracao do ciclo for (i)
;            R8    - guarda valores temporariamente
;
umull32:
	; Prologo
	push	r8
	push	r7
	push	r6
	push	r5
	push	r4

	; Iniciar p fazendo a extensao de sinal aos 16 MSb
	asr	r4, r3, #15
	mov	r5, r4
	; Inicia p_1
	mov	r6, #0
	; Implementacao do ciclo for
	mov	r7, #0	; Inicia i
umull32_loop:
	mov	r8, #32	; Avaliar o limite maximo de i
	cmp	r7, r8
	bhs	umull32_ret
	; Implementacao do if
	mov	r8, #1
	and	r8, r2, r8
	bzc	umull32_else
	mov	r8, #1
	cmp	r6, r8
	bne	umull32_loop_end
	add	r4, r4, r0	; Atualizar o valor de p
	adc	r5, r5, r1
	b	umull32_loop_end
umull32_else:
	; Implementacao otimizada do else
	mov	r8, #0
	cmp	r6, r8
	bne	umull32_loop_end
	sub	r4, r4, r0	; Atualizar o valor de p
	sbc	r5, r5, r1
umull32_loop_end:
	mov	r8, #1	; Definir o novo valor de p_1
	and	r6, r2, r8
	asr	r5, r5, #1
	rrx	r4, r4
	rrx	r3, r3
	rrx	r2, r2
	add	r7, r7, #1	; Incrementar i
	b	umull32_loop

umull32_ret:
	; Epilogo
	mov	r0, r2	; Preparar o valor a devolver
	mov	r1, r3

	pop	r4
	pop	r5
	pop	r6
	pop	r7
	pop	r8
	mov	pc, lr

; Rotina:    srand
; Descricao: Afeta a variavel global seed com um novo valor (semente),
;            recebido por parametro.
;            Interface exemplo: void srand( uint32_t nseed );
; Entradas:  R0 - Parte baixa (bits 0..15) do novo valor de seed
;            R1 - Parte alta (bits 16..31) do novo valor de seed
; Saidas:    -
; Efeitos:   Altera o valor da variavel global seed
;            R2 - guarda valores temporariamente
;
srand:
	ldr	r2, seed_addr_srand
	str	r0, [r2, #0]
	str	r1, [r2, #2]
	mov	pc, lr

seed_addr_srand:
	.word	seed

; Rotina:    rand
; Descricao: Implementa um gerador congruencial linear (LCG) para gerar numeros
;            pseudo-aleatorios entre zero e o parametro recebido.
; Entradas:  R0 - limite máximo da gearação
; Saidas:    R0 - O valor pseudo-aleatorio gerado
rand:
	; Prologo
	push	lr
	push	r4
	add		r4, r0 , #1 ; 0 <= gerado <= r0
	; Obter o valor atual de seed
	ldr	r2, seed_addr_rand
	ldr	r0, [r2, #0]
	ldr	r1, [r2, #2]
	; Calcular a multiplicacao a 32 bits
	mov	r2, #( 0x43FD >> 0 ) & 0xFF	; Carregar o valor 214013
	movt	r2, #( 0x43FD >> 8 ) & 0xFF
	mov	r3, #( 0x0003 >> 0 ) & 0xFF
	movt	r3, #( 0x0003 >> 8 ) & 0xFF
	bl	umull32
	; Calcular a adicao a 32 bits
	mov	r2, #( 0x9EC3 >> 0 ) & 0xFF	; Carregar o valor 2531011
	movt	r2, #( 0x9EC3 >> 8 ) & 0xFF
	mov	r3, #( 0x0026 >> 0 ) & 0xFF
	movt	r3, #( 0x0026 >> 8 ) & 0xFF
	add	r0, r0, r2
	adc	r1, r1, r3

    ; Nao e necessario implementar a divisao modulo, pois a operacao realizada
    ; com valores de 32 bits nunca ultrapassa o valor RAND_MAX (0xFFFFFFFF).
    ; No entanto, a operacao % RAND_MAX deve devolver 0 quando o novo valor de
    ; seed e exatamente igual a RAND_MAX. Assim, e suficiente verificar este
    ; caso e forcar seed a zero.
	mov	r2, #( RAND_MAX_L >> 0 ) & 0xFF
	movt	r2, #( RAND_MAX_L >> 8 ) & 0xFF
	cmp r0, r2
	bne rand_save_seed
	mov	r3, #( RAND_MAX_H >> 0 ) & 0xFF
	movt	r3, #( RAND_MAX_H >> 8 ) & 0xFF
	cmp r1, r3
	bne rand_save_seed
	mov r0, #0  	; Atribuir a seed o valor 0
	mov r1, #0

rand_save_seed:
	; Atualizar o valor de seed
	ldr	r2, seed_addr_rand
	str	r0, [r2, #0]
	str	r1, [r2, #2]
	b 		loop_mod_cond
;faz um modulo do número gerado para este fica entre 0..valor máximo 
loop_mod:
	sub		r1, r1, r4
loop_mod_cond:
	cmp		r1, r4
	bhs		loop_mod
	;retorna
	mov	r0, r1
    pop r4
	pop	pc

seed_addr_rand:
	.word	seed
;-----------------------------------------------------------------------
;								Data
;-----------------------------------------------------------------------
.data
;----------------------------------Lista dos dados existentes-----------------------------
die:
	.word 	die_4 ; 4 lados 
	.word 	die_6 ; 6 lados
	.word 	die_8 ; 8 lados
	.word 	die_12 ; 12 lados

;----------------------------------Lista das faces do dado de 4-----------------------------
die_4:
; Dado 4 faces = {2,4,6,8} (Pares)
	.byte	0x03 ; ultimo indice da lista
	.byte 	0x02 ; 2
	.byte 	0x04 ; 4
	.byte 	0x06 ; 6
	.byte 	0x08 ; 8
    .align 	1

;----------------------------------Lista das faces do dado de 6-----------------------------
die_6:
; Dado 6 faces = {1,2,3,5,7,9} (Primos, mais o 9)
	.byte	0x05 ; ultimo indice da lista
	.byte 	0x01 ; 1
	.byte 	0x02 ; 2
	.byte 	0x03 ; 3
	.byte 	0x05 ; 5
	.byte 	0x07 ; 7
	.byte 	0x09 ; 9
	.align 	1

;----------------------------------Lista das faces do dado de 8-----------------------------
die_8:
; Dado 8 faces = {1,2,3,4,5,6,7,8} (1-8)
	.byte	0x07 ; ultimo indice da lista
	.byte 	0x01 ; 1
	.byte 	0x02 ; 2
	.byte 	0x03 ; 3
	.byte 	0x04 ; 4
	.byte 	0x05 ; 5
	.byte 	0x06 ; 6
	.byte 	0x07 ; 7
	.byte 	0x08 ; 8
    .align 	1

;----------------------------------Lista das faces do dado de 12-----------------------------
die_12:
; Dado 12 faces = {1,1,2,2,3,3,4,4,5,5,6,6}
	.byte	0x0B ; ultimo indice da lista
	.byte 	0x01 ; 1
	.byte 	0x01 ; 1
	.byte 	0x02 ; 2
	.byte 	0x02 ; 2
	.byte 	0x03 ; 3
	.byte 	0x03 ; 3
	.byte 	0x04 ; 4
	.byte 	0x04 ; 4
	.byte 	0x05 ; 5
	.byte 	0x05 ; 5
	.byte 	0x06 ; 6
	.byte 	0x06 ; 6
    .align 	1

;----------------------------------Lista do código de 1..9 do display de 7segmentos-----------------------------
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

;----------------------------------Lista da sequência da animação-----------------------------
animation_seq: 
	.byte	0x00
	.byte 	0x20 ; F
	.byte 	0x10 ; E
	.byte 	0x08 ; D
	.byte 	0x04 ; C
	.byte 	0x02 ; B
	.byte   0x01 ; A
	.align 1

seed:
	.word	1, 0
var:
	.space 1

	.stack
	.space	STACK_SIZE
stack_top:
