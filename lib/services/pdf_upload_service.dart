import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class PdfUploadService {
  // 🔗 PDF işleme backend'i 8000 portunda çalışıyor
  static const String baseUrl = 'http://localhost:8000';

  /// PDF dosyasını yükler ve hem tarih hem sonuç listesini döndürür.
  static Future<Map<String, dynamic>> uploadPdf(File pdfFile) async {
    try {
      print("📤 PDF yükleniyor: ${pdfFile.path}");
      
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/upload/pdf'),
      );

      request.files.add(await http.MultipartFile.fromPath('file', pdfFile.path));

      final response = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Bağlantı zaman aşımına uğradı. Backend\'in çalıştığından emin olun.');
        },
      );
      
      final respStr = await response.stream.bytesToString();

      print("📡 PDF Upload Yanıt Kodu: ${response.statusCode}");
      print("📡 PDF Upload Yanıt: $respStr");

      if (response.statusCode == 200) {
        final data = jsonDecode(respStr);

        // backend şu formatta dönüyor:
        // { "date": "26.11.2019", "results": [ {...}, {...} ] }

        return {
          'date': data['date'],
          'results': List<Map<String, dynamic>>.from(data['results']),
        };
      } else {
        throw Exception('PDF yükleme hatası (${response.statusCode}): $respStr');
      }
    } catch (e) {
      print("❌ PDF yükleme hatası: $e");
      rethrow;
    }
  }
}
