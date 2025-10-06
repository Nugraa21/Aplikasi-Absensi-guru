import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/db_service.dart';

class ProfilePage extends StatefulWidget {
  final Map<String, dynamic> user;
  const ProfilePage({super.key, required this.user});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController nameCtrl;
  late TextEditingController nipCtrl;
  String photoPath = '';

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.user['name']);
    nipCtrl = TextEditingController(text: widget.user['nip']);
    photoPath = widget.user['photo'] ?? '';
  }

  Future<void> updateProfile() async {
    await DBService.updateProfile(
      widget.user['id'],
      nameCtrl.text,
      nipCtrl.text,
      photoPath,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profil berhasil diperbarui!")),
    );
  }

  Future<void> pickPhoto() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) setState(() => photoPath = img.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profil Guru")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            GestureDetector(
              onTap: pickPhoto,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: photoPath.isNotEmpty
                    ? FileImage(File(photoPath))
                    : null,
                child: photoPath.isEmpty
                    ? const Icon(Icons.person, size: 50)
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Nama"),
            ),
            TextField(
              controller: nipCtrl,
              decoration: const InputDecoration(labelText: "NIP"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: updateProfile,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text("Simpan Perubahan"),
            ),
          ],
        ),
      ),
    );
  }
}
