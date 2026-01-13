import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dashboard_doctor.dart';
import 'dashboard_patient.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  final String role; // doctor veya patient
  const LoginPage({super.key, required this.role});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailC = TextEditingController();
  final passC = TextEditingController();
  bool loading = false;

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    final email = emailC.text.trim();
    final pass = passC.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      _msg('E-posta ve parola zorunlu');
      return;
    }

    setState(() => loading = true);

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5080/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': pass}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _msg('Giriş başarılı!');

        final fullName = '${data['user']['firstName']} ${data['user']['lastName']}';

        // Kullanıcının rolüne göre yönlendirme
        if (widget.role == 'doctor') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => DoctorDashboardPage(
                fullName: fullName,
                email: data['user']['email'],
                userId: data['user']['id'].toString(),
              ),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => PatientDashboardPage(
                fullName: fullName,
                email: data['user']['email'],
                userId: data['user']['id'].toString(),
              ),
            ),
          );
        }
      } else {
        _msg(data['message'] ?? 'Giriş başarısız.');
      }
    } catch (e) {
      _msg('Sunucuya bağlanılamadı: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  void _msg(String t) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));
  }

  @override
  Widget build(BuildContext context) {
    final isDoctor = widget.role == 'doctor';
    final pageTitle = isDoctor ? 'Doktor Paneli' : 'Hasta Paneli';
    
    return Scaffold(
      appBar: AppBar(title: Text(pageTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailC,
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
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loading ? null : _login,
                    child: Text(loading ? 'Giriş yapılıyor...' : 'Giriş Yap'),
                  ),
                ),

                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RegisterPage(role: widget.role),
                      ),
                    );
                  },
                  child: const Text(
                    'Henüz hesabınız yok mu? Kayıt olun',
                    style: TextStyle(color: Colors.teal),
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
