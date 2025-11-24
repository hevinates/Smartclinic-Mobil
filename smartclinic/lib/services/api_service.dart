import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // Örn: http://localhost:5080  (DİKKAT: /api ekleme, controller route'u /auth)
  static const String baseUrl = 'http://192.168.1.100:5080/api/auth';

  final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
  ));

  final FlutterSecureStorage _secure = const FlutterSecureStorage();

  /// Giriş: token döner ve güvenli saklamaya yazılır. Kullanıcı bilgilerini geri verir.
  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });

    final token = res.data['accessToken'] as String;
    await _secure.write(key: 'token', value: token);

    final user = Map<String, dynamic>.from(res.data['user'] as Map);
    return user;
  }

  /// Kayıt: başarılıysa 200/201 döner
  Future<void> register({
    required String role,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    await _dio.post('/auth/register', data: {
      'role': role,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'password': password,
    });
  }

  /// Çıkış: sadece yerel token’ı siler
  Future<void> logout() async {
    await _secure.delete(key: 'token');
  }

  /// (opsiyonel) saklanan token'ı oku
  Future<String?> getToken() => _secure.read(key: 'token');
}
