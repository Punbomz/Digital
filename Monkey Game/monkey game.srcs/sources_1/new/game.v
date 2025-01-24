module game (
    input clk,                // 100MHz clock
    input reset,              // Reset signal
    input left_btn,           // Move character left
    input right_btn,          // Move character right
    input [9:0] x,            // Current pixel x-coordinate (from VGA controller)
    input [9:0] y,            // Current pixel y-coordinate (from VGA controller)
    output reg [11:0] rgb,    // RGB output for VGA
    output reg game_over,     // Game over signal
    output reg [7:0] score    // Score to be displayed
);

    // Screen parameters
    parameter SCREEN_WIDTH = 640;
    parameter SCREEN_HEIGHT = 480;

    // Character parameters
    parameter CHAR_WIDTH = 45;
    parameter CHAR_HEIGHT = 50;
    parameter CHAR_Y = SCREEN_HEIGHT - 20;

    // Circle parameters
    parameter CIRCLE_RADIUS = 5;

    // Initial positions
    reg [9:0] char_x = (SCREEN_WIDTH - CHAR_WIDTH) / 2;
    reg [9:0] circle_x = SCREEN_WIDTH / 2;
    reg [9:0] circle_y = 0;
    reg [9:0] prev_circle_x = SCREEN_WIDTH / 2;

    // Movement speed control
    reg [19:0] char_speed_count = 0;   // Counter for character speed
    reg [19:0] circle_speed_count = 0; // Counter for circle speed
    parameter CHAR_SPEED_DIV = 500_000; // Character speed divisor
    parameter CIRCLE_SPEED_DIV = 600_000; // Circle speed divisor 

    // Random circle X position generator
    reg [15:0] rand_seed = 16'hACE1;

    // Score counter
    reg [7:0] current_score = 0;

    // Score LED timer
    reg [19:0] score_led_timer = 0;    // Timer for LED

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            char_x <= (SCREEN_WIDTH - CHAR_WIDTH) / 2;
            circle_x <= SCREEN_WIDTH / 2;
            circle_y <= 0;
            prev_circle_x <= SCREEN_WIDTH / 2;
            rand_seed <= 16'hACE1;
            game_over <= 0;
            score <= 0;
            current_score <= 0;
            char_speed_count <= 0;
            circle_speed_count <= 0;
            score_led_timer <= 0;
        end else begin
            // Character movement speed control
            if (char_speed_count >= CHAR_SPEED_DIV) begin
                char_speed_count <= 0;
                if (left_btn && char_x > 1)
                    char_x <= char_x - 1;
                else if (right_btn && char_x < SCREEN_WIDTH - CHAR_WIDTH - 1)
                    char_x <= char_x + 1;
            end else begin
                char_speed_count <= char_speed_count + 1;
            end

            // Stop circle movement if game over
            if (!game_over) begin
                // Circle movement speed control
                if (circle_speed_count >= CIRCLE_SPEED_DIV) begin
                    circle_speed_count <= 0;
                    if (circle_y < SCREEN_HEIGHT) begin
                        circle_y <= circle_y + 1;
                    end else begin
                        // Check if the circle has fallen past the character
                        if (circle_y + CIRCLE_RADIUS >= CHAR_Y && 
                            circle_x >= char_x && circle_x <= char_x + CHAR_WIDTH) begin
                            // Circle collided with the character, score!
                            current_score <= current_score + 1;
                        end else if (circle_y + CIRCLE_RADIUS >= SCREEN_HEIGHT) begin
                            // Circle has fallen past the bottom of the screen without collision
                            game_over <= 1;  // Set game over flag
                        end

                        // Reset circle position and randomize X position
                        circle_y <= 0;
                        rand_seed <= {rand_seed[14:0], rand_seed[15] ^ rand_seed[13]} ^ circle_y;
                        circle_x <= rand_seed % (SCREEN_WIDTH - 2 * CIRCLE_RADIUS) + CIRCLE_RADIUS;

                        // Ensure the new position is different from the previous position
                        if (circle_x == prev_circle_x) begin
                            circle_x <= (circle_x + 20) % (SCREEN_WIDTH - 2 * CIRCLE_RADIUS) + CIRCLE_RADIUS;
                        end

                        prev_circle_x <= circle_x; // Update the previous position
                    end
                end else begin
                    circle_speed_count <= circle_speed_count + 1;
                end
            end

            // Update score
            score <= current_score;
        end
    end

    // RGB output logic
    always @(*) begin
        if (y >= CHAR_Y && y < CHAR_Y + CHAR_HEIGHT && x >= char_x && x < char_x + CHAR_WIDTH) begin
            rgb = 12'b1111_1111_1111; // White character
        end else if ((x - circle_x) * (x - circle_x) + (y - circle_y) * (y - circle_y) <= CIRCLE_RADIUS * CIRCLE_RADIUS) begin
            rgb = 12'b0000_1111_0000; // Green circle
        end else if (game_over) begin
            rgb = 12'b0000_0000_1111; // Red background when game is over
        end else begin
            rgb = 12'b0000_0000_0000; // Black background
        end
    end

endmodule
