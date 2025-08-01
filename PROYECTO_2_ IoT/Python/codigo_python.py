import json
import smtplib
import time
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import paho.mqtt.client as mqtt
from influxdb_client import InfluxDBClient, Point, WritePrecision
from influxdb_client.client.write_api import SYNCHRONOUS
import asyncio
from telegram import Bot
from datetime import datetime, timezone

# === CONFIGURACIONES ===
MQTT_BROKER = "broker.hivemq.com"
MQTT_TOPIC = "grupo4/sensores"

INFLUX_TOKEN = "g-jXmZ1ZaUQV87JwESocoxKX5-a8crCBOcOCsYPWcbgbVHmnl3Tr3HxZR6RKOYjGtJwvl8yuG1ZHuzAVRwmWvA=="
INFLUX_ORG = "Proyecto"
INFLUX_URL = "http://localhost:8086"

BUCKETS = {
    "DHT11": "DHT11",
    "LDR": "LDR"
}

TELEGRAM_TOKEN = "8469855669:AAF3rps7SZGwAqhY_qcZIsSGvKVqnc9HqyA"
TELEGRAM_CHAT_ID = "5533238896"

SMTP_SERVER = "smtp.gmail.com"
SMTP_PORT = 587
EMAIL_USER = "yaguachy78@gmail.com"
EMAIL_PASS = "ixfx fiur natw ibey"
EMAIL_TO = "taramueljennifer@gmail.com"

bot = Bot(token=TELEGRAM_TOKEN)
influx = InfluxDBClient(url=INFLUX_URL, token=INFLUX_TOKEN, org=INFLUX_ORG)
write_api = influx.write_api(write_options=SYNCHRONOUS)

# === CONTROL DE ALERTAS Y LECTURAS ===
ultimo_alerta_telegram = 0
ultimo_alerta_correo = 0
INTERVALO_ALERTA = 2  # segundos para alertas

ultimo_dht = 0
ultimo_ldr = 0
INTERVALO_LECTURA = 60  # segundos para guardar lecturas

# === FUNCIONES DE ALERTA ===
async def enviar_telegram_async(mensaje):
    try:
        await bot.send_message(chat_id=TELEGRAM_CHAT_ID, text=mensaje)
        print("📨 Telegram enviado.")
    except Exception as e:
        print("❌ Error al enviar Telegram:", e)

def enviar_telegram(mensaje):
    try:
        try:
            loop = asyncio.get_running_loop()
        except RuntimeError:
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)

        if loop.is_running():
            asyncio.ensure_future(enviar_telegram_async(mensaje))
        else:
            loop.run_until_complete(enviar_telegram_async(mensaje))
    except RuntimeError:
        asyncio.run(enviar_telegram_async(mensaje))

def enviar_correo(asunto, mensaje):
    msg = MIMEMultipart()
    msg['From'] = EMAIL_USER
    msg['To'] = EMAIL_TO
    msg['Subject'] = asunto
    msg.attach(MIMEText(mensaje, 'plain'))
    try:
        server = smtplib.SMTP(SMTP_SERVER, SMTP_PORT)
        server.starttls()
        server.login(EMAIL_USER, EMAIL_PASS)
        server.send_message(msg)
        server.quit()
        print("📧 Correo enviado.")
    except Exception as e:
        print("❌ Error al enviar correo:", e)

# === CALLBACK MQTT ===
def on_message(client, userdata, msg):
    global ultimo_alerta_telegram, ultimo_alerta_correo
    global ultimo_dht, ultimo_ldr

    try:
        payload = json.loads(msg.payload.decode())
        sensor = payload.get("sensor")
        ahora = time.time()

        bucket = BUCKETS.get(sensor)
        if not bucket:
            print(f"⚠️ Sensor desconocido: {sensor}")
            return

        punto = Point(sensor).tag("sensor", sensor).time(datetime.now(timezone.utc), WritePrecision.NS)

        if sensor == "DHT11":
            if ahora - ultimo_dht < INTERVALO_LECTURA:
                return
            ultimo_dht = ahora

            temp = payload.get("temperatura")
            humedad = payload.get("humedad")

            # Convertir a float sin importar int o float
            if temp is not None and humedad is not None:
                try:
                    temp_val = float(temp)
                    humedad_val = float(humedad)
                except (ValueError, TypeError):
                    print("❌ Error: temperatura o humedad no convertible a float.")
                    return

                punto.field("temperatura", temp_val).field("humedad", humedad_val)
                print(f"🌡️ Temp: {temp_val}°C  💧 Humedad: {humedad_val}%")

                if temp_val > 30:
                    print("⚠️ Temperatura alta detectada.")

                    if ahora - ultimo_alerta_telegram >= INTERVALO_ALERTA:
                        alerta = f"🚨 ALERTA: Temperatura alta > 30°C su temperatura actual es: ({temp_val} °C)"
                        enviar_telegram(alerta)
                        ultimo_alerta_telegram = ahora

                    if ahora - ultimo_alerta_correo >= INTERVALO_ALERTA:
                        alerta = f"🚨 ALERTA: Temperatura alta > 30° su temperatura actual es: ({temp_val} °C)"
                        enviar_correo("Alerta de Temperatura", alerta)
                        ultimo_alerta_correo = ahora

        elif sensor == "LDR":
            if ahora - ultimo_ldr < INTERVALO_LECTURA:
                return
            ultimo_ldr = ahora

            luz = payload.get("luz")
            if luz is not None:
                try:
                    luz_val = float(luz)
                except (ValueError, TypeError):
                    print("❌ Error: luz no convertible a float.")
                    return

                punto.field("luz", luz_val)
                print(f"💡 Luz: {luz_val}")

        write_api.write(bucket=bucket, org=INFLUX_ORG, record=punto)
        print(f"✅ Dato guardado en bucket {bucket}.\n")

    except Exception as e:
        print("❌ Error al procesar mensaje:", e)

# === CONEXIÓN MQTT Y BUCLE PRINCIPAL ===
mqtt_client = mqtt.Client()
mqtt_client.on_message = on_message
mqtt_client.connect(MQTT_BROKER, 1883, 60)
mqtt_client.subscribe(MQTT_TOPIC)
print("📡 Esperando mensajes MQTT...")

try:
    mqtt_client.loop_forever()
except KeyboardInterrupt:
    print("\n⏹ Finalizando...")
    mqtt_client.disconnect()
    influx.close()

