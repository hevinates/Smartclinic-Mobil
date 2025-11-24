import 'package:flutter/material.dart';
import '../patient_tests_page.dart'; // 🔹 Detay sayfasını görmek için doğru import
import 'test_detail_page.dart'; // 🔹 TestDetailPage widget'ını eklemek için doğru import

class TestListPage extends StatelessWidget {
  final String date;
  final List<Map<String, dynamic>> tests;
  final String userId; // 🔹 Kullanıcı ID eklendi

  const TestListPage({
    super.key,
    required this.date,
    required this.tests,
    required this.userId, // 🔹 Constructor’a eklendi
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tahliller ($date)')),
      body: ListView.separated(
        separatorBuilder: (_, __) => const Divider(),
        itemCount: tests.length,
        itemBuilder: (context, i) {
          final test = tests[i];
          final isOut = test['isOutOfRange'] == true;

          return ListTile(
            title: Text(
              test['testName'] ?? test['name'] ?? '',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isOut ? Colors.red : Colors.black,
              ),
            ),
            subtitle: Text(
              'Sonuç: ${test['result'] ?? '-'} | Referans: ${test['referenceRange'] ?? test['range'] ?? 'Bilinmiyor'}',
              style: TextStyle(color: isOut ? Colors.red : Colors.black54),
            ),
            onTap: () {
              print(test); // terminalde görmek için
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TestDetailPage(test: test),
                ),
              );
            },

          );
        },
      ),
    );
  }
}
