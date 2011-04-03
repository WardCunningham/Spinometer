
// Spinometer -- Adaptive cycle training meter
// (c) 2008 Ward Cunningham

class Meter {
  int pin;
  float scale;
  float state;

  public:  
  Meter (int p, float s) : pin(p), scale(s) {}
  
  void set (float value) {
    state = .99 * state + .01 * value;
    int pwm = state * 230 / scale;      // scale to meter full-scale volts
    analogWrite(pin, pwm);
  }
};

Meter thresholdMeter (10, 1024);
Meter contrastMeter (9, 250);
Meter sprintMeter (6, 300000);
Meter speedMeter (5, 50);
Meter rotationMeter (3, 3);

void setup () {
  pinMode(6,OUTPUT);
  digitalWrite(6,LOW);
  pinMode(12,OUTPUT);
  Serial.begin(9600);
}

int contrast = 0;
long delta;
int cycles = 0;

void loop () {
  trigger();
  beep();
}

void trigger () {
  static float threshold = 150.0;
  static float level = 150.0;
  static int min_level, max_level;
  static boolean prev = false;
  static long last = 0;

  int sig = analogRead(1);
  //int sig = millis()/(millis()/5000%2? 20:30)%2 ? 100 : 200;  // input simulator

  threshold = 0.9999 * threshold + 0.0001 * sig;
  thresholdMeter.set(threshold);

  level = 0.9 * level + 0.1 * sig;
  int i = level;
  if (i<min_level) min_level=i;
  if (i>max_level) max_level=i;
  contrast = max_level - min_level;
  contrastMeter.set(contrast);

  boolean curr = level > threshold;
  digitalWrite(13, curr);

  delta = millis() - last;

  if (delta > 1000 || (curr != prev && delta > 10)) {
    prev = curr;
    if (curr) {
      last = millis();
      measure();
      max_level = level;
    } 
    else {
      min_level = level;
    }
  }
}

void measure() {
  static long sprint = 0;
  static long minute = 0;
  static float speed;
  static float avg_delta = 30;
  static float rotation = 0;
  if (contrast > 8) {
    speed = 840.909090 / delta;
    avg_delta = avg_delta * 0.9 + delta * 0.1;
    float min_delta = delta < avg_delta ? delta : avg_delta;
    float max_delta = delta > avg_delta ? delta : avg_delta;
    rotation = rotation * 0.9 + (max_delta - min_delta) * 0.1;
  } 
  else {
    Serial.println(contrast, DEC);
    sprint = millis();
    minute = millis()+30000L;
    speed = 0;
    rotation = 0;
  }
  sprintMeter.set((millis()-sprint)%300000);
  speedMeter.set(speed);
  rotationMeter.set(3 - rotation);
  if (millis()>minute) {
    cycles = 150;
    minute = millis()+30000L;
  }
}

void beep () {
  static boolean toggle = LOW;
  if (cycles>0) {
    toggle = !toggle;
    digitalWrite(12, toggle); 
    cycles--;
  } 
}
