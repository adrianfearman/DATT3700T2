import mqtt.*;
import processing.serial.*;

MQTTClient client;

int random;
int receivedVal;
int currRound=3;
int life = 3;
int score;
String genInput = "";
int plyrInput;

ArrayList<Integer> genPattern =  new ArrayList<>();
ArrayList<Integer> plyrPattern = new ArrayList<>();

void setup() {
  size(200,200);
  
  client = new MQTTClient(this);
  client.connect("mqtt://datt3700:datt3700experiments@datt3700.cloud.shiftr.io", 
                  "player");
                  
  //generates a string of 4 random numbers from 1-9
  //for(int i=0;i<4;i++){
  //  random = int(random(1,10));
  //  test += random; //adds the random number to the string
  //}
  //client.publish("/aliceTest", test); //send to cloud
  
  //generates 4 random numbers from 1-9
 /* for(int i=0;i<4;i++){
    random = int(random(1,10));
    test = str(random);
    client.publish("/aliceTest", test); //send to cloud
    
    //to see the string of numbers generated:
    testStr += random; //adds the random number to a string
  }
  println(testStr); //prints string of numbers to console
 */
}

void keyReleased(){
  if (plyrPattern.size() < genPattern.size()){
    if (Character.getNumericValue(key) >= 0 && Character.getNumericValue(key) <= 9){
      plyrInput = Character.getNumericValue(key);
      plyrPattern.add(plyrInput);
      println(plyrPattern);
      println(genPattern);
      client.publish("/Team2/plyrInput", str(plyrInput));
    }
  }
}

void keyPressed() {
  if (key == CODED) {
    if (keyCode == UP) {
      gameRound();
      println(genPattern);
    } 
  } else if (key == 'm' || key == 'M'){
    outcomeCheck();
  }
}

void gameRound() {
    genPattern.clear();
    plyrPattern.clear();
    genInput = "";
    for(int i=0;i<=currRound;i++){
      random = int(random(1,10));
      genPattern.add(random);
      genInput = genInput + " " + str(random);
    }
    println(genInput);
    client.publish("/Team2/genInput", genInput);
    println(genPattern);
    
}

void outcomeCheck() {
  score = currRound-2;
  if (plyrPattern.equals(genPattern)){     //checks if player is correct
    println("YOU WIN THE ROUND, CURRENT SCORE:" + score);
    println("YOU HAVE: " + life + " heart(s) left");
    currRound++; 
    gameRound();
  } else {
    println("YOU LOSE THE ROUND, CURRENT SCORE:" + score);
    println("YOU HAVE: " + life + " heart(s) left");
    life--;
    gameRound();
  }
}



void draw() {
  //displays reading on screen
  background(0);
  //text("test value:" + test, 20, height/2);
  
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
