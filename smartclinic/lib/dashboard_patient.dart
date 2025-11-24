import 'package:flutter/material.dart';
import 'role_select_page.dart';
import 'patient_profile_page.dart';
import 'patient_tests_page.dart'; 
import 'test_list_page.dart';

class PatientDashboardPage extends StatelessWidget {
  final String fullName;
  final String email;
  final String userId; // ✅ eklendi

  const PatientDashboardPage({
    super.key,
    required this.fullName,
    required this.email,
    required this.userId, // ✅ eklendi
  });


  @override
  Widget build(BuildContext context) {
    final items = <_MenuItem>[
      _MenuItem(
        title: 'Profilim',
        icon: Icons.person,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PatientProfilePage(patientEmail: email),
            ),
          );
        },
      ),
      _MenuItem(
        title: 'Tahlillerim',
        icon: Icons.biotech,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PatientTestsPage(userId: userId, patientEmail: email),
            ),
          );
        },
      ),
      _MenuItem(title: 'Raporlama', icon: Icons.bar_chart, onTap: () => _todo(context, 'Raporlama')),
      _MenuItem(title: 'Chatbot', icon: Icons.chat_bubble, onTap: () => _todo(context, 'Chatbot')),
      _MenuItem(title: 'Öneriler', icon: Icons.lightbulb, onTap: () => _todo(context, 'Öneriler')),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Hasta paneli')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _WelcomeHeader(fullName: fullName),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: items.map((e) => _MenuCard(item: e)).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: SizedBox(
            width: 220,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const RoleSelectPage()),
                  (_) => false,
                );
              },
              icon: const Icon(Icons.logout),
              label: const Text('Çıkış yap'),
            ),
          ),
        ),
      ),
    );
  }

  static void _todo(BuildContext context, String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$name sayfası yakında')),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  final String fullName;
  const _WelcomeHeader({required this.fullName});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hoş geldiniz, $fullName', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text('SmartClinic', style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _MenuItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  _MenuItem({required this.title, required this.icon, required this.onTap});
}

class _MenuCard extends StatelessWidget {
  final _MenuItem item;
  const _MenuCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.surface,
          boxShadow: const [
            BoxShadow(blurRadius: 8, offset: Offset(0, 2), color: Color(0x14000000)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, size: 36),
              const SizedBox(height: 12),
              Text(item.title, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
