import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/validators.dart';
import '../../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  final bool register;
  const AuthScreen({super.key, this.register = false});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      email = TextEditingController(),
      password = TextEditingController();
  bool busy = false;
  String? error;
  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await AuthService.instance.authenticate(
        email.text.trim(),
        password.text,
        name: widget.register ? name.text.trim() : null,
      );
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Form(
            key: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.phonelink_setup_rounded,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'TechFix',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sua assistência, organizada.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (widget.register)
                  TextFormField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Nome'),
                    validator: (v) => Validators.required(v),
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                  validator: Validators.email,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Senha'),
                  validator: Validators.password,
                ),
                if (widget.register)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: TextFormField(
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirmar senha',
                      ),
                      validator: (v) =>
                          Validators.passwordConfirmation(v, password.text),
                    ),
                  ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: busy ? null : submit,
                  child: busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(),
                        )
                      : Text(widget.register ? 'Criar conta' : 'Entrar'),
                ),
                TextButton(
                  onPressed: busy
                      ? null
                      : () => context.goNamed(
                          widget.register
                              ? AppRoutes.login
                              : AppRoutes.register,
                        ),
                  child: Text(
                    widget.register
                        ? 'Já tenho uma conta'
                        : 'Cadastrar funcionário',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
