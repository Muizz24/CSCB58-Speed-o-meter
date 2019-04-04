# CSCB58-Speed-o-meter
A verilog designed to measure the speed of any object in the ultra sonic sensor's vicinity
This is the repository for the our CSCB58 or Computer Organization course at the University of Toronto Scarborough.

Our project will consist of our DE2 Board connected to a depth sensor, the HC-SR04 through the board GPIO pins.

As per our original project proposal, our code will connect the depth sensor and output a speed that is measured in km/h for the object. The range the sensor can hold is a maximum of 400cm and there are multiple auxillary capabilities that the speedometer holds such as:
  - A speed limit detector on the LEDR and LEDG designed to provide warnings when a user is beyond a given speed limit
  - A speed limit provider depending on the switches giving a certain speed limit that triggers the speed limit detector
  - A conversion system from KM/h to Mi/h by a toggling Dflipflop assigned to a KEY.

Output of the displacement is displayed on HEX0, HEX1, and HEX2
Output of the speed limit is displayed on HEX4 and HEX5
Output of the speed is displayed on HEX6 and HEX7

All code is in verilog

