module top (
    // inputs
    input clk_100MHz,
    input reset,
    input left_btn,
    input right_btn,

    // outputs
    // VGA
    output hsync,
    output vsync,
    output [11:0] rgb,

    // Game
    output led,

    // 7-segment
    output [6:0] seg,  // 7-segment outputs (a-g)
    output dp,          // Decimal point
    output [3:0] an     // Common anode control
);

    // VGA signals
    wire video_on;
    wire [9:0] pixel_x, pixel_y;

    // RGB output for VGA
    wire [11:0] game_rgb;

    // VGA controller instantiation
    vga_controller vga (
        .clk_100MHz(clk_100MHz),
        .reset(reset),
        .video_on(video_on),
        .hsync(hsync),
        .vsync(vsync),
        .p_tick(),
        .x(pixel_x),
        .y(pixel_y)
    );

    // Game logic signals
    wire game_over;  // Signal to indicate game over
    wire [7:0] score; // Score to display

    // Game logic instantiation
    game game_logic (
        .clk(clk_100MHz),
        .reset(reset),
        .left_btn(left_btn),
        .right_btn(right_btn),
        .x(pixel_x),
        .y(pixel_y),
        .rgb(game_rgb),
        .game_over(game_over),
        .score(score)
    );

    // VGA RGB output
    assign rgb = (video_on) ? (game_over ? 12'b0000_0000_1111 : game_rgb) : 12'b0;

    // 7-segment display for score
    assign seg = decode_score(score);  // Decode score to 7-segment format
    assign dp = 1;  // Decimal point is always off
    assign an = 4'b1110;  // Display score in the first digit (other digits off)
    assign led = game_over;

    // Decode the score into 7-segment representation
    function [6:0] decode_score;
        input [7:0] score;
        begin
            case (score)
                8'd0: decode_score = 7'b1000000;
                8'd1: decode_score = 7'b1111001;
                8'd2: decode_score = 7'b0100100;
                8'd3: decode_score = 7'b0110000;
                8'd4: decode_score = 7'b0011001;
                8'd5: decode_score = 7'b0010010;
                8'd6: decode_score = 7'b0000010;
                8'd7: decode_score = 7'b1111000;
                8'd8: decode_score = 7'b0000000;
                8'd9: decode_score = 7'b0010000;
                default: decode_score = 7'b1111111; // Default: turn off display
            endcase
        end
    endfunction

endmodule
