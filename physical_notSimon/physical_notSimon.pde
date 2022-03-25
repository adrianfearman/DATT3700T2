import mqtt.*;
import processing.serial.*;
import processing.sound.*;

MQTTClient client;

//Team2/life - how many lives the player has left
//Team2/score - total score 
//Team2/genInput - the computer generated pattern
//Team2/plyrInput - the button the player is currently pushing
//Team2/continueGame - does the player want to move on to the next round?

int random, receivedVal, plyrInput;
int currRound=3;
int life=3;
int score=0;
final int ROUNDSCORE=100;

boolean pressable = false;
boolean intro = true;

String genInput = "";
String anonPattern = "";

ArrayList<Integer> genPattern =  new ArrayList();
ArrayList<Integer> plyrPattern = new ArrayList();
ArrayList<SoundFile> soundList = new ArrayList();
ArrayList<SoundFile> alarmList = new ArrayList();
ArrayList<Timer> ts = new ArrayList();

void setup() {
  
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

void keyReleased(){
  if (intro == true){
    if (Character.getNumericValue(key) > 0 && Character.getNumericValue(key) <= 9){
      plyrInput = Character.getNumericValue(key);
      soundList.get(plyrInput-1).play();
    }
  }
  if (plyrPattern.size() < genPattern.size()){
    if (Character.getNumericValue(key) > 0 && Character.getNumericValue(key) <= 9){
      plyrInput = Character.getNumericValue(key);
      plyrPattern.add(plyrInput);
      soundList.get(plyrInput-1).play();
      //println(plyrPattern);
      client.publish("/Team2/plyrInput", str(plyrInput));
      if (genPattern.size() == plyrPattern.size()) {
        delay(750);
        outcomeCheck();
      }
    }
  }
}

void keyPressed() {
  if (key == CODED) {
    if (keyCode == UP) {
      client.publish("/Team2/life", str(life));
      client.publish("/Team2/score", str(score));
      intro = false;
      gameRound();
    } 
  } else if (key == 'y' || key == 'Y'){
    if (pressable == true){
      client.publish("/Team2/continueGame", "Y");
      gameRound();
    }
  } else if (key == 'n' || key == 'N'){
    if (pressable == true){
      client.publish("/Team2/continueGame", "N");
      exit();
    }
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
  client.publish("/Team2/life", str(life));
  client.publish("/Team2/score", str(score));
}


void draw() {
  //displays reading on screen
  background(0);
  
}

void clientConnected() {
  println("client connected");
  
  //receive all group members' info
  client.subscribe("/aliceTest");
}

//not sure if this part works
void messageReceived(String topic, byte[] payload) {
  if(topic.equals("/aliceTest"))
      receivedVal=int(new String(payload));
      
  println(receivedVal);
}
