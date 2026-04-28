import customtkinter as ctk
from groq import Groq

##########################
#version2 utilisation de l'API groq pour generer les reponses
#en utiliser groq
#########################


############################
#  Configuration de l'API
############################
client = Groq(api_key="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")

############################
# Fonction de réponse
############################
def catbot_responde(user_input):
    try:
        response = client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=[
                {"role": "system", "content": "Tu es un assistant utile et amical qui répond en français."},
                {"role": "user", "content": user_input}
            ]
        )
        return response.choices[0].message.content.strip()
    except Exception as e:
        print("ERREUR API :", e)
        return "⚠️ Une erreur s'est produite lors de la génération de la réponse."

############################
# Gestion de l'envoi
############################
def send_message(event=None):
    user_message = user_input.get()
    if user_message.strip() != "":
        chat_history.configure(state="normal")
        chat_history.insert("end", f"Vous : {user_message}\n", "user")
        
        bot_response = catbot_responde(user_message)
        chat_history.insert("end", f"Chatbot : {bot_response}\n\n", "bot")
        
        chat_history.configure(state="disabled")
        chat_history.see("end")
        user_input.delete(0, "end")

############################
#  Interface graphique
############################
app = ctk.CTk()
app.geometry("500x600")
app.title("Chatbot IA")

header = ctk.CTkLabel(app, text=" Bienvenue sur mon premier chatbot !", font=("Arial", 20, "bold"))
header.pack(pady=10)

chat_history = ctk.CTkTextbox(app, width=480, height=400, state="disabled")
chat_history.tag_config("user", foreground="blue")
chat_history.tag_config("bot", foreground="black")
chat_history.pack(pady=10, padx=10, fill="both", expand=True)

user_input_frame = ctk.CTkFrame(app)
user_input_frame.pack(pady=10, padx=10, fill="x")

user_input = ctk.CTkEntry(user_input_frame, placeholder_text="Tapez votre message ici...", width=380)
user_input.pack(side="left", padx=5)

send_button = ctk.CTkButton(user_input_frame, text="Envoyer", command=send_message)
send_button.pack(side="right", padx=5)

app.bind("<Return>", send_message)
app.mainloop()
