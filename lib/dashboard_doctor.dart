import 'package:flutter/material.dart';
import 'role_select_page.dart';
import 'doctor_profile_page.dart';
import 'doctor_patients_page.dart';
import 'doctor_appointments_page.dart';
import 'doctor_analytics_page.dart';
import 'doctor_messages_page.dart';

class DoctorDashboardPage extends StatelessWidget {
  final String fullName;
  final String email;
  final String userId;

  const DoctorDashboardPage({
    super.key,
    required this.fullName,
    required this.email,
    required this.userId,
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
              builder: (_) => DoctorProfilePage(doctorEmail: email),
            ),
          );
        },
      ),
      _MenuItem(
        title: 'Hastalarım',
        icon: Icons.group,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DoctorPatientsPage(
                doctorEmail: email,
              ),
            ),
          );
        },
      ),
      _MenuItem(
        title: 'Randevular',
        icon: Icons.event,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DoctorAppointmentsPage(
                doctorId: userId,
                doctorEmail: email,
              ),
            ),
          );
        },
      ),
      _MenuItem(
        title: 'Analizler',
        icon: Icons.analytics,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DoctorAnalyticsPage(
                doctorId: userId,
                doctorEmail: email,
              ),
            ),
          );
        },
      ),
      _MenuItem(
        title: 'Mesajlar',
        icon: Icons.message,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DoctorMessagesPage(
                doctorId: userId,
                doctorEmail: email,
              ),
            ),
          );
        },
      ),
    ];

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 233, 245, 255), // Açık mavi arka plan
      appBar: AppBar(
        title: const Text(
          'Doktor Paneli',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 25, 70, 122), // Koyu mavi
          ),
        ),
        automaticallyImplyLeading: false,
      ),
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
                  childAspectRatio: 1.15,
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
}

class _WelcomeHeader extends StatelessWidget {
  final String fullName;
  const _WelcomeHeader({required this.fullName});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hoş geldiniz, Dr. $fullName', style: Theme.of(context).textTheme.titleLarge),
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
