"""
🌿 ENTRAÎNEMENT DU MODÈLE DE DÉTECTION DE PLANTES
Script simple et clair pour entraîner un modèle de classification

STRUCTURE DU DATASET KAGGLE :
dataset/
    ├── train/
    │   ├── Tomato_healthy/
    │   │   ├── image1.jpg
    │   │   ├── image2.jpg
    │   ├── Tomato_late_blight/
    │   │   ├── image1.jpg
    │   ├── Potato_early_blight/
    │   └── ...
    └── test/
        └── (même structure)
"""

import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers
import os
import json

############################
# 1️⃣ CONFIGURATION
############################
# 🔧 CHANGEZ CES CHEMINS
DATASET_PATH = "dataset/train"  # Dossier de votre dataset Kaggle
MODEL_SAVE_PATH = "best_model.h5"  # Où sauvegarder le modèle
CLASSES_FILE = "classes.json"  # Liste des classes

# Paramètres d'entraînement
IMAGE_SIZE = (224, 224)  # Taille des images
BATCH_SIZE = 16  # Nombre d'images par batch
EPOCHS = 20  # Nombre d'époques (augmentez pour mieux apprendre)

############################
# 2️⃣ CHARGER LES DONNÉES
############################
print("📂 Chargement des données...")

# Charger automatiquement les images depuis les dossiers
train_dataset = keras.preprocessing.image_dataset_from_directory(
    DATASET_PATH,
    image_size=IMAGE_SIZE,
    batch_size=BATCH_SIZE,
    label_mode='categorical',  # Pour plusieurs classes
    shuffle=True,
    seed=42,
    validation_split=0.2,  # 20% pour validation
    subset='training'
)

validation_dataset = keras.preprocessing.image_dataset_from_directory(
    DATASET_PATH,
    image_size=IMAGE_SIZE,
    batch_size=BATCH_SIZE,
    label_mode='categorical',
    shuffle=True,
    seed=42,
    validation_split=0.2,
    subset='validation'
)

# Récupérer les noms des classes
class_names = train_dataset.class_names
num_classes = len(class_names)

print(f"✅ {num_classes} classes trouvées: {class_names}")

# Sauvegarder les noms des classes
with open(CLASSES_FILE, 'w') as f:
    json.dump(class_names, f, indent=2)
print(f"💾 Classes sauvegardées dans {CLASSES_FILE}")

############################
# 3️⃣ PRÉPARER LES DONNÉES
############################
print("🔧 Préparation des données...")

# Normaliser les pixels (0-255 -> 0-1)
normalization_layer = layers.Rescaling(1./255)

# Appliquer la normalisation
train_dataset = train_dataset.map(lambda x, y: (normalization_layer(x), y))
validation_dataset = validation_dataset.map(lambda x, y: (normalization_layer(x), y))

# Optimiser les performances
AUTOTUNE = tf.data.AUTOTUNE
train_dataset = train_dataset.cache().prefetch(buffer_size=AUTOTUNE)
validation_dataset = validation_dataset.cache().prefetch(buffer_size=AUTOTUNE)

############################
# 4️⃣ CRÉER LE MODÈLE
############################
print("🧠 Création du modèle...")

model = keras.Sequential([
    # Augmentation des données (pour mieux généraliser)
    layers.RandomFlip("horizontal"),
    layers.RandomRotation(0.1),
    layers.RandomZoom(0.1),

    # Couches de convolution (extraction de features)
    layers.Conv2D(32, (3, 3), activation='relu', input_shape=(224, 224, 3)),
    layers.MaxPooling2D((2, 2)),

    layers.Conv2D(64, (3, 3), activation='relu'),
    layers.MaxPooling2D((2, 2)),

    layers.Conv2D(128, (3, 3), activation='relu'),
    layers.MaxPooling2D((2, 2)),

    layers.Conv2D(128, (3, 3), activation='relu'),
    layers.MaxPooling2D((2, 2)),

    # Aplatir et classifier
    layers.Flatten(),
    layers.Dropout(0.5),  # Éviter le surapprentissage
    layers.Dense(256, activation='relu'),
    layers.Dropout(0.5),
    layers.Dense(num_classes, activation='softmax')  # Sortie: probabilités par classe
])

# Afficher l'architecture

############################
# 5️⃣ COMPILER LE MODÈLE
############################
print("⚙️ Compilation du modèle...")

model.compile(
    optimizer='adam',  # Algorithme d'optimisation
    loss='categorical_crossentropy',  # Fonction de perte
    metrics=['accuracy']  # Métrique à surveiller
)

############################
# 6️⃣ ENTRAÎNER LE MODÈLE
############################
print("🚀 Début de l'entraînement...")
print(f"📊 Epochs: {EPOCHS}, Batch size: {BATCH_SIZE}")

# Callback pour sauvegarder le meilleur modèle
checkpoint_callback = keras.callbacks.ModelCheckpoint(
    'best_model.h5',
    monitor='val_accuracy',
    save_best_only=True,
    verbose=1
)

# Early stopping (arrêter si plus d'amélioration)
early_stopping = keras.callbacks.EarlyStopping(
    monitor='val_loss',
    patience=3,
    restore_best_weights=True
)

# Entraîner
history = model.fit(
    train_dataset,
    validation_data=validation_dataset,
    epochs=EPOCHS,
    callbacks=[checkpoint_callback, early_stopping]
)

############################
# 7️⃣ SAUVEGARDER LE MODÈLE
############################
print(f"💾 Sauvegarde du modèle dans {MODEL_SAVE_PATH}...")
model.save(MODEL_SAVE_PATH)
print("✅ Modèle sauvegardé avec succès!")

############################
# 8️⃣ AFFICHER LES RÉSULTATS
############################
final_train_acc = history.history['accuracy'][-1]
final_val_acc = history.history['val_accuracy'][-1]

print("\n" + "="*50)
print("📊 RÉSULTATS FINAUX")
print("="*50)
print(f"✅ Précision entraînement: {final_train_acc*100:.2f}%")
print(f"✅ Précision validation: {final_val_acc*100:.2f}%")
print(f"📁 Modèle sauvegardé: {MODEL_SAVE_PATH}")
print(f"📁 Classes sauvegardées: {CLASSES_FILE}")
print("="*50)

print("\n🎉 Entraînement terminé!")
print("📌 Utilisez maintenant 'plant_detection_backend_with_model.py'")