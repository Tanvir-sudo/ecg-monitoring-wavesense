import processing.serial.*;
import ddf.minim.*;
import java.io.PrintWriter;

// Serial Settings
String portName = "COM3"; // Update to your Arduino's COM port
Serial myPort;

// ECG Data Buffers
float[] ecgBuffer;
int bufferSize = 600;
int index = 0;

// Beat Detection Variables
float threshold = 600;
boolean peakDetected = false;
int lastPeakTime = 0;
float BPM = 0;
int validBeats = 0;
int lastBeatDetectedTime = 0;
int[] bpmBuffer = new int[10]; // Buffer for averaging BPM
int bpmBufferIndex = 0;

// Lead-Off Detection
boolean leadOff = false;

// UI Elements
boolean readingEnabled = true;
boolean loggingEnabled = true;

// Sound
Minim minim;
AudioPlayer beepPlayer;
AudioPlayer readingStartPlayer;
AudioPlayer readingStopPlayer;

// Data Logging
PrintWriter output;
String logFileName = "ecg_data.csv";

// UI Element Positions
float sliderX, sliderY, sliderWidth = 300, sliderHeight = 10;
boolean sliderDragging = false;

float buttonW = 150, buttonH = 50, buttonRound = 15;
float loggingButtonX, loggingButtonY;
float readingButtonX, readingButtonY;

// Heartbeat Indicator
boolean showBeat = false;
int beatIndicatorTimer = 0;

// Custom Fonts
PFont titleFont;
PFont regularFont;

void settings() {
  fullScreen(P2D);
}

void setup() {
  minim = new Minim(this);
  beepPlayer = minim.loadFile("beep.wav");
  readingStartPlayer = minim.loadFile("readingStart.wav");
  readingStopPlayer = minim.loadFile("readingStop.wav");

  ecgBuffer = new float[bufferSize];

  // Open serial port
  myPort = new Serial(this, portName, 115200);
  myPort.bufferUntil('\n');

  // Open logging file
  if (loggingEnabled) {
    output = createWriter(logFileName);
    output.println("Time(ms),ECGValue,FilteredECG,BPM,LeadOff,ValidBeats");
  }

  // Position UI elements
  sliderX = width / 2 - sliderWidth / 2;
  sliderY = height - 80;
  loggingButtonX = 20;
  loggingButtonY = 20;
  readingButtonX = loggingButtonX + buttonW + 20;
  readingButtonY = loggingButtonY;

  // Load fonts
  titleFont = createFont("Arial-Bold", 32);
  regularFont = createFont("Arial", 16);

  background(0);
}

void draw() {
  drawBackgroundGradient();

  // Title
  textFont(titleFont);
  fill(255);
  textAlign(CENTER, TOP);
  text("ECG Visualizer", width / 2, 10);

  // ECG Waveform Panel
  fill(0, 0, 0, 120);
  rect(0, 50, width, height * 0.5 - 50);

  if (readingEnabled) {
    drawECGWaveform();
  } else {
    fill(255, 200, 0);
    textAlign(CENTER, CENTER);
    textSize(20);
    text("Reading Paused", width / 2, height * 0.25);
  }

  // BPM Display
  textFont(regularFont);
  fill(255);
  textAlign(LEFT, TOP);
  textSize(16);
  text("BPM: " + (BPM > 0 ? nf(BPM, 1, 2) : "--"), 20, height * 0.55f);
  text("Valid Beats: " + validBeats, 20, height * 0.55f + 20);

  // Threshold Value Display
  fill(255);
  text("Threshold: " + int(threshold), sliderX + sliderWidth + 20, sliderY - 10);

  // Lead-Off Warning
  if (leadOff && readingEnabled) {
    fill(255, 0, 0);
    textSize(18);
    text("Lead Off Detected! Please check electrodes.", 20, height * 0.55f + 40);
  }

  // Heartbeat Indicator
  if (showBeat && readingEnabled) {
    fill(255, 0, 0);
    ellipse(width - 50, 50, 20, 20);
  }

  // Draw UI
  drawSlider();
  drawLoggingButton();
  drawReadingButton();

  // Reset Beat Indicator
  if (millis() - beatIndicatorTimer > 100) {
    showBeat = false;
  }

  // Reset BPM if no beats detected for 3 seconds
  if (millis() - lastBeatDetectedTime > 3000) {
    BPM = 0;
    validBeats = 0;
  }
}

void drawBackgroundGradient() {
  noFill();
  for (int i = 0; i < height; i++) {
    float inter = map(i, 0, height, 0, 1);
    int c = lerpColor(color(25, 35, 45), color(5, 10, 20), inter);
    stroke(c);
    line(0, i, width, i);
  }
}

void drawECGWaveform() {
  stroke(0, 255, 0);
  noFill();
  beginShape();
  for (int i = 0; i < bufferSize; i++) {
    float y = map(ecgBuffer[i], 0, 1023, height * 0.5f, 50);
    vertex(i * (width / (float) bufferSize), y);
  }
  endShape();
}

void drawSlider() {
  float handleX = sliderX + map(threshold, 0, 1023, 0, sliderWidth);
  stroke(200);
  line(sliderX, sliderY, sliderX + sliderWidth, sliderY);
  fill(sliderDragging ? color(255, 200, 0) : color(220, 180, 0));
  ellipse(handleX, sliderY, 20, 20);
}

void drawLoggingButton() {
  fill(loggingEnabled ? color(0, 255, 0) : color(255, 0, 0));
  rect(loggingButtonX, loggingButtonY, buttonW, buttonH, buttonRound);
  fill(0);
  textAlign(CENTER, CENTER);
  textSize(14);
  text(loggingEnabled ? "Logging ON" : "Logging OFF", loggingButtonX + buttonW / 2, loggingButtonY + buttonH / 2);
}

void drawReadingButton() {
  fill(readingEnabled ? color(0, 0, 255) : color(255, 165, 0));
  rect(readingButtonX, readingButtonY, buttonW, buttonH, buttonRound);
  fill(0);
  textAlign(CENTER, CENTER);
  textSize(14);
  text(readingEnabled ? "Reading ON" : "Reading OFF", readingButtonX + buttonW / 2, readingButtonY + buttonH / 2);
}

void mousePressed() {
  if (mouseX > sliderX && mouseX < sliderX + sliderWidth && mouseY > sliderY - 10 && mouseY < sliderY + 20) {
    sliderDragging = true;
  } else if (mouseX > loggingButtonX && mouseX < loggingButtonX + buttonW && mouseY > loggingButtonY && mouseY < loggingButtonY + buttonH) {
    loggingEnabled = !loggingEnabled;
    if (loggingEnabled && output == null) {
      output = createWriter(logFileName);
      output.println("Time(ms),ECGValue,FilteredECG,BPM,LeadOff,ValidBeats");
    } else if (!loggingEnabled && output != null) {
      output.flush();
      output.close();
      output = null;
    }
  } else if (mouseX > readingButtonX && mouseX < readingButtonX + buttonW && mouseY > readingButtonY && mouseY < readingButtonY + buttonH) {
    toggleReading();
  }
}

void mouseDragged() {
  if (sliderDragging) {
    threshold = map(mouseX, sliderX, sliderX + sliderWidth, 0, 1023);
    threshold = constrain(threshold, 0, 1023);
  }
}

void mouseReleased() {
  sliderDragging = false;
}

void toggleReading() {
  readingEnabled = !readingEnabled;
  if (readingEnabled) {
    readingStartPlayer.rewind();
    readingStartPlayer.play();
  } else {
    readingStopPlayer.rewind();
    readingStopPlayer.play();
    BPM = 0; // Reset BPM
    beepPlayer.pause(); // Stop beep sound
    showBeat = false; // Reset heartbeat indicator
  }
}

void serialEvent(Serial p) {
  if (!readingEnabled) return; // Ignore serial data if reading is disabled

  String inData = p.readStringUntil('\n');
  if (inData != null) {
    if (inData.equals("Lead Off")) {
      leadOff = true;
    } else {
      leadOff = false;
      String[] vals = split(trim(inData), ',');
      if (vals.length == 3) {
        int ecgVal = int(vals[0]);
        ecgBuffer[index] = ecgVal;
        index = (index + 1) % bufferSize;
        detectBeat(ecgVal);
      }
    }
  }
}

void detectBeat(float val) {
  if (val > threshold && !peakDetected) {
    peakDetected = true;
    int currentTime = millis();
    if (lastPeakTime > 0) {
      float diff = currentTime - lastPeakTime;

      // Filter out invalid BPM values
      float currentBPM = 60000.0 / diff;
      if (currentBPM >= 40 && currentBPM <= 180) {
        bpmBuffer[bpmBufferIndex] = (int) currentBPM;
        bpmBufferIndex = (bpmBufferIndex + 1) % bpmBuffer.length;
        BPM = averageBPM();
        validBeats++;
        lastBeatDetectedTime = millis();
      }
    }
    lastPeakTime = currentTime;
    showBeat = true;
    beatIndicatorTimer = millis();
    if (!beepPlayer.isPlaying()) {
      beepPlayer.rewind();
      beepPlayer.play();
    }
  }

  if (val < threshold - 50) {
    peakDetected = false;
  }
}

float averageBPM() {
  int sum = 0;
  int count = 0;
  for (int i = 0; i < bpmBuffer.length; i++) {
    if (bpmBuffer[i] > 0) {
      sum += bpmBuffer[i];
      count++;
    }
  }
  return count > 0 ? sum / (float) count : 0;
}
