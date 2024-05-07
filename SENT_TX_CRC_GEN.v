module sent_tx_crc_gen(
	//reset
	input reset,

	//signals to control block
	
	input enable_crc_fast6,
	input enable_crc_fast4,
	input enable_crc_fast3,
	input enable_crc_serial,
	input enable_crc_enhanced,

	input [23:0] data_fast6_to_crc,
	input [15:0] data_fast4_to_crc,
	input [11:0] data_fast3_to_crc,
	input [7:0] data_short_to_crc,
	input [7:0] data_enhanced_to_crc,

	output reg [3:0] crc_serial,
	output reg [5:0] crc_enhanced,
	output reg [3:0] crc_fast
	);

    	reg [15:0] temp_data_serial;
	reg [31:0] temp_six_nibbles;
	reg [23:0] temp_four_nibbles;
	reg [19:0] temp_three_nibbles;
    	reg [6:0] p;
	reg [5:0] poly = 5'b11101;
    	always @(*) begin
		if(reset) begin
			crc_serial = 0;
			crc_fast = 0;
		end
		else begin
		if(enable_crc_serial) begin
        		p = 15;
        		temp_data_serial = {4'b0101,data_short_to_crc, 4'b0};

        		while (p > 3) begin

            		if (temp_data_serial[p] == 1'b1) begin
              	  		temp_data_serial[p-0] = temp_data_serial[p-0] ^ 1;
                		temp_data_serial[p-1] = temp_data_serial[p-1] ^ poly[3];
                		temp_data_serial[p-2] = temp_data_serial[p-2] ^ poly[2];
                		temp_data_serial[p-3] = temp_data_serial[p-3] ^ poly[1];
                		temp_data_serial[p-4] = temp_data_serial[p-4] ^ poly[0];
            		end

            		else begin
                		p = p - 1;
            		end

        	end

        	crc_serial[3] = temp_data_serial[3];
        	crc_serial[2] = temp_data_serial[2];
        	crc_serial[1] = temp_data_serial[1];
        	crc_serial[0] = temp_data_serial[0];
		end
	
		if(enable_crc_fast6) begin
        		p = 31;
        		temp_six_nibbles = {4'b0101,data_fast6_to_crc, 4'b0};

        		while (p > 3) begin

            		if (temp_six_nibbles[p] == 1'b1) begin
              	  		temp_six_nibbles[p-0] = temp_six_nibbles[p-0] ^ 1;
                		temp_six_nibbles[p-1] = temp_six_nibbles[p-1] ^ poly[3];
                		temp_six_nibbles[p-2] = temp_six_nibbles[p-2] ^ poly[2];
                		temp_six_nibbles[p-3] = temp_six_nibbles[p-3] ^ poly[1];
                		temp_six_nibbles[p-4] = temp_six_nibbles[p-4] ^ poly[0];
            		end

            		else begin
                		p = p - 1;
            		end

        	end

        	crc_fast[3] = temp_six_nibbles[3];
        	crc_fast[2] = temp_six_nibbles[2];
        	crc_fast[1] = temp_six_nibbles[1];
        	crc_fast[0] = temp_six_nibbles[0];
		end

		if(enable_crc_fast4) begin
        		p = 23;
        		temp_four_nibbles = {4'b0101,data_fast4_to_crc, 4'b0};

        		while (p > 3) begin

            		if (temp_four_nibbles[p] == 1'b1) begin
              	  		temp_four_nibbles[p-0] = temp_four_nibbles[p-0] ^ 1;
                		temp_four_nibbles[p-1] = temp_four_nibbles[p-1] ^ poly[3];
                		temp_four_nibbles[p-2] = temp_four_nibbles[p-2] ^ poly[2];
                		temp_four_nibbles[p-3] = temp_four_nibbles[p-3] ^ poly[1];
                		temp_four_nibbles[p-4] = temp_four_nibbles[p-4] ^ poly[0];
            		end

            		else begin
                		p = p - 1;
            		end

        	end

        	crc_fast[3] = temp_four_nibbles[3];
        	crc_fast[2] = temp_four_nibbles[2];
        	crc_fast[1] = temp_four_nibbles[1];
        	crc_fast[0] = temp_four_nibbles[0];
		end

		if(enable_crc_fast3) begin
        		p = 19;
        		temp_three_nibbles = {4'b0101,data_fast3_to_crc, 4'b0};

        		while (p > 3) begin

            		if (temp_three_nibbles[p] == 1'b1) begin
              	  		temp_three_nibbles[p-0] = temp_three_nibbles[p-0] ^ 1;
                		temp_three_nibbles[p-1] = temp_three_nibbles[p-1] ^ poly[3];
                		temp_three_nibbles[p-2] = temp_three_nibbles[p-2] ^ poly[2];
                		temp_three_nibbles[p-3] = temp_three_nibbles[p-3] ^ poly[1];
                		temp_three_nibbles[p-4] = temp_three_nibbles[p-4] ^ poly[0];
            		end

            		else begin
                		p = p - 1;
            		end

        	end

        	crc_fast[3] = temp_three_nibbles[3];
        	crc_fast[2] = temp_three_nibbles[2];
        	crc_fast[1] = temp_three_nibbles[1];
        	crc_fast[0] = temp_three_nibbles[0];
		end
		end
            
    	end

endmodule

/*
test case
data poly CRC4_code
0x2C7 0x13 0xD
0x287 0x13 0xA
0x285 0x15 0xC
0x200 0x18 0x8
*/


