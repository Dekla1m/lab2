`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07.04.2026 14:44:33
// Design Name: 
// Module Name: PS2
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

module PS2(
    input reset, // добавлен сброс
    input clk,
    input PS2_clk,
    input PS2_dat,
    output [7:0] out,
    output reg R_O,
    output reg ERROR
    );

parameter WAIT_START_BIT = 0,
          IDLE = 1,
          WRITE = 2,
          PARITY_BIT = 3,
          STOP_BIT = 4;
reg [2:0] state;

reg [3:0] cnt;
reg [7:0] PS2_buf;
reg [1:0] PS2_clk_sync, PS2_dat_sync;
reg PS2_clk_reg; // для обнаружения negedge PS2_clk

assign out = PS2_buf;

initial
begin
    cnt = 0;
    R_O = 0;
    ERROR = 0;
    state = WAIT_START_BIT;
    PS2_buf = 0;
    PS2_clk_sync = 2'b11;
    PS2_dat_sync = 2'b11;
    PS2_clk_reg  = 'b1;
end

always @(posedge clk) 
begin
    PS2_clk_sync <= {PS2_clk_sync[0], PS2_clk};
    PS2_dat_sync <= {PS2_dat_sync[0], PS2_dat};
    PS2_clk_reg  <= PS2_clk_sync[1];
end

wire neg_PS2_clk; // добавлено: чтобы избежать асинхронщины, внедрена логика отслеживания negedge
assign neg_PS2_clk = ~PS2_clk_sync[1] & PS2_clk_reg; // детектор фронта

always@(posedge clk)
begin
    if(reset)
        begin
            cnt = 0;
            R_O = 0;
            ERROR = 0;
            state = WAIT_START_BIT;
            PS2_buf = 0;
            PS2_clk_sync = 2'b11;
            PS2_dat_sync = 2'b11;
            PS2_clk_reg  = 'b1;
        end
     else if(neg_PS2_clk)
        begin
            case(state)
                //ожидание стартового бита
                WAIT_START_BIT:
                begin
                    R_O <= 0;
                    ERROR <= 0;
                    state <= ~PS2_dat_sync[1] ? WRITE : IDLE; // изменено: вместо PS2_dat - PS2_dat_sync[1]
                end
                
                //ожидание конца пакета
                IDLE: 
                    if(cnt == 4'd10) 
                    begin
                        ERROR <= 1;
                        R_O <= 1;
                        state <= WAIT_START_BIT;
                    end
                    
                //обработка бита данных
                WRITE: 
                begin
                    if(cnt == 4'd8) 
                        state <= PARITY_BIT;
                    //сдвиг вправо, так как передача начинается с младшего бита
                    PS2_buf <= {PS2_dat_sync[1], PS2_buf[7:1]};                     
                end 
                
                //обработка бита чётности
                PARITY_BIT: begin
                    if ((^PS2_buf) == PS2_dat_sync[1])
                        state <= STOP_BIT;
                    else
                        state <= IDLE;
                end
                
                STOP_BIT: begin
                    if (!PS2_dat_sync[1]) // изменено: вместо PS2_dat - PS2_dat_sync[1]
                        ERROR <= 1;
                    R_O <= 1;
                    state <= WAIT_START_BIT;
                    end
            endcase
        end
        else if (state == WAIT_START_BIT) begin //дополнительная проверка введена, чтобы R_O был активен только один такт после приёма
                R_O <= 0;                
            end
end

always@(posedge clk)
begin
    if(neg_PS2_clk)
    begin
        cnt <= cnt + 1;
        if(cnt == 4'd10)
            cnt <= 0;
    end
end

endmodule