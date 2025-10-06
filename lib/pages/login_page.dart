import 'package:flutter/material.dart';
import '../services/db_service.dart';
import 'home_page.dart';
import 'admin_dashboard.dart';
import 'register_page.dart';
import '../widgets/custom_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool loading = false;

  Future<void> _login() async {
    setState(() => loading = true);
    final user = await DBService.login(
      emailCtrl.text.trim(),
      passCtrl.text.trim(),
    );
    setState(() => loading = false);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login gagal: email/password salah")),
      );
      return;
    }
    if ((user['isAdmin'] ?? 0) == 0 && (user['isApproved'] ?? 0) == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Akun belum disetujui admin. Tunggu konfirmasi."),
        ),
      );
      return;
    }

    if ((user['isAdmin'] ?? 0) == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboard()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomePage(user: user)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.school, size: 64, color: Colors.green),
              const SizedBox(height: 8),
              const Text(
                "Absensi Guru",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Login (Guru/Admin)",
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(
                  labelText: "Email",
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              CustomButton(
                text: loading ? "Memproses..." : "Login",
                onPressed: loading ? () {} : _login,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterPage()),
                ),
                child: const Text("Belum punya akun? Daftar"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
