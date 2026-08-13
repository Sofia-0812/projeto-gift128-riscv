# Código assembly do GIFT-128 modificado para utilizar a extensão de instruções projetada.

# Mapeamento de Registradores:
# a0 - a3 : Armazenam a Chave (Key)
# s0 - s3 : Armazenam o Texto Plano / Texto Cifrado (Estado interno de 128 bits)
# s4      : Contador do laço (40 rodadas do GIFT-128)
# s5      : Endereço base da tabela de substituição (S-box) na memória
# s6 - s9 : Registradores temporários para cálculos
# a4      : Ponteiro para as constantes de rodada
# s10, s11: Reservados para medição de desempenho total (benchmarking)
# a5      : Acumulador de ciclos para a Lei de Amdahl (Fração f)

# MACROS DA EXTENSÃO DE HARDWARE (GIFT-128)
# Opcode: custom-0 (0x0B) e Formato: I-Type

# gift.load rs1, imm (funct3 = 0)
.macro gift_load rs1, imm
    .insn i 0x0B, 0, x0, \rs1, \imm
.endm

# gift.exec (funct3 = 1)
.macro gift_exec
    .insn i 0x0B, 1, x0, x0, 0
.endm

# gift.read rd, imm (funct3 = 2)
.macro gift_read rd, imm
    .insn i 0x0B, 2, \rd, x0, \imm
.endm

# MACROS DE DESLOCAMENTO (SHIFT)
# Estas duas macros abaixo mostram que a manipulação de bits em software demanda múltiplas 
# operações lógicas e de deslocamento. Elas aplicam uma máscara (AND),
# deslocam os bits (SRL/SLL) e unem o resultado (OR).
.macro RightShift dst, src, mask, shift
	li t0, \mask
	and t0, \src, t0
	srl t0, t0, \shift
	or \dst, \dst, t0
.endm

.macro LeftShift dst, src, mask, shift
	li t0, \mask
	and t0, \src, t0
	sll t0, t0, \shift
	or \dst, \dst, t0
.endm

# ETAPAS 3 e 4: ADDROUNDKEY e KEYSCHEDULE (Preparação da Chave)
# Estas macros preparam as chaves de rodada a partir da chave principal
# usando rotações e permutações.
.macro ExpandKey dst0, dst1, dst2, dst3, src
    # Extrai partes da chave usando manipulação de bits para a rodada atual
	and \dst3, \src, 0x1
	LeftShift \dst3, \src, 0x2, 3
	LeftShift \dst3, \src, 0x4, 6
	LeftShift \dst3, \src, 0x8, 9
	LeftShift \dst3, \src, 0x10, 12
	LeftShift \dst3, \src, 0x20, 15
	LeftShift \dst3, \src, 0x40, 18
	LeftShift \dst3, \src, 0x80, 21

	mv \dst2, zero
	RightShift \dst2, \src, 0x100, 8
	RightShift \dst2, \src, 0x200, 5
	RightShift \dst2, \src, 0x400, 2
	LeftShift \dst2, \src, 0x800, 1
	LeftShift \dst2, \src, 0x1000, 4
	LeftShift \dst2, \src, 0x2000, 7
	LeftShift \dst2, \src, 0x4000, 10
	LeftShift \dst2, \src, 0x8000, 13

	mv \dst1, zero
	RightShift \dst1, \src, 0x10000, 16
	RightShift \dst1, \src, 0x20000, 13
	RightShift \dst1, \src, 0x40000, 10
	RightShift \dst1, \src, 0x80000, 7
	RightShift \dst1, \src, 0x100000, 4
	RightShift \dst1, \src, 0x200000, 1
	LeftShift \dst1, \src, 0x400000, 2
	LeftShift \dst1, \src, 0x800000, 5

	mv \dst0, zero
	RightShift \dst0, \src, 0x1000000, 24
	RightShift \dst0, \src, 0x2000000, 21
	RightShift \dst0, \src, 0x4000000, 18
	RightShift \dst0, \src, 0x8000000, 15
	RightShift \dst0, \src, 0x10000000, 12
	RightShift \dst0, \src, 0x20000000, 9
	RightShift \dst0, \src, 0x40000000, 6
	RightShift \dst0, \src, 0x80000000, 3
.endm

.macro UpdateKey
    # Atualiza a chave mestra para a próxima rodada (KeySchedule)
	# Utiliza máscaras lógicas (AND) e deslocamentos para rotacionar a chave
	li t0, 0xfffc0000
	and t0, a0, t0
	li t1, 0x00030000
	and t1, a0, t1
	srl t0, t0, 2
	sll t1, t1, 14
	or t0, t0, t1

	li t1, 0x0000f000
	and t1, a0, t1
	li t2, 0x00000fff
	and t2, a0, t2
	srl t1, t1, 12
	sll t2, t2, 4
	or t1, t1, t2

	mv a0, a1
	mv a1, a2
	mv a2, a3
	or a3, t0, t1  # Atualização do estado da chave
.endm

# INÍCIO DO PROGRAMA PRINCIPAL
.section .text
	.globl main
	
	main:

	# Captura o estado inicial do contador de ciclos totais
        # rdcycle lê os 32 bits inferiores; rdcycleh lê os 32 bits superiores
        rdcycle s10
        rdcycleh s11

		la t0, encrypt # Carrega o endereço da função de encriptação
		jalr ra, 0(t0) # Salta para a função

		rdcycle t2             # Captura ciclo final (parte baixa)
        rdcycleh t3            # Captura ciclo final (parte alta)
        sub s10, t2, s10       # s10 = Ciclos totais gastos
        sub s11, t3, s11       # s11 = Diferença da parte alta

		ebreak

.section .text,"ax",@progbits
	.globl encrypt

	encrypt:
        # Carrega os endereços das estruturas de dados
		la a4, const           # Carrega endereço base das Constantes de Rodada
		
		# Carrega o Texto Plano (128 bits divididos em 4 registradores de 32 bits)
		la t0, txt2_e 
		lw s0, 0(t0)
		lw s1, 4(t0)
		lw s2, 8(t0)
		lw s3, 12(t0)

		# Carrega a Chave (128 bits divididos em 4 registradores de 32 bits)
		la t0, key2	
		lw a0, 12(t0)
		lw a1, 8(t0)
		lw a2, 4(t0)
		lw a3, 0(t0)

		# Inicializa o contador de rodadas (GIFT-128 possui 40 rodadas)
		li s4, 40
        
        # Inicializa o acumulador da Lei de Amdahl em zero
        li a5, 0
		
        # LAÇO PRINCIPAL 
		DO:
			
            # INÍCIO DA MEDIÇÃO DA FRAÇÃO 'f'
            rdcycle t4 # t4 liga o cronômetro do gargalo

            # Etapa 1 e 2: SubCells e PermBits (Acelerado em Hardware)
			
			# Carrega os 128 bits de estado no módulo 
			gift_load s0, 0
			gift_load s1, 1
			gift_load s2, 2
			gift_load s3, 3

			# Executa a instrução única para as etapas de SubCells e PermBits
			gift_exec

			# Lê os 128 bits processados de volta para a CPU 
			gift_read s0, 0
			gift_read s1, 1
			gift_read s2, 2
			gift_read s3, 3

            # FIM DA MEDIÇÃO DA FRAÇÃO 'f'
            rdcycle t5             # t5 desliga o cronômetro do gargalo
            sub t6, t5, t4         # t6 = tempo gasto apenas nessas 2 funções nesta rodada
            add a5, a5, t6         # a5 acumula os ciclos do gargalo 

			# Etapa 3: AddRoundKey

			# Combina a chave de rodada com o estado atual usando XOR bit a bit.
			ExpandKey s6, s7, s8, s9, a0
			sll s6, s6, 1
			sll s7, s7, 1
			sll s8, s8, 1
			sll s9, s9, 1

			xor s0, s0, s6
			xor s1, s1, s7
			xor s2, s2, s8
			xor s3, s3, s9

			ExpandKey s6, s7, s8, s9, a2
			sll s6, s6, 2
			sll s7, s7, 2
			sll s8, s8, 2
			sll s9, s9, 2

			xor s0, s0, s6
			xor s1, s1, s7
			xor s2, s2, s8
			xor s3, s3, s9

			# Adiciona a Constante de Rodada 
			lw t0, 0(a4)
			xor s3, s3, t0

			li t0, 0x80000000
			xor s0, s0, t0
			
            # Etapa 4: KeySchedule (Atualização da Chave)

			# Gera as chaves da próxima rodada a partir da chave atual.
			UpdateKey
			
            # Atualiza o ponteiro da constante de rodada para o próximo valor
			add a4, a4, 4

        # Decrementa o contador e verifica se chegou a zero
		addi s4, s4, -1
		WHILE: bne s4, zero, DO

	ret

# ÁREA DE DADOS
.section .data
	
    # Texto Plano (Vetor de teste oficial do padrão GIFT-128)
	txt2_e: .word 0xfedcba98, 0x76543210, 0xfedcba98, 0x76543210

    # Chave de Criptografia
	key2: .word 0xfedcba98, 0x76543210, 0xfedcba98, 0x76543210 

    # Constantes de Rodada (Uma para cada das 40 rodadas)
	const: .word 0x8,0x88,0x888,0x8888,0x88888,0x888880,0x888808,0x888088,0x880888,0x808888,0x88880,0x888800,0x888008,0x880088,0x800888,0x8880,0x88808,0x888080,0x880808,0x808088,0x80880,0x808800,0x88000,0x880000,0x800008,0x80,0x808,0x8088,0x80888,0x808880,0x88800,0x888000,0x880008,0x800088,0x880,0x8808,0x88088,0x880880,0x808808,0x88080,0x880800,0x808008,0x80080,0x800800,0x8000,0x80008,0x800080,0x800