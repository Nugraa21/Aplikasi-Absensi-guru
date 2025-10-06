import 'package:flutter/material.dart';
import '../services/db_service.dart';
import '../widgets/custom_button.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameCtrl = TextEditingController();
  final nipCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool isAdmin = false;
  bool loading = false;

  Future<void> _register() async {
    if (nameCtrl.text.isEmpty ||
        emailCtrl.text.isEmpty ||
        passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Isi semua field penting.")));
      return;
    }
    setState(() => loading = true);
    try {
      await DBService.registerUser(
        nameCtrl.text.trim(),
        nipCtrl.text.trim(),
        emailCtrl.text.trim(),
        passCtrl.text.trim(),
        isAdmin: isAdmin ? 1 : 0,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registrasi berhasil. Silakan login.")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal registrasi: $e")));
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daftar Akun"),
        backgroundColor: Colors.orange,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.all(20),
          child: ListView(
            shrinkWrap: true,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "Nama"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: nipCtrl,
                decoration: const InputDecoration(labelText: "NIP (opsional)"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password"),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text("Daftarkan sebagai Admin?"),
                  Checkbox(
                    value: isAdmin,
                    onChanged: (v) => setState(() => isAdmin = v ?? false),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              CustomButton(
                text: loading ? "Memproses..." : "Daftar",
                onPressed: loading ? () {} : _register,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
