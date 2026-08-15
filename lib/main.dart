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
        primaryColor: const Color(0xFFFF6B00),
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
  final TextEditingController _deviceController = TextEditingController(text: 'FOX-146242');
  bool _loading = false;
  String _msg = '';

  // === التعديل المهم - يتصل بموقعك الجديد ===
  Future<void> checkDevice() async {
    final deviceId = _deviceController.text.trim();
    if (deviceId.isEmpty) {
      setState(() => _msg = 'ادخل معرف الجهاز');
      return;
    }

    setState(() {
      _loading = true;
      _msg = 'جاري التحقق...';
    });

    try {
      // الرابط الجديد - Hostinger
      final url = Uri.parse('https://foxly.online/reseller/index.php?device_id=$deviceId');
      final res = await http.get(url);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['active'] == true) {
          final m3uUrl = data['device']['m3u_url'] ?? '';
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('device_id', deviceId);
          await prefs.setString('m3u_url', m3uUrl);
          await prefs.setBool('is_activated', true);

          setState(() => _msg = 'تم التفعيل ✅ $deviceId');
          
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => ChannelsPage(m3uUrl: m3uUrl, deviceId: deviceId)),
            );
          }
        } else {
          setState(() => _msg = 'الجهاز غير مفعل ❌ - فعّله من foxly.online/reseller/');
        }
      } else {
        setState(() => _msg = 'خطأ اتصال: ${res.statusCode}');
      }
    } catch (e) {
      setState(() => _msg = 'خطأ: $e');
    } finally {
      setState(() => _loading = false);
    }
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
              const Text('Powerful IPTV Player', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 32),
              TextField(
                controller: _deviceController,
                decoration: InputDecoration(
                  labelText: 'معرف الجهاز',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.devices),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : checkDevice,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B00),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text('تفعيل الجهاز', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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

class ChannelsPage extends StatelessWidget {
  final String m3uUrl;
  final String deviceId;
  const ChannelsPage({super.key, required this.m3uUrl, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('FOX-$deviceId مفعل ✅'),
        backgroundColor: const Color(0xFF121212),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 16),
            Text('الجهاز مفعل: $deviceId'),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(m3uUrl, style: const TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center),
            ),
            const SizedBox(height: 24),
            const Text('هنا كود تشغيل قنوات M3U حقك'),
          ],
        ),
      ),
    );
  }
}
