`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:21:10 12/14/2013 
// Design Name: 
// Module Name:    CPU 
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
module CPU(
	input clock,						//时钟周期
	input[15:0] d_datain,			//从内存读取16位数据
	input enable,						//使能信号
	input[15:0] i_datain,			//从指令地址读取的16位指令数据
	input reset,						//复位信号
	input start,						//开始信号
	output reg[7:0] d_addr,			//写入内存地址
	output reg[15:0] d_dataout,	//写入内存16位数据
	output reg d_we,					//写入内存使能信号
	output reg[7:0] i_addr			//指令地址
    );
	
   //状态编码:
	parameter idle = 1'b0;
	parameter exec = 1'b1;
	reg[1:0]	state, next_state;
	
	//操作符编码：
	parameter NOP = 5'b00000;
	parameter HALT = 5'b00001;
	parameter LOAD = 5'b00010;
	parameter STORE = 5'b00011;
	parameter LDIH = 5'b10000;
	parameter ADD = 5'b01000;
	parameter ADDI = 5'b01001;
	parameter ADDC = 5'b10001;
	parameter SUB = 5'b10010;
	parameter SUBI = 5'b10011;
	parameter SUBC = 5'b10100;
	parameter CMP = 5'b01100;
	parameter AND = 5'b01101;
	parameter OR = 5'b01110;
	parameter NOT = 5'b10111;
	parameter XOR = 5'b01111;
	parameter SLL = 5'b00100;
	parameter SRL = 5'b00110;
	parameter SLA = 5'b00101;
	parameter SRA = 5'b00111;
	parameter SLR = 5'b01010;
	parameter SRR = 5'b01011;
	parameter JUMP = 5'b11000;
	parameter JMPR = 5'b11001;
	parameter BZ = 5'b11010;
	parameter BNZ = 5'b11011;
	parameter BN = 5'b11100;
	parameter BNN = 5'b11101;
	parameter BC = 5'b11110;
	parameter BNC = 5'b11111;
	parameter INC = 5'b10101;
	parameter DEC = 5'b10110;
	
	//指令寄存器
	reg[15:0] id_ir;
	reg[15:0] ex_ir;
	reg[15:0] mem_ir;
	reg[15:0] wb_ir;
	
	//数据存储器
	reg[15:0] reg_A;
	reg[15:0] reg_B;
	reg[15:0] reg_C;
	reg[15:0] reg_C1;
	reg[15:0] smdr;
	reg[15:0] smdr1;
	reg[2:0] flag;						//flag[0]:CF,flag[1]:ZF,flag[2]:NF
	reg dw;
	
	//通用寄存器
	reg[15:0] gr[0:7];
	
	//PC计数器
	reg[7:0] pc;
	
	//ALU结果暂存
	wire[15:0] result;
	wire carry;

	//算术转换
	reg[4:0] operation;
	always@(*)
	begin
		case(ex_ir[15:11])
			LOAD:operation <= 5'b00100;	//load
			STORE:operation <= 5'b00000;	//add
			LDIH:operation <= 5'b00000;	//add
			ADD:operation <= 5'b00000;		//add
			ADDI:operation <= 5'b00000;	//add
			ADDC:operation <= 5'b00001;	//addc
			SUB:operation <= 5'b00010;		//sub
			SUBI:operation <= 5'b00010;	//sub
			SUBC:operation <= 5'b00011;	//subc
			INC:operation <= 5'b10000;		//inc
			DEC:operation <= 5'b10001;		//dec
			JUMP:operation <= 5'b00000;	//add
			JMPR:operation <= 5'b00000;	//add
			BZ:operation <= 5'b00000;		//add
			BNZ:operation <= 5'b00000;		//add
			BN:operation <= 5'b00000;		//add
			BNN:operation <= 5'b00000;		//add
			BC:operation <= 5'b00001;		//addc
			BNC:operation <= 5'b00001;		//addc
			CMP:operation <= 5'b00101;		//cmp
			AND:operation <= 5'b00110;		//and
			OR:operation <= 5'b00111;		//or
			XOR:operation <= 5'b01000;		//xor
			NOT:operation <= 5'b01001;		//not
			SLL:operation <= 5'b01010;		//sll
			SRL:operation <= 5'b01100;		//srl
			SLA:operation <= 5'b01011;		//sla
			SRA:operation <= 5'b01101;		//sra
			SLR:operation <= 5'b01110;		//slr
			SRR:operation <= 5'b01111;		//srr
			default: operation <= 5'b11111;
		endcase
	end

	ALU op(operation,reg_A,reg_B,flag[0],result,carry);
	
	//状态转换
	always@(posedge clock)
	begin
		if(!reset)	state <= idle;
		else	state <= next_state;
	end
	
	//下一状态选择
	always@(*)
	case(state)
		idle:
			if((enable == 1'b1)&&(start == 1'b1))	next_state <= exec;
			else	next_state <= idle;
		exec:
			if((enable == 1'b0)||(wb_ir[15:11] == HALT))	next_state <= idle;
			else	next_state <= exec;
	endcase
	
	//IF
	always@(posedge clock or negedge reset)
	begin
		if(!reset)
		begin
			id_ir <= 16'b0000_0000_0000_0000;
			pc <= 8'b0000_0000;
		end
		else if(state == exec)
		begin
			if((id_ir[15:11] == LOAD && i_datain[15:11] == ADD &&  (id_ir[10:8] == i_datain[2:0] || id_ir[10:8] == i_datain[6:4]))||
				(id_ir[15:11] == LOAD && i_datain[15:11] == ADDC && (id_ir[10:8] == i_datain[2:0] || id_ir[10:8] == i_datain[6:4]))||
				(id_ir[15:11] == LOAD && i_datain[15:11] == SUB && (id_ir[10:8] == i_datain[2:0] || id_ir[10:8] == i_datain[6:4]))||
				(id_ir[15:11] == LOAD && i_datain[15:11] == SUBC && (id_ir[10:8] == i_datain[2:0] || id_ir[10:8] == i_datain[6:4]))||
				(id_ir[15:11] == LOAD && i_datain[15:11] == OR && (id_ir[10:8] == i_datain[2:0] || id_ir[10:8] == i_datain[6:4]))||
				(id_ir[15:11] == LOAD && i_datain[15:11] == XOR && (id_ir[10:8] == i_datain[2:0] || id_ir[10:8] == i_datain[6:4]))||
				(id_ir[15:11] == LOAD && i_datain[15:11] == AND && (id_ir[10:8] == i_datain[2:0] || id_ir[10:8] == i_datain[6:4])))
			begin
				id_ir = 16'b0000_0000_0000_0000;
				pc = pc;
			end
			else if((id_ir[15:11] == LOAD && i_datain[15:11] == 	LOAD && id_ir[10:8] == i_datain[6:4])||
				(id_ir[15:11] == LOAD && i_datain[15:11] == STORE && id_ir[10:8] == i_datain[6:4])||
				(id_ir[15:11] == LOAD && i_datain[15:11] == INC && id_ir[10:8] == i_datain[6:4])||
				(id_ir[15:11] == LOAD && i_datain[15:11] == DEC && id_ir[10:8] == i_datain[6:4])||
				(id_ir[15:11] == LOAD && i_datain[15:11] == NOT && id_ir[10:8] == i_datain[6:4])||
				(id_ir[15:11] == LOAD && i_datain[15:11] == SLL && id_ir[10:8] == i_datain[6:4])||
				(id_ir[15:11] == LOAD && i_datain[15:11] == SRL && id_ir[10:8] == i_datain[6:4])||
				(id_ir[15:11] == LOAD && i_datain[15:11] == SLA && id_ir[10:8] == i_datain[6:4])||
				(id_ir[15:11] == LOAD && i_datain[15:11] == SRA && id_ir[10:8] == i_datain[6:4])||
				(id_ir[15:11] == LOAD && i_datain[15:11] == SLR && id_ir[10:8] == i_datain[6:4])||
				(id_ir[15:11] == LOAD && i_datain[15:11] == SRR && id_ir[10:8] == i_datain[6:4]))
				begin
				id_ir <= 16'b0000_0000_0000_0000;
				pc = pc;
				end
			else if((id_ir[15:11] == LOAD && i_datain[15:11] == LDIH && id_ir[10:8] == i_datain[10:8])||
				(id_ir[15:11] == LOAD && i_datain[15:11] == ADDI && id_ir[10:8] == i_datain[10:8])||
				(id_ir[15:11] == LOAD && i_datain[15:11] == SUBI && id_ir[10:8] == i_datain[10:8]))
				begin
				id_ir <= 16'b0000_0000_0000_0000;
				pc = pc;
				end
			
			//pc: 跳转
			else if(((mem_ir[15:11] == BZ) && (flag[1] == 1'b1))||
				((mem_ir[15:11] == BNZ) && (flag[1] == 1'b0))||
				((mem_ir[15:11] == BN) && (flag[2] == 1'b1))||
				((mem_ir[15:11] == BNN) && (flag[2] == 1'b0))||
				((mem_ir[15:11] == BC) && (flag[0] == 1'b1))||
				((mem_ir[15:11] == BNC) && (flag[0] == 1'b0))||
				(mem_ir[15:11] == JMPR)||(mem_ir[15:11] == JUMP))
				begin
				pc <= reg_C[7:0];
				id_ir <= i_datain;
				end
			//pc: +1
			else
				begin
				pc <= pc+1;
				id_ir <= i_datain;
				end
		end
	end
	
	//ID
	always@(posedge clock or negedge reset)
	begin
		if(!reset)
		begin
			ex_ir <= 16'b0000_0000_0000_0000;
			reg_B <= 16'b0000_0000_0000_0000;
			reg_A <= 16'b0000_0000_0000_0000;
			smdr <= 16'b0000_0000_0000_0000;
		end
		else if(state == exec)
		begin
			ex_ir <= id_ir;
			
			//reg_A: r1
			if((id_ir[15:11] == BZ)||
				(id_ir[15:11] == BNZ)||
				(id_ir[15:11] == BC)||
				(id_ir[15:11] == BNC)||
				(id_ir[15:11] == BN)||
				(id_ir[15:11] == BNN)||
				(id_ir[15:11] == JMPR)||
				(id_ir[15:11] == LDIH)||
				(id_ir[15:11] == ADDI)||
				(id_ir[15:11] == SUBI))
				reg_A <= gr[id_ir[10:8]];
			//reg_A: 0
			else if(id_ir[15:11] == JUMP)
				reg_A <= 16'b0000_0000_0000_0000;
			//reg_A: r2
			else
				reg_A <= gr[id_ir[6:4]];
			
			//reg_B: val3
			if((id_ir[15:11] == LOAD)||
				(id_ir[15:11] == STORE)||
				(id_ir[15:11] == SLL)||
				(id_ir[15:11] == SRL)||
				(id_ir[15:11] == SLA)||
				(id_ir[15:11] == SRA)||
				(id_ir[15:11] == SLR)||
				(id_ir[15:11] == SRR))
				reg_B <= {12'b0000_0000_0000, id_ir[3:0]};
			//reg_B: {val2,val3}
			else if((id_ir[15:11] == ADDI)||
				(id_ir[15:11] == SUBI)||
				(id_ir[15:11] == JUMP)||
				(id_ir[15:11] == JMPR)||
				(id_ir[15:11] == BZ)||
				(id_ir[15:11] == BNZ)||
				(id_ir[15:11] == BN)||
				(id_ir[15:11] == BNN)||
				(id_ir[15:11] == BC)||
				(id_ir[15:11] == BNC))
				reg_B <= {8'b0000_0000, id_ir[7:0]};
			//reg_B: {val2, val3, 0000_0000}
			else if(id_ir[15:11] == LDIH)
				reg_B <= {id_ir[7:0],8'b0000_0000};
			//reg_B: r3
			else if((id_ir[15:11] == ADD)||
				(id_ir[15:11] == ADDC)||
				(id_ir[15:11] == SUB)||
				(id_ir[15:11] == SUBC)||
				(id_ir[15:11] == CMP)||
				(id_ir[15:11] == AND)||
				(id_ir[15:11] == OR)||
				(id_ir[15:11] == XOR))
				reg_B <= gr[id_ir[2:0]];
			//reg_B: 0
			else
				reg_B <= 16'b0000_0000_0000_0000;
				
			//解决hazard
			//当下一指令需要用到前一指令的运算结果作为第一操作数时：reg_A提前赋值
			//当操作为LOAD STORE ADD ADDC SUB SUBC INC DEC CMP AND OR NOT XOR SLL SRL SLA SRA SLR SRR时才需对reg_A进行提前赋值
			if((id_ir[15:11] == ADD)||
				(id_ir[15:11] == ADDC)||
				(id_ir[15:11] == SUB)||
				(id_ir[15:11] == SUBC)||
				(id_ir[15:11] == CMP)||
				(id_ir[15:11] == AND)||
				(id_ir[15:11] == OR)||
				(id_ir[15:11] == NOT)||
				(id_ir[15:11] == XOR)||
				(id_ir[15:11] == INC)||
				(id_ir[15:11] == DEC)||
				(id_ir[15:11] == SLL)||
				(id_ir[15:11] == SRL)||
				(id_ir[15:11] == SLA)||
				(id_ir[15:11] == SRA)||
				(id_ir[15:11] == SLR)||
				(id_ir[15:11] == SRR))
				begin
					if(id_ir[6:4] == ex_ir[10:8])
						reg_A <= result;
					if(id_ir[6:4] == mem_ir[10:8])
						reg_A <= reg_C;
					if(id_ir[6:4] == wb_ir[10:8])
						reg_A <= reg_C1;
				end
			
			//当操作为LDIH SUBI ADDI时判断r1是否应该提前赋值
			if((id_ir[15:11] == LDIH)||
				(id_ir[15:11] == SUBI)||
				(id_ir[15:11] == ADDI))
				begin
					if(id_ir[10:8] == ex_ir[10:8])
						reg_A <= result;
				end
			//当下一指令需要用到前一指令的运算结果作为第二操作数时：reg_B提前赋值
			//当前操作为ADD ADDC SUB SUBC CMP AND OR XOR时才需要对reg_B进行修改
			if((id_ir[15:11] == ADD)||
				(id_ir[15:11] == ADDC)||
				(id_ir[15:11] == SUB)||
				(id_ir[15:11] == SUBC)||
				(id_ir[15:11] == CMP)||
				(id_ir[15:11] == AND)||
				(id_ir[15:11] == OR)||
				(id_ir[15:11] == XOR))
				begin
					if(id_ir[3:0] == ex_ir[10:8])
						reg_B <= result;
					if(id_ir[3:0] == mem_ir[10:8])
						reg_B <= reg_C;
					if(id_ir[3:0] == wb_ir[10:8])
						reg_B <= reg_C1;
				end
			
			//smdr: r1
			if(id_ir[15:11] == STORE)
				smdr <= gr[id_ir[10:8]];
			//smdr: 0
			else
				smdr <= 16'b0000_0000_0000_0000;
		end
	end
	
	//EX
	always@(posedge clock or negedge reset)
	begin
		if(!reset)
		begin
			mem_ir <= 16'b0000_0000_0000_0000;
			flag  <= 3'b000;
			reg_C <= 16'b0000_0000_0000_0000;
			dw <= 1'b0;
			smdr1 <= 16'b0000_0000_0000_0000;
		end
		else if(state == exec)
		begin
			mem_ir <= ex_ir;
			reg_C <= result;
			
			//zf:1
			if(result == 16'b0000_0000_0000_0000)
				flag[1] <= 1'b1;
			//zf:0
			else
				flag[1] <= 1'b0;
			
			//nf:1
			if(result[15] == 1'b1)
				flag[2] <= 1'b1;
			//nf:0
			else
				flag[2] <= 1'b0;
				
			//dw: 1
			if(ex_ir == STORE)
				dw <= 1'b1;
			//dw: 0
			else
				dw <= 1'b0;
				
			//smdr1: smdr
			if(ex_ir[15:11] == STORE)
				smdr1 <= smdr;
			//smdr1: 0
			else
				smdr1 <= 16'b0000_0000_0000_0000;
				
			//flag[0]:carry	
			if((ex_ir[15:11] == ADDC)||
				(ex_ir[15:11] == SUBC)||
				(ex_ir[15:11] == BC)||
				(ex_ir[15:11] == BNC)||
				(ex_ir[15:11] == CMP))
				flag[0] <= carry;
			//flag[0]:0
			else
				flag[0] <= 1'b0;
		end
	end
	
	//MEM
	always@(posedge clock or negedge reset)
	begin
		if(!reset)
		begin
			wb_ir <= 16'b0000_0000_0000_0000;
			reg_C1 <= 16'b0000_0000_0000_0000;
		end
		else if(state == exec)
		begin
			wb_ir <= mem_ir;
			d_we <= dw;
			d_dataout <= smdr1;
			
			//reg_C1: Memory
			if(mem_ir[15:11] == LOAD)
				reg_C1 <= d_datain;
			//reg_C1: ALU result
			else
				reg_C1 <= reg_C;	
			
			//d_addr
			if((mem_ir[15:11] == LOAD)||
				(mem_ir[15:11] == STORE))
				d_addr <= reg_C[7:0];
			else
				d_addr <= 8'b0000_0000;
		end
	end
	
	//WB
	always@(posedge clock)
	begin
		if(state == exec)
		begin
			/*
			if(id_ir[15:11] == LOAD)
				gr[id_ir[10:8]] <= d_datain;
			*/
			//wb r1:
			if((wb_ir[15:11] == LOAD)||
				(wb_ir[15:11] == LDIH)||
				(wb_ir[15:11] == ADD)||
				(wb_ir[15:11] == ADDI)||
				(wb_ir[15:11] == ADDC)||
				(wb_ir[15:11] == SUB)||
				(wb_ir[15:11] == SUBI)||
				(wb_ir[15:11] == SUBC)||
				(wb_ir[15:11] == INC)||
				(wb_ir[15:11] == DEC)||
				(wb_ir[15:11] == AND)||
				(wb_ir[15:11] == OR)||
				(wb_ir[15:11] == NOT)||
				(wb_ir[15:11] == XOR)||
				(wb_ir[15:11] == SLL)||
				(wb_ir[15:11] == SRL)||
				(wb_ir[15:11] == SLA)||
				(wb_ir[15:11] == SRA)||
				(wb_ir[15:11] == SLR)||
				(wb_ir[15:11] == SRR))
				gr[wb_ir[10:8]] <= reg_C1;
			else;
		end
		else;
	end
endmodule

//ALU
module ALU(
	input[4:0] select,
	input[15:0] in1,
	input[15:0] in2,
	input flag,									//flag[0]:CF,flag[1]:ZF,flag[2]:NF
	output reg[15:0] out,
	output reg carry							//carry
	);
	reg symbol;
	reg[16:0] test;
	always@(*)
		case(select)
			5'b00000:out = in1 + in2;		//add
			5'b00001:							//add with cf
			begin
				test = in1 + in2 + flag;
				out = in1 + in2 + flag;
				if(test[16] == 1'b1)
					carry = 1'b1;
				else
					carry = 1'b0;
			end
			5'b00010:out = in1 - in2;		//sub
			5'b00011:							//sub with cf
			begin
				if(in1 >= in2)
				begin
					out = in1 - in2;
					carry = 1'b0;
				end
				else
				begin
					out = in1 - in2;
					carry = 1'b1;
				end
			end
			5'b00100:out = in1;				//load
			5'b00101:							//cmp
			begin
				if(in1 >= in2) carry = 1'b0;
				else carry = 1'b1;
			end
			5'b00110:out = in1 & in2;		//and
			5'b00111:out = in1 | in2;		//or
			5'b01000:out = in1 ^ in2;		//xor
			5'b01001:out = ~in1;				//not
			5'b01010:out = in1 << in2;		//sll
			5'b01011:out = in1 << in2;		//sla
			5'b01100:out = in1 >> in2;		//srl
			5'b01101:							//sra
			begin
				if(in1[15] == 1'b0)
					out = in1 >> in2;
				else
					out = ~(~in1>>in2);
			end
			5'b01110:out = (in1 << in2) + (in1 >> (16 - in2));//slr
			5'b01111:out = (in1 >> in2) + (in1 << (16 - in2));//srr
			5'b10000:out <= in1 + 1;		//inc
			5'b10001:out <= in1 - 1;		//dec
			default:out <= 0;
		endcase
endmodule
