import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PatientProfilePage extends StatefulWidget {
  final String patientEmail; // giriş yapan hastanın maili
  const PatientProfilePage({super.key, required this.patientEmail});

  @override
  State<PatientProfilePage> createState() => _PatientProfilePageState();
}

class _PatientProfilePageState extends State<PatientProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final nameC = TextEditingController();
  final surnameC = TextEditingController();
  final heightC = TextEditingController();
  final weightC = TextEditingController();
  final hospitalC = TextEditingController(); // Hastane için controller

  int? selectedAge;
  String? selectedBloodGroup;
  int? selectedDoctorId;
  int? userId;

  List<Map<String, dynamic>> doctors = [];
  bool loading = true;

  // Yaş seçenekleri (18-100)
  final List<int> ageOptions = List.generate(83, (index) => index + 18);

  // Kan grubu seçenekleri
  final List<String> bloodGroupOptions = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', '0+', '0-'
  ];

  @override
  void initState() {
    super.initState();
    _fetchProfileAndDoctors();
  }

  Future<void> _fetchProfileAndDoctors() async {
    try {
      // 1️⃣ Kullanıcı bilgisini al (userId için)
      debugPrint('📧 Email ile kullanıcı aranıyor: ${widget.patientEmail}');
      
      final userRes = await http.get(
        Uri.parse('http://localhost:5080/api/auth/user/${widget.patientEmail}')
      );
      
      debugPrint('👤 User API Response: ${userRes.statusCode}');
      debugPrint('👤 User API Body: ${userRes.body}');
      
      if (userRes.statusCode == 200) {
        final userData = jsonDecode(userRes.body);
        userId = userData['id'];
        debugPrint('✅ UserId bulundu: $userId');
      } else {
        debugPrint('❌ Kullanıcı bulunamadı! Status: ${userRes.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kullanıcı bulunamadı: ${widget.patientEmail}'))
        );
      }

      // 2️⃣ Doktor listesini çek
      final doctorRes = await http.get(
        Uri.parse('http://localhost:5080/api/PatientProfile/doctors')
      );
      
      debugPrint('🩺 Doctors API Response: ${doctorRes.statusCode}');
      debugPrint('🩺 Doctors API Body: ${doctorRes.body}');
      
      if (doctorRes.statusCode == 200) {
        final List list = jsonDecode(doctorRes.body);
        doctors = list.where((d) {
          // Null ID'leri filtrele
          return d['id'] != null || d['Id'] != null;
        }).map((d) {
          final id = d['id'] ?? d['Id'];
          final firstName = d['name'] ?? d['Name'] ?? d['FirstName'] ?? '';
          final lastName = d['surname'] ?? d['Surname'] ?? d['LastName'] ?? '';
          final fullName = d['fullName'] ?? d['FullName'] ?? '$firstName $lastName'.trim();
          final hospital = d['DoctorHospital'] ?? d['doctorHospital'] ?? d['Hospital'] ?? '';
          
          debugPrint('🏥 Doktor: $fullName, Hastane: $hospital');
          
          return {
            'id': id is int ? id : int.tryParse(id.toString()) ?? 0,
            'fullName': fullName.isEmpty ? 'İsimsiz Doktor' : fullName,
            'hospital': hospital,
          };
        }).toList();
        
        debugPrint('✅ ${doctors.length} doktor bulundu');
        debugPrint('📋 Doktor listesi: $doctors');
      }

      // 3️⃣ Profil bilgilerini çek
      if (userId != null) {
        final profileRes = await http.get(
          Uri.parse('http://localhost:5080/api/PatientProfile/$userId')
        );
        
        debugPrint('📋 Profile API Response: ${profileRes.statusCode}');
        debugPrint('📋 Profile API Body: ${profileRes.body}');
        
        if (profileRes.statusCode == 200) {
          final data = jsonDecode(profileRes.body);
          
          // Verileri logla
          debugPrint('📝 Gelen profil verisi: $data');
          
          nameC.text = data['firstName'] ?? data['FirstName'] ?? '';
          surnameC.text = data['lastName'] ?? data['LastName'] ?? '';
          
          // Yaş için farklı alan isimleri kontrol et
          final ageValue = data['age'] ?? data['Age'];
          selectedAge = ageValue is int ? ageValue : (ageValue != null ? int.tryParse(ageValue.toString()) : null);
          
          selectedBloodGroup = data['bloodGroup'] ?? data['BloodGroup'];
          
          // Height ve Weight
          final heightValue = data['height'] ?? data['Height'];
          heightC.text = heightValue?.toString() ?? '';
          
          final weightValue = data['weight'] ?? data['Weight'];
          weightC.text = weightValue?.toString() ?? '';
          
          // Doktor ID
          final doctorIdValue = data['doctorId'] ?? data['DoctorId'];
          selectedDoctorId = doctorIdValue is int ? doctorIdValue : (doctorIdValue != null ? int.tryParse(doctorIdValue.toString()) : null);
          
          // Hastane bilgisi
          hospitalC.text = data['doctorHospital'] ?? data['DoctorHospital'] ?? '';
          
          debugPrint('✅ Profil bilgileri yüklendi:');
          debugPrint('   Ad: ${nameC.text}, Soyad: ${surnameC.text}');
          debugPrint('   Yaş: $selectedAge, Kan Grubu: $selectedBloodGroup');
          debugPrint('   Boy: ${heightC.text}, Kilo: ${weightC.text}');
          debugPrint('   Doktor ID: $selectedDoctorId, Hastane: ${hospitalC.text}');
        } else if (profileRes.statusCode == 404) {
          debugPrint('ℹ️ Henüz profil oluşturulmamış, yeni profil oluşturulacak');
        }
      }
    } catch (e) {
      debugPrint('❌ Hata: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bağlantı hatası: $e'))
      );
    } finally {
      setState(() => loading = false);
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
      'age': selectedAge,
      'bloodGroup': selectedBloodGroup,
      'height': heightC.text.isEmpty ? null : double.tryParse(heightC.text),
      'weight': weightC.text.isEmpty ? null : double.tryParse(weightC.text),
      'doctorId': selectedDoctorId,
    });

    try {
      final res = await http.post(
        Uri.parse('http://localhost:5080/api/PatientProfile'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil başarıyla kaydedildi.'))
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: ${res.body}'))
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bağlantı hatası: $e'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profilim')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildField('Ad', nameC),
              _buildField('Soyad', surnameC),
              
              // Yaş dropdown
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DropdownButtonFormField<int>(
                  value: selectedAge,
                  decoration: const InputDecoration(
                    labelText: 'Yaş',
                    border: OutlineInputBorder(),
                  ),
                  items: ageOptions.map((age) {
                    return DropdownMenuItem<int>(
                      value: age,
                      child: Text(age.toString()),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => selectedAge = val);
                  },
                  validator: (val) => val == null ? 'Yaş seçiniz' : null,
                ),
              ),

              // Kan grubu dropdown
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DropdownButtonFormField<String>(
                  value: selectedBloodGroup,
                  decoration: const InputDecoration(
                    labelText: 'Kan grubu',
                    border: OutlineInputBorder(),
                  ),
                  items: bloodGroupOptions.map((blood) {
                    return DropdownMenuItem<String>(
                      value: blood,
                      child: Text(blood),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => selectedBloodGroup = val);
                  },
                  validator: (val) => val == null ? 'Kan grubu seçiniz' : null,
                ),
              ),

              _buildField('Boy (cm)', heightC, type: TextInputType.number),
              _buildField('Kilo (kg)', weightC, type: TextInputType.number),

              const SizedBox(height: 16),

              // 🩺 Doktor seçimi
              DropdownButtonFormField<int>(
                value: selectedDoctorId,
                decoration: const InputDecoration(
                  labelText: 'Doktor Seçiniz',
                  border: OutlineInputBorder(),
                ),
                items: doctors.map((doc) {
                  final name = doc['fullName']?.toString() ?? 'İsimsiz Doktor';
                  return DropdownMenuItem<int>(
                    value: doc['id'] as int,
                    child: Text(name),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    selectedDoctorId = val;
                    // Seçilen doktorun hastane bilgisini al
                    final selectedDoc = doctors.firstWhere(
                      (d) => d['id'] == val,
                      orElse: () => {'hospital': ''},
                    );
                    hospitalC.text = selectedDoc['hospital']?.toString() ?? '';
                  });
                },
              ),

              const SizedBox(height: 12),

              // 🏥 Hastane bilgisi (otomatik)
              TextFormField(
                readOnly: true,
                controller: hospitalC,
                decoration: const InputDecoration(
                  labelText: 'Doktorun Çalıştığı Hastane',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  child: const Text('Kaydet'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController c, {TextInputType? type}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
