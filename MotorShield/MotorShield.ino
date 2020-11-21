/***************************************************
****************************************************
***************************************************/

 //https://learn.adafruit.com/adafruit-motor-shield-v2-for-arduino
 //https://www.airspayce.com/mikem/arduino/AccelStepper/classAccelStepper.html

 /***************************************************
 ****************************************************
 ***************************************************/
 


#include <AccelStepper.h>
#include <Wire.h>
#include <Adafruit_MotorShield.h>
#include "utility/Adafruit_MS_PWMServoDriver.h"

#include <Servo.h> 

// Adafruit Motor shield
Adafruit_MotorShield AFMShield(0x60); // Default address, no jumpers... so code done here for One shield.



//*** VARIABLE pour Filipe ************************************************************************!
byte stepper_move_type = SINGLE; // you can change these to SINGLE, DOUBLE, INTERLEAVE or MICROSTEP!



// ************************  servos  **************************
// speed value is between 0 and 180 (for the adafruit shield)
Servo servo__0;
Servo servo__1;


// ***********************  steppers  *************************
// value is between -200 and 200 with the stepper I have used... so 200 steps per revolution or/and 1.8 step angle
Adafruit_StepperMotor *stepper__2 = AFMShield.getStepper(200, 1); // M1-M2
Adafruit_StepperMotor *stepper__3 = AFMShield.getStepper(200, 2); // M3-M4
void forwardstepID_2() {  
  stepper__2->onestep(FORWARD, stepper_move_type);
}
void backwardstepID_2() {  
  stepper__2->onestep(BACKWARD, stepper_move_type);
}
void forwardstepID_3() {  
  stepper__3->onestep(FORWARD, stepper_move_type);
}
void backwardstepID_3() {  
  stepper__3->onestep(BACKWARD, stepper_move_type);
}

AccelStepper acc_stepper__2(forwardstepID_2, backwardstepID_2); 
AccelStepper acc_stepper__3(forwardstepID_3, backwardstepID_3); 

int minValueStepper = -200;
int maxValueStepper = 200;

bool velocity_mode = true;


// **************************  DC  ****************************
// speed value is between 0 and 255 (for the adafruit shield)
// we use negative numbers from processing in order to know the direction so from -255 to 255
int minValueDC = -255;
// later we'll use an array. Or not...
Adafruit_DCMotor *dc_motor4 = AFMShield.getMotor(1); // M1
Adafruit_DCMotor *dc_motor5 = AFMShield.getMotor(2); // M2
Adafruit_DCMotor *dc_motor6 = AFMShield.getMotor(3); // M3
Adafruit_DCMotor *dc_motor7 = AFMShield.getMotor(4); // M4


// ************************  SWITCH  *************************
// in order to easily switch between different kind of loops
typedef enum Loop_type:byte { RANDOM,COM,TEST } Loop_type;
Loop_type loop_type = COM; // by default, select COM where we listen to the serial port for processing messages


// used in order to trigger random values every two seconds when loop_type is set to RANDOM
unsigned long DELAY_TIME = 2000; // 2 seconds
unsigned long delayStart = 0;



void setup() {
 
  Serial.begin(9600); // Start serial communication at 9600 bps

  AFMShield.begin();

  servo__0.attach(9); // servo connection towards the center of the board
  servo__1.attach(10); // servo connection on the board edge

  // values to play with...... 
  // but there are probably more to play on
  // https://www.airspayce.com/mikem/arduino/AccelStepper/classAccelStepper.html
  // have a look at the examples of the accelstepper library! Menu "File" -> "Examples" -> "AccelStepper"
  acc_stepper__2.setMaxSpeed(200);
  //acc_stepper__2.setAcceleration(100);
  acc_stepper__3.setMaxSpeed(200);
  //acc_stepper__3.setAcceleration(100);

  delayStart = millis();

}


void loop() {

  if(loop_type == COM){
    
    listenToProcessing();
    
  }else if(loop_type == TEST){
    
    listenToSerialMonitor();  

    // write whatever you want in order to test different things.
    // ...

    // to be removed -> cecile
    updateTest();
    
  }else if(loop_type == RANDOM){
    
    updateRandom();
    
  }


  if(velocity_mode){
    acc_stepper__2.runSpeed();
    acc_stepper__3.runSpeed(); 
  }else{
    acc_stepper__2.run();
    acc_stepper__3.run();
  }
  

}


void listenToProcessing(){

  if (Serial.available() > 1) {
    //Serial.println("********** serial available **********"); // seulement si on arrive vraiment a rien lire dans la console
    //Serial.println('*');
    bool wait = true;
    int count = 0;
    int dataLength = 3;
    int dataIn[2];
    int value;
    while(wait) { // stay in this loop until newline is read
      if(Serial.available()) {
        //dataIn[count] = Serial.read();
        value = Serial.read();
        if (value == '\n') {
          wait = false; // exit while loop
        }else{
          //Serial.println(count);
          //Serial.println(dataIn[count]);
          if(count == 0) dataIn[0] = value;
          else if(count == 1) dataIn[1] = value<<8;
          else if(count == 2) dataIn[1] += value;
        }
        count++;
      }
    }  
    //Serial.println(dataIn[0]);
    //Serial.println(dataIn[1]);
    
    processDatas(dataIn,2);
    //Serial.println("*");
    //Serial.println("**************************************"); // seulement si on arrive vraiment a rien lire dans la console
  }

}


void processDatas(int data[], int dataLength){
  
  // according to the given ID, run the appropriate motor
  for(int i=0; i<dataLength; i += 2){
    int id = data[i];
    int value = 0;
    if( (i+1) < dataLength) value = data[i+1];
    //Serial.println(id);
    //Serial.println(value);
    if(id == 0 || id == 1){
      runServo(id,value);
    }else if(id == 2 || id == 3){
      runStepper(id,value);  
    }else if(id >= 4 && id <= 7){
      runDC(id,value);  
    }
  }
  
}


// sends value to servo with given id
void runServo(int id,int value){
  String s = String("run servo ") + id + String(" with value ") + value;
  // Serial.println(s);
  // servo library needs a number between 0 and 180
  // servoID_0.write(map(i, 0, 255, 0, 180));
  if(id == 0) servo__0.write(value);
  else if(id == 1) servo__1.write(value);
}


// sends value to stepper with given id
void runStepper(int id,int value){
  value = value + minValueStepper;
  String s = String("run stepper ") + id + String(" with value ") + value;
  //value = map(value,-200,200,-500,500); // valeur, min, max, minNew, maxNew => pour tester rapidement
  //Serial.println(s);
  if(id == 2)
  {
    if(velocity_mode) acc_stepper__2.setSpeed(value);
    else acc_stepper__2.moveTo(value);
  }
  else if(id == 3)
  {
    if(velocity_mode) acc_stepper__3.setSpeed(value);
    else acc_stepper__3.moveTo(value);
  }
}


// sends value to DC with given id
void runDC(int id,int value){
  Adafruit_DCMotor *dc_motor;
  if(id == 4) dc_motor = dc_motor4;
  else if(id == 5) dc_motor = dc_motor5;
  else if(id == 6) dc_motor = dc_motor6;
  else if(id == 7) dc_motor = dc_motor7;
  value = value + minValueDC; // [0,500] -> [-250,250]
  if(dc_motor != NULL) {
    dc_motor->setSpeed(abs(value));
    if(value > 0) dc_motor->run(FORWARD);
    else if(value < 0) dc_motor->run(BACKWARD);
    else if(value == 0) dc_motor->run(RELEASE);
  }
}


// to be removed... -> cecile
void updateTest(){
  triggerRandServos();
  triggerRandSteppers();
  triggerRandDCs();
}


void updateRandom(){
  if ((millis() - delayStart) >= DELAY_TIME) {
    delayStart = millis();
    triggerRandomPos();
  }
}


// triggers random positions for the servos, steppers and DCs
void triggerRandomPos(){

  triggerRandServos();
  triggerRandSteppers();
  triggerRandDCs();
  
}


// triggers one random value for both servos
void triggerRandServos(){
  int value =  random(200);
  servo__0.write(value);
  servo__1.write(value);
}


// triggers one random value for the steppers
void triggerRandSteppers(){
  
  
  //Serial.println("trigger steppers " + String(value));
  
  if(velocity_mode){
    int value = random(400) - 200;
    acc_stepper__2.setSpeed(value);
    acc_stepper__3.setSpeed(value);
  }else{
    int value = random(500) + 25;
    acc_stepper__2.moveTo(value);
    acc_stepper__3.moveTo(value);
  }
  
}


// triggers one random value for the DC motor
void triggerRandDCs(){
  
  int value = random(500) + minValueDC;
  //Serial.println("trigger DC:"+ String(value));
  triggerDC(4,value);
  value = random(500) + minValueDC;
  triggerDC(5,value);
  value = random(500) + minValueDC;
  triggerDC(6,value);
  value = random(500) + minValueDC;
  triggerDC(7,value);
}


// sends a value to the DC motor with the given id
void triggerDC(int id,int value){
  Adafruit_DCMotor *dc_motor = NULL;
  if(id == 4) dc_motor = dc_motor4;
  else if(id == 5) dc_motor = dc_motor5;
  else if(id == 6) dc_motor = dc_motor6;
  else if(id == 7) dc_motor = dc_motor7;
  value = value + minValueDC; // [0,500] -> [-250,250]
  if(dc_motor != NULL) {
    dc_motor->setSpeed(abs(value));
    if(value > 0) dc_motor->run(FORWARD);
    else if(value < 0) dc_motor->run(BACKWARD);
    else if(value == 0) dc_motor->run(RELEASE);
  }

}


// stops all DC motors
void stopAllDCs(){
  if(dc_motor4 != NULL) dc_motor4->run(RELEASE);  
  if(dc_motor5 != NULL) dc_motor5->run(RELEASE); 
  if(dc_motor6 != NULL) dc_motor6->run(RELEASE); 
  if(dc_motor7 != NULL) dc_motor7->run(RELEASE); 
}


// could be useful... in order to send directly entries to the arduino serial monitor
void listenToSerialMonitor(){
 
  if (Serial.available() > 0) {
    char rx_byte = Serial.read();
    
    if(rx_byte == '0'){
      Serial.println("is a zero");
    }else if(rx_byte == '1'){
      Serial.println("is a one");
    }
    
  } 
}


