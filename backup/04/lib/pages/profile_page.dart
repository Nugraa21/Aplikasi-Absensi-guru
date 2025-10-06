import 'dart:io';
import 'dart:ui';
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
  bool loading = false;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.user['name']);
    nipCtrl = TextEditingController(text: widget.user['nip']);
    photoPath = widget.user['photo'] ?? '';
  }

  Widget _glass({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: child,
        ),
      ),
    );
  }

  Future<void> pickImage() async {
    final p = ImagePicker();
    final img = await p.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (img != null) setState(() => photoPath = img.path);
  }

  Future<void> save() async {
    setState(() => loading = true);
    await DBService.updateProfile(
      widget.user['id'],
      nameCtrl.text.trim(),
      nipCtrl.text.trim(),
      photoPath,
    );
    setState(() => loading = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Profil disimpan")));
  }

  Future<void> deleteAccount() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Hapus Akun"),
        content: const Text("Hapus akun dan semua data absensi?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await DBService.deleteUser(widget.user['id']);
      // navigate to login page (pop all)
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 640),
          padding: const EdgeInsets.all(20),
          child: _glass(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: pickImage,
                  child: CircleAvatar(
                    radius: 54,
                    backgroundImage: photoPath.isNotEmpty
                        ? FileImage(File(photoPath))
                        : null,
                    child: photoPath.isEmpty
                        ? const Icon(Icons.person, size: 56)
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: "Nama"),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nipCtrl,
                  decoration: const InputDecoration(labelText: "NIP"),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: loading ? null : save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Simpan Profil"),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: deleteAccount,
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text("Hapus Akun"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
