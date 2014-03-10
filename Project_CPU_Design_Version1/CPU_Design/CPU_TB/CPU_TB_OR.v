`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   12:11:18 12/17/2013
// Design Name:   CPU
// Module Name:   E:/Embedded System/Lab5/CPU/CPU_TB.v
// Project Name:  CPU
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: CPU
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

		

module CPU_TB_OR;

	// Inputs
	reg clock;
	reg [15:0] d_datain;
	reg enable;
	reg [15:0] i_datain;
	reg reset;
	reg start;

	// Outputs
	wire [7:0] d_addr;
	wire [15:0] d_dataout;
	wire d_we;

	// Instantiate the Unit Under Test (UUT)
	CPU uut (
		.clock(clock), 
		.d_datain(d_datain), 
		.enable(enable), 
		.i_datain(i_datain), 
		.reset(reset), 
		.start(start), 
		.d_addr(d_addr), 
		.d_dataout(d_dataout), 
		.d_we(d_we)
	);
	always #5 clock = ~clock;
	initial begin
		// Initialize Inputs
		clock = 1;
		d_datain = 0;
		enable = 0;
		i_datain = 0;
		reset = 0;
		start = 0;
		
		// Wait 100 ns for global reset to finish
		#100;
      
		// Add stimulus here

		$display("pc:     id_ir      :regA:regB:regC:da: dd :w:regC:gr0 :gr1 :gr2 :gr3 :gr4 :gr5 :gr6 :gr7:cf:zf:nf");
		$monitor("%h:%b:%h:%h:%h:%h:%h:%b:%h:%h:%h:%h:%h:%h:%h:%h:%h:%h:%h:%h", 
		uut.pc, uut.mem_ir, uut.reg_A, uut.reg_B, uut.reg_C,
		d_addr, d_dataout, d_we, uut.reg_C1, uut.gr[0],uut.gr[1], uut.gr[2], uut.gr[3], uut.gr[4], uut.gr[5], 
		uut.gr[6],uut.gr[7],uut.flag[0],uut.flag[1],uut.flag[2]);
		
		enable <= 1; start <= 0; i_datain <= 0; d_datain <= 0;


		#10 reset <= 0;
		#10 reset <= 1;
		#10 enable <= 1;
		#10 start <=1;
		#10 start <= 0;
	
		uut.gr[1] <= 16'h0012;
		uut.gr[2] <= 16'h1200;

		i_datain <= {uut.OR, 3'b000, 4'b0001, 4'b0010};
		#10 i_datain <= {uut.NOP, 11'b000_0000_0000};
		#10 i_datain <= {uut.NOP, 11'b000_0000_0000};
		#10 i_datain <= {uut.NOP, 11'b000_0000_0000};
		#10 i_datain <= {uut.HALT, 11'b000_0000_0000};
		
	end
      
endmodule

