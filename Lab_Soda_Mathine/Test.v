`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   11:02:28 11/20/2013
// Design Name:   soda_machine
// Module Name:   C:/Embedded Software/Lab/Soda_Machine/Test.v
// Project Name:  Soda_Machine
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: soda_machine
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module Test;

	// Inputs
	reg clk;
	reg reset;
	reg Nickel;
	reg Dime;
	reg Quarter;
	reg Insert_money;

	// Outputs
	wire Dispance;
	wire ReturnNickel;
	wire ReturnDime;
	wire ReturnTwoDimes;
	wire [5:0] total;
	wire [3:0] seg;
	wire [6:0] a_to_g;

	// Instantiate the Unit Under Test (UUT)
	soda_machine uut (
		.clk(clk), 
		.reset(reset), 
		.Nickel(Nickel), 
		.Dime(Dime), 
		.Quarter(Quarter), 
		.Insert_money(Insert_money), 
		.Dispance(Dispance), 
		.ReturnNickel(ReturnNickel), 
		.ReturnDime(ReturnDime), 
		.ReturnTwoDimes(ReturnTwoDimes), 
		.total(total), 
		.seg(seg), 
		.a_to_g(a_to_g)
	);

	initial begin
		// Initialize Inputs
		clk = 0;
		reset = 0;
		Nickel = 0;
		Dime = 0;
		Quarter = 0;
		Insert_money = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		forever
		#100
		begin
			Nickel = ~Nickel;
			if(Nickel == 1)
			begin 
				Dime = 0;
				Quarter = 0;
			end
			else
			begin
				if(Dime == 0)
				begin
					Dime = ~Dime;
					Nickel = 0;
					Quarter = 0;
				end
				else
				begin
					Dime =~Dime;
					Nickel = 0;
					Quarter = 1;
				end
			end
			clk = ~clk;
			#100
			Insert_money = ~Insert_money;
			#100;
			clk = ~clk;
			Insert_money = ~Insert_money;
		end
	end
      
endmodule

