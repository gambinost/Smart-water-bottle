#include <Arduino.h>
#include <DHT.h> 
#include <Wire.h>
#include <SPI.h>
#include <Wire.h>
#include <WiFiClientSecure.h>
#include <PubSubClient.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

#define ssid "Nabil"
#define wifi_pass "Juju@12345"

#define ir_pin 35
#define heartrate_pin 34
#define relay 2
#define buzzer 4
#define button 12

#define DHTTYPE DHT11  
#define DHTPIN 14

int width = 128;
int height = 64;
Adafruit_SSD1306 display(width,height,&Wire,-1);
#define oled_address 0x3C

int previousValue = -1;
unsigned long constantDuration = 0;
unsigned long thresholdDuration; // in seconds
const int tolerance = 2; // ±2 range tolerance

float h;
float t;
float f;
float hif;
float hic;

int bpm;
int averageValue;

bool reminder = false;
String mixer_state = "OFF";

int temp_check = 0;
int humid_check = 0;

DHT dht(DHTPIN, DHTTYPE);

WiFiClientSecure wifiClientSecure;
PubSubClient client(wifiClientSecure);

// MQTT Broker settings
const char *broker = "3a88e4f60f124dde87fa46d504b7e065.s1.eu.hivemq.cloud";
const char *brokerUser = "darkooo142@gmail.com";
const char *brokerPass = "Moamen4172";
const int brokerPort = 8883;
const char *topic1 = "flutter/reminder";
const char *topic2 = "flutter/reminder_state";
const char *topic3 = "flutter/mixer";

// function to setup wifi
void setup_wifi() {
    delay(10);
    Serial.println();
    Serial.print("Connecting to ");
    Serial.println(ssid); // print name of wifi 

    WiFi.begin(ssid, wifi_pass); // start connection to the network

    // wait until wifi connection is established 
    while (WiFi.status() != WL_CONNECTED) {
        delay(500);
        Serial.print(".");
    }

    // print connected to wifi when connection succeeds 
    Serial.println("Connected to WiFi");
    Serial.print("IP address: ");
    Serial.println(WiFi.localIP());
}

// function to connect to MQTT
void connect_mqtt() {
    // keep trying until it connects
    while (!client.connected()) {
        Serial.print("Connecting to MQTT...");
        // attempt connection to MQTT with specified user and pass
        if (client.connect("ESP32Client_12345", brokerUser, brokerPass)) {
            Serial.println("connected");
            // subscribe to topics 
            client.subscribe(topic1);
            client.subscribe(topic2);
            client.subscribe(topic3);
        } else {
          // print failed if connection fails 
            Serial.print("failed, rc=");
            Serial.print(client.state());
            Serial.println(" try again in 5 seconds");
            delay(5000);
        }
    }
}


//function to recieve message from subsbcribed topics
void callback(char *topic, byte *payload, unsigned int length) {
  // print the topic the message was sent on
    Serial.print("Message arrived [");
    Serial.print(topic);
    Serial.println("] ");

  // topic 1 is for the reminder time
    if(String(topic) == topic1){
      String minutes = "";
      String seconds = "";
      // message is sent in MM:SS format
      // add first 2 digits to minutes variable 
      for (int i = 0; i <= 1; i++) {
          minutes += (char)payload[i];
      }
      // add last 2 digits to seconds variable (ignore ":")
      for(int j = 3; j<length; j++){
        seconds+=(char)payload[j];
      }

      // print the recived message for debugging purposes 
      Serial.print("Minutes: ");
      Serial.println(minutes);
      Serial.print("Seconds: ");
      Serial.println(seconds);

          // turn reminder to true so that in the actual function, the reminder starts
          // so that when he turns reminder off, the function stops 
          reminder = true;
          
          // add total minutes and seconds to threshold duration
          thresholdDuration = (minutes.toInt()*60 + seconds.toInt()); // multiply minutes by 60 so it's all in seconds
          Serial.print("Duration in seconds: ");
          Serial.println(thresholdDuration);
    }


    // topic 2 is for turing the reminder off 
    if(String(topic) == topic2){
      String message = "";
      for(int i = 0; i<length; i++){
        message+=(char)payload[i];
      }
      // if message sent is OFF, reminder is turned to false 
      if(message == "turned off"){
        reminder = false;
      }
      Serial.print("Reminder State: ");
      Serial.println(message);

    }

    // topic 3 is for turing mixer on 
    if(String(topic) == topic3){   
      mixer_state = "";   

    // put the message recieved in mixer_state variable
      for(int i = 0; i<length; i++){
        mixer_state+=(char)payload[i];
      }
      Serial.print("Mixer State: ");
      Serial.println(mixer_state);
    }
}

void oled_display(int bpm,int temp,int humid, unsigned char logo []){
  display.clearDisplay();
  display.drawBitmap(0, 0, logo, 128, 64, 1);
  display.display();
  delay(2000);

  display.clearDisplay();
  display.setTextSize(1); // Set text size to 1 for the labels
  display.setTextColor(WHITE);

  // Center the labels
  display.setCursor(10, 10);  // Position for "BPM"
  display.print("BPM");

  display.setCursor(50, 10);  // Position for "TEMP"
  display.print("TEMP");

  display.setCursor(90, 10);  // Position for "HUMIDITY"
  display.print("HUMID");

  // Set text size larger for the values
  display.setTextSize(2);

  // Position values below their respective labels
  display.setCursor(10, 30);  // Position for BPM value
  display.print(bpm);

  display.setCursor(50, 30);  // Position for TEMP value
  display.print(temp);

  display.setCursor(90, 30);  // Position for HUMIDITY value
  display.print(humid);

  display.display();
  delay(2000);
}
 unsigned char logo_array [] PROGMEM={
  0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 
	0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 
	0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 
	0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 
	0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 
	0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 
	0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 
	0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 
	0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 
	0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 
	0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 
	0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 
	0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 
	0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 
	0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 
	0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 
	0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 
	0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 
	0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 
	0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 
	0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 
	0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 
	0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 
	0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xf7, 0xff, 0xff, 0xff, 
	0xff, 0xff, 0x05, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x9f, 0xfd, 0xff, 0xff, 0xff, 0x7f, 0xff, 
	0xff, 0xff, 0xf8, 0x01, 0xff, 0xff, 0xff, 0xff, 0xff, 0xfc, 0x3f, 0xff, 0xff, 0xff, 0xff, 0xff, 
	0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 
	0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 
	0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xc0, 0x01, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 
	0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xfe, 0x0f, 0xf8, 0x3f, 0xff, 0xff, 0xf9, 0xff, 0xff, 0xff, 
	0xff, 0xff, 0x1f, 0xff, 0xf7, 0xff, 0xfc, 0x7d, 0x9f, 0x0f, 0xff, 0xe7, 0xff, 0xc4, 0x7f, 0xff, 
	0xff, 0xff, 0x00, 0x0f, 0x1f, 0xff, 0xf1, 0xe0, 0x03, 0xc6, 0xff, 0x3f, 0xff, 0xff, 0xff, 0xff, 
	0xff, 0xff, 0x3f, 0x81, 0xff, 0xff, 0xe3, 0xc0, 0x00, 0xf3, 0xe7, 0xff, 0xff, 0xff, 0xff, 0xff, 
	0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xe7, 0x00, 0x00, 0x79, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 
	0xff, 0xff, 0x83, 0x1f, 0xff, 0xff, 0xce, 0x00, 0x80, 0x39, 0xff, 0xff, 0xfd, 0xff, 0x7f, 0xff, 
	0xff, 0xff, 0x03, 0x8f, 0xff, 0xff, 0xce, 0x00, 0x00, 0x39, 0xff, 0xff, 0xef, 0xff, 0xff, 0xff, 
	0xff, 0xff, 0x00, 0x00, 0x00, 0xff, 0xce, 0x00, 0x00, 0x30, 0x7f, 0xfe, 0x7f, 0xff, 0xff, 0xff, 
	0xff, 0xff, 0xf8, 0x00, 0x1f, 0xff, 0xca, 0x00, 0x00, 0x39, 0xfb, 0xf1, 0xff, 0xff, 0xff, 0xff, 
	0xff, 0xff, 0xff, 0xc1, 0xff, 0xff, 0xcf, 0x00, 0x00, 0x79, 0xf0, 0x0f, 0xff, 0xff, 0xff, 0xff, 
	0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xe7, 0x80, 0x00, 0x73, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 
	0xff, 0xff, 0x7f, 0x7f, 0xff, 0xff, 0xe3, 0xc0, 0x83, 0xf3, 0xff, 0xff, 0xff, 0xf7, 0xff, 0xff, 
	0xff, 0xff, 0x00, 0x40, 0xbf, 0xfd, 0xf9, 0xf8, 0xcf, 0xe7, 0xff, 0xff, 0xfe, 0x7f, 0xff, 0xff, 
	0xff, 0xff, 0x00, 0x00, 0x00, 0x47, 0xfc, 0xf4, 0x8f, 0xce, 0x01, 0xfe, 0x63, 0xff, 0xff, 0xff, 
	0xff, 0xff, 0x00, 0x10, 0x00, 0x7f, 0xfe, 0x7c, 0x19, 0x1f, 0xfe, 0x00, 0x1f, 0xff, 0xff, 0xff, 
	0xff, 0xff, 0x03, 0xff, 0x8f, 0xff, 0xff, 0x3e, 0x01, 0x3f, 0xff, 0xff, 0xfd, 0xff, 0x7f, 0xff, 
	0xff, 0xff, 0xbf, 0x00, 0xff, 0x81, 0x73, 0x9e, 0x0e, 0x7f, 0xf4, 0xff, 0xc0, 0x00, 0x7f, 0xff, 
	0xff, 0xff, 0xf8, 0x00, 0x00, 0x00, 0x00, 0x80, 0x00, 0x4d, 0x73, 0x00, 0x04, 0x00, 0x7f, 0xff, 
	0xff, 0xff, 0x80, 0x00, 0x03, 0xfc, 0x00, 0x00, 0x00, 0x62, 0x00, 0x00, 0x00, 0x00, 0x7f, 0xff, 
	0xff, 0xff, 0x80, 0x00, 0x3f, 0xff, 0xf0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0xfe, 0x7f, 0xff, 
	0xff, 0xff, 0x80, 0x01, 0xff, 0xff, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00, 0x7f, 0xff, 0xff, 0xff, 
	0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xe0, 0x00, 0x7f, 0xff, 0x87, 0xff, 0xfe, 0xff, 0xff, 
	0xff, 0xff, 0xc7, 0xfc, 0x03, 0xff, 0xff, 0xc0, 0x00, 0x7f, 0xff, 0xff, 0x7e, 0x51, 0xff, 0xff, 
	0xff, 0xff, 0xe0, 0x00, 0x00, 0x00, 0x00, 0x40, 0xf3, 0x80, 0x00, 0x00, 0x00, 0x01, 0xff, 0xff, 
	0xff, 0xff, 0xff, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0f, 0xff, 0x83, 0xff, 0xff, 
	0xff, 0xff, 0xff, 0xfe, 0x00, 0x00, 0x00, 0x1e, 0x00, 0x00, 0x01, 0xff, 0xff, 0xff, 0xff, 0xff, 
	0xff, 0xff, 0xfd, 0x3f, 0xe0, 0x00, 0x1f, 0xff, 0xff, 0x00, 0x1f, 0xff, 0xff, 0xff, 0xff, 0xff, 
	0xff, 0xff, 0xfe, 0x00, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xfb, 0xf0, 0x1f, 0xff, 0xff, 
	0xff, 0xff, 0xff, 0x80, 0x07, 0xfe, 0x00, 0x00, 0x03, 0x1f, 0xf0, 0x00, 0x00, 0x7f, 0xff, 0xff, 
	0xff, 0xff, 0xff, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0xff, 0xff, 0xff, 
	0xff, 0xff, 0xff, 0xf8, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x07, 0xff, 0xff, 0xff, 
	0xff, 0xff, 0xff, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x3f, 0xff, 0xff, 0xff, 
	0xff, 0xff, 0xff, 0xff, 0xf0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03, 0xff, 0xff, 0xff, 0xff, 
	0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 
	0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
};  


void readAndDisplayDHTData(DHT& dhtSensor) {
  //Delay for sensor stability
  delay(2000);

  //Reading temperature or humidity takes about 250 milliseconds!
   h = dhtSensor.readHumidity();
  //Read temperature as Celsius (the default)
   t = dhtSensor.readTemperature();
  //Read temperature as Fahrenheit (isFahrenheit = true)
   f = dhtSensor.readTemperature(true);

  
  if (isnan(h) || isnan(t) || isnan(f)) {
    Serial.println(F("Failed to read from DHT sensor!"));
    return;
  }

  //Compute heat index in Fahrenheit (the default)
   hif = dhtSensor.computeHeatIndex(f, h);
  //Compute heat index in Celsius (isFahrenheit = false)
   hic = dhtSensor.computeHeatIndex(t, h, false);


  Serial.print(F("Humidity: "));
  Serial.print(h);
  Serial.print(F("%  Temperature: "));
  Serial.print(t);
  Serial.print(F("°C "));
  Serial.print(f);
  Serial.print(F("°F  Heat index: "));
  Serial.print(hic);
  Serial.print(F("°C "));
  Serial.print(hif);
  Serial.println(F("°F"));

  String temp = String(t);
  String humidity = String(h);
 
 // publish the humidity and temperature to MQTT to display on the flutter app
 client.publish("esp/temperature", temp.c_str());
 client.publish("esp/humidity",humidity.c_str());


    // if temp or humidity is high, send to MQTT to display an alert in the app 
    if(t > 35){
    temp_check++;
    if(temp_check == 1 || temp_check == 20){
    client.publish("esp/temperature/alert", "high");}
    temp_check = (temp_check >=20)? 0 : temp_check;
  }
     if(h>50){
      humid_check++;
      if(humid_check == 1 || humid_check == 20){
      client.publish("esp/humidity/alert", "high");}
      humid_check = (humid_check >= 20) ? 0 : humid_check;
     }
}



void BPM(int pin) {
  const int sampleWindow = 100;  // Sample window width in milliseconds
  static unsigned long previousMillis = 0;

  unsigned long currentMillis = millis();
  int peakToPeak = 0;  // Variable to store peak-to-peak value
  int signalMax = 0;
  int signalMin = 4095; // Setting to max ADC value for ESP32

  if (currentMillis - previousMillis >= sampleWindow) {
    previousMillis = currentMillis;

    // Capture the signal within the sample window
    for (unsigned long startMillis = millis(); millis() - startMillis < sampleWindow;) {
      int sensorValue = analogRead(pin);

      // Track the max and min values to find the peak-to-peak amplitude
      if (sensorValue > signalMax) {
        signalMax = sensorValue;  // Save the max value
      }

      if (sensorValue < signalMin) {
        signalMin = sensorValue;  // Save the min value
      }
    }

    peakToPeak = signalMax - signalMin;  // Calculate peak-to-peak value

      // Map peak-to-peak range to a plausible BPM range
       bpm = map(peakToPeak, 20, 4095, 50, 150); // Adjust the BPM range

  

        // Print only the average heart rate
        Serial.print("Average Heart Rate: ");
        Serial.print(bpm);
        Serial.println(" BPM");

        String str_bpm = String(bpm);
        client.publish("esp/heartbeat", str_bpm.c_str());


        // if BPM is high, send alert to the app through MQTT
        if (bpm >= 100) {
          client.publish("esp/heartbeat/alert", "high"); 
        }

      }
    }



void readAndMapIRSensor(int pin) {
  int totalValue = 0;

  // Take 5 samples
  for (int i = 0; i < 5; i++) {
    int sensorValue = analogRead(pin);
    int mappedValue = map(sensorValue, 0, 4095, 0, 35);
    totalValue += mappedValue;
    // Short delay between readings
  }

  // Calculate the average
   averageValue = totalValue / 5;


  // Print the average value
  Serial.println("Average IR value:");
  Serial.println(averageValue);

  String ir_reading = String(averageValue);
  client.publish("esp/water_level", ir_reading.c_str());

  // Check if the IR value stays within ±2 of the previous value
  if (previousValue != -1 && abs(averageValue - previousValue) <= tolerance) {
    // Increase the duration the value has stayed within the range
    constantDuration += 5; // delay since there are 5 seconds wasted in running the other functions, so to make sure reminder works for the correct time, we add 5 seconds
  } else {
    // Reset if the value is outside the range
    constantDuration = 0;
  }

  // Save the current value as the previous one for the next loop
  previousValue = averageValue;

  // Check if the constant duration exceeds the threshold and reminder is set to true 
  if (constantDuration >= thresholdDuration && reminder) { // this means water level stayed the same for the set duration, so send a reminder
    // publish reminder to app through MQTT 
    client.publish("esp/water_reminder", "yes");
    Serial.println("REMINDER ON");
    digitalWrite(buzzer, HIGH); // turn the buzzer on
    delay(2000);
    constantDuration = 0; // set duration back to 0 to check for water levels again
    digitalWrite(buzzer, LOW); // turn buzzer off 
  } 
  
}


void motor(){
  if(mixer_state == "ON"){
  digitalWrite(relay, HIGH);
  Serial.println("Mixer is on");
  delay(2000);
  digitalWrite(relay, LOW);
  mixer_state = "";
  }
 
}



void setup() {
  Serial.begin(115200);
  // connect to wifi 
  setup_wifi();
  // define pin mode for IR sensor and relay
  pinMode(ir_pin, INPUT);
  pinMode(relay, OUTPUT);
  pinMode(buzzer, OUTPUT);
  pinMode(button, INPUT_PULLUP);
  // set MQTT broker and port
  client.setServer(broker, brokerPort);
  // set callback to handlw incoming messages 
  client.setCallback(callback);
  // allow wifi connection without certificate
  wifiClientSecure.setInsecure();
  // connect to MQTT
  connect_mqtt();
  // initialize  OLED display
  display.begin(SSD1306_SWITCHCAPVCC, oled_address);
  
}

void loop() {
  // connect to MQTT if disconnected
  if (!client.connected()) {
        connect_mqtt();
    }
    client.loop();
  //execute functions for all sensors and actuators
  readAndMapIRSensor(ir_pin);
  BPM(heartrate_pin);
  readAndDisplayDHTData(dht);
  oled_display(bpm, t, h, logo_array);
  motor();


}