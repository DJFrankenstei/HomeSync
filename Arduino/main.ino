#include <SoftwareSerial.h>
#include <DHT.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>

SoftwareSerial BT(10, 11);

#define DHTPIN 8
#define DHTTYPE DHT11

DHT dht(DHTPIN, DHTTYPE);
LiquidCrystal_I2C lcd(0x27, 20, 4);

int numRelays = 3;
bool relayState[3] = {false, false, false};

bool lcdOn = false;

int trigPin = 5;
int echoPin = 7;
int pirPin = 6;

unsigned long lastSend = 0;

bool doorStream = false;
bool tempStream = false;

String incomingBuffer = "";

void setup() {
  Serial.begin(9600);
  BT.begin(9600);
  dht.begin();

  lcd.init();
  lcd.noBacklight();
  lcd.clear();

  for (int i = 0; i < numRelays; i++) {
    pinMode(i + 2, OUTPUT);
    digitalWrite(i + 2, HIGH);
  }

  pinMode(trigPin, OUTPUT);
  pinMode(echoPin, INPUT);
  pinMode(pirPin, INPUT);
}

void loop() {
  handleIncomingBT();

  unsigned long now = millis();

  if (now - lastSend > 300) {
    lastSend = now;

    long distance = getCm();
    bool motion = motionDetected();

    // ---- DOOR ----
    if (doorStream) {
      String msg = "0;" + String(distance) + ";" + (motion ? "true" : "false");
      BT.println(msg);
    } else {
      if (distance < 50 && motion) {
        static int idx = 0;
        int toSend = idx % 2;
        idx++;
        BT.println(toSend);
      }
    }

    // ---- TEMP ----
    if (tempStream) {
      float temp = dht.readTemperature();
      float humidity = dht.readHumidity();

      if (!isnan(temp) && !isnan(humidity)) {
        String msg = "1;" + String(temp) + ";" + String(humidity);
        BT.println(msg);
      }
    }
  }
}

// -------- HANDLE INCOMING --------
void handleIncomingBT() {
  while (BT.available()) {
    char c = BT.read();

    if (c == '\n') {
      processMessage(incomingBuffer);
      incomingBuffer = "";
    } else {
      incomingBuffer += c;
    }
  }
}

// -------- PROCESS MESSAGE --------
void processMessage(String msg) {
  msg.trim();

  // ---- SINGLE CHAR COMMAND ----
  if (msg.length() == 1 && isDigit(msg[0])) {
    int val = msg[0] - '0';

    Serial.println(val);

    if (val == 3) {
      lcdOn = !lcdOn;
      if (lcdOn) lcd.backlight();
      else lcd.noBacklight();
    }
    else if (val == 4) {
      tempStream = !tempStream;
    }
    else if (val == 5) {
      doorStream = !doorStream;
    }
    else if (val < numRelays) {
      relayState[val] = !relayState[val];
      digitalWrite(val + 2, relayState[val] ? LOW : HIGH);
    }

    return;
  }

  // ---- STRUCTURED LCD MESSAGE ----
  int firstSep = msg.indexOf(';');
  int secondSep = msg.indexOf(';', firstSep + 1);
  int thirdSep = msg.indexOf(';', secondSep + 1);

  if (firstSep == -1 || secondSep == -1 || thirdSep == -1) return;

  int row1 = msg.substring(0, firstSep).toInt();
  String data1 = msg.substring(firstSep + 1, secondSep);

  int row2 = msg.substring(secondSep + 1, thirdSep).toInt();
  String data2 = msg.substring(thirdSep + 1);

  displayASCII(row1, data1);
  displayASCII(row2, data2);
}

// -------- ASCII DISPLAY --------
void displayASCII(int row, String asciiData) {
  if (!lcdOn) return;
  if (row > 1) return;

  lcd.setCursor(0, row);

  String text = "";
  int start = 0;

  while (true) {
    int underscore = asciiData.indexOf('_', start);

    String numStr;
    if (underscore == -1) {
      numStr = asciiData.substring(start);
    } else {
      numStr = asciiData.substring(start, underscore);
    }

    char c = (char) numStr.toInt();
    text += c;

    if (underscore == -1) break;
    start = underscore + 1;
  }

  lcd.print("                    "); // 20 spaces
  lcd.setCursor(0, row);
  lcd.print(text);
}

// -------- SENSORS --------
bool motionDetected() {
  return digitalRead(pirPin) == HIGH;
}

long getCm() {
  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);

  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);

  long duration = pulseIn(echoPin, HIGH, 30000);
  return duration * 0.034 / 2;
}