import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'dashboard_doctor.dart';
import 'dashboard_patient.dart';

class RegisterPage extends StatefulWidget {
  final String role; // doctor veya patient
  const RegisterPage({super.key, required this.role});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameC = TextEditingController();
  final surnameC = TextEditingController();
  final emailC = TextEditingController();
  final passC = TextEditingController();
  bool loading = false;

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (nameC.text.trim().isEmpty || surnameC.text.trim().isEmpty) {
      _msg('Ad ve soyad zorunlu');
      return;
    }
    final emailOk = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(emailC.text.trim());
    if (!emailOk) {
      _msg('Geçerli bir e-posta yaz');
      return;
    }
    if (passC.text.length < 6) {
      _msg('Parola en az 6 karakter olmalı');
      return;
    }

    setState(() => loading = true);

    try {
      final url = Uri.parse('http://localhost:5080/api/auth/register');
      final body = jsonEncode({
        "firstName": nameC.text.trim(),
        "lastName": surnameC.text.trim(),
        "email": emailC.text.trim(),
        "password": passC.text,
        "role": widget.role
      });

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _msg('✅ ${data["message"] ?? "Kayıt başarılı"}');

        final fullName = '${nameC.text.trim()} ${surnameC.text.trim()}';

        if (widget.role == 'doctor') {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => DoctorDashboardPage(
                fullName: fullName,
                email: emailC.text.trim(),
                userId: 'doctorId', // Replace with the actual doctor ID if available
              ),
            ),
            (_) => false,
          );
        } else {
          // 🔹 userId tipi farklı dönebilir diye kontrol eklendi
          final userField = data['user'];
          String userId;

          if (userField is Map && userField.containsKey('id')) {
            userId = userField['id'].toString();
          } else if (userField is List && userField.isNotEmpty) {
            userId = userField.first['id'].toString();
          } else {
            userId = userField.toString();
          }

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => PatientDashboardPage(
                fullName: fullName,
                email: emailC.text.trim(),
                userId: userId,
              ),
            ),
            (_) => false,
          );
        }
      } else {
        _msg('❌ Sunucu hatası: ${response.body}');
      }
    } catch (e) {
      _msg('⚠️ Bağlantı hatası: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  void _msg(String t) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.role == 'doctor' ? 'Doktor Kaydı' : 'Hasta Kaydı';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameC,
                  decoration: const InputDecoration(
                    labelText: 'Ad',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: surnameC,
                  decoration: const InputDecoration(
                    labelText: 'Soyad',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailC,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-posta',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passC,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Parola',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loading ? null : _submit,
                    child: Text(loading ? 'Kaydediliyor...' : 'Kaydol'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
