# WaveSense: Low-Cost Real-Time ECG Monitoring

A low-cost ECG monitor built with an Arduino UNO and an AD8232 heart-rate sensor. The Arduino streams the signal over serial, and a sketch in the Processing IDE (Java-based) plots the waveform live, estimates heart rate, warns when an electrode comes off, and logs readings to CSV.

Embedded SW and IoT course project, Woosong University, December 2024.

## Features

- Real-time ECG waveform display
- Threshold-based R-peak detection with heart rate (BPM) averaged over the last 10 beats; the threshold is adjustable with an on-screen slider
- Lead-off detection with an on-screen warning
- Audio beep on each detected beat, plus start/stop sounds
- CSV logging (`time, raw ECG, filtered ECG, BPM, lead-off, valid beats`) with an on/off button

## Hardware

| Part | Connection |
|---|---|
| Arduino UNO | USB to PC |
| AD8232 OUTPUT | A0 |
| AD8232 LO+ / LO- | D10 / D11 |
| AD8232 3.3V / GND | 3.3V / GND |
| AD8232 SDN | GND (continuous operation) |
| 3 electrodes | AD8232 sensor cable |

## Running

1. Upload `arduino/ECG_Arduino/ECG_Arduino.ino` with the Arduino IDE (baud rate 115200).
2. Install [Processing](https://processing.org/) and the **Minim** library (Sketch > Import Library > Manage Libraries).
3. Open `processing/ECG_Processing/ECG_Processing.pde`, set `portName` to your Arduino port (for example `COM3` or `/dev/ttyUSB0`), and run.

Slides: [docs/WaveSense_presentation.pdf](docs/WaveSense_presentation.pdf)

## Note

This is an educational prototype, not a medical device.

## Team WaveSense

Harishik Dev Singh Jamwal, Cinmoy Purkaystha, Kakon Chakrabarty, Tanvir Ahamed
