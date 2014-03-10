`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:17:37 11/19/2013 
// Design Name: 
// Module Name:    soda 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module soda(
	input clk,
	input nickels,
	input dimes,
	input quarters,
	input reset,
	output reg dispance,
	output reg returnnickels,
	output reg[1:0] nickel_num,
	output reg returndimes,
	output reg[1:0] dimes_num,
	output reg[3:0] an,
	output reg[6:0] a_to_g
    );
	 
	reg[5:0] total; 
	//count module
	
	always@(posedge nickels or posedge dimes or posedge quarters or posedge reset)
	begin
		if(reset)
		begin
			total <= 0;
			dispance <= 0;
			returnnickels <= 0;
			nickel_num <= 0;
			returndimes <= 0;
			dimes_num <= 0;
		end
		else
		begin
			total = nickels*5 + dimes*10 + quarters*25;
			if(total >= 25)
			begin
				if(total == 25)
				begin
					dispance <= 1;
					returnnickels <= 0;
					nickel_num <= 0;
					returndimes <= 0;
					dimes_num <= 0;
				end
				else if(total == 30)
				begin
					dispance <= 0;
					returnnickels <= 1;
					nickel_num <= 1;
					returndimes <= 0;
					dimes_num <= 0;
				end
				else if(total == 35)
				begin
					dispance <= 0;
					returnnickels <= 0;
					nickel_num <= 0;
					returndimes <= 1;
					dimes_num <= 1;
				end
				else if(total == 40)
				begin
					dispance <= 0;
					returnnickels <= 1;
					nickel_num <= 1;
					returndimes <= 1;
					dimes_num <= 1;
				end
				else if(total == 45)
				begin
					dispance <= 0;
					returnnickels <= 0;
					nickel_num <= 0;
					returndimes <= 1;
					dimes_num <= 2;
				end
			end
		end
	end
	//frequ_divide
	reg[19:0] div;
	wire select;
	assign select = div[18];
	reg[3:0] digit; 
	reg[5:0] total_temp;
	
	wire[3:0] seg;
	reg[3:0] ten;
	reg[3:0] dig;
	assign seg = 4'b1111;
	
	always@(posedge clk)
		if(div[19] == 1) div <= 0;
		else div <= div+1;
	
	always@(*)
	begin
		total_temp <= total;
		if(total_temp[0] == 0) dig = 0;
		else dig = 5;
		if(total_temp >= 40) ten = 4;
		else if(total_temp >= 30) ten = 3;
		else if(total_temp >= 20) ten = 2;
		else if(total_temp >= 10) ten = 1;
		else ten = 0;
	end
	
	always@(*)
		case(select)
			0: digit = dig;
			1:	digit = ten;
			default: digit = dig;
		endcase
	//display ten and dig	
	always@(*)
	begin
		an = 4'b1111;
		if(seg[select] == 1)
		an[select] = 0;
	end
	//display module
	always@(*)
	case(digit)
		0:a_to_g=7'b0000001;
		1:a_to_g=7'b1001111;
		2:a_to_g=7'b0010010;
		3:a_to_g=7'b0000110;
		4:a_to_g=7'b1001100;
		5:a_to_g=7'b0100100;
		6:a_to_g=7'b0100000;
		7:a_to_g=7'b0001111;
		8:a_to_g=7'b0000000;
		9:a_to_g=7'b0000100;
		'hA:a_to_g=7'b0001000;
		'hB:a_to_g=7'b1100000;
		'hC:a_to_g=7'b0110001;
		'hD:a_to_g=7'b1000010;
		'hE:a_to_g=7'b0110000;
		'hF:a_to_g=7'b0111000;
		default:a_to_g=7'b0000001;
	endcase
endmodule
