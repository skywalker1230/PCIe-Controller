// Create Date: 2024/08/03 18:29:48
// Design Name: 
// Module Name: TRANSACTION
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
module TX_TRANS_LAYER (
  input wire                    clk,
  input wire                    reset_n,
  
  //software interface
  input  wire  [511:0]			payload_i;	// Flit Payload: 64Byte(512 bit)
  input  wire  [31:0]			address_i
  input  wire  					valid_i;	// data와 addr의 valid/ready를 묶어서 하나로
  output  wire  				ready_o
  
  input  wire  [2:0]            header_fmt_i,	// 3b'0x0, 3DW Header(32bit address), Address below 4GB
  input  wire  [4:0]            header_type_i,	// 00000b = Mem RD/WR
  input  wire  [2:0]            header_tc_i,	// Traffic Class(0(lowest) ~ 7(Highest))
  input  wire  [9:0]            header_length_i,	// Payload Size: 00 0000 0000b = 1024DW(4096B), 00 0000 0001b = 1DW(4B)...
  input  wire  [15:0]           header_requestID_i,
  input  wire  [15:0]           header_completID_i,
  // WRR로 동작할 경우 보낸 순서대로 돌아오지 않을 수 있으므로 Tag Field가 필요할 수도 있다.
  // 아니다. 순서를 지키고 싶은 packet만 같은 TC를 할당하면 된다.
   
   // Port Arbitration은 고려할 필요 없다, VC Arbitration만 고려하자. VC 개수는 2개이고 mapping은 아래와 같이 설정한다.
   // VC0(low priority)  : TC0(must map to VC0), TC1, TC2, TC3, TC4
   // VC1(high priority) : TC5, TC6, TC7
   // VC arbitration은 4phase(VC1-VC1-VC1-VC0)로 한다.
   
  //data link layer interface
  output reg	[1023:0]     	tlp_out,
  output reg                	tlp_out_valid,
  input  wire               	tlp_in_ready
  
);
    reg                     	tlp_out_valid_n;
	reg 		[31:0] 			addr;
	reg    		[31:0]			header [2:0];
    reg			[511:0]			data;


	reg			[607:0]			tlp;
	wire		[1023:0]		src_data_o[1:0];
	wire						src_valid_o[1:0];
	
	
	reg                         rden_o_1;
    reg                         rden_o_1_n;
    reg                         rden_o_2;
    reg                         rden_o_2_n;
    reg                         wren_o_1;
    reg                         wren_o_1_n;
    reg                         wren_o_2;  
    reg                         wren_o_2_n;    
	
	reg							rdy, rdy_n;

    reg         [1023:0]        wdata_o_1;
    reg         [1023:0]        wdata_o_1_n;
    reg         [1023:0]        wdata_o_2;
    reg         [1023:0]        wdata_o_2_n;
   
    wire                        src_ready_i  [1:0];
    wire        [1023:0]        rdata_i_1;
    wire        [1023:0]        rdata_i_2;
    
    wire                        aempty_i_1;
    wire                        aempty_i_2;
  
	
    // Packetizer / FIFO*2 / Arbiter
	
/////////////////////////////////////////////////////////
////////////////		PACKETIZER		///////////////// 
///////////////////////////////////////////////////////// 

	PACKETIZER packetizer
	(
		.tlp_o				(tlp),
		
    	.header_fmt_i		(header_fmt_i),
		.header_type_i		(header_type_i),
		.header_tc_i		(header_tc_i),
		.header_length_i	(header_length_i),
		.header_requestID_i	(header_requestID_i),
		.header_completID_i	(header_completID_i),
		.data_i				(data),
		.address_i			(address_i)	
	);   

////////////////////////////////////////////////////
//////////////		FIFO * 2  	   ///////////////// 
////////////////////////////////////////////////////
	SAL_FIFO // VC0
	#( 
		.DEPTH_LG2           (4),
		.DATA_WIDTH       	 (1024),
		.AFULL_THRES         (15),
		.AEMPTY_THRES        (1)					
	)	
		fifo_1
	(
		.clk				(clk),
		.rst_n				(reset_n),


		.full_o   			(full_i_1),
		.rdata_o			(rdata_i_1),
		.empty_o			(empty_i_1),


		.rden_i   			(rden_o_1),
	 	.wren_i  			(wren_o_1),
	 	.wdata_i 			(wdata_o_1),

		.aempty_o			(aempty_i_1);
	);


	SAL_FIFO // VC1
	#(
		.DEPTH_LG2           (4) 					,
		.DATA_WIDTH       	 (1024)					,
		.AFULL_THRES         (15)		            ,
		.AEMPTY_THRES        (1)					
	)	
		fifo_2
	(
		.clk				(clk)					,
		.rst_n				(reset_n)				,


		.full_o				(full_i_2)				,
		.rdata_o			(rdata_i_2)				,
		.empty_o 			(empty_i_2)			    ,


		.rden_i				(rden_o_2)				,
	 	.wren_i				(wren_o_2)				,
	 	.wdata_i			(wdata_o_2)				,

		.aempty_o			(aempty_i_2)		    
	);
	

////////////////////////////////////////////////////
//////////////		ARBITER		////////////////////
////////////////////////////////////////////////////  
	ARBITER_WRR
	#(
		.N_MASTER           (2),
		.DATA_SIZE          (1024),					//32*7
		.HIGH_P				(3),
		.LOW_P				(1)
	)
		arbiter
	(
    	.clk				 	(clk),
    	.rst_n               	(reset_n),
  
    	.src_ready_o			(src_ready_i),	// Just one of two is active
   		.dst_data_o				(tlp_out),
    	.dst_valid_o			(tlp_out_valid),

    	.dst_ready_i			(tlp_in_ready),
		.src_data_i				(src_data_o),
  		.src_valid_i			(src_valid_o)			

	);

	assign src_data_o[0] = rdata_i_1;
	assign src_data_o[1] = rdata_i_2;

	assign src_valid_o[0] = !empty_i_1;
	assign src_valid_o[1] = !empty_i_2;                                            

	always_comb begin				
		wdata_o_1_n				=				wdata_o_1;
		wdata_o_2_n				=				wdata_o_2;
		wren_o_1_n              =               wren_o_1;
		wren_o_2_n              =               wren_o_2;
		rden_o_1_n              =               rden_o_1;
		rden_o_2_n              =               rden_o_2;
		rdy_n					=				1'b0;
			
		if(src_ready_i[0]) begin
		    rden_o_1_n = 1'b1;
		end
		else begin
		    rden_o_1_n = 1'b0;
		end
		
	    if(src_ready_i[1]) begin
		    rden_o_2_n = 1'b1;	    
		end
		else begin
		    rden_o_2_n = 1'b0;
		end
		
		if(valid_i) begin
		    //tlp = {header[0], header[1], header[2], data};

			if( header[0][22:20] >= 5) begin		 // TC5, TC6, TC7 -> VC1(FIFO2)
				if(!full_i_2) begin
				    wren_o_1_n  =  1'b0;
				    wren_o_2_n  =  1'b1;
					wdata_o_2_n = { {416{1'b0}}, tlp };
					
					rdy_n	=	1'b1;
				end
			end

			else begin       						// TC0, TC1, TC2, TC3, TC4 -> VC0(FIFO1)
				if(!full_i_1) begin					
				    wren_o_1_n  =  1'b1;
				    wren_o_2_n  =  1'b0;
					wdata_o_1_n = { {416{1'b0}}, tlp };
					
					rdy_n	=	1'b1;
				end
			end
        end
        
        else begin	// valid_i = 0
	        wren_o_1_n  =  1'b0;
	        wren_o_2_n  =  1'b0;
        end
		
    end
    
	always_ff @(posedge clk or negedge reset_n)	begin
		if(!reset_n)	begin
			wdata_o_1				<=				'b0;
			wdata_o_2				<=				'b0;
			wren_o_1                <=              'b0;
			wren_o_2                <=              'b0;
			rden_o_1                <=              'b0;
			rden_o_2                <=              'b0;
			rdy           			<=              'b0;
		end

		else begin
			wdata_o_1				<=				wdata_o_1_n;
			wdata_o_2				<=				wdata_o_2_n;
			wren_o_1                <=              wren_o_1_n;
			wren_o_2                <=              wren_o_2_n;
			rden_o_1                <=              rden_o_1_n;
			rden_o_2                <=              rden_o_2_n;
			rdy           			<=              rdy_n;
		end
	end
	
	assign ready_o	=	rdy;

endmodule
