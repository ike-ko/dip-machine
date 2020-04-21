import controlP5.*;
import processing.serial.*;

Serial port;
char startMarker = '<';
char endMarker = '>';
String ds, td, ht, us;

ControlP5 cp5;
Textfield downSpeed, travelDistance, holdTime, upSpeed;
Button begin, moveUp, moveDown;

void setup() {
  size(455, 500);

  printArray(Serial.list());
  port = new Serial(this, "COM3", 9600);

  cp5 = new ControlP5(this);
  PFont buttonFont = createFont("arial bold", 14);

  downSpeed = cp5.addTextfield("downSpeed")
    .setLabel("")
    .setPosition(335, 80)
    .setSize(100, 40)
    .setColorForeground(color(0, 0, 0))
    .setColorBackground(color(255, 255, 255))
    .setColorValue(color(0, 0, 0))
    .setFont(createFont("arial", 26))
    ;

  travelDistance = cp5.addTextfield("travelDistance")
    .setLabel("")
    .setPosition(335, 140)
    .setSize(100, 40)
    .setColorForeground(color(0, 0, 0))
    .setColorBackground(color(255, 255, 255))
    .setColorValue(color(0, 0, 0))
    .setFont(createFont("arial", 26))
    ;

  holdTime = cp5.addTextfield("holdTime")
    .setLabel("")
    .setPosition(335, 200)
    .setSize(100, 40)
    .setColorForeground(color(0, 0, 0))
    .setColorBackground(color(255, 255, 255))
    .setColorValue(color(0, 0, 0))
    .setFont(createFont("arial", 26))
    ;

  upSpeed = cp5.addTextfield("upSpeed")
    .setLabel("")
    .setPosition(335, 260)
    .setSize(100, 40)
    .setColorForeground(color(0, 0, 0))
    .setColorBackground(color(255, 255, 255))
    .setColorValue(color(0, 0, 0))
    .setFont(createFont("arial", 26))
    ;

  begin = cp5.addButton("begin")
    .setLabel("Start")
    .setPosition(20, 325)
    .setSize(125, 75)
    .setFont(buttonFont)
    ;

  cp5.addButton("stop")
    .setLabel("      Stop\n(SPACE BAR)")
    .setPosition(310, 325)
    .setSize(125, 75)
    .setFont(buttonFont)
    .setColorBackground(color(255, 0, 0))
    .setColorForeground(color(255, 100, 100))
    .setColorActive(color(255, 150, 150))
    ;

  cp5.addButton("reset")
    .setLabel("Reset")
    .setPosition(310, 410)
    .setSize(125, 75)
    .setFont(buttonFont)
    .setColorBackground(color(255, 0, 0))
    .setColorForeground(color(255, 100, 100))
    .setColorActive(color(255, 150, 150))
    ;

  moveUp = cp5.addButton("moveUp")
    .setLabel("      Move Up\n(UP ARROW KEY)")
    .setPosition(150, 325)
    .setSize(155, 75)
    .setFont(buttonFont)
    ;

  moveDown = cp5.addButton("moveDown")
    .setLabel("       Move Down\n(DOWN ARROW KEY)")
    .setPosition(150, 410)
    .setSize(155, 75)
    .setFont(buttonFont)
    ;
}

void draw() {
  background(180, 180, 180);
  fill(0, 0, 0);
  textSize(32);
  text("Dip Machine", 20, 50);
  textSize(24);
  text("Down Speed", 20, 100);
  text("Travel Distance", 20, 160);
  text("Hold Time", 20, 220);
  text("Up Speed", 20, 280);
  textSize(18);
  text("(mm/sec, max 12.5)", 20, 120);
  text("(millimeters, max 350)", 20, 180);
  text("(seconds)", 20, 240);
  text("(mm/sec, max 12.5)", 20, 300);
  
  checkButtonStatus();
}

void keyPressed() {
  if (key == CODED) {
    if (keyCode == UP) {
      moveUp();
    } else if (keyCode == DOWN) {
      moveDown();
    }
  } else {
    if (key == ' ') {
      stop();
    }
  }
}

void keyReleased() {
  if (key == CODED) {
    if (keyCode == UP || keyCode == DOWN) {
      stop();
    }
  }
}

void checkButtonStatus() {
  if (validateAll() == true) {
    begin
      .unlock()
      .setColorBackground(color(0, 0, 255));
  } else {
    begin
      .lock()
      .setColorBackground(color(50, 50, 50));
  }

  if (validateSpeed(ds) == true) {
    moveDown
      .unlock()
      .setColorBackground(color(0, 0, 255));
  } else {
    moveDown
      .lock()
      .setColorBackground(color(50, 50, 50));
  }

  if (validateSpeed(us) == true) {
    moveUp
      .unlock()
      .setColorBackground(color(0, 0, 255));
  } else {
    moveUp
      .lock()
      .setColorBackground(color(50, 50, 50));
  }
}

void begin() {
  ds = downSpeed.getText();
  td = travelDistance.getText();
  ht = holdTime.getText();
  us = upSpeed.getText();

  if (
    validateSpeed(ds) == true &&
    validateDistance(td) == true &&
    validateTime(ht) == true &&
    validateSpeed(us) == true
    ) {
    port.write(startMarker + ds + "," + td  + "," + ht + "," + us + endMarker);
  }
}

void stop() {
  port.write(startMarker + "s" + endMarker);
}

void reset() {
  port.write(startMarker + "r" + endMarker);
}

void moveUp() {
  us = upSpeed.getText();
  if (validateSpeed(us) == true) {
    port.write(startMarker + "m-" + us + endMarker);
  }
}

void moveDown() {
  ds = downSpeed.getText();
  if (validateSpeed(ds) == true) {
    port.write(startMarker + "m" + ds + endMarker);
  }
}

boolean validateAll() {
  ds = downSpeed.getText();
  td = travelDistance.getText();
  ht = holdTime.getText();
  us = upSpeed.getText();

  if (
    validateSpeed(ds) == true &&
    validateDistance(td) == true &&
    validateTime(ht) == true &&
    validateSpeed(us) == true
    ) {
    return true;
  }
  return false;
}

boolean validateSpeed(String input) {
  float speed;

  try {
    speed = Float.parseFloat(input);
  }
  catch (NumberFormatException nfe) {
    return false;
  }

  if (speed > 0 && speed <= 12.5) {
    return true;
  }
  return false;
}

boolean validateDistance(String input) {
  float dist;

  try {
    dist = Float.parseFloat(input);
  }
  catch (NumberFormatException nfe) {
    return false;
  }

  if (dist > 0 && dist <= 350) {
    return true;
  }
  return false;
}

boolean validateTime(String input) {
  float time;

  try {
    time = Float.parseFloat(input);
  }
  catch (NumberFormatException nfe) {
    return false;
  }

  if (time >= 0) {
    return true;
  }
  return false;
}
