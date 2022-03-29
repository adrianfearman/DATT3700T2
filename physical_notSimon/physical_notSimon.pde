import mqtt.*;
import processing.serial.*;
import processing.sound.*;
import cc.arduino.*;

Arduino arduino;
MQTTClient client;

int random, receivedVal, plyrInput;
int currRound=3;
int life=3;
int score=0;

final int ROUNDSCORE=100;
final int PRESSED = 1;
final int NOTPRESSED = 0;
final int STARTPIN = 2; //change to first pin used on the arduino
final int CONVERT = STARTPIN-1; //used to convert to arrays based on which arduino pin is used
final int PINS = 8;

boolean pressable = false;
boolean intro = true;

String genInput = "";
String anonPattern = "";

ArrayList<Integer> genPattern =  new ArrayList();
ArrayList<Integer> plyrPattern = new ArrayList();
ArrayList<Integer> stateCheck = new ArrayList();
ArrayList<SoundFile> soundList = new ArrayList();
ArrayList<SoundFile> alarmList = new ArrayList();
ArrayList<Timer> ts = new ArrayList();

void setup() {
  
  arduino = new Arduino(this, Arduino.list()[2], 57600);
  
  for (int i=0; i<=13; i++) {
    arduino.pinMode(i, Arduino.INPUT);
  }
  
  for (int j=0; j<=PINS; j++){
    stateCheck.add(NOTPRESSED);
  }
  
  soundList.add(new SoundFile(this, "BARK.mp3"));
  soundList.add(new SoundFile(this, "BONK.mp3"));
  soundList.add(new SoundFile(this, "MARIO_JUMP.mp3"));
  soundList.add(new SoundFile(this, "FART.mp3"));
  soundList.add(new SoundFile(this, "MEOW.mp3"));
  soundList.add(new SoundFile(this, "PARTY.mp3"));
  soundList.add(new SoundFile(this, "CHOMP.mp3"));
  soundList.add(new SoundFile(this, "TACOBELL.mp3"));
  
  alarmList.add(new SoundFile(this, "CORRECT.mp3"));
  alarmList.add(new SoundFile(this, "WRONG.mp3"));
  alarmList.add(new SoundFile(this, "PRICE_IS_WRONG.mp3"));
  alarmList.add(new SoundFile(this, "didi.mp3"));
  
  
  
  size(200,200);
  
  client = new MQTTClient(this);
  client.connect("mqtt://datt3700:datt3700experiments@datt3700.cloud.shiftr.io", 
                  "player");
}

class Timer {
  float timeRecord=0, intervalTime=0;
  SoundFile sound;
  boolean rePlay=false;
  Timer(SoundFile f, float t) {
    intervalTime=1000*t;
    sound=f;
    timeRecord=millis();
  }
  void timing() {
    if (millis()-timeRecord>intervalTime&&!sound.isPlaying()&&!rePlay)
    {
      sound.play();
      rePlay=true;
    }
    if (rePlay&&!sound.isPlaying()) {
      timeRecord=millis();
      rePlay=false;
    }
  }
}

void buttonPress(int button){
  if (intro == true){
      plyrInput = button-CONVERT;
      soundList.get(plyrInput-CONVERT).play();
  }
  if (plyrPattern.size() < genPattern.size()){
    plyrInput = button-CONVERT;
    plyrPattern.add(plyrInput);
    soundList.get(plyrInput-CONVERT).play();
    //println(plyrPattern);
    client.publish("/Team2/plyrInput", str(plyrInput));
    if (genPattern.size() == plyrPattern.size()) {
      delay(750);
      outcomeCheck();
    }
  }
}

void keyPressed() {
  if (key == CODED) {
    if (keyCode == UP) {
      intro = false;
      gameRound();
    } 
  } else if (key == 'y' || key == 'Y'){
    if (pressable == true){gameRound();}
  } else if (key == 'n' || key == 'N'){
    if (pressable == true) {exit();}
  }
}

void gameRound() {
    pressable = false;
    genPattern.clear();
    plyrPattern.clear();
    genInput = "";
    anonPattern = "";
    for(int i=0;i<=currRound;i++){
      random = int(random(1,9));
      genPattern.add(random);
      genInput = genInput + " " + str(random);
    }
    client.publish("/Team2/genInput", genInput);
    for(int i=0;i<=currRound;i++){
      delay(1000);
      soundList.get(genPattern.get(i)-1).play();
    }
    
    //timer needs to start
    
    //println(genPattern);
    println("GO!");
    
}

void continueGame() {
  pressable = true;
  println("");
  delay(200);
  println("CONTINUE GAME? 'Y' or 'N'");
}

void outcomeCheck() {
  if (plyrPattern.equals(genPattern)){     //checks if player is correct
    score += ROUNDSCORE;
    println("YOU WIN THE ROUND, CURRENT SCORE:" + score);
    println("YOU HAVE: " + life + " heart(s) left");
    alarmList.get(0).play();
    currRound++; 
    continueGame();
  } else {
      life--;
      println("YOU LOSE THE ROUND, CURRENT SCORE:" + score);
      println("YOU HAVE: " + life + " heart(s) left");
      if (life > 0){
        alarmList.get(1).play();
        continueGame();
      } else {
        alarmList.get(2).play();
        println("YOU HAVE LOST THE GAME. FINAL SCORE: " + score);
        currRound=3;
        life = 3;
      }
   }
}

void draw() {
  //displays reading on screen
  background(0);
  
  int prevState;
  int currState;
  for (int i = STARTPIN; i<(PINS+STARTPIN); i++) {
    if (arduino.digitalRead(i) == Arduino.HIGH){
      prevState = stateCheck.get(i-CONVERT);
      currState = arduino.digitalRead(i);
      if (prevState != currState){
        buttonPress(i);
        stateCheck.set(i-CONVERT, currState);
      }
    } else {
      stateCheck.set(i-CONVERT, NOTPRESSED);
    }
  }
}

void clientConnected() {
  println("client connected");
  
  //receive all group members' info
  client.subscribe("/Team2/buttonPressed");
}

//not sure if this part works
void messageReceived(String topic, byte[] payload) {
  if(topic.equals("/aliceTest"))
      receivedVal=int(new String(payload));
      
  println(receivedVal);
}
