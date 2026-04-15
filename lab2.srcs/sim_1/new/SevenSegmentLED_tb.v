`timescale 1ns / 1ps

module SevenSegmentLED_tb;

    reg clk;
    reg RESET;
    reg [31:0] NUMBER;
    reg [7:0] AN_MASK;
    wire [7:0] AN;
    wire [6:0] SEG;
    
    SevenSegmentLED uut (
        .clk(clk),
        .RESET(RESET),
        .NUMBER(NUMBER),
        .AN_MASK(AN_MASK),
        .AN(AN),
        .SEG(SEG)
    );
    
    initial clk = 0;
    always #5 clk = ~clk;
    
    function [6:0] expected_seg;
        input [3:0] digit;
        begin
            case (digit)
                4'h0: expected_seg = 7'b1000000;
                4'h1: expected_seg = 7'b1111001;
                4'h2: expected_seg = 7'b0100100;
                4'h3: expected_seg = 7'b0110000;
                4'h4: expected_seg = 7'b0011001;
                4'h5: expected_seg = 7'b0010010;
                4'h6: expected_seg = 7'b0000010;
                4'h7: expected_seg = 7'b1111000;
                4'h8: expected_seg = 7'b0000000;
                4'h9: expected_seg = 7'b0010000;
                4'hA: expected_seg = 7'b0001000;
                4'hB: expected_seg = 7'b0000011;
                4'hC: expected_seg = 7'b1000110;
                4'hD: expected_seg = 7'b0100001;
                4'hE: expected_seg = 7'b0000110;
                4'hF: expected_seg = 7'b0001110;
                default: expected_seg = 7'b1111111;
            endcase
        end
    endfunction
    
    function [7:0] expected_an_raw;
        input [2:0] idx;
        begin
            case (idx)
                3'd0: expected_an_raw = 8'b11111110;
                3'd1: expected_an_raw = 8'b11111101;
                3'd2: expected_an_raw = 8'b11111011;
                3'd3: expected_an_raw = 8'b11110111;
                3'd4: expected_an_raw = 8'b11101111;
                3'd5: expected_an_raw = 8'b11011111;
                3'd6: expected_an_raw = 8'b10111111;
                3'd7: expected_an_raw = 8'b01111111;
                default: expected_an_raw = 8'b11111111;
            endcase
        end
    endfunction
    
    // Функция ожидания конкретного индикатора
    task wait_for_indicator;
        input [2:0] idx;
        input [31:0] timeout;
        reg [7:0] expected_an;
        reg [31:0] count;
        begin
            expected_an = expected_an_raw(idx) | AN_MASK;
            count = 0;
            while ((AN != expected_an) && (count < timeout)) begin
                #5; // Ждём полтакта
                count = count + 1;
            end
            if (count >= timeout) begin
                $display("TIMEOUT: Ожидание индикатора %d не завершилось", idx);
            end
        end
    endtask
    
    reg test_pass;
    reg [7:0] an_expected;
    reg [6:0] seg_expected;
    integer i, j;
    
    initial begin
        $dumpfile("SevenSegmentLED_tb.vcd");
        $dumpvars(0, SevenSegmentLED_tb);
        
        RESET = 1;
        NUMBER = 32'h0;
        AN_MASK = 8'h00;
        test_pass = 1;
        
        #20;
        RESET = 0;
        #15;
        
        //==========================================================================
        // ТЕСТ 1: Сброс и инициализация
        //==========================================================================
        $display("\n========================================");
        $display("ТЕСТ 1: Сброс и инициализация");
        $display("========================================");
        
        // Ждём пока появится индикатор 0
        wait_for_indicator(3'd0, 1000);
        
        if (AN == 8'b11111110) begin
            $display("PASS: После сброса активен индикатор 0 (AN=11111110)");
        end else begin
            $display("FAIL: После сброса AN=%b, ожидалось 11111110", AN);
            test_pass = 0;
        end
        
        #20;
        
        //==========================================================================
        // ТЕСТ 2: Последовательная индикация
        //==========================================================================
        $display("\n========================================");
        $display("ТЕСТ 2: Последовательная индикация");
        $display("========================================");
        
        NUMBER = 32'hFEDCBA98;
        
        for (i = 0; i < 8; i = i + 1) begin
            // Ждём конкретный индикатор
            wait_for_indicator(i[2:0], 1000);
            #2; // Небольшая задержка для стабилизации
            
            seg_expected = expected_seg(NUMBER[(i*4)+:4]);
            an_expected = expected_an_raw(i[2:0]);
            
            if (SEG == seg_expected && AN == an_expected) begin
                $display("PASS: Индикатор: цифра %h, SEG=%b, AN=%b", 
                         i, NUMBER[(i*4)+:4], SEG, AN);
            end else begin
                $display("FAIL: Индикатор %d:", i);
                $display("  SEG: получено %b, ожидалось %b", SEG, seg_expected);
                $display("  AN:  получено %b, ожидалось %b", AN, an_expected);
                test_pass = 0;
            end
        end
        
        // Проверка зацикливания
        wait_for_indicator(3'd0, 1000);
        #2;
        if (AN == 8'b11111110) begin
            $display("PASS: Цикл мультиплексирования корректно зациклен");
        end else begin
            $display("FAIL: После 8 тактов AN=%b, ожидалось 11111110", AN);
            test_pass = 0;
        end
        
        //==========================================================================
        // ТЕСТ 3: Работа маски AN_MASK
        //==========================================================================
        $display("\n========================================");
        $display("ТЕСТ 3: Маска AN_MASK");
        $display("========================================");
        
        NUMBER = 32'h12345678;
        AN_MASK = 8'b00001111;
        
        for (i = 0; i < 8; i = i + 1) begin
            wait_for_indicator(i[2:0], 1000);
            #2;
            
            if (i[2:0] < 4) begin  // ИСПРАВЛЕНО: i[2:0] вместо i
                if (AN[i[2:0]] == 1'b1) begin  // ИСПРАВЛЕНО: i[2:0] вместо i
                    $display("Индикатор %d: корректно отключён маской", i[2:0]);  // ИСПРАВЛЕНО
                end else begin
                    $display("FAIL: Индикатор %d должен быть отключён, но AN[%d]=%b", 
                             i[2:0], i[2:0], AN[i[2:0]]);  // ИСПРАВЛЕНО
                    test_pass = 0;
                end
            end else begin
                if (AN[i[2:0]] == 1'b0) begin  // ИСПРАВЛЕНО: i[2:0] вместо i
                    $display("Индикатор %d: активен (не замаскирован)", i[2:0]);  // ИСПРАВЛЕНО
                end else begin
                    $display("FAIL: Индикатор %d должен быть активен, но AN[%d]=%b", 
                             i[2:0], i[2:0], AN[i[2:0]]);  // ИСПРАВЛЕНО
                    test_pass = 0;
                end
            end
        end
        
        AN_MASK = 8'h00;
        
        //==========================================================================
        // ТЕСТ 4: Динамическое обновление
        //==========================================================================
        $display("\n========================================");
        $display("ТЕСТ 4: Динамическое обновление");
        $display("========================================");
        
        NUMBER = 32'h00000000;
        #20;
        
        for (j = 0; j < 5; j = j + 1) begin
            NUMBER = NUMBER + 32'h1;
            
            // Ждём пока индикатор 0 станет неактивным
            while (AN[0] == 1'b0) #5;
            
            // Теперь ждём следующего появления индикатора 0
            wait_for_indicator(3'd0, 1000);
            #2;
            
            seg_expected = expected_seg(NUMBER[3:0]);
            
            if (SEG == seg_expected) begin
                $display("Live-обновление: NUMBER=%h, SEG=%b (цифра %h)", 
                         NUMBER, SEG, NUMBER[3:0]);
            end else begin
                $display("FAIL: Live-обновление не сработало");
                $display("  SEG: получено %b, ожидалось %b", SEG, seg_expected);
                test_pass = 0;
            end
        end
        
        //==========================================================================
        // ИТОГИ
        //==========================================================================
        $display("\n========================================");
        if (test_pass) begin
            $display("ВСЕ ТЕСТЫ ПРОЙДЕНЫ");
        end else begin
            $display("НЕКОТОРЫЕ ТЕСТЫ НЕ ПРОЙДЕНЫ ");
        end
        $display("========================================\n");
        
        #50;
        $finish;
    end
endmodule