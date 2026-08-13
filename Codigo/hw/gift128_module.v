module gift128_module (
    input clk,
    input load_enable,
    input execute_enable,
    input [1:0] imm_sel, // Seletor do MUX/DEMUX (Valor imediato)
    input [31:0] rs1_data, // Dado vindo do processador
    output reg [31:0] rd_data // Dado voltando para o processador
);

    // O Buffer Interno de 128 bits
    
    reg [31:0] buffer [0:3];
    wire [127:0] estado_atual = {buffer[0], buffer[1], buffer[2], buffer[3]};
    
    // Fios intermediários

    wire [127:0] estado_subcells;
    wire [127:0] estado_futuro;

    // MUX Interno (Roteamento de Leitura)

    always @(*) begin
        case(imm_sel)
            2'b00: rd_data = buffer[0];
            2'b01: rd_data = buffer[1];
            2'b10: rd_data = buffer[2];
            2'b11: rd_data = buffer[3];
        endcase
    end

    // Atualização Síncrona do Buffer (Load e Execute)

    always @(posedge clk) begin

        // DEMUX Interno (Roteamento de Carga)

        if (load_enable) begin
            case (imm_sel)
                2'b00: buffer[0] <= rs1_data; // Escreve no 1º quarto do buffer
                2'b01: buffer[1] <= rs1_data; // Escreve no 2º quarto do buffer
                2'b10: buffer[2] <= rs1_data; // Escreve no 3º quarto do buffer
                2'b11: buffer[3] <= rs1_data; // Escreve no 4º quarto do buffer
            endcase
        end

        // Atualização In-Place 

        else if (execute_enable) begin
            {buffer[0], buffer[1], buffer[2], buffer[3]} <= estado_futuro; 
        end  
    end

    
    // Núcleo de Processamento: SubCells + PermBits

    // SubCells (32 S-Boxes em paralelo usando generate)

    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : sbox_inst
            wire I0 = estado_atual[(i*4) + 0];
            wire I1 = estado_atual[(i*4) + 1];
            wire I2 = estado_atual[(i*4) + 2];
            wire I3 = estado_atual[(i*4) + 3];

            // Equações lógicas da S-Box (XNOR representado por ~(a ^ b))

            wire w1 = ~(I1 ^ ~(I0 & I2));
            wire w2 = ~(I0 ^ ~(w1 & I3));
            wire w3 = ~(I2 ^ ~(w2 | w1));
            wire w4 = ~(I3 ^ w3);
            wire w5 = ~(w1 ^ w4);
            wire w6 = ~(w3 ^ ~(w2 & w5));

            // Atribuição de saída

            assign estado_subcells[(i*4) + 3] = w2; // O3
            assign estado_subcells[(i*4) + 2] = w6; // O2
            assign estado_subcells[(i*4) + 1] = w5; // O1
            assign estado_subcells[(i*4) + 0] = w4; // O0
        end
    endgenerate

    // PermBits (Hardwiring / Roteamento Físico)

    // Função geradora da permutação P(i) do GIFT-128.
    // Em tempo de síntese lógica, essa função é usada para inferir as conexões elétricas 
    // diretas (hardwiring) entre os terminais. O resultado é uma rede de roteamento estrutural 
    // de latência zero, sem consumo de portas lógicas.

    function integer calc_perm_128;
        input integer i;
        begin
            calc_perm_128 = 4 * (i / 16) + 32 * (((3 * ((i % 16) / 4)) + (i % 4)) % 4) + (i % 4);
        end
    endfunction

    // Bloco de geração para a instanciação estrutural da fiação

    genvar bit_idx;
    generate
        for (bit_idx = 0; bit_idx < 128; bit_idx = bit_idx + 1) begin : perm_bits_loop
            assign estado_futuro[calc_perm_128(bit_idx)] = estado_subcells[bit_idx];
        end
    endgenerate

endmodule