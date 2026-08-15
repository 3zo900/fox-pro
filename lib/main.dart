import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://luhqqezypncukhgbfpsr.supabase.co',
    anonKey: 'sb_publishable_Nl7F2yY5l1A02u0LwM6yug_02b1vH5l',
  );
  runApp(const FoxProApp());
}

class FoxProApp extends StatelessWidget {
  const FoxProApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FOX PRO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: const Color(0xFF080808)),
      home: const ActivationScreen(),
    );
  }
}

class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key});
  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final _deviceCtrl = TextEditingController();
  final _m3uCtrl = TextEditingController();
  bool _loading = false;
  String _deviceId = 'FOX-0000';

  @override
  void initState() {
    super.initState();
    _deviceId = 'FOX-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
  }

  Future<void> _activate() async {
    setState(() => _loading = true);
    try {
      final id = _deviceCtrl.text.trim().isEmpty ? _deviceId : _deviceCtrl.text.trim();
      final supa = Supabase.instance.client;
      final res = await supa.from('devices').select().eq('device_id', id).maybeSingle();
      String? urlToPlay = _m3uCtrl.text.trim().isNotEmpty ? _m3uCtrl.text.trim() : null;
      if (res != null && res['m3u_url'] != null) urlToPlay = res['m3u_url'];
      if (urlToPlay != null && urlToPlay.isNotEmpty) {
        if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PlayerScreen(m3uUrl: urlToPlay!)));
        return;
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا يوجد M3U - اكتب رابط أو فعل الجهاز من لوحة التحكم')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            Container(width: 120, height: 120, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)), child: const Icon(Icons.play_circle_fill, size: 80, color: Color(0xFFFF6A00))),
            const SizedBox(height: 20),
            RichText(text: const TextSpan(children: [TextSpan(text: 'FOX ', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)), TextSpan(text: 'PRO', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFFFF6A00))) ])),
            const Text('Player', style: TextStyle(color: Colors.grey, letterSpacing: 4)),
            const SizedBox(height: 8),
            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(20)), child: Text(_deviceId, style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Color(0xFFFF6A00)))),
            const SizedBox(height: 30),
            TextField(controller: _deviceCtrl, decoration: InputDecoration(hintText: 'معرف الجهاز (اختياري)', filled: true, fillColor: const Color(0xFF121212), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), prefixIcon: const Icon(Icons.phone_iphone, color: Colors.grey)), style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 12),
            TextField(controller: _m3uCtrl, decoration: InputDecoration(hintText: 'رابط M3U للتجربة', filled: true, fillColor: const Color(0xFF121212), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), prefixIcon: const Icon(Icons.link, color: Colors.grey)), style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, height: 52, child: ElevatedButton(onPressed: _loading ? null : _activate, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6A00), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: _loading ? const CircularProgressIndicator(color: Colors.black) : const Text('تشغيل FOX PRO Player', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)))),
          ]),
        ),
      ),
    );
  }
}

class PlayerScreen extends StatefulWidget {
  final String m3uUrl;
  const PlayerScreen({super.key, required this.m3uUrl});
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _loading = true;
  String? _err;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.m3uUrl));
      await _videoController!.initialize();
      _chewieController = ChewieController(videoPlayerController: _videoController!, autoPlay: true, looping: false, allowFullScreen: true, allowMuting: true);
      setState(() => _loading = false);
    } catch (e) {
      setState(() { _loading = false; _err = e.toString(); });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FOX PRO Player'), backgroundColor: Colors.black),
      backgroundColor: Colors.black,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6A00)))
          : _chewieController != null && _videoController!.value.isInitialized
              ? Chewie(controller: _chewieController!)
              : Center(child: Padding(padding: const EdgeInsets.all(16), child: Text('تعذر تشغيل الرابط:\n${widget.m3uUrl}\n\n$_err', style: const TextStyle(color: Colors.white)))),
    );
  }
}
