#include <WiFi.h>
#include <HTTPClient.h>
#include <SoftwareSerial.h>
#include "secrets.h"  // ⬅ Import your credentials securely

// GSM module connected to pins 16 (RX) and 17 (TX)
SoftwareSerial gsmSerial(16, 17);

void setup() {
  Serial.begin(115200);
  gsmSerial.begin(9600);

  Serial.println("Connecting to Wi-Fi...");
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  int retryCount = 0;
  while (WiFi.status() != WL_CONNECTED && retryCount < 20) {
    delay(500);
    Serial.print(".");
    retryCount++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n✅ Wi-Fi connected!");
    Serial.print("IP Address: ");
    Serial.println(WiFi.localIP());

    // 1️⃣ Send alert to Supabase
    sendSupabaseEvent("CPR_DEVICE_001", "ON");

    // 2️⃣ Send SMS alert
    sendSMS("+919164206878", "🚨 CPR Device Activated!\nAJ Hospital G Pole\nhttps://maps.app.goo.gl/7u3kc5qL8XuJktR67");

  } else {
    Serial.println("\n❌ Wi-Fi connection failed!");
  }
}

void sendSupabaseEvent(String deviceId, String status) {
  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    http.begin(SUPABASE_URL);
    http.addHeader("Content-Type", "application/json");
    http.addHeader("apikey", SUPABASE_API_KEY);
    http.addHeader("Authorization", String("Bearer ") + SUPABASE_API_KEY);

    String jsonBody = "{\"device_id\":\"" + deviceId + "\",\"status\":\"" + status + "\"}";
    int httpResponseCode = http.POST(jsonBody);

    if (httpResponseCode > 0) {
      Serial.print("✅ Supabase Response Code: ");
      Serial.println(httpResponseCode);
    } else {
      Serial.print("❌ Supabase Error Code: ");
      Serial.println(httpResponseCode);
    }

    http.end();
  } else {
    Serial.println("⚠ Not connected to Wi-Fi, skipping Supabase event.");
  }
}

void sendSMS(String number, String message) {
  gsmSerial.println("AT");
  delay(1000);
  gsmSerial.println("AT+CMGF=1"); // Set to text mode
  delay(1000);
  gsmSerial.print("AT+CMGS=\"");
  gsmSerial.print(number);
  gsmSerial.println("\"");
  delay(1000);
  gsmSerial.print(message);
  delay(500);
  gsmSerial.write(26); // CTRL+Z → send message
  delay(2000);
  Serial.println("✅ SMS sent!");
}

void loop() {
  // Nothing here for now — could add periodic checks or sensors later
}