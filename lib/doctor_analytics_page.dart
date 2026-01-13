import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'doctor_patient_tests_page.dart';

class DoctorAnalyticsPage extends StatefulWidget {
  final String doctorId;
  final String doctorEmail;

  const DoctorAnalyticsPage({
    super.key,
    required this.doctorId,
    required this.doctorEmail,
  });

  @override
  State<DoctorAnalyticsPage> createState() => _DoctorAnalyticsPageState();
}

class _DoctorAnalyticsPageState extends State<DoctorAnalyticsPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _patients = [];
  int? _doctorUserId;

  // Tahlil istatistikleri
  int _totalTests = 0;
  int _totalOutOfRange = 0;
  int _patientsWithTests = 0;
  Map<String, int> _testTypeDistribution = {};
  List<Map<String, dynamic>> _recentAbnormalTests = [];
  
  // Her hasta için ayrı istatistikler
  Map<String, Map<String, dynamic>> _patientStats = {};

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _loading = true);
    try {
      // 1️⃣ Önce doktor userId'sini al
      final userRes = await http.get(
        Uri.parse('http://localhost:5080/api/auth/user/${widget.doctorEmail}')
      );

      if (userRes.statusCode == 200) {
        final userData = jsonDecode(userRes.body);
        _doctorUserId = userData['id'];

        // 2️⃣ Doktorun hastalarını çek
        final patientsRes = await http.get(
          Uri.parse('http://localhost:5080/api/DoctorProfile/patients/$_doctorUserId')
        );

        if (patientsRes.statusCode == 200) {
          final List data = jsonDecode(patientsRes.body);
          _patients = data.map((p) => {
            'userId': p['userId'] ?? p['UserId'],
            'firstName': p['firstName'] ?? p['FirstName'] ?? '',
            'lastName': p['lastName'] ?? p['LastName'] ?? '',
            'age': p['age'] ?? p['Age'],
            'bloodGroup': p['bloodGroup'] ?? p['BloodGroup'] ?? '',
            'gender': p['gender'] ?? p['Gender'] ?? '',
          }).toList();

          // 3️⃣ Her hasta için tahlillerini çek
          await _loadAllPatientTests();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Veriler yüklenemedi: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadAllPatientTests() async {
    int totalTests = 0;
    int outOfRange = 0;
    int patientsWithTests = 0;
    Map<String, int> testTypes = {};
    List<Map<String, dynamic>> abnormalTests = [];
    Map<String, Map<String, dynamic>> patientStats = {};

    for (var patient in _patients) {
      final patientId = patient['userId']?.toString();
      if (patientId == null) continue;

      // Her hasta için istatistik başlat
      int patientTotalTests = 0;
      int patientOutOfRange = 0;

      try {
        final testRes = await http.get(
          Uri.parse('http://localhost:5080/api/test/user/$patientId')
        );

        if (testRes.statusCode == 200) {
          final List<dynamic> testData = jsonDecode(testRes.body);
          bool hasTests = false;

          for (var group in testData) {
            final tests = group['tests'] as List<dynamic>? ?? [];
            for (var test in tests) {
              hasTests = true;
              totalTests++;
              patientTotalTests++;

              // Test türü dağılımı
              final testName = test['testName']?.toString() ?? 'Diğer';
              testTypes[testName] = (testTypes[testName] ?? 0) + 1;

              // Anormal testleri topla
              if (test['isOutOfRange'] == true) {
                outOfRange++;
                patientOutOfRange++;
                abnormalTests.add({
                  'patientName': '${patient['firstName']} ${patient['lastName']}',
                  'patientId': patientId,
                  'testName': testName,
                  'result': test['result'],
                  'referenceRange': test['referenceRange'],
                  'date': test['date'] ?? group['date'],
                });
              }
            }
          }

          if (hasTests) patientsWithTests++;
        }
      } catch (e) {
        print('Hasta $patientId tahlilleri alınamadı: $e');
      }

      // Hasta istatistiklerini kaydet
      patientStats[patientId] = {
        'name': '${patient['firstName']} ${patient['lastName']}',
        'totalTests': patientTotalTests,
        'outOfRange': patientOutOfRange,
        'normalTests': patientTotalTests - patientOutOfRange,
        'healthPercentage': patientTotalTests > 0 
            ? ((patientTotalTests - patientOutOfRange) / patientTotalTests * 100)
            : 100.0,
      };
    }

    // Son anormal testleri tarihe göre sırala
    abnormalTests.sort((a, b) {
      final dateA = a['date']?.toString() ?? '';
      final dateB = b['date']?.toString() ?? '';
      return dateB.compareTo(dateA);
    });

    setState(() {
      _totalTests = totalTests;
      _totalOutOfRange = outOfRange;
      _patientsWithTests = patientsWithTests;
      _testTypeDistribution = testTypes;
      _recentAbnormalTests = abnormalTests.take(10).toList();
      _patientStats = patientStats;
    });
  }

  // Kan grubu dağılımını hesapla
  Map<String, int> _getBloodGroupDistribution() {
    Map<String, int> distribution = {};
    for (var p in _patients) {
      final bloodGroup = p['bloodGroup']?.toString() ?? 'Belirtilmemiş';
      if (bloodGroup.isNotEmpty) {
        distribution[bloodGroup] = (distribution[bloodGroup] ?? 0) + 1;
      }
    }
    return distribution;
  }

  // Cinsiyet dağılımını hesapla
  Map<String, int> _getGenderDistribution() {
    int male = 0, female = 0, other = 0;
    for (var p in _patients) {
      final gender = p['gender']?.toString().toLowerCase() ?? '';
      if (gender == 'erkek' || gender == 'male') {
        male++;
      } else if (gender == 'kadın' || gender == 'female') {
        female++;
      } else if (gender.isNotEmpty) {
        other++;
      }
    }
    return {'Erkek': male, 'Kadın': female, 'Diğer': other};
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);
    final totalPatients = _patients.length;

    final bloodGroupDist = _getBloodGroupDistribution();
    final genderDist = _getGenderDistribution();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analizler'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAnalytics,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Genel İstatistikler
              Text(
                'Genel Bakış',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Hasta ve Tahlil Kartları
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Toplam Hasta',
                      value: totalPatients.toString(),
                      icon: Icons.people,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Tahlilli Hasta',
                      value: _patientsWithTests.toString(),
                      icon: Icons.assignment_ind,
                      color: Colors.teal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Toplam Tahlil',
                      value: _totalTests.toString(),
                      icon: Icons.biotech,
                      color: Colors.purple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Anormal Sonuç',
                      value: _totalOutOfRange.toString(),
                      icon: Icons.warning_amber,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Sağlık Durumu Özeti - Her hasta ayrı ayrı
              if (_patientStats.isNotEmpty) ...[
                Text(
                  'Hastalarınızın Sağlık Durumu',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ..._patients.map((patient) {
                  final patientId = patient['userId']?.toString();
                  final stats = _patientStats[patientId];
                  if (stats == null || stats['totalTests'] == 0) return const SizedBox.shrink();
                  
                  final healthPct = stats['healthPercentage'] as double;
                  final normalCount = stats['normalTests'] as int;
                  final abnormalCount = stats['outOfRange'] as int;
                  final totalCount = stats['totalTests'] as int;
                  
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DoctorPatientTestsPage(
                              patientId: patientId!,
                              patientName: stats['name'],
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Hasta avatarı ve ismi
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                              child: Text(
                                (stats['name'] as String).isNotEmpty 
                                    ? (stats['name'] as String)[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // İsim ve tahlil sayısı
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    stats['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$totalCount tahlil',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Sağlık durumu göstergesi
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox(
                                      width: 50,
                                      height: 50,
                                      child: CircularProgressIndicator(
                                        value: healthPct / 100,
                                        strokeWidth: 5,
                                        backgroundColor: Colors.red.shade100,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          healthPct > 80 ? Colors.green : 
                                          healthPct > 50 ? Colors.orange : Colors.red,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${healthPct.toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: healthPct > 80 ? Colors.green : 
                                               healthPct > 50 ? Colors.orange : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '✓$normalCount',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    if (abnormalCount > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '⚠$abnormalCount',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.chevron_right, color: Colors.grey[400]),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 24),
              ],

              // Tahlil Türleri Dağılımı
              if (_testTypeDistribution.isNotEmpty) ...[
                Text(
                  'Tahlil Türleri',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: (_testTypeDistribution.entries.toList()
                          ..sort((a, b) => b.value.compareTo(a.value)))
                          .take(8)
                          .map((entry) => _TestTypeBar(
                            testName: entry.key,
                            count: entry.value,
                            total: _totalTests,
                          ))
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Anormal Sonuçlar
              if (_recentAbnormalTests.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Dikkat Gerektiren Sonuçlar',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(Icons.warning, color: Colors.orange),
                  ],
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 2,
                  color: Colors.orange.shade50,
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _recentAbnormalTests.length > 5 ? 5 : _recentAbnormalTests.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final test = _recentAbnormalTests[index];
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.warning_amber, color: Colors.orange),
                        ),
                        title: Text(
                          test['patientName'] ?? 'Bilinmeyen Hasta',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          '${test['testName']}: ${test['result']} (Ref: ${test['referenceRange'] ?? 'N/A'})',
                        ),
                        trailing: Text(
                          _formatDate(test['date']),
                          style: theme.textTheme.bodySmall,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DoctorPatientTestsPage(
                                patientId: test['patientId'],
                                patientName: test['patientName'],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Cinsiyet Dağılımı
              if (totalPatients > 0 && (genderDist['Erkek']! > 0 || genderDist['Kadın']! > 0)) ...[
                Text(
                  'Cinsiyet Dağılımı',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _GenderCard(
                        label: 'Erkek',
                        count: genderDist['Erkek'] ?? 0,
                        icon: Icons.male,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _GenderCard(
                        label: 'Kadın',
                        count: genderDist['Kadın'] ?? 0,
                        icon: Icons.female,
                        color: Colors.pink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // Kan Grubu Dağılımı
              if (totalPatients > 0 && bloodGroupDist.isNotEmpty) ...[
                Text(
                  'Kan Grubu Dağılımı',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: bloodGroupDist.entries.map((entry) {
                        return _BloodGroupChip(
                          bloodGroup: entry.key,
                          count: entry.value,
                          total: totalPatients,
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Hasta yoksa mesaj
              if (_patients.isEmpty)
                Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      Icon(Icons.analytics_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Henüz hastanız bulunmuyor',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Hastalar sizi seçtiğinde burada istatistikler görünecek',
                        style: TextStyle(color: Colors.grey[500]),
                        textAlign: TextAlign.center,
                      ),
                    ],
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

class _MiniStatRow extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _MiniStatRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(label),
        const Spacer(),
        Text(
          value.toString(),
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}

class _TestTypeBar extends StatelessWidget {
  final String testName;
  final int count;
  final int total;

  const _TestTypeBar({
    required this.testName,
    required this.count,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? (count / total) * 100 : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  testName,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$count (${percentage.toStringAsFixed(0)}%)',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 8,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GenderCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;

  const _GenderCard({
    required this.label,
    required this.count,
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
            Icon(icon, color: color, size: 36),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(label, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}

class _BloodGroupChip extends StatelessWidget {
  final String bloodGroup;
  final int count;
  final int total;

  const _BloodGroupChip({
    required this.bloodGroup,
    required this.count,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? (count / total * 100).toStringAsFixed(0) : '0';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bloodtype, size: 18, color: Colors.red[700]),
          const SizedBox(width: 4),
          Text(
            '$bloodGroup: $count ($percentage%)',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.red[700],
            ),
          ),
        ],
      ),
    );
  }
}
