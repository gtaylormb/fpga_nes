/*******************************************************************************
#   +html+<pre>
#
#   FILENAME: synchronizer.sv
#   AUTHOR: Greg Taylor     CREATION DATE: 31 March 2009
#
#   DESCRIPTION: Synchronize signal across time domains
#
#   CHANGE HISTORY:
#   31 March 2009        Greg Taylor
#       Initial version
#
#	13 March 2013		 Greg Taylor
#		Added SystemVerilog assertions to check for incorrect usage
#		From:
#		Mark Litterick, “Pragmatic Simulation-Based Verification of Clock Domain
#		Crossing Signals and Jitter Using SystemVerilog Assertions,” DVCon 2006
#  		www.verilab.com/files/sva_cdc_paper_dvcon2006.pdf
#
#   SVN Identification
#   $Id$
#******************************************************************************/
`timescale 1ns / 1ps
`default_nettype none  // disable implicit net type declarations

module synchronizer #(
    parameter RESET_LEVEL = 0,
    parameter SYNC_STAGES = 2
) (
    input wire clk,   // clock domain of out
    input wire in, 
    output logic out       
);
    (* ASYNC_REG="TRUE" *) // inform build tools this is a false path
    logic [SYNC_STAGES-1:0] sync_regs = {SYNC_STAGES{RESET_LEVEL}};
    
    always_ff @(posedge clk)
    	sync_regs <= {sync_regs[SYNC_STAGES-2:0], in};
        
    always_comb out = sync_regs[SYNC_STAGES-1];        
	
	//  Signal being synchronized must be stable for at least 3 clock edges
	ERROR_synchronizer_input_not_stable_long_enough:
		assert property (@(posedge clk)
			!$stable(in) |=> $stable(in) [*2]);

    property p_no_glitch;
        logic data;
        @(in)
        (1, data = !in) |=>
        @(posedge clk)
        (in == data);
    endproperty
    
    ERROR_synchronizer_input_signal_glitch:
    	assert property(p_no_glitch);
    	
	ERROR_synchronizer_input_unknown_value:
		assert property (@(posedge clk)
			!$isunknown(in));
endmodule
`default_nettype wire  // re-enable implicit net type declarations
