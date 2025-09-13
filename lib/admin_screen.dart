// lib/admin_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  Future<void> _addStudent() async {
    final String username = _usernameController.text.trim();
    final String password = _passwordController.text.trim();
    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Username dan Password tidak boleh kosong.'),
        ),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username ini sudah terdaftar.')),
        );
      } else {
        await _firestore.collection('users').add({
          'username': username,
          'password': password,
          'role': 'siswa',
          'hasScanned': false, // <-- PERUBAHAN 1: Tambahkan status awal
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Siswa berhasil ditambahkan!')),
        );
        _usernameController.clear();
        _passwordController.clear();
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menambahkan siswa: $e')));
    }
    if (mounted)
      setState(() {
        _isLoading = false;
      });
  }

  Future<void> _deleteStudent(String docId) async {
    // ... (Fungsi _deleteStudent tidak berubah, biarkan saja)
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Apakah Anda yakin ingin menghapus siswa ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _firestore.collection('users').doc(docId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Siswa berhasil dihapus.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menghapus siswa: $e')));
      }
    }
  }

  // FUNGSI BARU UNTUK MERESET STATUS SCAN SISWA
  Future<void> _resetScanStatus(String docId) async {
    try {
      await _firestore.collection('users').doc(docId).update({
        'hasScanned': false,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sesi siswa berhasil di-reset. Siswa bisa scan kembali.',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mereset sesi: $e')));
    }
  }

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ... Form tambah siswa tidak berubah ...
            const Text(
              'Tambah Siswa Baru',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username Siswa Baru',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password Siswa Baru',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    onPressed: _addStudent,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Tambahkan Siswa'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
            const Divider(height: 40),

            const Text(
              'Daftar Siswa',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('users')
                  .where('role', isEqualTo: 'siswa')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                  return const Center(child: Text('Belum ada data siswa.'));

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var studentDoc = snapshot.data!.docs[index];
                    var studentData = studentDoc.data() as Map<String, dynamic>;
                    bool hasScanned = studentData['hasScanned'] ?? false;

                    return Card(
                      color: hasScanned
                          ? Colors.grey[300]
                          : Colors.white, // <-- Indikator visual
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Icon(
                            hasScanned ? Icons.check_circle : Icons.person,
                            color: Colors.white,
                          ),
                          backgroundColor: hasScanned
                              ? Colors.green
                              : Colors.blueAccent,
                        ),
                        title: Text(studentData['username'] ?? 'Tanpa Nama'),
                        subtitle: Text(
                          hasScanned
                              ? 'Status: Sudah Scan'
                              : 'Status: Belum Scan',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // <-- PERUBAHAN 2: Tombol Reset
                            IconButton(
                              icon: const Icon(
                                Icons.refresh,
                                color: Colors.orange,
                              ),
                              onPressed: () => _resetScanStatus(studentDoc.id),
                              tooltip: 'Reset Sesi Siswa',
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () => _deleteStudent(studentDoc.id),
                              tooltip: 'Hapus Siswa',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
