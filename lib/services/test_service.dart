import 'dart:convert';
import 'package:http/http.dart' as http;

class TestService {
  static const String baseUrl = 'http://localhost:5080/api/test';

  // 🔹 1. Tahlil ekleme
  static Future<void> addTest(Map<String, dynamic> testData) async {
    // Hata almamak için Guid string'e dönüştür + boş sonuçları önle
    final fixedData = {
      "userId": testData["userId"].toString(), // Guid string olarak gönder
      "testName": testData["testName"] ?? "",
      "result": testData["result"] ?? "", // boşsa bile boş string gönder
      "referenceRange": testData["referenceRange"] ?? "",
      "isOutOfRange": testData["isOutOfRange"] ?? false,
      "batchId": testData["batchId"] ?? "", // Benzersiz grup ID'si
      "date": testData["date"] ?? DateTime.now().toUtc().toIso8601String(),
    };

    // 🔹 Ekle dediğim satır burada:
    print("🧾 API'ye gönderilen veri: ${jsonEncode(fixedData)}");

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/add'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(fixedData),
      );

      print("📡 API Yanıt Kodu: ${res.statusCode}");
      print("📡 API Yanıt: ${res.body}");

      if (res.statusCode != 200 && res.statusCode != 201) {
        throw Exception('Tahlil kaydedilemedi (${res.statusCode}): ${res.body}');
      }
    } catch (e) {
      print("❌ Test ekleme hatası: $e");
      rethrow;
    }
  }

  // 🔹 2. Kullanıcının geçmiş tahlillerini alma
  static Future<List<dynamic>> getUserTests(String userId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/user/$userId'));

      print("📥 Tahliller alınıyor - Yanıt kodu: ${res.statusCode}");

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        throw Exception('Tahliller alınamadı (${res.statusCode}): ${res.body}');
      }
    } catch (e) {
      print("❌ Tahlil alma hatası: $e");
      rethrow;
    }
  }
}
