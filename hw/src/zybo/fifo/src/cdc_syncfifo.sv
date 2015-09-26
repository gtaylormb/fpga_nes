/*******************************************************************************
#   +html+<pre>
#
#   FILENAME: cdc_syncfifo.sv
#   AUTHOR: Greg Taylor     CREATION DATE: 6 Feb 2013
#
#   DESCRIPTION:
#	Code from Cliff Cummings' paper, "Clock domain Crossing (CDC) Design &
#	Verification Techniques Using SystemVerilog":

This 1-deep two register FIFO has a number of interesting characteristics. Since the FIFO is built
using only two registers or a 2-deep dual port RAM, the gray code counters used to detect full
and empty are simple toggle flip-flops, which is really nothing more than 1-bit binary counters
(remember, the MSB of a standard gray code is the same as the MSB of a binary code).

On reset, both pointers are cleared and the FIFO is empty and hence the FIFO is not full. We use
the inverted not-full condition to indicate that the FIFO is ready to receive a data or control word
(wrdy is high). After a data or control word is put into the FIFO (using wput), the wptr toggles
and the FIFO becomes full, or in other words, the wrdy signal goes low, which also disables the
ability to toggle the wptr and therefore also disables the ability to put another word into the 2-
register FIFO until the first word is removed from the FIFO by the receiving clock-domain logic.

What is especially interesting about this design is that the wptr is now pointing to the second
location in the 2-register FIFO, so when the FIFO does again become ready (when wrdy is high),
the wptr is already pointing to the next location to write.

The same concept is replicated on receiving side of the FIFO. When a data or control word is
written into the FIFO, the FIFO becomes not empty. We use the inverted not-empty condition to
indicate that the FIFO is has a data or control word that is ready to be received (rrdy is high).

By using two registers to store the multi-bit CDC values, we are able to remove one clock cycle
from the send MCP formulation and another cycle from the acknowledge feedback path.

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

module cdc_syncfifo #(
	parameter type dat_t = logic [7:0]
) (
    // Write clk interface
    input dat_t wdata,
    output wire wrdy,
    input wire wput,
    input wire wclk,
    // Read clk interface
    output dat_t rdata,
    output wire rrdy,
    input wire rget,
    input wire rclk
);
    
    logic wptr, we, wq2_rptr;
    logic rptr, rq2_wptr;
    
    wctl wctl (.*);
    rctl rctl (.*);
    synchronizer w2r_sync (.out(rq2_wptr), .in(wptr), .clk(rclk));
    synchronizer r2w_sync (.out(wq2_rptr), .in(rptr), .clk(wclk));
    
    // dual-port 2-deep ram
    dp_ram2 #(
    	dat_t
    ) dpram (
		.q(rdata),
		.d(wdata),
		.waddr(wptr),
		.raddr(rptr),
		.we(we),
		.clk(wclk),
		.*
	);
	
	ERROR_fifo_wr_while_wrdy_not_asserted:
		assert property (@(posedge wclk)
			wput |-> wrdy);
			
	ERROR_fifo_rd_while_rrdy_not_asserted:
		assert property (@(posedge rclk)
			rget |-> rrdy);			
endmodule
`default_nettype wire  // re-enable implicit net type declarations
