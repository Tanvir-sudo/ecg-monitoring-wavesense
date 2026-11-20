// Arduino code to read ECG from AD8232 and send to Serial
// Wiring:
// AD8232 Output -> A0
// AD8232 LO+ -> D10
// AD8232 LO- -> D11
// AD8232 GND -> GND
// AD8232 3.3V -> 3.3V
// AD8232 SDN -> GND (continuous operation)

int ECG_PIN = A0;
int LO_PLUS_PIN = 10;
int LO_MINUS_PIN = 11;

void setup() {
  Serial.begin(115200);
  pinMode(ECG_PIN, INPUT);
  pinMode(LO_PLUS_PIN, INPUT);
  pinMode(LO_MINUS_PIN, INPUT);
}

void loop() {
  int ecgValue = analogRead(ECG_PIN);
  int loPlus = digitalRead(LO_PLUS_PIN);
  int loMinus = digitalRead(LO_MINUS_PIN);

  // Send data in CSV format: ECGValue,LOPlus,LOMinus
  Serial.print(ecgValue);
  Serial.print(",");
  Serial.print(loPlus);
  Serial.print(",");
  Serial.println(loMinus);

  delay(70); // ~14 samples per second (reduce the delay for a higher sampling rate)
}



