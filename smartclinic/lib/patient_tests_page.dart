import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/pdf_upload_service.dart';
import '../services/test_service.dart';
import 'test_list_page.dart';

class PatientTestsPage extends StatefulWidget {
  final String userId;
  final String patientEmail;

  const PatientTestsPage({
    super.key,
    required this.userId,
    required this.patientEmail,
  });

  @override
  State<PatientTestsPage> createState() => _PatientTestsPageState();
}

class _PatientTestsPageState extends State<PatientTestsPage> {
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadTestsFromDatabase(widget.userId);
  }

  Future<void> _loadTestsFromDatabase(String userId) async {
    setState(() => _loading = true);
    try {
      final data = await TestService.getUserTests(userId);
      final list = List<Map<String, dynamic>>.from(data);

      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (var item in list) {
        final dateKey = (item['date'] ?? '').split('T').first;
        grouped.putIfAbsent(dateKey, () => []).add(item);
      }

      final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

      setState(() {
        _results = sortedKeys
            .map((key) => {'date': key, 'items': grouped[key]})
            .toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Tahliller alınamadı: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickAndUploadPdf() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (picked == null) return;

    final file = File(picked.files.single.path!);

    setState(() => _loading = true);
    try {
      final response = await PdfUploadService.uploadPdf(file);
      final date = response['date'];
      final results = List<Map<String, dynamic>>.from(response['results']);

      for (var test in results) {
        await TestService.addTest({
          "userId": widget.userId,
          "testName": test['name'],
          "result": test['result'],
          "referenceRange": test['range'],
          "isOutOfRange": test['isOutOfRange'],
          "date": DateTime.now().toIso8601String(),
        });
      }

      await _loadTestsFromDatabase(widget.userId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tahliller (${date ?? "bilinmiyor"}) kaydedildi')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tahlillerim'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _loading ? null : _pickAndUploadPdf,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _results.isEmpty
              ? const Center(child: Text('Henüz bir tahlil yüklenmedi'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _results.length,
                  itemBuilder: (context, i) {
                    final group = _results[i];
                    final date = group['date'];
                    final items = group['items'] as List<Map<String, dynamic>>;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.calendar_today, color: Colors.teal),
                        title: Text('Tahlil Tarihi: $date'),
                        subtitle: Text('${items.length} sonuç mevcut'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TestListPage(
                                date: date,
                                tests: List<Map<String, dynamic>>.from(items),
                                userId: widget.userId,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
