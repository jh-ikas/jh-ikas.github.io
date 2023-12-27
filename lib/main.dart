import 'package:flutter/material.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:flutter_chat_bubble/bubble_type.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dynamic Duo Translator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: TranslationPage(),
    );
  }
}

class ChatMessage {
  String messageContent;
  bool messageType;
  ChatMessage({required this.messageContent, required this.messageType});

  @override
  String toString() {
    return 'ChatMessage{messageContent: $messageContent, messageType: $messageType}';
  }
}

class TranslationPage extends StatefulWidget {
  @override
  _TranslationPageState createState() => _TranslationPageState();
}

class _TranslationPageState extends State<TranslationPage> {
  final TextEditingController _controller = TextEditingController();
  List<ChatMessage> messages = [];
  String _selectedLanguage = '영어';
  List<String> languages = [
    '독일어',
    '라틴어',
    '러시아어',
    '몽골어',
    '베트남어',
    '스웨덴어',
    '스페인어',
    '아랍어',
    '영어',
    '이탈리아어',
    '일본어',
    '중국어 (간체)',
    '중국어 (번체)',
    '태국어',
    '터키어',
    '포르투갈어',
    '폴란드어',
    '프랑스어',
    '핀란드어',
    '필리핀어',
    '한국어',
    '힌디어'
  ];

  Timer? _timer;
  bool _isServiceAvailable = true;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 60), (timer) {
      _checkServiceAvailability();
    });
  }

  void _checkServiceAvailability() {
    final currentDate = DateTime.now();
    final endDate = DateTime(2024, 1, 1, 0, 0, 0); // 종료 날짜 설정

    if (currentDate.isAfter(endDate)) {
      if (_isServiceAvailable) {
        setState(() {
          _isServiceAvailable = false;
        });
        _showServiceUnavailableMessage();
      }
    }
  }

  void _showServiceUnavailableMessage() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("서비스 종료 알림"),
          content: Text("이 서비스는 더 이상 사용할 수 없습니다."),
          actions: <Widget>[
            TextButton(
              child: Text("확인"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void _sendMessage() async {
    final userMessage = _controller.text;
    if (userMessage.trim().isEmpty) {
      return;
    }

    setState(() {
      messages.insert(
          0, ChatMessage(messageContent: userMessage, messageType: true));
      _controller.clear();
    });

    final response = await _sendToChatGPT(userMessage);

    setState(() {
      messages.insert(
          0, ChatMessage(messageContent: response, messageType: false));
    });
  }

  Future<String> _sendToChatGPT(String message) async {
    if (!_isServiceAvailable) {
      return "이 서비스는 더 이상 사용할 수 없습니다.";
    }

    try {
      const apiKey = String.fromEnvironment('API_KEY');

      if (apiKey == '') {
        return "API 키가 설정되지 않았습니다.";
      }

      //apiKey = const String.fromEnvironment('API_KEY');
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4-1106-preview',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a multilingual translator. Only the translation. Don\'t say anything else.'
            },
            {
              'role': 'user',
              'content':
                  'Only Translate [$message] into [${_selectedLanguage}]. Don\'t have any interaction.'
            }
          ],
          'temperature': 0.6,
          'max_tokens': 4095,
        }),
      );

      if (response.statusCode == 200) {
        final bodyBytes = response.bodyBytes;
        final bodyString = utf8.decode(bodyBytes);
        final data = jsonDecode(bodyString);
        final text = data['choices'][0]['message']['content'];

        // 클립보드에 복사
        Clipboard.setData(ClipboardData(text: text?.trim() ?? ""));

        return text?.trim() ?? "";
      } else {
        return "번역 오류가 발생했습니다. 다시 시도해주세요.";
      }
    } catch (e) {
      return "API 요청 중 오류가 발생했습니다: ${e.toString()}";
    }
  }

  @override
  Widget build(BuildContext context) {
    // final appBarHeight = AppBar().preferredSize.height;
    // final statusBarHeight = MediaQuery.of(context).padding.top;
    final bottomBarHeight = MediaQuery.of(context).size.height * 0.075;

    return Scaffold(
      appBar: AppBar(
        title: Text('Dynamic Duo Translator'),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(
                        "assets/background.jpg"), // Ensure this path is correct
                    fit: BoxFit.fill,
                  ),
                ),
                child: ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 4.0),
                      child: GestureDetector(
                        onTap: () {
                          final messageToCopy = message.messageContent;
                          Clipboard.setData(ClipboardData(text: messageToCopy));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('메시지가 복사되었습니다.'),
                            ),
                          );
                        },
                        child: ChatBubble(
                          clipper: ChatBubbleClipper5(
                              type: message.messageType
                                  ? BubbleType.sendBubble
                                  : BubbleType.receiverBubble),
                          alignment: message.messageType
                              ? Alignment.topRight
                              : Alignment.topLeft,
                          backGroundColor:
                              message.messageType ? Colors.blue : Colors.grey,
                          child: Text(message.messageContent,
                              style: TextStyle(color: Colors.white)),
                          margin: EdgeInsets.only(top: 8),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Container(
              height: bottomBarHeight,
              color: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    flex: 1,
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedLanguage,
                        isExpanded: true,
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedLanguage = newValue!;
                          });
                        },
                        items: languages
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    flex: 8,
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: "Enter a message",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      maxLines: null,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: ElevatedButton(
                      onPressed: _sendMessage,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
                      ),
                      child: Icon(Icons.send),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
