import themidibus.*;
import processing.serial.*;
import controlP5.*;



PFont fontBig;
PFont fontMiddle;
PFont fontSmall;

color darkBlue = 0xff14283b;
color turqoise = 0xff17a1a5;
color blueGreen = 0xff006468;

DropdownList ddlist;

String portNameGui;

class Gui implements ControlListener
{
  
  int nbMotors = 8;
  Slider[] sliders = new Slider[nbMotors];
  int minValueServo = 0;
  int maxValueServo = 180;
  int minValueStepper = -200;
  int maxValueStepper = 200;
  int minValueDC = -255;
  int maxValueDC = 255;
  
  
  Gui()
  {
    
    
    fontBig = createFont("Verdana",16,true); 
    fontMiddle = createFont("Verdana",14,true); 
    fontSmall = createFont("Verdana",12,true); 
    
    cp5.setColorForeground(turqoise);
    cp5.setColorBackground(blueGreen);
    cp5.setFont(fontBig);
    cp5.setColorActive(darkBlue);

  }
  
  void setup(){
    
    int yTitle = 80;
    cp5.addTextlabel("MOTORS_gui_main")
      .setText("MOTORS")
      .setPosition(50,yTitle)
      .setColorValue(0xff14283b)
      .setFont(fontBig);
      
      
    int yMotors = 170;
    for(int i=0; i<8; i++){
      
      int minv = minValueServo;
      int maxv = maxValueServo;
      if(i == 2 || i == 3) { minv = minValueStepper; maxv = maxValueStepper; }
      else if(i >= 4 && i <= 7) { minv = minValueDC; maxv = maxValueDC; }
      // parameters : name, minimum, maximum, default value (float), x, y, width, height
      sliders[i] = cp5.addSlider("SLIDERMOTORVAL_" + i,minv,maxv,0.5*(maxv-minv)+minv,250,yMotors,300,30);
      sliders[i].setSliderMode(Slider.FLEXIBLE);
      sliders[i].setColorValue(darkBlue);
      sliders[i].getValueLabel().align(ControlP5.RIGHT_OUTSIDE, ControlP5.CENTER).setFont(fontMiddle);
      sliders[i].getCaptionLabel().setVisible(false);
      sliders[i].addListener(this);
      
      Textlabel label = cp5.addTextlabel("LABELMOTORVAL_"+i).setText("motor"+i).setPosition(50,yMotors+5).setFont(fontSmall).setColor(darkBlue);
      if(i== 0) label.setText("Servo motor 0(pin 9 - center)");
      else if(i == 1) label.setText("Servo motor 1(pin 10 - edge)");
      else if(i == 2) label.setText("Stepper motor 2(M1-M2)");
      else if(i == 3) label.setText("Stepper motor 3(M3-M4)");
      else if(i == 4) label.setText("DC motor 4(M1)");
      else if(i == 5) label.setText("DC motor 5(M2)");
      else if(i == 6) label.setText("DC motor 6(M3)");
      else if(i == 7) label.setText("DC motor 7(M4)");
      
      yMotors += 50;
      
    }
    
    setupSelectPort(yTitle);
    
  }
  
  
  void setupSelectPort(int y){
    ddlist = cp5.addDropdownList("PORTS")
          .setPosition(250, y)
          .setSize(300, 25)
          .setHeight(150)
          .setItemHeight(25)
          .setBarHeight(25)
          .setFont(fontSmall)
          .setColorBackground(darkBlue)
          .setColorForeground(blueGreen)
          .setColorActive(darkBlue)
          .setColorCaptionLabel(color(255))
          ;
 
     ddlist.getCaptionLabel().set("ARDUINO PORT"); //set PORT before anything is selected
     ddlist.addListener(this);
     
     portNameGui = Serial.list()[0]; //0 as default
     //arduinoSerial.openPort(portNameGui);
  }
  
  String getPortName(){
    return portNameGui;
  }
  
  void drawSelectPort(){
 
    if(ddlist.isMouseOver()) {
       ddlist.clear(); 
       for (int i=0;i<Serial.list().length;i++) {
         ddlist.addItem(Serial.list()[i], i); 
       }
    }
    if(portIsOpen && port.available() > 0) {  //read incoming data from serial port
      println(port.readStringUntil('\n')); //read until new input
     } 
  }
  
  
  void setMotorValueFromMidi(int motorIndex, int midiValue)
  {
    int minv = minValueServo;
    int maxv = maxValueServo;
    if(motorIndex == 2 || motorIndex == 3) { minv = minValueStepper; maxv = maxValueStepper; }
    else if(motorIndex >= 4 && motorIndex <= 7) { minv = minValueDC; maxv = maxValueDC; }
    float value = map(midiValue,0,127,minv,maxv);
    if(motorIndex >= 0 && motorIndex < nbMotors)
    {
       sliders[motorIndex].setValue(value); 
    }
  }
  
  
  void reset(int motorIndex)
  {
    int minv = minValueServo;
    int maxv = maxValueServo;
    if(motorIndex == 2 || motorIndex == 3) { minv = minValueStepper; maxv = maxValueStepper; }
    else if(motorIndex >= 4 && motorIndex <= 7) { minv = minValueDC; maxv = maxValueDC; }
    if(motorIndex >= 0 && motorIndex < nbMotors)
    {
       sliders[motorIndex].setValue(0.5*(maxv-minv)); 
    } 
  }
  
  
  void resetAll()
  {
    for(int i=0; i<sliders.length; i++)
    {
       int minv = minValueServo;
       int maxv = maxValueServo;
       if(i == 2 || i == 3) { minv = minValueStepper; maxv = maxValueStepper; }
       else if(i >= 4 && i <= 7) { minv = minValueDC; maxv = maxValueDC; }
       sliders[i].setValue(0.5*(maxv-minv)); 
    }
  }
 
 
  void controlEvent(ControlEvent evt)
   {

      if(!evt.isController())
        return;
      
      Controller c = evt.getController();
      String addr = c.getAddress();
      float value = c.getValue();
      String[] params = split(addr,"_");
      
      //for debugging purposes...
      //println("CONTROL EVENT",addr,value);
      //for(int i=0; i<params.length; i++){ println(i,":",params[i]); }
      
      if (ddlist.isMouseOver() && addr.startsWith("/PORTS")) {
         //if(portIsOpen){
         //port.clear();
         //}
         //port.stop();
         portNameGui = Serial.list()[int(evt.getController().getValue())]; //port name is set to the selected port in the dropDownMenu
         arduinoSerial.openPort(portNameGui);
      }
      
      if(addr.startsWith("/SLIDERMOTORVAL")){
        if(params.length >= 2){
          int motorIndex = int(params[1]);
          //println("SLIDER / motor index",motorIndex);
          if(motorIndex == 2 || motorIndex == 3){ value += abs(minValueStepper); }
          else if(motorIndex >= 4 && motorIndex <= 7) { value += abs(minValueDC); }
          arduinoSerial.sendToArduino(motorIndex,int(value));
        }
      }
      
   }
  
  
};
