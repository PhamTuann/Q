module top
	#(parameter ADDRESSWIDTH= 4,
	parameter DATAWIDTH= 8)
	(
		input PCLK,
		input PRESETn,
		input [ADDRESSWIDTH-1:0]PADDR,
		input [DATAWIDTH-1:0] PWDATA,
		input PWRITE,
		input PSELx,
		input PENABLE,
		output [DATAWIDTH-1:0] PRDATA,
		output PREADY,
		
		input reset,
		input clk,
		input channel_format, //0: serial, 1: enhanced
		input optional_pause,
		input config_bit,
		input enable,
		input [4:0] id_4bit,
		input [7:0] id_8bit,
		input [11:0] data_12bit,
		input [15:0] data_16bit,
		input [7:0] data_short,
		
		//output
		output data_pulse	

	);
	
	//signals apb
	wire [7:0] reg_status;
	wire [7:0] reg_receive;
	wire [7:0] reg_command;
	wire [7:0] reg_temp;
	wire [7:0] reg_pres;
	wire write_enable_tx;

	//signals crc block
	wire enable_crc_fast6;
	wire enable_crc_fast4;
	wire enable_crc_fast3;
	wire enable_crc_serial;
	wire enable_crc_enhanced;

	wire [23:0] data_fast6_to_crc;
	wire [15:0] data_fast4_to_crc;
	wire [11:0] data_fast3_to_crc;
	wire [7:0] data_short_to_crc;
	wire [7:0] data_enhanced_to_crc;

	wire [3:0] crc_serial;
	wire [5:0] crc_enhanced;
	wire [3:0] crc_fast;

	//signals pulse block
	wire ticks;

	//signals to control
	wire [3:0] data_nibble;
	wire pulse;
	wire sync;
	wire pause;
	wire pulse_done;

	apb_slave apb_slave(
		.PCLK(PCLK),
		.PRESETn(PRESETn),
		.PADDR(PADDR),
		.PWDATA(PWDATA),
		.PWRITE(PWRITE),
		.PSELx(PSELx),
		.PENABLE(PENABLE),
		.PRDATA(PRDATA),
		.PREADY(PREADY),

		//register
		.reg_status(reg_status),  
		.reg_receive(reg_receive), 
		.reg_command(reg_command), 
		.reg_temp(reg_temp), 
		.reg_pres(reg_pres), 

		//output control fifo tx
		.write_enable_tx(write_enable_tx)
	);

	async_fifo temp_fifo(
		.write_enable(write_enable_tx), 
		.write_clk(PCLK), 
		.write_reset_n(reg_command[7]),
		.read_enable(read_enable), 
		.read_clk(clk), 
		.read_reset_n(reg_command[6]),
		.write_data(reg_temp),
		.read_data(data_in),
		.write_full(reg_status[7]),
		.read_empty(reg_status[6])
	);

	sent_tx_data_reg sent_tx_data_reg(
		//clk and reset
		.clk(clk),
		.reset(reset),

		//signals to control block
		.load_14bit(load_14bit),
		.f1_14bit(f1_14bit),
		.read_enable(read_enable),
		.done(done),

		//signals to fifo
		.data_in(data_in)
	);
	sent_tx_control sent_tx_control(
		//clk and reset
		.clk(clk),
		.reset(reset),

		//normal input
		.channel_format(channel_format), //0: serial(), 1: enhanced
		.optional_pause(optional_pause),
		.config_bit(config_bit),
		.enable(enable),
		.id_4bit(id_4bit),
		.id_8bit(id_8bit),
		.data_12bit(data_12bit),
		.data_16bit(data_16bit),
		.data_short(data_short),

		//signals to crc block
		.crc_serial(crc_serial),
		.crc_enhanced(crc_enhanced),
		.crc_fast(crc_fast),
		.enable_crc_fast6(enable_crc_fast6),
		.enable_crc_fast4(enable_crc_fast4),
		.enable_crc_fast3(enable_crc_fast3),
		.enable_crc_serial(enable_crc_serial),
		.enable_crc_enhanced(enable_crc_enhanced),
		.data_fast6_to_crc(data_fast6_to_crc),
		.data_fast4_to_crc(data_fast4_to_crc),
		.data_fast3_to_crc(data_fast3_to_crc),
		.data_short_to_crc(data_short_to_crc),
		.data_enhanced_to_crc(data_enhanced_to_crc),
	

		//signals to pulse gen block
		.pulse_done(pulse_done),
		.data_nibble(data_nibble),
		.pulse(pulse),
		.sync(sync),
		.pause(pause),
	
		//signals to data reg block
		.data_fast1(data_fast1),
		.data_fast2(data_fast2),
		.done(done),
		.load_14bit(load_14bit)
	);
	sent_tx_pulse_gen sent_tx_pulse_gen(
		//clk and reset
		.ticks(ticks),
		.reset(reset),

		//signals to control
		.data_nibble(data_nibble),
		.pulse(pulse),
		.sync(sync),
		.pause(pause),
		.pulse_done(pulse_done),

		//output
		.data_pulse(data_pulse)
	);
	sent_tx_gen_ticks sent_tx_gen_ticks(
		.clk(clk),
		.reset(reset),
		.ticks(ticks)
	);
	sent_tx_crc_gen sent_tx_crc_gen(
		.reset(reset),
		.crc_serial(crc_serial),
		.crc_enhanced(crc_enhanced),
		.crc_fast(crc_fast),
		.enable_crc_fast6(enable_crc_fast6),
		.enable_crc_fast4(enable_crc_fast4),
		.enable_crc_fast3(enable_crc_fast3),
		.enable_crc_serial(enable_crc_serial),
		.enable_crc_enhanced(enable_crc_enhanced),
		.data_fast6_to_crc(data_fast6_to_crc),
		.data_fast4_to_crc(data_fast4_to_crc),
		.data_fast3_to_crc(data_fast3_to_crc),
		.data_short_to_crc(data_short_to_crc),
		.data_enhanced_to_crc(data_enhanced_to_crc)
	);

endmodule