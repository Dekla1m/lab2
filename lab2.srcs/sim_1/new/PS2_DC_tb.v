`timescale 1ns / 1ps

module PS2_DC_tb;

// Сигналы
reg [7:0] keycode;
wire [3:0] out;
wire [1:0] flags;
integer i;
reg test_fail;

// Подключение модуля
PS2_DC uut (
    .keycode(keycode),
    .out(out),
    .flags(flags)
);

// Ожидаемые значения для цифр 0-F
reg [7:0] expected_codes [0:15];

initial begin
    // Инициализация таблицы скан-кодов
    expected_codes[0] = 8'h45;
    expected_codes[1] = 8'h16;
    expected_codes[2] = 8'h1E;
    expected_codes[3] = 8'h26;
    expected_codes[4] = 8'h25;
    expected_codes[5] = 8'h2E;
    expected_codes[6] = 8'h36;
    expected_codes[7] = 8'h3D;
    expected_codes[8] = 8'h3E;
    expected_codes[9] = 8'h46;
    expected_codes[10] = 8'h1C;
    expected_codes[11] = 8'h32;
    expected_codes[12] = 8'h21;
    expected_codes[13] = 8'h23;
    expected_codes[14] = 8'h24;
    expected_codes[15] = 8'h2B;
end

initial begin
    $dumpfile("PS2_DC_tb.vcd");
    $dumpvars(0, PS2_DC_tb);
    
    //======================================================================
    // ТЕСТ 1: Проверка всех цифр 0-F
    //======================================================================
    $display("");
    $display("ТЕСТ 1: Проверка цифр 0-F");
    
    test_fail = 0;
    keycode = 0;
    #1;
    
    for (i = 0; i < 16; i = i + 1) begin
        keycode = expected_codes[i];
        #1;
        
        if (out !== i[3:0]) begin
            $display("  FAIL: Цифра %d. Скан-код=%h, out=%h (ожидалось %h)", 
                     i, expected_codes[i], out, i[3:0]);
            test_fail = 1;
        end
        
        if (flags !== 2'b01) begin
            $display("  FAIL: Цифра %d. flags=%b (ожидалось 01)", i, flags);
            test_fail = 1;
        end
    end
    
    if (!test_fail)
        $display("PASS: Все цифры 0-F декодируются верно");
    else
        $display("FAIL: Ошибки в декодировании цифр");
    
    #10;
    
    //======================================================================
    // ТЕСТ 2: Проверка клавиши Enter
    //======================================================================
    $display("");
    $display("ТЕСТ 2: Проверка Enter (0x5A)");
    
    test_fail = 0;
    keycode = 8'h5A;
    #1;
    
    if (out !== 4'h0) begin
        $display("  FAIL: Enter. out=%h (ожидалось 0)", out);
        test_fail = 1;
    end
    
    if (flags !== 2'b10) begin
        $display("  FAIL: Enter. flags=%b (ожидалось 10)", flags);
        test_fail = 1;
    end
    
    if (!test_fail)
        $display("PASS: Enter декодируется верно");
    else
        $display("FAIL: Ошибка декодирования Enter");
    
    #10;
    
    //======================================================================
    // ТЕСТ 3: Проверка клавиши Enter
    //======================================================================
    $display("");
    $display("ТЕСТ 3: Проверка Backspace (0x66)");
    
    test_fail = 0;
    keycode = 8'h66;
    #1;
    
    if (out !== 4'h0) begin
        $display("  FAIL: Backspace. out=%h (ожидалось 0)", out);
        test_fail = 1;
    end
    
    if (flags !== 2'b11) begin
        $display("  FAIL: Backspace. flags=%b (ожидалось 10)", flags);
        test_fail = 1;
    end
    
    if (!test_fail)
        $display("PASS: Backspace декодируется верно");
    else
        $display("FAIL: Ошибка декодирования Backspace");
    
    #10;
    
    //======================================================================
    // ТЕСТ 3: Проверка неизвестных кодов (default)
    //======================================================================
    $display("");
    $display("ТЕСТ 3: Проверка неизвестных кодов");
    
    test_fail = 0;
    
    // Тестируем несколько случайных неизвестных кодов
    keycode = 8'h00; #1;
    if (out !== 4'h0 || flags !== 2'b00) begin
        $display("  FAIL: Код 0x00. out=%h flags=%b", out, flags);
        test_fail = 1;
    end
    
    keycode = 8'hFF; #1;
    if (out !== 4'h0 || flags !== 2'b00) begin
        $display("  FAIL: Код 0xFF. out=%h flags=%b", out, flags);
        test_fail = 1;
    end
    
    keycode = 8'hF0; #1;
    if (out !== 4'h0 || flags !== 2'b00) begin
        $display("  FAIL: Код 0xF0. out=%h flags=%b", out, flags);
        test_fail = 1;
    end
    
    keycode = 8'hAA; #1;
    if (out !== 4'h0 || flags !== 2'b00) begin
        $display("  FAIL: Код 0xAA. out=%h flags=%b", out, flags);
        test_fail = 1;
    end
    
    if (!test_fail)
        $display("PASS: Неизвестные коды обрабатываются корректно");
    else
        $display("FAIL: Ошибки в обработке неизвестных кодов");
    
    #10;
    $display("");
    $display("ТЕСТИРОВАНИЕ ЗАВЕРШЕНО");
    $finish;
end

endmodule