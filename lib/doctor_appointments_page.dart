import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DoctorAppointmentsPage extends StatefulWidget {
  final String doctorId;
  final String doctorEmail;

  const DoctorAppointmentsPage({
    super.key,
    required this.doctorId,
    required this.doctorEmail,
  });

  @override
  State<DoctorAppointmentsPage> createState() => _DoctorAppointmentsPageState();
}

class _DoctorAppointmentsPageState extends State<DoctorAppointmentsPage> {
  List<Map<String, dynamic>> _appointments = [];
  bool _loading = true;
  String _filter = 'All'; // All, Pending, Approved, Completed, Rejected
  int? _doctorUserId;

  @override
  void initState() {
    super.initState();
    _loadDoctorAndAppointments();
  }

  Future<void> _loadDoctorAndAppointments() async {
    setState(() => _loading = true);
    try {
      // Doktor userId'sini al
      final userRes = await http.get(
        Uri.parse('http://localhost:5080/api/auth/user/${widget.doctorEmail}')
      );
      
      if (userRes.statusCode == 200) {
        final userData = jsonDecode(userRes.body);
        _doctorUserId = userData['id'];
        await _loadAppointments();
      }
    } catch (e) {
      debugPrint('Hata: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadAppointments() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5080/api/appointments/doctor/$_doctorUserId'),
      );

      debugPrint('📅 Doctor Appointments Response: ${response.statusCode}');
      debugPrint('📅 Doctor Appointments Body: ${response.body}');

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          _appointments = data.map((a) {
            // Tarih formatını düzelt
            String dateStr = '';
            var rawDate = a['appointmentDate'] ?? a['AppointmentDate'];
            if (rawDate != null) {
              dateStr = rawDate.toString().split('T')[0];
            }
            
            // Hasta ismini al
            String patientName = a['patientname'] ?? a['patientName'] ?? a['PatientName'] ?? 'Hasta';
            
            return {
              'id': a['id'] ?? a['Id'],
              'patientId': a['patientId'] ?? a['PatientId'],
              'patientName': patientName.trim(),
              'appointmentDate': dateStr,
              'appointmentTime': a['appointmenttime'] ?? a['appointmentTime'] ?? a['AppointmentTime'] ?? '',
              'reason': a['reason'] ?? a['Reason'] ?? '',
              'status': a['status'] ?? a['Status'] ?? 'Pending',
            };
          }).toList();
        });
        debugPrint('✅ ${_appointments.length} randevu yüklendi');
        for (var a in _appointments) {
          debugPrint('   - ${a['patientName']} | ${a['appointmentDate']} ${a['appointmentTime']} | ${a['status']}');
        }
      }
    } catch (e) {
      debugPrint('❌ Randevular yüklenemedi: $e');
    }
  }

  Future<void> _approveAppointment(int appointmentId) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:5080/api/appointments/$appointmentId/approve'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Randevu onaylandı!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadAppointments();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  Future<void> _rejectAppointment(int appointmentId, String? note) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:5080/api/appointments/$appointmentId/reject'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'note': note}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Randevu reddedildi'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadAppointments();
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
        _loadAppointments();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  void _showRejectDialog(int appointmentId) {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Randevuyu Reddet'),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(
            labelText: 'Red sebebi (opsiyonel)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _rejectAppointment(appointmentId, noteController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reddet'),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredAppointments {
    if (_filter == 'All') return _appointments;
    return _appointments.where((a) => a['status'] == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final filtered = _filteredAppointments;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Randevularım'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  _FilterChip('All', 'Tümü', _appointments.length),
                  _FilterChip('Pending', 'Bekleyen', 
                    _appointments.where((a) => a['status'] == 'Pending').length),
                  _FilterChip('Approved', 'Onaylı', 
                    _appointments.where((a) => a['status'] == 'Approved').length),
                  _FilterChip('Completed', 'Tamamlandı', 
                    _appointments.where((a) => a['status'] == 'Completed').length),
                  _FilterChip('Rejected', 'Reddedildi', 
                    _appointments.where((a) => a['status'] == 'Rejected').length),
                ],
              ),
            ),
          ),
        ),
      ),
      body: filtered.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    _filter == 'All' 
                        ? 'Henüz randevu bulunmuyor'
                        : 'Bu kategoride randevu yok',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final appointment = filtered[index];
                return _AppointmentCard(
                  appointment: appointment,
                  onApprove: () => _approveAppointment(appointment['id']),
                  onReject: () => _showRejectDialog(appointment['id']),
                  onCancel: () => _cancelAppointment(appointment['id']),
                );
              },
            ),
    );
  }

  Widget _FilterChip(String value, String label, int count) {
    final isSelected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text('$label ($count)'),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _filter = value);
        },
        backgroundColor: Colors.grey[200],
        selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        checkmarkColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final Map<String, dynamic> appointment;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onCancel;

  const _AppointmentCard({
    required this.appointment,
    required this.onApprove,
    required this.onReject,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final status = appointment['status'] ?? 'Pending';
    final patientName = appointment['patientName'] ?? 'Bilinmeyen';
    final date = appointment['appointmentDate'] ?? '';
    final time = appointment['appointmentTime'] ?? '';
    final reason = appointment['reason'] ?? '';

    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'Approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'Rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'Completed':
        statusColor = Colors.blue;
        statusIcon = Icons.done_all;
        break;
      case 'Cancelled':
        statusColor = Colors.grey;
        statusIcon = Icons.block;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: statusColor.withOpacity(0.2),
                  child: Icon(statusIcon, color: statusColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patientName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _getStatusText(status),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // İptal butonu (Pending ve Approved için)
                if (status == 'Pending' || status == 'Approved')
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: onCancel,
                    tooltip: 'İptal Et',
                  ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(_formatDate(date)),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(time),
              ],
            ),
            if (reason.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.note, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(child: Text(reason)),
                ],
              ),
            ],
            if (status == 'Pending') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.close),
                      label: const Text('Reddet'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onApprove,
                      icon: const Icon(Icons.check),
                      label: const Text('Onayla'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
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

  String _getStatusText(String status) {
    switch (status) {
      case 'Approved':
        return 'Onaylandı ✓';
      case 'Rejected':
        return 'Reddedildi ✗';
      case 'Completed':
        return 'Tamamlandı ✓';
      default:
        return 'Onay Bekliyor ⏳';
    }
  }
}
