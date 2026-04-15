module FilterDreb_tb();

reg clk;
localparam RELEASE = 0;
localparam PRESS = 1;
reg IN_SIGNAL; 
wire OUT_SIGNAL_ENABLE, OUT_SIGNAL;

initial IN_SIGNAL = 0;
initial clk = 0;
always #5 clk <= ~clk;

FilterDreb #(3) btn_dreb_filter(
    .CLK(clk),
    .CLOCK_ENABLE(1),
    .IN_SIGNAL(IN_SIGNAL),
    .OUT_SIGNAL_ENABLE(OUT_SIGNAL_ENABLE),
    .OUT_SIGNAL(OUT_SIGNAL)
);

initial
begin
    test_filter_1();
    test_filter_2();
    test_filter_3();    
    
    $srandom(33985);
    repeat($urandom_range(150, 0))
    begin
        IN_SIGNAL <= $random;
        #10;
    end
end


task send_signal_to_filter;
    input signal_in;
    input [4:0] ticks;
begin
    @(posedge clk);
    IN_SIGNAL <= signal_in;
    $display("[%0t]: Сигнал %b подан на линию.", $time, signal_in);
    repeat(ticks) @(posedge clk);
    IN_SIGNAL <= 0;
    $display("[%0t]: Сигнал %b убран с линии, подан сигнал 0", $time, signal_in);
end
endtask

task test_filter_1;
reg test_result;
begin
    $display("\n[%0t]: Тест 1. Реакция фильтра дребезга на сигнал высокого уровня на шине физ. манипулятора.", $time);
    $display("[%0t]: (время удержания сигнала соответствует требуемому)", $time);
    send_signal_to_filter(PRESS, 8);
    repeat(3) @(posedge clk); test_result <= (OUT_SIGNAL_ENABLE == 1'b1);
    send_signal_to_filter(RELEASE, 8);
    test_info(1, test_result);
end
endtask

task test_filter_2;
reg test_result;
begin
    $display("\n[%0t]: Тест 2. Реакция фильтра дребезга на сигнал высокого уровня на шине физ. манипулятора.", $time);
    $display("[%0t]: (время удержания сигнала меньше требуемого)", $time);
    send_signal_to_filter(PRESS, 7);
    // ждём два такта так как из-за синхронизатора происходит задержка
    repeat(3) @(posedge clk); test_result = (OUT_SIGNAL_ENABLE == 1'b0);
    test_info(2, test_result);
end
endtask

task test_filter_3;
reg test_result;
begin
    $display("\n[%0t]: Тест 3. Реакция фильтра дребезга на сигнал низкого уровня на шине физ. манипулятора.", $time);
    send_signal_to_filter(RELEASE, 8);
    repeat(3) @(posedge clk); test_result = (OUT_SIGNAL_ENABLE == 1'b0);
    test_info(3, test_result);
end
endtask

task test_info;
    input integer test_number;
    input test_result;
begin    
    if (test_result)
        $display("[%0t]: Тест %0d пройден.", $time, test_number);
    else
        $display("[%0t]: Тест %0d НЕ пройден.", $time, test_number);
end
endtask

endmodule
