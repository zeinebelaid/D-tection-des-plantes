import customtkinter as ctk
##########################
#version 1 moi meme entree les reponses 

#########################
###############
#fonction de réponse du bot
#################
def catbot_responde(user_input):
    #cette fonction est un dictionnaire (cle,valeur) de réponses prédéfinies
    responses={
        "bonjour":"Bonjour! Comment puis-je vous aider aujourd'hui?",
        "comment ça va?":"Je suis un programme informatique, donc je n'ai pas de sentiments, mais merci de demander!",
        "quel est ton nom?":"Je suis ChatBot, votre assistant virtuel.",
        "au revoir":"Au revoir! Passez une bonne journée!"
    }
    return responses.get(user_input .lower(),"Désolé, je ne comprends pas votre question.")
###################
####################

#fonction pour gérer l'envoi des messages
###################
def send_message(event=None):
    user_message=user_input.get()
    if user_message.strip()!="":#strip supprimer les espace au debut et a la fin deu message 
        chat_history.configure(state="normal") #permet d'activer la zone de texte pour y écrire
        chat_history.insert("end",f"vous:# {user_message}\n","user") #insertion du message utilisateur avec le style "user"
        bot_response=catbot_responde(user_message)
        chat_history.insert("end",f"chatbot:# {bot_response}\n","bot")
        chat_history.configure(state="disabled") #désactivation de la zone de texte pour empêcher la modification par l'utilisateur
        chat_history.see("end") #fait défiler la zone de texte jusqu'à la
        user_input.delete(0,"end") #efface le champ de saisie après l'envoi du message

#configure l'interface graphique
app=ctk.CTk()#création de la fenêtre principale
app.geometry("500x600") #définition de la taille de la fenêtre
app.title("chatbot IA ") #titre de la fenêtre

#entête de l'application
header=ctk.CTkLabel(app,text="bienvenue sur mon premier chatbot ",font=("arial",24,"bold"))
header.pack(pady=10)  #ajout de l'entête à la fenêtre avec un espacement vertical


#zone de texte pour afficher les messages
chat_history=ctk.CTkTextbox(app,width=480,height=400,state="disabled")
chat_history.tag_config("user",foreground="blue")  #configuration du style pour les messages utilisateur
chat_history.tag_config("bot",foreground="green")  #configuration du style pour les messages du bot
chat_history.pack(pady=10,padx=10,fill="both",expand= True)   #ajout de la zone de texte à la fenêtre avec un espacement et remplissage


#champ de saisie pour l'utilisateur
user_input_frame=ctk.CTkFrame(app)
user_input_frame.pack(pady=10,padx=10,fill="x")  #fill=x occuper tout le largeur disponible dans le contenaire parent  # ajout du cadre de saisie à la fenêtre avec un espacement et remplissage
user_input=ctk.CTkEntry(user_input_frame,placeholder_text="Tapez votre message ici...",width=380)
user_input.pack(side="left",padx=5)#sied=positionnement à gauche

send_button=ctk.CTkButton(user_input_frame,text="Envoyer",command=send_message)
send_button.pack(side="right",padx=5) #positionnement à droite

        
#associer la touche "Entrée" au champ de saisie pour envoyer le message
app.bind("<Return>",send_message)
######################################
app.mainloop()

    