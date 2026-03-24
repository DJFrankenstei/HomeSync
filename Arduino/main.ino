#include <SoftwareSerial.h>

SoftwareSerial BT(10, 11);

int numRelays = 3;
bool relayState[3] = {false, false, false}; // OFF initially

int trigPin = 5;
int echoPin = 7;

int idx = 0;

unsigned long lastSend = 0;

bool streamOpen = false;


void setup() {
  Serial.begin(9600);
  BT.begin(9600);

  for (int i = 0; i < numRelays; i++) {
    pinMode(i + 2, OUTPUT);
    digitalWrite(i + 2, HIGH);
  }

  pinMode(trigPin, OUTPUT);
  pinMode(echoPin, INPUT);

  pinMode(6, INPUT);
}

void loop() {
  int val = readBT();

 

  if (val != -1) {
    Serial.println(val);
    if (val == 3) {
      streamOpen = !streamOpen;
      Serial.println("toggled stream");
    } else {
      relayState[val] = !relayState[val]; // TOGGLE
  
      if (relayState[val]) {
        digitalWrite(val + 2, LOW);
      } else {
        digitalWrite(val + 2, HIGH);
      }
    }
  }

  if ((motionDetected() && getCm() < 20) && !streamOpen) {
    Serial.println(getCm());
    
    
    int toSend = idx % 2;

    idx++;

    BT.write(toSend);
  }

  unsigned long now = millis();
  if (streamOpen && now - lastSend > 200) {  // send every 200ms
        lastSend = now;
        String distance = String(getCm());
        String motion = motionDetected() ? "true" : "false";
        String stream = distance + ";" + motion;

        Serial.println(stream);
        BT.print(stream);
  }

  if (Serial.available() > 0) {
    int incoming = Serial.read();

    if (incoming) {

      int toSend = idx % 2;

      idx++;

      Serial.println(toSend);
   //   BT.write(toSend);
    }
    
  }

  

  
}

bool motionDetected() {
  return digitalRead(6) == HIGH;
}

long getCm() {
  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);

  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);

  long duration = pulseIn(echoPin, HIGH);

  long distance = duration * 0.034 / 2;

  return distance;
}

int readBT() {
  if (BT.available() > 0) {
    char c = BT.read();
    int num = c - '0';

    if (num >= 0 && num < numRelays + 1) {
      return num;
    }
  }
  return -1;
}

void toggleStream() {
  streamOpen = !streamOpen;
}
