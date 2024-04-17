module CNN(
    input clk,
    input rst_n,
    input in_valid,
    input signed [15:0] in_data,
    input opt,
    output reg out_valid,
    output reg signed [15:0] out_data
);

    // Parameters
    parameter IDLE = 4'd0;
    parameter READ = 4'd1;
    parameter CALC = 4'd2;
    parameter OUT  = 4'd3;

    // Registers
    reg [2:0] cs, ns;
    reg [2:0] x_cnt, y_cnt;
    reg signed [15:0] image [0:5][0:5];
    reg signed [15:0] kernel [0:2][0:2];
    reg signed [15:0] conv [0:3][0:3];
    reg signed [15:0] buffer [0:1][0:3];
    reg signed [15:0] max [0:1][0:1];
    reg signed [15:0] outv [0:3];
    reg opt_reg;
    reg out_valid_reg;
    reg [6:0] k;
    reg [15:0] c;
    reg [15:0] out;
    reg signed [15:0] max_value;
    //reg [2:0] out_cnt;
    //reg [4:0] conv_cnt;
    reg [1:0] x, y; // Declare 'x' and 'y' registers
    reg signed [15:0] result [0:3];
    integer i, j ;

    // FSM
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)begin
            cs<=IDLE;
        end else begin
            cs <=ns;
        end
    end

    // FSM design
    always @(*) begin
              
        case (cs)
            IDLE: ns = in_valid ? READ : IDLE;
            READ: ns = (k == 6'd45) ? CALC : READ;
            CALC: ns = (c == 16'd20 && x_cnt == 3'd0 && y_cnt == 3'd0) ? OUT : CALC;
            OUT:  ns = (out == 4) ? IDLE : OUT;
            default: ns = IDLE;
        endcase
    end
    // Output handling
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_valid <= 1'd0;
            out <= 0;
        end else begin
            out_valid <= 1'd0;
        end 
    end

    // Opt reg setting //can you make this part be systhesis
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            opt_reg <= 1'd0;
        end else if (ns == READ && k==6'd1) begin
            opt_reg <= opt;
        end 
    end

    //Initalize
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)begin
           // c = 16'd0;
           // k = 16'd0;
        end else if(in_valid)begin
            c = 16'd0;
        end else begin
            k=6'd0;
        end 
    end
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)begin
            out = 16'd0;
        end else if(ns == OUT)begin
            out = out + 16'd1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)begin

        end else if(in_valid)begin
            out_valid <= 1'b0;
            out_data <= 16'd0;
            out <= 0;
        end else begin
            out_data <= 16'd0;
        end

    end

    


    // Pointer
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_cnt <= 3'd0;
            y_cnt <= 3'd0;
        end else if (ns == READ) begin
            if (k < 6'd36) begin
                if (x_cnt == 3'd5) begin
                    if (y_cnt == 3'd5) begin
                        x_cnt <= 3'd0;
                        y_cnt <= 3'd0;
                    end else begin
                        x_cnt <= 3'd0;
                        y_cnt <= y_cnt + 3'd1;
                    end
                end else begin
                    x_cnt <= x_cnt + 3'd1;
                    y_cnt <= y_cnt;
                end
            end else begin
                if (x_cnt == 3'd2) begin
                    if (y_cnt == 3'd2) begin
                        x_cnt <= 3'd0;
                        y_cnt <= 3'd0;
                    end else begin
                        x_cnt <= 3'd0;
                        y_cnt <= y_cnt + 3'd1;
                    end
                end else begin
                    x_cnt <= x_cnt + 3'd1;
                    y_cnt <= y_cnt;
                end
            end
        end else if (ns == CALC) begin
            if(c<16'd16)begin
                if (x_cnt == 3'd3) begin
                    if (y_cnt == 3'd3) begin
                        x_cnt <= 3'd0;
                        y_cnt <= 3'd0;
                    end else begin
                        x_cnt <= 3'd0;
                        y_cnt <= y_cnt + 3'd1;
                    end
                end else begin
                    x_cnt <= x_cnt + 3'd1;
                    y_cnt <= y_cnt;
                end
            end else begin 
                x_cnt<=3'd0;
                y_cnt<=3'd0;
            end
        end else if (ns == OUT) begin
            y_cnt <= 3'd0;
            x_cnt <= 3'd0;
        end
    end
    

    //input image
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)begin
            for (i = 0; i < 6; i++)begin
                for(j = 0; j<6;j++) begin
                    image[i][j] <= 8'd0;
                end
            end
            for (i = 0; i < 3; i++)begin
                for(j = 0; j<3;j++) begin
                    kernel[i][j] <= 8'd0;
                end
            end
            for (i = 0; i < 4; i++)begin
                for(j = 0; j<4;j++) begin
                    conv[i][j] <= 4'd0;
                end
            end
            for(i = 0; i<2; i++)begin
                for(j = 0; j<4;j++)begin
                buffer[i][j] <= 8'd0;
                end
            end
        end else if(ns == READ)begin
            if(k<6'd36)begin
                image[x_cnt][y_cnt] <= in_data;
            end else begin
                kernel[x_cnt][y_cnt] <= in_data;
            end
            k = k+6'd1;
        end else if(in_valid)begin
            out_valid <= 1'b0;
            out <= 0;
        end else begin
            out_data <= 16'd0;
        end
    end

    // Image, Kernel Input, Convolution, ReLU
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)begin
            //out = 16'd0;
        end else if(ns == CALC) begin
            //c = 0;
            c = c+16'd1;
            if(c<=16'd16) begin
                if(opt_reg == 1'd0)begin
                    conv[x_cnt][y_cnt] <= (image[x_cnt][y_cnt]*kernel[0][0] + image[x_cnt][y_cnt+1]*kernel[0][1] 
                    + image[x_cnt][y_cnt+2]*kernel[0][2]+ image[x_cnt+1][y_cnt]*kernel[1][0] + image[x_cnt+1][y_cnt+1]*kernel[1][1] 
                    + image[x_cnt+1][y_cnt+2]*kernel[1][2]+ image[x_cnt+2][y_cnt]*kernel[2][0] 
                    + image[x_cnt+2][y_cnt+1]*kernel[2][1] + image[x_cnt+2][y_cnt+2]*kernel[2][2]) <0 ? 0:(image[x_cnt][y_cnt]*kernel[0][0] + image[x_cnt][y_cnt+1]*kernel[0][1] 
                    + image[x_cnt][y_cnt+2]*kernel[0][2]+ image[x_cnt+1][y_cnt]*kernel[1][0] + image[x_cnt+1][y_cnt+1]*kernel[1][1] 
                    + image[x_cnt+1][y_cnt+2]*kernel[1][2]+ image[x_cnt+2][y_cnt]*kernel[2][0] 
                    + image[x_cnt+2][y_cnt+1]*kernel[2][1] + image[x_cnt+2][y_cnt+2]*kernel[2][2]);
                end else begin
                    conv[x_cnt][y_cnt] <= (image[x_cnt][y_cnt]*kernel[0][0] + image[x_cnt][y_cnt+1]*kernel[0][1] 
                    + image[x_cnt][y_cnt+2]*kernel[0][2]+ image[x_cnt+1][y_cnt]*kernel[1][0] + image[x_cnt+1][y_cnt+1]*kernel[1][1] 
                    + image[x_cnt+1][y_cnt+2]*kernel[1][2]+ image[x_cnt+2][y_cnt]*kernel[2][0] 
                    + image[x_cnt+2][y_cnt+1]*kernel[2][1] + image[x_cnt+2][y_cnt+2]*kernel[2][2]);
                end
            end else begin
                //maxpooling part
                buffer[0][0] <= (conv[0][0]>conv[1][0])?conv[0][0]:conv[1][0];
                buffer[1][0] <= (conv[2][0]>conv[3][0])?conv[2][0]:conv[3][0];
                buffer[0][1] <= (conv[0][1]>conv[1][1])?conv[0][1]:conv[1][1];
                buffer[1][1] <= (conv[2][1]>conv[3][1])?conv[2][1]:conv[3][1];
                buffer[0][2] <= (conv[0][2]>conv[1][2])?conv[0][2]:conv[1][2];
                buffer[1][2] <= (conv[2][2]>conv[3][2])?conv[2][2]:conv[3][2];
                buffer[0][3] <= (conv[0][3]>conv[1][3])?conv[0][3]:conv[1][3];
                buffer[1][3] <= (conv[2][3]>conv[3][3])?conv[2][3]:conv[3][3];
                max[0][0] <= (buffer[0][0]>buffer[0][1])?buffer[0][0]:buffer[0][1];
                max[1][0] <= (buffer[1][0]>buffer[1][1])?buffer[1][0]:buffer[1][1];
                max[0][1] <= (buffer[0][2]>buffer[0][3])?buffer[0][2]:buffer[0][3];
                max[1][1] <= (buffer[1][2]>buffer[1][3])?buffer[1][2]:buffer[1][3];
                outv[0] <= max[0][0];
                outv[1] <= max[1][0];
                outv[2] <= max[0][1];
                outv[3] <= max[1][1];
            end
        end
    end
//Output
    always @(posedge clk or negedge rst_n)begin
        if (!rst_n) begin
            //out_valid <= 1'b0;
            out_data <= 16'd0;
            //out <= 16'd0;
        end
        else if (ns == OUT) begin
            out_valid <= 1'b1;
           // out = out +16'd1;
            if(out <=4)begin
                out_data <= outv[out-1];
            end else begin
                out_data <= 16'd0;
            end
        end
        else begin
            out_valid <= 1'b0;
            out_data <= 16'd0;
        end
    end
endmodule

