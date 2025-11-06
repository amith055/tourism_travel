import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ignore: camel_case_types
class Ai_assistant extends StatefulWidget {
  const Ai_assistant({super.key});

  @override
  State<Ai_assistant> createState() => _Ai_assistantPageState();
}

class _Ai_assistantPageState extends State<Ai_assistant> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  String apiKey = "AIzaSyDqjEwO7nrdqeJqdvIsrdgL6Rfd2bB4RfA";

  Future<void> _sendMessage() async {
    final message = _controller.text.trim();
    if (message.isEmpty || apiKey.isEmpty) return;

    setState(() {
      _messages.add({'sender': 'user', 'text': message});
      _controller.clear();
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(
          "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey",
        ),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text": """
You are a friendly and knowledgeable chatbot assistant for a tourism and culture mobile app.
Dont give too long answers until asked for more details.
You help users with questions about:
- tourist destinations
- local cultural events and festivals
- travel guidance and planning
- local food, customs, and culture
- guides, local venues, and sightseeing
- safety and legal travel information

Always reply in a polite, informative, and engaging tone.
If the user asks about unrelated topics, kindly steer them back to tourism, travel, or culture.
And also answer to the users specific questions , it can be different types also like , todays date , time , math calculations , etc. , in a conversational manner. seasons and weather conditions can also be included in your answers where relevant.
""",
                },
                {"text": message},
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply =
            data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"] ??
            "Sorry, I didn’t understand that.";
        setState(() {
          _messages.add({'sender': 'bot', 'text': reply});
        });
      } else {
        setState(() {
          _messages.add({
            'sender': 'bot',
            'text': "Error: ${response.statusCode} - ${response.reasonPhrase}",
          });
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({'sender': 'bot', 'text': 'Network error: $e'});
      });
    } finally {
      setState(() => _isLoading = false);
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Help & Legal Assistant'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          // 🌄 Top Gradient Header
          if (_messages.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF00BCD4), Color(0xFF007ACC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.white,
                    size: 70,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Hi there! 👋",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "I’m your travel & culture assistant.\nAsk me about tourist spots, local events, or travel safety!",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),

          // 💬 Chat messages section
          Expanded(
            child:
                _messages.isEmpty
                    ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 30.0),
                        child: Text(
                          "Start chatting below to explore destinations, get cultural insights, or learn about travel safety and legal tips.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 15,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    )
                    : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(12),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        final isUser = msg['sender'] == 'user';
                        return Align(
                          alignment:
                              isUser
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  isUser
                                      ? Colors.cyanAccent.withOpacity(0.15)
                                      : Colors.white10,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(12),
                                topRight: const Radius.circular(12),
                                bottomLeft:
                                    isUser
                                        ? const Radius.circular(12)
                                        : Radius.zero,
                                bottomRight:
                                    isUser
                                        ? Radius.zero
                                        : const Radius.circular(12),
                              ),
                            ),
                            child: Text(
                              msg['text']!,
                              style: TextStyle(
                                color:
                                    isUser ? Colors.cyanAccent : Colors.white,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          ),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(color: Colors.cyanAccent),
            ),

          // ✏️ Input bar
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white24)),
        color: Colors.black,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Ask about travel, local events, or legal help...",
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Colors.cyanAccent),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _isLoading ? null : _sendMessage,
            icon: const Icon(Icons.send, color: Colors.cyanAccent),
          ),
        ],
      ),
    );
  }
}
