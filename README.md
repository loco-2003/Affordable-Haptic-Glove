# Affordable Haptic Glove for Stroke Rehabilitation

This repository details a low-cost, wearable haptic glove system using ESP32, flex sensors, vibration motors, and a Flutter-based game interface. Designed for stroke rehabilitation, it encourages therapeutic finger movements through interactive gameplay.

---

## System Overview

- **Detection**: Flex sensors on fingers capture movement.
- **Feedback**: Vibration motors provide haptic cues.
- **Controller**: ESP32 processes sensor data and controls feedback.
- **Communication**: Mobile app connects over Wi-Fi using WebSockets for real-time interaction.

---

## Hardware Components

- **ESP32 Microcontroller**: Dual-core MCU with Wi-Fi/Bluetooth.
- **Flex Sensors**: Analog input for each finger.
- **Vibration Motors**: Haptic feedback via digital pins.
- **Transistors/Diodes**: Motor control and circuit protection.
- **Buck Converter**: Safe voltage supply.
- **Power**: 9V battery or USB.

---


## Software Architecture & Benefits

### ESP32 Firmware
- Arduino-based; reads flex sensors, sends data & controls vibration motors via WebSocket.

### Flutter App
- Connects to ESP32 over Wi-Fi.
- Runs finger reaction game, logs movements, reaction times, and sessions.
- Shows progress with graphs and stats (Hive database).

### Communication
- WebSocket ensures real-time, low-latency, reliable data exchange.

### Game & Tracking
- Players respond to finger cues; game actions vibrate the finger.
- Logs accuracy, reaction times, and session stats.
- Progress graphs help therapists track recovery.

### Patient Benefits
- Fun, interactive rehab at home.
- Instant tactile feedback.
- Open-source, affordable, and data-driven progress tracking.

---

## Cost Comparison

| Feature                | Commercial Gloves     | This Project            |
|------------------------|----------------------|-------------------------|
| Price                  | ₹25,000 – ₹1,00,000+ | Under ₹1,000            |
| Design                 | Bulky/proprietary    | Lightweight/modular     |
| Availability           | Clinics only         | Home use                |
| Feedback               | Force feedback       | Vibration motors        |
| App                    | Closed-source        | Open-source Flutter     |

---

## Setup Instructions

### ESP32 Firmware

1. Open `ESP32_Code/haptic_glove.ino` in Arduino IDE.
2. Install libraries: `WiFi.h`, `WebSocketsServer.h`.
3. Upload code to ESP32.
4. Join `ESP32_Game` Wi-Fi network.

### Flutter App

1. Install Flutter SDK.
2. In `Flutter_App/`, run:
    ```bash
    flutter pub get
    flutter run
    ```

---

## References

- Dahiya, R. S., Valle, M. (2012). *Robotic Tactile Sensing*.
- He, J., et al. (2017). *Haptic feedback for rehabilitation*.
- Lane, J. C., et al. (2018). *Low-cost glove for stroke rehabilitation*.
- Espressif Systems. *ESP32 Technical Reference Manual*.
- TensorFlow Lite for Microcontrollers.

---

## Project Team

- Abraham Jeyakumar
- Aravind Sunil
- Jostin Jaison
- Keerthana N

**Guide**: Prof. Sindhu Krishnan  
**Dept**: Electronics & Communication Engg  
**Institution**: NSS College of Engineering, Palakkad

---

## License

For educational use. Credit original authors when adapting.
