// 2021 / 10 / 24
// QSPI Slave

module qspi_slave(
//clock inputs
qspi_clk,

//inputs
port_80,
port_81,
lpc_hit,

//outputs
qspi_int,
qspi_out

);

	input qspi_clk;
	input [7:0] port_80;
	input [7:0] port_81;
	input lpc_hit;

	output qspi_int;
	output [3:0] qspi_out;
	
	reg [3:0] qspi_out;
	reg qspi_int;
	
	always
	begin
		qspi_int <= lpc_hit;
	end

	always @ (posedge lpc_hit or posedge qspi_clk)
	begin
		if (qspi_clk)
		begin
			qspi_out <= port_80 [3:0];
		end
		else
		begin
			qspi_out <= port_80 [7:4];
		end
	end          

endmodule