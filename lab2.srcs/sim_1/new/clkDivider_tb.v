`timescale 1ns / 1ps

module clkDivider_tb;

parameter DIVISOR = 100;

reg clk;
reg RESET;
wire tick;

clkDivider #(
    .DIVISOR(DIVISOR)
) uut (
    .clk(clk),
    .RESET(RESET),
    .tick(tick)
);

initial clk = 0;
always #5 clk = ~clk;

integer tick_count;

initial begin
    RESET = 1;
    tick_count = 0;
    
    #20;
    RESET = 0;
    
    // ТЕСТ 1: Проверка сброса
    if (tick == 1'b0)
        $display("ТЕСТ 1 ПРОЙДЕН: После сброса tick = 0");
    else
        $display("ТЕСТ 1 ПРОВАЛЕН: tick = %b", tick);
    
    // ТЕСТ 2: Ждём несколько импульсов
    repeat (5) begin
        @(posedge tick);
        tick_count = tick_count + 1;
    end
    
    $display("ТЕСТ 2: Получено %d импульсов tick", tick_count);
    $display("Всего тактов clk: ~%d", tick_count * DIVISOR);
    
    $display("\n=== ВСЕ ТЕСТЫ ЗАВЕРШЕНЫ ===");
    $finish;
end

endmodule