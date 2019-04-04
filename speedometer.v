/* We could not get our speed calculation to work. This is because the distance calculation did not work.
   It seems the group that made the usensor (distance calculation) had a different hardware setup, and 
   thus it worked for them, but not for us.
   Instead, we hard-coded the speed ouput to just be determined by switches 15 to 17.
*/
module speedometer(CLOCK_50, SW, GPIO, HEX0, HEX1, HEX2, HEX4, HEX5, HEX6, HEX7, LEDR, LEDG);
  input CLOCK_50;
  input [17:0] SW;
  inout [35:0] GPIO;
  output reg [17:0] LEDR;
  output reg [7:0] LEDG;
  output [6:0] HEX0, HEX1, HEX2, HEX4, HEX5, HEX6, HEX7;
  reg [20:0] speed_output;
  wire [20:0] displace_output;
  wire [3:0] d_hundreds, d_tens, d_ones, s_hundreds, s_tens, s_ones, l_hundreds, l_tens, l_ones;

/* This is the module that was suppose to calculate speed
   The always block below this is the hard-coded speed output

  // calculate speed, store it in speed_output
  // also store displacement in displace_output
  speed_calculator sc(
	.speed(speed_output),
	.displacement(displace_output),
	.trig(GPIO[0]),	
	.echo(GPIO[1]),
	.clock(CLOCK_50)
	);
*/
  always @(*)
	case (SW[17:15])
		3'b000: speed_output <= 0;
		3'b001: speed_output <= 10;
		3'b010: speed_output <= 20;
		3'b011: speed_output <= 30;
		3'b100: speed_output <= 40;
		3'b101: speed_output <= 50;
		3'b110: speed_output <= 60;
		3'b111: speed_output <= 70;
		default: speed_output <= 0;
	endcase	
  assign displace_output = ((speed_output * 1000) / 3600);

  // display displacement on HEX0, HEX1, HEX2 as cm
  BCD bcd_displace(
	.binary(displace_output[7:0]),
	.Hundreds(d_hundreds),
	.Tens(d_tens),
	.Ones(d_ones)
	);

  hex_display d_display_hundreds(
	.IN(d_hundreds),
	.OUT(HEX2)
	);

  hex_display d_display_tens(
	.IN(d_tens),
	.OUT(HEX1)
	);

  hex_display d_display_ones(
	.IN(d_ones),
	.OUT(HEX0)
	);

  // display speed on HEX6 and HEX7 as km/h
  BCD bcd_speed(
	.binary(speed_output[7:0]),
	.Hundreds(s_hundreds),
	.Tens(s_tens),
	.Ones(s_ones)
	);

  hex_display s_display_tens(
	.IN(s_tens),
	.OUT(HEX7)
	);
  hex_display s_display_ones(
	.IN(s_ones),
	.OUT(HEX6)
	);

  // use SW switches to set the speed limit
  reg [7:0] limit;
  always @(*)
	case (SW[4:0])
		5'b00000: limit <= 8'd5;
		5'b00001: limit <= 8'd10;
		5'b00010: limit <= 8'd15;
		5'b00011: limit <= 8'd20;
		5'b00100: limit <= 8'd25;
		5'b00101: limit <= 8'd30;
		5'b00110: limit <= 8'd35;
		5'b00111: limit <= 8'd40;
		5'b01000: limit <= 8'd45;
		5'b01001: limit <= 8'd50;
		5'b01010: limit <= 8'd55;
		5'b01011: limit <= 8'd60;
		5'b01100: limit <= 8'd65;
		5'b01101: limit <= 8'd70;
		5'b01110: limit <= 8'd75;
		5'b01111: limit <= 8'd80;
		5'b10000: limit <= 8'd85;
		5'b10001: limit <= 8'd90;
		5'b10010: limit <= 8'd95;
		5'b10011: limit <= 8'd100;
		5'b10100: limit <= 8'd105;
		5'b10101: limit <= 8'd110;
		5'b10110: limit <= 8'd115;
		5'b10111: limit <= 8'd120;
		5'b11000: limit <= 8'd125;
		5'b11001: limit <= 8'd130;
		5'b11010: limit <= 8'd135;
		5'b11011: limit <= 8'd140;
		5'b11100: limit <= 8'd145;
		5'b11101: limit <= 8'd150;
		5'b11110: limit <= 8'd155;
		5'b11111: limit <= 8'd160;
		default: limit <= 5;
	endcase	

  // display the speed limit in HEX4 and HEX5 as km/h
  BCD bcd_speed_limit(
	.binary(limit[7:0]),
	.Hundreds(l_hundreds),
	.Tens(l_tens),
	.Ones(l_ones)
	);

  hex_display l_display_tens(
	.IN(l_tens),
	.OUT(HEX5)
	);

  hex_display l_display_ones(
	.IN(l_ones),
	.OUT(HEX4)
	);

  // 1Hz clock (clock cycles are 1 seconds)
  wire flash_clock;
  wire [27:0] out2;
  RateDivider update(
	.clock(CLOCK_50),
 	.enable(1'b1),
 	.d(28'd25000000),
 	.q(out2)
	);
  assign flash_clock = (out2 == 28'd0) ? 1 : 0;

  // LEDG = within speed limit
  always @(posedge CLOCK_50)
  begin
	if (speed_output[7:0] <= limit) // Case where under speed_limit
		LEDG[7:0] <= 8'b11111111;
        else if (LEDR[17:0] == 18'b111111111111111111) // Case when over speed limit
		LEDG[7:0] <= 8'b00000000;
  end
  // flashing LEDR = passed speed limit
  always @(posedge CLOCK_50)
  begin
	if (flash_clock == 1'b1) begin
		if (speed_output[7:0] > limit && LEDR[17:0] == 18'b000000000000000000) // Case where over limit and LEDR is off
			LEDR[17:0] <= 18'b111111111111111111;
		else
			LEDR[17:0] <= 18'b000000000000000000; // Case where over limit and LEDR is on
	end
        else if (LEDG[7:0] == 8'b11111111) // Case when under speed limit
		LEDR[17:0] <= 18'b000000000000000000;
  end

endmodule

/* This is the speed calculator module
   It does not work, because the usensor code does not generate distance.
*/
module speed_calculator(speed, displacement, trig, echo, clock);
  input clock;
  inout echo, trig;
  output reg [20:0] displacement;
  output [20:0] speed;
  // on every clock cycle, update curr and prev distance
  wire [20:0] curr_dist;
  reg [20:0] prev_dist;
  // calculate the distance with usensor
  usensor distance_calculator(
	.distance(curr_dist),
	.trig(trig),
	.echo(echo),
	.clock(clock)
	);

  // 100Hz clock (clock cycles are 0.01 seconds)
  wire [27:0] out1;
  reg adj_clock;
  RateDivider rd(
	.clock(CLOCK_50),
 	.enable(1'b1),
 	.d(28'd500000),
 	.q(out1)
	);

  always @(posedge clock) begin
	if (out1 == 28'd0)
		adj_clock <= ~adj_clock;
  end

  // update previous distance every 0.01 second
  always @(posedge clock) begin
    if (adj_clock == 1'b1)
       prev_dist <= curr_dist;
  end
  // calculate displacement with current and previous distance
  always @(posedge clock) begin
    if (adj_clock == 1'b0)
      displacement <= (curr_dist > prev_dist)?(curr_dist - prev_dist):(prev_dist - curr_dist);
  end
  // calculate speed with displacement, convert to km/h
  assign speed = (((displacement * 100)*36)/1000);
endmodule

// Module to calculate distance with an ultrasonic sensor
// Code referenced from
// https://github.com/mohammadmoustafa/CSCB58-Winter-2018-Project
module usensor(distance, trig, echo, clock);
  input clock, echo;
  output reg [25:0] distance;
  output reg trig;

  reg [25:0] master_timer;
  reg [25:0] trig_timer;
  reg [25:0] echo_timer;
  reg [25:0] echo_shift10;
  reg [25:0] echo_shift12;
  reg [25:0] temp_distance;
  reg echo_sense, echo_high;

  localparam  TRIG_THRESHOLD = 14'b10011100010000,
              MASTER_THRESHOLD = 26'b10111110101111000010000000;


  always @(posedge clock)
  begin
    if (master_timer == MASTER_THRESHOLD)
		begin
        master_timer <= 0;
		  
		  end
    else if (trig_timer == TRIG_THRESHOLD || echo_sense)
      begin
        trig <= 0;
        echo_sense <= 1;
        if (echo)
			   			    begin
					echo_high <= 1;
					echo_timer <= echo_timer + 1;
					//////////////////////////////////////////////////////
					// CLOCK_50 -> 50 000 000 clock cycles per second
					// let n = number of cycles
					// speed of sound in air: 340m/s
					// n / 50 000 000 = num of seconds
					// num of seconds * 340m/s = meters
					// meters * 100 = cm ~ distance to object and back
					// So we divide by 2 to get distance to object
					// 1/ 50 000 000 * 340 * 100 / 2 = 0.00034
					// n * 0.00034 = n * 34/100 000 = n / (100 000/34)
					// = 2941
					// To make up for sensor inaccuracy and simple math
					// we round down to 2900
					temp_distance <= (echo_timer / 2900);
					//////////////////////////////////////////////////////
			    end
        else
          begin
				distance <= temp_distance + 2'd2;
				echo_timer <= 0;
				trig_timer <= 0;
				echo_sense <= 0;
          end
      end
    else
	   begin
      trig <= 1;
      trig_timer <= trig_timer + 1;
      master_timer <= master_timer + 1;
    end
  end
endmodule

module hex_display(IN, OUT);
   input [3:0] IN;
	 output reg [7:0] OUT;

	 always @(*)
	 begin
		case(IN[3:0])
			4'b0000: OUT = 7'b1000000;
			4'b0001: OUT = 7'b1111001;
			4'b0010: OUT = 7'b0100100;
			4'b0011: OUT = 7'b0110000;
			4'b0100: OUT = 7'b0011001;
			4'b0101: OUT = 7'b0010010;
			4'b0110: OUT = 7'b0000010;
			4'b0111: OUT = 7'b1111000;
			4'b1000: OUT = 7'b0000000;
			4'b1001: OUT = 7'b0011000;
			4'b1010: OUT = 7'b0001000;
			4'b1011: OUT = 7'b0000011;
			4'b1100: OUT = 7'b1000110;
			4'b1101: OUT = 7'b0100001;
			4'b1110: OUT = 7'b0000110;
			4'b1111: OUT = 7'b0001110;

			default: OUT = 7'b0111111;
		endcase

	end
endmodule

// BINARY TO BCD CONVERSION ALGORITHM
// CODE REFERENCED FROM
// http://www.eng.utah.edu/~nmcdonal/Tutorials/BCDTutorial/BCDConversion.html
module BCD (
  input [7:0] binary,
  output reg [3:0] Hundreds,
  output reg [3:0] Tens,
  output reg [3:0] Ones
  );

  integer i;
  always @(binary)
  begin
    //set 100's, 10's, and 1's to 0
    Hundreds = 4'd0;
    Tens = 4'd0;
    Ones = 4'd0;

    for (i = 7; i >=0; i = i-1)
    begin
      //add 3 to columns >= 5
      if (Hundreds >= 5)
        Hundreds = Hundreds + 3;
      if (Tens >= 5)
        Tens = Tens + 3;
      if (Ones >= 5)
        Ones = Ones + 3;

      //shift left one
      Hundreds = Hundreds << 1;
      Hundreds[0] = Tens[3];
      Tens = Tens << 1;
      Tens[0] = Ones[3];
      Ones = Ones << 1;
      Ones[0] = binary[i];
    end
  end
endmodule

module RateDivider(clock, enable, d, q);
    input enable, clock;
    // 50MHz:d=1, 1Hz:d=50000000, 0.5Hz:d=100000000, 0.25Hz:d=200000000
    input [27:0] d;
    output reg [27:0] q;
    always @(posedge clock)
    begin
    // reset to d after counting to 0
    if (q == 28'd0)
	 q <= d;
    // count down if enabled
    else if (enable == 1'b1)
	 q <= q - 1'b1;
    end
endmodule

// This isn't being used because who needs to convert to miles :)
module DFlipFLop(data, clk, reset, q);
	input data, clk, reset;
	output reg q;
	always @(posedge clk)
	begin
	// Convert to Km
	if (reset == 1'b0)
		q <= (data * 8)/5;
	// Convert to miles
	else
		q <= (data * 5)/8;
	end
endmodule
