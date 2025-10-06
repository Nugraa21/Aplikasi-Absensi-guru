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
  final jabatanCtrl = TextEditingController();
  final kelasCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool asAdmin = false;
  bool loading = false;

  Future<void> _register() async {
    if (nameCtrl.text.isEmpty ||
        emailCtrl.text.isEmpty ||
        passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Isi Nama, Email, Password.")),
      );
      return;
    }
    setState(() => loading = true);
    try {
      await DBService.registerUser(
        name: nameCtrl.text.trim(),
        nip: nipCtrl.text.trim(),
        jabatan: jabatanCtrl.text.trim(),
        kelas: kelasCtrl.text.trim(),
        email: emailCtrl.text.trim(),
        password: passCtrl.text.trim(),
        isAdmin: asAdmin ? 1 : 0,
        isApproved: asAdmin ? 1 : 0,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Registrasi berhasil. Tunggu konfirmasi admin (untuk guru).",
          ),
        ),
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
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 700),
          padding: const EdgeInsets.all(20),
          child: ListView(
            shrinkWrap: true,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: "Nama Lengkap",
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
              const SizedBox(height: 8),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text("Buat akun sebagai Admin?"),
                  Checkbox(
                    value: asAdmin,
                    onChanged: (v) => setState(() => asAdmin = v ?? false),
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
