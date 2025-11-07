#include <SoftwareSerial.h>

SoftwareSerial mySerial(3, 2);
void setup() {
  Serial.begin(9600);
  mySerial.begin(9600);

  Serial.println("Initializing GSM...");
  delay(1000);

  // Basic AT Test
  mySerial.println("AT");
  updateSerial();

  // SMS text mode
  mySerial.println("AT+CMGF=1");
  updateSerial();
  
  // Send SMS
  mySerial.println("AT+CMGS=\"+919164206878\""); // <-- change if needed
  updateSerial();

  // ✅ IMPORTANT:
  // SMS format Twilio/backend expects: CPR,<latitude>,<longitude>
  // Example dummy values: 12.9173 , 77.6043
  mySerial.print("CPR,12.9173,77.6043");
  updateSerial();

  // CTRL+Z to actually send
  mySerial.write(26);

  Serial.println("\n✅ SMS Sent!");
}

void loop() {
  // Nothing here; trigger SMS from sensor later if needed
}

void updateSerial() {
  delay(500);
  while (Serial.available()) {
    mySerial.write(Serial.read());
  }
  while (mySerial.available()) {
    Serial.write(mySerial.read());
  }
}
