// 2021 / 10 / 24
// LPC Decode
// LPC Ports 80 & 81

// Test System:
// Intel SHB-DT Refresh CRB (H97 QS)

// Resources:
// Intel 251289
// Lattice RD1049

module lpc_decode(
//inputs
lpc_v3p3_s0,
lpc_clk_l,
lpc_rst_l,
lpc_frame_l,

//outputs
port_80,
port_81,
lpc_hit,

//inouts
lpc_lad
);
	input lpc_v3p3_s0;
	input lpc_clk_l;
	input lpc_rst_l;
	input lpc_frame_l;
	
	output [7:0] port_80;
	output [7:0] port_81;
	
	output lpc_hit;
	
	inout [3:0] lpc_lad;
	
	reg [7:0] port_80;
	reg [7:0] port_81;
	reg lpc_hit;
	reg [2:0] cmd_reg;
	reg lad_oe_reg;
	reg [31:0] address_reg;
	reg [3:0] state_lpc;
	reg [3:0] start_reg;
	reg [7:0] lad_out_mux;
	reg [3:0] lad_in;
	reg [3:0] lad_out;
	
   wire iow = ~cmd_reg[2] & ~cmd_reg[1] & cmd_reg[0]; 									// CYCTYPE + DIR I/O Write
	wire lad_oe = lad_oe_reg & lpc_frame_l;													// 
	wire iow_hit = (address_reg[31:20] == 12'h008);											// Port 8x
	assign lpc_lad[3:0] = lad_oe ? lad_out : 4'hz;											// 
	
	// lpc buffer
	always @(lpc_frame_l, lpc_rst_l, lpc_lad [3:0])
	begin
		lad_in = lpc_lad;
	end
	
	// State Machine parameters
	parameter [3:0] idle = 4'h0;
	parameter [3:0] command = 4'h1;
	parameter [3:0] addr7 = 4'h2;
	parameter [3:0] addr6 = 4'h3;
	parameter [3:0] addr5 = 4'h4;
	parameter [3:0] addr4 = 4'h5;
	parameter [3:0] iow_pre_tar0 = 4'h6;
	parameter [3:0] iow_pre_tar1 = 4'h7;
	parameter [3:0] iow_sync0 = 4'h8;
	parameter [3:0] iow_data0 = 4'h9;
	parameter [3:0] iow_data1 = 4'ha;
	parameter [3:0] post_tar0 = 4'hb;
	parameter [3:0] post_tar1 = 4'hc;
	parameter [3:0] abort = 4'hd;
	

	always @(posedge lpc_clk_l or negedge lpc_rst_l) 
   begin
		// lpc_rst_l clear
		if (~lpc_rst_l) 
			begin
   		state_lpc <=  idle;
		   address_reg <=  32'h00000000;
		   start_reg <=  4'h0;
		   cmd_reg <=  3'b000;
	      lad_out <=  4'h0;
	      lad_oe_reg <=  1'b0;
			
			// only clear port data if board exits s0 state
			//if (~lpc_v3p3_s0)
			//	begin
	      //   port_80 <=  8'h00;
			//	port_81 <=  8'h00;
			//	end
			end
		
		// LPC State Machine
  	 	else 
		begin
			case (state_lpc)
				// idle case: Wait for lpc_frame_l
				idle: 
				begin
				lad_oe_reg <= 1'b0;
			  	
					if (~lpc_frame_l) 
					  begin
		      	  	start_reg <=  lad_in;
	   	      	state_lpc <=  command;
		   	     end
			        else 
					  begin
		   	     		state_lpc <= idle;
						end
	      	  	end
				
				// command case: 
			  	command: 
			  	begin
	         	if (~lpc_frame_l) 
					// Extended timing mode
					begin
	   	      	start_reg <=  lad_in;
		   	   	state_lpc <=  command;
	      	  	end
	          	else if (start_reg == 4'h0) 
					begin 
	   	      	cmd_reg <=  lad_in[3:1];
	      	    	state_lpc <=  addr7;
		        	end
		        	else 
					begin
         	   	state_lpc <=  idle;
          		end
	      	end
				
				// LPC address notes:
				// for standard lpc_frame_l timing, LPC specifies either a 16 bit or 32 bit address.
				// for extended lpc_frame_l timing, LPC specifies an address length from 4 to 32 bits, in nibble increments.
				// Consult intel document number 251289 for futher information.
				
				// addr7 case: address [15:12] or [31:28]
	   	   addr7: 
				begin
		      	address_reg[31:28] <=  lad_in;
	   	     	if (~lpc_frame_l) 
					begin
	         		state_lpc <=  abort;
	          	end 
		        	else 
					begin
	      	    	state_lpc <= addr6;
	      	  	end
        		end
        
				// addr6 case: address [11:8] or [27:24]
			  	addr6: 
			  	begin
      	  		address_reg[27:24] <=  lad_in;
         	 	if (~lpc_frame_l) 
					begin
	          		state_lpc <=  abort;
         	 	end
          		else
					begin
            		state_lpc <=  addr5;
 	         	end
   	    	 end
				
				// addr5 case: address [7:4] or [23:20]
				addr5: 
			 	begin
      	  		address_reg[23:20] <= lad_in;
	      	  	if (~lpc_frame_l) 
					begin
	          		state_lpc <=  abort;
	          	end 
   	       	else
					begin
         	   	state_lpc <= addr4;
	          	end
   	     	end
	     
				// addr4 case: address [3:0] or [19:16]
				addr4: 
				begin
					address_reg[19:16] <= lad_in;
	      	  	if (~lpc_frame_l) 
			  		begin
						state_lpc <=  abort;
					end
	          	else if (iow) 
					begin
	   	       	state_lpc <=  iow_data0;
	          	end
   	       	else 
					begin
	      	    	//state_lpc <=  addr3;
						state_lpc <= idle;
          		end
        		end
	      
				
				iow_data0: 
				begin
	   	   	if (~lpc_frame_l) 
					begin
	         	 	state_lpc <= abort;
 	         	end
   	       	else if (address_reg[31:20] == 12'h008) 
					begin
	      	    	case (address_reg[19:16])
	              		4'h0: port_80[3:0] <= lad_in;
   	       	    	4'h1: port_81[3:0] <= lad_in;
   	         	endcase
	            	state_lpc <= iow_data1;
    	      	end
 	         	else 
					begin
		          	state_lpc <= idle;
		        	end
		      end
	      
				
				iow_data1: 
				begin
		      	if (~lpc_frame_l)
					begin                                                                                                                                                                                                                                                                                                                                                                 
		         	state_lpc <=  abort;
  		        	end
	          	else 
					begin
	      	    	case (address_reg[19:16])
      	      	  	4'h0: begin
										port_80[7:4] <= lad_in;
										lpc_hit <= 1'b1;
									end
           			   4'h1: begin
										port_81[7:4] <= lad_in;
										//lpc_hit <= 1'b1;
									end
	 	           	endcase
 		           	state_lpc <= iow_pre_tar0;
						
						
      	    	end
	     		end
        
				
			  	iow_pre_tar0: 
				begin
					lpc_hit <= 1'b0;
					
      	   	if (~lpc_frame_l) 
					begin
		         	state_lpc <= abort;
      	    	end
	          	else 
					begin
      	      	state_lpc <= iow_pre_tar1;
      	    	end
      	  	end 
        	
				
				iow_pre_tar1: 
				begin
      	   	if (~lpc_frame_l) 
					begin
		         	state_lpc <= abort;
      	    	end
	          	else 
					begin
      	      	state_lpc <= iow_sync0;
      	    	end
      	  	end 
				
				
				iow_sync0: 
				begin
	  	        	lad_oe_reg <=  1'b1;
 	         	lad_out <= 4'h0;
	          	if (~lpc_frame_l)
					begin
		          	state_lpc <=  abort;
	          	end
	  	        	else 
				 	begin
          			state_lpc <=  post_tar0;
     		     	end
        		end
        
				
		  		post_tar0: 
				begin
       	   	lad_out <=  4'hF;
       	   	if (~lpc_frame_l) 
					begin
	   	      	state_lpc <=  abort;
      	    	end
      	    	else 
					begin
      	      	state_lpc <=  post_tar1;
    	      	end
    	    	end 
    	    
				
			  	post_tar1: 
				begin
    		     	lad_oe_reg <=  1'b0;
   	       	if (~lpc_frame_l) 
				 	begin
	   	    		state_lpc <= abort;
          		end
					else 
					begin
 	   	        	state_lpc <=  idle;
   	       	end
        		end 
				
				// abort case: lpc_frame_l is asserted
		   	abort: 
				begin
					lad_oe_reg <=  1'b0;
      	    	if (~lpc_frame_l) 
					begin
						state_lpc <=  abort;
          		end
          		else 
					begin
		         	 state_lpc <=  idle;
         	 	end
      	  	end
        
		  		default:
	        	state_lpc <=  idle;
			endcase
		end	
	end		  
endmodule