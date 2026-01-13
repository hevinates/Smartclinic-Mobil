import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DoctorMessagesPage extends StatefulWidget {
  final String doctorId;
  final String doctorEmail;

  const DoctorMessagesPage({
    super.key,
    required this.doctorId,
    required this.doctorEmail,
  });

  @override
  State<DoctorMessagesPage> createState() => _DoctorMessagesPageState();
}

class _DoctorMessagesPageState extends State<DoctorMessagesPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> _messages = [];
  Map<String, dynamic>? _selectedPatient;
  bool _loading = true;
  bool _loadingMessages = false;
  int? _doctorUserId;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() => _loading = true);
    try {
      // 1️⃣ Önce doktor userId'sini al (Hastalarım sayfası gibi)
      final userRes = await http.get(
        Uri.parse('http://localhost:5080/api/auth/user/${widget.doctorEmail}')
      );
      
      if (userRes.statusCode == 200) {
        final userData = jsonDecode(userRes.body);
        _doctorUserId = userData['id'];
        
        // 2️⃣ Şimdi bu doktorun hastalarını çek
        final patientsRes = await http.get(
          Uri.parse('http://localhost:5080/api/DoctorProfile/patients/$_doctorUserId')
        );
        
        if (patientsRes.statusCode == 200) {
          final List data = jsonDecode(patientsRes.body);
          setState(() {
            _patients = data.map((p) => {
              'userId': p['userId'] ?? p['UserId'],
              'firstName': p['firstName'] ?? p['FirstName'] ?? '',
              'lastName': p['lastName'] ?? p['LastName'] ?? '',
            }).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Hastalar yüklenemedi: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadMessages(int patientId) async {
    setState(() => _loadingMessages = true);
    try {
      debugPrint('📨 Mesajlar yükleniyor... DoctorId: $_doctorUserId, PatientId: $patientId');
      
      final response = await http.get(
        Uri.parse('http://localhost:5080/api/messages/$_doctorUserId/$patientId'),
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
    if (_messageController.text.trim().isEmpty || _selectedPatient == null) return;

    final message = _messageController.text.trim();
    _messageController.clear();

    // Mesajı hemen ekranda göster (optimistic update)
    setState(() {
      _messages.add({
        'id': DateTime.now().millisecondsSinceEpoch,
        'senderId': _doctorUserId,
        'receiverId': _selectedPatient!['userId'],
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
          'senderId': _doctorUserId,
          'receiverId': _selectedPatient!['userId'],
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

    return Scaffold(
      appBar: AppBar(
        title: _selectedPatient == null
            ? const Text('Mesajlar')
            : Text('${_selectedPatient!['firstName']} ${_selectedPatient!['lastName']}'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        leading: _selectedPatient != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _selectedPatient = null;
                    _messages.clear();
                  });
                },
              )
            : null,
      ),
      body: _selectedPatient == null
          ? _buildPatientList(theme)
          : _buildChatView(theme),
    );
  }

  Widget _buildPatientList(ThemeData theme) {
    if (_patients.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Henüz hastanız bulunmuyor',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _patients.length,
      itemBuilder: (context, index) {
        final patient = _patients[index];
        final name = '${patient['firstName']} ${patient['lastName']}';
        
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.primary,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
          subtitle: const Text('Mesaj göndermek için dokunun'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            setState(() {
              _selectedPatient = patient;
              _messages.clear();
            });
            _loadMessages(patient['userId']);
          },
        );
      },
    );
  }

  Widget _buildChatView(ThemeData theme) {
    return Column(
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
                        final isDoctor = messageSenderId == _doctorUserId;
                        final content = message['content'] ?? '';
                        final time = _formatTime(message['sentAt']);

                        debugPrint('📩 Mesaj: senderId=$messageSenderId, doctorUserId=$_doctorUserId, isDoctor=$isDoctor');

                        return _MessageBubble(
                          content: content,
                          isMine: isDoctor,
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
              backgroundColor: Colors.grey[400],
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
              backgroundColor: theme.colorScheme.primary,
              child: const Icon(Icons.person, color: Colors.white, size: 18),
            ),
          ],
        ],
      ),
    );
  }
}
