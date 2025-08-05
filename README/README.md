## Proyecto Final – Comunicaciones Analógicas y Digitales

Este proyecto integra diferentes técnicas de transmisión y procesamiento de señales usando MATLAB, Arduino (ESP32), Python, MQTT e InfluxDB. Se desarrollan dos esquemas de comunicación digital para transmitir datos multicanal desde sensores.

---

## Estructura del Proyecto

```
PROYECTO_FINAL/
│
├── MATLAB_Esquema1/
│   ├── acquisition.m
│   ├── coding.m
│   ├── compression.m
│   ├── channel_mod.m
│   ├── mod_8psk.m
│   └── utils/  (archivos .mat, .png, .csv generados)
│
├── MATLAB_Esquema2/
│   ├── ofdm.m
│   ├── demod.m
│   └── outputs/
│
├── Arduino/
│   └── esp32_mqtt_sensores.ino
│
├── Python_MQTT/
│   ├── receiver.py
│   └── requirements.txt
│
└── README.md
```

---

## Objetivo General

Transmitir datos de sensores (temperatura, humedad y luz) usando dos esquemas digitales:
1. **Esquema 1:** Modulación digital directa con 8-PSK
2. **Esquema 2:** Modulación multicarrier OFDM con inserción de pilotos

---

## Tecnología y Herramientas

- MATLAB (procesamiento de señales)
- Arduino (ESP32, sensores DHT11 y LDR)
- Python (backend receptor)
- MQTT (protocolo de mensajería)
- InfluxDB (base de datos de series temporales)
- Telegram + Correo (alertas)

---

## Datos de Entrada

Desde el ESP32 se adquieren tres señales:
- Temperatura (°C)
- Humedad relativa (%)
- Nivel de luz (0-4095)

Se transmite cada segundo a través del protocolo MQTT al tópico: `grupo4/sensores`.

---

## Librerías Python necesarias (`requirements.txt`)

```
paho-mqtt
influxdb-client
python-telegram-bot
```

Instalación:

```bash
pip install -r requirements.txt
```

---

## Cómo ejecutar

### MATLAB

#### Esquema 1 – Portadora única con modulación 8-PSK

```matlab
acquisition     % Paso 1: Adquisición de señal multicanal
coding          % Paso 2: Codificación PCM y DPCM
compression     % Paso 3: Compresión Wavelet + µ-law
mod_8psk        % Paso 5: Modulación digital 8-PSK
```

#### Esquema 2 – OFDM con 64 subportadoras

```matlab
ofdm            % Paso 6: OFDM con inserción de pilotos y prefijo cíclico
demod           % Paso 7: Demodulación, ecualización y reconstrucción
```

---

### Arduino (ESP32)

1. Abre `esp32_mqtt_sensores.ino` en el IDE de Arduino
2. Configura tu red Wi-Fi y broker MQTT
3. Carga el código en el ESP32
4. Abre el Monitor Serial a 115200 baudios

---

### Python

Ejecutar el receptor y backend:

```bash
cd Python_MQTT
python receiver.py
```

---

## Python – Receptor MQTT + InfluxDB + Alertas

 Carpeta: `Python_MQTT/receiver.py`

### Funciones del backend:

- Escucha el tópico MQTT `grupo4/sensores`
- Guarda los datos en **InfluxDB**:
  - Bucket `DHT11`: temperatura y humedad
  - Bucket `LDR`: luz
- Envía alertas si:
  - Temperatura > 30 °C
- Alertas automáticas por:
  - Telegram
  - Correo electrónico

---

## Reglas de Alerta del Backend

| Condición                 | Acción automática                          |
|---------------------------|--------------------------------------------|
| Temperatura > 30 °C       | Telegram + Correo electrónico           |
| Lectura cada 60 segundos  | Guardado en InfluxDB                    |

---

## Buckets usados en InfluxDB

| Bucket  | Variables almacenadas         |
|---------|-------------------------------|
| DHT11   | temperatura, humedad          |
| LDR     | nivel de luz                  |

---

## Broker MQTT

- Broker público usado: `broker.hivemq.com`
- Tópico: `grupo4/sensores`

---

## Archivos generados automáticamente

Durante la ejecución de los scripts en MATLAB, se generan automáticamente:
- Archivos `.mat`: señales intermedias
- Imágenes `.png`: gráficas de tiempo, frecuencia, constelación, PSD, PAPR, BER
- Archivos `.csv`: tablas de bit-rate vs SNR, compresión, evaluación MOS

---

## Autores

- Pablo Flores, Jennifer Taramuel, Jean Yaguachi

---

## Notas

- Se debe tener instalado InfluxDB y habilitado el puerto 8086
- Se debe tener instalado Grafana y habilitado el puerto 3000
- Asegúrate de tener conexión a Internet para el envío de alertas
- El ESP32 debe tener acceso a la red Wi-Fi configurada

---