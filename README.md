# Affordable Haptic Glove for Stroke Rehabilitation

This repository presents a cost-efficient, wearable neurorehabilitation system integrating **ESP32 (Xtensa LX6 dual-core SoC)**, **flex resistive sensors**, **ERM vibration actuators**, and a **Flutter (Dart) UI layer**. The glove supports **gesture-based therapy** using embedded sensing, real-time haptics, and edge-device analytics for post-stroke hand function recovery.

---

## 🧠 System Architecture

The system uses **ESP32 in SoftAP mode** to form a standalone Wi-Fi network, streams **ADC-acquired flex sensor data**, and processes motor control via **PWM-regulated GPIOs**. A **Flutter mobile client** interfaces over **full-duplex WebSocket**, displaying an interactive neuro-motor training game while logging kinematic metrics locally using **Hive DB**.

---

## 🔩 Hardware Components

- **ESP32-WROOM-32 (Arduino)** – Dual-core MCU with integrated TCP/IP stack, ADC (12-bit), and PWM timers.
- **Flex Sensors** – Variable resistors modeled as voltage dividers for finger-angle estimation.
- **Vibration Motors (ERM)** – PWM-driven via NPN transistor switches; feedback for motor cortex activation.
- **2N2222/BC547 + Flyback Diodes** – Ensure safe inductive switching under motor load.
- **LM2596 Buck Converter** – Regulates 9V input down to 3.3V logic-compatible rails.
- **9V Battery/USB** – Mobile power for untethered use.

---

## 📱 Software Architecture

### Embedded Firmware (ESP32 / Arduino C)
- Initializes SoftAP using `WiFi.softAP()`
- Reads flex sensor voltages on ADC1/ADC2 channels.
- Maps analog input to calibrated bend ranges.
- Manages ERM motors using `analogWrite()` for PWM modulation.
- Implements non-blocking WebSocket I/O via `WebSocketsServer`.

### Flutter App (Dart)
- Connects to ESP32's Wi-Fi AP using `dart:io`.
- WebSocket client for real-time data ingestion and actuation.
- Gesture recognition mapped to a **reaction-based game UI**.
- Stores time-series data (sensor + user response) via **Hive (NoSQL, local-first)**.
- Provides in-app telemetry with `charts_flutter`.

---

## 🔁 Communication Protocol

- Uses **WebSocket over TCP/IP** for persistent, bidirectional transport.
- Low-latency, full-duplex socket enables sensor-actuator loop closure <50ms.
- Avoids BLE pairing complexity by leveraging ESP32 SoftAP and local IP (192.168.4.1).

---

## 🎮 Gameplay-Driven Therapy

- UI simulates finger-specific visual cues (colored stimuli).
- Corresponding vibration motor triggers as haptic prompt.
- Patient bends the correct finger; ADC input validates response.
- Latency and accuracy metrics collected for each session.
- Game difficulty dynamically adjusts to motion fidelity.

---

## 📊 Rehab Analytics

- Each session logs:
  - Per-finger bend range
  - Response latency
  - Missed/incorrect gestures
- Data persisted using Hive’s key-value object boxes.
- Enables offline rehab tracking without cloud integration.
- Visual analytics include:
  - Reaction time histograms
  - Finger-wise performance heatmaps
  - Weekly recovery deltas

---

## 🩺 Clinical Relevance

- Aims to stimulate **neuroplasticity** through high-repetition, gamified exercises.
- Optimized for **home therapy** in post-stroke patients with limited access to in-clinic rehab.
- Supports **low-cost deployment** using open hardware + software (₹<1000 per unit).
- Promotes use in **physiotherapy labs**, **rural rehab camps**, and **assistive tech R&D**.

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
## 🛠 Setup Instructions

### ESP32 Firmware

1. Open `ESP32_Code/haptic_glove.ino` in **Arduino IDE**
2. Install dependencies: `WebSocketsServer`, `WiFi`.
3. Connect ESP32 over USB, select correct COM port.
4. Upload firmware and monitor via serial.

### Flutter App

```bash
cd Flutter_App
flutter pub get
flutter run
```
Connect to `ESP32_Game` Wi-Fi → Navigate to `192.168.4.1`

---

## 👨‍🔬 References

- Espressif: *ESP32 Technical Reference Manual*  
- JNER: *Gamified Rehab Post-Stroke – 2017*  
- Springer: *Tactile Sensing Technologies*  
- IEEE Access: *Low-cost Smart Wearables for Neuro Recovery*  
- TensorFlow Micro: *On-device ML for Motor Control*

---

## 👥 Authors & Contributors

- Abraham Jeyakumar  
- Aravind Sunil  
- Jostin Jaison  
- Keerthana N  

**Guide**: Prof. Sindhu Krishnan  
**Dept**: ECE, NSS College of Engineering, Palakkad

---

## 📄 License

© 2024. For research and academic purposes only.  
Redistribution or reuse requires attribution and prior approval from the authors.
