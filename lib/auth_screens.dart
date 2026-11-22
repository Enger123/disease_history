import 'package:flutter/material.dart';
import 'auth.dart';
import 'home.dart';
import 'main.dart';

final emailRe = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginState();
}

class _LoginState extends State<LoginScreen> {
  final _f = GlobalKey<FormState>();
  final _email = TextEditingController(), _pass = TextEditingController();
  String? _err;

  Future<void> _submit() async {
    if (!_f.currentState!.validate()) return;
    final e = await Auth.login(_email.text, _pass.text);
    if (!mounted) return;
    e == null ? goTo(context, const HomeScreen()) : setState(() => _err = e);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _f,
                child: Column(children: [
                  Icon(Icons.medical_services, size: 72, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 8),
                  Text('Вхід', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 24),
                  TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email), border: OutlineInputBorder()),
                      validator: (v) => (v == null || !emailRe.hasMatch(v.trim())) ? 'Введіть коректний email' : null),
                  const SizedBox(height: 12),
                  TextFormField(
                      controller: _pass,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Пароль', prefixIcon: Icon(Icons.lock), border: OutlineInputBorder()),
                      validator: (v) => (v == null || v.isEmpty) ? 'Введіть пароль' : null),
                  if (_err != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_err!, style: const TextStyle(color: Colors.red))),
                  const SizedBox(height: 20),
                  SizedBox(width: double.infinity, child: FilledButton(onPressed: _submit, child: const Text('Увійти'))),
                  TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                      child: const Text('Немає акаунта? Зареєструватися')),
                ]),
              ),
            ),
          ),
        ),
      );
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterState();
}

class _RegisterState extends State<RegisterScreen> {
  final _f = GlobalKey<FormState>();
  final _name = TextEditingController(), _email = TextEditingController(), _pass = TextEditingController(), _pass2 = TextEditingController();
  String? _err;

  Future<void> _submit() async {
    if (!_f.currentState!.validate()) return;
    final e = await Auth.register(_name.text, _email.text, _pass.text);
    if (!mounted) return;
    e == null ? goTo(context, const HomeScreen()) : setState(() => _err = e);
  }

  InputDecoration _d(String l, IconData i) =>
      InputDecoration(labelText: l, prefixIcon: Icon(i), border: const OutlineInputBorder());

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Реєстрація')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _f,
              child: Column(children: [
                TextFormField(controller: _name, decoration: _d("Ім'я", Icons.person), validator: (v) => (v == null || v.trim().isEmpty) ? "Введіть ім'я" : null),
                const SizedBox(height: 12),
                TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: _d('Email', Icons.email), validator: (v) => (v == null || !v.contains('@')) ? 'Введіть коректний email' : null),
                const SizedBox(height: 12),
                TextFormField(controller: _pass, obscureText: true, decoration: _d('Пароль', Icons.lock), validator: (v) => (v == null || v.length < 6) ? 'Мінімум 6 символів' : null),
                const SizedBox(height: 12),
                TextFormField(controller: _pass2, obscureText: true, decoration: _d('Повторіть пароль', Icons.lock_outline), validator: (v) => v != _pass.text ? 'Паролі не збігаються' : null),
                if (_err != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_err!, style: const TextStyle(color: Colors.red))),
                const SizedBox(height: 20),
                SizedBox(width: double.infinity, child: FilledButton(onPressed: _submit, child: const Text('Створити акаунт'))),
              ]),
            ),
          ),
        ),
      );
}

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});
  @override
  State<DeleteAccountScreen> createState() => _DeleteState();
}

class _DeleteState extends State<DeleteAccountScreen> {
  final _pass = TextEditingController();
  String? _err;

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
              title: const Text('Видалити акаунт?'),
              content: const Text('Усі записи та прикріплені файли буде видалено безповоротно.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Скасувати')),
                TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Видалити', style: TextStyle(color: Colors.red))),
              ],
            ));
    if (ok != true) return;
    final e = await Auth.deleteAccount(_pass.text);
    if (!mounted) return;
    e == null ? goTo(context, const LoginScreen()) : setState(() => _err = e);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Видалення акаунта')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            const Icon(Icons.warning_amber, size: 64, color: Colors.red),
            const SizedBox(height: 12),
            Text('Акаунт ${Auth.email} та всі його дані буде видалено. Для підтвердження введіть пароль.', textAlign: TextAlign.center),
            const SizedBox(height: 20),
            TextField(controller: _pass, obscureText: true, decoration: InputDecoration(labelText: 'Пароль', border: const OutlineInputBorder(), errorText: _err)),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, child: FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red), onPressed: _delete, child: const Text('Видалити акаунт'))),
          ]),
        ),
      );
}
