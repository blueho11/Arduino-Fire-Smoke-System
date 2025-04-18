  /*
  --------------------------------------------
  | Coderes : Fadi / Keria / Saif            |
  |                                          |
  | Date : Mon Mar 31 12:30:00 AM EET 2025.  |
  |                                          |
  | Project : Smoke And Fire Detection.      |
  --------------------------------------------
  */

  // Include Library.
  #include <SoftwareSerial.h> // Related to SIM800L module
  #include <LiquidCrystal_I2C.h> // Related to I2C
  #include <Wire.h>  // Related to I2C


  // ============= Define pins =================
  const int BUZZER = 13;
  const int RedLed = 12;
  const int GreenLed = 11;
  const int YellowLed = 10;
  const int Pump = 8;
  const int fireSensor = 7;
  const int fan = 6;
  const int txpin = 3;
  const int rxpin = 2;
  const int LM35 = A1;
  const int smokeSensor = A0;


  // ========== Initialze Variables ============   
  const int MED_SMOKE = 600;
  const int HIGH_SMOKE = 800;
  const int HIGH_TEMP = 70;

  // ============ Initialize LCD ===============
  LiquidCrystal_I2C lcd(0x27, 16, 2);


  // ============ Initialize SIM ===============  
  const int N = 3; // Determine how many phone mobile i want to call
  String arr[N] = {"01023065186", "", ""};  // Array to store phone numbers

  SoftwareSerial sim800L(rxpin, txpin);



// =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-= [Setup] =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  void setup() {

    Serial.begin(9600);  // Start Serial Monitor
    sim800L.begin(9600); // Start SIM800L communication

    Serial.println("Initializing...");
    sim800L.println("AT");
    delay(1000);
    sim800L.println("AT+CMGF=1");
    delay(1000);


    lcd.init();
    lcd.backlight();

    pinMode(RedLed, OUTPUT);
    pinMode(YellowLed, OUTPUT);
    pinMode(GreenLed, OUTPUT);
    pinMode(BUZZER, OUTPUT);
    pinMode(fireSensor, INPUT);
    pinMode(fan,OUTPUT);
    pinMode(Pump,OUTPUT);

    lcd.setCursor(centerText("Fire And Smoke"), 0);
    lcd.print("Fire And Smoke");
    delay(1000);
    lcd.setCursor(0,1);
    lcd.print("Detection System");
    delay(2000);
    lcd.clear();

  }

  // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-= [Functions] =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  
  // [1] Calculates the starting column to center text on a 16-character LCD
  int centerText(String text) {
    int length = text.length();
    return (16 - length) / 2;

  }

  
  // [2] Blink LEDs with Delay 250 millesecond
  void blinkLEDs() {
    digitalWrite(RedLed, HIGH);
    digitalWrite(YellowLed, HIGH);
    digitalWrite(GreenLed, HIGH);
    delay(250);
    digitalWrite(RedLed, LOW);
    digitalWrite(YellowLed, LOW);
    digitalWrite(GreenLed, LOW);
    delay(250);
  }


  // [3] Sets the fan speed to a medium level
  void Mid_Fan(){
    analogWrite(fan,125);
  }

  // [4] Sets the fan speed to the highest level
  void High_Fan(){
    analogWrite(fan,255);
  }


  // [5] highAlert Function Work in dangerous Situation 
  //     - Turn blinkLed  
  //     - Set Fan speed High
  //     - Turn on Buzzer with Specfic hz [1000] To Make Different Sound
  void highAlert() {
    for (int i = 0; i < 30; i++) {
      tone(BUZZER, 1000, 300);
      blinkLEDs();
      High_Fan();
    }
    delay(100);
  }

  void WaterPump() {
    delay(50);
    digitalWrite(Pump, HIGH); // Turn pump ON
    delay(5000);              // Wait 5 secondsH;
  }
  
  // [6] send an SMS using the SIM800L module
  //      - text: The message content to be sent
  //      - phone: The recipient's phone number
  void send_sms(String text, String phone) {
      Serial.println("sending sms...."); // Print status message to Serial Monitor
      delay(50);

      sim800L.print("AT+CMGF=1\r"); // Set SMS mode to text
      delay(1000);

      sim800L.print("AT+CMGS=\"" + phone + "\"\r"); // Specify the recipient phone number
      delay(1000);

      sim800L.print(text); // Send the message content
      delay(100);

      sim800L.write(0x1A); // Send the End-Of-Message (EOM) command
      delay(5000); // Wait for SMS to be sent 5 Second
  }

  void send_multi_sms(String text) {
    for (int i = 0; i < N; i++){
        if (arr[i] != ""){
            Serial.print("Sending SMS to: ");
            Serial.println(arr[i]);
            send_sms(text, arr[i]);
        }
    }
  }

  // [7] make a phone call using the SIM800L module
  //   - To The recipient's phone number
  void make_call(String phone) {
      Serial.println("calling...."); // Print status message to Serial Monitor

      sim800L.println("ATD" + phone + ";"); // Dial the phone number
      delay(20000); // Wait 20 seconds before hanging up

      sim800L.println("ATH"); // Hang up the call
      delay(1000);
  }


  void make_multi_call() {
    for (int i = 0; i < N; i++) {
        if (arr[i] != "") { 
            Serial.print("Calling: ");
            Serial.println(arr[i]);
            make_call(arr[i]);
        }
    }
  }
 

  // [8] read temperature from an analog temperature sensor
  //   -Convert ADC To temperature in degrees Celsius
  float LM_TEMP(){
    int temp_adc_val;
    float temp_val;
    temp_adc_val = analogRead(LM35);  /* Read Temperature */
    temp_val = (temp_adc_val * 4.88);      /* Convert adc value to equivalent voltage */
    temp_val = (temp_val/10);  /* LM35 gives output of 10mv/°C */
    Serial.print("Temperature = ");
    Serial.print(temp_val);
    Serial.print(" Degree Celsius\n");
    delay(5000);  // Wait 5 Sec Until Give the New Value Of Temp
    return temp_val;
  }

  
  // [9] Read Smoke Sensor And Return the ADC Value
  int readSmoke() {
    int smokeValue = analogRead(smokeSensor);
    
    lcd.setCursor(0, 0);
    lcd.print("Smoke: ");
    lcd.print("LOW");
    lcd.print("     ");
    return smokeValue;
  }

  // [10] Read The Fire Sensor And Return the ADC Value
  int readFire() {
    int fireValue = digitalRead(fireSensor);
    lcd.setCursor(0, 1);
    lcd.print("NO FIRE DETECTED");

    return fireValue;
  }


  // =-=-=-=-=-=-=-=-=-= Main loop function-=-=-=-=-=-=-=-=-=-=-=-=-=
  void loop() {

    // Debug and test the sim800L 
    while (sim800L.available())
    {
      Serial.println(sim800L.readString());
    }

    // Read Value Came From Function to make operation on it. 
    float temperature = LM_TEMP();
    int smokeValue = readSmoke();
    int fireValue = readFire();


    if (fireValue == 0) {
      lcd.setCursor(0, 1);
      lcd.print("FIRE DETECTED ! ");
      highAlert();
      WaterPump();
      send_multi_sms("Fire DETECTED"); // Final Action send Sms And Make Call
      make_multi_call();
      
    } 


    else if (temperature > HIGH_TEMP) {
      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("Dangerous!!");
      lcd.setCursor(0, 1);
      lcd.print("TEMP:");
      lcd.print(temperature);
      digitalWrite(GreenLed,LOW);
      digitalWrite(YellowLed, HIGH);
      tone(BUZZER, 950);
      Mid_Fan();
      Serial.println("HIGH TEMP !!");
      send_multi_sms("DANGEROUS! THE TEMPRATURE IS");
    } 
    

    else if (smokeValue > HIGH_SMOKE) {
      lcd.setCursor(0, 0);
      lcd.print("HIGH SMOKE");
      highAlert();
      send_multi_sms("HIGH SMOKE DETECTED");
      make_multi_call();
    }


    else if (smokeValue > MED_SMOKE) {
      lcd.setCursor(0, 0);
      lcd.print("MEDIUM SMOKE");
      digitalWrite(GreenLed,LOW);
      digitalWrite(YellowLed, HIGH);
      tone(BUZZER, 750);
      Mid_Fan();
      send_multi_sms("MEDIUM SMOKE DETECTED!");
    }


    else {
      digitalWrite(YellowLed, LOW);
      digitalWrite(RedLed, LOW);
      digitalWrite(Pump,LOW);
      digitalWrite(fan,LOW);
      noTone(BUZZER);
      digitalWrite(GreenLed, HIGH);
    }

    delay(500);
  }
