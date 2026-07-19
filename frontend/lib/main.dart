import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:universal_html/html.dart' as html;
import 'dart:convert';
import 'dart:async';

void main() {
  runApp(const LaiHoaApp());
}

class LaiHoaApp extends StatelessWidget {
  const LaiHoaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Tuyên Truyền Lai Hòa',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.light),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const GeneratorPage(),
    );
  }
}

class GeneratorPage extends StatefulWidget {
  const GeneratorPage({super.key});

  @override
  State<GeneratorPage> createState() => _GeneratorPageState();
}

class _GeneratorPageState extends State<GeneratorPage> {
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _licenseController = TextEditingController();
  bool _isLoading = false;
  String _message = '';
  double _progress = 0.0;
  Timer? _progressTimer;

  // URL of the API. Defaults to localhost, but can be overridden by dart-define
  static const String apiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:8080');

  Future<void> _generateVideo() async {
    final topic = _topicController.text;
    final license = _licenseController.text;
    if (topic.isEmpty || license.isEmpty) {
      setState(() => _message = 'Vui lòng nhập chủ đề và License Key');
      return;
    }

    setState(() {
      _isLoading = true;
      _message = 'Đang gọi AI sinh kịch bản và giọng đọc...';
      _progress = 0.0;
    });

    // Simulate progress since backend might take 15-30 seconds
    _progressTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() {
        if (_progress < 0.9) {
          _progress += 0.02;
        }
      });
    });

    try {
      final response = await http.post(
        Uri.parse('$apiUrl/generate-video'),
        headers: {
          'Content-Type': 'application/json',
          'x-license-key': license,
        },
        body: jsonEncode({'topic': topic, 'duration': 60}),
      );

      _progressTimer?.cancel();
      setState(() => _progress = 1.0);

      if (response.statusCode == 200) {
        setState(() => _message = 'Tạo video thành công! Đang tải xuống...');
        
        // Trigger download
        final blob = html.Blob([response.bodyBytes], 'video/mp4');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", "video_laihoa.mp4")
          ..click();
        html.Url.revokeObjectUrl(url);

      } else {
        setState(() => _message = 'Lỗi ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      _progressTimer?.cancel();
      setState(() => _message = 'Lỗi kết nối: $e');
    } finally {
      setState(() {
        _isLoading = false;
        _progressTimer?.cancel();
      });
    }
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo Video Lai Hòa'),
        elevation: 2,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Card(
            elevation: 4,
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Nhập thông tin Video',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _topicController,
                    decoration: const InputDecoration(
                      labelText: 'Chủ đề tuyên truyền',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.topic),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _licenseController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'License Key (Bảo mật)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.security),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _generateVideo,
                    icon: const Icon(Icons.video_call),
                    label: Text(_isLoading ? 'Đang xử lý...' : 'Tạo Video Mới'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  ),
                  
                  if (_isLoading) ...[
                    const SizedBox(height: 24),
                    LinearProgressIndicator(value: _progress),
                    const SizedBox(height: 8),
                    Text('${(_progress * 100).toInt()}%', textAlign: TextAlign.center),
                  ],

                  const SizedBox(height: 24),
                  if (_message.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _message.startsWith('Lỗi') ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _message,
                        style: TextStyle(
                          color: _message.startsWith('Lỗi') ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
