`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: top_tb
// Description: Детальный тестбенч для top модуля
//              - Ввод с клавиатуры (цифра + Enter)
//              - Проверка автопереключения дисплея
//              - Проверка ошибок валидации
//              - Проверка сброса
//////////////////////////////////////////////////////////////////////////////////

module top_tb;

// ============================================================================
// СИГНАЛЫ ТЕСТБЕНЧА
// ============================================================================
reg clk;
reg PS2_clk;
reg PS2_dat;
reg btn_reset;

wire [7:0] SEG_AN;
wire [6:0] SEG_CAT;

// Сигналы для отладки (через иерархию)
wire [3:0] ps2_digit;
wire [1:0] ps2_flags;
wire [31:0] seq_display_buffer;
wire seq_input_error;
wire [7:0] seq_error_code;
wire main_config_ready;
wire main_done;
wire main_busy;
wire [15:0] main_taken_items;
wire [31:0] main_max_value;
wire main_error_valid;
wire [7:0] main_error_code;
wire [31:0] display_data;
wire show_result;

integer i;

initial begin
    clk = 0;
    forever #10 clk = ~clk;  // 50 MHz
end

initial begin
    PS2_clk = 1;
    forever #5000 PS2_clk = ~PS2_clk;  // ~100 kHz для симуляции
end

// ============================================================================
// ПОДКЛЮЧЕНИЕ МОДУЛЯ top
// ============================================================================
top uut (
    .clk(clk),
    .btn_reset(btn_reset),
    .PS2_clk(PS2_clk),
    .PS2_dat(PS2_dat),
    .SEG_AN(SEG_AN),
    .SEG_CAT(SEG_CAT)
);

// ============================================================================
// ОТЛАДОЧНЫЕ СИГНАЛЫ (иерархический доступ)
// ============================================================================

// PS2
assign ps2_digit = uut.u_ps2_dc.out;
assign ps2_flags = uut.u_ps2_dc.flags;

// InputSequencer
assign seq_display_buffer = uut.u_input_seq.display_buffer;
assign seq_input_error = uut.u_input_seq.input_error;
assign seq_error_code = uut.u_input_seq.error_code;

// main
assign main_config_ready = uut.u_main.config_ready;
assign main_done = uut.u_main.done;
assign main_busy = uut.u_main.busy;
assign main_taken_items = uut.u_main.taken_items;
assign main_max_value = uut.u_main.max_value;
assign main_error_valid = uut.u_main.error_valid;
assign main_error_code = uut.u_main.error_code;

// Логика отображения внутри top (если есть такой регистр)
// Если нет - можно добавить в top.v: output reg show_result;
// assign show_result = uut.show_result;

// ============================================================================
// ЗАДАЧА ОТПРАВКИ СКАН-КОДА (упрощённая для симуляции)
// ============================================================================
task send_ps2_key;
    input [7:0] scan_code;
    integer i;
    reg parity;
    begin
        // Start bit
        @(negedge PS2_clk);
        PS2_dat = 0;
        #2500;
        
        // 8 бит данных (LSB first)
        parity = 1;
        for (i = 0; i < 8; i = i + 1) begin
            @(negedge PS2_clk);
            PS2_dat = scan_code[i];
            parity = parity ^ scan_code[i];
            #2500;
        end
        
        // Parity bit
        @(negedge PS2_clk);
        PS2_dat = parity;
        #2500;
        
        // Stop bit
        @(negedge PS2_clk);
        PS2_dat = 1;
        #2500;
        
        // Возврат в idle
        @(posedge PS2_clk);
        PS2_dat = 1;
        #5000;
    end
endtask

// ============================================================================
// ОБЁРТКИ ДЛЯ УДОБСТВА
// ============================================================================
task send_digit;
    input [3:0] digit;
    begin
        case(digit)
            4'h0: send_ps2_key(8'h45);
            4'h1: send_ps2_key(8'h16);
            4'h2: send_ps2_key(8'h1E);
            4'h3: send_ps2_key(8'h26);
            4'h4: send_ps2_key(8'h25);
            4'h5: send_ps2_key(8'h2E);
            4'h6: send_ps2_key(8'h36);
            4'h7: send_ps2_key(8'h3D);
            4'h8: send_ps2_key(8'h3E);
            4'h9: send_ps2_key(8'h46);
            4'hA: send_ps2_key(8'h1C);
            4'hB: send_ps2_key(8'h32);
            4'hC: send_ps2_key(8'h21);
            4'hD: send_ps2_key(8'h23);
            4'hE: send_ps2_key(8'h24);
            4'hF: send_ps2_key(8'h2B);
            default: $display("WARNING: Неизвестная цифра %h", digit);
        endcase
        #1000;  // Пауза между нажатиями
    end
endtask

task send_enter;
    begin
        send_ps2_key(8'h5A);  // Enter
        #1000;
    end
endtask

task send_backspace;
    begin
        send_ps2_key(8'h66);  // Backspace
        #1000;
    end
endtask

// ============================================================================
// ОСНОВНОЙ БЛОК ТЕСТОВ
// ============================================================================
initial begin
    $dumpfile("top_tb.vcd");
    $dumpvars(0, top_tb);
    
    // Инициализация
    PS2_dat = 1;
    btn_reset = 0;
    
    // Сброс системы
    #50;
    btn_reset = 1;
    #100;
    btn_reset = 0;
    #100;
    
    // Ждём готовности к вводу
    wait(main_config_ready);
    #100;
    
    // =========================================================================
    // ТЕСТ 1: Полный цикл ввода и проверка результата
    // =========================================================================
    $display("\n=== ТЕСТ 1: Полный цикл ввода (N=2, W=5) ===");
    
    // Ввод N = 2
    $display("Ввод: N = 2");
    send_digit(4'h2);
    send_enter();
    
    // Проверка: буфер ввода показывает 2
    if (seq_display_buffer[3:0] == 4'h2) begin
        $display("? Буфер ввода: %h (OK)", seq_display_buffer[3:0]);
    end else begin
        $error("? Буфер ввода: %h (ожидалось 2)", seq_display_buffer[3:0]);
    end
    
    // Ввод W = 5
    $display("Ввод: W = 5");
    send_digit(4'h5);
    send_enter();
    
    // Ввод весов: w[0]=1, w[1]=3
    $display("Ввод: Weight[0] = 1");
    send_digit(4'h1);
    send_enter();
    
    $display("Ввод: Weight[1] = 3");
    send_digit(4'h3);
    send_enter();
    
    // Ввод цен: p[0]=1, p[1]=4
    $display("Ввод: Price[0] = 1");
    send_digit(4'h1);
    send_enter();
    
    $display("Ввод: Price[1] = 4");
    send_digit(4'h4);
    send_enter();
    
    // Финальный Enter - запуск вычислений
    $display("Запуск вычислений (Enter)...");
    send_enter();
    
    // Проверка: началось вычисление
    #100;
    if (main_busy) begin
        $display("? Вычисление началось (busy=1)");
    end else begin
        $error("? Вычисление НЕ началось (busy=0)");
    end
    
    // Ждём завершения
    wait(main_done);
    #200;
    
    // Проверка результата
    $display("\n--- Проверка результата ---");
    $display("max_value = %d (ожидалось 5)", main_max_value);
    $display("taken_items = %b (ожидалось 0001)", main_taken_items[3:0]);
    
    if (main_max_value == 32'd5) begin
        $display("? max_value: PASS");
    end else begin
        $error("? max_value: FAIL");
    end
    
    if (main_taken_items[3:0] == 4'b0001) begin
        $display("? taken_items: PASS");
    end else begin
        $error("? taken_items: FAIL");
    end
    
    // =========================================================================
    // ТЕСТ 2: Проверка Backspace
    // =========================================================================
    $display("\n=== ТЕСТ 2: Проверка Backspace ===");
    
    // Сброс и новый ввод
    btn_reset = 1;
    #50;
    btn_reset = 0;
    wait(main_config_ready);
    #100;
    
    // Ввод "23", затем Backspace ? должно остаться "2"
    send_digit(4'h2);
    send_digit(4'h3);
    #100;
    
    $display("После ввода '23': display_buffer = %h", seq_display_buffer[7:0]);
    
    send_backspace();
    #100;
    
    $display("После Backspace: display_buffer = %h (ожидалось 2)", seq_display_buffer[3:0]);
    
    if (seq_display_buffer[3:0] == 4'h2) begin
        $display("? Backspace: PASS");
    end else begin
        $error("? Backspace: FAIL");
    end
    
    // =========================================================================
    // ТЕСТ 3: Ошибка валидации (N > MAX_N)
    // =========================================================================
    $display("\n=== ТЕСТ 3: Ошибка валидации (N=20 > 16) ===");
    
    btn_reset = 1;
    #50;
    btn_reset = 0;
    wait(main_config_ready);
    #100;
    
    // Ввод N = 20 (0x14)
    send_digit(4'h1);
    send_digit(4'h4);
    send_enter();
    #200;
    
    $display("input_error = %b", seq_input_error);
    $display("error_code = %d", seq_error_code);
    
    if (seq_input_error && seq_error_code == 8'd1) begin
        $display("? Ошибка N > MAX_N: PASS");
    end else begin
        $error("? Ошибка N > MAX_N: FAIL");
    end
    
    // =========================================================================
    // ТЕСТ 4: Ошибка валидации (W > MAX_W)
    // =========================================================================
    $display("\n=== ТЕСТ 4: Ошибка валидации (W=600 > 512) ===");
    
    btn_reset = 1;
    #50;
    btn_reset = 0;
    wait(main_config_ready);
    #100;
    
    // N = 2
    send_digit(4'h2);
    send_enter();
    
    // W = 600 (0x258)
    send_digit(4'h2);
    send_digit(4'h5);
    send_digit(4'h8);
    send_enter();
    #200;
    
    $display("input_error = %b", seq_input_error);
    $display("error_code = %d", seq_error_code);
    
    if (seq_input_error && seq_error_code == 8'd2) begin
        $display("? Ошибка W > MAX_W: PASS");
    end else begin
        $error("? Ошибка W > MAX_W: FAIL");
    end
    
    // =========================================================================
    // ТЕСТ 5: Большой тест (N=5, W=50)
    // =========================================================================
    $display("\n=== ТЕСТ 5: Нагрузочный тест (N=5, W=50) ===");
    
    btn_reset = 1;
    #50;
    btn_reset = 0;
    wait(main_config_ready);
    #100;
    
    // N=5, W=50
    send_digit(4'h5); send_enter();
    send_digit(4'h3); send_digit(4'h2); send_enter();  // 0x32 = 50
    
    // Weights: 5, 10, 15, 20, 25
    send_digit(4'h5); send_enter();
    send_digit(4'h1); send_digit(4'h0); send_enter();
    send_digit(4'h1); send_digit(4'h5); send_enter();
    send_digit(4'h2); send_digit(4'h0); send_enter();
    send_digit(4'h2); send_digit(4'h5); send_enter();
    
    // Prices: 10, 20, 30, 40, 50
    send_digit(4'h1); send_digit(4'h0); send_enter();
    send_digit(4'h2); send_digit(4'h0); send_enter();
    send_digit(4'h3); send_digit(4'h0); send_enter();
    send_digit(4'h4); send_digit(4'h0); send_enter();
    send_digit(4'h5); send_digit(4'h0); send_enter();
    
    // Запуск
    send_enter();
    
    // Ждём завершения (может занять время)
    wait(main_done);
    #200;
    
    $display("max_value = %d", main_max_value);
    $display("taken_items = %h", main_taken_items[7:0]);
    
    if (main_max_value > 0 && !main_error_valid) begin
        $display("? Нагрузочный тест: PASS (вычисления завершены)");
    end else begin
        $error("? Нагрузочный тест: FAIL");
    end
    
    // =========================================================================
    // ЗАВЕРШЕНИЕ
    // =========================================================================
    $display("\n========================================");
    $display("ВСЕ ТЕСТЫ ЗАВЕРШЕНЫ");
    $display("========================================");
    
    #100;
    $finish;
end

endmodule