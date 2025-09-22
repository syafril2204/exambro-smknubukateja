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

  final ValueNotifier<List<String>> _selectedStudentIdsNotifier =
      ValueNotifier([]);

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _selectedStudentIdsNotifier.dispose();
    super.dispose();
  }

  Future<void> _addStudent() async {
    final String username = _usernameController.text.trim();
    final String password = _passwordController.text.trim();
    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Username dan Password tidak boleh kosong.')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Username ini sudah terdaftar.')));
      } else {
        await _firestore.collection('users').add({
          'username': username,
          'password': password,
          'role': 'siswa',
          'hasScanned': false,
        });
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Siswa berhasil ditambahkan!')));
        _usernameController.clear();
        _passwordController.clear();
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal menambahkan siswa: $e')));
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _deleteSelectedStudents() async {
    final selectedIds = _selectedStudentIdsNotifier.value;
    if (selectedIds.isEmpty) return;

    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konfirmasi Hapus (${selectedIds.length} Siswa)'),
        content: const Text('Yakin ingin menghapus semua siswa yang terpilih?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Hapus')),
        ],
      ),
    );
    if (confirm == true) {
      WriteBatch batch = _firestore.batch();
      for (String docId in selectedIds) {
        batch.delete(_firestore.collection('users').doc(docId));
      }
      await batch.commit();
      _selectedStudentIdsNotifier.value = [];
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Siswa terpilih berhasil dihapus.')));
    }
  }

  Future<void> _resetSelectedStudents() async {
    final selectedIds = _selectedStudentIdsNotifier.value;
    if (selectedIds.isEmpty) return;

    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konfirmasi Reset (${selectedIds.length} Siswa)'),
        content: const Text(
            'Yakin ingin mereset sesi scan semua siswa yang terpilih?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Reset')),
        ],
      ),
    );
    if (confirm == true) {
      WriteBatch batch = _firestore.batch();
      for (String docId in selectedIds) {
        batch.update(
            _firestore.collection('users').doc(docId), {'hasScanned': false});
      }
      await batch.commit();
      _selectedStudentIdsNotifier.value = [];
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Sesi siswa terpilih berhasil di-reset.')));
    }
  }

  Future<void> _resetAllStudents() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Reset SEMUA Siswa'),
        content: const Text(
            'Apakah Anda yakin ingin mereset sesi scan SEMUA siswa?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Reset Semua')),
        ],
      ),
    );

    if (confirm == true) {
      final querySnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'siswa')
          .get();
      WriteBatch batch = _firestore.batch();
      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {'hasScanned': false});
      }
      await batch.commit();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sesi semua siswa berhasil di-reset.')));
    }
  }

  Future<void> _deleteAllStudents() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus SEMUA Siswa'),
        content: const Text(
            'PERINGATAN: Tindakan ini akan menghapus SEMUA data siswa dan tidak bisa dibatalkan. Apakah Anda benar-benar yakin?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('HAPUS SEMUA',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      final querySnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'siswa')
          .get();
      WriteBatch batch = _firestore.batch();
      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Semua siswa berhasil dihapus.')));
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
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout)
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Tambah Siswa Baru',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                    labelText: 'Username Siswa Baru',
                    border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                    labelText: 'Password Siswa Baru',
                    border: OutlineInputBorder())),
            const SizedBox(height: 20),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    onPressed: _addStudent,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Tambahkan Siswa'),
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16))),
            const Divider(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Daftar Siswa',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: _resetAllStudents,
                      icon: const Icon(Icons.refresh, color: Colors.orange),
                      label: const Text('Reset All',
                          style: TextStyle(color: Colors.orange)),
                    ),
                    TextButton.icon(
                      onPressed: _deleteAllStudents,
                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                      label: const Text('Hapus Semua',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(height: 10),
            ValueListenableBuilder<List<String>>(
              valueListenable: _selectedStudentIdsNotifier,
              builder: (context, selectedIds, child) {
                if (selectedIds.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('${selectedIds.length} terpilih'),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                          onPressed: _resetSelectedStudents,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reset'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange)),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                          onPressed: _deleteSelectedStudents,
                          icon: const Icon(Icons.delete),
                          label: const Text('Hapus'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red)),
                    ],
                  ),
                );
              },
            ),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('users')
                  .where('role', isEqualTo: 'siswa')
                  .orderBy('username')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                  return const Center(child: Text('Belum ada data siswa.'));

                return ValueListenableBuilder<List<String>>(
                  valueListenable: _selectedStudentIdsNotifier,
                  builder: (context, selectedIds, child) {
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var studentDoc = snapshot.data!.docs[index];
                        var studentData =
                            studentDoc.data() as Map<String, dynamic>;
                        bool hasScanned = studentData['hasScanned'] ?? false;
                        bool isSelected = selectedIds.contains(studentDoc.id);

                        return Card(
                          color: isSelected
                              ? Colors.lightBlue[100]
                              : (hasScanned ? Colors.grey[300] : Colors.white),
                          child: ListTile(
                            leading: Checkbox(
                              value: isSelected,
                              onChanged: (bool? value) {
                                final currentList =
                                    List<String>.from(selectedIds);
                                if (value == true) {
                                  currentList.add(studentDoc.id);
                                } else {
                                  currentList.remove(studentDoc.id);
                                }
                                _selectedStudentIdsNotifier.value = currentList;
                              },
                            ),
                            title:
                                Text(studentData['username'] ?? 'Tanpa Nama'),
                            subtitle: Text(hasScanned
                                ? 'Status: Sudah Scan'
                                : 'Status: Belum Scan'),
                          ),
                        );
                      },
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
