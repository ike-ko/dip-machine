# dip-machine

This repository is the code for a "dip machine" that my father asked me to put together for his work. The "dip machine" is a stepper motor controlled by an Arduino Uno microcontroller used in a lab for precise and controlled dipping of samples into various chemicals (My understanding of their use of this machine ends here...). The Arduino is connected to a PC, from which a GUI (Shown below) can be used to control the dipping mechanism.

I used the AccelStepper library to control the stepper motor in the Arduino code. It utilizes input from a serial port to set the speed at which the machine will dip and return, the distance to which it will dip down to, and the amount of time to hold at the set distance. The code also allows for stopping of movement at any time and for manual control of dipping with the arrow keys.

The GUI was created in Processing and can be seen below.

![Dipping machine GUI created in Processing](/screenshot.jpg?raw=true "Title")

