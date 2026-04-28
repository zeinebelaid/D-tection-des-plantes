import paho.mqtt.client as mqtt
import time
import json

# Configuration du broker MQTT
BROKER = "broker.hivemq.com"  # Broker public gratuit
PORT = 1883
TOPIC_PUBLISH = "flutter/python/response"
TOPIC_SUBSCRIBE = "flutter/python/request"

# Callback quand la connexion est établie
def on_connect(client, userdata, flags, rc):
    print(f"Connecté au broker avec le code: {rc}")
    client.subscribe(TOPIC_SUBSCRIBE)
    print(f"Souscrit au topic: {TOPIC_SUBSCRIBE}")

# Callback quand un message est reçu
def on_message(client, userdata, msg):
    print(f"Message reçu sur {msg.topic}: {msg.payload.decode()}")
    
    try:
        data = json.loads(msg.payload.decode())
        message = data.get('message', '')
        
        # Traiter le message et envoyer une réponse
        response = {
            'response': f"Python a reçu: {message}",
            'timestamp': time.time()
        }
        
        client.publish(TOPIC_PUBLISH, json.dumps(response))
        print(f"Réponse envoyée: {response}")
        
    except json.JSONDecodeError:
        print("Erreur: message non-JSON reçu")

# Créer le client MQTT
client = mqtt.Client()
client.on_connect = on_connect
client.on_message = on_message

# Se connecter au broker
print(f"Connexion au broker {BROKER}...")
client.connect(BROKER, PORT, 60)

# Démarrer la boucle
client.loop_forever()