// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:secure_application/secure_application.dart';
import 'firebase_options.dart';
import 'login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return SecureApplication(
      nativeRemoveDelay: 800,
      onNeedUnlock: (secure) async {
        return null;
      },
      child: SecureGate(
        child: MaterialApp(
          title: 'EXAMBRO - SMK MA\'ARIF NU BUKATEJA',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            useMaterial3: true,
          ),
          // Hilangkan banner "DEBUG" bawaan Flutter
          debugShowCheckedModeBanner: false,
          // Bungkus halaman utama dengan widget Banner
          home: Banner(
            message: "DEMO",
            location: BannerLocation.topEnd, // Posisi banner
            color: Colors.red,
            child: const LoginScreen(),
          ),
        ),
      ),
    );
  }
}