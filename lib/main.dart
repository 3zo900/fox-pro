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
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: const Color(0xFF080808)),
      home: const AutoActivationPage(),
    );
  }
}

class AutoActivationPage extends StatefulWidget {
  const AutoActivationPage({super.key});
  @override
  State<AutoActivationPage> createState() => _AutoActivationPageState();
}

class _AutoActivationPageState extends State<AutoActivationPage> {
  String status = 'جاري تفعيل الجهاز تلقائيا...';
  String deviceId = '';
  bool isActive = false;
  String m3uUrl = '';

  @override
  void initState() {
    super.initState();
    autoActivate();
  }

  Future<void> autoActivate() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedId = prefs.getString('device_id');
    
    if (savedId == null) {
      savedId = 'FOX-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
      await prefs.setString('device_id', savedId);
    }

    setState(() {
      deviceId = savedId!;
    });

    try {
      final url = Uri.parse('https://foxly.online/reseller/index.php?device_id=$deviceId');
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['active'] == true) {
          final m3u = data['device']['m3u_url'] ?? '';
          await prefs.setString('m3u_url', m3u);
          await prefs.setBool('is_activated', true);
          setState(() {
            isActive = true;
            m3uUrl = m3u;
            status = 'تم التفعيل بنجاح ✅';
          });
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePage(m3u: m3uUrl, deviceId: deviceId)));
            }
          });
        } else {
          setState(() {
            isActive = false;
            status = 'الجهاز غير مفعل - تواصل مع الموزع';
          });
        }
      } else {
        setState(() => status = 'خطأ اتصال: ${res.statusCode}');
      }
    } catch (e) {
      setState(() => status = 'لا يوجد اتصال بالسيرفر - سيتم المحاولة مجددا');
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
              Image.asset('assets/logo.png', width: 180, errorBuilder: (c,e,s) => const Icon(Icons.live_tv, size: 100, color: Color(0xFFFF6B00))),
              const SizedBox(height: 24),
              const Text('FOX PRO', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              if (!isActive) ...[
                const CircularProgressIndicator(color: Color(0xFFFF6B00)),
                const SizedBox(height: 20),
                Text(status, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFFF6B00))),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      const Text('معرف جهازك:', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 8),
                      SelectableText(deviceId, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      const SizedBox(height: 8),
                      const Text('انسخ هذا المعرف وارسله للموزع لتفعيله من لوحة الادمن', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: autoActivate,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B00), foregroundColor: Colors.black),
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة المحاولة'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final String m3u;
  final String deviceId;
  const HomePage({super.key, required this.m3u, required this.deviceId});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF080808),
        title: Row(children: [
          Image.asset('assets/logo.png', width: 32, errorBuilder: (c,e,s) => const Icon(Icons.live_tv, color: Color(0xFFFF6B00))),
          const SizedBox(width: 8),
          const Text('FOX PRO'),
        ]),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo.png', width: 120, errorBuilder: (c,e,s) => const Icon(Icons.live_tv, size: 80, color: Color(0xFFFF6B00))),
            const SizedBox(height: 20),
            const Text('تم تفعيل الجهاز بنجاح', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 10),
            Text('ID: $deviceId', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            Text('M3U: ${m3u.isEmpty ? "من لوحة الموزع" : "جاهز"}', style: const TextStyle(color: Color(0xFFFF6B00))),
          ],
        ),
      ),
    );
  }
}
