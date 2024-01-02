`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Garrett Knuf
// Date Created: 12/21/2023
// 
// Project Name: WS2812B
// Module Name: ws2812b
// Description: This module emulates the behavior of a WS2812b RGB LED driver.
//  It has a single data in pin (din) and a single data out pin (dout). It either
//  uses the data input to update its internal state or passes it onto its output
//  to a cascaded WS2812b. It has 8-8-8 RGB bit resolution and uses PWM signals
//  to create the desired intensity of each color. An internal 100 MHz clock is
//  used to control system timing.
//
//  See WS2812b datasheet to understand communication protocol and refer to
//  WS2812b_arch.png to see module block diagram. 
//////////////////////////////////////////////////////////////////////////////////

module ws2812b(
    input clk_100MHz,
    input din,      // data in
    output dout,    // data out
    output rled,    // red LED PWM signal
    output gled,    // green LED PWM signal
    output bled     // blue LED PWM signal
    );
    
    parameter SHIFT_REG_BITS = 24;      // number of bits in shift register
    parameter SAMPLE_CNTR_MAX = 60;     // sampling duration lasts 600 ns
    parameter RESET_CNTR_MAX = 5000;    // 50 us minimum reset duration
    parameter CLOCK_PERIOD = 10;        // 100 MHz (10 ns period)
    
    reg [12:0] reset_cntr;  // determines how long din held low 
    reg [5:0] sample_cntr;  // determines when sampling duration expires
    reg [4:0] data_cntr;    // counts number of data bits collected
    reg [8:0] pwm_prescale; // clock divider for PWM prescaling
    reg [7:0] pwm_cntr_r;   // red LED PWM compare match register
    reg [7:0] pwm_cntr_g;   // green LED PWM compare match register
    reg [7:0] pwm_cntr_b;   // blue LED PWM compare match register
    reg [23:0] shift_reg;   // data shift register
    reg [23:0] data_latch;  // data latched from shift register
    reg data_in;            // alias for din
    
    wire reset_active;
    wire data_bit;
    wire data_recv;
    wire data_clk;
    wire pwm_clk;
    
    // reset command (din LOW for at least 50 us)
    assign reset_active = (reset_cntr == RESET_CNTR_MAX); 
    
    // data bit to sampling into shift register
    // 1 if din HIGH for greater than 60 us, 0 otherwise
    assign data_bit = (sample_cntr == SAMPLE_CNTR_MAX);
    
    // signal whether all 24 bits of data are received from din
    assign data_recv = (data_cntr == SHIFT_REG_BITS + 1);
    
    // clock for 24-bit shift register
    assign data_clk = ~din & ~data_recv;
    
    // divides clock by 512 to give 195312.5 kHz clock to PWM counters
    assign pwm_clk = pwm_prescale[8];
    
    // output data if cascading WS2812B if all data is received
    assign dout = data_recv & din;
    
    // generate PWM signals for RGB LEDs
    assign rled = (pwm_cntr_r[7:0] < data_latch[15:8]);
    assign gled = (pwm_cntr_g[7:0] < data_latch[23:16]);
    assign bled = (pwm_cntr_b[7:0] < data_latch[7:0]);
    
    initial begin
        reset_cntr <= 0;
        sample_cntr <= 0;
        data_cntr <= 0;
        pwm_prescale <= 0;
        pwm_cntr_r <= 0;
        pwm_cntr_g <= 0;
        pwm_cntr_b <= 0;
        shift_reg <= 0;
        data_latch <= 0;
        data_in <= 0;
    end
    
    always @ (posedge data_clk) begin
        shift_reg[23:0] <= {shift_reg[22:0], data_bit};  
    end
    
    always @ (posedge data_recv) begin
        data_latch <= shift_reg;
    end
    
    always @ (posedge data_in) begin
        if (reset_active) begin
            data_cntr <= 0;
        end else begin
            if (data_cntr <= SHIFT_REG_BITS)
                data_cntr <= data_cntr + 1;
        end  
    end
    
    always @ (posedge clk_100MHz) begin
        data_in <= din;
        pwm_prescale <= pwm_prescale + 1;
        if (din) begin
            reset_cntr <= 0;
            if (sample_cntr < SAMPLE_CNTR_MAX)
                sample_cntr <= sample_cntr + 1;
        end else begin
            if (reset_cntr < RESET_CNTR_MAX) 
                reset_cntr <= reset_cntr + 1;  
            sample_cntr <= 0;
        end
    end
    
    always @ (negedge pwm_clk) begin
        pwm_cntr_r <= pwm_cntr_r + 1;
        pwm_cntr_g <= pwm_cntr_g + 1;
        pwm_cntr_b <= pwm_cntr_b + 1;
    end
    
endmodule
