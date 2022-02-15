// 2021 / 08 / 23
//
// FPGA LPCDBG Top Level
//
// 

module top_level(
// System Power
lpc_v3p3_s0,

// LPC clk input
lpc_clk_l,

// LPC data inouts
lpc_lad,

// LPC Decode inputs
lpc_rst_l,
lpc_frame_l,

// Outputs for QSPI
qspi_out,
qspi_clk,
qspi_int

);

	// System Power
	input lpc_v3p3_s0;

	// LPC clk input
	input lpc_clk_l;

	// LPC data inouts
	inout [3:0] lpc_lad;

	// LPC Decode inputs
	input lpc_rst_l;
	input lpc_frame_l;

	// QSPI
	input qspi_clk;
	output qspi_int;

	output [3:0] qspi_out;


	// Wires
	wire [7:0] port_80;
	wire [7:0] port_81;

	wire lpc_hit;


lpc_decode(
	lpc_v3p3_s0,
	lpc_clk_l,
	lpc_rst_l,
	lpc_frame_l,

	port_80,
	port_81,
	lpc_hit,

	lpc_lad
);

qspi_slave(
	qspi_clk,
	
	port_80,
	port_81,
	lpc_hit,
	
	qspi_int,
	qspi_out
);
endmodule