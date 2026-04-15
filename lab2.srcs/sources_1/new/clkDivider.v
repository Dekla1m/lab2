`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.04.2026 20:58:48
// Design Name: 
// Module Name: clkDivider
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


`timescale 1ns / 1ps

module clkDivider #(
    parameter DIVISOR = 12500
)(
    input wire clk,
    input wire RESET,
    output reg tick  // Импульс 1 такт при достижении DIVISOR
);

reg [15:0] counter;

always @(posedge clk or posedge RESET) begin
    if (RESET) begin
        counter <= 16'd0;
        tick <= 1'b0;
    end else begin
        tick <= 1'b0;
        if (counter >= DIVISOR - 1) begin
            counter <= 16'd0;
            tick <= 1'b1;  // Импульс на 1 такт
        end else begin
            counter <= counter + 16'd1;
        end
    end
end

endmodule
