`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.04.2026 15:46:46
// Design Name: 
// Module Name: PS2_tb
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


module PS2_tb();

reg clk = 0;
reg reset;
wire PS2_clk;
reg PS2_dat = 1;

wire R_O, ERROR;
wire [7:0] out;

reg [10:0] package;
reg PS2_clk_generator = 1;
reg PS2_clk_mask = 1;
always #20 PS2_clk_generator <= ~PS2_clk_generator;
assign PS2_clk = PS2_clk_generator | PS2_clk_mask;

PS2 uut_PS2(
    .clk(clk),
    .reset(reset),
    .PS2_clk(PS2_clk),
    .PS2_dat(PS2_dat),
    .R_O(R_O),
    .ERROR(ERROR),
    .out(out)
);

always #5 clk <= ~clk;

initial
begin
    @(posedge clk)
    reset <= 1;
    @(posedge clk)
    reset <= 0;
    package <= {1'b1, 1'b1, 8'hF0, 1'b0}; 
    //передаются биты от младшего к старшему, например число F0 передаётся как 0F 
    @(posedge PS2_clk_generator)
    PS2_clk_mask <= 0;
    PS2_dat <= package[0];
    @(posedge PS2_clk_generator)
    PS2_dat <= package[1];
    @(posedge PS2_clk_generator)
    PS2_dat <= package[2];
    @(posedge PS2_clk_generator)
    PS2_dat <= package[3];
    @(posedge PS2_clk_generator)
    PS2_dat <= package[4];
    @(posedge PS2_clk_generator)
    PS2_dat <= package[5];
    @(posedge PS2_clk_generator)
    PS2_dat <= package[6];
    @(posedge PS2_clk_generator)
    PS2_dat <= package[7];
    @(posedge PS2_clk_generator)
    PS2_dat <= package[8];
    @(posedge PS2_clk_generator)
    PS2_dat <= package[9];
    @(posedge PS2_clk_generator)
    PS2_dat <= package[10];
    @(posedge PS2_clk_generator)
    PS2_clk_mask <= 1;
    
    wait(R_O)
    $display("=========== Тест 1 ============\npackage = %b, data = %h \nout = %h, ERROR = %b", package[10:0], package[8:1], out, ERROR);
    
    @(posedge PS2_clk_generator)
    package <= {1'b1, 1'b1, 8'hF0, 1'b1}; 
    //передаются биты от младшего к старшему, например число F0 передаётся как 0F 
    @(posedge PS2_clk_generator)
    PS2_clk_mask <= 0;
    PS2_dat <= package[0];
    @(posedge PS2_clk_generator)
    PS2_dat <= package[1];
    @(posedge PS2_clk_generator)
    PS2_dat <= package[2];
    @(posedge PS2_clk_generator)
    PS2_dat <= package[3];
    @(posedge PS2_clk_generator)
    PS2_dat <= package[4];
    @(posedge PS2_clk_generator)
    PS2_dat <= package[5];
    @(posedge PS2_clk_generator)
    PS2_dat <= package[6];
    @(posedge PS2_clk_generator)
    PS2_dat <= package[7];
    @(posedge PS2_clk_generator)
    PS2_dat <= package[8];
    @(posedge PS2_clk_generator)
    PS2_dat <= package[9];
    @(posedge PS2_clk_generator)
    PS2_dat <= package[10];
    @(posedge PS2_clk_generator)
    PS2_clk_mask <= 1;
    
    wait(R_O)
    $display("=========== Тест 2 ============\npackage = %b, data = %h \nout = %h, ERROR = %b", package[10:0], package[8:1], out, ERROR);
    
    @(posedge PS2_clk_generator)
    package <= {1'b1, 1'b0, 8'hF0, 1'b0}; 
    //передаются биты от младшего к старшему, например число F0 передаётся как 0F 
    @(posedge PS2_clk_generator)
    PS2_clk_mask <= 0;
    PS2_dat <= package[0];
    @(posedge PS2_clk_generator)
    PS2_dat <= package[1];
    @(posedge PS2_clk_generator)
    PS2_dat <= package[2];
    @(posedge PS2_clk_generator)
    PS2_dat <= package[3];
    @(posedge PS2_clk_generator)
    PS2_dat <= package[4];
    @(posedge PS2_clk_generator)
    PS2_dat <= package[5];
    @(posedge PS2_clk_generator)
    PS2_dat <= package[6];
    @(posedge PS2_clk_generator)
    PS2_dat <= package[7];
    @(posedge PS2_clk_generator)
    PS2_dat <= package[8];
    @(posedge PS2_clk_generator)
    PS2_dat <= package[9];
    @(posedge PS2_clk_generator)
    PS2_dat <= package[10];
    @(posedge PS2_clk_generator)
    PS2_clk_mask <= 1;
    
    wait(R_O)
    $display("=========== Тест 3 ============\npackage = %b, data = %h \nout = %h, ERROR = %b", package[10:0], package[8:1], out, ERROR);
    
    @(posedge PS2_clk_generator)
    package <= {1'b0, 1'b1, 8'hF0, 1'b0}; 
    //передаются биты от младшего к старшему, например число F0 передаётся как 0F 
    @(posedge PS2_clk_generator)
    PS2_clk_mask <= 0;
    PS2_dat <= package[0];
    @(posedge PS2_clk_generator)
    PS2_dat <= package[1];
    @(posedge PS2_clk_generator)
    PS2_dat <= package[2];
    @(posedge PS2_clk_generator)
    PS2_dat <= package[3];
    @(posedge PS2_clk_generator)
    PS2_dat <= package[4];
    @(posedge PS2_clk_generator)
    PS2_dat <= package[5];
    @(posedge PS2_clk_generator)
    PS2_dat <= package[6];
    @(posedge PS2_clk_generator)
    PS2_dat <= package[7];
    @(posedge PS2_clk_generator)
    PS2_dat <= package[8];
    @(posedge PS2_clk_generator)
    PS2_dat <= package[9];
    @(posedge PS2_clk_generator)
    PS2_dat <= package[10];
    @(posedge PS2_clk_generator)
    PS2_clk_mask <= 1;
    
    wait(R_O)
    $display("=========== Тест 4 ============\npackage = %b, data = %h \nout = %h, ERROR = %b", package[10:0], package[8:1], out, ERROR);
    
end

endmodule
