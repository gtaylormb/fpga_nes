/*******************************************************************************
#   +html+<pre>
#
#   FILENAME: rctl.sv
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

module rctl (
    output wire rrdy,
    output logic rptr = 0,
    input wire rget,
    input wire rq2_wptr,
    input wire rclk
);
    typedef enum {
    	xxx,
    	VALID
    } status_e;
    
    status_e status;
    wire rinc;
    
    assign status = status_e'(rrdy);
    assign rinc = rrdy & rget;
    assign rrdy = (rq2_wptr ^ rptr);
    
    always_ff @(posedge rclk)
        rptr <= rptr ^ rinc;
        
endmodule
`default_nettype wire  // re-enable implicit net type declarations