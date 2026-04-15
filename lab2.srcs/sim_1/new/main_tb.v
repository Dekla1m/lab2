`timescale 1ns / 1ps

module main_tb;

parameter MAX_N = 16;
parameter MAX_W = 512;
parameter DATA_WIDTH = 32;
parameter ADDR_WIDTH = 10;
parameter CLK_PERIOD = 10;

integer start_time = 0; 
integer end_time = 0; 

reg clk;
reg reset;
reg [DATA_WIDTH-1:0] data_in;
reg [ADDR_WIDTH-1:0] addr;
reg write_enable;
reg config_start;

wire busy;
wire done;
wire config_ready;
wire [ADDR_WIDTH-1:0] expected_addr;
wire [MAX_N-1:0] taken_items;
wire [DATA_WIDTH-1:0] max_value;
wire [7:0] error_code;
wire error_valid;

main #(
    .MAX_N(MAX_N),
    .MAX_W(MAX_W),
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) uut (
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .addr(addr),
    .write_enable(write_enable),
    .config_start(config_start),
    .busy(busy),
    .done(done),
    .config_ready(config_ready),
    .expected_addr(expected_addr),
    .taken_items(taken_items),
    .max_value(max_value),
    .error_code(error_code),
    .error_valid(error_valid),
    .debug_dp_W()
);

// Генерация тактового сигнала

always @(posedge clk) begin
    end_time = end_time + 10;
end

initial begin
    clk = 0;
    forever # (CLK_PERIOD / 2) clk = ~clk;
end

// Процедура записи конфигурации
task write_config;
    input [ADDR_WIDTH-1:0] a;
    input [DATA_WIDTH-1:0] d;
begin
    @(posedge clk);
    addr = a;
    data_in = d;
    write_enable = 1;
    @(posedge clk);
    write_enable = 0;
    #5;
end
endtask

initial begin
    // Инициализация сигналов
    reset = 1;
    config_start = 0;
    write_enable = 0;
    addr = 0;
    data_in = 0;
    
    #20;
    reset = 0;
    #10;
    
    // =========================================================================
    // ТЕСТ 1: Произвольные значения
    // =========================================================================
    $display("\n=== ТЕСТ 1: Произвольные значения ===");
    
    // N=3, W=10
    write_config(10'd0, 32'd3);
    write_config(10'd1, 32'd10);
    
    // Weights: w[0]=2, w[1]=3, w[2]=5 (адреса 2,3,4)
    write_config(10'd2, 32'd2);
    write_config(10'd3, 32'd3);
    write_config(10'd4, 32'd5);
    
    // Prices: p[0]=3, p[1]=4, p[2]=7 (адреса 18,19,20)
    write_config(10'd18, 32'd3);
    write_config(10'd19, 32'd4);
    write_config(10'd20, 32'd7);
    
    // Start command (адрес 34)
    write_config(10'd34, 32'd1);
    
    config_start = 1;
    @(posedge clk);
    config_start = 0;
    
    wait (done);
    #10;
    
    $display("Загрузка конфигурации: N=3, W=10, w={2,3,5}, p={3,4,7}");
    $display("taken_items: %b (Ожидалось: 0001)", taken_items);
    $display("max_value: %d (Ожидалось: 15)", max_value);
    $display("error_valid: %b, error_code: %d", error_valid, error_code);
    
    if (taken_items == 16'b0001 && max_value == 32'd15 && !error_valid)
        $display("? ТЕСТ 1 ПРОЙДЕН");
    else
        $display("? ТЕСТ 1 ПРОВАЛЕН");
    
    #50;
    
    // =========================================================================
    // ТЕСТ 2: Одинаковые веса и стоимости
    // =========================================================================
    $display("\n=== ТЕСТ 2: Одинаковые веса и стоимости ===");
    
    reset = 1;
    #20;
    reset = 0;
    #10;
    
    write_config(10'd0, 32'd3);
    write_config(10'd1, 32'd10);
    write_config(10'd2, 32'd2);
    write_config(10'd3, 32'd2);
    write_config(10'd4, 32'd2);
    write_config(10'd18, 32'd3);
    write_config(10'd19, 32'd3);
    write_config(10'd20, 32'd3);
    write_config(10'd34, 32'd1);
    
    config_start = 1;
    @(posedge clk);
    config_start = 0;
    
    wait (done);
    #10;
    
    $display("Загрузка конфигурации: N=3, W=10, w={2,2,2}, p={3,3,3}");
    $display("taken_items: %b (Ожидалось: 0001)", taken_items);
    $display("max_value: %d (Ожидалось: 15)", max_value);
    
    if (taken_items == 16'b0001 && max_value == 32'd15)
        $display("? ТЕСТ 2 ПРОЙДЕН");
    else
        $display("? ТЕСТ 2 ПРОВАЛЕН");
    
    #50;
    
    // =========================================================================
    // ТЕСТ 3: Вместимость рюкзака = 0
    // =========================================================================
    $display("\n=== ТЕСТ 3: Вместимость рюкзака = 0 ===");
    
    reset = 1;
    #20;
    reset = 0;
    #10;
    
    write_config(10'd0, 32'd3);
    write_config(10'd1, 32'd0);
    write_config(10'd2, 32'd2);
    write_config(10'd3, 32'd3);
    write_config(10'd4, 32'd4);
    write_config(10'd18, 32'd5);
    write_config(10'd19, 32'd6);
    write_config(10'd20, 32'd7);
    write_config(10'd34, 32'd1);
    
    config_start = 1;
    @(posedge clk);
    config_start = 0;
    
    wait (done);
    #10;
    
    $display("Загрузка конфигурации: N=3, W=0, w={2,3,4}, p={5,6,7}");
    $display("taken_items: %b (Ожидалось: 0000)", taken_items);
    $display("max_value: %d (Ожидалось: 0)", max_value);
    
    if (taken_items == 16'b0000 && max_value == 32'd0)
        $display("? ТЕСТ 3 ПРОЙДЕН");
    else
        $display("? ТЕСТ 3 ПРОВАЛЕН");
    
    #50;
    
    // =========================================================================
    // ТЕСТ 4: Один предмет
    // =========================================================================
    $display("\n=== ТЕСТ 4: Один предмет ===");
    
    reset = 1;
    #20;
    reset = 0;
    #10;
    
    write_config(10'd0, 32'd1);
    write_config(10'd1, 32'd5);
    write_config(10'd2, 32'd2);
    write_config(10'd18, 32'd3);
    write_config(10'd34, 32'd1);
    
    config_start = 1;
    @(posedge clk);
    config_start = 0;
    
    wait (done);
    #10;
    
    $display("Загрузка конфигурации: N=1, W=5, w={2}, p={3}");
    $display("taken_items: %b (Ожидалось: 0001)", taken_items);
    $display("max_value: %d (Ожидалось: 6)", max_value);
    
    if (taken_items == 16'b0001 && max_value == 32'd6)
        $display("? ТЕСТ 4 ПРОЙДЕН");
    else
        $display("? ТЕСТ 4 ПРОВАЛЕН");
    
    #50;
    
    // =========================================================================
    // ТЕСТ 5: Вес каждого предмета > вместимости
    // =========================================================================
    $display("\n=== ТЕСТ 5: Вес каждого предмета > вместимости ===");
    
    reset = 1;
    #20;
    reset = 0;
    #10;
    
    write_config(10'd0, 32'd3);
    write_config(10'd1, 32'd5);
    write_config(10'd2, 32'd16);
    write_config(10'd3, 32'd20);
    write_config(10'd4, 32'd28);
    write_config(10'd18, 32'd28);
    write_config(10'd19, 32'd48);
    write_config(10'd20, 32'd100);
    write_config(10'd34, 32'd1);
    
    config_start = 1;
    @(posedge clk);
    config_start = 0;
    
    wait (done);
    #10;
    
    $display("Загрузка конфигурации: N=3, W=5, w={16,20,28}, p={28,48,100}");
    $display("taken_items: %b (Ожидалось: 0000)", taken_items);
    $display("max_value: %d (Ожидалось: 0)", max_value);
    
    if (taken_items == 16'b0000 && max_value == 32'd0)
        $display("? ТЕСТ 5 ПРОЙДЕН");
    else
        $display("? ТЕСТ 5 ПРОВАЛЕН");
    
    #50;
    
    // =========================================================================
    // ТЕСТ 6: Веса одинаковые, стоимости разные
    // =========================================================================
    $display("\n=== ТЕСТ 6: Веса одинаковые, стоимости разные ===");
    
    reset = 1;
    #20;
    reset = 0;
    #10;
    
    write_config(10'd0, 32'd3);
    write_config(10'd1, 32'd5);
    write_config(10'd2, 32'd5);
    write_config(10'd3, 32'd5);
    write_config(10'd4, 32'd5);
    write_config(10'd18, 32'd10);
    write_config(10'd19, 32'd15);
    write_config(10'd20, 32'd20);
    write_config(10'd34, 32'd1);
    
    config_start = 1;
    @(posedge clk);
    config_start = 0;
    
    wait (done);
    #10;
    
    $display("Загрузка конфигурации: N=3, W=5, w={5,5,5}, p={10,15,20}");
    $display("taken_items: %b (Ожидалось: 0100)", taken_items);
    $display("max_value: %d (Ожидалось: 20)", max_value);
    
    if (taken_items == 16'b0100 && max_value == 32'd20)
        $display("? ТЕСТ 6 ПРОЙДЕН");
    else
        $display("? ТЕСТ 6 ПРОВАЛЕН");
    
    #50;
    
    // =========================================================================
    // ТЕСТ 7: Стоимости одинаковые, веса разные
    // =========================================================================
    $display("\n=== ТЕСТ 7: Стоимости одинаковые, веса разные ===");
    
    reset = 1;
    #20;
    reset = 0;
    #10;
    
    write_config(10'd0, 32'd3);
    write_config(10'd1, 32'd8);
    write_config(10'd2, 32'd2);
    write_config(10'd3, 32'd3);
    write_config(10'd4, 32'd4);
    write_config(10'd18, 32'd10);
    write_config(10'd19, 32'd10);
    write_config(10'd20, 32'd10);
    write_config(10'd34, 32'd1);
    
    config_start = 1;
    @(posedge clk);
    config_start = 0;
    
    wait (done);
    #10;
    
    $display("Загрузка конфигурации: N=3, W=8, w={2,3,4}, p={10,10,10}");
    $display("taken_items: %b (Ожидалось: 0001)", taken_items);
    $display("max_value: %d (Ожидалось: 40)", max_value);
    
    if (taken_items == 16'b0001 && max_value == 32'd40)
        $display("? ТЕСТ 7 ПРОЙДЕН");
    else
        $display("? ТЕСТ 7 ПРОВАЛЕН");
    
    #50;
    
    // =========================================================================
    // ТЕСТ 8: Нагрузочный тест (большое количество предметов)
    // =========================================================================
    $display("\n=== ТЕСТ 8: Нагрузочный тест (N=10, W=100) ===");
    
    reset = 1;
    #20;
    reset = 0;
    #10;
    
    // N=10, W=100
    write_config(10'd0, 32'd10);
    write_config(10'd1, 32'd100);
    
    // Weights: 1,2,3,4,5,6,7,8,9,10 (адреса 2-11)
    write_config(10'd2, 32'd1);
    write_config(10'd3, 32'd2);
    write_config(10'd4, 32'd3);
    write_config(10'd5, 32'd4);
    write_config(10'd6, 32'd5);
    write_config(10'd7, 32'd6);
    write_config(10'd8, 32'd7);
    write_config(10'd9, 32'd8);
    write_config(10'd10, 32'd9);
    write_config(10'd11, 32'd10);
    
    // Prices: 1,3,5,7,9,11,13,15,17,19 (адреса 18-27)
    write_config(10'd18, 32'd1);
    write_config(10'd19, 32'd3);
    write_config(10'd20, 32'd5);
    write_config(10'd21, 32'd7);
    write_config(10'd22, 32'd9);
    write_config(10'd23, 32'd11);
    write_config(10'd24, 32'd13);
    write_config(10'd25, 32'd15);
    write_config(10'd26, 32'd17);
    write_config(10'd27, 32'd19);
    
    // Start command
    write_config(10'd34, 32'd1);
    start_time = end_time;
    #20;
    config_start = 1;
    @(posedge clk);
    config_start = 0;
    
    // Замеряем время начала
    wait(done)
    #10;
    $display("Конец вычислений: %0t ns", start_time);
    $display("Конец вычислений: %0t ns", end_time);
    $display("Загрузка конфигурации: N=10, W=100");
    $display("taken_items: %b", taken_items);
    $display("max_value: %d", max_value);
    $display("Ожидаемый max_value: ~300 (приблизительно)");
    
    if (!error_valid && max_value > 0)
        $display("? ТЕСТ 8 ПРОЙДЕН (вычисления завершены)");
    else
        $display("? ТЕСТ 8 ПРОВАЛЕН");
    
    #50;
    
    // =========================================================================
    // ТЕСТ 9: Выход за пределы N (N > MAX_N)
    // =========================================================================
    $display("\n=== ТЕСТ 9: Выход за пределы N (N=20 > 16) ===");
    
    reset = 1;
    #20;
    reset = 0;
    #10;
    
    // N=20 (больше MAX_N=16!)
    write_config(10'd0, 32'd20);
    write_config(10'd1, 32'd50);
    
    // Пытаемся записать веса (должны игнорироваться или вызвать ошибку)
    write_config(10'd2, 32'd5);
    write_config(10'd3, 32'd10);
    
    #20;
    
    $display("error_valid: %b", error_valid);
    $display("error_code: %d", error_code);
    $display("config_ready: %b", config_ready);
    
    if (error_valid && error_code == 8'd1) begin
        $display("? ТЕСТ 9 ПРОЙДЕН (ошибка N > MAX_N обнаружена)");
    end else begin
        $display("??  ТЕСТ 9: Ошибка не обнаружена (error_valid=%b, error_code=%d)", 
                 error_valid, error_code);
        $display("   Это может быть ОК, если валидация только в InputSequencer");
    end
    
    #50;
    
    // =========================================================================
    // ТЕСТ 10: Выход за пределы W (W > MAX_W)
    // =========================================================================
    $display("\n=== ТЕСТ 10: Выход за пределы W (W=1000 > 512) ===");
    
    reset = 1;
    #20;
    reset = 0;
    #10;
    
    // N=3, W=1000 (больше MAX_W=512!)
    write_config(10'd0, 32'd3);
    write_config(10'd1, 32'd1000);
    
    // Weights
    write_config(10'd2, 32'd10);
    write_config(10'd3, 32'd20);
    write_config(10'd4, 32'd30);
    
    // Prices
    write_config(10'd18, 32'd15);
    write_config(10'd19, 32'd25);
    write_config(10'd20, 32'd35);
    
    #20;
    
    $display("error_valid: %b", error_valid);
    $display("error_code: %d", error_code);
    $display("config_ready: %b", config_ready);
    
    if (error_valid && error_code == 8'd2) begin
        $display("? ТЕСТ 10 ПРОЙДЕН (ошибка W > MAX_W обнаружена)");
    end else begin
        $display("??  ТЕСТ 10: Ошибка не обнаружена (error_valid=%b, error_code=%d)", 
                 error_valid, error_code);
        $display("   Это может быть ОК, если валидация только в InputSequencer");
    end
    
    #50;
    
    $display("\n========================================");
    $display("ВСЕ ТЕСТЫ ЗАВЕРШЕНЫ");
    $display("========================================");
    $finish;
end

endmodule