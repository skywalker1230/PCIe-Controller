`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Taehyeon Lee
// 
// Create Date: 2024/08/03 18:29:48
// Design Name: 
// Module Name: ARBITER
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


module ARBITER_WRR
#(
    N_MASTER		= 4,	// 2
    DATA_SIZE		= 32,	// 1024
	HIGH_P			= 3,
	LOW_P			= 1
)
(
	input	wire				clk,
	input	wire				rst_n,  // _n means active low

    // configuration registers
	input	wire						src_valid_i[N_MASTER],	// when FIFO is not empty
	output	reg							src_ready_o[N_MASTER],
	input	wire [DATA_SIZE-1:0]		src_data_i[N_MASTER],

	output	reg							dst_valid_o,
	input	wire						dst_ready_i,
	output	reg [DATA_SIZE-1:0]			dst_data_o
);

	localparam H_CNT		= $clog2(HIGH_P);	// log2(3) = 2
	localparam L_CNT		= $clog2(LOW_P);	// log2(1) = 0
	reg	[H_CNT:0]		h_cnt,		h_cnt_n;
	reg	[L_CNT:0]		l_cnt,		l_cnt_n;
	
	localparam					S_0		= 3'b00,
								S_1		= 3'b01,
								S_2		= 3'b10,
								S_3		= 3'b11;
								
								
	reg [1:0]			state,	state_n;

	reg					valid,	valid_n;	// output
	reg	[DATA_SIZE-1:0]	data,	data_n;		// output

  
	always_ff @(posedge clk) begin
		if (!rst_n) begin
			state			<= 0;
			h_cnt			<= 0;
			l_cnt			<= 0;
			
			valid			<= 1'b0;
			data			<= 'd0;
		end
		else begin
			state			<= state_n;
			h_cnt			<= h_cnt_n;
			l_cnt			<= l_cnt_n;
			
			valid           <= valid_n;
			data            <= data_n;
		end
	end

    // WRR arbiter
	always_comb begin
		state_n		= state;
		data_n  	= data;
		valid_n		= 0;
		{src_ready_o[0],src_ready_o[1]}	= 2'b00;
		
		case(state)
			S_0: begin	// VC0 - ARBITER Empty
				//valid = 0;
				src_ready_o[0] = dst_ready_i || !valid;
				
				if(src_ready_o[0]) begin
					if(src_valid_i[0]) begin
						data_n = src_data_i[0];
						valid_n = 1;
						state_n = S_2;
					
						l_cnt_n = l_cnt + 1;
						if(l_cnt_n == LOW_P) begin // VC0 Phase End, VC1 Phase Start!
							l_cnt_n = 0;
							state_n = S_3;
						end
					end
					
					else if(src_valid_i[1]) begin	// VC0 Phase End, VC1 Phase Start!
						state_n = S_1;
						l_cnt_n = 0;
					end
				end
				
			end
			
			S_1: begin	// VC1 - ARBITER Empty
				//valid = 0;
				src_ready_o[1] = dst_ready_i || !valid;
				
				if(src_ready_o[1]) begin
					if(src_valid_i[1]) begin
						data_n = src_data_i[1];
						valid_n = 1;
						state_n = S_3;
					
						h_cnt_n = h_cnt + 1;
						if(h_cnt_n == HIGH_P) begin	// VC1 Phase End, VC0 Phase Start!
							h_cnt_n = 0;
							state_n = S_2;
						end
					end
					
					else if(src_valid_i[0]) begin	// VC1 Phase End, VC0 Phase Start!
						state_n = S_0;
						h_cnt_n = 0;
					end
				end
				
			end
			
			S_2: begin	// VC0 - ARBITER Full
				//valid = 1;
				src_ready_o[0] = dst_ready_i || !valid;
				
				if(src_ready_o[0]) begin
					if(src_valid_i[0]) begin
						data_n = src_data_i[0];
						valid_n = 1;
						state_n = S_2;
					
						l_cnt_n = l_cnt + 1;
						if(l_cnt_n == LOW_P) begin // VC0 Phase End, VC1 Phase Start!
							if (src_valid_i[1]) begin
								l_cnt_n = 0;
								state_n = S_3;
							end
							else begin
								l_cnt_n = LOW_P - 1;
								state_n = S_2;
							end
						end
					end
					
					else if(src_valid_i[1]) begin	// VC0 Phase End, VC1 Phase Start!
						state_n = S_1;
						l_cnt_n = 0;
					end
				end
				
			end
			
			S_3: begin	// VC1 - ARBITER Full
				//valid = 1;
				src_ready_o[1] = dst_ready_i || !valid;
				
				if(src_ready_o[1]) begin
					if(src_valid_i[1]) begin
						data_n = src_data_i[1];
						valid_n = 1;
						state_n = S_3;
					
						h_cnt_n = h_cnt + 1;
						if(h_cnt_n == HIGH_P) begin	// VC1 Phase End, VC0 Phase Start!
							if (src_valid_i[0]) begin
								h_cnt_n = 0;
								state_n = S_2;
							end
							else begin
								h_cnt_n = HIGH_P - 1;
								state_n = S_3;
							end
						end
					end
					
					else if(src_valid_i[0]) begin	// VC1 Phase End, VC0 Phase Start!
						state_n = S_0;
						h_cnt_n = 0;
					end
				end
				
			end
	
		endcase
	end

	assign  dst_valid_o             = valid;
	assign  dst_data_o              = data;

endmodule