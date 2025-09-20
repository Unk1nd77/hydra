//**********************************
// 2021.02.24
// Чернышов А. В.
// Перед каждым отображением/передачей адреса IP он запрашивается повторно
//
// 2021.02.10
// Чернышов А. В.
// Корректировка системного вызова подключения к сети Wi-Fi
// Отладка отображения уровня сигнала Wi-Fi
// Отображение (дополнительно) уровня сигнала Wi-Fi на экране с адресом IP
// 
// 2020.10.09
// Варюхин К.
// Корректировка чтения конфигурации из SPIFFS
// Введение усреднения результатов измерений
// Введение отображения инициализации датчика BME280
// Отображение уровня сигнала Wi-Fi на экране измерений
//**********************************

// Библиотеки для сервера на ESP8266
#include <ESP8266WiFi.h>                                // Подключаем библиотеку ESP8266WiFi
#include <ESP8266WebServer.h>                           // Подключаем библиотеку ESP8266WebServer
#include <ESP8266HTTPClient.h>                          // Подключаем библиотеку ESP8266HTTPClient

// Библиотека для LCD экрана
#include <LiquidCrystal_I2C.h>                          // Подключаем библиотеку LiquidCrystal_I2C

// Библиотеки для bme280
#include <Wire.h>                                       // Подключаем библиотеку Wire
#include <Adafruit_Sensor.h>                            // Подключаем библиотеку Adafruit_Sensor
#include <Adafruit_BME280.h>                            // Подключаем библиотеку Adafruit_BME280

// Библиотека для SPIFFS
#include "FS.h"

////////////////////////////////////////////////////////////////////////////////////////////////////

LiquidCrystal_I2C lcd(0x27,16,2);         // Объект LCD

#define SEALEVELPRESSURE_HPA (1013.25)    // Высота
Adafruit_BME280 bme;                      // Объект BME280

// Переменные для показателей температуры, влажности и давления
float temperature = 0;                    
float humidity = 0;
float pressure = 0;

float temp_array[5];
float hum_array[5];

// Переменные для LCD
String LCDmode = "2";
String LCDstring1;
String LCDstring2;

String json;                              // Переменная JSON для отправки данных на сервер

int numMillis = 0;                        // Переменная, хранящая количество милисекунд таймера
int timer = 60000;                         // Переменная, хранящая период измерений

int count = 0;

String whoami;                            // Имя устройства
String Akey;                              // Akey
String wifi_name;                         // Название WiFi сети
String wifi_pass;                         // Пароль WiFi сети
IPAddress myIP;                           // Хранит IP адресс
ESP8266WebServer server(80);              // Объявление сервера и номер порта для общения
HTTPClient http;

// Объявления функций выплнения команд
void handleRoot();                        // Обработчик главной страницы
void handleData();                        // Обработчик показателей BME280
void handleMode();                        // Обработчик режима устройства
void handleLCD();                         // Обработчик LCD
void handleLED();                         // Обработчик подсветки

////////////////////////////////////////////////////////////////////////////////////////////////////

// Инициализация
void setup() 
{
  // Инициализация COM порта
  Serial.begin(115200); delay(500);

    // Инициализация LCD
  lcd.begin();
  lcd.backlight();
  
  lcd.clear();
  lcd.setCursor(0,0);
  lcd.print("Init. SPIFFS");
  
  // Инициализация SPIFFS
  if (!SPIFFS.begin()) {
    Serial.println("Error: No SPIFFS");
    lcd.clear();
    lcd.setCursor(0,0);
    lcd.print("NO SPIFFS");
    return;
  }
  
  // Инициализация Hydra
  File f_config = SPIFFS.open("/config.txt", "r");
  if (!f_config) {
      Serial.println("Error: File doesn't exist");
      return;
    } else {
     whoami = f_config.readStringUntil('\n');
     if (whoami.charAt(whoami.length()-1) == 13)
     whoami = whoami.substring(0, whoami.length()-1);
     
     Akey = f_config.readStringUntil('\n');
     if (Akey.charAt(Akey.length()-1) == 13)
     Akey = Akey.substring(0, Akey.length()-1);
     
     wifi_name = f_config.readStringUntil('\n');
     if (wifi_name.charAt(wifi_name.length()-1) == 13)
     wifi_name = wifi_name.substring(0, wifi_name.length()-1);
     
     wifi_pass = f_config.readStringUntil('\n');
     if (wifi_pass.charAt(wifi_pass.length()-1) == 13)
     wifi_pass = wifi_pass.substring(0, wifi_pass.length()-1);
     
    }
  f_config.close();
  Serial.println();
  Serial.println(whoami);
  Serial.println(Akey);
  Serial.println(wifi_name);
  Serial.println(wifi_pass);

  lcd.clear();
  lcd.setCursor(0,0);
  lcd.print("Init. BME280...");
  
  // Инициализация датчика BME280 
  while (!bme.begin(0x76)) {
     Serial.println("Error: BME280 doesn't exist!");
     lcd.clear();
     lcd.setCursor(0,0);
     lcd.print("Init. BME280...");
     delay(1000);
   }

   // Инициализация WiFi
  WiFi.persistent(false);                 // Не перезаписывать параметры Wi-Fi в EEPROM
  WiFi.disconnect();                      // Отключение станции от точки доступа 
  WiFi.mode(WIFI_OFF); delay(500);        // Установка режима WiFi - Выкл.
  WiFi.mode(WIFI_STA);                    // Установка режима WiFi - «станция»

  //WiFi.setOutputPower(15);                 // Установка мощности передатчика: min=0, max=20.5
  WiFi.setOutputPower(15);

  /*
  IPAddress staIP(192,168,7,7);            // Установка IP адреса
  IPAddress staGW(192,168,7,1);            // Установка адреса шлюза (если есть) (3 первых числа должны совпадать с IP)
  IPAddress staNET(255,255,255,0);         // Установка маски подсети
  WiFi.config(staIP, staGW, staNET);       // Настройка сетевого интерфейса программной точки доступа
  */
  
  // Подключение к сети
  WiFi.begin(wifi_name.c_str(), wifi_pass.c_str());
  lcd.clear();
  lcd.setCursor(0,0);
  lcd.print("WiFi connecting...");
  
  while (WiFi.status() != WL_CONNECTED)
  {
    delay(500);
    Serial.print(".");
  }
  myIP=WiFi.localIP();                     // Сохранение строки с IP адресом
  Serial.println("");
  Serial.println(myIP);

  // Вывод IP адреса на LCD
  lcd.clear();
  lcd.setCursor(0,0);
  lcd.print("Local IP");
  lcd.setCursor(0,1);
  lcd.print(myIP);
  lcd.setCursor(13,0);
  lcd.print((int)(WiFi.RSSI()));

  // Инициализация сервера
  server.on("/", handleRoot);             // Установка вызова обработчика главной страницы
  server.on("/getData", handleData);      // Установка вызова обработчика BME280
  server.on("/setMode", handleMode);      // Установка вызова обработчика режима работы
  server.on("/setLCD", handleLCD);        // Установка вызова обработчика экрана
  server.on("/setLED", handleLED);        // Установка вызова обработчика подсветки
  server.begin();                         // Перезапуск сервера
}

////////////////////////////////////////////////////////////////////////////////////////////////////

void loop() 
{
  server.handleClient();                  // Обработчик запросов клиента.
  
  // Периодическое измерение окружающей среды  
  if (count < 5)
  {
    if((millis()-numMillis)>=timer/5)
    {
      numMillis=millis();
      temp_array[count]=bme.readTemperature();
      hum_array[count]=bme.readHumidity();
      count++;
    }
  }
  else
  {
    count = 0;
    temperature = (temp_array[0]+temp_array[1]+temp_array[2]+temp_array[3]+temp_array[4])/5.000F;
    humidity = (hum_array[0]+hum_array[1]+hum_array[2]+hum_array[3]+hum_array[4])/5.000F;
    pressure = bme.readPressure()/100.0F*0.7500637554192F;

    sendJsonToDB();

    // Если режим работы - показание измерений, то проводится обновление информации на экране
    if (LCDmode == "0")
    {
      lcd.clear();
      lcd.setCursor(0,0);
      lcd.print("T="); lcd.print(temperature,1); lcd.print((char)223); lcd.print("C ");
      lcd.print("H="); lcd.print(humidity,1); lcd.print("%");
      lcd.setCursor(0,1);
      lcd.print("P="); lcd.print(pressure,1); lcd.print("mmHg");
      //lcd.print(" R="); lcd.print(WiFi.RSSI(),1); lcd.print("dBm");
      lcd.setCursor(13,1);
      lcd.print((int)(WiFi.RSSI()));

      if (WiFi.status() != WL_CONNECTED)
      {
        lcd.clear();
        lcd.setCursor(0,0);
        lcd.print("No WiFi signal");
      }
    }else if (LCDmode == "2")                
      {
    lcd.clear();
    lcd.setCursor(0,0);
    lcd.print("Local IP");
    lcd.setCursor(0,1);
    //lcd.print(myIP);
    lcd.print(WiFi.localIP());
    lcd.setCursor(13,0);
    lcd.print((int)(WiFi.RSSI()));
      }
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////

// Обработчик главной страницы
void handleRoot()
{
  File page = SPIFFS.open("/page.html", "r");
  server.streamFile(page, "text/html");
  page.close(); 
}

void sendJsonToDB()
{
  json  =  "{\"system\":{ ";
  json += "\"Akey\":\""+Akey+"\", ";
  json += "\"Serial\":\""+whoami+"\", ";
  json += "\"Version\":\"2021-02-24\", ";
  json += "\"RSSI\":\"" + String(WiFi.RSSI()) + "\",";
  json += "\"MAC\":\"" + String(WiFi.macAddress()) + "\",";
  myIP=WiFi.localIP();
  json += "\"IP\":\""; json+= (String)myIP[0] + String(".") + (String)myIP[1] + String(".") +(String)myIP[2] + String(".") + (String)myIP[3]; json += "\"},";
  json += "\"BME280\":{ ";
  json += "\"temp\":"+String(temperature)+",";
  json += "\"humidity\":"+String(humidity)+",";
  json += "\"pressure\":"+String(pressure)+"} }";

  http.begin("http://188.35.161.31/core/jsonadd.php");
  http.addHeader("Content-Type", "application/json");
  int resulthttp = http.POST(json);
  Serial.print("Done: ");
  Serial.println(resulthttp);
  http.end();
}

// Обработчик показателей BME280
void handleData()
{ 
  
  //Отправка JSON строки
  json="{\n\"temperature\": ";
  json+=temperature;
  json+=",\n\"humidity\": ";
  json+=humidity;
  json+=",\n\"pressure\": ";
  json+=pressure;
  json+="\n}";
  
  server.send(200, "application/json", json);
}

// Обработчик режима устройства
void handleMode()
{
  LCDmode = server.arg("mode");           // Считывание выбранного режима

  // Режим отображения показаний окружающей среды
  if (LCDmode == "0")                     
  {
    lcd.clear();
    lcd.setCursor(0,0);
    lcd.print("T="); lcd.print(temperature,1); lcd.print((char)223); lcd.print("C ");
    lcd.print("H="); lcd.print(humidity,1); lcd.print("%");
    lcd.setCursor(0,1);
    lcd.print("P="); lcd.print(pressure,1); lcd.print("mmHg");
    lcd.setCursor(13,1);
    lcd.print((int)(WiFi.RSSI()));
    
    server.send(200,"text/plain","Показания");
  }
  
  // Режим пейджера
  else if (LCDmode == "1")                
  {
    lcd.clear();
    lcd.setCursor(0,0);
    lcd.print(LCDstring1);
    lcd.setCursor(0,1);
    lcd.print(LCDstring2);
    
    server.send(200, "text/plain", "Пейджер");
  }

  // Режим отображения IP
  else if (LCDmode == "2")                
  {
    lcd.clear();
    lcd.setCursor(0,0);
    lcd.print("Local IP");
    lcd.setCursor(0,1);
    //lcd.print(myIP);
    lcd.print(WiFi.localIP());
    lcd.setCursor(13,0);
    lcd.print((int)(WiFi.RSSI()));
    
    server.send(200, "text/plain", "IP");
  }
  else server.send(200, "text/plain", "...");
}

// Обработчик LCD
void handleLCD()
{
  if (server.arg("num")=="1")             // Обработка 1 строки
  {
    LCDstring1=server.arg("str");
    if (LCDmode=="1")
    {
      lcd.setCursor(0,0);
      for (int i = 0; i <16;i++) lcd.print(' ');
      lcd.setCursor(0,0);
      lcd.print(LCDstring1);
    }
  }
  else if (server.arg("num")=="2")        // Обработка 2 строки
  {
    LCDstring2=server.arg("str");
    if (LCDmode=="1")
    {
      lcd.setCursor(0,1);
      for (int i = 0; i <16;i++) lcd.print(' ');
      lcd.setCursor(0,1);
      lcd.print(LCDstring2);
    }
  }
  server.send(200, "text/plain", "");
}

// Обработчик подсветки
void handleLED()
{
  if (server.arg("LEDstate")=="1")
  {
    lcd.backlight();
    server.send(200, "text/plain", "ВКЛ");
  }
  else if (server.arg("LEDstate")=="0")
  {
    lcd.noBacklight();
    server.send(200, "text/plain", "ВЫКЛ");
  }
}
