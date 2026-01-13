import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DoctorPatientTestsPage extends StatefulWidget {
  final String patientId;
  final String patientName;

  const DoctorPatientTestsPage({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<DoctorPatientTestsPage> createState() => _DoctorPatientTestsPageState();
}

class _DoctorPatientTestsPageState extends State<DoctorPatientTestsPage> {
  List<Map<String, dynamic>> _results = [];
  bool _loading = true;
  bool _showOnlyOutOfRange = false;

  @override
  void initState() {
    super.initState();
    _loadTests();
  }

  Future<void> _loadTests() async {
    setState(() => _loading = true);
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5080/api/test/user/${widget.patientId}'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        
        // API tarih bazlı gruplandırılmış veri döndürüyor
        // Format: [{"date": "2025-11-24", "tests": [...]}]
        setState(() {
          _results = data.map((group) => {
            'date': group['date']?.toString().split('T').first ?? '',
            'items': (group['tests'] as List<dynamic>?)
                ?.map((t) => Map<String, dynamic>.from(t))
                .toList() ?? [],
          }).toList();
          
          // Tarihe göre sırala (en yeni önce)
          _results.sort((a, b) => (b['date'] ?? '').compareTo(a['date'] ?? ''));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tahliller yüklenemedi: $e')),
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

    // Filtrelenmiş sonuçları hesapla
    List<Map<String, dynamic>> filteredResults = _results.map((group) {
      final items = group['items'] as List<Map<String, dynamic>>;
      final filteredItems = _showOnlyOutOfRange
          ? items.where((test) => test['isOutOfRange'] == true).toList()
          : items;
      return {
        'date': group['date'],
        'items': filteredItems,
      };
    }).where((group) => (group['items'] as List).isNotEmpty).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.patientName),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Ref dışı filtresi
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Sadece referans dışı sonuçlar',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                Switch(
                  value: _showOnlyOutOfRange,
                  onChanged: (value) {
                    setState(() {
                      _showOnlyOutOfRange = value;
                    });
                  },
                  activeColor: Colors.teal,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Liste
          Expanded(
            child: filteredResults.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.biotech, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Tahlil bulunmuyor',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredResults.length,
                    itemBuilder: (context, index) {
                      final group = filteredResults[index];
                      final date = group['date'];
                      final items = group['items'] as List<Map<String, dynamic>>;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ExpansionTile(
                          leading: const Icon(Icons.calendar_today, color: Colors.teal),
                          title: Text(
                            'Tahlil Tarihi: ${_formatDate(date)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('${items.length} sonuç'),
                          children: items.map((test) {
                            final isOutOfRange = test['isOutOfRange'] == true;
                            return ListTile(
                              leading: Icon(
                                isOutOfRange ? Icons.warning : Icons.check_circle,
                                color: isOutOfRange ? Colors.red : Colors.green,
                              ),
                              title: Text(test['testName'] ?? 'Bilinmeyen'),
                              subtitle: Text(
                                '${test['result']} (Ref: ${test['referenceRange'] ?? 'N/A'})',
                              ),
                              trailing: isOutOfRange
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Text(
                                        'Anormal',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    )
                                  : null,
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
          ),
        ],
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
