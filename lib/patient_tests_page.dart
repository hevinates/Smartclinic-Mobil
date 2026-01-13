import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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
  String? _errorMessage;
  int? _realUserId; // Gerçek integer userId

  @override
  void initState() {
    super.initState();
    _initializeAndLoadTests();
  }

  Future<void> _initializeAndLoadTests() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      // Önce gerçek userId'yi al
      final userRes = await http.get(
        Uri.parse('http://localhost:5080/api/auth/user/${widget.patientEmail}')
      );
      
      if (userRes.statusCode == 200) {
        final userData = jsonDecode(userRes.body);
        _realUserId = userData['id'];
        print('✅ Gerçek userId alındı: $_realUserId');
        
        // Sonra tahlilleri yükle
        await _loadTestsFromDatabase(_realUserId.toString());
      } else {
        throw Exception('Kullanıcı bilgisi alınamadı');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Tahliller yüklenemedi: $e';
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadTestsFromDatabase(String userId) async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    
    try {
      final data = await TestService.getUserTests(userId);
      
      // API zaten tarih bazlı gruplandırılmış veri döndürüyor
      // Format: [{"date": "2025-11-24", "tests": [...]}]
      final List<Map<String, dynamic>> groupedResults = [];
      
      for (var item in data) {
        final dateKey = item['date'] ?? '';
        final tests = item['tests'] as List<dynamic>? ?? [];
        
        groupedResults.add({
          'date': dateKey,
          'items': tests.map((t) => Map<String, dynamic>.from(t)).toList(),
        });
      }
      
      // Tarihe göre sırala (en yeni önce)
      groupedResults.sort((a, b) => (b['date'] ?? '').compareTo(a['date'] ?? ''));

      setState(() {
        _results = groupedResults;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Tahliller yüklenemedi: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tahliller alınamadı: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickAndUploadPdf() async {
    if (_realUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kullanıcı bilgisi alınamadı'), backgroundColor: Colors.red),
      );
      return;
    }

    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (picked == null) return;

    final file = File(picked.files.single.path!);

    setState(() => _loading = true);
    try {
      print("🔄 PDF yükleme başlıyor...");
      final response = await PdfUploadService.uploadPdf(file);
      final date = response['date'];
      final results = List<Map<String, dynamic>>.from(response['results']);

      print("✅ PDF analiz edildi. ${results.length} sonuç bulundu.");

      // Her PDF yüklemesi için benzersiz batchId oluştur
      final batchId = DateTime.now().millisecondsSinceEpoch.toString();

      for (var i = 0; i < results.length; i++) {
        var test = results[i];
        print("💾 Tahlil kaydediliyor ${i + 1}/${results.length}: ${test['name']}");
        
        await TestService.addTest({
          "userId": _realUserId,
          "testName": test['name'],
          "result": test['result'],
          "referenceRange": test['range'],
          "isOutOfRange": test['isOutOfRange'],
          "batchId": batchId, // Benzersiz grup ID'si
          "date": DateTime.now().toUtc().toIso8601String(),
        });
      }

      print("✅ Tüm tahliller kaydedildi. Veritabanından yeniden yükleniyor...");
      await _loadTestsFromDatabase(_realUserId.toString());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${results.length} tahlil başarıyla kaydedildi (${date ?? "bilinmiyor"})'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print("❌ HATA DETAYI: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Hata: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  int _getOutOfRangeCount(List<dynamic> items) {
    return items.where((item) => item['isOutOfRange'] == true).length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tahlillerim'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'PDF Yükle',
            onPressed: _loading ? null : _pickAndUploadPdf,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_errorMessage!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _initializeAndLoadTests,
                        child: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                )
              : _results.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.science_outlined, size: 80, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'Henüz tahlil yüklenmedi',
                            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sağ üstteki + butonuna tıklayarak\nPDF formatında tahlil yükleyebilirsiniz.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _pickAndUploadPdf,
                            icon: const Icon(Icons.upload_file),
                            label: const Text('PDF Yükle'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _initializeAndLoadTests,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _results.length,
                        itemBuilder: (context, i) {
                          final group = _results[i];
                          final date = group['date'] as String;
                          final items = group['items'] as List<dynamic>;
                          final outOfRangeCount = _getOutOfRangeCount(items);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TestListPage(
                                      date: date,
                                      tests: items.map((t) => Map<String, dynamic>.from(t)).toList(),
                                      userId: widget.userId,
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.science,
                                        color: theme.colorScheme.primary,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _formatDate(date),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${items.length} sonuç',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          if (outOfRangeCount > 0)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 4),
                                              child: Row(
                                                children: [
                                                  Icon(Icons.warning_amber, size: 16, color: Colors.orange[700]),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '$outOfRangeCount değer referans dışı',
                                                    style: TextStyle(
                                                      color: Colors.orange[700],
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      color: Colors.grey[400],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
