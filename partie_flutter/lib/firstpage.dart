import 'package:chaatbot_detection/prochat.dart';
import 'package:chaatbot_detection/sensor.dart';
import 'package:chaatbot_detection/ui/screens/signing/signin_page.dart';
import 'package:flutter/material.dart';
import './chatbot_screen.dart';
import './PlantDetectionScreen.dart';

// Firebase Auth
import 'package:firebase_auth/firebase_auth.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Main Screen',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[900],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[850],
          foregroundColor: Colors.white,
        ),
      ),
      themeMode: _themeMode,
      home: Homepage(
        onThemeToggle: _toggleTheme,
        isDarkMode: _themeMode == ThemeMode.dark,
      ),
    );
  }
}

class Homepage extends StatelessWidget {
  final VoidCallback onThemeToggle;
  final bool isDarkMode;
  const Homepage({
    super.key,
    required this.onThemeToggle,
    required this.isDarkMode,
  });

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SignIn()),
      (route) => false,
    );
  }

  // OPTION A: AlertDialog selector (compact)
  Future<void> _chooseChatDialog(BuildContext context) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Choisir le chat'),
        content: const Text('Sélectionnez un mode de conversation'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'chatbot'),
            child: const Text('Chatbot'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'Global Chat'),
            child: const Text('ProChat'),
          ),
        ],
      ),
    ); // returns 'chatbot' | 'prochat' | null [web:24][web:43]
    if (!context.mounted) return;
    if (choice == 'chatbot') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const Chatbot_Screen()),
      ); // [web:10]
    } else if (choice == 'prochat') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const GeminiChatScreen()),
      ); // [web:10]
    }
  }

  // OPTION B: Modal Bottom Sheet (touch-friendly)
  Future<void> _chooseChatSheet(BuildContext context) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.smart_toy),
              title: const Text('Chatbot'),
              subtitle: const Text('Assistant standard'),
              onTap: () => Navigator.pop(ctx, 'chatbot'),
            ),
            ListTile(
              leading: const Icon(Icons.workspace_premium),
              title: const Text('ProChat'),
              subtitle: const Text('Version avancée'),
              onTap: () => Navigator.pop(ctx, 'prochat'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ); // returns 'chatbot' | 'prochat' | null [web:32][web:39][web:46]
    if (!context.mounted) return;
    if (choice == 'chatbot') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const Chatbot_Screen()),
      ); // [web:10]
    } else if (choice == 'prochat') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const GeminiChatScreen()),
      ); // [web:10]
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page principale'),
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            tooltip: isDarkMode ? 'Mode clair' : 'Mode sombre',
            onPressed: onThemeToggle,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
                  heroTag: "unique_tag_1",
                  // Choose one of the two handlers:
                  // onPressed: () => _chooseChatDialog(context),
                  onPressed: () => _chooseChatSheet(context),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.chat),
                ),
                const SizedBox(width: 40),
                FloatingActionButton(
                  heroTag: "unique_tag_2",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => PlantDetectionScreen()),
                    ); // [web:10]
                  },
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.verified),
                ),
                const SizedBox(width: 40),
                FloatingActionButton(
                  heroTag: "unique_tag_3",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserSensorsScreen(),
                      ),
                    ); // [web:10]
                  },
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.sensors),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text('Chatbot'),
                  SizedBox(width: 60),
                  Text('Vérification'),
                  SizedBox(width: 20),
                  Text('Les Capteurs'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
