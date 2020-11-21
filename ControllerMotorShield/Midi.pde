

static final int  MAX_MIDI_NUM  = 128;
MidiBus midiBus;
int minMidiValue = 0;
int maxMidiValue = 127;
int stopMidiValue = 64;

void listMidiDevices()
{
  MidiBus.list();
}

void openMidi(String in,String out)
{
  println("----> Trying to open midi port ",in,out);
  midiBus = new MidiBus(this, in , out );
}

void controllerChange(int channel, int num, int value)
{
    // println("CC ( num:", num, "/ value:",value,"/ channel:",channel,")");
    /* corresponding values for num 
       (0-7): midi slider
       (16-23): midi knobs
       (32-39): stop buttons / value=127 -> press / value=0 -> release
       (42): stop all / value=127 -> press / value=0 -> release
    */
    
    if( num >= 0 && num<8) // midi sliders
    {
      int motorIndex = num;
      //println("MIDI slider / motor index:",motorIndex,"value:",value);
      gui.setMotorValueFromMidi(motorIndex,value);
    }
    else if( (num>=16)&&(num<24) ) //knobs
    {
      // DO NOTHING FOR NOW
      int motorIndex = num-16;
      println("MIDI knobs / motor index:",motorIndex,"value:",value);
    }
    else if( (num>=32)&&(num<40) && value == 127) //Bouton [S]
    {
      int motorIndex = num-32 + 8;
      println("MIDI STOP / motor index:",motorIndex);
      gui.reset(motorIndex);
    }
    else if( num==42 && value == 127) //Main Stop
    {
      println("MIDI STOP ALL");
      gui.resetAll();
    }
}

void noteOn(int channel, int pitch, int vel)
{
  print("NoteON:  C:"+channel+" N:"+pitch+" V:"+vel);
}

void noteOff(int channel, int pitch, int vel)
{
  print("NoteOFF: ");print(" C:"+channel);print(" N:"+pitch);println(" V:"+vel);
}
