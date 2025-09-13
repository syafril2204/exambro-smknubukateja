// lib/webview_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart'; // <-- IMPORT BARU
import 'package:webview_flutter/webview_flutter.dart';
import 'login_screen.dart';

class WebViewScreen extends StatefulWidget {
  final String url;
  const WebViewScreen({super.key, required this.url});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Memaksa aplikasi masuk ke mode fullscreen total
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // =================== PERINTAH SPESIFIK ANTI-SCREENSHOT ===================
    // Menambahkan pengamanan ekstra khusus untuk halaman ini
    FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
    // ======================================================================

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) => setState(() => _isLoading = true),
          onPageFinished: (String url) => setState(() => _isLoading = false),
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  void _logout() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  void dispose() {
    // Mengembalikan UI sistem ke normal
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    // Menghapus pengamanan ekstra saat halaman ditutup
    FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: SafeArea(
          top: false,
          bottom: false,
          child: Stack(
            children: [
              WebViewWidget(controller: _controller),
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _logout,
          label: const Text('Logout'),
          icon: const Icon(Icons.logout),
          backgroundColor: Colors.red[700],
          foregroundColor: Colors.white,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      ),
    );
  }
}