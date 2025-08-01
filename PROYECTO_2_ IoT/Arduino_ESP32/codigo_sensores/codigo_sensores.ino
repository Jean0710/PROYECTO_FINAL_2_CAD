#include <WiFi.h>              // Librería para conectarse a redes Wi-Fi
#include <PubSubClient.h>      // Librería para conectarse a un broker MQTT
#include <DHT.h>               // Librería para sensores DHT (temperatura y humedad)
#include <ArduinoJson.h>       // Librería para crear y manejar objetos JSON

// Datos de la red Wi-Fi y del broker MQTT
const char* ssid = "iPhone";                         // Nombre de la red Wi-Fi
const char* password = "JanTThony2003";              // Contraseña de la red Wi-Fi
const char* mqtt_server = "broker.hivemq.com";       // Dirección del broker MQTT

WiFiClient espClient;            // Cliente WiFi para conexión MQTT
PubSubClient client(espClient); // Cliente MQTT usando WiFi

// Configuración del sensor DHT11
#define DHTPIN 4                // Pin digital al que está conectado el DHT11
#define DHTTYPE DHT11           // Tipo de sensor DHT
DHT dht(DHTPIN, DHTTYPE);       // Inicialización del sensor DHT

// Configuración del sensor LDR
#define LDR_PIN 32              // Pin analógico donde está conectado el LDR

// Temporizador para controlar cada cuánto se envían los datos
unsigned long lastTime = 0;

void setup() {
  Serial.begin(115200);         // Iniciar monitor serial a 115200 baudios
  dht.begin();                  // Iniciar sensor DHT

  // Conexión a red Wi-Fi
  WiFi.begin(ssid, password);   // Iniciar conexión Wi-Fi
  while (WiFi.status() != WL_CONNECTED) {  // Esperar hasta que se conecte
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi conectado."); // Confirmación de conexión Wi-Fi

  // Configuración del servidor MQTT
  client.setServer(mqtt_server, 1883); // Establecer dirección y puerto del broker MQTT
}

void loop() {
  if (!client.connected()) {  // Verifica si se perdió la conexión MQTT
    reconnect();              // Intenta reconectarse si es necesario
  }
  client.loop();              // Mantiene activa la comunicación MQTT

  unsigned long now = millis(); // Tiempo actual desde que se inició el ESP32

  if (now - lastTime > 1000) {  // Ejecutar cada 1 segundo
    // Lectura del sensor DHT11
    float temp = dht.readTemperature(); // Leer temperatura en °C
    float humedad = dht.readHumidity(); // Leer humedad relativa

    // Lectura del sensor LDR
    int luz = analogRead(LDR_PIN); // Leer nivel de luz (valor entre 0 y 4095)

    // Verifica si las lecturas del DHT11 son válidas
    if (!isnan(temp) && !isnan(humedad)) {
      // Crear objeto JSON con datos del DHT11
      StaticJsonDocument<256> doc1;
      doc1["sensor"] = "DHT11";      // Tipo de sensor
      doc1["temperatura"] = temp;    // Temperatura leída
      doc1["humedad"] = humedad;     // Humedad leída

      char mensaje1[256];            // Buffer para mensaje JSON
      serializeJson(doc1, mensaje1); // Convertir JSON a texto
      client.publish("grupo4/sensores", mensaje1); // Publicar en el tema MQTT
      Serial.println(mensaje1);      // Mostrar en monitor serial
    } else {
      Serial.println("Error al leer DHT11."); // Mensaje de error si la lectura falla
    }

    // Crear objeto JSON con datos del LDR
    StaticJsonDocument<256> doc2;
    doc2["sensor"] = "LDR";   // Tipo de sensor
    doc2["luz"] = luz;        // Nivel de luz

    char mensaje2[256];       // Buffer para mensaje JSON
    serializeJson(doc2, mensaje2); // Convertir JSON a texto
    client.publish("grupo4/sensores", mensaje2); // Publicar en el tema MQTT
    Serial.println(mensaje2); // Mostrar en monitor serial

    lastTime = now; // Actualizar tiempo de última lectura
  }
}

// Función para reconectar al broker MQTT si la conexión se pierde
void reconnect() {
  while (!client.connected()) {
    Serial.print("Intentando conexión MQTT...");
    // Intentar conectar con el ID "ESP32Client"
    if (client.connect("ESP32Client")) {
      Serial.println("Conectado.");
      client.subscribe("grupo4/sensores"); // Suscribirse al tema (por si quieres recibir también)
    } else {
      Serial.print("Fallo rc=");
      Serial.print(client.state()); // Imprimir código de error
      Serial.println(" - Reintentando en 5 segundos.");
      delay(5000); // Esperar antes de intentar de nuevo
    }
  }
}

