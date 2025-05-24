#include <WiFi.h>
#include <WebSocketsServer.h>

// WiFi Access Point credentials
const char* ssid = "ESP32_Game";
const char* password = "12345678";

// WebSocket server on port 8888
WebSocketsServer webSocket = WebSocketsServer(8888);

// Flex sensor analog input pins
const int flexPins[5] = {36, 39, 34, 35, 32};
int flexValues[5];
int mapped[5];

// Vibration motor digital output pins
const int motorPins[5] = {4, 19,22,23,21};
bool motorStates[5] = {false, false, false, false, false};
unsigned long motorStartTime[5] = {0, 0, 0, 0, 0};

const int VIBRATION_DURATION = 500;  // ms
const unsigned long sendInterval = 100;  // ms
unsigned long lastSentTime = 0;

// DC Motor control pins
const int EN = 25;
const int IN1 = 26;
const int IN2 = 27;

void setup() {
  Serial.begin(115200);

  // Set up WiFi Access Point
  WiFi.softAP(ssid, password);
  Serial.println("WiFi Access Point Started");
  Serial.print("IP Address: ");
  Serial.println(WiFi.softAPIP());

  // Initialize WebSocket
  webSocket.begin();
  webSocket.onEvent(webSocketEvent);

  // Set up vibration motor pins
  for (int i = 0; i < 5; i++) {
    pinMode(motorPins[i], OUTPUT);
    digitalWrite(motorPins[i], LOW);
    motorStates[i] = false;
  }

  // Set up DC motor control pins
  pinMode(EN, OUTPUT);
  pinMode(IN1, OUTPUT);
  pinMode(IN2, OUTPUT);
  digitalWrite(EN, LOW);  // Motor off
  digitalWrite(IN1, LOW);
  digitalWrite(IN2, LOW);
}

void loop() {
  webSocket.loop();

  // Send sensor data every 100ms
  if (millis() - lastSentTime >= sendInterval) {
    readFlexSensors();
    sendFlexData();
    printStatusToSerial();
    lastSentTime = millis();
  }

  // Handle vibration motor timeouts
  for (int i = 0; i < 5; i++) {
    if (motorStates[i] && millis() - motorStartTime[i] >= VIBRATION_DURATION) {
      digitalWrite(motorPins[i], LOW);
      motorStates[i] = false;
    }
  }
}

void readFlexSensors() {
  for (int i = 0; i < 5; i++) {
    int raw = analogRead(flexPins[i]);
    mapped[i] = map(raw, 0, 4095, 0, 1000);
    flexValues[i] = mapped[i];
  }
}

void sendFlexData() {
  String message = "FLEX:";
  for (int i = 0; i < 5; i++) {
    message += String(flexValues[i]);
    if (i < 4) message += " ";
  }
  webSocket.broadcastTXT(message);
}

void printStatusToSerial() {
  Serial.print("Flex Values => ");
  for (int i = 0; i < 5; i++) {
    Serial.print("F" + String(i + 1) + ": " + String(flexValues[i]) + " ");
  }
  Serial.println();

  Serial.print("Motor States => ");
  for (int i = 0; i < 5; i++) {
    Serial.print("M" + String(i + 1) + ": ");
    Serial.print(motorStates[i] ? "1" : "0");
    Serial.print(" ");
  }
  Serial.println("\n");
}

void webSocketEvent(uint8_t client, WStype_t type, uint8_t * payload, size_t length) {
  if (type == WStype_TEXT) {
    String msg = String((char *)payload);
    Serial.println("Received: " + msg);

    if (msg.startsWith("VIBRATE:")) {
      int index = msg.substring(8).toInt();
      if (index >= 0 && index < 5) {
        triggerVibration(index);
        Serial.println("🔔 Vibration triggered for motor " + String(index));

        // Trigger DC motor only when second vibration motor (index 1) is triggered
        if (index == 1) {
          runDCMotorSequence();
        }
      }
    } else if (msg == "GAME_OVER") {
      for (int i = 0; i < 5; i++) {
        digitalWrite(motorPins[i], LOW);
        motorStates[i] = false;
      }
    } else if (msg.startsWith("REMOVE:")) {
      int index = msg.substring(7).toInt();
      if (index >= 0 && index < 5) {
        digitalWrite(motorPins[index], LOW);
        motorStates[index] = false;
      }
    }
  }
}

void triggerVibration(int index) {
  delay(3000);
  digitalWrite(motorPins[index], HIGH);
  motorStates[index] = true;
  motorStartTime[index] = millis();
}

// DC motor ON full power in both directions, no speed control
void runDCMotorSequence() {
  // Anticlockwise
  digitalWrite(IN1, LOW);
  digitalWrite(IN2, HIGH);
  digitalWrite(EN, HIGH);
  Serial.println("DC Motor rotating ANTICLOCKWISE (full speed)");
  delay(1000);
  // Clockwise
  digitalWrite(IN1, HIGH);
  digitalWrite(IN2, LOW);
  digitalWrite(EN, HIGH);
  Serial.println("DC Motor rotating CLOCKWISE (full speed)");
  delay(1000);

  // Stop
  digitalWrite(IN1, LOW);
  digitalWrite(IN2, LOW);
  digitalWrite(EN, LOW);
  Serial.println("DC Motor stopped");
}
