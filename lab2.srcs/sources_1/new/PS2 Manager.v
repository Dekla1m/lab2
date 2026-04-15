`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07.04.2026 15:04:48
// Design Name: 
// Module Name: PS2 Manager
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module PS2_Manager (
    input clk,
    input reset,
    input PS2_dat,
    input PS2_clk,
    
    output reg R_O,
    output [3:0] out,
    output [1:0] flags
);
// Состояние ожидания установки сигнала готовности пакета данных
parameter WAIT_ONE = 0;
// Состояние ожидания сброса сигнала готовности пакета данных
parameter WAIT_ZERO = 1;
reg state;
// Выходы модуля приёма одного пакета PS2
wire PS2_R_O, PS2_ERROR;
wire [7:0] PS2_out;
// Регистр флага отжатия клавиши
reg release_flag;

initial begin
    state = 0; R_O = 0;
    release_flag = 0;
end

always@(posedge clk)
begin
    case(state)
        WAIT_ONE: begin
            if (PS2_R_O) begin
                if (!PS2_ERROR) begin
                    if (PS2_out == 8'hF0)
                        release_flag <= 1;
                    else if (release_flag) begin
                        release_flag <= 0;
                    end
                    else begin 
                        R_O <= 1;
                    end
                end
                state <= WAIT_ZERO;
            end
        end
        WAIT_ZERO: begin
            R_O <= 0;
            if (!PS2_R_O)
                state <= WAIT_ONE;
        end
    endcase
end

// Приём одного пакета PS2
PS2 ps2(
    .reset(reset),
    .clk(clk),
    .PS2_clk(PS2_clk), .PS2_dat(PS2_dat),
    .out(PS2_out), .R_O(PS2_R_O),
    .ERROR(PS2_ERROR)
);

// Дешифратор пакета
PS2_DC dc(.keycode(PS2_out), .out(out), .flags(flags));
endmodule
