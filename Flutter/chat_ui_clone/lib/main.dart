import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const ChatApp());
}

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat UI Clone',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const ChatPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ChatMessage {
  final String id;
  final String text;
  final bool isMe;
  final DateTime time;

  ChatMessage({required this.id, required this.text, required this.isMe, DateTime? time}) : time = time ?? DateTime.now();
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<ChatMessage> _messages = [
    ChatMessage(id: '1', text: 'Hey! 👋', isMe: false, time: DateTime.now().subtract(const Duration(minutes: 10))),
    ChatMessage(id: '2', text: 'Hi! How are you?', isMe: true, time: DateTime.now().subtract(const Duration(minutes: 9, seconds: 30))),
    ChatMessage(id: '3', text: 'I\'m good, thanks. Working on a Flutter project — building a chat UI.', isMe: false, time: DateTime.now().subtract(const Duration(minutes: 8))),
    ChatMessage(id: '4', text: 'Nice! Want to see a quick mock?', isMe: true, time: DateTime.now().subtract(const Duration(minutes: 7, seconds: 10))),
  ];

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final msg = ChatMessage(id: DateTime.now().millisecondsSinceEpoch.toString(), text: text, isMe: true);
    setState(() {
      _messages.add(msg);
      _controller.clear();
    });
    // Scroll to bottom after a short delay to allow the list to build
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  String _formatTime(DateTime t) {
    final now = DateTime.now();
    if (now.difference(t).inDays == 0) {
      return DateFormat.Hm().format(t); // 14:05
    }
    return DateFormat('MMM d, HH:mm').format(t);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            CircleAvatar(child: Icon(Icons.person)),
            SizedBox(width: 12),
            Expanded(child: Text('Alexandra', overflow: TextOverflow.ellipsis)),
          ],
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.call)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final m = _messages[index];
                final isMe = m.isMe;
                // Bubble alignment and styling
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      if (!isMe) ...[
                        const Padding(
                          padding: EdgeInsets.only(right: 8.0),
                          child: CircleAvatar(radius: 18, child: Icon(Icons.person, size: 18)),
                        ),
                      ],
                      Flexible(
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Container(
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                              decoration: BoxDecoration(
                                color: isMe ? Colors.indigo[400] : Colors.grey[200],
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: Radius.circular(isMe ? 16 : 2),
                                  bottomRight: Radius.circular(isMe ? 2 : 16),
                                ),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    m.text,
                                    style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 16),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(_formatTime(m.time), style: TextStyle(color: (isMe ? Colors.white70 : Colors.black45), fontSize: 11)),
                                      const SizedBox(width: 6),
                                      if (isMe) Icon(Icons.done_all, size: 14, color: Colors.white70),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 8),
                        const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: CircleAvatar(radius: 18, child: Icon(Icons.person, size: 18)),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),

          // Input area
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Row(
                children: [
                  IconButton(onPressed: () {}, icon: const Icon(Icons.add_circle_outline)),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              minLines: 1,
                              maxLines: 5,
                              decoration: const InputDecoration(hintText: 'Type a message', border: InputBorder.none),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          IconButton(
                            onPressed: _sendMessage,
                            icon: const Icon(Icons.send, color: Colors.indigo),
                          ),
                        ],
                      ),
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
