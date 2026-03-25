#include <SoftwareSerial.h>
#include <DHT.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>

#define BT_RX 10
#define BT_TX 11

#define DHTPIN 8
#define DHTTYPE DHT11

#define NUM_RELAYS 3

#define RELAY_ON LOW
#define RELAY_OFF HIGH

#define CMD_LCD_TOGGLE 3
#define CMD_TEMP_STREAM 4
#define CMD_DOOR_STREAM 5

#define DIST_THRESHOLD 50
#define SEND_INTERVAL 300
#define DHT_INTERVAL 2000
#define PIR_DEBOUNCE 200

SoftwareSerial BT(BT_RX, BT_TX);
DHT dht(DHTPIN, DHTTYPE);
LiquidCrystal_I2C lcd(0x27, 20, 4);

bool relayState[NUM_RELAYS] = {false, false, false};

bool lcdOn = false;
bool doorStream = false;
bool tempStream = false;

String lcdCache[4];

unsigned long lastSend = 0;
unsigned long lastDHTRead = 0;
unsigned long lastPIRTime = 0;

int trigPin = 5;
int echoPin = 7;
int pirPin = 6;

String incomingBuffer = "";

float lastTemp = 0;
float lastHumidity = 0;
bool pirState = false;

void setup() {
  Serial.begin(9600);
  BT.begin(9600);
  dht.begin();

  lcd.init();
  lcd.noBacklight();
  lcd.clear();

  for (int i = 0; i < 4; i++) {
    lcdCache[i] = "";
  }

  for (int i = 0; i < NUM_RELAYS; i++) {
    pinMode(i + 2, OUTPUT);
    digitalWrite(i + 2, RELAY_OFF);
  }

  pinMode(trigPin, OUTPUT);
  pinMode(echoPin, INPUT);
  pinMode(pirPin, INPUT);
}

void loop() {
  handleIncomingBT();

  unsigned long now = millis();

  updatePIR(now);
  updateDHT(now);

  if (now - lastSend > SEND_INTERVAL) {
    lastSend = now;
    handleDoor();
    handleTemp();
  }
}

void handleDoor() {
  long distance = getCm();
  if (distance == -1) return;

  if (doorStream) {
    String msg = "0;";
    msg += distance;
    msg += ";";
    msg += (pirState ? "true" : "false");
    BT.println(msg);
  } else {
    if (distance < DIST_THRESHOLD && pirState) {
      BT.println("DOOR_TRIGGERED");
    }
  }
}

void handleTemp() {
  if (!tempStream) return;

  String msg = "1;";
  msg += lastTemp;
  msg += ";";
  msg += lastHumidity;

  BT.println(msg);
}

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

void processMessage(String msg) {
  msg.trim();

  if (msg.length() == 1 && isDigit(msg[0])) {
    int val = msg[0] - '0';

    if (val == CMD_LCD_TOGGLE) {
      lcdOn = !lcdOn;
      if (lcdOn) {
        lcd.backlight();
        refreshLCD();
      } else {
        lcd.noBacklight();
      }
    }
    else if (val == CMD_TEMP_STREAM) {
      tempStream = !tempStream;
    }
    else if (val == CMD_DOOR_STREAM) {
      doorStream = !doorStream;
    }
    else if (val < NUM_RELAYS) {
      relayState[val] = !relayState[val];
      digitalWrite(val + 2, relayState[val] ? RELAY_ON : RELAY_OFF);
    }

    return;
  }

  int first = msg.indexOf(';');
  int second = msg.indexOf(';', first + 1);
  int third = msg.indexOf(';', second + 1);

  if (first == -1 || second == -1 || third == -1) return;

  int row1 = msg.substring(0, first).toInt();
  String data1 = msg.substring(first + 1, second);

  int row2 = msg.substring(second + 1, third).toInt();
  String data2 = msg.substring(third + 1);

  displayASCII(row1, data1);
  displayASCII(row2, data2);
}

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

    if (numStr.length() > 0) {
      char c = (char) numStr.toInt();
      text += c;
    }

    if (underscore == -1) break;
    start = underscore + 1;
  }

  lcdCache[row] = text;

  lcd.print("                    ");
  lcd.setCursor(0, row);
  lcd.print(text);
}

void refreshLCD() {
  lcd.clear();
  for (int i = 0; i < 4; i++) {
    lcd.setCursor(0, i);
    lcd.print(lcdCache[i]);
  }
}

void updatePIR(unsigned long now) {
  bool current = digitalRead(pirPin);

  if (current && (now - lastPIRTime > PIR_DEBOUNCE)) {
    pirState = true;
    lastPIRTime = now;
  } else if (!current) {
    pirState = false;
  }
}

void updateDHT(unsigned long now) {
  if (now - lastDHTRead < DHT_INTERVAL) return;

  lastDHTRead = now;

  float t = dht.readTemperature();
  float h = dht.readHumidity();

  if (!isnan(t) && !isnan(h)) {
    lastTemp = t;
    lastHumidity = h;
  }
}

long getCm() {
  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);

  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);

  long duration = pulseIn(echoPin, HIGH, 20000);

  if (duration == 0) return -1;

  return duration * 0.034 / 2;
}
