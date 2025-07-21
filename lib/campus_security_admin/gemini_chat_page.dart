import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

class GeminiChatPage extends StatefulWidget {
  const GeminiChatPage({super.key});

  @override
  State<GeminiChatPage> createState() => _GeminiChatPageState();
}

class _GeminiChatPageState extends State<GeminiChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _apiKey;
  final List<Map<String, dynamic>> _chatHistory = [];

  @override
  void initState() {
    super.initState();
    _initializeGemini();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeGemini() async {
    setState(() => _isLoading = true);
    try {
      // Get API key from env
      _apiKey = dotenv.get('GEMINI_API_KEY');

      if (_apiKey == null || _apiKey!.isEmpty) {
        _addSystemMessage("Error: GEMINI_API_KEY not found in .env file");
        return;
      }

      _addSystemMessage("Welcome to Gemini Chat! How can I help you today?");
    } catch (e) {
      _addSystemMessage("Error initializing Gemini API: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addSystemMessage(String content) {
    setState(() {
      _messages.add(ChatMessage(
        content: content,
        isUser: false,
        timestamp: DateTime.now(),
      ));

      // Add to chat history if not an error message
      if (!content.startsWith("Error:")) {
        _chatHistory.add({
          'role': 'model',
          'parts': [
            {'text': content}
          ]
        });
      }
    });
  }

  void _addUserMessage(String content) {
    if (content.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        content: content,
        isUser: true,
        timestamp: DateTime.now(),
      ));

      // Add to chat history
      _chatHistory.add({
        'role': 'user',
        'parts': [
          {'text': content}
        ]
      });
    });

    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _addUserMessage(message);
    _messageController.clear();

    if (_apiKey == null) {
      _addSystemMessage(
          "Gemini API is not initialized. Please try again later.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Prepare the message content
      List<Map<String, dynamic>> contents = [];

      // Add the chat history for context
      for (var msg in _chatHistory) {
        contents.add(msg);
      }

      // Create the request body
      final requestBody = jsonEncode({
        'contents': contents,
        'generationConfig': {
          'temperature': 0.7,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 1000,
        },
      });

      // Send request to Gemini API
      final response = await http.post(
        Uri.parse(
            "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$_apiKey"),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final candidates = jsonResponse['candidates'] as List?;

        if (candidates == null || candidates.isEmpty) {
          _addSystemMessage("No response received from Gemini.");
          return;
        }

        final firstCandidate = candidates.first;
        final content = firstCandidate['content'] as Map<String, dynamic>?;

        if (content == null) {
          _addSystemMessage("Invalid response format from Gemini.");
          return;
        }

        final parts = content['parts'] as List?;
        if (parts == null || parts.isEmpty) {
          _addSystemMessage("Empty response from Gemini.");
          return;
        }

        final text = parts.first['text'] as String? ?? '';
        _addSystemMessage(text);
      } else {
        _addSystemMessage(
            "Error: API returned status code ${response.statusCode}");
        print("API Error: ${response.body}");
      }
    } catch (e) {
      _addSystemMessage("Error getting response: $e");
      print("Exception: $e");
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    // Add a slight delay to ensure the list has updated
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.chat,
                    color: Colors.blue,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                const Text(
                  'Gemini Chat',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Chat Area
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 80,
                              color: Colors.blue.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Start a chat with Gemini AI',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.blueGrey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          return ChatBubble(message: message);
                        },
                      ),
              ),
            ),

            const SizedBox(height: 20),

            // Input Area
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Ask Gemini something...',
                          border: InputBorder.none,
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            onPressed: _sendMessage,
                            icon: const Icon(Icons.send),
                            color: Colors.blue,
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
  });
}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: message.isUser ? Colors.blue : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: message.isUser ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                color: message.isUser
                    ? Colors.white.withOpacity(0.7)
                    : Colors.black54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
