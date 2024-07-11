import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AIDreamUpCreation extends StatefulWidget {
  final Function(String) getDreamUpText;
  const AIDreamUpCreation({
    super.key,
    required this.getDreamUpText,
  });

  @override
  State<AIDreamUpCreation> createState() => _AIDreamUpCreationState();
}

class _AIDreamUpCreationState extends State<AIDreamUpCreation>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final String blurredKey =
      '';
  final String initialPrompt =
      'Du bist ein virtueller Assistent, der den Nutzern hilft, einen "DreamUp" zu formulieren. Ein DreamUp ist eine individuelle Wunschvorstellung davon, was ein Nutzer gerne erleben würde oder wie er sich eine ideale Freundschaft vorstellt. Deine Aufgabe ist es, ein Gespräch mit dem Nutzer zu führen, ihm eine Frage zu stellen und aus seinen Antworten Informationen zu sammeln. Hier sind einige Fragen, die du dem Nutzer stellen kannst. Du kannst diese Frage in deinen eigenen Worten formulieren, um das Gespräch natürlicher zu gestalten: 1. Was würdest du gerne mal erleben oder tun oder was hattest du mal und du wünschst es dir zurück? 2. Welche Aktivitäten machen dir besonders viel Spaß und würdest du gerne öfter mit einem Freund oder einer Freundin teilen? 3. Wie stellst du dir eine ideale Freundschaft vor? Welche Eigenschaften sollte diese Freundschaft haben? 4. Gibt es bestimmte Situationen oder Momente, die du dir in dieser Freundschaft wünschst? 5. Welche gemeinsamen Ziele oder Entwicklungen würdest du in einer Freundschaft anstreben? Stelle immer nur eine Frage auf einmal und warte auf die Antwort des Nutzers, bevor du die nächste Frage stellst. Setze das Gespräch so lange fort, wie der Benutzer darauf eingeht, und stelle Rückfragen, um die Antworten zu präzisieren und ein möglichst genaues Bild ihrer Vorstellungen zu bekommen. Fokussiere dich dabei aber nicht zu sehr auf die spezifische Aktivität selbst, sondern eher auf das Ausleben dieser mit anderen Menschen. Formuliere keinen abschließenden Text, bis du dazu aufgefordert wirst.';
  final String creationPrompt =
      'Basierend auf den folgenden Nachrichten, fasse meine Informationen zusammen. Beschreibe meine Wünsche und meine Erfahrungen so, als wärst du ich, also in der Ich-Perspektive. Hebe heraus, was mir besonders wichtig ist und worauf ich eventuell Fokus gelegt habe.';

  late AnimationController _animationController;
  late Animation<double> _animation;

  int messageCount = 0;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _sendInitialPrompt();
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();

    super.dispose();
  }

  Future<void> _sendInitialPrompt() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer apiKey',
        },
        body: json.encode({
          'model': 'gpt-3.5-turbo-0125',
          'messages': [
            {'role': 'system', 'content': initialPrompt},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        print('got response: $data');

        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': data['choices'][0]['message']['content'],
          });
          _animationController.forward();
          setState(() {
            _isLoading = false;
          });
        });
      }
    } catch (e) {
      print('an error occurred while sending initial prompt: $e');

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage(String message) async {
    try {
      setState(() {
        _messages.add({'role': 'user', 'content': message});
        _animationController.reset();

        _isLoading = true;
      });

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer apiKey',
        },
        body: json.encode({
          'model': 'gpt-3.5-turbo-0125',
          'messages': [
            {'role': 'system', 'content': initialPrompt},
            ..._messages
                .map((msg) => {'role': msg['role'], 'content': msg['content']}),
          ],
          'max_tokens': 150,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        print('got response: $data');

        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': data['choices'][0]['message']['content'],
          });
          _animationController.forward();
          messageCount++;

          print('messages: $messageCount');

          setState(() {
            _isLoading = false;
          });
        });
      }
    } catch (e) {
      print('an error occurred while chatting with AI: $e');

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createDreamUpText() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer apiKey',
        },
        body: json.encode({
          'model': 'gpt-3.5-turbo-0125',
          'messages': [
            {
              'role': 'system',
              'content': creationPrompt,
            },
            ..._messages
                .map((msg) => {'role': msg['role'], 'content': msg['content']}),
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        print('got response: $data');

        var content = data['choices'][0]['message']['content'];

        print(content);

        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': content,
          });

          _isLoading = false;
        });

        widget.getDreamUpText(content);
      }
    } catch (e) {
      print('an error occurred while generating the DreamUp text: $e');

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: Container(
            color: Colors.transparent,
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.black87,
            ),
          ),
        ),
        centerTitle: true,
        title: const Text(
          'AI Chat Test Page',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: GestureDetector(
              onTap: () {
                FocusManager.instance.primaryFocus?.unfocus();
              },
              child: Container(
                color: Colors.blueGrey.withOpacity(0.2),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Center(
                          child: Container(
                            margin: const EdgeInsets.only(
                              right: 20,
                              top: 20,
                            ),
                            child: Text(
                              '$messageCount/3',
                              style: const TextStyle(
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            if (messageCount < 3) return;

                            await _createDreamUpText();
                          },
                          child: Container(
                            margin: const EdgeInsets.only(
                              right: 20,
                              top: 20,
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 7,
                              horizontal: 10,
                            ),
                            decoration: BoxDecoration(
                              color: messageCount < 3
                                  ? Colors.grey
                                  : Colors.blueAccent,
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: const Text(
                              'Text Erstellen',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Center(
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : FadeTransition(
                                opacity: _animation,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 30,
                                  ),
                                  child: Text(
                                    _messages.isNotEmpty
                                        ? _messages.last['content'] ?? ''
                                        : '',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24.0),
                      border: Border.all(
                        color: Colors.black26,
                        width: 2,
                      ),
                    ),
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                        hintText: 'Nachricht',
                        hintStyle: TextStyle(
                          color: Colors.black87,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                SizedBox(
                  height: 40,
                  child: FloatingActionButton(
                    onPressed: () {
                      _sendMessage(_controller.text);
                      _controller.clear();
                    },
                    backgroundColor: Colors.blue,
                    child: const Icon(
                      Icons.send_rounded,
                    ),
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
