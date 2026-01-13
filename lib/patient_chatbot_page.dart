import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'patient_messages_page.dart';
import 'patient_appointment_page.dart';

class PatientChatbotPage extends StatefulWidget {
  final String userId;
  final String patientEmail;

  const PatientChatbotPage({
    super.key,
    required this.userId,
    required this.patientEmail,
  });

  @override
  State<PatientChatbotPage> createState() => _PatientChatbotPageState();
}

class _PatientChatbotPageState extends State<PatientChatbotPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  int? _patientUserId;
  List<Map<String, dynamic>> _tests = [];
  Map<String, dynamic>? _patientProfile;

  // Gemini API
  static const String _apiKey = 'YOUR_API_KEY'; // Buraya kendi API Key'inizi eklemelisiniz.
  late final GenerativeModel _model;
  late final ChatSession _chat;

  final String _systemPrompt = '''
Sen SmartClinic uygulamasının sağlık asistanısın. Adın "SmartClinic Asistan".
Görevin hastalara sağlık konularında yardımcı olmak, sorularını yanıtlamak ve genel sağlık tavsiyeleri vermek.

ÖNEMLİ KURALLAR:
1. Her zaman Türkçe yanıt ver.
2. Nazik, anlayışlı ve profesyonel ol.
3. Tıbbi teşhis KOYMA, sadece genel bilgi ver.
4. Ciddi durumlarda mutlaka doktora başvurmalarını öner.
5. Acil durumlarda 112'yi aramalarını söyle.
6. Yanıtlarını kısa ve öz tut, emoji kullan.
7. İlaç önerme, sadece doktora danışmalarını söyle.
8. Hasta bilgilerini gizli tut.
9. Tahlil sonuçlarını yorumlarken referans değerlerini de belirt.
10. Her zaman pozitif ve destekleyici bir dil kullan.

Uygulama özellikleri hakkında bilgi:
- Hastalar tahlil sonuçlarını görüntüleyebilir
- Doktorlarına mesaj gönderebilir
- Randevu alabilir
- Profil bilgilerini güncelleyebilir
- AI asistan ile sağlık sorularını sorabilir
''';

  @override
  void initState() {
    super.initState();
    _initializeGemini();
    _loadPatientData();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    _addMessage(
      'Merhaba! 👋 Ben SmartClinic sağlık asistanınızım.\n\n'
      'Size nasıl yardımcı olabilirim?\n\n'
      '• 🔬 Tahlil sonuçlarınızı analiz edebilirim\n'
      '• 💊 Sağlık önerileri verebilirim\n'
      '• ❓ Sorularınızı yanıtlayabilirim\n\n'
      'Hemen sormaya başlayın!',
      isUser: false,
    );
  }

  void _initializeGemini() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
      systemInstruction: Content.text(_systemPrompt),
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 2048,
      ),
    );
    _chat = _model.startChat();
  }

  Future<void> _loadPatientData() async {
    try {
      final userRes = await http.get(
        Uri.parse('http://localhost:5080/api/auth/user/${widget.patientEmail}')
      );
      
      if (userRes.statusCode == 200) {
        final userData = jsonDecode(userRes.body);
        _patientUserId = userData['id'];
        
        final profileRes = await http.get(
          Uri.parse('http://localhost:5080/api/PatientProfile/$_patientUserId')
        );
        if (profileRes.statusCode == 200) {
          _patientProfile = jsonDecode(profileRes.body);
        }
        
        final testsRes = await http.get(
          Uri.parse('http://localhost:5080/api/PatientProfile/$_patientUserId/tests')
        );
        if (testsRes.statusCode == 200) {
          final List data = jsonDecode(testsRes.body);
          _tests = data.cast<Map<String, dynamic>>();
        }
      }
    } catch (e) {
      debugPrint('Hasta verileri yüklenemedi: $e');
    }
  }

  void _addMessage(String text, {required bool isUser}) {
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: isUser));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _addMessage(message, isUser: true);
    _messageController.clear();

    setState(() => _isLoading = true);

    try {
      // Hasta bilgilerini context olarak ekle
      String contextMessage = message;
      if (_patientProfile != null) {
        final name = '${_patientProfile!['firstName'] ?? ''} ${_patientProfile!['lastName'] ?? ''}'.trim();
        final age = _patientProfile!['age'] ?? '';
        final bloodGroup = _patientProfile!['bloodGroup'] ?? '';
        final gender = _patientProfile!['gender'] ?? '';
        
        contextMessage = '''
[Hasta Bilgisi: Ad: $name, Yaş: $age, Kan Grubu: $bloodGroup, Cinsiyet: $gender]
Hasta sorusu: $message
''';
      }

      final response = await _chat.sendMessage(Content.text(contextMessage));
      final responseText = response.text ?? 'Üzgünüm, bir hata oluştu. Lütfen tekrar deneyin.';
      
      setState(() => _isLoading = false);
      _addMessage(responseText, isUser: false);
    } catch (e) {
      setState(() => _isLoading = false);
      _addMessage(
        '❌ Bağlantı hatası oluştu. Lütfen internet bağlantınızı kontrol edin ve tekrar deneyin.',
        isUser: false,
      );
      debugPrint('Gemini API Hatası: $e');
    }
  }

  void _analyzeTests() async {
    _addMessage('📊 Tahlillerimi analiz et', isUser: true);
    
    setState(() => _isLoading = true);
    
    if (_tests.isEmpty) {
      setState(() => _isLoading = false);
      _addMessage(
        '📋 Henüz kayıtlı tahlil sonucunuz bulunmuyor.\n\nTahlil sonuçlarınızı "Tahlillerim" sayfasından yükleyebilirsiniz.',
        isUser: false,
      );
      return;
    }

    try {
      String testInfo = 'Hastanın tahlil sonuçları:\n';
      for (var test in _tests.take(5)) {
        final testName = test['testName'] ?? test['testname'] ?? 'Bilinmeyen';
        final testDate = test['testDate'] ?? test['testdate'] ?? '';
        final description = test['description'] ?? '';
        testInfo += '- $testName ($testDate): $description\n';
      }
      testInfo += '\nBu tahlilleri genel olarak değerlendir ve hastaya önerilerde bulun.';

      final response = await _chat.sendMessage(Content.text(testInfo));
      final responseText = response.text ?? 'Tahlil analizi yapılamadı.';
      
      setState(() => _isLoading = false);
      _addMessage(responseText, isUser: false);
    } catch (e) {
      setState(() => _isLoading = false);
      _addMessage('❌ Tahlil analizi sırasında bir hata oluştu.', isUser: false);
    }
  }

  void _showHealthTip() async {
    _addMessage('💡 Sağlık önerisi ver', isUser: true);
    
    setState(() => _isLoading = true);

    try {
      final response = await _chat.sendMessage(
        Content.text('Bana günlük hayatta uygulayabileceğim pratik bir sağlık önerisi ver. Kısa ve öz olsun, emoji kullan.')
      );
      final responseText = response.text ?? 'Öneri alınamadı.';
      
      setState(() => _isLoading = false);
      _addMessage(responseText, isUser: false);
    } catch (e) {
      setState(() => _isLoading = false);
      _addMessage('❌ Öneri alınırken bir hata oluştu.', isUser: false);
    }
  }

  void _showProfile() {
    _addMessage('👤 Profil bilgilerimi göster', isUser: true);
    
    if (_patientProfile == null) {
      _addMessage(
        '⚠️ Profil bilgilerinize ulaşılamadı. Lütfen profilinizi güncelleyin.',
        isUser: false,
      );
      return;
    }
    
    final firstName = _patientProfile!['firstName'] ?? _patientProfile!['firstname'] ?? '';
    final lastName = _patientProfile!['lastName'] ?? _patientProfile!['lastname'] ?? '';
    final age = _patientProfile!['age'] ?? _patientProfile!['Age'] ?? '-';
    final bloodGroup = _patientProfile!['bloodGroup'] ?? _patientProfile!['bloodgroup'] ?? '-';
    final gender = _patientProfile!['gender'] ?? _patientProfile!['Gender'] ?? '-';
    
    String profile = '👤 **Profil Bilgileriniz**\n\n';
    profile += '📛 Ad Soyad: $firstName $lastName\n';
    profile += '🎂 Yaş: $age\n';
    profile += '🩸 Kan Grubu: $bloodGroup\n';
    profile += '⚧ Cinsiyet: $gender\n';
    
    _addMessage(profile, isUser: false);
  }

  void _goToMessages() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PatientMessagesPage(
          userId: widget.userId,
          patientEmail: widget.patientEmail,
        ),
      ),
    );
  }

  void _goToAppointments() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PatientAppointmentPage(
          userId: widget.userId,
          patientEmail: widget.patientEmail,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.smart_toy, color: Colors.white),
            SizedBox(width: 8),
            Text('AI Sağlık Asistanı'),
          ],
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _messages.clear();
                _initializeGemini();
                _addWelcomeMessage();
              });
            },
            tooltip: 'Sohbeti Sıfırla',
          ),
        ],
      ),
      body: Column(
        children: [
          // Hızlı Eylem Butonları
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _QuickActionButton(
                    icon: Icons.biotech,
                    label: 'Tahlillerimi Analiz Et',
                    color: Colors.purple,
                    onTap: _analyzeTests,
                  ),
                  const SizedBox(width: 8),
                  _QuickActionButton(
                    icon: Icons.message,
                    label: 'Doktoruma Mesaj',
                    color: Colors.blue,
                    onTap: _goToMessages,
                  ),
                  const SizedBox(width: 8),
                  _QuickActionButton(
                    icon: Icons.calendar_month,
                    label: 'Randevu Al',
                    color: Colors.green,
                    onTap: _goToAppointments,
                  ),
                  const SizedBox(width: 8),
                  _QuickActionButton(
                    icon: Icons.lightbulb,
                    label: 'Sağlık Önerisi',
                    color: Colors.orange,
                    onTap: _showHealthTip,
                  ),
                  const SizedBox(width: 8),
                  _QuickActionButton(
                    icon: Icons.person,
                    label: 'Profilim',
                    color: Colors.teal,
                    onTap: _showProfile,
                  ),
                ],
              ),
            ),
          ),

          // Mesajlar listesi
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _ChatBubble(
                  message: message.text,
                  isUser: message.isUser,
                );
              },
            ),
          ),

          // Yükleniyor göstergesi
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI düşünüyor...',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),

          // Mesaj giriş alanı
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Sağlık sorunuzu yazın...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    onPressed: _isLoading ? null : _sendMessage,
                    mini: true,
                    child: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;

  const _ChatBubble({
    required this.message,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              backgroundColor: theme.colorScheme.primary,
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16).copyWith(
                  topLeft: isUser ? const Radius.circular(16) : Radius.zero,
                  topRight: isUser ? Radius.zero : const Radius.circular(16),
                ),
              ),
              child: Text(
                message,
                style: TextStyle(
                  color: isUser ? Colors.white : theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: theme.colorScheme.secondary,
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ],
        ],
      ),
    );
  }
}
