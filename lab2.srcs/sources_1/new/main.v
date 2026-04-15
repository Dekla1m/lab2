`timescale 1ns / 1ps

module main #(
    parameter MAX_N = 16,
    parameter MAX_W = 512,
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 10
)(
    input wire clk,
    input wire reset,
    
    input wire [DATA_WIDTH-1:0] data_in,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire write_enable,
    input wire config_start,
    
    output reg busy,
    output reg done,
    output reg config_ready,
    output reg [ADDR_WIDTH-1:0] expected_addr,
    output reg [MAX_N-1:0] taken_items,
    output reg [DATA_WIDTH-1:0] max_value,
    output reg [15:0] debug_dp_W,
    
    // Выходы для ошибок
    output reg [7:0] error_code,
    output reg error_valid
);

// ============================================================================
// АДРЕСА РЕГИСТРОВ
// ============================================================================
localparam [ADDR_WIDTH-1:0] ADDR_N            = 10'd0;
localparam [ADDR_WIDTH-1:0] ADDR_W            = 10'd1;
localparam [ADDR_WIDTH-1:0] ADDR_WEIGHTS_START = 10'd2;
localparam [ADDR_WIDTH-1:0] ADDR_WEIGHTS_END   = 10'd17;
localparam [ADDR_WIDTH-1:0] ADDR_PRICES_START  = 10'd18;
localparam [ADDR_WIDTH-1:0] ADDR_PRICES_END    = 10'd33;
localparam [ADDR_WIDTH-1:0] ADDR_START         = 10'd34;

// ============================================================================
// СОСТОЯНИЯ FSM
// ============================================================================
localparam [3:0] STATE_CONFIG      = 4'd0;
localparam [3:0] STATE_START       = 4'd1;
localparam [3:0] STATE_INIT_DP     = 4'd2;
localparam [3:0] STATE_DP_COMPUTE  = 4'd3;
localparam [3:0] STATE_DP_UPDATE   = 4'd4;
localparam [3:0] STATE_RECONSTRUCT = 4'd5;
localparam [3:0] STATE_CHECK_ITEM  = 4'd6;
localparam [3:0] STATE_OUTPUT      = 4'd7;
localparam [3:0] STATE_DONE        = 4'd8;
localparam [3:0] STATE_ERROR       = 4'd9;
localparam [3:0] STATE_CHECK_COMPARE = 4'd10;

// ============================================================================
// РЕГИСТРЫ КОНФИГУРАЦИИ
// ============================================================================
reg [7:0] N_reg;
reg [7:0] W_reg;
reg [15:0] weights_mem [0:MAX_N-1];
reg [15:0] prices_mem [0:MAX_N-1];
reg config_complete;

// ============================================================================
// РЕГИСТРЫ СОСТОЯНИЯ
// ============================================================================
reg [3:0] state;
reg [7:0] item_counter;
reg [15:0] capacity_counter;
reg [15:0] new_value;
reg [15:0] dp_value_prev;
reg [15:0] check_value;
reg dp_update_flag;
reg reconstruct_done;

// ============================================================================
// ПАМЯТЬ DP
// ============================================================================
reg [15:0] dp_mem [0:MAX_W];

// ============================================================================
// ЕДИНЫЙ ALWAYS-БЛОК (Однопроцессорная FSM)
// ============================================================================
always @(posedge clk or posedge reset) begin
    if (reset) begin
        // Сброс всех регистров
        state <= STATE_CONFIG;
        N_reg <= 8'd0;
        W_reg <= 8'd0;
        config_complete <= 1'b0;
        item_counter <= 8'd0;
        capacity_counter <= 16'd0;
        taken_items <= 0;
        max_value <= 0;
        dp_update_flag <= 1'b0;
        reconstruct_done <= 1'b0;
        error_code <= 8'd0;
        error_valid <= 1'b0;
        expected_addr <= ADDR_N;
        
        // Выходные сигналы
        busy <= 1'b0;
        done <= 1'b0;
        config_ready <= 1'b1;
    end else begin
        // По умолчанию сбрасываем импульсные сигналы
        busy <= 1'b0;
        done <= 1'b0;
        config_ready <= 1'b0;
        dp_update_flag <= 1'b0;
        
        // ====================================================================
        // ОБРАБОТКА ЗАПИСИ КОНФИГУРАЦИИ
        // ====================================================================
        if (write_enable && state == STATE_CONFIG) begin
            error_valid <= 1'b0;
            
            if (addr == ADDR_N) begin
                if (data_in[7:0] > MAX_N) begin
                    error_code <= 8'd1;
                    error_valid <= 1'b1;
                end else begin
                    N_reg <= data_in[7:0];
                    expected_addr <= ADDR_W;
                end
            end
            else if (addr == ADDR_W) begin
                if (data_in[15:0] > MAX_W) begin
                    error_code <= 8'd2;
                    error_valid <= 1'b1;
                end else begin
                    W_reg <= data_in[7:0];
                    expected_addr <= ADDR_WEIGHTS_START;
                end
            end
            else if (addr >= ADDR_WEIGHTS_START && addr <= ADDR_WEIGHTS_END) begin
                weights_mem[addr - ADDR_WEIGHTS_START] <= data_in[15:0];
                if (addr < ADDR_WEIGHTS_END)
                    expected_addr <= addr + 1;
                else
                    expected_addr <= ADDR_PRICES_START;
            end
            else if (addr >= ADDR_PRICES_START && addr <= ADDR_PRICES_END) begin
                prices_mem[addr - ADDR_PRICES_START] <= data_in[15:0];
                if (addr < ADDR_PRICES_END)
                    expected_addr <= addr + 1;
                else
                    expected_addr <= ADDR_START;
            end
            else if (addr == ADDR_START) begin
                if (data_in[0] == 1'b1) begin
                    state <= STATE_START;
                end
            end
        end
        
        // ====================================================================
        // FSM ЛОГИКА
        // ====================================================================
        case (state)
            // ----------------------------------------------------------------
            STATE_CONFIG: begin
                config_ready <= 1'b1;
                
                if (error_valid) begin
                    state <= STATE_ERROR;
                end
            end
            
            // ----------------------------------------------------------------
            STATE_START: begin
                busy <= 1'b1;
                item_counter <= 8'd0;
                capacity_counter <= 16'd0;
                taken_items <= 0;
                max_value <= 0;
                config_complete <= 1'b0;
                state <= STATE_INIT_DP;
            end
            
            // ----------------------------------------------------------------
            STATE_INIT_DP: begin
                busy <= 1'b1;
                dp_mem[capacity_counter] <= 16'd0;
                
                if (capacity_counter < W_reg) begin
                    capacity_counter <= capacity_counter + 16'd1;
                    state <= STATE_INIT_DP;
                end else begin
                    capacity_counter <= 16'd0;
                    state <= STATE_DP_COMPUTE;
                end
            end
            
            // ----------------------------------------------------------------
            STATE_DP_COMPUTE: begin
                busy <= 1'b1;
                
                if (weights_mem[item_counter] <= capacity_counter) begin
                    dp_value_prev <= dp_mem[capacity_counter - weights_mem[item_counter]];
                    new_value <= dp_mem[capacity_counter - weights_mem[item_counter]] + 
                                 prices_mem[item_counter];
                    dp_update_flag <= 1'b1;
                end else begin
                    dp_update_flag <= 1'b0;
                end
                
                state <= STATE_DP_UPDATE;
            end
            
            // ----------------------------------------------------------------
            STATE_DP_UPDATE: begin
                busy <= 1'b1;
                
                if (dp_update_flag && (new_value > dp_mem[capacity_counter])) begin
                    dp_mem[capacity_counter] <= new_value;
                end
                
                if (capacity_counter < W_reg) begin
                    capacity_counter <= capacity_counter + 16'd1;
                    state <= STATE_DP_COMPUTE;
                end else begin
                    capacity_counter <= 16'd0;
                    if (item_counter < N_reg - 1) begin
                        item_counter <= item_counter + 8'd1;
                        state <= STATE_DP_COMPUTE;
                    end else begin
                        state <= STATE_RECONSTRUCT;
                    end
                end
            end
            
            // ----------------------------------------------------------------
            STATE_RECONSTRUCT: begin
                busy <= 1'b1;
                capacity_counter <= W_reg;
                item_counter <= 8'd0;
                reconstruct_done <= 1'b0;
                state <= STATE_CHECK_ITEM;
            end
            
            // ----------------------------------------------------------------
            STATE_CHECK_ITEM: begin
                busy <= 1'b1;
                
                if (capacity_counter == 0) begin
                    reconstruct_done <= 1'b1;
                    state <= STATE_OUTPUT;
                end
                else if (item_counter >= N_reg) begin
                    reconstruct_done <= 1'b1;
                    state <= STATE_OUTPUT;
                end
                else if (weights_mem[item_counter] <= capacity_counter) begin
                    check_value <= dp_mem[capacity_counter - weights_mem[item_counter]] +
                                  prices_mem[item_counter];
                    state <= STATE_CHECK_COMPARE;  // ? Переход для сравнения в следующем такте
                end
                else begin
                    item_counter <= item_counter + 8'd1;
                    state <= STATE_CHECK_ITEM;
                end
            end
            
            // Новое состояние для сравнения:
            STATE_CHECK_COMPARE: begin
                busy <= 1'b1;
                
                if (check_value == dp_mem[capacity_counter]) begin
                    taken_items[item_counter] <= 1'b1;
                    capacity_counter <= capacity_counter - weights_mem[item_counter];
                    item_counter <= 8'd0;
                end else begin
                    item_counter <= item_counter + 8'd1;
                end
                state <= STATE_CHECK_ITEM;
            end
            
            // ----------------------------------------------------------------
            STATE_OUTPUT: begin
                busy <= 1'b1;
                max_value <= dp_mem[W_reg];
                debug_dp_W <= dp_mem[W_reg];
                state <= STATE_DONE;
            end
            
            // ----------------------------------------------------------------
            STATE_DONE: begin
                done <= 1'b1;
                state <= STATE_DONE;
            end
            
            // ----------------------------------------------------------------
            STATE_ERROR: begin
                error_valid <= 1'b1;
                state <= STATE_ERROR;
            end
            
            // ----------------------------------------------------------------
            default: begin
                state <= STATE_CONFIG;
            end
        endcase
    end
end

endmodule