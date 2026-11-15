import 'package:flutter/material.dart';
import '../../core/utils/validators.dart';
import '../../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(text: AuthService.instance.user?.name);
  final email = TextEditingController(text: AuthService.instance.user?.email);
  bool busy = false;
  @override
  void dispose() {
    name.dispose();
    email.dispose();
    super.dispose();
  }

  Future<void> action(bool logout) async {
    if (!logout && !form.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      if (logout) {
        await AuthService.instance.logout();
      } else {
        await AuthService.instance.updateProfile(
          name.text.trim(),
          email.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Perfil atualizado.')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Meu perfil')),
    body: Form(
      key: form,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.account_circle_outlined, size: 80),
          const SizedBox(height: 16),
          Text(
            AuthService.instance.user?.isAdmin == true
                ? 'Administrador'
                : 'Funcionário',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: name,
            decoration: const InputDecoration(labelText: 'Nome'),
            validator: (v) => Validators.required(v),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: email,
            decoration: const InputDecoration(labelText: 'E-mail'),
            validator: Validators.email,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: busy ? null : () => action(false),
            child: const Text('Salvar perfil'),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: busy ? null : () => action(true),
            child: const Text('Sair'),
          ),
        ],
      ),
    ),
  );
}
