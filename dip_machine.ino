// dip_machine <5,50,3,10>

// AccelStepper Setup
#include <AccelStepper.h>
AccelStepper stepper(1, 7, 6);

// Define connections
#define BOT_LIMIT_SWITCH 3
#define TOP_LIMIT_SWITCH 4

// Define dip sequence enumeration
enum runningStates {
  RESET,
  STOP,
  //  CALIBRATE,
  MOVE_DOWN,
  HOLD,
  MOVE_UP,
  MANUAL
};

// Define variables
const float DIPSWITCH_SETTING = 400.0;          // Pulse/rev
const float BALLSCREW_LEAD = 5.0;               // mm/rev

const float RESET_SPEED = -320.0;               // steps per second, speed at which stepper resets to origin point (MUST BE NEGATIVE)

float downSpeed = 1.0;                          // mm/sec
float travelDistance = 10.0;                    // mm
float holdTime = 3.0;                           // sec
float upSpeed = 1.0;

float stepperSpeed = 320.0;                     // steps per second, calculated with DIPSWITCH_SETTING, BALLSCREW_LEAD, and the inputted desired speed
float travelRevs = 800.0;                       // travel distance converted to revolutions using DIPSWITCH_SETTING and BALLSCREW_LEAD

boolean newData = false;

enum runningStates currentSequence = STOP;      // tracks current step in dip sequence using defined enum
boolean isResetting = false;                    // used to reset stepper to top position

const byte NUM_CHARS = 32;
char receivedChars[NUM_CHARS];
char tempChars[NUM_CHARS];                      // temporary array for use when parsing

unsigned long prevMillis = 0;                   // track time for holding in position
unsigned long currentMillis = 0;

void setup() {
  Serial.begin(9600);
  pinMode(BOT_LIMIT_SWITCH, INPUT);
  pinMode(TOP_LIMIT_SWITCH, INPUT);
  stepper.setMaxSpeed(1000);
}

void loop() {
  recvWithStartEndMarkers();

  if (newData == true) {                // handle inputted serial data
    Serial.println(receivedChars);

    if (receivedChars[0] == 's') {      // stop dipping sequence
      currentSequence = STOP;
    }
    else if (receivedChars[0] == 'r') { // reset to top position
      stepper.setSpeed(RESET_SPEED);
      currentSequence = RESET;
    }
    else if (receivedChars[0] == 'm') {
      strcpy(tempChars, receivedChars + 1);
      calculateStepperSpeed(atof(tempChars));
      currentSequence = MANUAL;
    }
    else {
      strcpy(tempChars, receivedChars);
      parseData();

      //      stepper.setSpeed(RESET_SPEED);     // setup speed for calibration
      //      currentSequence = CALIBRATE;
      calibrateStepper();
      currentSequence = MOVE_DOWN;
    }
    newData = false;
  }

  switch (currentSequence) {
    case RESET:
      resetPosition();
      break;

    case STOP:
      break;

    //    case CALIBRATE:
    //      calibratePosition();
    //      break;

    case MOVE_DOWN:
      if (digitalRead(BOT_LIMIT_SWITCH) == false || stepper.currentPosition() >= travelRevs) {
        goToHold();
      }
      else {
        stepper.runSpeedToPosition();
      }
      break;

    case HOLD:
      currentMillis = millis();

      if (currentMillis - prevMillis >= holdTime * 1000.0) {
        currentSequence = MOVE_UP;
      }
      break;

    case MOVE_UP:
      if (digitalRead(TOP_LIMIT_SWITCH) == false || stepper.currentPosition() <= 0) {
        currentSequence = STOP;
      }
      else {
        stepper.runSpeedToPosition();
      }
      break;

    case MANUAL:
      if (digitalRead(TOP_LIMIT_SWITCH) == false || digitalRead(BOT_LIMIT_SWITCH) == false) {
        currentSequence = STOP;
      }
      else {
        stepper.runSpeed();
      }
      break;

    default:
      break;
  }
}

void recvWithStartEndMarkers() {
  static boolean recvInProgress = false;
  static byte ndx = 0;
  char startMarker = '<';
  char endMarker = '>';
  char rc;

  while (Serial.available() > 0 && newData == false) {
    rc = Serial.read();

    if (recvInProgress == true) {
      if (rc != endMarker) {
        receivedChars[ndx] = rc;
        ndx++;
        if (ndx >= NUM_CHARS) {
          ndx = NUM_CHARS - 1;
        }
      }
      else {
        receivedChars[ndx] = '\0'; // terminate the string
        recvInProgress = false;
        ndx = 0;
        newData = true;
      }
    }

    else if (rc == startMarker) {
      recvInProgress = true;
    }
  }
}

void parseData() {      // split the data into its parts

  char * strtokIndx;    // this is used by strtok() as an index

  strtokIndx = strtok(tempChars, ",");
  downSpeed = atof(strtokIndx);

  strtokIndx = strtok(NULL, ",");
  travelDistance = atof(strtokIndx);

  strtokIndx = strtok(NULL, ",");
  holdTime = atof(strtokIndx);

  strtokIndx = strtok(NULL, ",");
  upSpeed = atof(strtokIndx);
}

//void calibratePosition() {
//  if (digitalRead(TOP_LIMIT_SWITCH) == false) {
//    calibrateStepper();
//    currentSequence = MOVE_DOWN;
//  }
//  if (currentSequence == CALIBRATE) {
//    stepper.runSpeed();
//  }
//}

void resetPosition() {
  if (digitalRead(TOP_LIMIT_SWITCH) == false) {
    currentSequence = STOP;
  }
  stepper.runSpeed();
}

void calibrateStepper() {
  stepper.setCurrentPosition(0);
  calculateTravelRevs();
  stepper.moveTo(travelRevs);
  calculateStepperSpeed(downSpeed);
}

void calculateTravelRevs() {
  travelRevs = travelDistance / BALLSCREW_LEAD * DIPSWITCH_SETTING;
}

void calculateStepperSpeed(float desiredSpeed) {
  stepperSpeed = desiredSpeed * DIPSWITCH_SETTING / BALLSCREW_LEAD;
  stepper.setSpeed(stepperSpeed);
}

void goToHold() {
  stepper.moveTo(0);
  calculateStepperSpeed(upSpeed);
  currentSequence = HOLD;

  prevMillis = millis();
}
