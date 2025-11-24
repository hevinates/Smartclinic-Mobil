import 'package:flutter/material.dart';

class TestDetailPage extends StatelessWidget {
  final Map<String, dynamic> test;

  const TestDetailPage({super.key, required this.test});

  @override
  Widget build(BuildContext context) {
    final name = test['testName'] ?? 'Tahlil';
    final result = test['result'] ?? '-';
    final reference = test['referenceRange'] ?? 'Bilinmiyor';
    final date = (test['date'] ?? '').toString().split('T').first;
    final isOut = test['isOutOfRange'] == true;

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sonuç: $result',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isOut ? Colors.red : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text('Referans Aralığı: $reference'),
            const SizedBox(height: 8),
            Text('Tarih: $date'),
          ],
        ),
      ),
    );
  }
}
