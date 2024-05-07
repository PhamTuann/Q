module sent_tx_data_reg(
	//clk and reset
	input clk,
	input reset,

	//signals to control block
	input load_14bit,
	output reg [13:0] f1_14bit,
	output reg read_enable,
	output reg done,

	//signals to fifo
	input [7:0] data_in
	);

	reg [4:0] count_enable;
	reg [2:0] count_store;
	reg [7:0] a;
	reg [7:0] b;
	reg [5:0] c;
	reg [3:0] count_data;
	always @(posedge clk or posedge reset) begin
		if(reset) begin
			f1_14bit <= 0;
			read_enable <= 0;
			count_enable <= 0;
			count_store <= 0;
			a <= 0;
			b <= 0;
			c <= 0;
			done <= 0;
		end
		else begin
			if(load_14bit) begin
			if(count_enable == 6) begin
				read_enable <= 1;
				count_enable <= 0;
				if(!count_store && count_data != 3) begin
					a <= data_in; count_store <= 1; 
					
				end
				else if(!count_store && count_data == 3) begin
					a <= data_in; done <= 1;
				end
				else begin b <= data_in; count_store <= 0; done <= 1; end
			end
			else begin
				count_enable <= count_enable + 1;
			end
			end

			if(done) done <= 0;
			if(read_enable) read_enable <= 0;
		end
	
	end
	always @(negedge clk or posedge reset) begin
		if(reset) begin
			f1_14bit <= 0;
			read_enable <= 0;
			count_data <= 0;
		end
		else begin
			if(done) begin 
				if(count_data == 0)begin
					f1_14bit <= {a,b[7:2]}; c <= b[1:0]; 
					count_data <= 1;
				end
				if(count_data == 1)begin
					f1_14bit <= {c[1:0],a,b[7:4]}; c <= b[3:0]; 
					count_data <= 2;
				end
				if(count_data == 2)begin
					f1_14bit <= {c[3:0],a,b[7:6]}; c <= b[5:0]; 
					count_data <= 3;
				end
				if(count_data == 3)begin
					f1_14bit <= {c,a}; 
					count_data <= 0;
				end
			end
		end
	end
endmodule
