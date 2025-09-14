// lib/main.dart

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:secure_application/secure_application.dart';
import 'firebase_options.dart';
import 'login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Konfigurasi untuk Firebase Crashlytics
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Lapis 1: Keamanan Aplikasi
    return SecureApplication(
      nativeRemoveDelay: 800,
      onNeedUnlock: (secure) async {
        return null;
      },
      child: SecureGate(
        // Lapis 2: Aplikasi Utama
        child: MaterialApp(
          title: 'EXAMBRO - SMK MA\'ARIF NU BUKATEJA',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            useMaterial3: true,
          ),
          // Pastikan banner DEBUG bawaan Flutter mati
          debugShowCheckedModeBanner: false,
          
          // // Lapis 3: Watermark Banner
          // home: Banner(
          //   message: "DEMO CLIENT", // Teks watermark
          //   location: BannerLocation.topEnd, // Posisi di pojok kanan atas
          //   color: Colors.red, // Warna pita banner
          //   child: const LoginScreen(),
          // ),
        ),
      ),
    );
  }
}