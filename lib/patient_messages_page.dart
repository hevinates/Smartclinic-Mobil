import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PatientMessagesPage extends StatefulWidget {
  final String userId;
  final String patientEmail;

  const PatientMessagesPage({
    super.key,
    required this.userId,
    required this.patientEmail,
  });

  @override
  State<PatientMessagesPage> createState() => _PatientMessagesPageState();
}

class _PatientMessagesPageState extends State<PatientMessagesPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  Map<String, dynamic>? _doctorInfo;
  int? _patientUserId;
  int? _doctorId;
  bool _loading = true;
  bool _loadingMessages = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      // 1️⃣ Önce hasta userId'sini al
      final userRes = await http.get(
        Uri.parse('http://localhost:5080/api/auth/user/${widget.patientEmail}')
      );
      
      if (userRes.statusCode == 200) {
        final userData = jsonDecode(userRes.body);
        _patientUserId = userData['id'];
        
        // 2️⃣ Hasta profilini al ve doktorunu bul
        final profileRes = await http.get(
          Uri.parse('http://localhost:5080/api/PatientProfile/$_patientUserId')
        );
        
        if (profileRes.statusCode == 200) {
          final profileData = jsonDecode(profileRes.body);
          _doctorId = profileData['doctorId'] ?? profileData['DoctorId'];
          
          if (_doctorId != null) {
            // 3️⃣ Doktor bilgilerini al
            final doctorRes = await http.get(
              Uri.parse('http://localhost:5080/api/DoctorProfile/$_doctorId')
            );
            
            if (doctorRes.statusCode == 200) {
              final doctorData = jsonDecode(doctorRes.body);
              setState(() {
                _doctorInfo = {
                  'id': _doctorId,
                  'firstName': doctorData['firstName'] ?? doctorData['FirstName'] ?? '',
                  'lastName': doctorData['lastName'] ?? doctorData['LastName'] ?? '',
                  'hospital': doctorData['hospital'] ?? doctorData['Hospital'] ?? '',
                };
              });
              
              // 4️⃣ Mesajları yükle
              await _loadMessages();
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Veri yüklenemedi: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadMessages() async {
    if (_doctorId == null || _patientUserId == null) return;
    
    setState(() => _loadingMessages = true);
    try {
      debugPrint('📨 Mesajlar yükleniyor... PatientId: $_patientUserId, DoctorId: $_doctorId');
      
      final response = await http.get(
        Uri.parse('http://localhost:5080/api/messages/$_patientUserId/$_doctorId'),
      );
      
      debugPrint('📥 Messages API Response: ${response.statusCode}');
      debugPrint('📥 Messages API Body: ${response.body}');

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          _messages = data.map((m) {
            return {
              'id': m['id'],
              'senderId': m['senderid'],  // küçük harf
              'receiverId': m['receiverid'],  // küçük harf
              'content': m['content'] ?? '',
              'sentAt': m['sentat'],  // küçük harf
              'messageType': m['messagetype'] ?? 'Normal',  // küçük harf
            };
          }).toList();
        });
        debugPrint('✅ ${_messages.length} mesaj yüklendi');
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('❌ Mesajlar yüklenemedi: $e');
    } finally {
      setState(() => _loadingMessages = false);
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _doctorId == null) return;

    final message = _messageController.text.trim();
    _messageController.clear();

    // Mesajı hemen ekranda göster (optimistic update)
    setState(() {
      _messages.add({
        'id': DateTime.now().millisecondsSinceEpoch,
        'senderId': _patientUserId,
        'receiverId': _doctorId,
        'content': message,
        'sentAt': DateTime.now().toIso8601String(),
        'messageType': 'Normal',
      });
    });
    _scrollToBottom();

    try {
      debugPrint('📤 Mesaj gönderiliyor...');
      
      final response = await http.post(
        Uri.parse('http://localhost:5080/api/messages'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'senderId': _patientUserId,
          'receiverId': _doctorId,
          'content': message,
          'messageType': 'Normal',
        }),
      );

      debugPrint('📥 Send Response: ${response.statusCode}');
      debugPrint('📥 Send Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Mesaj gönderildi');
      }
    } catch (e) {
      debugPrint('❌ Mesaj gönderilemedi: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mesaj gönderilemedi: $e')),
        );
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);

    // Doktor seçilmemişse
    if (_doctorInfo == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mesajlar'),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Henüz bir doktor seçmediniz.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'Profilinizden doktorunuzu seçebilirsiniz.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final doctorName = 'Dr. ${_doctorInfo!['firstName']} ${_doctorInfo!['lastName']}';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctorName,
                    style: const TextStyle(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_doctorInfo!['hospital']?.isNotEmpty ?? false)
                    Text(
                      _doctorInfo!['hospital'],
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Mesajlar
          Expanded(
            child: _loadingMessages
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(
                        child: Text('Henüz mesaj yok. İlk mesajı siz gönderin! 💬'),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          // senderId'yi int'e çevirerek karşılaştır
                          final messageSenderId = int.tryParse(message['senderId'].toString()) ?? 0;
                          final isPatient = messageSenderId == _patientUserId;
                          final content = message['content'] ?? '';
                          final time = _formatTime(message['sentAt']);

                          return _MessageBubble(
                            content: content,
                            isMine: isPatient,
                            time: time,
                          );
                        },
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
                        hintText: 'Mesajınızı yazın...',
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
                    onPressed: _sendMessage,
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

  String _formatTime(dynamic timestamp) {
    try {
      final dt = DateTime.parse(timestamp.toString());
      return '${dt.day}.${dt.month}.${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class _MessageBubble extends StatelessWidget {
  final String content;
  final bool isMine;
  final String time;

  const _MessageBubble({
    required this.content,
    required this.isMine,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primary,
              child: const Icon(Icons.person, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isMine ? theme.colorScheme.primary : Colors.grey[200],
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomLeft: isMine ? const Radius.circular(16) : Radius.zero,
                      bottomRight: isMine ? Radius.zero : const Radius.circular(16),
                    ),
                  ),
                  child: Text(
                    content,
                    style: TextStyle(
                      color: isMine ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                if (time.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      time,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ),
              ],
            ),
          ),
          if (isMine) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[400],
              child: const Icon(Icons.person, color: Colors.white, size: 18),
            ),
          ],
        ],
      ),
    );
  }
}
