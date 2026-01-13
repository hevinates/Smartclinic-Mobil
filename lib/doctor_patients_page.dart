import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'doctor_patient_tests_page.dart';

class DoctorPatientsPage extends StatefulWidget {
  final String doctorEmail;

  const DoctorPatientsPage({
    super.key,
    required this.doctorEmail,
  });

  @override
  State<DoctorPatientsPage> createState() => _DoctorPatientsPageState();
}

class _DoctorPatientsPageState extends State<DoctorPatientsPage> {
  List<Map<String, dynamic>> _patients = [];
  bool _loading = true;
  int? _doctorUserId;

  @override
  void initState() {
    super.initState();
    _loadDoctorAndPatients();
  }

  Future<void> _loadDoctorAndPatients() async {
    setState(() => _loading = true);
    try {
      // 1️⃣ Önce doktor userId'sini al
      debugPrint('📧 Email ile doktor aranıyor: ${widget.doctorEmail}');
      
      final userRes = await http.get(
        Uri.parse('http://localhost:5080/api/auth/user/${widget.doctorEmail}')
      );
      
      debugPrint('👤 User API Response: ${userRes.statusCode}');
      
      if (userRes.statusCode == 200) {
        final userData = jsonDecode(userRes.body);
        _doctorUserId = userData['id'];
        debugPrint('✅ Doctor UserId bulundu: $_doctorUserId');
        
        // 2️⃣ Şimdi bu doktorun hastalarını çek
        final patientsRes = await http.get(
          Uri.parse('http://localhost:5080/api/DoctorProfile/patients/$_doctorUserId')
        );
        
        debugPrint('🏥 Patients API Response: ${patientsRes.statusCode}');
        debugPrint('🏥 Patients API Body: ${patientsRes.body}');
        
        if (patientsRes.statusCode == 200) {
          final List data = jsonDecode(patientsRes.body);
          setState(() {
            _patients = data.map((p) => {
              'userId': p['userId'] ?? p['UserId'],
              'firstName': p['firstName'] ?? p['FirstName'] ?? '',
              'lastName': p['lastName'] ?? p['LastName'] ?? '',
              'age': p['age'] ?? p['Age'],
              'bloodGroup': p['bloodGroup'] ?? p['BloodGroup'] ?? '',
              'email': p['email'] ?? p['Email'] ?? '',
            }).toList();
          });
          debugPrint('✅ ${_patients.length} hasta bulundu');
        }
      }
    } catch (e) {
      debugPrint('❌ Hata: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hastalar yüklenemedi: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hastalarım'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _patients.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Henüz sizi seçen hasta bulunmuyor',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _patients.length,
              itemBuilder: (context, index) {
                final patient = _patients[index];
                return _PatientCard(
                  patient: patient,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DoctorPatientTestsPage(
                          patientId: patient['userId'].toString(),
                          patientName: '${patient['firstName']} ${patient['lastName']}',
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final Map<String, dynamic> patient;
  final VoidCallback onTap;

  const _PatientCard({
    required this.patient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = '${patient['firstName']} ${patient['lastName']}';
    final age = patient['age']?.toString() ?? 'Belirtilmemiş';
    final bloodGroup = patient['bloodGroup'] ?? 'Belirtilmemiş';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.cake, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text('$age yaş', style: TextStyle(color: Colors.grey[600])),
                        const SizedBox(width: 16),
                        Icon(Icons.bloodtype, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(bloodGroup, style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
