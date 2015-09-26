/*******************************************************************************
#   +html+<pre>
#
#   FILENAME: dp_ram2.sv
#   AUTHOR: Greg Taylor     CREATION DATE: 6 Feb 2013
#
#   DESCRIPTION:
#	Code from Cliff Cummings' paper, "Clock domain Crossing (CDC) Design &
#	Verification Techniques Using SystemVerilog."
#
#   CHANGE HISTORY:
#   6 Feb 2013    Greg Taylor
#       Initial version
#
#   SVN Identification
#   $Id$
#******************************************************************************/
`timescale 1ns / 1ps
`default_nettype none // disable implicit net type declarations

module dp_ram2 #(
	parameter type dat_t = logic [7:0]
) (
    output dat_t q,
    input dat_t d,
    input wire waddr,
    input wire raddr,
    input wire we,
    input wire clk
);
	dat_t mem [0:1];
	
	always_ff @(posedge clk)
		if (we)
			mem[waddr] <= d;
		
	assign q = mem[raddr];
endmodule
`default_nettype wire  // re-enable implicit net type declarations