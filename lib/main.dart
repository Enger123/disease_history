import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/material.dart';
import 'auth.dart';
import 'auth_screens.dart';
import 'home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  await Auth.restore();
  runApp(const MedApp());
}

void goTo(BuildContext c, Widget w) =>
    Navigator.pushAndRemoveUntil(c, MaterialPageRoute(builder: (_) => w), (_) => false);

class MedApp extends StatelessWidget {
  const MedApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Історія хвороб',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: const Color(0xFF00897B), useMaterial3: true),
        home: const SplashScreen(),
      );
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) goTo(context, Auth.userId != null ? const HomeScreen() : const LoginScreen());
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF00897B),
        body: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutBack,
            builder: (_, v, child) => Opacity(opacity: v.clamp(0, 1), child: Transform.scale(scale: v, child: child)),
            child: const Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.medical_services, size: 96, color: Colors.white),
              SizedBox(height: 16),
              Text('Історія хвороб',
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            ]),
          ),
        ),
      );
}
