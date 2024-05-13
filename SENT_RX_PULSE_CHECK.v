module sent_rx_pulse_check (
	input data_pulse,
	input clk_rx,
	input reset,
	output reg [3:0] data_nibble_rx,

	output reg [27:0] data_fast6_to_check_crc,
	output reg [19:0] data_fast4_to_check_crc,
	output reg [15:0] data_fast3_to_check_crc,
	output reg [15:0] data_short_to_check_crc,
	output reg [27:0] data_enhanced_to_check_crc,

	output reg done_pre_data_fast6,
	output reg done_pre_data_fast4,
	output reg done_pre_data_fast3,
	output reg done_pre_data_short,
	output reg done_pre_data_enhanced
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

	reg status;
	reg [3:0] status_nb;

	reg [15:0] data1;
	reg [15:0] data2;
	reg [27:0] data3;
	reg done;
	reg done_data;
	reg done_state;
	reg [2:0] count_nibbles;
	reg done_pre;
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
	
	/*always @(negedge tick or posedge reset) begin
		if(reset) begin
			count_ticks <= 0; 
		end
		else begin
			if ((data_pulse==0) && (d==1)) begin
				if(count_ticks == 56) begin
					state_a <= SYNC;
					count_ticks <= 0;
				end
				else if(status) begin state_a <= STATUS; count_ticks <= 0; end
				else begin state_a <= DATA; count_ticks <= 0; end
			end
			else count_ticks <= count_ticks + 1;
		end
	end */

	//FSM
	always @(posedge tick or posedge reset) begin
		if(reset) begin
			state_a <= STATUS;
			count_data <= 0;
			d<=0;
			count_frame <= 0;
			status <= 0;
			status_nb <= 0;
			count_ticks <= 0;
			data1 <= 0;
			data2 <= 0;
			done <= 0;
			done_data <= 0;
			data3 <= 0;
			count_nibbles <= 0;
			done_state <= 0;
			done_pre <= 0;
			data_fast6_to_check_crc <= 0;
			data_fast4_to_check_crc <= 0;
			data_fast3_to_check_crc <= 0;
			data_short_to_check_crc <= 0;
			data_enhanced_to_check_crc <= 0;

			done_pre_data_fast6 <= 0;
			done_pre_data_fast4 <= 0;
			done_pre_data_fast3 <= 0;
			done_pre_data_short <= 0;
			done_pre_data_enhanced <= 0;
		end
		else begin
			d <= data_pulse;

			case(state_a)
				IDLE: begin

				end
				SYNC: begin
					if ((data_pulse==0) && (d==1)) begin
						status <= 1;
						state_a <= STATUS;
					end
					else state_a <= SYNC;
				end
		
				STATUS: begin
					
					if ((data_pulse==0) && (d==1)) begin
						status_nb <= count_data - 12;
						count_data <= 0;
						state_a <= DATA;
						status <= 0;
						done <= 1;
					end
					else count_data <= count_data + 1;
				end

				DATA: begin
					count_ticks <= count_ticks+1;
					if(count_ticks > 27) begin
						data3 <= 0;
						count_ticks <= 0;
						count_data <= 0;
						if(count_nibbles == 7) begin count_nibbles <= 0; data_fast6_to_check_crc <= data3; done_pre_data_fast6 <= 1; end
						else if(count_nibbles == 5) begin count_nibbles <= 0; data_fast4_to_check_crc <= data3; end
						else if(count_nibbles == 4) begin count_nibbles <= 0; data_fast3_to_check_crc <= data3; end

						if(count_frame == 15) begin done_pre <= 1; state_a <= IDLE; state <= IDLE; end
						else begin state_a <= SYNC; count_frame <= count_frame + 1; end
					end
					else begin
						if ((data_pulse==0) && (d==1)) begin
							data_nibble_rx <= count_data - 12;
							count_data <= 0;
							state_a <= DATA;
							count_ticks <= 0;
							done_data <= 1;
							count_nibbles <= count_nibbles + 1;
						end
						else begin 
							count_data <= count_data + 1; 
						end
					end
				end
			endcase
		end
	end

	always @(posedge clk_rx or reset) begin
		if(reset) begin

		end
		else begin
			if(done) begin
				data1 <= {data1,status_nb[3]};
				data2 <= {data2,status_nb[2]};
				done <= 0;
			end

			if(done_data) begin
				data3 <= {data3,data_nibble_rx};
				done_data <= 0;
			end
			if(done_pre) begin
				data_short_to_check_crc <= data2;
				done_pre <= 0;
			end

		end
	end

	always @(negedge clk_rx or reset) begin
		if(done_pre_data_fast6) done_pre_data_fast6 <= 0;
	end

endmodule