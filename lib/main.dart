import 'package:flutter/material.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const FoxProApp());

class FoxProApp extends StatelessWidget {
  const FoxProApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: const Color(0xFF0A0A0A)),
      home: const TrialScreen(),
    );
  }
}

class TrialScreen extends StatefulWidget {
  const TrialScreen({super.key});
  @override
  State<TrialScreen> createState() => _TrialScreenState();
}

class _TrialScreenState extends State<TrialScreen> {
  final codeCtrl = TextEditingController();
  String deviceId = "FOX-000000";
  String msg = "";
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? saved = prefs.getString('fox_device_id');
      if (saved == null) {
        saved = "FOX-${Random().nextInt(900000) + 100000}";
        await prefs.setString('fox_device_id', saved);
      }
      if (mounted) setState(() { deviceId = saved!; loading = false; });
    } catch (e) {
      if (mounted) setState(() { deviceId = "FOX-${Random().nextInt(900000)+100000}"; loading = false; });
    }
  }

  void activate() {
    if (codeCtrl.text.trim().length >= 3) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen(deviceId: deviceId)));
    } else {
      setState(() => msg = "اكتب كود التفعيل");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFFFF6B00))));
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 50),
            Container(
              width: 120, height: 120,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
              child: const Icon(Icons.live_tv, size: 60, color: Color(0xFFFF6B00)),
            ),
            const SizedBox(height: 18),
            const Text("FOX PRO", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
            const Text("Powerful IPTV Player", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
              child: Column(children: [
                const Text("معرف جهازك - ثابت ✅", style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
                const SizedBox(height: 6),
                SelectableText(deviceId, style: const TextStyle(fontSize: 20, color: Colors.amber, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text("هذا الرقم ما يتغير أبداً", style: TextStyle(fontSize: 11, color: Colors.grey)),
              ]),
            ),
            const SizedBox(height: 22),
            TextField(
              controller: codeCtrl,
              keyboardType: TextInputType.number,
              maxLength: 7,
              textAlign: TextAlign.center,
              style: const TextStyle(letterSpacing: 8, fontSize: 22, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: "كود التفعيل",
                counterText: "",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.vpn_key),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton(
                onPressed: activate,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B00), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text("تفعيل", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            Text(msg, style: const TextStyle(color: Colors.redAccent)),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final String deviceId;
  const HomeScreen({super.key, required this.deviceId});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("FOX PRO"), backgroundColor: Colors.black),
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.check_circle, size: 80, color: Colors.green),
          const SizedBox(height: 16),
          const Text("تم التفعيل بنجاح ✅", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(deviceId, style: const TextStyle(fontSize: 18, color: Colors.amber)),
          const SizedBox(height: 24),
          const Text("IPTV Player جاهز", style: TextStyle(color: Colors.grey)),
        ]),
      ),
    );
  }
}
