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
  List<dynamic> subscriptions = [];

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
      status = 'جاري فحص $deviceId...';
    });

    try {
      final url = Uri.parse('https://foxly.online/api/check.php?device_id=$deviceId');
      final res = await http.get(url, headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 10));
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['active'] == true) {
          final m3u = data['m3u_url'] ?? data['device']?['m3u_url'] ?? '';
          final subs = data['subscriptions'] ?? data['device']?['subscriptions'] ?? [];
          final expiry = data['expiry'] ?? '';
          await prefs.setString('m3u_url', m3u);
          await prefs.setString('expiry', expiry);
          await prefs.setString('subscriptions', jsonEncode(subs));
          await prefs.setBool('is_activated', true);
          setState(() {
            isActive = true;
            m3uUrl = m3u;
            subscriptions = subs;
            status = 'تم التفعيل بنجاح ✅ حتى $expiry';
          });
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePage(m3u: m3uUrl, deviceId: deviceId, subscriptions: subscriptions, expiry: expiry)));
            }
          });
        } else {
          if(data['expired'] == true){
            setState(() => status = 'انتهى اشتراكك ${data['expiry']} - جدد من الموزع');
          } else {
            setState(() => status = 'الجهاز غير مفعل - تواصل مع الموزع\nكودك: $deviceId');
          }
        }
      } else {
        setState(() => status = 'خطأ سيرفر: ${res.statusCode}');
      }
    } catch (e) {
      bool? localActive = prefs.getBool('is_activated');
      if(localActive == true){
        setState(() {
          isActive = true;
          m3uUrl = prefs.getString('m3u_url') ?? '';
          status = 'تم التفعيل (وضع اوفلاين) ✅';
        });
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePage(m3u: m3uUrl, deviceId: deviceId, subscriptions: [], expiry: prefs.getString('expiry') ?? '')));
          }
        });
      } else {
        setState(() => status = 'لا يوجد اتصال: $e\nتأكد ان ملف api/check.php موجود');
      }
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
  final List<dynamic> subscriptions;
  final String expiry;
  const HomePage({super.key, required this.m3u, required this.deviceId, required this.subscriptions, required this.expiry});
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Image.asset('assets/logo.png', width: 100, errorBuilder: (c,e,s) => const Icon(Icons.live_tv, size: 60, color: Color(0xFFFF6B00)))),
            const SizedBox(height: 16),
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFFF6B00).withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('معرف: $deviceId', style: const TextStyle(color: Colors.grey)),
              Text('ينتهي: $expiry', style: const TextStyle(color: Color(0xFFFF6B00), fontWeight: FontWeight.bold)),
            ])),
            const SizedBox(height: 16),
            const Text('اشتراكاتك:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(child: ListView.builder(itemCount: subscriptions.isEmpty ? 1 : subscriptions.length, itemBuilder: (c,i){
              if(subscriptions.isEmpty) return ListTile(title: const Text('الرئيسي'), subtitle: SelectableText(m3u, style: const TextStyle(fontSize: 10)));
              final sub = subscriptions[i];
              return Card(color: const Color(0xFF1a1a1a), child: ListTile(title: Text(sub['name'] ?? 'اشتراك $i'), subtitle: SelectableText(sub['m3u'] ?? '', style: const TextStyle(fontSize: 9, color: Colors.grey))));
            })),
          ],
        ),
      ),
    );
  }
}
