# Affordable Haptic Glove for Stroke Rehabilitation

This repository contains the design and implementation of a low-cost, wearable haptic glove system developed using ESP32, flex sensors, vibration motors, and a Flutter-based game interface. The system is intended to support stroke rehabilitation by encouraging patients to perform therapeutic finger movements through an interactive game environment.

---

## Repository Structure


---

## System Overview

The haptic glove is designed to detect finger movements using flex sensors and provide real-time haptic feedback using vibration motors. The ESP32 microcontroller collects sensor data and communicates with a mobile application over Wi-Fi using WebSockets. The mobile application presents a game-based interface to motivate consistent therapy and monitor patient progress.

---

## Hardware Components

### 1. ESP32 Microcontroller
- Dual-core microcontroller with built-in Wi-Fi and Bluetooth.
- Acts as the central unit for processing flex sensor input and controlling vibration feedback.
- Enables wireless communication with the mobile application.

### 2. Flex Sensors
- Placed on fingers to detect bending movements.
- Output is an analog signal proportional to the bending angle.
- Data is digitized using the ESP32's ADC channels.

### 3. Vibration Motors
- Provide haptic feedback corresponding to user actions.
- Controlled via digital output pins using transistors for switching.

### 4. Transistors and Diodes
- Transistors act as electronic switches to control motors.
- Diodes protect the circuit from voltage spikes (back EMF).

### 5. Buck Converter
- Reduces the battery voltage to a level safe for the ESP32 and other components.

### 6. Power Supply
- Powered by a 9V battery or USB connection for portability.

---

## Software Architecture

### ESP32 Firmware
- Developed using Arduino IDE.
- Captures analog input from flex sensors.
- Maps values to finger motion data and sends via WebSocket to the mobile app.
- Activates vibration motors as required.

### Mobile Application (Flutter)
- Connects to ESP32 via WebSocket (using the ESP32-created Wi-Fi AP).
- Displays a finger-based reaction game.
- Logs sensor data, reaction times, and therapy sessions.
- Analyzes patient progress through visual graphs and statistics.

---

## Communication Protocol: WebSockets

WebSocket is used for continuous two-way communication between the ESP32 and the Flutter app. This ensures:
- Low-latency data transmission
- Real-time feedback and interaction
- Reliable communication over Wi-Fi (ESP32 as Access Point)

---

## Game Mechanics and Patient Interaction

- A game interface presents falling colored blocks, each representing a finger.
- When a block appears, the corresponding vibration motor is triggered.
- The patient must bend the appropriate finger to "remove" the block.
- Correct movements are logged; delayed or missed responses increase accumulated blocks.
- The game ends if too many blocks accumulate.

---

## Data Analysis and Recovery Tracking

- Finger movements and reaction times are recorded.
- Session data is stored locally using the Hive database.
- The application includes:
  - Reaction time graphs per finger
  - Usage statistics
  - Progress tracking across sessions
- This data can assist therapists in evaluating motor recovery over time.

---

## Benefits for Stroke Patients

- Encourages motor re-learning through repetitive, interactive movements.
- Provides instant tactile feedback to reinforce correct gestures.
- Allows therapy to continue at home with minimal supervision.
- Reduces dependence on hospital-based rehabilitation setups.
- Tracks quantitative improvements, enabling data-driven therapy.

---

## Cost Comparison and Affordability

| Feature                       | Commercial Haptic Gloves          | Proposed System                |
|------------------------------|----------------------------------|-------------------------------|
| Approximate Cost             | ₹25,000 – ₹1,00,000+              | Under ₹1,000                  |
| Design                       | Bulky, proprietary                | Lightweight, modular          |
| Availability                 | Limited to clinics                | Usable at home                |
| Feedback Mechanism           | Complex force feedback            | Simple vibration motors       |
| Application Software         | Closed-source                     | Open-source Flutter application |

The use of off-the-shelf components and open-source platforms ensures that the glove can be built and used affordably by rehabilitation centers, students, or hobbyists.

---

## Setup Instructions

### ESP32 Firmware

1. Open `ESP32_Code/haptic_glove.ino` in Arduino IDE.
2. Install required libraries: `WiFi.h`, `WebSocketsServer.h`.
3. Upload the code to the ESP32.
4. Connect to the Wi-Fi network `ESP32_Game` created by the ESP32.

### Flutter Application

1. Ensure Flutter SDK is installed.
2. Navigate to the `Flutter_App/` directory.
3. Run the following commands:

```bash
flutter pub get
flutter run
