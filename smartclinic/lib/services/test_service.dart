import 'dart:convert';
import 'package:http/http.dart' as http;

class TestService {
  static const String baseUrl = 'http://192.168.1.100:5080/api/test';

  // 🔹 1. Tahlil ekleme
  static Future<void> addTest(Map<String, dynamic> testData) async {
    // Hata almamak için Guid string'e dönüştür + boş sonuçları önle
    final fixedData = {
      "userId": testData["userId"].toString(), // Guid string olarak gönder
      "testName": testData["testName"] ?? "",
      "result": testData["result"] ?? "", // boşsa bile boş string gönder
      "referenceRange": testData["referenceRange"] ?? "",
      "isOutOfRange": testData["isOutOfRange"] ?? false,
      "date": DateTime.now().toUtc().toIso8601String(),
    };

    // 🔹 Ekle dediğim satır burada:
    print("🧾 API'ye gönderilen veri: ${jsonEncode(fixedData)}");

    final res = await http.post(
      Uri.parse('$baseUrl/add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(fixedData),
    );

    if (res.statusCode != 200) {
      throw Exception('Tahlil kaydedilemedi: ${res.body}');
    }
  }

  // 🔹 2. Kullanıcının geçmiş tahlillerini alma
  static Future<List<dynamic>> getUserTests(String userId) async {
    final res = await http.get(Uri.parse('$baseUrl/user/$userId'));

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Tahliller alınamadı: ${res.statusCode}');
    }
  }
}
