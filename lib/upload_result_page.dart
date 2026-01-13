import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class UploadResultPage extends StatefulWidget {
  final String patientEmail;
  const UploadResultPage({super.key, required this.patientEmail});

  @override
  State<UploadResultPage> createState() => _UploadResultPageState();
}

class _UploadResultPageState extends State<UploadResultPage> {
  bool loading = false;
  String? fileName;

  Future<void> _uploadPDF() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result == null) return;

    final file = result.files.single;
    setState(() => fileName = file.name);

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('http://192.168.1.100:5080/api/upload/pdf'), // backend endpoint
    );

    request.fields['email'] = widget.patientEmail;
    request.files.add(await http.MultipartFile.fromPath('file', file.path!));

    setState(() => loading = true);

    final res = await request.send();
    setState(() => loading = false);

    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ PDF başarıyla yüklendi ve analiz edildi.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Yükleme başarısız.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sonuç Yükleme')),
      body: Center(
        child: loading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (fileName != null) Text('Seçilen dosya: $fileName'),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _uploadPDF,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('PDF Yükle ve Analiz Et'),
                  ),
                ],
              ),
      ),
    );
  }
}
