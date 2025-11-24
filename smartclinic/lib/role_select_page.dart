import 'package:flutter/material.dart';
import 'login_page.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class RoleSelectPage extends StatelessWidget {
  const RoleSelectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🌊 Dalgalanan başlık
                AnimatedTextKit(
                  animatedTexts: [
                    WavyAnimatedText(
                      'SmartClinic',
                      textStyle: const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0f837d),
                        fontFamily: 'Poppins',
                        letterSpacing: 1.2,
                      ),
                      speed: const Duration(milliseconds: 150),
                    ),
                  ],
                  isRepeatingAnimation: true,
                  repeatForever: true,
                ),

                // 🩺 Görsel (başlığın altına)
                const SizedBox(height: 24),
                Image.asset(
                  'assets/images/logo.png', // kendi dosya adın neyse onu yaz
                  width: 180,
                  height: 180,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 100),

                // 🔘 Doktor girişi butonu
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const LoginPage(role: 'doctor'),
                        ),
                      );
                    },
                    child: const Text('Doktor girişi'),
                  ),
                ),

                const SizedBox(height: 12),

                // 🔘 Hasta girişi butonu
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const LoginPage(role: 'patient'),
                        ),
                      );
                    },
                    child: const Text('Hasta girişi'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
