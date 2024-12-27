#include <Arduino.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>

// Koneksi WiFi
const char* ssid = "HW807-LCD-47A8";
const char* password = "1234567890";
const char* IPAddr = "192.168.8.214";
// const char* ssid = "CICI_BIZNET";
// const char* password = "cici2024";
// const char* IPAddr = "192.168.18.100";
// const char* ssid = "KOMINFO";
// const char* password = "12345678";
// const char* IPAddr = "192.168.43.155";

WiFiClient NodeMCU;

// Pin sensor kekeruhan
const int turbiditySensorPin = 34;

// LCD
LiquidCrystal_I2C lcd(0x27, 16, 2);

// Definisi pin
const int redLED = 27;
const int blueLED = 26;
const int greenLED = 25;
const int hijauLED = 12;
const int buzzer = 23;
const int echoPin = 18;
const int trigPin = 5;

// Variabel untuk sensor ultrasonik
long duration;
float jarak;
const float tinggiWadah = 16.6;
float tinggiAir;
const char* kode_alat = "alatUcup"; // Sesuaikan dengan kode alat di database

// Status verifikasi
bool isVerified = false;

// Deklarasi fungsi
float readUltrasonic();
void verifyAndSendData(int turbidity, float tinggiAir);

// Task prototypes
void TaskReadSensors(void* pvParameters);
void TaskControlOutputs(void* pvParameters);
void TaskSendData(void* pvParameters);
void TaskDisplayLCD(void* pvParameters);

void setup() {
    Serial.begin(9600);
    Wire.begin();
    lcd.init();
    lcd.backlight();

    // Inisialisasi pin
    pinMode(blueLED, OUTPUT);
    pinMode(redLED, OUTPUT);
    pinMode(greenLED, OUTPUT);
    pinMode(hijauLED, OUTPUT);
    pinMode(buzzer, OUTPUT);
    pinMode(trigPin, OUTPUT);
    pinMode(echoPin, INPUT);

    // Koneksi WiFi
    WiFi.begin(ssid, password);
    lcd.print("Connecting");
    while (WiFi.status() != WL_CONNECTED) {
        lcd.print(".");
        Serial.print(".");
        delay(500);
    }

    lcd.clear();
    lcd.print("WIFI CONNECTED");
    Serial.println("CONNECTED...");
    delay(1000);

    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Welcome to");
    lcd.setCursor(0, 1);
    lcd.print("T O S E R B A !");
    delay(3000);
    lcd.clear();

    // Create tasks
    xTaskCreate(TaskReadSensors, "ReadSensors", 4096, NULL, 4, NULL);
    xTaskCreate(TaskControlOutputs, "ControlOutputs", 4096, NULL, 2, NULL);
    xTaskCreate(TaskSendData, "SendData", 4096, NULL, 3, NULL);
    xTaskCreate(TaskDisplayLCD, "DisplayLCD", 4096, NULL, 2, NULL);
}

float readUltrasonic() {
    digitalWrite(trigPin, LOW);
    delayMicroseconds(2);
    digitalWrite(trigPin, HIGH);
    delayMicroseconds(10);
    digitalWrite(trigPin, LOW);
    duration = pulseIn(echoPin, HIGH);
    jarak = duration * 0.034 / 2;
    return tinggiWadah - jarak;
}

void verifyAndSendData(int turbidity, float tinggiAir) {
    if (WiFi.status() != WL_CONNECTED) {
        Serial.println("WiFi tidak terhubung!");
        return;
    }

    HTTPClient http;
    StaticJsonDocument<200> doc;

    // Verifikasi kode alat
    String verifyUrl = String("http://") + IPAddr + "/toserba/android/verify_alat.php?kode=" + String(kode_alat);
    http.begin(verifyUrl);
    int httpCode = http.GET();

    if (httpCode == HTTP_CODE_OK) {
        String response = http.getString();
        DeserializationError error = deserializeJson(doc, response);

        if (!error) {
            isVerified = doc["verified"];

            if (isVerified) {
                // Update data kekeruhan
                String turbidityUrl = String("http://") + IPAddr + "/toserba/android/kirimdatakeruh.php?nilaiKeruh=" + String(turbidity) + "&kode_alat=" + String(kode_alat);
                http.begin(turbidityUrl);
                http.GET();
                http.end();

                // Update data ketinggian
                String waterLevelUrl = String("http://") + IPAddr + "/toserba/android/kirimdatatinggi.php?nilaiTinggi=" + String(tinggiAir) + "&kode_alat=" + String(kode_alat);
                http.begin(waterLevelUrl);
                http.GET();
                http.end();
            }
        }
    }
    http.end();
}

void TaskReadSensors(void* pvParameters) {
    while (1) {
        // Baca sensor ketinggian air
        float tinggiAir = readUltrasonic();
        Serial.print("Tinggi Air: ");
        Serial.println(tinggiAir);

        // Baca sensor kekeruhan
        int turbidityValue = analogRead(turbiditySensorPin);
        Serial.print("Nilai Kekeruhan: ");
        Serial.println(turbidityValue);

        

        vTaskDelay(1000 / portTICK_PERIOD_MS);
    }
}

void TaskControlOutputs(void* pvParameters) {
    while (1) {
        // Baca data sensor langsung
        float tinggiAir = readUltrasonic();
        int turbidityValue = analogRead(turbiditySensorPin);

        // Hitung kekeruhan dalam persen
        int turbidity = map(turbidityValue, 0, 750, 0, 100);

        // Kontrol LED berdasarkan ketinggian air dan kekeruhan
        if (tinggiAir < 6) {
            digitalWrite(redLED, HIGH);
        } else {
            digitalWrite(redLED, LOW);
        }

        vTaskDelay(1000 / portTICK_PERIOD_MS);
    }
}

void TaskSendData(void* pvParameters) {
    while (1) {
        // Baca data sensor langsung
        float tinggiAir = readUltrasonic();
        int turbidityValue = analogRead(turbiditySensorPin);

        // Kirim data ke server
        int turbidity = map(turbidityValue, 0, 750, 0, 100);
        verifyAndSendData(turbidity, tinggiAir);

        vTaskDelay(1000 / portTICK_PERIOD_MS);
    }
}

void TaskDisplayLCD(void* pvParameters) {
    while (1) {

        
        // Baca data sensor langsung
        float tinggiAir = readUltrasonic();
        int turbidityValue = analogRead(turbiditySensorPin);
        int turbidity = map(turbidityValue, 0, 750, 0, 100);

        // Tampilkan data di LCD
        lcd.clear();
        lcd.setCursor(0, 0);
        lcd.print(turbidity);
        lcd.setCursor(0, 1);
        lcd.print(tinggiAir);

        if (tinggiAir <= 6) {
            digitalWrite(blueLED, LOW);  // LED biru menyala
            digitalWrite(redLED, HIGH);
            digitalWrite(greenLED, LOW);
            digitalWrite(buzzer, LOW);
            lcd.setCursor(6, 1);
            lcd.print("(RENDAH)");
            Serial.println("Status Air: RENDAH");
        } else if (tinggiAir <= 8) {
            digitalWrite(blueLED, HIGH);  // LED biru menyala
            digitalWrite(redLED, LOW);
            digitalWrite(greenLED, LOW);
            digitalWrite(buzzer, LOW);
            lcd.setCursor(6, 1);
            lcd.print("(SEDANG)");
            Serial.println("Status Air: SEDANG");
        } else if (tinggiAir <= 11) {
            digitalWrite(blueLED, LOW);
            digitalWrite(redLED, LOW);
            digitalWrite(greenLED, HIGH);
            digitalWrite(buzzer, LOW);
            lcd.setCursor(6, 1);
            lcd.print("(TINGGI)");
            Serial.println("Status Air: TINGGI");
        } else if (tinggiAir >= 12) {
            digitalWrite(buzzer, HIGH);   // Buzzer menyala
            digitalWrite(greenLED, HIGH); // LED menyala
            digitalWrite(redLED, HIGH);   // LED menyala
            digitalWrite(blueLED, HIGH);  // LED menyala
            lcd.setCursor(6, 1);
            lcd.print("(WARNING!)");
            Serial.println("Status Air: WARNING!");
        } else {
            Serial.println("Status Air: .....");
        }

        // Mengontrol LED dan buzzer berdasarkan status kekeruhan
        if (turbidity > 500) { // Air bersih
            lcd.setCursor(4, 0);
            lcd.print("(BERSIH)");
            Serial.println("Status: BERSIH");
        } else if (turbidity > 400) { // Air agak keruh
            lcd.setCursor(4, 0);
            lcd.print("(AGAK KERUH)");
            Serial.println("Status: AGAK KERUH");
        } else { // Air keruh
            lcd.setCursor(4, 0);
            lcd.print("(KERUH)");
            Serial.println("Status: KERUH");
            digitalWrite(buzzer, HIGH);
            delay(100);
            digitalWrite(buzzer, LOW);
            delay(100);
        }

        vTaskDelay(1000 / portTICK_PERIOD_MS);
    }
}

void loop() {
    digitalWrite(hijauLED, HIGH);
        delay(100);
        digitalWrite(hijauLED, LOW);
        delay(1000);
}