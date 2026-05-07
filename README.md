 GIFT-128 RISC-V Instruction Set Extension

Este repositório contém a implementação de uma extensão customizada do conjunto de instruções (ISA) RISC-V projetada para acelerar a cifra de bloco **GIFT-128**. O objetivo principal é otimizar as etapas de *SubCells* e *PermBits* através de uma única instrução de hardware, reduzindo drasticamente a contagem de ciclos em comparação com implementações puramente em software.

## 📌 Contexto e Intuito
O projeto nasceu da necessidade de viabilizar criptografia forte em dispositivos com recursos limitados (IoT). Identificamos que as operações de permutação de bits e substituição por S-Box são os maiores gargalos no RISC-V de 32 bits (RV32I). 

A solução proposta funde essas duas etapas em um módulo combinacional integrado diretamente ao *datapath* do processador, permitindo que uma transformação complexa de 128 bits seja resolvida em hardware enquanto o processador gerencia o fluxo de dados.

## 📂 Organização do Repositório

O desenvolvimento foi dividido em três frentes principais, refletidas nas pastas deste repositório:

### 1. Hardware (`/hw`)
Contém os arquivos de descrição de hardware (Verilog/VHDL) que compõem o sistema

### 2. Software (`/sw`)
Arquivos relacionados à execução e teste no processador:
* **Baseline em Assembly:** Implementação ingênua do GIFT-128 em Assembly RISC-V puro para métricas de comparação.
* **Firmware de Teste:** Código que utiliza as instruções customizadas para validar o processamento do hardware.
* **Linker Scripts:** Configurações de memória para o ambiente do PicoRV32.

### 3. Simulação (`/sim`)
Ambiente de validação e verificação:
* **Testbenches:** Arquivos para estimular o hardware e verificar a corretude dos resultados frente aos vetores de teste oficiais do GIFT-128.
* **Scripts de Automação:** Ferramentas para rodar o Icarus Verilog e gerar arquivos de formas de onda (.vcd).

## 🛠 Como o Projeto foi Construído

1. **Design Lógico:** O módulo foi desenhado para processar 128 bits internamente, utilizando uma interface de carga sequencial (4x 32 bits) para se adequar ao barramento do RV32I.
2. **Modificação do Datapath:** Expandimos a Unidade de Controle do PicoRV32 para reconhecer novos Opcodes customizados.
3. **Validação:** Utilizamos o **Icarus Verilog** para simulação RTL e o **GTKWave** para análise dos sinais, garantindo que a integração não quebrasse as instruções nativas do processador.

---
*Projeto desenvolvido como parte do curso de Ciência da Computação - PUC Minas.*
