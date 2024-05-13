module sent_rx_control(
	//clk and reset
	input clk_rx,
	input reset,
	
	//signals to pulse check block
	input done_pre_data_fast6,
	input done_pre_data_fast4,
	input done_pre_data_fast3,
	input done_pre_data_short,
	input done_pre_data_enhanced,

	//signals to crc check
	output reg enable_crc_check_fast6,
	output reg enable_crc_check_fast4,
	output reg enable_crc_check_fast3,
	output reg enable_crc_check_serial,
	output reg enable_crc_check_enhanced,

	input valid_data_serial,
	input valid_data_enhanced,
	input valid_data_fast,

	input [7:0] data_serial,
	input [23:0] data_enhanced,
	input [23:0] data_fast
	
	);

	reg g;

	always @(negedge clk_rx or posedge reset) begin
		if(reset) begin
			enable_crc_check_fast6 <= 0;
			enable_crc_check_fast4 <= 0;
			enable_crc_check_fast3 <= 0;
			enable_crc_check_serial <= 0;
			enable_crc_check_enhanced <= 0;
			g <= 0;
		end
		else begin
			g <= done_pre_data_fast6;

			if((done_pre_data_fast6 == 0) && (g == 1)) begin enable_crc_check_fast6 <= 1; end
		end
	end
	always @(posedge clk_rx or posedge reset) begin
		if(reset) begin
			enable_crc_check_fast6 <= 0;
			enable_crc_check_fast4 <= 0;
			enable_crc_check_fast3 <= 0;
			enable_crc_check_serial <= 0;
			enable_crc_check_enhanced <= 0;
		end
		else begin
			if(enable_crc_check_fast6) begin enable_crc_check_fast6 <= 0; end
		end
	end

endmodule
