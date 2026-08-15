// الجديد - صح ✅ يحفظ الرقم مرة وحدة
final prefs = await SharedPreferences.getInstance();
String? saved = prefs.getString('fox_device_id');
if (saved == null) {
  saved = "FOX-${Random().nextInt(900000)+100000}";
  await prefs.setString('fox_device_id', saved);
}
deviceId = saved!;
