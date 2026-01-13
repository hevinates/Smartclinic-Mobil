import 'package:flutter/material.dart';
import 'services/test_service.dart';

class PatientReportsPage extends StatefulWidget {
  final String userId;
  final String patientEmail;

  const PatientReportsPage({
    super.key,
    required this.userId,
    required this.patientEmail,
  });

  @override
  State<PatientReportsPage> createState() => _PatientReportsPageState();
}

class _PatientReportsPageState extends State<PatientReportsPage> {
  bool _loading = true;
  int _totalTests = 0;
  int _outOfRangeTests = 0;
  int _inRangeTests = 0;
  int _totalDates = 0;
  List<Map<String, dynamic>> _recentTests = [];

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() => _loading = true);
    try {
      // TestService kullanarak tahlilleri çek
      final data = await TestService.getUserTests(widget.userId);
      
      // API tarih bazlı gruplandırılmış veri döndürüyor
      // Format: [{"date": "2025-11-24", "tests": [...]}]
      int totalTests = 0;
      int outOfRange = 0;
      List<Map<String, dynamic>> allTests = [];
      
      for (var group in data) {
        final tests = group['tests'] as List<dynamic>? ?? [];
        for (var test in tests) {
          totalTests++;
          if (test['isOutOfRange'] == true) {
            outOfRange++;
          }
          allTests.add(Map<String, dynamic>.from(test));
        }
      }

      // Son 5 tahlili al (tarihe göre sıralı)
      allTests.sort((a, b) {
        final dateA = a['date']?.toString() ?? '';
        final dateB = b['date']?.toString() ?? '';
        return dateB.compareTo(dateA);
      });

      setState(() {
        _totalDates = data.length;
        _totalTests = totalTests;
        _outOfRangeTests = outOfRange;
        _inRangeTests = totalTests - outOfRange;
        _recentTests = allTests.take(5).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rapor verileri alınamadı: $e')),
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

    final theme = Theme.of(context);
    final double percentage = _totalTests > 0 
        ? (_inRangeTests / _totalTests) * 100 
        : 0;
    
    // Renk belirleme: 80+ yeşil, 60-80 turuncu, 60- kırmızı
    Color scoreColor;
    if (percentage > 80) {
      scoreColor = Colors.green;
    } else if (percentage >= 60) {
      scoreColor = Colors.orange;
    } else {
      scoreColor = Colors.red;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Raporlama'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadReportData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Özet İstatistikler
              Text(
                'Tahlil Özeti',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Toplam Değer',
                      value: _totalTests.toString(),
                      icon: Icons.biotech,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Toplam Tahlil',
                      value: _totalDates.toString(),
                      icon: Icons.calendar_today,
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Normal Değerler',
                      value: _inRangeTests.toString(),
                      icon: Icons.check_circle,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Anormal Değerler',
                      value: _outOfRangeTests.toString(),
                      icon: Icons.cancel,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Sağlık Skoru Kartı
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: scoreColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.favorite,
                          color: scoreColor,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sağlık Skoru',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            Text(
                              '${percentage.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: scoreColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Progress göstergesi
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(
                          value: percentage / 100,
                          strokeWidth: 6,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Görsel Gösterim
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Tahlil Dağılımı',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Basit progress bar gösterimi
                      SizedBox(
                        height: 120,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _BarChart(
                              label: 'Normal',
                              value: _inRangeTests,
                              maxValue: _totalTests,
                              color: Colors.green,
                            ),
                            _BarChart(
                              label: 'Anormal',
                              value: _outOfRangeTests,
                              maxValue: _totalTests,
                              color: Colors.red,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Son Tahliller
              if (_recentTests.isNotEmpty) ...[
                Text(
                  'Son Tahliller',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                ..._recentTests.map((test) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (test['isOutOfRange'] == true ? Colors.red : Colors.green).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        test['isOutOfRange'] == true 
                            ? Icons.warning_amber 
                            : Icons.check_circle_outline,
                        color: test['isOutOfRange'] == true 
                            ? Colors.red 
                            : Colors.green,
                      ),
                    ),
                    title: Text(
                      test['testName'] ?? 'Bilinmeyen',
                      style: TextStyle(
                        color: test['isOutOfRange'] == true ? Colors.red[700] : null,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Sonuç: ${test['result']} | Ref: ${test['referenceRange'] ?? 'N/A'}',
                    ),
                    trailing: Text(
                      _formatDate(test['date']),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                )),
              ],

              const SizedBox(height: 16),

              // Genel Değerlendirme
              Card(
                color: percentage > 80 
                    ? Colors.green.shade50 
                    : percentage >= 60
                        ? Colors.orange.shade50
                        : Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            percentage > 80 
                                ? Icons.sentiment_satisfied 
                                : percentage >= 60
                                    ? Icons.sentiment_neutral
                                    : Icons.sentiment_dissatisfied,
                            color: scoreColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Genel Değerlendirme',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _totalTests == 0
                            ? 'Henüz tahlil sonucu bulunmuyor. Tahlil yükleyerek sağlık durumunuzu takip edebilirsiniz. 📋'
                            : percentage > 80
                                ? 'Tahlil sonuçlarınız genel olarak normal aralıkta. Sağlığınıza dikkat etmeye devam edin! 💪'
                                : percentage >= 60
                                    ? 'Tahlil sonuçlarınızın bir kısmı normal aralık dışında. Sağlığınızı izlemeye devam edin. 🩺'
                                    : 'Bazı tahlil sonuçlarınız normal aralık dışında. Doktorunuzla görüşmeniz önerilir. 🩺',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '-';
    try {
      final dt = DateTime.parse(date.toString());
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (e) {
      return '-';
    }
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  final String label;
  final int value;
  final int maxValue;
  final Color color;

  const _BarChart({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final height = maxValue > 0 ? (value / maxValue) * 80 : 0.0;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          value.toString(),
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Container(
          width: 60,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
