`timescale 1ns/10ps
module LCD_CTRL(clk, reset, cmd, cmd_valid, IROM_Q, IROM_rd, IROM_A, IRAM_valid, IRAM_D, IRAM_A, busy, done);
input clk;
input reset;
input [3:0] cmd;
input cmd_valid;
input [7:0] IROM_Q;
output reg IROM_rd;
output reg [5:0] IROM_A;
output reg IRAM_valid;
output reg [7:0] IRAM_D;
output reg [5:0] IRAM_A;
output reg busy;
output reg done;

reg [9:0] temp;	//ensure overflow doesn't happend 
reg [7:0] M1,M2,m1,m2,Maximum,Minimum,Aver;//represent Max, Min, Average

reg [2:0] ptrX,ptrY;// represent current coordinate
reg [7:0] LUp,RUp,LDown,RDown;

reg [7:0] mem [7:0][7:0];

//FSM 
reg [1:0] state,NextState;
parameter [1:0] IDLE=2'b00,READ=2'b01,OPER=2'b10,OUTPUT=2'b11;

integer i,j;

parameter [3:0] Write=4'b0000,
				ShiftUp=4'b0001,
				ShiftDown=4'b0010,
				ShiftLeft=4'b0011,
				ShifhRight=4'b0100,
				Max = 4'b0101,
				Min = 4'b0110,
				Average = 4'b0111,
				Counterclockwise=4'b1000,
				Clockwise=4'b1001,
				MirrorX = 4'b1010,
				MirrorY = 4'b1011;

always@(posedge clk or posedge reset)begin
	if(reset)begin
		state<=IDLE;
		IROM_rd<=1;
		IRAM_A<=0;
		busy<=1;
		done<=0;
		ptrX<=3'd4;
		ptrY<=3'd4;
	end
	else begin
		state<=NextState;
		case(state)
			IDLE:begin
				if(IROM_rd==1)begin
					IROM_A<=0;
				end
			end
			READ:begin
				mem[IROM_A[5:3]][IROM_A[2:0]]<=IROM_Q;
				if(IROM_A==6'd63)begin
					IROM_rd<=0;
					busy<=0;
				end
				else begin
					IROM_A<=IROM_A+1;
				end
			end
			OPER:begin
				if(cmd_valid==1)begin
					busy<=1;
					case(cmd)
						Write:begin
							IRAM_valid<=1;
							IRAM_D <= mem[0][0];
							for(i=0;i<8;i=i+1)begin
								for(j=0;j<8;j=j+1)begin
									if(j<7)begin
										mem[i][j]<=mem[i][j+1];
									end
									else begin
										if(i<7)begin
											mem[i][j]<=mem[i+1][0];
										end
										else begin
											mem[i][j]<=0;
										end
									end
								end
							end
						end
						ShiftUp:begin
							if(ptrY>1)
								ptrY<=ptrY-1;
						end

						ShiftDown:begin
							if(ptrY<3'd7)
								ptrY<=ptrY+1;
						end

						ShifhRight:begin
							if(ptrX<3'd7)
								ptrX<=ptrX+1;
						end

						ShiftLeft:begin
							if(ptrX>1)
								ptrX<=ptrX-1;
						end

						Max:begin
							mem[ptrY-1][ptrX-1] <= Maximum;
							mem[ptrY-1][ptrX] <= Maximum;
							mem[ptrY][ptrX-1] <= Maximum;
							mem[ptrY][ptrX] <=Maximum;
						end
						Min:begin
							mem[ptrY-1][ptrX-1] <= Minimum;
							mem[ptrY-1][ptrX] <= Minimum;
							mem[ptrY][ptrX-1] <= Minimum;
							mem[ptrY][ptrX] <=Minimum;
						end
						Average:begin
							mem[ptrY-1][ptrX-1] <= Aver;
							mem[ptrY-1][ptrX] <= Aver;
							mem[ptrY][ptrX-1] <= Aver;
							mem[ptrY][ptrX] <= Aver;
						end
						Counterclockwise:begin
							mem[ptrY-1][ptrX-1] <= RUp;
							mem[ptrY-1][ptrX] <= RDown;
							mem[ptrY][ptrX-1] <= LUp;
							mem[ptrY][ptrX] <= LDown;
						end
						Clockwise:begin
							mem[ptrY-1][ptrX-1] <= LDown;
							mem[ptrY-1][ptrX] <= LUp;
							mem[ptrY][ptrX-1] <= RDown;
							mem[ptrY][ptrX] <= RUp;
						end
						MirrorX:begin
							mem[ptrY-1][ptrX-1] <= LDown;
							mem[ptrY-1][ptrX] <= RDown;
							mem[ptrY][ptrX-1] <= LUp;
							mem[ptrY][ptrX] <= RUp;
						end
						MirrorY:begin
							mem[ptrY-1][ptrX-1] <= RUp;
							mem[ptrY-1][ptrX] <= LUp;
							mem[ptrY][ptrX-1] <= RDown;
							mem[ptrY][ptrX] <= LDown;
						end
						default:begin
							ptrX<=3'd4;
							ptrY<=3'd4;
						end
					endcase
				end
				else begin
					busy<=0;
				end
			end
			OUTPUT:begin
				if(IRAM_A==6'd63)begin
					done<=1;
					busy<=0;
				end
				else begin
					IRAM_A<=IRAM_A+1;
				end
				IRAM_D <= mem[0][0];
				for(i=0;i<8;i=i+1)begin
					for(j=0;j<8;j=j+1)begin
						if(j<7)begin
							mem[i][j]<=mem[i][j+1];
						end
						else begin
							if(i<7)begin
								mem[i][j]<=mem[i+1][0];
							end
							else begin
								mem[i][j]<=0;
							end
						end
					end
				end
			end
		endcase
		
	end

end

//FSM
always@(*)begin
	case(state)
		IDLE:NextState = (IROM_rd==1)?READ:IDLE;
		READ:NextState = (IROM_A==6'd63)?OPER:READ;
		OPER:NextState = (cmd_valid==1 && cmd==Write)?OUTPUT:OPER;
		OUTPUT:NextState = (IRAM_A==6'd63)?IDLE:OUTPUT;

	endcase

end

//ensure the four point
always@(*)begin
	LUp = mem[ptrY-1][ptrX-1];
	RUp = mem[ptrY-1][ptrX];
	LDown=mem[ptrY][ptrX-1];
	RDown=mem[ptrY][ptrX];

	M1 = (LUp>RUp)?LUp:RUp;
	M2 = (LDown>RDown)?LDown:RDown;
	Maximum = (M1>M2)?M1:M2;

	m1 = (LUp<RUp)?LUp:RUp;
	m2 = (LDown<RDown)?LDown:RDown;
	Minimum = (m1<m2)?m1:m2;

		temp = LUp+RUp+LDown+RDown;
		Aver = temp>>2;

end

endmodule



