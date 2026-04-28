import json
import time
import paho.mqtt.client as mqtt
import uuid
from groq import Groq

############################
#  Configuration de l'API Groq
############################
GROQ_API_KEY = "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"
client_groq = Groq(api_key=GROQ_API_KEY)

############################
# Configuration MQTT
############################
MQTT_BROKER = "test.mosquitto.org"
MQTT_PORT = 1883
MQTT_KEEPALIVE = 60

############################
# Fonction de réponse Groq
############################
def catbot_responde(user_input):
    """Génère une réponse via l'API Groq"""
    try:
        response = client_groq.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=[
                {"role": "system", "content": "Tu es un assistant utile et amical qui répond en français."},
                {"role": "user", "content": user_input}
            ]
        )
        return response.choices[0].message.content.strip()
    except Exception as e:
        print(f"❌ ERREUR API Groq: {e}")
        return "⚠️ Une erreur s'est produite lors de la génération de la réponse."

############################
# Callbacks MQTT
############################
def on_connect(client, userdata, flags, rc):
    """Appelé lors de la connexion au broker MQTT"""
    if rc == 0:
        print("✅ Connecté au broker MQTT")
        client.subscribe("chat/request/#")
        print("📡 Abonné à chat/request/#")
    else:
        print(f"❌ Échec de connexion, code: {rc}")

def on_message(client, userdata, msg):
    """Appelé lorsqu'un message est reçu"""
    try:
        payload = msg.payload.decode('utf-8')
        data = json.loads(payload)
        print(f"📥 Message reçu sur {msg.topic}: {data}")
        
        user_message = data.get("message", "")
        client_id = data.get("clientId")
        
        if not client_id:
            print("⚠️ Message sans clientId - ignoré")
            return
        
        if not user_message:
            print("⚠️ Message vide - ignoré")
            return
        
        print(f"💬 Traitement du message de {client_id}: {user_message}")
        
        # Générer la réponse via Groq
        bot_reply = catbot_responde(user_message)
        print(f"🤖 Réponse générée: {bot_reply[:50]}...")
        
        # Préparer la réponse
        response_payload = json.dumps({
            "reply": bot_reply,
            "clientId": client_id,
            "timestamp": int(time.time())
        })
        
        # Publier sur le topic de réponse spécifique au client
        response_topic = f"chat/response/{client_id}"
        result = client.publish(response_topic, response_payload, qos=1)
        
        if result.rc == mqtt.MQTT_ERR_SUCCESS:
            print(f"✅ Réponse publiée sur {response_topic}")
        else:
            print(f"❌ Échec de publication: {result.rc}")
            
    except json.JSONDecodeError as e:
        print(f"❌ Erreur décodage JSON: {e}")
    except Exception as e:
        print(f"❌ Erreur on_message: {e}")

def on_disconnect(client, userdata, rc):
    """Appelé lors de la déconnexion"""
    if rc != 0:
        print(f"⚠️ Déconnexion inattendue, code: {rc}")
    else:
        print("👋 Déconnecté du broker MQTT")

############################
# Configuration et démarrage
############################
def main():
    if not GROQ_API_KEY:
        print("❌ ERREUR: Veuillez configurer GROQ_API_KEY")
        return
    
    mqtt_client = mqtt.Client(
        client_id=f"python-bot-{uuid.uuid4()}", 
        clean_session=True
    )
    
    mqtt_client.on_connect = on_connect
    mqtt_client.on_message = on_message
    mqtt_client.on_disconnect = on_disconnect
    
    try:
        print(f"🔌 Connexion au broker {MQTT_BROKER}:{MQTT_PORT}...")
        mqtt_client.connect(MQTT_BROKER, MQTT_PORT, MQTT_KEEPALIVE)
        
        print("🚀 Serveur chatbot démarré - En attente de messages...")
        mqtt_client.loop_forever()
        
    except KeyboardInterrupt:
        print("\n⏹️  Arrêt du serveur...")
        mqtt_client.disconnect()
    except Exception as e:
        print(f"❌ Erreur de connexion: {e}")

if __name__ == "__main__":
    main()