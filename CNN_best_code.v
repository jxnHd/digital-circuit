module CNN(
    // input
    input                           clk,
    input                           rst_n,
    input                           in_valid,
    input      signed   [15:0]      in_data,
    input                           opt,
    // output
    output reg                      out_valid, 
    output reg signed   [15:0]      out_data	
);

///////////////////////////////////////////////////////
//                   Parameter                       //
///////////////////////////////////////////////////////

parameter IDLE = 2'd0;
parameter READ = 2'd1;
parameter CALC = 2'd2;
parameter OUT  = 2'd3;

///////////////////////////////////////////////////////
//                       FSM                         //
///////////////////////////////////////////////////////

reg [1:0] cs, ns;

///////////////////////////////////////////////////////
//                   wire & reg                      //
///////////////////////////////////////////////////////

reg signed [4:0] image [0:5][0:5];
reg signed [9:0] feature_map [0:3][0:3];
reg signed [9:0] relu_layer [0:3][0:3];
reg opt_save;
reg [5:0] cnt;
reg [1:0] x, nx, y, ny;
reg signed [9:0] a, b, c, d, nout_data;

integer i, j;

///////////////////////////////////////////////////////
//                   FSM design                      //
///////////////////////////////////////////////////////

always @(posedge clk, negedge rst_n) begin
	if (!rst_n) cs <= IDLE;
	else cs <= ns;
end 

always @(*) begin
	case (cs)
		IDLE: begin
			if (in_valid) ns = READ;
			else ns = cs;
		end
		// Read from in_data to image
		READ: begin
			if (cnt == 6'd34) ns = CALC;
			else ns = cs;
		end
		// Multiply 16 positions of image by in_data(kernel), then accumulate and store the result in feature_map.
		CALC: begin
			if (in_valid) ns = cs;
			else ns = OUT;
		end
		OUT: begin
			if (cnt == 6'd3) ns = IDLE;
			else ns = cs;
		end
		default: ns = cs;
	endcase
end

///////////////////////////////////////////////////////
//                     design                        //
///////////////////////////////////////////////////////

// cnt: counter for counting the number of cycle in a certain state
always @(posedge clk, negedge rst_n) begin
	if (!rst_n) cnt <= 6'd0;
	else begin
		case (cs)
			READ: begin
				if (cnt < 6'd34) cnt <= cnt + 6'd1;
				else cnt <= 6'd0;

			end
			OUT: begin
				if (cnt < 6'd3) cnt <= cnt + 6'd1;
				else cnt <= 6'd0;
			end
			default: cnt <= cnt;
		endcase
	end
end

///////////////////////////////////////////////////////
//                     input                         //
///////////////////////////////////////////////////////

// opt_save: save the given opt
always @(posedge clk) begin
	case (cs)
		IDLE: if (in_valid) opt_save <= opt;
		default: opt_save <= opt_save;
	endcase
end

// image: store the given 36 image values
always @(posedge clk) begin
	case (cs)
		IDLE, READ: begin
			if (in_valid) begin

				// Use shift registers to avoid synthesizing decoders, tri-state buffers, or anything that will increase the area.
				// Can use "for loop" for simplicity

				image[5][5] <= in_data;
				image[5][4] <= image[5][5];
				image[5][3] <= image[5][4];
				image[5][2] <= image[5][3];
				image[5][1] <= image[5][2];
				image[5][0] <= image[5][1];

				image[4][5] <= image[5][0];
				image[4][4] <= image[4][5];
				image[4][3] <= image[4][4];
				image[4][2] <= image[4][3];
				image[4][1] <= image[4][2];
				image[4][0] <= image[4][1];

				image[3][5] <= image[4][0];
				image[3][4] <= image[3][5];
				image[3][3] <= image[3][4];
				image[3][2] <= image[3][3];
				image[3][1] <= image[3][2];
				image[3][0] <= image[3][1];

				image[2][5] <= image[3][0];
				image[2][4] <= image[2][5];
				image[2][3] <= image[2][4];
				image[2][2] <= image[2][3];
				image[2][1] <= image[2][2];
				image[2][0] <= image[2][1];

				image[1][5] <= image[2][0];
				image[1][4] <= image[1][5];
				image[1][3] <= image[1][4];
				image[1][2] <= image[1][3];
				image[1][1] <= image[1][2];
				image[1][0] <= image[1][1];

				image[0][5] <= image[1][0];
				image[0][4] <= image[0][5];
				image[0][3] <= image[0][4];
				image[0][2] <= image[0][3];
				image[0][1] <= image[0][2];
				image[0][0] <= image[0][1];
			end
			else image <= image;
		end
		default: image <= image;
	endcase
end

///////////////////////////////////////////////////////
//                    calculation                    //
///////////////////////////////////////////////////////

// x, y: recording the upper-left position of the 4x4 matrix that should be multiplied by the current in_data(kernel) value

// x
always @(posedge clk) begin
	x <= nx;
end

// nx
always @(*) begin
	case (cs)
		CALC: begin
			if (x < 2'd2) nx = x + 2'd1;
			else nx = 2'd0;
		end
		default: nx = 2'd0;
	endcase
end

// y
always @(posedge clk) begin
	y <= ny;
end

// ny
always @(*) begin
	case (cs)
		CALC: begin
			if (x < 2'd2) ny = y;
			else begin
				if (y < 2'd2) ny = y + 2'd1;
				else ny = 2'd0;
			end
		end
		default: ny = 2'd0;
	endcase
end

// feature_map: store the convolution result
always @(posedge clk) begin
	case (cs)
		IDLE: begin
			for (int i = 0 ; i < 4 ; i = i + 1) begin
				for (int j = 0 ; j < 4 ; j = j + 1) begin
					feature_map[i][j] <= 'd0;
				end
			end
		end
		CALC: begin
			if (in_valid) begin
				for (int i = 0 ; i < 4 ; i = i + 1) begin
					for (int j = 0 ; j < 4 ; j = j + 1) begin
						feature_map[i][j] <= feature_map[i][j] + in_data * image[y+i][x+j];

					end
				end
			end
			else feature_map <= feature_map;
		end
		default: feature_map <= feature_map;
	endcase
end

// relu_layer: store the result after relu activation function
always @(*) begin
	if (opt_save) begin
		relu_layer = feature_map;
	end
	else begin
		for (int i = 0 ; i < 4 ; i = i + 1) begin
			for (int j = 0 ; j < 4 ; j = j + 1) begin
				if (feature_map[i][j][9]) relu_layer[i][j] = 'd0;
				else relu_layer[i][j] = feature_map[i][j];
			end
		end
	end
end

// Max-pooling module, using only one module to calculate the corresponding output for 4 output cycles.
// the inputs a, b, c, d switch to the next value after every cycle in OUT state
// order of (a, b, c, d): upper left 4 -> upper right 4 -> lower left 4 -> lower right 4
max max0 ( .a(a), .b(b), .c(c), .d(d), .out(nout_data) );

// a
always @(*) begin
	case (cs)
		CALC: begin
			if (in_valid) a = 'd0;
			else a = relu_layer[0][0];
		end
		OUT: begin
			case (cnt)
				'd0: a = relu_layer[0][2];
				'd1: a = relu_layer[2][0];
				'd2: a = relu_layer[2][2];
				default: a = 'd0;
			endcase
		end
		default: a = 'd0;
	endcase
end

// b
always @(*) begin
	case (cs)
		CALC: begin
			if (in_valid) b = 'd0;
			else b = relu_layer[0][1];
		end
		OUT: begin
			case (cnt)
				'd0: b = relu_layer[0][3];
				'd1: b = relu_layer[2][1];
				'd2: b = relu_layer[2][3];
				default: b = 'd0;
			endcase
		end
		default: b = 'd0;
	endcase
end

// c
always @(*) begin
	case (cs)
		CALC: begin
			if (in_valid) c = 'd0;
			else c = relu_layer[1][0];
		end
		OUT: begin
			case (cnt)
				'd0: c = relu_layer[1][2];
				'd1: c = relu_layer[3][0];
				'd2: c = relu_layer[3][2];
				default: c = 'd0;
			endcase
		end
		default: c = 'd0;
	endcase
end

// d
always @(*) begin
	case (cs)
		CALC: begin
			if (in_valid) d = 'd0;
			else d = relu_layer[1][1];
		end
		OUT: begin
			case (cnt)
				'd0: d = relu_layer[1][3];
				'd1: d = relu_layer[3][1];
				'd2: d = relu_layer[3][3];
				default: d = 'd0;
			endcase
		end
		default: d = 'd0;
	endcase
end

///////////////////////////////////////////////////////
//                     output                        //
///////////////////////////////////////////////////////

// out_data
always @(posedge clk, negedge rst_n) begin
	if (!rst_n) out_data <= 'd0;
	else begin
		case (ns)
			OUT: out_data <= nout_data;
			default: out_data <= 'd0;
		endcase
	end
end

// out_valid
always @(posedge clk, negedge rst_n) begin
	if (!rst_n) out_valid <= 1'b0;
	else begin
		case (ns)
			OUT: out_valid <= 1'b1;
			default: out_valid <= 1'b0;
		endcase
	end
end

endmodule

///////////////////////////////////////////////////////
//                    submodule                      //
///////////////////////////////////////////////////////

// module for max-pooling
module max(
    // input
    input signed [9:0] a,
    input signed [9:0] b,
    input signed [9:0] c,
    input signed [9:0] d,
    // output
    output signed [9:0] out
);

wire signed [9:0] temp1, temp2;

assign temp1 = (a > b) ? a : b;
assign temp2 = (c > d) ? c : d;
assign out = (temp1 > temp2) ? temp1 : temp2;

endmodule
