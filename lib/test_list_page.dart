import 'package:flutter/material.dart';

class TestListPage extends StatefulWidget {
  final String date;
  final List<Map<String, dynamic>> tests;
  final String userId;

  const TestListPage({
    super.key,
    required this.date,
    required this.tests,
    required this.userId,
  });

  @override
  State<TestListPage> createState() => _TestListPageState();
}

class _TestListPageState extends State<TestListPage> {
  bool _showOnlyOutOfRange = false;

  String _formatDate(String dateStr) {
    try {
      final d = DateTime.parse(dateStr);
      return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normalTests = widget.tests.where((t) => t['isOutOfRange'] != true).toList();
    final outOfRangeTests = widget.tests.where((t) => t['isOutOfRange'] == true).toList();
    
    // Gösterilecek testler
    final displayTests = _showOnlyOutOfRange ? outOfRangeTests : widget.tests;

    return Scaffold(
      appBar: AppBar(
        title: Text('Tahliller - ${_formatDate(widget.date)}'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Özet Kartı - Açık Gri
          Card(
            color: Colors.grey[200],
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem(
                    icon: Icons.science,
                    label: 'Toplam',
                    value: '${widget.tests.length}',
                    color: theme.colorScheme.primary,
                  ),
                  _buildSummaryItem(
                    icon: Icons.check_circle,
                    label: 'Normal',
                    value: '${normalTests.length}',
                    color: Colors.green,
                  ),
                  _buildSummaryItem(
                    icon: Icons.warning,
                    label: 'Anormal',
                    value: '${outOfRangeTests.length}',
                    color: Colors.red,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Filtre Toggle
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sadece Referans Dışı',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  Switch(
                    value: _showOnlyOutOfRange,
                    onChanged: (value) {
                      setState(() {
                        _showOnlyOutOfRange = value;
                      });
                    },
                    activeColor: Colors.red,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Test Listesi
          if (displayTests.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.check_circle, size: 64, color: Colors.green[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Referans dışı değer yok',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          else
            ...displayTests.map((test) => _buildTestCard(test)),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildTestCard(Map<String, dynamic> test) {
    final testName = test['testName'] ?? test['name'] ?? '';
    final result = test['result'] ?? '-';
    final reference = test['referenceRange'] ?? test['range'] ?? '-';
    final isOutOfRange = test['isOutOfRange'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isOutOfRange ? Colors.red.withOpacity(0.3) : Colors.transparent,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isOutOfRange 
                    ? Colors.red.withOpacity(0.1) 
                    : Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isOutOfRange ? Icons.warning_amber : Icons.check_circle_outline,
                color: isOutOfRange ? Colors.red : Colors.green,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    testName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isOutOfRange ? Colors.red[700] : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Sonuç: ',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        result,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isOutOfRange ? Colors.red[600] : Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Ref: $reference',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
