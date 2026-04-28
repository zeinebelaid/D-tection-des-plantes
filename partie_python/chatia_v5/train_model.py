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
from tensorflow.keras.applications import MobileNetV2
import os
import json


############################
# 1️⃣ CONFIGURATION
############################
os.environ["TF_ENABLE_ONEDNN_OPTS"] = "0"
DATASET_PATH = "dataset/train"
MODEL_SAVE_PATH = "models/best_model.h5"
CLASSES_FILE = "classes.json"

IMAGE_SIZE = (224, 224)
BATCH_SIZE = 16
EPOCHS = 15

############################
# 2️⃣ CHARGER LES DONNÉES
############################
print("📂 Chargement des données...")

train_dataset = keras.preprocessing.image_dataset_from_directory(
    DATASET_PATH,
    image_size=IMAGE_SIZE,
    batch_size=BATCH_SIZE,
    label_mode='categorical',
    shuffle=True,
    seed=42,
    validation_split=0.2,
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

class_names = train_dataset.class_names
num_classes = len(class_names)

print(f"✅ {num_classes} classes trouvées: {class_names}")

with open(CLASSES_FILE, 'w') as f:
    json.dump(class_names, f, indent=2)
print(f"💾 Classes sauvegardées dans {CLASSES_FILE}")

############################
# 3️⃣ PRÉPARER LES DONNÉES
############################
print("🔧 Préparation des données...")

# ✅ FIX : MobileNetV2 veut des valeurs entre -1 et 1 (pas 0-1)
def preprocess(image, label):
    image = tf.cast(image, tf.float32)
    image = keras.applications.mobilenet_v2.preprocess_input(image)
    return image, label

train_dataset = train_dataset.map(preprocess)
validation_dataset = validation_dataset.map(preprocess)

AUTOTUNE = tf.data.AUTOTUNE
train_dataset = train_dataset.prefetch(buffer_size=AUTOTUNE)
validation_dataset = validation_dataset.prefetch(buffer_size=AUTOTUNE)

############################
# 4️⃣ CRÉER LE MODÈLE
############################
print("🧠 Création du modèle...")

# ✅ FIX : MobileNetV2 pré-entraîné sur 1.4M images → beaucoup plus précis
base_model = MobileNetV2(
    input_shape=(224, 224, 3),
    include_top=False,
    weights='imagenet'
)
base_model.trainable = False

inputs = keras.Input(shape=(224, 224, 3))
x = layers.RandomFlip("horizontal")(inputs)
x = layers.RandomRotation(0.1)(x)
x = layers.RandomZoom(0.1)(x)
x = base_model(x, training=False)
x = layers.GlobalAveragePooling2D()(x)
x = layers.Dropout(0.5)(x)
x = layers.Dense(256, activation='relu')(x)
x = layers.Dropout(0.3)(x)
outputs = layers.Dense(num_classes, activation='softmax')(x)

model = keras.Model(inputs, outputs)

############################
# 5️⃣ COMPILER LE MODÈLE
############################
print("⚙️ Compilation du modèle...")

model.compile(
    optimizer=keras.optimizers.Adam(learning_rate=1e-3),
    loss='categorical_crossentropy',
    metrics=['accuracy']
)

############################
# 6️⃣ ENTRAÎNER LE MODÈLE
############################
print("🚀 Début de l'entraînement...")
print(f"📊 Epochs: {EPOCHS}, Batch size: {BATCH_SIZE}")

checkpoint_callback = keras.callbacks.ModelCheckpoint(
    MODEL_SAVE_PATH,
    monitor='val_accuracy',
    save_best_only=True,
    verbose=1
)

early_stopping = keras.callbacks.EarlyStopping(
    monitor='val_loss',
    patience=4,
    restore_best_weights=True
)

reduce_lr = keras.callbacks.ReduceLROnPlateau(
    monitor='val_loss',
    factor=0.5,
    patience=2,
    verbose=1
)

history = model.fit(
    train_dataset,
    validation_data=validation_dataset,
    epochs=EPOCHS,
    callbacks=[checkpoint_callback, early_stopping, reduce_lr]
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
print("📌 Utilisez maintenant votre backend avec le nouveau best_model.h5")