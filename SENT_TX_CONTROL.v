module sent_tx_control(
	//clk and reset
	input clk,
	input reset,

	//normal input
	input channel_format, //0: serial, 1: enhanced
	input optional_pause,
	input config_bit,
	input enable,
	input [4:0] id_4bit,
	input [7:0] id_8bit,
	input [11:0] data_12bit,
	input [15:0] data_16bit,
	input [7:0] data_short,
	
	//signals to crc block
	input [3:0] crc_serial,
	input [5:0] crc_enhanced,
	input [3:0] crc_fast,
	output reg enable_crc_fast6,
	output reg enable_crc_fast4,
	output reg enable_crc_fast3,
	output reg enable_crc_serial,
	output reg enable_crc_enhanced,
	output reg [23:0] data_fast6_to_crc,
	output reg [15:0] data_fast4_to_crc,
	output reg [11:0] data_fast3_to_crc,
	output [7:0] data_short_to_crc,
	output [7:0] data_enhanced_to_crc,

	//signals to pulse gen block
	input pulse_done,
	output reg [3:0] data_nibble,
	output reg pulse,
	output reg sync,
	output reg pause,
	
	//signals to data reg block
	input [15:0] data_fast1,
	input [11:0] data_fast2,
	input done,
	output reg load_14bit
	);

	localparam TWO_FAST_CHANNELS_12_12 = 0;
	localparam ONE_FAST_CHANNELS_12 = 1;
	localparam HIGH_SPEED_ONE_FAST_CHANNEL_12 = 2;
	localparam SECURE_SENSOR = 3;
	localparam SINGLE_SENSOR_12_0 = 4;
	localparam TWO_FAST_CHANNELS_14_10 = 5;
	localparam TWO_FAST_CHANNELS_16_8 = 6;

	localparam IDLE = 0;
	localparam SYNC = 1;
	localparam STATUS = 2;
	localparam DATA = 3;
	localparam CRC = 4;
	localparam PAUSE = 5;

	reg [2:0] frame_format;
	reg [2:0] state;
	reg [23:0] six_nibbles;
	reg [5:0] count_frame;
	reg sig_prev;
	reg sig_enable;
	reg [2:0] count_nibble;
	assign data_serial_to_crc = data_short;
	reg [2:0] count_load;

	reg [15:0] saved_short_data;
	reg [17:0] saved_enhanced_bit3;
	reg [17:0] saved_enhanced_bit2;
	
	always @(data_short) begin
		if(data_short == 12'h006 || data_short == 12'h007 || data_short == 12'h008 || data_short == 12'h009
		|| data_short == 12'h00A || data_short == 12'h00C) begin
			frame_format = 0;
		end
		if(data_short == 12'h001) begin
			frame_format = 5;
		end
		if(data_short == 12'h003) begin
			frame_format = 2;
		end
		/*if(data_short == 12'h006) begin
			frame_format = 3;
		end
		if(data_short == 12'h001) begin
			frame_format = 4;
		end*/
	end
	
	//FSM
	always @(posedge clk or posedge reset) begin
		if(reset) begin
			data_nibble <= 0;
			state <= IDLE;
			sync <= 0;
			pause <= 0;
			pulse <= 0;
			count_frame <= 0;
			saved_short_data <= 0;
			saved_enhanced_bit3 <= 0;
			saved_enhanced_bit2 <= 0;
			six_nibbles <= 0;
			enable_crc_fast6 <= 0;
			enable_crc_fast4 <= 0;
			enable_crc_fast3 <= 0;
			enable_crc_serial <= 0;
			data_fast6_to_crc <= 0;
			data_fast4_to_crc <= 0;
			data_fast3_to_crc <= 0;
			
		end
		else begin
			sig_prev <= pulse_done;
			case(state) 
				IDLE: begin
					//CHANGE STATE
					pulse <= 0;
					if(enable) begin
						state <= SYNC;
						count_frame <= 0;
					end
				end
				SYNC: begin
					//CHANGE STATE
					sync <= 1;
					if((pulse_done == 0) && (sig_prev==1)) begin
    						state <= STATUS;
  					end

					//PRE DATA FAST
					if(count_load==0) begin count_load<= 1; load_14bit <= 1;end
					if(done) load_14bit <= 0;
					
					//ENABLE CRC FAST CHANNEL
					if((frame_format == TWO_FAST_CHANNELS_12_12) || (frame_format == SECURE_SENSOR)|| (frame_format == SINGLE_SENSOR_12_0)||
					(frame_format == TWO_FAST_CHANNELS_14_10) || (frame_format == TWO_FAST_CHANNELS_16_8) ) begin
						enable_crc_fast6 <= 1;
					end
					else if(frame_format == ONE_FAST_CHANNELS_12) begin 
						enable_crc_fast3 <= 1;
					end
					else if(frame_format == HIGH_SPEED_ONE_FAST_CHANNEL_12) begin 
						enable_crc_fast4 <= 1;
					end
					
					//ENABLE CRC SHORT && ENHANCED
					if(!channel_format) enable_crc_serial <= 1;
					else enable_crc_enhanced <= 1;
					
					//PRE SAVED DATA
						if(!channel_format) saved_short_data <= {id_4bit, data_short, crc_serial};
						else if(channel_format && !config_bit) begin
							saved_enhanced_bit3 <= {7'b1111110, config_bit, id_8bit[7:4],1'b0,id_8bit[3:0], 1'b0};
							saved_enhanced_bit2 <= {crc_enhanced, data_12bit};
						end
						else begin
							saved_enhanced_bit3 <= {7'b1111110, config_bit, id_4bit,1'b0,data_16bit[15:12], 1'b0};
							saved_enhanced_bit2 <= {crc_enhanced, data_16bit[11:0]};
						end
					
				end
				STATUS: begin
					//CHANGE STATE
					sync <= 0;
					pulse <= 1;
					if(!channel_format) begin
						data_nibble[2] <= saved_short_data[15];
						if(count_frame ==0) begin
							data_nibble[3] <= 1;
						end
						else data_nibble[3] <= 0;

						if((pulse_done == 0) && (sig_prev==1)) begin
    							state <= DATA;
							saved_short_data <= {saved_short_data[14:0], 1'b0};
  						end
					end
					else begin
						data_nibble[2] <= saved_enhanced_bit2[17];
						data_nibble[3] <= saved_enhanced_bit3[17];

						if((pulse_done == 0) && (sig_prev==1)) begin
    							state <= DATA;
							saved_enhanced_bit2 <= {saved_enhanced_bit2[16:0], 1'b0};
							saved_enhanced_bit3 <= {saved_enhanced_bit3[16:0], 1'b0};
  						end
					end
				end
				DATA: begin
					//CHANGE STATE
					if( (frame_format == TWO_FAST_CHANNELS_12_12) || (frame_format == SECURE_SENSOR)|| (frame_format == SINGLE_SENSOR_12_0)||
					(frame_format == TWO_FAST_CHANNELS_14_10) || (frame_format == TWO_FAST_CHANNELS_16_8) ) begin
						data_nibble <= data_fast6_to_crc[23:20];
						if((pulse_done == 0) && (sig_prev==1)) begin
    							count_nibble <= count_nibble + 1;
							data_fast6_to_crc <= {data_fast6_to_crc[19:0], 4'b0000};
  						end
					end
					else if(frame_format == ONE_FAST_CHANNELS_12) begin 
						data_nibble <= data_fast3_to_crc[11:8];
						if((pulse_done == 0) && (sig_prev==1)) begin
    							count_nibble <= count_nibble + 1;
							data_fast3_to_crc <= {data_fast3_to_crc[7:0], 4'b0000};
  						end
					end
					else if(frame_format == HIGH_SPEED_ONE_FAST_CHANNEL_12) begin 
						data_nibble <= data_fast4_to_crc[15:12];
						if((pulse_done == 0) && (sig_prev==1)) begin
    							count_nibble <= count_nibble + 1;
							data_fast4_to_crc <= {data_fast4_to_crc[11:0], 4'b0000};
  						end
					end
				end
				
				CRC: begin
					//CHANGE STATE
					data_nibble <= crc_fast;
					if((pulse_done == 0) && (sig_prev==1)) begin
    						pulse <= 0;
						if(optional_pause) state <= PAUSE;
						else begin
							if(!channel_format && count_frame != 15) begin
								state <= SYNC;
								count_frame <= count_frame + 1;
							end
							else if(channel_format && count_frame != 17) begin
								 state <= SYNC;
								count_frame <= count_frame + 1;
							end
							else state <= IDLE;
						end		
					end
				end
				PAUSE: begin
					pause <= 1;
					if((pulse_done == 0) && (sig_prev==1)) begin
    						pause <= 0;
						if(!channel_format && count_frame != 15) begin
								state <= SYNC;
								count_frame <= count_frame + 1;
							end
							else if(channel_format && count_frame != 17) begin
								 state <= SYNC;
								count_frame <= count_frame + 1;
							end
							else state <= IDLE;
					end

				end

			endcase
		end
	end
	
	
	always @(negedge clk or posedge reset) begin	
		if(reset) begin
			count_nibble <= 0;
		end
		else begin
			if(state == DATA) begin
				if( (frame_format == TWO_FAST_CHANNELS_12_12) || (frame_format == SECURE_SENSOR)|| (frame_format == SINGLE_SENSOR_12_0)||
					(frame_format == TWO_FAST_CHANNELS_14_10) || (frame_format == TWO_FAST_CHANNELS_16_8) ) begin
					if(count_nibble == 6) begin
						count_nibble <= 0;
						state <= CRC;
					end
					else state <= DATA;
				end
				else if(frame_format == ONE_FAST_CHANNELS_12) begin 
					if(count_nibble == 3) begin
						count_nibble <= 0;
						state <= CRC;
					end
					else state <= DATA;
				end
				else if(frame_format == HIGH_SPEED_ONE_FAST_CHANNEL_12) begin 
					if(count_nibble == 4) begin
						count_nibble <= 0;
						state <= CRC;
					end
					else state <= DATA;
				end
			end
		end
	end

	
	always @(frame_format or data_fast1 or data_fast2) begin
			case(frame_format) 
				TWO_FAST_CHANNELS_12_12: begin data_fast6_to_crc <= {data_fast1[11:0], data_fast2[3:0], data_fast2[7:4], data_fast2[11:8]}; end
						
				ONE_FAST_CHANNELS_12: begin data_fast3_to_crc <= {data_fast1[11:0]}; end

				HIGH_SPEED_ONE_FAST_CHANNEL_12: begin data_fast4_to_crc <= {1'b0,data_fast1[11:9],1'b0,data_fast1[8:6],1'b0,data_fast1[5:3],1'b0,data_fast1[2:0]}; end

				SECURE_SENSOR: begin data_fast6_to_crc <= {data_fast1[11:0],!data_fast1[11:9]}; end
						
				SINGLE_SENSOR_12_0: begin data_fast6_to_crc <= {data_fast1[11:0],12'b0}; end

				TWO_FAST_CHANNELS_14_10: begin data_fast6_to_crc <= {data_fast1[13:0],data_fast2[1:0],data_fast2[5:2],data_fast2[9:6]}; end

				TWO_FAST_CHANNELS_16_8: begin data_fast6_to_crc <= {data_fast1,data_fast2[3:0],data_fast2[7:4]}; end	
			endcase
	end
	
endmodule
