`timescale 1ns / 1ps

module PS2_Manager_tb;

// Сигналы тестбенча
reg clk;
reg PS2_dat;
reg PS2_clk;

wire R_O;
wire [3:0] out;
wire [1:0] flags;

// Инстанс тестируемого модуля
PS2_Manager uut (
    .clk(clk),
    .PS2_dat(PS2_dat),
    .PS2_clk(PS2_clk),
    .R_O(R_O),
    .out(out),
    .flags(flags)
);

// Генерация тактового сигнала (период 10 ns = 100 MHz)
initial clk = 0;
always #5 clk = ~clk;

// Инициализация сигналов PS2
initial begin
    PS2_clk = 1;
    PS2_dat = 1;
end

// =========================================================
// РЕГИСТРЫ-ЗАЩЁЛКИ ДЛЯ ФИКСАЦИИ СОБЫТИЙ
// =========================================================
reg R_O_captured;        // Флаг: был ли зафиксирован импульс R_O
reg [3:0] captured_out;  // Значение out в момент R_O
reg [1:0] captured_flags;// Значение flags в момент R_O

// Логика захвата: срабатывает по фронту clk, если R_O == 1
always @(posedge clk) begin
    if (R_O) begin
        R_O_captured <= 1;
        captured_out <= out;
        captured_flags <= flags;
    end
end

// Задача для сброса защёлок перед каждым тестом
task reset_capture;
    begin
        R_O_captured = 0;
        captured_out = 0;
        captured_flags = 0;
    end
endtask

// Имитация передачи байта по протоколу
task send_ps2_byte;
    input [7:0] data;
    integer i;
    reg parity;
    begin
        parity = ~(^data); // Нечётная чётность
        
        repeat(5) @(posedge clk);
        
        // Старт-бит
        PS2_dat = 0;
        #10 PS2_clk = 0;
        #40 PS2_clk = 1;
        
        // 8 бит данных (LSB first)
        for (i = 0; i < 8; i = i + 1) begin
            PS2_dat = data[i];
            #10 PS2_clk = 0;
            #40 PS2_clk = 1;
        end
        
        // Бит чётности
        PS2_dat = parity;
        #10 PS2_clk = 0;
        #40 PS2_clk = 1;
        
        // Стоп-бит
        PS2_dat = 1;
        #10 PS2_clk = 0;
        #40 PS2_clk = 1;
        
        repeat(5) @(posedge clk);
    end
endtask
// =========================================================
// ЗАПУСК ТЕСТОВ
// =========================================================
initial begin
    // Инициализация защёлок
    reset_capture;
    repeat(10) @(posedge clk);

    // ------------------------------------------------------
    // ТЕСТ 1: Нажатие цифры '1' (код 8'h16)
    // Ожидаем: R_O_captured=1, captured_out=1, captured_flags[0]=1
    // ------------------------------------------------------
    $display("ТЕСТ 1: Нажатие цифры '1' (код 8'h16)");
    reset_capture;
    send_ps2_byte(8'h16);
    
    // Ждём достаточно времени для обработки пакета
    repeat(30) @(posedge clk);
    
    if (R_O_captured && captured_out == 4'h1 && captured_flags[0] == 1)
        $display("PASS TEST 1: Цифра '1' распознана корректно.");
    else
        $display("FAIL TEST 1: Ошибка! R_O_cap=%b out=%h flags=%b", 
                 R_O_captured, captured_out, captured_flags);

    repeat(10) @(posedge clk);

    // ------------------------------------------------------
    // ТЕСТ 2: Отжатие клавиши (F0 + 8'h16)
    // Ожидаем: R_O_captured=0 (сигнал не должен появиться)
    // ------------------------------------------------------
    $display("\n>>> ТЕСТ 2: Отжатие клавиши '1' (F0 + 8'h16)");
    reset_capture;
    
    send_ps2_byte(8'hF0);
    repeat(15) @(posedge clk);
    
    send_ps2_byte(8'h16);
    repeat(30) @(posedge clk);
    
    if (!R_O_captured)
        $display("PASS TEST 2: Отжатие обработано корректно (R_O не активирован).");
    else
        $display("FAIL TEST 2: Ошибка! R_O не должен активироваться при отжатии. out=%h flags=%b", 
                 captured_out, captured_flags);

    repeat(10) @(posedge clk);

    // ------------------------------------------------------
    // ТЕСТ 3: Нажатие цифры 'A' (код 8'h1C)
    // Ожидаем: R_O_captured=1, captured_out=A, captured_flags[0]=1
    // ------------------------------------------------------
    $display("\n>>> ТЕСТ 3: Нажатие цифры 'A' (код 8'h1C)");
    reset_capture;
    send_ps2_byte(8'h1C);
    
    repeat(30) @(posedge clk);
    
    if (R_O_captured && captured_out == 4'hA && captured_flags[0] == 1)
        $display("PASS TEST 3: Цифра 'A' распознана корректно.");
    else
        $display("FAIL TEST 3: Ошибка! R_O_cap=%b out=%h flags=%b", 
                 R_O_captured, captured_out, captured_flags);

    repeat(10) @(posedge clk);

    // ------------------------------------------------------
    // ТЕСТ 4: Нажатие Enter (код 8'h5A)
    // Ожидаем: R_O_captured=1, captured_flags[1]=1
    // ------------------------------------------------------
    $display("\n>>> ТЕСТ 4: Нажатие Enter (код 8'h5A)");
    reset_capture;
    send_ps2_byte(8'h5A);
    
    repeat(30) @(posedge clk);
    
    if (R_O_captured && captured_flags[1] == 1)
        $display("PASS TEST 4: Enter распознан корректно.");
    else
        $display("FAIL TEST 4: Ошибка! R_O_cap=%b flags=%b", 
                 R_O_captured, captured_flags);

    repeat(10) @(posedge clk);

    // ------------------------------------------------------
    // Завершение
    // ------------------------------------------------------
    $display("\n==========================================================");
    $display("Все тесты выполнены");
    $display("==========================================================");
    $finish;
end
endmodule
