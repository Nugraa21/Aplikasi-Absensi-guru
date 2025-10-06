// lib/pages/profile_page.dart
// Page for viewing and editing user profile, including photo upload and password change.
// Fixed: Added missing import for LoginPage.

import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/db_service.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  final Map<String, dynamic> user;
  const ProfilePage({super.key, required this.user});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController nameCtrl;
  late TextEditingController nipCtrl;
  late TextEditingController jabatanCtrl;
  late TextEditingController kelasCtrl;
  String photoPath = '';
  bool loading = false;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.user['name']);
    nipCtrl = TextEditingController(text: widget.user['nip']);
    jabatanCtrl = TextEditingController(text: widget.user['jabatan']);
    kelasCtrl = TextEditingController(text: widget.user['kelas']);
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
            border: Border.all(color: Colors.green.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(color: Colors.green.withOpacity(0.1), blurRadius: 10),
            ],
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
      jabatanCtrl.text.trim(),
      kelasCtrl.text.trim(),
      photoPath,
    );
    setState(() => loading = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Profil disimpan")));
  }

  Future<void> _changePassword() async {
    final newPassCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Ubah Password"),
        content: TextField(
          controller: newPassCtrl,
          obscureText: true,
          decoration: const InputDecoration(labelText: "Password Baru"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPassCtrl.text.isEmpty) return;
              final db = await DBService.getDB();
              await db.update(
                'users',
                {'password': newPassCtrl.text.trim()},
                where: 'id = ?',
                whereArgs: [widget.user['id']],
              );
              Navigator.pop(ctx);
              if (mounted)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Password diubah")),
                );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
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
                  radius: 56,
                  backgroundImage: photoPath.isNotEmpty
                      ? FileImage(File(photoPath))
                      : null,
                  child: photoPath.isEmpty
                      ? const Icon(Icons.person, size: 56, color: Colors.green)
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: "Nama",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nipCtrl,
                decoration: const InputDecoration(
                  labelText: "NIP",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: jabatanCtrl,
                decoration: const InputDecoration(
                  labelText: "Jabatan",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: kelasCtrl,
                decoration: const InputDecoration(
                  labelText: "Kelas (mengajar)",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: loading ? null : save,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Simpan Profil"),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _changePassword,
                style: OutlinedButton.styleFrom(foregroundColor: Colors.green),
                child: const Text("Ubah Password"),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (r) => false,
                  );
                },
                style: OutlinedButton.styleFrom(foregroundColor: Colors.green),
                child: const Text("Logout"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
