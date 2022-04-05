import mqtt.*;
import processing.serial.*;
import processing.sound.*;
import cc.arduino.*;

Arduino arduino;
MQTTClient client;

/*
"/Team2/plyrInput"
"/Team2/genInput"
"/Team2/life"
"/Team2/score"
"/Team2/round"
"/Team2/time"  //time left in round (counting up)
"/Team2/continue" //yes, no
"/Team2/outcome" //won, lost, lostgame
"/Team2/start"  //start
*/


int random, receivedVal, plyrInput;
int lateRound=9;
int currRound=3;
int life=3;
int score=0;
float maxTime=30000;
float minTime=10000;
float t;

final int MAXROUND=9;
final int ROUNDSCORE=100;
final int PRESSED = 1;
final int NOTPRESSED = 0;
final int STARTPIN = 2; //change to first pin used on the arduino
final int CONVERT = STARTPIN-1; //used to convert to arrays based on which arduino pin is used
final int PINS = 8;

boolean startTimer = false;
boolean pressable = false; //start btn
boolean cdPlaying = false;
boolean intro = true; //intro screen
boolean lostTime = false;

String genInput = "";

ArrayList<Integer> genPattern =  new ArrayList();
ArrayList<Integer> plyrPattern = new ArrayList();
ArrayList<Integer> stateCheck = new ArrayList();
ArrayList<SoundFile> soundList = new ArrayList();
ArrayList<SoundFile> alarmList = new ArrayList();

void setup() {
  
  arduino = new Arduino(this, Arduino.list()[2], 57600);
  
  for (int i=2; i<=10; i++) {
    arduino.pinMode(i, Arduino.INPUT);
  }
  
  for (int j=0; j<PINS; j++){
    println(j);
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
  alarmList.add(new SoundFile(this, "COUNTDOWN.mp3"));
  
  
  
  size(200,200);
  
  client = new MQTTClient(this);
  client.connect("mqtt://datt3700:datt3700experiments@datt3700.cloud.shiftr.io", 
                  "player");
}

void buttonPress(int button){
  if (intro == true){
      plyrInput = button-CONVERT;
      client.publish("/Team2/plyrInput", str(plyrInput));
      soundList.get(plyrInput-1).play();
  }
  if (plyrPattern.size() < genPattern.size()){
    plyrInput = button-CONVERT;
    plyrPattern.add(plyrInput);
    soundList.get(plyrInput-CONVERT).play();
    println(plyrPattern);
    client.publish("/Team2/plyrInput", str(plyrInput));
    if (genPattern.size() == plyrPattern.size()) {
      startTimer=false;
      delay(750);
      outcomeCheck();
    }
  }
}


void keyReleased(){
  if (intro == true){
    if (Character.getNumericValue(key) > 0 && Character.getNumericValue(key) < 9){
      plyrInput = Character.getNumericValue(key);
      client.publish("/Team2/plyrInput", str(plyrInput));
      soundList.get(plyrInput-1).play();
    }
  }
  if (plyrPattern.size() < genPattern.size()){
    if (Character.getNumericValue(key) > 0 && Character.getNumericValue(key) < 9){
      plyrInput = Character.getNumericValue(key);
      plyrPattern.add(plyrInput);
      soundList.get(plyrInput-1).play();
      println(plyrPattern);
      client.publish("/Team2/plyrInput", str(plyrInput));
      if (genPattern.size() == plyrPattern.size()) {
        startTimer=false;
        delay(750);
        outcomeCheck();
      }
    }
  }
}

void keyPressed() {
  if (key == CODED) {
    if (keyCode == UP) {
      client.publish("/Team2/start", "start");
      intro = false;
      gameRound();
    } 
  } else if (key == 'y' || key == 'Y'){
    if (pressable == true){
      client.publish("/Team2/continue", "yes");
      gameRound();
    }
    
  } /*else if (key == 'n' || key == 'N'){
    if (pressable == true){
      client.publish("/Team2/continue", "no");
      exit();
    }
  }*/
}

void gameRound() {
  client.publish("/Team2/life", str(life));
  client.publish("/Team2/score", str(score));
  client.publish("/Team2/round", str(currRound+1));
  if (lateRound>MAXROUND && maxTime>minTime) {maxTime-=2000;}
  pressable=false;
  startTimer=false;
  cdPlaying=false;
  genPattern.clear();
  plyrPattern.clear();
  genInput = "";
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
  
  println(genPattern);
  
  println("GO!");
  t=millis();
  startTimer=true;
   //timer();
    
}

void continueGame() {
  pressable = true;
  println("");
  delay(200);
  println("CONTINUE GAME? 'Y' or 'N'");
}

void outcomeCheck() {
  alarmList.get(3).stop();
  if (plyrPattern.equals(genPattern)){     //checks if player is correct
    score += ROUNDSCORE;
    //client.publish("/Team2/life", str(life));
    client.publish("/Team2/score", str(score));
    client.publish("/Team2/outcome", "won");
    println("YOU WIN THE ROUND, CURRENT SCORE:" + score);
    println("YOU HAVE: " + life + " heart(s) left");
    alarmList.get(0).play();
    if(currRound<MAXROUND) {currRound++;} 
    else {lateRound++;}
    continueGame();
  } else {
    life--;
    //client.publish("/Team2/life", str(life));
    client.publish("/Team2/score", str(score));
    if (lostTime == true){
      client.publish("/Team2/outcome", "time");
      lostTime=false;
    } else {
      client.publish("/Team2/outcome", "wrong");
    }
    println("YOU LOSE THE ROUND, CURRENT SCORE:" + score);
    println("YOU HAVE: " + life + " heart(s) left");
    if (life > 0){
      alarmList.get(1).play();
      continueGame();
    } else {
      alarmList.get(2).play();
      //client.publish("/Team2/life", str(life));
      client.publish("/Team2/score", str(score));
      client.publish("/Team2/outcome", "lostgame");
      println("YOU HAVE LOST THE GAME. FINAL SCORE: " + score);
      currRound=3;
      life=3;
      intro=true;
    }
   }
}

String timeConvert(float tC){
  float countdown = ((tC - maxTime) * -1)/1000;
  return str(int(countdown));
}


void draw() {
  //displays reading on screen
  background(0);
  
 for (int i = STARTPIN; i<13; i++){
 if (arduino.digitalRead(i) == Arduino.HIGH){
   println(i + " is working");
 }
 }
 
  int prevState;
  int currState;
  for (int i = STARTPIN; i<(PINS+STARTPIN); i++) {
    if (arduino.digitalRead(i) == Arduino.HIGH){
      prevState = stateCheck.get(i-STARTPIN);
      currState = arduino.digitalRead(i);
      if (prevState != currState){
        buttonPress(i);
        stateCheck.set(i-STARTPIN, currState);
      }
    } else {
      stateCheck.set(i-STARTPIN, NOTPRESSED);
    }
  }
  
  if (arduino.digitalRead(10) == Arduino.HIGH){
    if (pressable == true) {
      client.publish("/Team2/continue", "yes");
      pressable = false;
      gameRound();
    }
    if (intro == true) {
      client.publish("/Team2/start", "start");
      intro = false;
      gameRound();
    }
  }
  
  textSize(60);
  text(str(int((millis()-t)/1000)), 20, 60); 

  if(startTimer==true){
    client.publish("/Team2/time", timeConvert(millis()-t));
    if ((millis()-t)>=maxTime){
      startTimer=false;
      println("TIMES UP");
      lostTime = true;
      outcomeCheck();
    } 
    if ((millis()-t)>=maxTime-10000 && cdPlaying==false){
      cdPlaying=true;
      alarmList.get(3).play();
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
