
Serial port;
boolean portIsOpen = false;

class ArduinoSerial
{
    
   ControllerMotorShield controller;
   
   ArduinoSerial(ControllerMotorShield controller)
   {
     this.controller = controller;
     
     String[] ports = Serial.list();
     println("Available SERIAL ports:");
     for(int i=0; i<ports.length; i++)
     {
       println(ports[i]);
     }
     
     //in case we do not use the GUI port selector
     //set the portname manually and uncomment the openPort(...) line
     String portName = Serial.list()[1]; 
     //openPort(portName);

   }
   
   void openPort(String portName){
     println("----> Trying to open serial port " + portName);
     port = new Serial(this.controller, portName, 9600);
     // wait a little bit to be sure it is opened correctly
     delay(1000);
     portIsOpen = true;
   }
   
   void sendToArduino(int id, int value)
   {
      //println("-----> Sending to ARDUINO: Servo ID " + id + " WITH speed " + value);
      
      /*
      byte b[] = {64,32};
      b[0] = byte(id);
      b[1] = byte(...);
      port.clear();
      port.write(b[0]);
      port.write(b[1]);
      */
      
      port.clear();
      port.write(id);
      // value can go above 256 -> we need two bytes to send the value
      // euh...... c'est quoi ce bordel... j'ai utilisé des int alors que je parle de char/byte...
      int firstByte = value>>8;
      int secondByte = value&0xFF;
      //println("-----> " + firstByte + " " + secondByte);
      port.write(firstByte);
      port.write(secondByte);
      port.write('\n');
      
      //to be checked...
      //Probably better for arduino com but introduces too much latency in the GUI.
      //delay(30);
   }
   
   
   // prints out on the console DEBUGGING messages from Arduino (instead of using the arduino serial monitor)
   void listen()
   {
       //print("is listening...");
       if ( portIsOpen && port.available() > 0) {  // If data is available,
          String msg = port.readStringUntil('\n');
          if(msg != null) {
            print("Arduino received:",msg);
          }
       }
       
   }
    
};
