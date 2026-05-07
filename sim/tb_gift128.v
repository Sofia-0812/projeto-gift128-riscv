module tb_gift128;
    reg clk = 0;
    reg resetn = 0;
    wire trap; // Adicionado sinal de trap
    
    // Cria um relógio (clock) simulado (10ns período -> 100MHz)
    always #5 clk = ~clk; 

    initial begin
        // Cria o arquivo de ondas para vermos no GTKWave depois
        $dumpfile("sim/ondas.vcd"); 
        $dumpvars(0, tb_gift128);
        
        // Tira o processador do Reset
        #100 resetn = 1;
        
        // Aguarda o processador sinalizar o fim (trap)
        wait(trap);
        // Pequeno atraso para garantir que os últimos registradores sejam atualizados
        #20;
        
        // IMPRIME OS REGISTRADORES S0, S1, S2 e S3 DIRETO NO TERMINAL!
        $display("========================================");
        $display("RESULTADO DA CRIPTOGRAFIA (GIFT-128):");
        $display("s0 (Reg 8)  : %h", uut.cpuregs[8]);
        $display("s1 (Reg 9)  : %h", uut.cpuregs[9]);
        $display("s2 (Reg 18) : %h", uut.cpuregs[18]);
        $display("s3 (Reg 19) : %h", uut.cpuregs[19]);
        $display("----------------------------------------");
        $display("MÉTRICAS DE DESEMPENHO:");
        // s10 contém o total de ciclos
        $display("Ciclos totais: %d", uut.cpuregs[26]); 
        $display("========================================");

        $display("Simulacao finalizada!");
        $finish;
    end

    // Fios para conectar a CPU na Memória
    wire mem_valid;
    wire mem_instr;
    reg mem_ready;
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [3:0] mem_wstrb;
    reg [31:0] mem_rdata;

    // Colocando o PicoRV32 
    picorv32 uut (
        .clk(clk),
        .resetn(resetn),
        .trap(trap),       // Conectado o sinal de trap
        .mem_valid(mem_valid),
        .mem_instr(mem_instr),
        .mem_ready(mem_ready),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_wstrb(mem_wstrb),
        .mem_rdata(mem_rdata)
    );

    // Criando a Memória RAM e carregando o Hexadecimal
    reg [7:0] memory [0:65535];
    initial $readmemh("sw/firmware.hex", memory);

    // Regras de como a Memória responde à CPU
    always @(posedge clk) begin
        mem_ready <= 0;
        if (mem_valid && !mem_ready) begin
            if (mem_wstrb == 0) begin // CPU Lendo
                // Junta 4 bytes para formar os 32 bits (PicoRV32 usa Little-Endian)
                mem_rdata <= {memory[mem_addr+3], memory[mem_addr+2], memory[mem_addr+1], memory[mem_addr]};
                mem_ready <= 1;
            end else begin // CPU Escrevendo
                if (mem_wstrb[0]) memory[mem_addr]   <= mem_wdata[ 7: 0];
                if (mem_wstrb[1]) memory[mem_addr+1] <= mem_wdata[15: 8];
                if (mem_wstrb[2]) memory[mem_addr+2] <= mem_wdata[23:16];
                if (mem_wstrb[3]) memory[mem_addr+3] <= mem_wdata[31:24];
                mem_ready <= 1;
            end
        end
    end
endmodule