import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class PdfUploadService {
  // 🔗 Backend adresi — iOS’ta localhost yerine 127.0.0.1 değil, 10.0.2.2 veya bilgisayar IP’si kullan
  static const String baseUrl = 'http://192.168.1.100:8000';

  /// PDF dosyasını yükler ve hem tarih hem sonuç listesini döndürür.
  static Future<Map<String, dynamic>> uploadPdf(File pdfFile) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/upload/pdf'),
    );

    request.files.add(await http.MultipartFile.fromPath('file', pdfFile.path));

    final response = await request.send();
    final respStr = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = jsonDecode(respStr);

      // backend şu formatta dönüyor:
      // { "date": "26.11.2019", "results": [ {...}, {...} ] }

      return {
        'date': data['date'],
        'results': List<Map<String, dynamic>>.from(data['results']),
      };
    } else {
      throw Exception('PDF yükleme hatası: ${response.statusCode}');
    }
  }
}
