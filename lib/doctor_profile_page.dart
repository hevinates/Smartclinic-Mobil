import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DoctorProfilePage extends StatefulWidget {
  final String doctorEmail;

  const DoctorProfilePage({super.key, required this.doctorEmail});

  @override
  State<DoctorProfilePage> createState() => _DoctorProfilePageState();
}

class _DoctorProfilePageState extends State<DoctorProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final nameC = TextEditingController();
  final surnameC = TextEditingController();
  final hospitalC = TextEditingController();
  
  int? userId;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfileAndUser();
  }

  Future<void> _fetchProfileAndUser() async {
    try {
      // 1️⃣ Kullanıcı bilgisini al (userId için)
      debugPrint('📧 Email ile doktor aranıyor: ${widget.doctorEmail}');
      
      final userRes = await http.get(
        Uri.parse('http://localhost:5080/api/auth/user/${widget.doctorEmail}')
      );
      
      debugPrint('👤 User API Response: ${userRes.statusCode}');
      debugPrint('👤 User API Body: ${userRes.body}');
      
      if (userRes.statusCode == 200) {
        final userData = jsonDecode(userRes.body);
        userId = userData['id'];
        debugPrint('✅ UserId bulundu: $userId');
      } else {
        debugPrint('❌ Kullanıcı bulunamadı! Status: ${userRes.statusCode}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Kullanıcı bulunamadı: ${widget.doctorEmail}'))
          );
        }
      }

      // 2️⃣ Profil bilgilerini çek
      if (userId != null) {
        final profileRes = await http.get(
          Uri.parse('http://localhost:5080/api/DoctorProfile/$userId')
        );
        
        debugPrint('📋 Profile API Response: ${profileRes.statusCode}');
        debugPrint('📋 Profile API Body: ${profileRes.body}');
        
        if (profileRes.statusCode == 200) {
          final data = jsonDecode(profileRes.body);
          debugPrint('📝 Gelen profil verisi: $data');
          
          nameC.text = data['firstName'] ?? data['FirstName'] ?? '';
          surnameC.text = data['lastName'] ?? data['LastName'] ?? '';
          hospitalC.text = data['hospital'] ?? data['Hospital'] ?? '';
          
          debugPrint('✅ Doktor profili yüklendi:');
          debugPrint('   Ad: ${nameC.text}, Soyad: ${surnameC.text}');
          debugPrint('   Hastane: ${hospitalC.text}');
        } else if (profileRes.statusCode == 404) {
          debugPrint('ℹ️ Henüz profil oluşturulmamış, yeni profil oluşturulacak');
        }
      }
    } catch (e) {
      debugPrint('❌ Hata: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bağlantı hatası: $e'))
        );
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kullanıcı bilgisi bulunamadı'))
      );
      return;
    }

    final body = jsonEncode({
      'userId': userId,
      'firstName': nameC.text,
      'lastName': surnameC.text,
      'hospital': hospitalC.text,
    });

    debugPrint('💾 Doktor profili kaydediliyor...');
    debugPrint('📤 Gönderilen veri: $body');

    try {
      final res = await http.post(
        Uri.parse('http://localhost:5080/api/DoctorProfile'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      debugPrint('📥 Kayıt Response: ${res.statusCode}');
      debugPrint('📥 Kayıt Body: ${res.body}');

      if (res.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Profil başarıyla kaydedildi.'))
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: ${res.body}'))
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Kayıt hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bağlantı hatası: $e'))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilim'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profil Avatar
              CircleAvatar(
                radius: 60,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(Icons.person, size: 60, color: Colors.white),
              ),
              const SizedBox(height: 24),

              _buildField('Ad', nameC),
              _buildField('Soyad', surnameC),
              _buildField('Hastane', hospitalC),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveProfile,
                  icon: const Icon(Icons.save),
                  label: const Text('Kaydet'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: c,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: Icon(
            label == 'Ad' || label == 'Soyad' ? Icons.person : Icons.local_hospital,
          ),
        ),
        validator: (v) => v?.isEmpty ?? true ? '$label zorunlu' : null,
      ),
    );
  }

  @override
  void dispose() {
    nameC.dispose();
    surnameC.dispose();
    hospitalC.dispose();
    super.dispose();
  }
}
