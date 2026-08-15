import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
  String status = 'جاري تفعيل الجهاز...';
  String deviceId = '';
  bool isLoading = true;
  TextEditingController manualIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    initDevice();
  }

  Future<String> getStableDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? saved = prefs.getString('device_id_stable');
    if (saved!= null && saved.isNotEmpty) return saved;
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final id = androidInfo.id?? androidInfo.androidId?? '';
      if (id.isNotEmpty) {
        int hash = id.hashCode.abs();
        String stable = 'FOX-${(hash % 9000000 + 1000000).toString()}';
        await prefs.setString('device_id_stable', stable);
        await prefs.setString('android_id', id);
        return stable;
      }
    } catch (e) {}
    String? old = prefs.getString('device_id');
    if (old!= null) {
      await prefs.setString('device_id_stable', old);
      return old;
    }
    final rnd = Random().nextInt(9000000) + 1000000;
    String newId = 'FOX-$rnd';
    await prefs.setString('device_id_stable', newId);
    await prefs.setString('device_id', newId);
    return newId;
  }

  Future<void> initDevice() async {
    String stableId = await getStableDeviceId();
    setState(() {
      deviceId = stableId;
      manualIdController.text = stableId;
    });
    await checkActivation(stableId);
  }

  Future<void> checkActivation(String idToCheck) async {
    setState(() {
      isLoading = true;
      status = 'جاري فحص $idToCheck...';
      deviceId = idToCheck;
    });
    try {
      final url = Uri.parse('https://foxly.online/api/check.php?device_id=$idToCheck');
      final res = await http.get(url, headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['active'] == true) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('m3u_url', data['m3u_url']?? data['device']?['main_m3u']?? '');
          await prefs.setString('expiry', data['expiry']?? '');
          await prefs.setString('subscriptions', jsonEncode(data['subscriptions']?? data['device']?['subscriptions']?? []));
          await prefs.setBool('is_activated', true);
          await prefs.setString('device_id_stable', idToCheck);
          if (!mounted) return;
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePage(
            m3u: data['m3u_url']?? '',
            deviceId: idToCheck,
            subscriptions: data['subscriptions']?? [],
            expiry: data['expiry']?? '',
            plan: data['device']?['plan']?? '',
          )));
          return;
        } else {
          setState(() {
            if (data['expired'] == true) {
              status = 'انتهى اشتراكك يوم ${data['expiry']} - جدد من الموزع';
            } else {
              status = 'الجهاز غير مفعل\nانسخ الكود وارسله للموزع';
            }
            isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      setState(() {
        status = 'فشل الاتصال: $e';
        isLoading = false;
      });
    }
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('is_activated') == true) {
      final m3u = prefs.getString('m3u_url')?? '';
      final expiry = prefs.getString('expiry')?? '';
      if (m3u.isNotEmpty) {
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePage(m3u: m3u, deviceId: idToCheck, subscriptions: [], expiry: expiry, plan: 'year')));
        return;
      }
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.live_tv, size: 80, color: Color(0xFFFF6B00)),
              const SizedBox(height: 16),
              const Text('FOX PRO', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('التفعيل التلقائي', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFFF6B00), width: 1)),
                child: Column(
                  children: [
                    const Text('كود جهازك الثابت (ما يتغير):', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 8),
                    SelectableText(deviceId, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFFF6B00))),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: deviceId));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ الكود')));
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('نسخ الكود'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B00), foregroundColor: Colors.black),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (isLoading)...[
                const CircularProgressIndicator(color: Color(0xFFFF6B00)),
                const SizedBox(height: 16),
                Text(status, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFFF6B00), fontSize: 13)),
              ] else...[
                Text(status, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 20),
                const Divider(color: Colors.white10),
                const SizedBox(height: 10),
                const Text('اذا حذفت التطبيق ورجع الرقم؟', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextField(
                  controller: manualIdController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'ادخل كودك القديم',
                    hintText: 'FOX-3860373',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (manualIdController.text.trim().isNotEmpty) {
                        checkActivation(manualIdController.text.trim());
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white10),
                    child: const Text('تفعيل بالكود القديم'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => checkActivation(deviceId),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B00), foregroundColor: Colors.black),
                    icon: const Icon(Icons.refresh),
                    label: const Text('إعادة الفحص'),
                  ),
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
  final String plan;
  const HomePage({super.key, required this.m3u, required this.deviceId, required this.subscriptions, required this.expiry, required this.plan});
  @override
  Widget build(BuildContext context) {
    final isLifetime = expiry == '2099-12-31' || plan == 'lifetime';
    return Scaffold(
      appBar: AppBar(backgroundColor: const Color(0xFF080808), title: const Text('FOX PRO')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFFF6B00).withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: Row(children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('مفعل: $deviceId', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(isLifetime? 'مدى الحياة ♾️' : 'ينتهي: $expiry', style: const TextStyle(color: Color(0xFFFF6B00), fontSize: 12)),
              ]),
            ])),
            const SizedBox(height: 16),
            Expanded(child: ListView.builder(itemCount: subscriptions.isEmpty? 1 : subscriptions.length, itemBuilder: (c,i){
              if(subscriptions.isEmpty) return Card(color: const Color(0xFF1a1a1a), child: ListTile(title: const Text('الرئيسي'), subtitle: SelectableText(m3u, style: const TextStyle(fontSize: 10, color: Colors.grey))));
              final sub = subscriptions[i];
              return Card(color: const Color(0xFF1a1a1a), child: ListTile(title: Text(sub['name']?? 'اشتراك $i'), subtitle: SelectableText(sub['m3u']?? '', style: const TextStyle(fontSize: 9, color: Colors.grey))));
            })),
          ],
        ),
      ),
    );
  }
}
