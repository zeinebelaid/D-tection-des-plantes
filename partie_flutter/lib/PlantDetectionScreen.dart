import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:uuid/uuid.dart';

class PlantDetectionScreen extends StatefulWidget {
  const PlantDetectionScreen({super.key});

  @override
  State<PlantDetectionScreen> createState() => _PlantDetectionScreenState();
}

class _PlantDetectionScreenState extends State<PlantDetectionScreen> {
  File? _selectedImage;
  bool _isAnalyzing = false;
  bool isConnected = false;
  bool _isConnecting = false;
  Map<String, dynamic>? _analysisResult;
  final ImagePicker _picker = ImagePicker();

  final String clientId = const Uuid().v4();
  final String broker = 'broker.emqx.io'; // ✅ Broker stable
  final int port = 1883;
  late MqttServerClient client;

  StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>? _messageSubscription;
  Timer? _reconnectTimer;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    _setupMqtt();
  }

  Future<void> _setupMqtt() async {
    if (_isConnecting) return;
    setState(() => _isConnecting = true);

    try {
      client = MqttServerClient.withPort(broker, 'flutter-plant-$clientId', port);
      client.logging(on: false);
      client.keepAlivePeriod = 60;
      client.autoReconnect = true;
      client.connectTimeoutPeriod = 10000;
      client.resubscribeOnAutoReconnect = true; // ✅ Re-subscribe automatique

      client.onConnected = _onConnected;
      client.onDisconnected = _onDisconnected;
      client.onAutoReconnect = _onAutoReconnect;
      client.onAutoReconnected = _onAutoReconnected;

      final connMsg = MqttConnectMessage()
          .withClientIdentifier('flutter-plant-$clientId')
          .startClean()
          .withWillQos(MqttQos.atMostOnce);
      client.connectionMessage = connMsg;

      print('🔌 Connexion à $broker:$port...');
      await client.connect();
    } catch (e) {
      print('❌ Erreur MQTT: $e');
      setState(() {
        isConnected = false;
        _isConnecting = false;
      });
      _scheduleReconnect(); // ✅ Planifier reconnexion si échec
    }
  }

  // ✅ Callback connexion établie
  void _onConnected() {
    print('✅ MQTT Connecté à $broker');
    setState(() {
      isConnected = true;
      _isConnecting = false;
    });
    _reconnectTimer?.cancel();
    _subscribeToResponse();
  }

  // ✅ Callback déconnexion
  void _onDisconnected() {
    print('⚠️ MQTT Déconnecté');
    setState(() {
      isConnected = false;
      _isConnecting = false;
    });
    _scheduleReconnect();
  }

  // ✅ Callback avant reconnexion auto
  void _onAutoReconnect() {
    print('🔄 Reconnexion automatique en cours...');
    setState(() => _isConnecting = true);
  }

  // ✅ Callback après reconnexion auto réussie
  void _onAutoReconnected() {
    print('✅ Reconnexion automatique réussie!');
    setState(() {
      isConnected = true;
      _isConnecting = false;
    });
    _subscribeToResponse(); // ✅ Re-subscribe après reconnexion
  }

  // ✅ Planifier une reconnexion après délai
  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      print('🔄 Tentative de reconnexion...');
      _setupMqtt();
    });
  }

  void _subscribeToResponse() {
    _messageSubscription?.cancel();

    final topic = 'plant/response/$clientId';
    client.subscribe(topic, MqttQos.atLeastOnce);
    print('📡 Abonné à: $topic');

    _messageSubscription = client.updates?.listen(
          (List<MqttReceivedMessage<MqttMessage>> messages) {
        final msg = messages[0].payload as MqttPublishMessage;
        final payload =
        MqttPublishPayload.bytesToStringAsString(msg.payload.message);

        try {
          final data = jsonDecode(payload);
          print('📥 Réponse reçue: $data');

          _timeoutTimer?.cancel(); // ✅ Annuler le timeout

          if (mounted) {
            setState(() {
              _analysisResult = data;
              _isAnalyzing = false;
            });
          }
        } catch (e) {
          print('❌ Erreur parsing: $e');
          if (mounted) {
            setState(() => _isAnalyzing = false);
            _showSnackBar('Erreur de réception: $e', Colors.red);
          }
        }
      },
    );
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (photo != null) {
        setState(() {
          _selectedImage = File(photo.path);
          _analysisResult = null;
        });
      }
    } catch (e) {
      _showSnackBar('Erreur caméra: $e', Colors.red);
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _analysisResult = null;
        });
      }
    } catch (e) {
      _showSnackBar('Erreur galerie: $e', Colors.red);
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) {
      _showSnackBar('Veuillez sélectionner une image', Colors.orange);
      return;
    }
    if (!isConnected) {
      _showSnackBar('Non connecté au serveur MQTT', Colors.red);
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _analysisResult = null;
    });

    try {
      final bytes = await _selectedImage!.readAsBytes();
      final base64Image = base64Encode(bytes);

      final payload = jsonEncode({
        'clientId': clientId,
        'image': base64Image,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      final topic = 'plant/request/$clientId';
      final builder = MqttClientPayloadBuilder();
      builder.addString(payload);

      client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
      print('📤 Image envoyée sur $topic');

      // ✅ Timeout de 30 secondes avec Timer annulable
      _timeoutTimer?.cancel();
      _timeoutTimer = Timer(const Duration(seconds: 30), () {
        if (_isAnalyzing && mounted) {
          setState(() => _isAnalyzing = false);
          _showSnackBar('Timeout: Aucune réponse du serveur', Colors.red);
        }
      });
    } catch (e) {
      setState(() => _isAnalyzing = false);
      _showSnackBar('Erreur d\'envoi: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _resetAnalysis() {
    setState(() {
      _selectedImage = null;
      _analysisResult = null;
    });
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _reconnectTimer?.cancel();
    _timeoutTimer?.cancel();
    client.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détection de Plantes'),
        actions: [
          // ✅ Indicateur de connexion amélioré
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _isConnecting
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.orange,
              ),
            )
                : Icon(
              isConnected ? Icons.cloud_done : Icons.cloud_off,
              color: isConnected ? Colors.green : Colors.red,
            ),
          ),
          if (_selectedImage != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Réinitialiser',
              onPressed: _resetAnalysis,
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ✅ Bannière de statut connexion
              if (!isConnected)
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: _isConnecting
                        ? Colors.orange.withOpacity(0.15)
                        : Colors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _isConnecting ? Colors.orange : Colors.red,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isConnecting ? Icons.sync : Icons.wifi_off,
                        color: _isConnecting ? Colors.orange : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isConnecting
                            ? 'Connexion au serveur...'
                            : 'Serveur déconnecté. Reconnexion...',
                        style: TextStyle(
                          color: _isConnecting ? Colors.orange : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

              // 📸 Zone d'image
              Container(
                height: 300,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[850] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDarkMode ? Colors.grey[700]! : Colors.grey[400]!,
                    width: 2,
                  ),
                ),
                child: _selectedImage == null
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_outlined,
                        size: 80,
                        color: isDarkMode
                            ? Colors.grey[600]
                            : Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune image sélectionnée',
                        style: TextStyle(
                          color: isDarkMode
                              ? Colors.grey[400]
                              : Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
                    : ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(
                    _selectedImage!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 🎯 Boutons de sélection
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isAnalyzing ? null : _pickImageFromCamera,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Caméra'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor:
                        isDarkMode ? Colors.blue[700] : Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isAnalyzing ? null : _pickImageFromGallery,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Galerie'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor:
                        isDarkMode ? Colors.green[700] : Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 🔍 Bouton d'analyse
              ElevatedButton.icon(
                onPressed:
                (_selectedImage != null && !_isAnalyzing && isConnected)
                    ? _analyzeImage
                    : null,
                icon: _isAnalyzing
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.analytics),
                label: Text(_isAnalyzing ? 'Analyse en cours...' : 'Analyser'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor:
                  isDarkMode ? Colors.purple[700] : Colors.purple,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 📊 Résultats
              if (_analysisResult != null) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[850] : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withOpacity(isDarkMode ? 0.3 : 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.eco, color: Colors.green[600], size: 28),
                          const SizedBox(width: 12),
                          Text(
                            'Résultats de l\'analyse',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      _buildResultRow(
                        icon: Icons.local_florist,
                        label: 'Nom de la plante',
                        value: _analysisResult!['plant_name'] ?? 'Inconnu',
                        color: Colors.green,
                        isDarkMode: isDarkMode,
                      ),
                      const SizedBox(height: 16),

                      _buildResultRow(
                        icon: _analysisResult!['is_diseased'] == true
                            ? Icons.warning_amber_rounded
                            : Icons.check_circle,
                        label: 'État',
                        value: _analysisResult!['is_diseased'] == true
                            ? 'Malade'
                            : 'Saine',
                        color: _analysisResult!['is_diseased'] == true
                            ? Colors.red
                            : Colors.green,
                        isDarkMode: isDarkMode,
                      ),

                      if (_analysisResult!['is_diseased'] == true) ...[
                        const SizedBox(height: 16),
                        _buildResultRow(
                          icon: Icons.coronavirus,
                          label: 'Maladie détectée',
                          value: _analysisResult!['disease_name'] ??
                              'Non spécifiée',
                          color: Colors.orange,
                          isDarkMode: isDarkMode,
                        ),
                      ],

                      if (_analysisResult!['confidence'] != null) ...[
                        const SizedBox(height: 16),
                        _buildResultRow(
                          icon: Icons.trending_up,
                          label: 'Confiance',
                          value:
                          '${((_analysisResult!['confidence'] as num) * 100).toStringAsFixed(1)}%',
                          color: Colors.blue,
                          isDarkMode: isDarkMode,
                        ),
                        const SizedBox(height: 12),
                        // ✅ Barre de progression pour la confiance
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: (_analysisResult!['confidence'] as num)
                                .toDouble(),
                            minHeight: 10,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              (_analysisResult!['confidence'] as num) > 0.7
                                  ? Colors.green
                                  : (_analysisResult!['confidence'] as num) >
                                  0.4
                                  ? Colors.orange
                                  : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDarkMode,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}