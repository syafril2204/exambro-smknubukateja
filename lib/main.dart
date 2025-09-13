// lib/main.dart

import 'dart:async'; // <-- Import baru
import 'dart:ui'; // <-- Import baru
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart'; // <-- Import baru
import 'package:secure_application/secure_application.dart';
import 'firebase_options.dart';
import 'login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // =================== KODE BARU UNTUK CRASHLYTICS ===================
  // Menangkap error dari framework Flutter
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  // Menangkap error dari luar framework Flutter (misal: native code)
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  // ====================================================================

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Sisa kode ini tidak berubah
    return SecureApplication(
      nativeRemoveDelay: 800,
      onNeedUnlock: (secure) async {
        return null;
      },
      child: SecureGate(
        child: MaterialApp(
          title: 'EXAMBRO - SMK MA\'ARIF NU BUKATEJA',
          theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
          debugShowCheckedModeBanner: false,
          home: const LoginScreen(),
          // Anda bisa memilih salah satu metode watermark di sini jika mau
        ),
      ),
    );
  }
}
