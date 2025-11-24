import 'package:flutter/material.dart';
import 'role_select_page.dart';

class DoctorDashboardPage extends StatelessWidget {
  const DoctorDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_MenuItem>[
      _MenuItem(title: 'Profilim', icon: Icons.person, onTap: () => _todo(context, 'Profilim')),
      _MenuItem(title: 'Hastalarım', icon: Icons.group, onTap: () => _todo(context, 'Hastalarım')),
      _MenuItem(title: 'Randevular', icon: Icons.event, onTap: () => _todo(context, 'Randevular')),
      _MenuItem(title: 'Lab istekleri', icon: Icons.science, onTap: () => _todo(context, 'Lab istekleri')),
      _MenuItem(title: 'Mesajlar', icon: Icons.message, onTap: () => _todo(context, 'Mesajlar')),
    ];

  return Scaffold(
  appBar: AppBar(title: const Text('Doktor paneli')),
  body: SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              padding: const EdgeInsets.only(bottom: 96), // alt barda çakışmayı engelle
              childAspectRatio: 1.15, // kart oranı
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
