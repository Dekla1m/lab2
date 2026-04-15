`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: top
// Description: Интеграция всей системы: ввод -> вычисление -> вывод
//////////////////////////////////////////////////////////////////////////////////

module top(
    input wire clk,        // Основная частота (50/100 MHz)
    input wire btn_reset,  // Кнопка сброса
    input wire PS2_clk,    // PS/2 Clock
    input wire PS2_dat,    // PS/2 Data
    output wire [7:0] SEG_AN, // Аноды индикаторов
    output wire [6:0] SEG_CAT // Катоды индикаторов
);

// ============================================================================
// 1. СБРОС С ФИЛЬТРАЦИЕЙ ДРЕБЕЗГА
// ============================================================================
wire reset_filtered;
FilterDreb u_filter (
    .CLK(clk),
    .CLOCK_ENABLE(1'b1),  // Р’СЃРµРіРґР° РІРєР»СЋС‡РµРЅ
    .IN_SIGNAL(btn_reset),
    .OUT_SIGNAL(reset_filtered) // ?? Проверь имя порта в твоём FilterDreb (может быть btn_out)
);

// ============================================================================
// 2. ДЕЛИТЕЛЬ ЧАСТОТЫ ДЛЯ ДИСПЛЕЯ
// ============================================================================
wire clk_display;
clkDivider #(
    .DIVISOR(100) // Подстрой под свою частоту clk (50MHz -> 500Hz развёртка)
) clkDivider (
    .clk(clk),
    .RESET(reset_filtered),
    .tick(clk_display) // Медленный такт только для SevenSegmentLED
);

// ============================================================================
// 3. ОБРАБОТКА PS/2
// ============================================================================
wire ps2_ready_sig;
wire [7:0] ps2_keycode;
wire [1:0] ps2_flags_raw;
wire [3:0] ps2_digit_val;
wire [1:0] ps2_flags_dec;

// Приёмник протокола
PS2_Manager u_ps2_manager (
    .clk(clk),
    .reset(reset_filtered),
    .PS2_clk(PS2_clk),
    .PS2_dat(PS2_dat),
    .R_O(ps2_ready_sig),   // ?? Проверь имя порта (может быть PS2_R_O)
    .out(ps2_keycode),
    .flags(ps2_flags_raw)
);

// Дешифратор скан-кодов
PS2_DC u_ps2_dc (
    .keycode(ps2_keycode),
    .out(ps2_digit_val),
    .flags(ps2_flags_dec)
);

// Преобразование флагов в понятные сигналы для InputSequencer
wire is_number    = ps2_ready_sig && (ps2_flags_dec == 2'd1);
wire is_enter     = ps2_ready_sig && (ps2_flags_dec == 2'd2);
wire is_backspace = ps2_ready_sig && (ps2_flags_dec == 2'd3);

// ============================================================================
// 4. ВВОД ДАННЫХ (InputSequencer)
// ============================================================================
wire [31:0] seq_data_out;
wire [9:0]  seq_addr_out;
wire        seq_write_enable;
wire        seq_config_start;
wire [31:0] display_buffer;
wire        input_error;
wire [7:0]  seq_error_code;

InputSequencer #(
    .MAX_N(16),
    .MAX_W(512)
) u_input_seq (
    .clk(clk),
    .reset(reset_filtered),
    .digit(ps2_digit_val),
    .digit_valid(is_number),
    .is_enter(is_enter),
    .is_backspace(is_backspace),
    .data_out(seq_data_out),
    .addr_out(seq_addr_out),
    .write_enable(seq_write_enable),
    .config_start(seq_config_start),
    .display_buffer(display_buffer),
    .input_error(input_error),
    .error_code(seq_error_code),
    .input_stage() // Не используется в top
);

// ============================================================================
// 5. ВЫЧИСЛЕНИЕ (main)
// ============================================================================
wire        main_busy;
wire        main_done;
wire        main_config_ready;
wire [15:0] main_taken_items;
wire [31:0] main_max_value;
wire        main_error_valid;
wire [7:0]  main_error_code;

main #(
    .MAX_N(16),
    .MAX_W(512),
    .DATA_WIDTH(32),
    .ADDR_WIDTH(10)
) u_main (
    .clk(clk),
    .reset(reset_filtered),
    .data_in(seq_data_out),
    .addr(seq_addr_out),
    .write_enable(seq_write_enable),
    .config_start(seq_config_start),
    .busy(main_busy),
    .done(main_done),
    .config_ready(main_config_ready),
    .expected_addr(),
    .taken_items(main_taken_items),
    .max_value(main_max_value),
    .debug_dp_W(),
    .error_code(main_error_code),
    .error_valid(main_error_valid)
);

// ============================================================================
// 6. ЛОГИКА ОТОБРАЖЕНИЯ (Мультиплексор)
// ============================================================================
reg [31:0] display_data;
reg [7:0]  display_mask;

always @(*) begin
    // 1?? Приоритет: Ошибки (ввода или валидации в main)
    if (input_error || main_error_valid) begin
        display_data = {24'd0, input_error ? seq_error_code : main_error_code};
        display_mask = 8'b11111100; // Показываем код на последних 2 индикаторах
    end
    // 2?? Приоритет: Результат вычислений (маска взятых предметов в HEX)
    else if (main_done) begin
        // 16 бит taken_items -> 4 hex цифры. Старшие 16 бит забиваем нулями.
        display_data = {16'd0, main_taken_items};
        display_mask = 8'b00000000; // Все 8 индикаторов активны
    end
    // 3?? Приоритет: Процесс ввода (живой буфер)
    else begin
        display_data = display_buffer;
        display_mask = 8'b00000000; // Все 8 индикаторов активны
    end
end

// ============================================================================
// 7. ВЫВОД НА ДИСПЛЕЙ
// ============================================================================
SevenSegmentLED u_display (
    .clk(clk_display),   // Тактирование от отдельного делителя
    .RESET(reset_filtered),
    .NUMBER(display_data),
    .AN_MASK(display_mask),
    .AN(SEG_AN),
    .SEG(SEG_CAT)
);

endmodule