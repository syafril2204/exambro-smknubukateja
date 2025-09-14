// lib/student_screen.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'login_screen.dart';
import 'webview_screen.dart';
import 'package:kiosk_mode/kiosk_mode.dart';

class StudentScreen extends StatefulWidget {
  final String username;
  final String docId; // <-- Terima docId
  const StudentScreen({super.key, required this.username, required this.docId});

  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _handleScan(String scannedUrl) async {
    // 1. Update status di Firestore
    await _firestore.collection('users').doc(widget.docId).update({
      'hasScanned': true,
    });

    // 2. Pindah ke halaman WebView
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => WebViewScreen(url: scannedUrl)),
      );
    }
  }

  void _logout() async  {
    
    await stopKioskMode();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Selamat Datang, ${widget.username}'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      // Gunakan StreamBuilder untuk memantau status 'hasScanned' secara real-time
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('users').doc(widget.docId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Terjadi error memuat data.'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Data siswa tidak ditemukan.'));
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;
          bool hasScanned = userData['hasScanned'] ?? false;

          // LOGIKA UTAMA: Tampilkan UI berdasarkan status
          if (hasScanned) {
            // JIKA SUDAH SCAN, TAMPILKAN INI
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 100,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Sesi Ujian Selesai',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Anda sudah melakukan scan QR Code. Hubungi pengawas jika terjadi kesalahan.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          } else {
            // JIKA BELUM SCAN, TAMPILKAN SCANNER
            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Arahkan kamera ke QR Code Ujian',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: MobileScanner(
                    onDetect: (capture) {
                      final List<Barcode> barcodes = capture.barcodes;
                      if (barcodes.isNotEmpty) {
                        final String? url = barcodes.first.rawValue;
                        if (url != null && url.startsWith('http')) {
                          _handleScan(url);
                        }
                      }
                    },
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
