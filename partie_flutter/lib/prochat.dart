// lib/screens/gemini_chat_screen.dart
import 'package:flutter/material.dart';

class GeminiChatScreen extends StatefulWidget {
  const GeminiChatScreen({super.key});
  @override
  State<GeminiChatScreen> createState() => _GeminiChatScreenState();
}

class _GeminiChatScreenState extends State<GeminiChatScreen> {
  final List<_ChatMessage> _messages = [];
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _isTyping = false;

  final List<String> _suggestions = const [
    "What plant disease is this?",
    "Explain the difference between healthy and infected leaves",
    "Summarize this plant health report",
  ];

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isTyping) return;

    setState(() {
      _messages
          .add(_ChatMessage(text: trimmed, isUser: true, ts: DateTime.now()));
      _isTyping = true;
    });
    _input.clear();
    _jumpToBottom();

    // Insert an empty assistant message we will update as chunks arrive.
    setState(() {
      _messages.add(_ChatMessage(text: '', isUser: false, ts: DateTime.now()));
    });
    final botIndex = _messages.length - 1;

    try {
      String buffer = '';
    } catch (e) {
      setState(() {
        _messages[botIndex] =
            _ChatMessage(text: 'Error: $e', isUser: false, ts: DateTime.now());
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Gemini error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isTyping = false);
    }
  }

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onTapSuggestion(String s) => _sendMessage(s);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gemini Chat"), centerTitle: true),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isTyping && index == _messages.length) {
                  return const _TypingIndicator();
                }
                final msg = _messages[index];
                return _ChatBubble(message: msg);
              },
            ),
          ),
          if (_messages.isEmpty && _suggestions.isNotEmpty)
            _SuggestionChips(
                suggestions: _suggestions, onTap: _onTapSuggestion),
          const Divider(height: 1),
          _InputBar(
            controller: _input,
            onSend: _sendMessage,
            isBusy: _isTyping,
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime ts;
  _ChatMessage({required this.text, required this.isUser, required this.ts});
}

class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final align = message.isUser ? Alignment.centerRight : Alignment.centerLeft;
    final bg = message.isUser
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceContainerHighest;
    final fg = message.isUser
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurfaceVariant;

    return Align(
      alignment: align,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.80),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: message.isUser
                ? const Radius.circular(14)
                : const Radius.circular(4),
            bottomRight: message.isUser
                ? const Radius.circular(4)
                : const Radius.circular(14),
          ),
        ),
        child: Text(message.text, style: TextStyle(color: fg, fontSize: 15)),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();
  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.all(Radius.circular(14))),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            _Dot(delay: 0),
            SizedBox(width: 4),
            _Dot(delay: 200),
            SizedBox(width: 4),
            _Dot(delay: 400),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});
  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1000))
    ..repeat();
  late final Animation<double> _a = Tween(begin: 0.3, end: 1.0)
      .chain(CurveTween(curve: Curves.easeInOut))
      .animate(_c);

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _c.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _a,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final Future<void> Function(String) onSend;
  final bool isBusy;
  const _InputBar(
      {required this.controller, required this.onSend, required this.isBusy});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  hintText: "Message Gemini...",
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: isBusy ? null : () => onSend(controller.text),
              icon: const Icon(Icons.send_rounded),
              color: Theme.of(context).colorScheme.primary,
              tooltip: "Send",
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionChips extends StatelessWidget {
  final List<String> suggestions;
  final void Function(String) onTap;
  const _SuggestionChips({required this.suggestions, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: suggestions
            .map((s) => ActionChip(label: Text(s), onPressed: () => onTap(s)))
            .toList(),
      ),
    );
  }
}
