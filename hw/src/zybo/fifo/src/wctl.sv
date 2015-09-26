/*******************************************************************************
#   +html+<pre>
#
#   FILENAME: wctl.sv
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

module wctl (
    output wire wrdy,
    output logic wptr = 0,
    output wire we,
    input wire wput, 
    input wire wq2_rptr,
    input wire wclk
);
    assign we = wrdy & wput;
    assign wrdy = ~(wq2_rptr ^ wptr);
    
    always_ff @(posedge wclk)
        wptr <= wptr ^ we;
endmodule
`default_nettype wire  // re-enable implicit net type declarations