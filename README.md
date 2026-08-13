# Aceleração em Hardware do GIFT-128 no RISC-V (PicoRV32)

Este repositório contém o código-fonte e os ambientes de simulação para o desenvolvimento de uma extensão de conjunto de instruções focada na aceleração do algoritmo criptográfico de baixo consumo (LWC) **GIFT-128** em uma arquitetura **RISC-V de 32 bits**. O projeto tem como objetivo mitigar o elevado custo computacional das etapas `SubCells` (substituição não linear) e `PermBits` (difusão espacial) que ocorre em implementações puramente em software.

## Estrutura do Repositório

O projeto está dividido em três frentes principais dentro da pasta `/Codigo`:

* **/hw (Hardware):** Contém a descrição em nível RTL (Verilog) do processador original (`picorv32.v`), do módulo em hardware especializado (`gift128_module.v`) e do processador modificado para integrar o módulo GIFT-128 ao *Datapath* (`picorv32_altered.v`). 
* **/sw (Software):** Contém as implementações do algoritmo em linguagem Assembly (`rv32i`). Destaca-se o arquivo `gift128_baseline.S`, utilizado para estabelecer a *baseline* de desempenho puramente em software (extração de ciclos de clock) e validar a corretude da cifra através de vetores de teste oficiais. O arquivo `gift128_custom.S` contém a implementação otimizada, fazendo uso das novas instruções customizadas (via diretiva `.insn`) para utilizar o acelerador em hardware.
* **/sim (Simulação):** Contém os *testbenches* em Verilog utilizados para a validação funcional e extração de métricas de desempenho (`tb_gift128_baseline.v`, `tb_gift128_custom.v` e `testbench_ez.v`).

## Ferramentas Utilizadas
Para compilar e simular este projeto, são necessárias as seguintes ferramentas da *toolchain* de hardware e software:

* **RISC-V GNU Toolchain** (`riscv64-unknown-elf-gcc`): Para compilação do código Assembly em binários executáveis.
* **Icarus Verilog** (`iverilog`): Para compilação e simulação do design RTL.
* **Yosys**: Para a síntese lógica e extração de custo de área em *Gate Equivalents* (GE).

## Como Executar a Baseline em Software
Navegue até a pasta `/Codigo` e rode a sequencia:

1. Compila o Assembly Baseline:
```bash
riscv64-unknown-elf-gcc -c -march=rv32i -mabi=ilp32 -o sw/firmware_baseline.o sw/gift128_baseline.S
```

2. Linka com o mapa de memória (`riscv.ld`):
```bash
riscv64-unknown-elf-ld -m elf32lriscv -T sw/riscv.ld -o sw/firmware_baseline.elf sw/firmware_baseline.o
```

3. Converte para `.hex` (Verilog format):
```bash
riscv64-unknown-elf-objcopy -O verilog sw/firmware_baseline.elf sw/firmware_baseline.hex
```

4. Compila o hardware com o testbench baseline:
```bash
iverilog -o sim/sim_baseline hw/picorv32.v sim/tb_gift128_baseline.v
```

5. Executa a simulação:
```bash
vvp sim/sim_baseline
```

## Como Executar o Conjunto Customizado (Com Extensão de Hardware) 
Navegue até a pasta `/Codigo` e rode a sequencia:

 1. Compila o Assembly Custom:
```bash
riscv64-unknown-elf-gcc -c -march=rv32i -mabi=ilp32 -o sw/firmware_custom.o sw/gift128_custom.S
```

2. Linka com o mapa de memória (`riscv.ld`):
```bash
riscv64-unknown-elf-ld -m elf32lriscv -T sw/riscv.ld -o sw/firmware_custom.elf sw/firmware_custom.o
```

3. Converte para `.hex` (Verilog format):
```bash
riscv64-unknown-elf-objcopy -O verilog sw/firmware_custom.elf sw/firmware_custom.hex
```

4. Compila o hardware com o testbench custom:
```bash
iverilog -o sim/sim_custom hw/picorv32_altered.v hw/gift128_module.v sim/tb_gift128_custom.v
```

5. Executa a simulação:
```bash
vvp sim/sim_custom
```
