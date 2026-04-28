##########################
# version4 - Google Gemini avec images (CORRIGÉ)
#########################
import customtkinter as ctk
import google.generativeai as genai
from tkinter import filedialog
from PIL import Image
import io

############################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
# Configuration de l'API Gemini
############################
genai.configure(api_key="AIzaSyBO-LygVfC4kd0uTtwMh3HmZdzNTGuQGU0")
model = genai.GenerativeModel('gemini-1.5-flash')

selected_image_path = None

############################
# Fonction de réponse
############################
def catbot_responde(user_input, image_path=None):
    try:
        if image_path:
            # Ouvrir l'image avec PIL
            img = Image.open(image_path)
            # Envoyer le texte + l'image à Gemini
            response = model.generate_content([user_input, img])
        else:
            # Envoyer seulement le texte
            response = model.generate_content(user_input)
        
        return response.text
    except Exception as e:
        print("ERREUR API :", e)
        return "⚠️ Une erreur s'est produite lors de la génération de la réponse."

############################
# Gestion de l'envoi
############################
def send_message(event=None):
    global selected_image_path
    user_message = user_input.get()
    
    if user_message.strip() != "" or selected_image_path:
        chat_history.configure(state="normal")
        
        # Afficher le message de l'utilisateur
        if selected_image_path:
            chat_history.insert("end", f"Vous : {user_message} [📷 Image jointe]\n", "user")
        else:
            chat_history.insert("end", f"Vous : {user_message}\n", "user")
        
        # Obtenir la réponse du bot
        bot_response = catbot_responde(user_message, selected_image_path)
        chat_history.insert("end", f"Chatbot : {bot_response}\n\n", "bot")
        
        chat_history.configure(state="disabled")
        chat_history.see("end")
        user_input.delete(0, "end")
        
        # Réinitialiser l'image après l'envoi
        selected_image_path = None
        image_preview.configure(text="Aucune image")

############################
# Fonction pour télécharger une image
############################
def upload_image():
    global selected_image_path
    file_path = filedialog.askopenfilename(
        title="Sélectionner une image", 
        filetypes=[("Fichiers Image", "*.png;*.jpg;*.jpeg;*.bmp;*.gif")]
    )
    if file_path:
        selected_image_path = file_path
        # Afficher le nom du fichier au lieu de l'aperçu
        filename = file_path.split("/")[-1].split("\\")[-1]
        image_preview.configure(text=f"📷 {filename[:20]}...")

############################
# Interface graphique
############################
app = ctk.CTk()
app.geometry("600x700")
app.title("Chatbot IA avec Vision")

header = ctk.CTkLabel(app, text="🤖 Chatbot avec Vision (Gemini)", font=("Arial", 20, "bold"))
header.pack(pady=10)

chat_history = ctk.CTkTextbox(app, width=580, height=400, state="disabled")
chat_history.tag_config("user", foreground="blue")
chat_history.tag_config("bot", foreground="black")
chat_history.pack(pady=10, padx=10, fill="both", expand=True)

# Frame pour l'aperçu de l'image
image_frame = ctk.CTkFrame(app, height=120)
image_frame.pack(pady=5, padx=10, fill="x")

image_preview = ctk.CTkLabel(
    image_frame, 
    text="Aucune image", 
    width=200, 
    height=60,
    corner_radius=8,
    fg_color=("gray85", "gray25")
)
image_preview.pack(side="left", padx=10, pady=10)

upload_button = ctk.CTkButton(image_frame, text="📷 Joindre une image", command=upload_image)
upload_button.pack(side="left", padx=10, pady=10)

# Frame pour l'entrée utilisateur
user_input_frame = ctk.CTkFrame(app)
user_input_frame.pack(pady=10, padx=10, fill="x")

user_input = ctk.CTkEntry(user_input_frame, placeholder_text="Tapez votre message ici...", width=460)
user_input.pack(side="left", padx=5)

send_button = ctk.CTkButton(user_input_frame, text="Envoyer", command=send_message)
send_button.pack(side="right", padx=5)

app.bind("<Return>", send_message)
app.mainloop()