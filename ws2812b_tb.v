`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Garrett Knuf
// Date Created: 12/22/2023
// 
// Project Name: WS2812B
// Module Name: ws2812b_tb
// Description: This testbench tests two cascaded WS2812b modules. It emulates the
//  behavior of a device sending data into the din pin of the WS2812b. The
//  state of internal registers in the WS2812b and the dout pin can be observed.
//////////////////////////////////////////////////////////////////////////////////

module ws2812b_tb();

    parameter DIN_CLOCK_T = 1250;   // din period (1.25 us)
    parameter DATA_BITS = 48;       // bits of data to send on din

    reg din, clk_100MHz;
    wire dout1, rled1, gled1, bled1;
    wire dout2, rled2, gled2, bled2;
    
    // Testing signals
    reg [(DATA_BITS-1):0] data;
    reg data_clk;
    reg [7:0] data_cntr;
    
    ws2812b uut1 (
        .clk_100MHz(clk_100MHz),
        .din(din),
        .dout(dout1),
        .rled(rled1),
        .gled(gled1),
        .bled(bled1));
                  
    ws2812b uut2 (
        .clk_100MHz(clk_100MHz),
        .din(dout1),
        .dout(dout2),
        .rled(rled2),
        .gled(gled2),
        .bled(bled2));
                 
    initial begin
        din <= 0;
        data_clk <= 0;
        clk_100MHz <= 0;
        data_cntr <= 0;
        
        // sample data to send on din
        data <= 'h40c07f007fff;
    end                
    
    always #(DIN_CLOCK_T / 2) data_clk = ~data_clk;
    
    always #5 clk_100MHz = ~clk_100MHz;
    
    always @ (posedge data_clk) begin
        if (data_cntr != DATA_BITS+1) begin 
            data_cntr <= data_cntr + 1;
            din <= 1;
            if (data[DATA_BITS-1] == 1) begin
                #900 // 1 code, high voltage time (0.9 us)
                din <= 0;
            end else begin
                #350 // 0 code, low voltage time (0.35 us)
                din <= 0;
            end
            
            // shift to next bit
            data[(DATA_BITS-1):0] <= {data[(DATA_BITS-2):0], 1'b0};
        end
    end

endmodule
