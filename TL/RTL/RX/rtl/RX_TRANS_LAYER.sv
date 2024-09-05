`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/09 22:26:09
// Design Name: 
// Module Name: RX_TRANS_LAYER
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


module RX_TRANS_LAYER (
    input wire                      clk,
    input wire                      reset_n,
  
   //data link layer interface
    input wire     [1023:0]         tlp_data_in,
    input wire                      tlp_data_in_valid,
    output reg                      tlp_data_out_ready,
  
    //software interface
    //AXI_R_IF.SRC                axi_r_if   
    output reg     [2:0]            header_fmt_o,
    output reg     [4:0]            header_type_o,
    output reg     [2:0]            header_tc_o,
    output reg     [9:0]            header_length_o,
    //output reg     [3:0]            header_ID_o,
    output reg     [15:0]           header_requestID_o,
    output reg     [15:0]           header_completID_o,
	
    output reg     [511:0]          data_out,	// Flit Payload: 64Byte(512 bit)
    output reg     [31:0]           addr_out
);
    //ARBITER
    localparam	N_CH = 2; //two FIFO
    localparam	DATA_SIZE = 1024;//608; //Header(3DW)+data(512b)

    
    wire	fifo_full_0, fifo_full_1;
    wire	tlp_valid_0, tlp_valid_1;
	wire	fifo_empty_0, fifo_empty_1;
	//wire [DATA_SIZE-1:0] 	tlp_data;
    
	wire					src_ready[N_CH];
    wire [DATA_SIZE-1:0]	src_data[N_CH];
    wire					src_valid[N_CH];

    wire					dst_valid;
    wire					dst_ready;
    wire [DATA_SIZE-1:0]	dst_data;

    wire [2:0]        		tlp_TC;

    assign tlp_TC 		= tlp_data_in[598:596];
    assign tlp_valid_0 	= tlp_data_in_valid & (tlp_TC < 3'b101);	// TC0~TC4
    assign tlp_valid_1 	= tlp_data_in_valid & (tlp_TC >= 3'b101);	// TC5~TC7

    assign tlp_data_out_ready = (tlp_TC < 3'b101)? !fifo_full_0: !fifo_full_1;


    SAL_FIFO #(
    .DEPTH_LG2           (4),
    .DATA_WIDTH          (DATA_SIZE),
    .AFULL_THRES         ((1<<4)-1),
    .AEMPTY_THRES        (1)
)
    fifo_0
    (
    .clk(clk),
    .rst_n(reset_n),

    .full_o(fifo_full_0),
    .afull_o(),
    .wren_i(tlp_valid_0),
    .wdata_i(tlp_data_in),

    .empty_o(fifo_empty_0),
    .aempty_o(),
    .rden_i(src_ready[0]),
    .rdata_o(src_data[0])
);

    SAL_FIFO #(
    .DEPTH_LG2           (4),
    .DATA_WIDTH          (DATA_SIZE),
    .AFULL_THRES         ((1<<4)-1),
    .AEMPTY_THRES        (1)
)
    fifo_1
    (
    .clk(clk),
    .rst_n(reset_n),

    .full_o(fifo_full_1),
    .afull_o(),
    .wren_i(tlp_valid_1),
    .wdata_i(tlp_data_in),

    .empty_o(fifo_empty_1),
    .aempty_o(),
    .rden_i(src_ready[1]),
    .rdata_o(src_data[1])
);
    assign src_valid[0] = !fifo_empty_0;
    assign src_valid[1] = !fifo_empty_1;

    ARBITER_WRR #(
        .N_MASTER			(N_CH),
        .DATA_SIZE			(DATA_SIZE),
		.HIGH_P				(3),
		.LOW_P				(1)
    )
    u_arbiter
    (
    .clk(clk),
    .rst_n(reset_n),  // _n means active low
    
    .src_valid_i(src_valid),
    .src_ready_o(src_ready),
    .src_data_i(src_data),

    .dst_valid_o(dst_valid),
    .dst_ready_i(dst_ready),	// always 1
    .dst_data_o(dst_data)
);

    TLP_DEPACKETIZER u_tlp_depacketizer
(
    .data_i(dst_data),
    .tlp_ready_o(dst_ready),	// always 1
    .tlp_valid_i(dst_valid),

    .header_fmt_o(header_fmt_o),
    .header_type_o(header_type_o),
    .header_tc_o(header_tc_o),
    .header_length_o(header_length_o),
    //.header_ID_o(header_ID_o),
    .header_requestID_o(header_requestID_o),
    .header_completID_o(header_completID_o),
    .data_out(data_out),
    .addr_out(addr_out)	
);    
  
endmodule