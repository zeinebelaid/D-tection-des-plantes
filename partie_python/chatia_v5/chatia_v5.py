import json
import base64
import io
import numpy as np
import paho.mqtt.client as mqtt
from paho.mqtt.client import CallbackAPIVersion
import uuid
import time
from PIL import Image
from tensorflow import keras
from groq import Groq

############################
# CONFIGURATION
############################

MQTT_BROKER = "broker.emqx.io"
MQTT_PORT = 1883
MQTT_KEEPALIVE = 60

MODEL_PATH = "models/best_model.h5"
CLASSES_FILE = "classes.json"

GROQ_API_KEY = "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"
client_groq = Groq(api_key=GROQ_API_KEY)

print("🔄 Chargement du modèle...")
try:
    model = keras.models.load_model(MODEL_PATH)
    print("✅ Modèle chargé avec succès!")

    with open(CLASSES_FILE, 'r') as f:
        class_names = json.load(f)
    print(f"✅ {len(class_names)} classes chargées: {class_names}")

except Exception as e:
    print(f"❌ Erreur de chargement: {e}")
    print("⚠️  Lancez d'abord 'train_model.py' pour entraîner le modèle!")
    exit(1)

############################
# FONCTION CHATBOT GROQ
############################
def chatbot_response(user_input):
    try:
        response = client_groq.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=[
                {
                    "role": "system",
                    "content": """Tu es un expert en agriculture et santé des plantes. 
                    Réponds en français de manière utile et précise.
                    Si on te pose des questions sur les maladies des plantes, donne des conseils pratiques.
                    Sois amical et professionnel."""
                }, {"role": "user", "content": user_input}
            ],
            temperature=0.7,
            max_tokens=1024
        )
        return response.choices[0].message.content.strip()
    except Exception as e:
        print(f'❌ ERREUR API Groq: {e}')
        return "⚠️ Désolé, je rencontre un problème technique. Veuillez réessayer."

############################
# FONCTION D'ANALYSE D'IMAGE
############################
def analyze_plant_image(image_data):
    try:
        image_bytes = base64.b64decode(image_data)
        image = Image.open(io.BytesIO(image_bytes))

        if image.mode != 'RGB':
            image = image.convert('RGB')

        image = image.resize((224, 224))
        img_array = np.array(image)
        img_array = img_array / 255.0
        img_array = np.expand_dims(img_array, axis=0)

        print(f"📸 Image préparée: {img_array.shape}")

        predictions = model.predict(img_array, verbose=0)
        predicted_index = np.argmax(predictions[0])
        confidence = float(predictions[0][predicted_index])
        predicted_class = class_names[predicted_index]

        print(f"🔍 Prédiction: {predicted_class} ({confidence*100:.2f}%)")

        parts = predicted_class.split('_')

        if len(parts) >= 2:
            plant_name = parts[0].replace('_', ' ').title()
            disease_part = '_'.join(parts[1:])

            if 'healthy' in disease_part.lower():
                is_diseased = False
                disease_name = None
            else:
                is_diseased = True
                disease_name = disease_part.replace('_', ' ').title()
        else:
            plant_name = predicted_class.replace('_', ' ').title()
            is_diseased = False
            disease_name = None

        return {
            "plant_name": plant_name,
            "is_diseased": is_diseased,
            "disease_name": disease_name,
            "confidence": confidence,
            "raw_class": predicted_class,
            "status": "success"
        }

    except Exception as e:
        print(f"❌ Erreur analyse: {e}")
        return {
            "status": "error",
            "message": str(e)
        }

############################
# CALLBACKS MQTT
############################
def on_connect(client, userdata, flags, reason_code, properties):
    if reason_code == 0:
        print("✅ Connecté au broker MQTT")
        client.subscribe("plant/request/#", qos=1)
        client.subscribe("chat/request/#", qos=1)
        print("📡 Abonné à plant/request/# et chat/request/#")
    else:
        print(f"❌ Échec de connexion, code: {reason_code}")

def on_message(client, userdata, msg):
    try:
        payload = msg.payload.decode('utf-8')
        print(f"📥 Message reçu sur {msg.topic}: {payload[:100]}...")

        data = json.loads(payload)

        # 🌿 TRAITEMENT DES IMAGES DE PLANTES
        if msg.topic.startswith("plant/request/"):
            client_id = data.get("clientId")
            image_base64 = data.get("image")

            if not client_id or not image_base64:
                print("⚠️ Données d'image manquantes - ignoré")
                return

            print(f"\n{'='*60}")
            print(f"📥 Analyse d'image - Client: {client_id}")
            print(f"{'='*60}")

            analysis_result = analyze_plant_image(image_base64)

            if analysis_result.get("status") == "success":
                print(f"✅ Plante: {analysis_result['plant_name']}")
                print(f"{'✅' if not analysis_result['is_diseased'] else '⚠️'} État: {'Saine' if not analysis_result['is_diseased'] else 'Malade'}")
                if analysis_result['is_diseased']:
                    print(f"🦠 Maladie: {analysis_result['disease_name']}")
            else:
                print(f"❌ Erreur: {analysis_result.get('message')}")

            response_payload = json.dumps({
                "clientId": client_id,
                "plant_name": analysis_result.get("plant_name"),
                "is_diseased": analysis_result.get("is_diseased"),
                "disease_name": analysis_result.get("disease_name"),
                "confidence": analysis_result.get("confidence"),
                "status": analysis_result.get("status", "success"),
                "message": analysis_result.get("message", "Analyse complétée"),
                "timestamp": int(time.time())
            })

            # ✅ CORRECTION : le topic de réponse plante était déjà correct côté serveur.
            # La correction principale est dans le client Flutter qui écoutait 'chat/response/'
            # au lieu de 'plant/response/...'.
            response_topic = f"plant/response/{client_id}"
            result = client.publish(response_topic, response_payload, qos=1)

            if result.rc == mqtt.MQTT_ERR_SUCCESS:
                print(f"✅ Réponse envoyée sur {response_topic}")
            else:
                print(f"❌ Échec d'envoi: {result.rc}")

            print(f"{'='*60}\n")

        # 💬 TRAITEMENT DES MESSAGES CHATBOT
        elif msg.topic.startswith("chat/request/"):
            user_message = data.get("message", "")
            client_id = data.get("clientId")

            if not client_id:
                print("⚠️ Message sans clientId - ignoré")
                return

            if not user_message:
                print("⚠️ Message vide - ignoré")
                return

            print(f"\n{'='*60}")
            print(f"💬 Message chat de {client_id}: {user_message}")
            print(f"{'='*60}")

            print("🔄 Génération de la réponse via Groq...")
            bot_reply = chatbot_response(user_message)
            print(f"🤖 Réponse: {bot_reply}")

            response_payload = json.dumps({
                "reply": bot_reply,
                "clientId": client_id,
                "timestamp": int(time.time())
            })

            response_topic = f"chat/response/{client_id}"
            result = client.publish(response_topic, response_payload, qos=1)

            if result.rc == mqtt.MQTT_ERR_SUCCESS:
                print(f"✅ Réponse chat publiée sur {response_topic}")
            else:
                print(f"❌ Échec de publication chat: {result.rc}")

            print(f"{'='*60}\n")

    except json.JSONDecodeError as e:
        print(f"❌ Erreur JSON: {e}")
    except Exception as e:
        print(f"❌ Erreur dans on_message: {e}")

def on_disconnect(client, userdata, flags, reason_code, properties):
    print(f"⚠️ Déconnecté du broker, code: {reason_code}")
    if reason_code != 0:
        print("🔄 Tentative de reconnexion dans 5 secondes...")
        time.sleep(5)
        try:
            client.reconnect()
            print("✅ Reconnexion réussie!")
        except Exception as e:
            print(f"❌ Reconnexion échouée: {e}")

############################
# DÉMARRAGE
############################
def main():
    if not GROQ_API_KEY or GROQ_API_KEY == "votre_cle_api_groq_ici":
        print("❌ ERREUR: Veuillez configurer une clé API Groq valide")
        return

    mqtt_client = mqtt.Client(
        client_id=f"python-plant-ai-{uuid.uuid4()}",
        clean_session=True,
        callback_api_version=CallbackAPIVersion.VERSION2
    )

    mqtt_client.on_connect = on_connect
    mqtt_client.on_message = on_message
    mqtt_client.on_disconnect = on_disconnect

    mqtt_client.reconnect_delay_set(min_delay=1, max_delay=30)

    while True:
        try:
            print(f"\n🔌 Connexion au broker {MQTT_BROKER}:{MQTT_PORT}...")
            mqtt_client.connect(MQTT_BROKER, MQTT_PORT, MQTT_KEEPALIVE)

            print("🚀 Serveur démarré!")
            print("🧠 Modèle IA prêt")
            print("💬 Chatbot Groq activé")
            print("📸 En attente de messages...\n")

            mqtt_client.loop_forever(retry_first_connection=True)

        except KeyboardInterrupt:
            print("\n⏹️ Arrêt du serveur...")
            mqtt_client.disconnect()
            break
        except Exception as e:
            print(f"❌ Erreur: {e}")
            print("🔄 Nouvelle tentative dans 10 secondes...")
            time.sleep(10)

if __name__ == "__main__":
    main()