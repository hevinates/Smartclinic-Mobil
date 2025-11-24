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
  final ageC = TextEditingController();
  final bloodC = TextEditingController();
  final heightC = TextEditingController();
  final weightC = TextEditingController();

  String? selectedDoctorId;
  String? selectedDoctorHospital;

  List<Map<String, dynamic>> doctors = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfileAndDoctors();
  }

  Future<void> _fetchProfileAndDoctors() async {
    try {
      // 1️⃣ Doktor listesini çek
      final doctorRes = await http.get(Uri.parse('http://localhost:5080/api/doctors'));
      if (doctorRes.statusCode == 200) {
        final List list = jsonDecode(doctorRes.body);
        doctors = list.map((d) => {
          'id': d['_id'],
          'firstName': d['firstName'],
          'lastName': d['lastName'],
          'hospital': d['hospital'],
        }).toList();
      }

      // 2️⃣ Hasta profilini çek
      final patientRes = await http.get(Uri.parse('http://localhost:5080/api/patients/${widget.patientEmail}'));
      if (patientRes.statusCode == 200) {
        final data = jsonDecode(patientRes.body);
        nameC.text = data['firstName'] ?? '';
        surnameC.text = data['lastName'] ?? '';
        ageC.text = data['age']?.toString() ?? '';
        bloodC.text = data['bloodGroup'] ?? '';
        heightC.text = data['height']?.toString() ?? '';
        weightC.text = data['weight']?.toString() ?? '';
        selectedDoctorId = data['doctorId'];
        selectedDoctorHospital = data['doctorHospital'];
      }
    } catch (e) {
      debugPrint('Profil verisi alınamadı: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final body = jsonEncode({
      'firstName': nameC.text,
      'lastName': surnameC.text,
      'age': int.tryParse(ageC.text),
      'bloodGroup': bloodC.text,
      'height': double.tryParse(heightC.text),
      'weight': double.tryParse(weightC.text),
      'doctorId': selectedDoctorId,
      'doctorHospital': selectedDoctorHospital,
    });

    try {
      final res = await http.put(
        Uri.parse('http://localhost:5080/api/patients/${widget.patientEmail}'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Profil başarıyla güncellendi.')));
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Hata: ${res.body}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Bağlantı hatası: $e')));
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
              _buildField('Yaş', ageC, type: TextInputType.number),
              _buildField('Kan grubu', bloodC),
              _buildField('Boy (cm)', heightC, type: TextInputType.number),
              _buildField('Kilo (kg)', weightC, type: TextInputType.number),

              const SizedBox(height: 16),

              // 🩺 Doktor seçimi
              DropdownButtonFormField<String>(
                value: selectedDoctorId,
                decoration: const InputDecoration(
                  labelText: 'Doktor Seçiniz',
                  border: OutlineInputBorder(),
                ),
                items: doctors.map((doc) {
                  final name = '${doc['firstName']} ${doc['lastName']}';
                  return DropdownMenuItem<String>(
                    value: doc['id'],
                    child: Text(name),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    selectedDoctorId = val;
                    selectedDoctorHospital = doctors
                        .firstWhere((d) => d['id'] == val)['hospital']
                        .toString();
                  });
                },
              ),

              const SizedBox(height: 12),

              // 🏥 Hastane bilgisi
              TextFormField(
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Doktorun Çalıştığı Hastane',
                  border: OutlineInputBorder(),
                ),
                controller: TextEditingController(text: selectedDoctorHospital ?? ''),
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
