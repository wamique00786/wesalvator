import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Chatbot extends StatefulWidget {
  const Chatbot({super.key});

  @override
  State<Chatbot> createState() => _ChatbotState();
}

class _ChatbotState extends State<Chatbot> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> messages = [];
  final String apiUrl = "https://wesalvator.com/api/chatbot/";
  bool _isBotTyping = false;
  bool _showSampleMessages = true;

  Future<void> sendMessage(String userMessage) async {
    if (userMessage.isEmpty) return;

    setState(() {
      messages.add({"user": userMessage});
      _isBotTyping = true;
      _showSampleMessages = false;
    });

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: utf8.encode(jsonEncode({"message": userMessage})),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          messages
              .add({"bot": responseData["response"] ?? "No response from bot"});
          _isBotTyping = false;
        });
      } else {
        showError("Error ${response.statusCode}: ${response.body}");
        setState(() {
          _isBotTyping = false;
        });
      }
    } catch (e) {
      showError("Failed to connect. Check your internet.");
      setState(() {
        _isBotTyping = false;
      });
    }
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Wesalvator Assistant",
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: messages.length + (_isBotTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == messages.length && _isBotTyping) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text("Typing...",
                              style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                  );
                }
                final entry = messages[index];
                bool isUser = entry.keys.first == "user";
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blueAccent : Colors.grey[900],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      entry.values.first,
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_showSampleMessages) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Wrap(
                spacing: 8,
                children: [
                  "Help with animal rescue",
                  "Help with animal adoption",
                  "Volunteer"
                ]
                    .map((message) => ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                          ),
                          onPressed: () => sendMessage(message),
                          child: Text(message),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      hintStyle: TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.grey[900],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () {
                      final message = _controller.text.trim();
                      if (message.isNotEmpty) {
                        sendMessage(message);
                        _controller.clear();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
