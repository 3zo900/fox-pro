import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const FoxProApp());
}

class FoxProApp extends StatelessWidget {
  const FoxProApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FOX PRO',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF080808),
      ),
      home: const ActivationPage(),
    );
  }
}

class ActivationPage extends StatefulWidget {
  const ActivationPage({super.key});
  @override
  State<ActivationPage> createState() => _ActivationPageState();
}

class _ActivationPageState extends State<ActivationPage> {
  final TextEditingController _ctrl = TextEditingController(text: 'FOX-146242');
  bool _loading = false;
  String _msg = '';

  Future<void> checkDevice() async {
    final id = _ctrl.text.trim();
    if (id.isEmpty) {
      setState(() => _msg = 'ادخل معرف الجهاز');
      return;
    }
    setState(() {
      _loading = true;
      _msg = 'جاري التحقق...';
    });
    try {
      final url = Uri.parse('https://foxly.online/reseller/index.php?device_id=$id');
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['active'] == true) {
          final m3u = data['device']['m3u_url']?? '';
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('m3u_url', m3u);
          await prefs.setString('device_id', id);
          await prefs.setBool('is_activated', true);
          setState(() => _msg = 'تم التفعيل ✅ $id');
        } else {
          setState(() => _msg = 'الجهاز غير مفعل ❌');
        }
      } else {
        setState(() => _msg = 'خطأ اتصال: ${res.statusCode}');
      }
    } catch (e) {
      setState(() => _msg = 'خطأ: $e');
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.live_tv, size: 80, color: Color(0xFFFF6B00)),
              const SizedBox(height: 16),
              const Text('FOX PRO', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              TextField(
                controller: _ctrl,
                decoration: InputDecoration(
                  labelText: 'معرف الجهاز',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading? null : checkDevice,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B00),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.all(16),
                  ),
                  child: _loading
                     ? const CircularProgressIndicator(color: Colors.black)
                      : const Text('تفعيل الجهاز'),
                ),
              ),
              const SizedBox(height: 16),
              Text(_msg, style: const TextStyle(color: Color(0xFFFF6B00))),
            ],
          ),
        ),
      ),
    );
  }
}
