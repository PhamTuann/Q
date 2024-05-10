module sent_rx_pulse_check (
	input data_pulse,
	input clk_rx,
	input reset,
	output reg [3:0] data_nibble_rx,
	output sync_rx,
	output pause_rx,
	output channel_error,
	output channel_format_received,
	output config_bit_received,
	output data_check_ticks
	);
	

	localparam COUNT_TICKS = 1;
	localparam DONE = 2;

	localparam IDLE = 0;
	localparam SYNC = 1;
	localparam STATUS = 2;
	localparam DATA = 3;
	localparam CRC = 4;
	localparam PAUSE = 5;	

	reg a;
	reg tick = 0;
	reg start;
	reg [10:0] b;
	reg d;
	reg [10:0] counter2;
	reg [1:0] count;
	reg [2:0] state;
	reg [2:0] state_a;
	reg [6:0] count_data;
	reg [5:0] count_frame;
	reg [6:0] count_ticks;
	
	//count tick
	always @(posedge clk_rx or posedge reset) begin
		if(reset) begin
			b <= 0;
			start <= 0;	
			count <= 0;
			state <= IDLE;
			counter2 = 0;
			data_nibble_rx <= 0;
		end
		else begin
			a <= data_pulse;
			case(state)
				IDLE: begin
					if((data_pulse==0) && (a==1)) begin
						state <= COUNT_TICKS;
					end
				end
				COUNT_TICKS: begin
					if((data_pulse==0) && (a==1)) begin
						state <= DONE;
						b <= (counter2+1)/56/2;
					end
					else counter2 <= counter2 + 1;
				end
				DONE: begin
					counter2 <= 0;
				end
			endcase
		end
	end

	//tick -> tick clk
	always @(posedge clk_rx) begin
		if (count == b-1) begin
			tick <= ~tick;
			count <= 0;
		end
		else count <= count + 1;
	end
	
	always @(negedge tick or posedge reset) begin
		if(reset) begin

		end
		else begin
			if ((data_pulse==0) && (d==1)) begin
				
				if(count_ticks == 56) begin
					state_a <= SYNC;
					count_ticks <= 0;
				end
				else begin state_a <= DATA; count_ticks <= 0; end
			end
			else count_ticks <= count_ticks + 1;
		end
	end

	//FSM
	always @(posedge tick or posedge reset) begin
		if(reset) begin
			state_a <= IDLE;
			count_data <= 0;
			d<=0;
			count_frame <= 0;
		end
		else begin
			d <= data_pulse;

			case(state_a)
		
				STATUS: begin
					if ((data_pulse==0) && (d==1)) begin
						data_nibble_rx <= count_data - 12;
						count_data <= 0;
						state_a <= DATA;
					end
					else count_data <= count_data + 1;
				end

				DATA: begin
					if ((data_pulse==0) && (d==1)) begin
						data_nibble_rx <= count_data - 12;
						count_data <= 0;
						state_a <= DATA;
					end
					else count_data <= count_data + 1;
				end
				
			endcase
		end
	end
endmodule