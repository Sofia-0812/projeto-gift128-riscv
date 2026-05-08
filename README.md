# Aceleração em Hardware do GIFT-128 no RISC-V (PicoRV32)

Este repositório contém o código-fonte e os ambientes de simulação para o desenvolvimento de uma extensão de conjunto de instruções (ISA) focada na aceleração do algoritmo criptográfico de baixo consumo (LWC) **GIFT-128** em uma arquitetura **RISC-V de 32 bits**.

O projeto tem como objetivo mitigar o elevado custo computacional das etapas `SubCells` (substituição não linear) e `PermBits` (difusão espacial) que ocorre em implementações puramente em software, propondo uma arquitetura de função fixa que funde ambas as operações em um único ciclo combinacional (*in-place update*).

## 🗂️ Estrutura do Repositório

O projeto está dividido em três frentes principais:

* `/hw` **(Hardware):** Contém a descrição em nível RTL (Verilog) do processador. O arquivo principal é o `picorv32.v`, que será modificado para integrar o módulo GIFT-128 ao *Datapath*.
* `/sw` **(Software):** Contém a implementação do algoritmo em linguagem Assembly (`rv32i`). Destaca-se o arquivo `gift128_baseline.S`, utilizado para estabelecer a *baseline* de desempenho puramente em software (extração de ciclos de clock) e validar a corretude da cifra através de vetores de teste oficiais.
* `/sim` **(Simulação):** Contém os *testbenches* em Verilog utilizados para a validação funcional.

## Ferramentas Utilizadas
Para compilar e simular este projeto, são necessárias as seguintes ferramentas da *toolchain* de hardware e software:

* **RISC-V GNU Toolchain** (`riscv64-unknown-elf-gcc`): Para compilação do código Assembly em binários executáveis.
* **Icarus Verilog** (`iverilog`): Para compilação e simulação do design RTL.
* **GTKWave**: Para inspeção visual dos sinais temporais.
* **Yosys**: Para a síntese lógica e extração de custo de área em Gate Equivalents (GE).

## Como Executar a Baseline em Software

1. **Compilar o Software (Assembly):**
   Navegue até a pasta `/sw` e utilize a toolchain do RISC-V para gerar o binário (`.elf`) e o arquivo hexadecimal de memória (`.hex`).
   ```bash
   cd sw
   riscv64-unknown-elf-gcc -nostartfiles -T riscv.ld -o firmware.elf gift128_baseline.S
   riscv64-unknown-elf-objcopy -O verilog firmware.elf firmware.hex

2. **Rodar a Simulação da Baseline:**
   Após gerar o arquivo `.hex`, navegue até a pasta `/sim` e utilize o Icarus Verilog para simular a execução no núcleo original do PicoRV32.
   ```bash
   cd ../sim
   iverilog -o sim_baseline tb_gift128.v ../hw/picorv32.v
   ./sim_baseline
