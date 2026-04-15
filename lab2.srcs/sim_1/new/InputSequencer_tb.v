`timescale 1ns / 1ps

module InputSequencer_tb;

//==============================================================================
// ÑÈÃÍÀËÛ
//==============================================================================
reg clk;
reg reset;
reg [3:0] digit;
reg digit_valid;
reg is_enter;
reg is_backspace;

wire [31:0] data_out;
wire [9:0] addr_out;
wire write_enable;
wire config_start;
wire [31:0] display_buffer;
wire input_error;
wire [7:0] error_code;
wire [3:0] input_stage;

//==============================================================================
// ÏÎÄÊËŞ×ÅÍÈÅ ÌÎÄÓËß
//==============================================================================
InputSequencer #(
    .MAX_N(16),
    .MAX_W(512)
) uut (
    .clk(clk),
    .reset(reset),
    .digit(digit),
    .digit_valid(digit_valid),
    .is_enter(is_enter),
    .is_backspace(is_backspace),
    .data_out(data_out),
    .addr_out(addr_out),
    .write_enable(write_enable),
    .config_start(config_start),
    .display_buffer(display_buffer),
    .input_error(input_error),
    .error_code(error_code),
    .input_stage(input_stage)
);

//==============================================================================
// ÒÀÊÒÎÂÛÉ ÑÈÃÍÀË
//==============================================================================
initial clk = 0;
always #5 clk = ~clk;  // 100 MHz

//==============================================================================
// ÇÀÄÀ×À: Îòïğàâêà öèôğû
//==============================================================================
task send_digit;
    input [3:0] d;
    begin
        digit = d;
        digit_valid = 1;
        is_enter = 0;
        is_backspace = 0;
        #10;
        digit_valid = 0;
        #10;
    end
endtask

//==============================================================================
// ÇÀÄÀ×À: Îòïğàâêà Enter
//==============================================================================
task send_enter;
    begin
        digit = 4'h0;
        digit_valid = 1;
        is_enter = 1;
        is_backspace = 0;
        #10;
        digit_valid = 0;
        is_enter = 0;
        #10;
    end
endtask

//==============================================================================
// ÇÀÄÀ×À: Îòïğàâêà Backspace
//==============================================================================
task send_backspace;
    begin
        digit = 4'hF;
        digit_valid = 1;
        is_enter = 0;
        is_backspace = 1;
        #10;
        digit_valid = 0;
        is_backspace = 0;
        #10;
    end
endtask

//==============================================================================
// ÎÑÍÎÂÍÎÉ ÁËÎÊ ÒÅÑÒÎÂ
//==============================================================================
initial begin
    reset = 1;
    digit = 0;
    digit_valid = 0;
    is_enter = 0;
    is_backspace = 0;
    
    #20;
    reset = 0;
    #30;
    
    //==========================================================================
    // ÒÅÑÒ 1: Óñïåøíûé ââîä N=2, W=5, weights=[1,3], prices=[1,4]
    //==========================================================================
    $display("\n=== ÒÅÑÒ 1: Óñïåøíûé ââîä ===");
    
    // N = 2
    send_digit(4'h2);
    #50;
    $display("N ââåä¸í: display_buffer = %h, stage = %d", display_buffer, input_stage);
    send_enter();
    #50;
    
    // W = 5
    send_digit(4'h5);
    #50;
    $display("W ââåä¸í: display_buffer = %h, stage = %d", display_buffer, input_stage);
    send_enter();
    #50;
    
    // Weight[0] = 1
    send_digit(4'h1);
    send_enter();
    #50;
    
    // Weight[1] = 3
    send_digit(4'h3);
    send_enter();
    #50;
    
    // Price[0] = 1
    send_digit(4'h1);
    send_enter();
    #50;
    
    // Price[1] = 4
    send_digit(4'h4);
    send_enter();
    #50;
    
    // Ôèíàëüíûé Enter
    send_enter();
    #100;
    
    $display("config_start = %b", config_start);
    $display("input_stage = %d (îæèäàëîñü 7 = DONE)", input_stage);
    
    if (input_stage == 4'd7)
        $display("ÒÅÑÒ 1 ÏĞÎÉÄÅÍ");
    else
        $error("ÒÅÑÒ 1 ÏĞÎÂÀËÅÍ");
    
    #100;
    
    //==========================================================================
    // ÒÅÑÒ 2: Îøèáêà N > 16
    //==========================================================================
    $display("\n=== ÒÅÑÒ 2: Îøèáêà N > 16 ===");
    
    reset = 1;
    #20;
    reset = 0;
    #30;
    
    // N = 20 (áîëüøå MAX_N=16)
    send_digit(4'h2);
    send_digit(4'h0);
    send_enter();
    #100;
    
    $display("input_error = %b, error_code = %d", input_error, error_code);
    
    if (error_code == 8'd1)
        $display("ÒÅÑÒ 2 ÏĞÎÉÄÅÍ (îøèáêà N)");
    else
        $error("ÒÅÑÒ 2 ÏĞÎÂÀËÅÍ");
    
    #100;
    
    //==========================================================================
    // ÒÅÑÒ 3: Backspace
    //==========================================================================
    $display("\n=== ÒÅÑÒ 3: Backspace ===");
    
    reset = 1;
    #20;
    reset = 0;
    #30;
    
    // Ââîä "23", çàòåì Backspace ? äîëæíî îñòàòüñÿ "2"
    send_digit(4'h2);
    send_digit(4'h3);
    #50;
    $display("Ïîñëå ââîäà 23: display_buffer = %h", display_buffer);
    
    send_backspace();
    #50;
    $display("Ïîñëå Backspace: display_buffer = %h (îæèäàëîñü 2)", display_buffer);
    
    if (display_buffer == 32'h2)
        $display("ÒÅÑÒ 3 ÏĞÎÉÄÅÍ (Backspace)");
    else
        $error("ÒÅÑÒ 3 ÏĞÎÂÀËÅÍ");
    
    #100;
    
    //==========================================================================
    // ÈÒÎÃÈ
    //==========================================================================
    $display("\n=== ÂÑÅ ÒÅÑÒÛ ÇÀÂÅĞØÅÍÛ ===");
    $finish;
end

endmodule