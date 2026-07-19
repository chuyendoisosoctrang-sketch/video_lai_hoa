import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  Future<void> _generateVideo() async {
    final topic = _topicController.text;
    final license = _licenseController.text;
    if (topic.isEmpty || license.isEmpty) {
      setState(() => _message = 'Vui lòng nhập chủ đề và License Key');
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      // For local testing, we assume the backend runs on localhost:8080
      final response = await http.post(
        Uri.parse('http://localhost:8080/generate-video'),
        headers: {
          'Content-Type': 'application/json',
          'x-license-key': license,
        },
        body: jsonEncode({'topic': topic, 'duration': 60}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => _message = data['message'] ?? 'Thành công!');
      } else {
        setState(() => _message = 'Lỗi ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      setState(() => _message = 'Lỗi kết nối: $e');
    } finally {
      setState(() => _isLoading = false);
    }
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
                    icon: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.video_call),
                    label: Text(_isLoading ? 'Đang xử lý...' : 'Tạo Video Mới'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  ),
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
