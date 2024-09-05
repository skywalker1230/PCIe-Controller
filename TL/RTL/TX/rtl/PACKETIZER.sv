`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Taehyeon Lee
// 
// Create Date: 2024/08/03 18:29:48
// Design Name: 
// Module Name: Packetizer
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


module PACKETIZER
(
    output	wire [607:0]	tlp_o,
    //input   wire			tlp_ready_i,
    //output  wire			tlp_valid_o,

    input   wire  [2:0]		header_fmt_i,
    input   wire  [4:0]		header_type_i,
    input   wire  [2:0]		header_tc_i,
    input   wire  [9:0]		header_length_i,
    input   wire  [15:0]	header_requestID_i,
    input   wire  [15:0]	header_completID_i,
    input   wire  [511:0]  	data_i,
    input   wire  [31:0]   	address_i	
);

	reg		[31:0]		header [2:0];

	always_comb begin	
        // Packet type (memory header - 00000b = Memory Read or Write)
	    if (((header_fmt_i == 3'b000)||(header_fmt_i == 3'b010)) && (header_type_i == 5'b00000)) begin
            header[0] = {header_fmt_i, header_type_i, {1'b0}, header_tc_i, {10{1'b0}}, header_length_i};
            header[1] = {header_requestID_i, {16{1'b0}} };
            header[2] = {address_i[31:2], {2{1'b0}} };
		end
		
		// Packet type (completion header - 01010b = completion)
		else if (((header_fmt_i == 3'b000)||(header_fmt_i == 3'b010)) && (header_type_i == 5'b01010) ) begin  
            header[0] = {header_fmt_i, header_type_i, {1'b0}, header_tc_i, {10{1'b0}}, header_length_i};
            header[1] = {header_requestID_i, {16{1'b0}} };
            header[2] = {header_completID_i, {16{1'b0}} };						 	
		end

		else begin // reserved
			header[0] = 32'b0;
			header[1] = 32'b0;
			header[2] = 32'b0;
    	end
		
		tlp_o = {header[0], header[1], header[2], data_i};
	end