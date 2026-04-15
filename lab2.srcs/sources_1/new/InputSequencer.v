`timescale 1ns / 1ps

module InputSequencer #(
    parameter MAX_N = 16,
    parameter MAX_W = 512
)(
    input wire clk,
    input wire reset,
    
    input wire [3:0] digit,
    input wire digit_valid,
    input wire is_enter,
    input wire is_backspace,
    
    output reg [31:0] data_out,
    output reg [9:0] addr_out,
    output reg write_enable,
    output reg config_start,
    
    output reg [31:0] display_buffer,
    output reg input_error,
    output reg [7:0] error_code,
    output reg [3:0] input_stage
);

localparam [3:0] S_IDLE         = 4'd0;
localparam [3:0] S_INPUT_N      = 4'd1;
localparam [3:0] S_INPUT_W      = 4'd2;
localparam [3:0] S_INPUT_WEIGHT = 4'd3;
localparam [3:0] S_INPUT_PRICE  = 4'd4;
localparam [3:0] S_WAIT_START   = 4'd5;
localparam [3:0] S_ERROR        = 4'd6;
localparam [3:0] S_DONE         = 4'd7;

reg [3:0] state;
reg [31:0] accum_buffer;
reg [3:0] digit_count;
reg [31:0] N_reg;
reg [31:0] W_reg;
reg [3:0] item_index;

// Выходы по умолчанию
always @(posedge clk or posedge reset) begin
    if (reset) begin
        state <= S_IDLE;
        accum_buffer <= 32'd0;
        digit_count <= 4'd0;
        N_reg <= 32'd0;
        W_reg <= 32'd0;
        item_index <= 4'd0;
        data_out <= 32'd0;
        addr_out <= 10'd0;
        write_enable <= 1'b0;
        config_start <= 1'b0;
        input_error <= 1'b0;
        error_code <= 8'd0;
    end else begin
        // По умолчанию сохраняем состояние
        write_enable <= 1'b0;
        config_start <= 1'b0;
        input_error <= 1'b0;
        display_buffer <= accum_buffer;  // ? Всегда отображаем буфер
        input_stage <= state;
        
        case (state)
            // ================================================================
            S_IDLE: begin
                accum_buffer <= 32'd0;
                digit_count <= 4'd0;
                
                if (digit_valid && !is_enter && !is_backspace) begin
                    accum_buffer <= {28'd0, digit};
                    digit_count <= 4'd1;
                    state <= S_INPUT_N;
                end
            end
            
            // ================================================================
            S_INPUT_N: begin
                if (digit_valid && is_backspace) begin
                    if (digit_count > 1) begin
                        accum_buffer <= {4'd0, accum_buffer[31:4]};
                        digit_count <= digit_count - 1'b1;
                    end else begin
                        accum_buffer <= 32'd0;
                        digit_count <= 4'd0;
                        state <= S_IDLE;
                    end
                end
                else if (digit_valid && is_enter) begin
                    if (accum_buffer > MAX_N) begin
                        input_error <= 1'b1;
                        error_code <= 8'd1;
                        state <= S_ERROR;
                    end else begin
                        N_reg <= accum_buffer;
                        data_out <= accum_buffer;
                        addr_out <= 10'd0;
                        write_enable <= 1'b1;
                        accum_buffer <= 32'd0;
                        digit_count <= 4'd0;
                        state <= S_INPUT_W;
                    end
                end
                else if (digit_valid && digit_count < 8) begin
                    accum_buffer <= {accum_buffer[27:0], digit};
                    digit_count <= digit_count + 1'b1;
                end
            end
            
            // ================================================================
            S_INPUT_W: begin
                if (digit_valid && is_backspace) begin
                    if (digit_count > 1) begin
                        accum_buffer <= {4'd0, accum_buffer[31:4]};
                        digit_count <= digit_count - 1'b1;
                    end else begin
                        accum_buffer <= 32'd0;
                        digit_count <= 4'd0;
                        state <= S_INPUT_N;
                    end
                end
                else if (digit_valid && is_enter) begin
                    if (accum_buffer > MAX_W) begin
                        input_error <= 1'b1;
                        error_code <= 8'd2;
                        state <= S_ERROR;
                    end else begin
                        W_reg <= accum_buffer;
                        data_out <= accum_buffer;
                        addr_out <= 10'd1;
                        write_enable <= 1'b1;
                        accum_buffer <= 32'd0;
                        digit_count <= 4'd0;
                        item_index <= 4'd0;
                        state <= S_INPUT_WEIGHT;
                    end
                end
                else if (digit_valid && digit_count < 8) begin
                    accum_buffer <= {accum_buffer[27:0], digit};
                    digit_count <= digit_count + 1'b1;
                end
            end
            
            // ================================================================
            S_INPUT_WEIGHT: begin
                if (digit_valid && is_backspace) begin
                    if (digit_count > 1) begin
                        accum_buffer <= {4'd0, accum_buffer[31:4]};
                        digit_count <= digit_count - 1'b1;
                    end else begin
                        accum_buffer <= 32'd0;
                        digit_count <= 4'd0;
                        if (item_index > 0) begin
                            item_index <= item_index - 1'b1;
                        end else begin
                            state <= S_INPUT_W;
                        end
                    end
                end
                else if (digit_valid && is_enter) begin
                    data_out <= accum_buffer;
                    addr_out <= 10'd2 + item_index;
                    write_enable <= 1'b1;
                    accum_buffer <= 32'd0;
                    digit_count <= 4'd0;
                    
                    if (item_index >= N_reg[3:0] - 1) begin
                        item_index <= 4'd0;
                        state <= S_INPUT_PRICE;
                    end else begin
                        item_index <= item_index + 1'b1;
                    end
                end
                else if (digit_valid && digit_count < 8) begin
                    accum_buffer <= {accum_buffer[27:0], digit};
                    digit_count <= digit_count + 1'b1;
                end
            end
            
            // ================================================================
            S_INPUT_PRICE: begin
                if (digit_valid && is_backspace) begin
                    if (digit_count > 1) begin
                        accum_buffer <= {4'd0, accum_buffer[31:4]};
                        digit_count <= digit_count - 1'b1;
                    end else begin
                        accum_buffer <= 32'd0;
                        digit_count <= 4'd0;
                        if (item_index > 0) begin
                            item_index <= item_index - 1'b1;
                        end else begin
                            state <= S_INPUT_WEIGHT;
                        end
                    end
                end
                else if (digit_valid && is_enter) begin
                    data_out <= accum_buffer;
                    addr_out <= 10'd18 + item_index;
                    write_enable <= 1'b1;
                    accum_buffer <= 32'd0;
                    digit_count <= 4'd0;
                    
                    if (item_index >= N_reg[3:0] - 1) begin
                        item_index <= 4'd0;
                        state <= S_WAIT_START;
                    end else begin
                        item_index <= item_index + 1'b1;
                    end
                end
                else if (digit_valid && digit_count < 8) begin
                    accum_buffer <= {accum_buffer[27:0], digit};
                    digit_count <= digit_count + 1'b1;
                end
            end
            
            // ================================================================
            S_WAIT_START: begin
                if (digit_valid && is_enter) begin
                    data_out <= 32'd1;
                    addr_out <= 10'd34;
                    write_enable <= 1'b1;
                    config_start <= 1'b1;
                    state <= S_DONE;
                end
                else if (digit_valid && is_backspace) begin
                    state <= S_INPUT_PRICE;
                    item_index <= (N_reg[3:0] > 1) ? N_reg[3:0] - 2 : 4'd0;
                end
            end
            
            // ================================================================
            S_ERROR: begin
                if (digit_valid && is_backspace) begin
                    input_error <= 1'b0;
                    error_code <= 8'd0;
                    accum_buffer <= 32'd0;
                    digit_count <= 4'd0;
                    state <= (error_code == 8'd1) ? S_INPUT_N : S_INPUT_W;
                end
            end
            
            // ================================================================
            S_DONE: begin
                // Ждём внешнего сброса
            end
            
            default: state <= S_IDLE;
        endcase
    end
end

endmodule