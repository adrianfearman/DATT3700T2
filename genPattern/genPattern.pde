import mqtt.*;
import processing.serial.*;

MQTTClient client;

int random;
int receivedVal;
String test = "";
String testStr="";

void setup() {
  size(200,200);
  
  client = new MQTTClient(this);
  client.connect("mqtt://datt3700:datt3700experiments@datt3700.cloud.shiftr.io", 
                  "alice");
                  
  //generates a string of 4 random numbers from 1-9
  //for(int i=0;i<4;i++){
  //  random = int(random(1,10));
  //  test += random; //adds the random number to the string
  //}
  //client.publish("/aliceTest", test); //send to cloud
  
  //generates 4 random numbers from 1-9
  for(int i=0;i<4;i++){
    random = int(random(1,10));
    test = str(random);
    client.publish("/aliceTest", test); //send to cloud
    
    //to see the string of numbers generated:
    testStr += random; //adds the random number to a string
  }
  println(testStr); //prints string of numbers to console
 
}

void draw() {
  //displays reading on screen
  background(0);
  text("test value:" + test, 20, height/2);
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
