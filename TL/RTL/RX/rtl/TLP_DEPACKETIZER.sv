////////////////////////////////////////////////////////////////////////////////// 
// Engineer: Taehyeon Lee
// 
// Create Date: 2024/08/26 13:44:48 
// Module Name: TLP_DEPACKETIZER
//////////////////////////////////////////////////////////////////////////////////

module TLP_DEPACKETIZER
(
    input    wire [1023:0]	data_i,
    output   wire			tlp_ready_o,
    input    wire			tlp_valid_i,

    output   wire  [2:0]		header_fmt_o,
    output   wire  [4:0]		header_type_o,
    output   wire  [2:0]		header_tc_o,
    output   wire  [9:0]		header_length_o,
    //output   wire  [3:0]        header_ID_o,
    output   wire  [15:0]		header_requestID_o,
    output   wire  [15:0]		header_completID_o,
	
    output   wire  [511:0]      data_out,
    output   wire  [31:0]       addr_out	
);

    reg [2:0] 		header_fmt;
    reg [4:0] 		header_type;
    reg [2:0]		header_tc;
    reg [9:0]		header_length;
	//reg  [3:0]  	header_ID;
    reg [15:0]		header_requestID;
    reg [15:0]		header_completID;
	
    reg [511:0]    	data;
    reg [31:0]     	addr;	

    localparam  	CPLD  	= 8'b01001010,	// response of Read
					CPL		= 8'b00001010,	// response of Non-posted Write, Unsuccessful Read
                    MWR  	= 8'b01000000,	// Memory Write
					MRD		= 8'b00000000;	// Memory Read

    always_comb begin
        header_fmt 	= 'd0;
        header_type = 'd0;
        data    	= 'd0;
		
        if (tlp_valid_i) begin
            header_fmt  = data_i[607:605];
            header_type = data_i[604:600];
             
            case ({header_fmt,header_type})
            CPLD: begin
                header_tc 			= data_i[598:596];
				header_length 		= data_i[585:576];
				//header_ID 		= data_i[195:192];
				header_requestID 	= data_i[575:560];
				header_completID 	= data_i[543:528];
				data	    		= data_i[511:0];
				addr				= 'd0;

            end
			
			CPL: begin
                 header_tc 			= data_i[598:596];
				header_length 		= data_i[585:576];
				//header_ID 		= data_i[195:192];
				header_requestID 	= data_i[575:560];
				header_completID 	= data_i[543:528];
                addr				= 'd0;
            end
        
            MRD: begin
				header_tc 			= data_i[598:596];
				header_length 		= data_i[585:576];
				//header_ID 		= data_i[195:192];
				header_requestID 	= data_i[575:560];
				addr 				= data_i[543:528];
				header_completID 	= 'd0;
				end
			
			MWR: begin
				header_tc 			= data_i[598:596];
				header_length 		= data_i[585:576];
				//header_ID 		= data_i[195:192];
				header_requestID 	= data_i[575:560];
				addr 				= data_i[543:528];
				data	    		= data_i[511:0];
				header_completID 	= 'd0;
            end
			
            default: begin    
                header_tc	 		= 'd0;
                header_length	 	= 'd0;
				//header_ID	 		= 'd0;
                header_requestID 	= 'd0;
                header_completID 	= 'd0;
                addr				= 'd0;
            end
            endcase
		end
        else begin
            header_tc	 		= 'd0;
            header_length	 	= 'd0;
			//header_ID	 		= 'd0;
     	    header_requestID 	= 'd0;
     	    header_completID 	= 'd0;
        
            addr				= 'd0;
        end
    end

    assign tlp_ready_o = 1'b1;

    assign header_fmt_o 		= header_fmt;
    assign header_type_o 		= header_type;
    assign header_tc_o 			= header_tc;
    assign header_length_o 		= header_length;
    //assign header_ID_o 		= header_ID;
    assign header_requestID_o 	= header_requestID;
    assign header_completID_o 	= header_completID;
	
    assign data_out = data;
    assign addr_out = addr;	

endmodule 