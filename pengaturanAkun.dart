import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class PengaturanAkun extends StatefulWidget {
  @override
  _PengaturanAkunState createState() => _PengaturanAkunState();
}

class _PengaturanAkunState extends State<PengaturanAkun> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController usernameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  String oldUsername = '';
  String iP = "192.168.0.40";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Ambil data dari SharedPreferences
    String savedUsername = prefs.getString('username') ?? '';
    String savedEmail = prefs.getString('email') ?? '';
    
    setState(() {
      oldUsername = savedUsername;
      usernameController.text = savedUsername;
      emailController.text = savedEmail;
    });
    
    // Jika Anda menggunakan database (misalnya Firebase atau API),
    // Anda bisa menambahkan kode seperti ini:
    /*
    try {
      final userData = await DatabaseService().getUserData(savedUsername);
      setState(() {
        emailController.text = userData.email;
      });
    } catch (e) {
      print('Error loading user data: $e');
    }
    */
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pengaturan Akun'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: usernameController,
                decoration: InputDecoration(labelText: 'Username'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Username tidak boleh kosong';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty || !value.contains('@')) {
                    return 'Silakan masukkan email yang valid';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: passwordController,
                decoration: InputDecoration(labelText: 'Password Baru'),
                obscureText: true,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _updateProfile(),
                child: Text('Perbarui Akun'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        String uri = "http://$iP/toserba/android/editAkun.php";
        
        // Pastikan data yang dikirim
        print('Old Username: $oldUsername');
        print('New Username: ${usernameController.text}');
        print('Email: ${emailController.text}');
        
        // Buat request body
        Map<String, String> requestBody = {
          'old_username': oldUsername,
          'new_username': usernameController.text,
          'email': emailController.text,
        };

        // Tambahkan password jika ada
        if (passwordController.text.isNotEmpty) {
          requestBody['password'] = passwordController.text;
        }

        print('Sending request with body: $requestBody');

        // Kirim request
        final response = await http.post(
          Uri.parse(uri),
          body: requestBody,
        );

        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          print('Decoded response: $responseData');

          if (responseData['status'] == 'success') {
            // Update SharedPreferences
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('username', usernameController.text);
            await prefs.setString('email', emailController.text);

            // Tampilkan dialog sukses
            if (!context.mounted) return;
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 10),
                      Text('Berhasil'),
                    ],
                  ),
                  content: Text('Profil berhasil diperbarui'),
                  actions: [
                    TextButton(
                      child: Text('OK'),
                      onPressed: () {
                        Navigator.of(context).pop(); // Tutup dialog
                        Navigator.pushReplacementNamed(context, '/dashboard'); // Refresh halaman
                      },
                    ),
                  ],
                );
              },
            );
          } else {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(responseData['message'] ?? 'Gagal memperbarui profil'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          throw Exception('Server error: ${response.statusCode}');
        }
      } catch (e) {
        print('Error updating profile: $e');
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
