import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PatientAppointmentPage extends StatefulWidget {
  final String userId;
  final String patientEmail;

  const PatientAppointmentPage({
    super.key,
    required this.userId,
    required this.patientEmail,
  });

  @override
  State<PatientAppointmentPage> createState() => _PatientAppointmentPageState();
}

class _PatientAppointmentPageState extends State<PatientAppointmentPage> {
  final _reasonController = TextEditingController();
  List<Map<String, dynamic>> _appointments = [];
  Map<String, dynamic>? _doctorInfo;
  int? _patientUserId;
  int? _doctorId;
  DateTime? _selectedDate;
  String? _selectedTime;
  bool _loading = true;
  bool _showForm = false;

  final List<String> _timeSlots = [
    '09:00', '09:30', '10:00', '10:30', '11:00', '11:30',
    '13:00', '13:30', '14:00', '14:30', '15:00', '15:30', '16:00', '16:30',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      // 1️⃣ Hasta userId'sini al
      final userRes = await http.get(
        Uri.parse('http://localhost:5080/api/auth/user/${widget.patientEmail}')
      );
      
      if (userRes.statusCode == 200) {
        final userData = jsonDecode(userRes.body);
        _patientUserId = userData['id'];
        
        // 2️⃣ Hasta profilinden doktor bilgisini al
        final profileRes = await http.get(
          Uri.parse('http://localhost:5080/api/PatientProfile/$_patientUserId')
        );
        
        if (profileRes.statusCode == 200) {
          final profileData = jsonDecode(profileRes.body);
          _doctorId = profileData['doctorId'] ?? profileData['DoctorId'];
          
          if (_doctorId != null) {
            // 3️⃣ Doktor bilgilerini al
            final doctorRes = await http.get(
              Uri.parse('http://localhost:5080/api/DoctorProfile/$_doctorId')
            );
            
            if (doctorRes.statusCode == 200) {
              final doctorData = jsonDecode(doctorRes.body);
              setState(() {
                _doctorInfo = {
                  'id': _doctorId,
                  'firstName': doctorData['firstName'] ?? doctorData['FirstName'] ?? '',
                  'lastName': doctorData['lastName'] ?? doctorData['LastName'] ?? '',
                  'hospital': doctorData['hospital'] ?? doctorData['Hospital'] ?? '',
                };
              });
            }
          }
        }
        
        // 4️⃣ Randevuları yükle
        await _loadAppointments();
      }
    } catch (e) {
      debugPrint('Veri yüklenemedi: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadAppointments() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5080/api/appointments/patient/$_patientUserId'),
      );
      
      debugPrint('📅 Appointments Response: ${response.statusCode}');
      debugPrint('📅 Appointments Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          _appointments = data.map((a) => {
            'id': a['id'] ?? a['Id'],
            'doctorId': a['doctorId'] ?? a['DoctorId'],
            'doctorName': a['doctorName'] ?? a['DoctorName'] ?? 'Dr. ${_doctorInfo?['firstName'] ?? ''} ${_doctorInfo?['lastName'] ?? ''}',
            'appointmentDate': a['appointmentDate'] ?? a['AppointmentDate'],
            'appointmentTime': a['appointmentTime'] ?? a['AppointmentTime'],
            'reason': a['reason'] ?? a['Reason'] ?? '',
            'status': a['status'] ?? a['Status'] ?? 'Pending',
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Randevular yüklenemedi: $e');
    }
  }

  Future<void> _bookAppointment() async {
    if (_doctorId == null || _selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tarih ve saat seçin')),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5080/api/appointments'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'patientId': _patientUserId,
          'doctorId': _doctorId,
          'appointmentDate': _selectedDate!.toIso8601String().split('T')[0],
          'appointmentTime': _selectedTime,
          'reason': _reasonController.text,
          'status': 'Pending',
        }),
      );

      debugPrint('📤 Book Response: ${response.statusCode}');
      debugPrint('📤 Book Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Randevu talebiniz gönderildi!'),
            backgroundColor: Colors.green,
          ),
        );
        _resetForm();
        await _loadAppointments();
      } else {
        throw Exception('Randevu oluşturulamadı');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  Future<void> _cancelAppointment(int appointmentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Randevu İptal'),
        content: const Text('Bu randevuyu iptal etmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('İptal Et'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await http.delete(
        Uri.parse('http://localhost:5080/api/appointments/$appointmentId'),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Randevu iptal edildi'),
            backgroundColor: Colors.orange,
          ),
        );
        await _loadAppointments();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  void _resetForm() {
    setState(() {
      _selectedDate = null;
      _selectedTime = null;
      _reasonController.clear();
      _showForm = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);

    // Doktor seçilmemişse
    if (_doctorInfo == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Randevularım'),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Henüz bir doktor seçmediniz.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'Randevu almak için önce profilinizden\ndoktorunuzu seçmelisiniz.',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final doctorName = 'Dr. ${_doctorInfo!['firstName']} ${_doctorInfo!['lastName']}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Randevularım'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doktor Bilgisi
            Card(
              color: theme.colorScheme.primary.withOpacity(0.1),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primary,
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                title: Text(doctorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(_doctorInfo!['hospital'] ?? ''),
              ),
            ),

            const SizedBox(height: 16),

            // Yeni Randevu Butonu veya Form
            if (!_showForm) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _showForm = true),
                  icon: const Icon(Icons.add),
                  label: const Text('Yeni Randevu Al'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ] else ...[
              // Randevu Formu
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Yeni Randevu',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: _resetForm,
                          ),
                        ],
                      ),
                      const Divider(),

                      // Tarih Seçimi
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(const Duration(days: 1)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 90)),
                          );
                          if (date != null) {
                            setState(() => _selectedDate = date);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Tarih Seçin',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            _selectedDate == null
                                ? 'Tarih seçilmedi'
                                : '${_selectedDate!.day}.${_selectedDate!.month}.${_selectedDate!.year}',
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Saat Seçimi
                      DropdownButtonFormField<String>(
                        value: _selectedTime,
                        decoration: const InputDecoration(
                          labelText: 'Saat Seçin',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.access_time),
                        ),
                        items: _timeSlots.map((time) {
                          return DropdownMenuItem(
                            value: time,
                            child: Text(time),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedTime = value);
                        },
                      ),

                      const SizedBox(height: 16),

                      // Sebep
                      TextField(
                        controller: _reasonController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Randevu Sebebi (Opsiyonel)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.note),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Gönder Butonu
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _bookAppointment,
                          icon: const Icon(Icons.send),
                          label: const Text('Randevu Talep Et'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Randevularım Başlığı
            Text(
              'Randevu Geçmişi',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Randevu Listesi
            if (_appointments.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.event_busy, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        const Text(
                          'Henüz randevunuz bulunmuyor',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ..._appointments.map((appointment) => _AppointmentCard(
                appointment: appointment,
                onCancel: () => _cancelAppointment(appointment['id']),
              )),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }
}

class _AppointmentCard extends StatelessWidget {
  final Map<String, dynamic> appointment;
  final VoidCallback onCancel;

  const _AppointmentCard({
    required this.appointment,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final status = appointment['status'] ?? 'Pending';
    final doctorName = appointment['doctorName'] ?? 'Bilinmiyor';
    final date = appointment['appointmentDate'] ?? '';
    final time = appointment['appointmentTime'] ?? '';
    final reason = appointment['reason'] ?? '';

    Color statusColor;
    IconData statusIcon;
    String statusText;
    bool canCancel = false;

    switch (status) {
      case 'Approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Onaylandı ✓';
        canCancel = true;
        break;
      case 'Rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Reddedildi ✗';
        break;
      case 'Completed':
        statusColor = Colors.blue;
        statusIcon = Icons.done_all;
        statusText = 'Tamamlandı ✓';
        break;
      case 'Cancelled':
        statusColor = Colors.grey;
        statusIcon = Icons.block;
        statusText = 'İptal Edildi';
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusText = 'Onay Bekliyor ⏳';
        canCancel = true;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctorName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        statusText,
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                if (canCancel)
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: onCancel,
                    tooltip: 'İptal Et',
                  ),
              ],
            ),
            const Divider(),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(_formatDate(date)),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(time),
              ],
            ),
            if (reason.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.note, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(child: Text(reason)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}.${date.month}.${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}
