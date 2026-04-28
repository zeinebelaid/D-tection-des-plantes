import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:uuid/uuid.dart';

class Chatbot_Screen extends StatefulWidget {
  const Chatbot_Screen({super.key});

  @override
  State<Chatbot_Screen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<Chatbot_Screen> {
  final List<Map<String, String>> messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool isConnected = false;
  bool isConnecting = false;

  final String clientId = const Uuid().v4();
  final String broker = 'broker.emqx.io'; // ✅ Broker stable
  final int port = 1883;
  late MqttServerClient client;

  StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>? _messageSubscription;
  Timer? _reconnectTimer;

  @override
  void initState() {
    super.initState();
    _setupMqtt();
  }

  // ✅ Setup MQTT robuste
  Future<void> _setupMqtt() async {
    if (isConnecting) return;

    setState(() => isConnecting = true);

    try {
      client = MqttServerClient.withPort(broker, 'flutter-chat-$clientId', port);
      client.logging(on: false);
      client.keepAlivePeriod = 60;
      client.autoReconnect = true;
      client.resubscribeOnAutoReconnect = true; // ✅ Re-subscribe auto
      client.connectTimeoutPeriod = 10000;

      client.onConnected = _onConnected;
      client.onDisconnected = _onDisconnected;
      client.onAutoReconnect = _onAutoReconnect;
      client.onAutoReconnected = _onAutoReconnected;

      client.onSubscribed = (String topic) {
        print('✅ Abonné à: $topic');
      };

      final connMsg = MqttConnectMessage()
          .withClientIdentifier('flutter-chat-$clientId')
          .startClean()
          .withWillQos(MqttQos.atMostOnce);
      client.connectionMessage = connMsg;

      print('🔌 Connexion à $broker:$port...');
      await client.connect();

    } catch (e) {
      print('❌ Erreur setupMqtt: $e');
      if (mounted) {
        setState(() {
          isConnecting = false;
          isConnected = false;
        });
        _addSystemMessage('❌ Erreur de connexion. Nouvelle tentative dans 5s...');
        _scheduleReconnect();
      }
    }
  }

  // ✅ Connexion établie
  void _onConnected() {
    print('✅ MQTT Connecté à $broker');
    _reconnectTimer?.cancel();

    if (mounted) {
      setState(() {
        isConnected = true;
        isConnecting = false;
      });
    }

    _subscribeToResponse();
    _addSystemMessage('✅ Connecté au serveur');
  }

  // ✅ Déconnexion
  void _onDisconnected() {
    print('⚠️ MQTT Déconnecté');
    _messageSubscription?.cancel();
    _messageSubscription = null;

    if (mounted) {
      setState(() {
        isConnected = false;
        isConnecting = false;
      });
      _addSystemMessage('⚠️ Déconnecté. Reconnexion en cours...');
      _scheduleReconnect();
    }
  }

  // ✅ Avant reconnexion auto
  void _onAutoReconnect() {
    print('🔄 Reconnexion automatique...');
    if (mounted) setState(() => isConnecting = true);
  }

  // ✅ Après reconnexion auto réussie
  void _onAutoReconnected() {
    print('✅ Reconnexion automatique réussie!');
    _reconnectTimer?.cancel();

    if (mounted) {
      setState(() {
        isConnected = true;
        isConnecting = false;
      });
      _addSystemMessage('✅ Reconnecté au serveur');
    }

    _subscribeToResponse(); // ✅ Re-subscribe
  }

  // ✅ Planifier reconnexion manuelle
  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      print('🔄 Tentative de reconnexion...');
      _setupMqtt();
    });
  }

  // ✅ Subscribe au topic de réponse
  void _subscribeToResponse() {
    _messageSubscription?.cancel();

    final topic = 'chat/response/$clientId';
    client.subscribe(topic, MqttQos.atLeastOnce);
    print('📡 Abonné à: $topic');

    _messageSubscription = client.updates?.listen(
          (List<MqttReceivedMessage<MqttMessage>> messages) {
        final msg = messages[0].payload as MqttPublishMessage;
        final payload =
        MqttPublishPayload.bytesToStringAsString(msg.payload.message);

        try {
          final data = jsonDecode(payload);
          final reply = data['reply'] ?? '';
          print('💬 Réponse bot: $reply');

          if (mounted) {
            setState(() {
              this.messages.add({'from': 'bot', 'text': reply});
            });
            _scrollToBottom();
          }
        } catch (e) {
          print('⚠️ Erreur parsing réponse: $e');
        }
      },
      onError: (dynamic error) {
        print('⚠️ Erreur stream: $error');
      },
    );
  }

  // ✅ Envoyer un message
  void sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    if (!isConnected ||
        client.connectionStatus?.state != MqttConnectionState.connected) {
      _showSnackBar('Non connecté au serveur MQTT', Colors.red);
      return;
    }

    setState(() {
      messages.add({'from': 'user', 'text': text});
    });
    _controller.clear();
    _scrollToBottom();

    final payload = jsonEncode({
      'message': text,
      'clientId': clientId,
    });

    final topic = 'chat/request/$clientId';
    final builder = MqttClientPayloadBuilder();
    builder.addString(payload);

    try {
      client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
      print('📤 Message envoyé sur $topic');
    } catch (e) {
      print('❌ Erreur envoi: $e');
      _addSystemMessage('❌ Erreur d\'envoi: $e');
      setState(() => messages.removeLast());
    }
  }

  // ✅ Scroll automatique vers le bas
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _addSystemMessage(String text) {
    if (mounted) {
      setState(() => messages.add({'from': 'system', 'text': text}));
      _scrollToBottom();
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

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _reconnectTimer?.cancel();
    _scrollController.dispose();
    _controller.dispose();
    client.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chatbot Plantes 🌿'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: isConnecting
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
        ],
      ),
      body: Column(
        children: [
          // ✅ Bannière statut connexion
          if (!isConnected)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: isConnecting
                  ? Colors.orange.withOpacity(0.15)
                  : Colors.red.withOpacity(0.15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isConnecting ? Icons.sync : Icons.wifi_off,
                    size: 16,
                    color: isConnecting ? Colors.orange : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isConnecting
                        ? 'Connexion au serveur...'
                        : 'Déconnecté — Reconnexion dans 5s...',
                    style: TextStyle(
                      color: isConnecting ? Colors.orange : Colors.red,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // ✅ Liste des messages
          Expanded(
            child: messages.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: isDarkMode
                        ? Colors.grey[700]
                        : Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Posez une question sur vos plantes !',
                    style: TextStyle(
                      color: isDarkMode
                          ? Colors.grey[500]
                          : Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              controller: _scrollController,
              itemCount: messages.length,
              padding: const EdgeInsets.all(8),
              itemBuilder: (_, i) {
                final m = messages[i];
                final isUser = m['from'] == 'user';
                final isSystem = m['from'] == 'system';

                // Message système
                if (isSystem) {
                  return Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 16),
                      padding: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.blue[900]?.withOpacity(0.3)
                            : Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDarkMode
                              ? Colors.blue[700]!
                              : Colors.blue.shade200,
                        ),
                      ),
                      child: Text(
                        m['text'] ?? '',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDarkMode
                              ? Colors.blue[200]
                              : Colors.blue[900],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                // Message user / bot
                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                        vertical: 4, horizontal: 8),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                      maxWidth:
                      MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: isUser
                          ? (isDarkMode
                          ? Colors.blue[700]
                          : Colors.blue[500])
                          : (isDarkMode
                          ? Colors.grey[800]
                          : Colors.grey[200]),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 16),
                      ),
                    ),
                    child: Text(
                      m['text'] ?? '',
                      style: TextStyle(
                        color: isUser
                            ? Colors.white
                            : (isDarkMode
                            ? Colors.white
                            : Colors.black87),
                        fontSize: 15,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ✅ Zone de saisie
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[850] : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color:
                    Colors.black.withOpacity(isDarkMode ? 0.3 : 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: isConnected,
                      maxLines: null, // ✅ Multi-ligne
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        hintText: isConnected
                            ? 'Tapez votre message...'
                            : 'Connexion en cours...',
                        hintStyle: TextStyle(
                          color: isDarkMode
                              ? Colors.grey[500]
                              : Colors.grey[500],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: isDarkMode
                            ? Colors.grey[800]
                            : Colors.grey[100],
                      ),
                      onSubmitted: (_) => sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // ✅ Bouton envoi
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isConnected
                          ? (isDarkMode ? Colors.blue[600] : Colors.blue)
                          : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: isConnected ? sendMessage : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}