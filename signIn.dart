import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SignInScreen extends StatefulWidget {
  @override
  createState() {
    return signInScreenState();
  }
}

class signInScreenState extends State<SignInScreen> {
  final Formkey = GlobalKey<FormState>();
  String _nama = "";
  String _pass = "";
  String _alat = "";
  String iP = "192.168.0.40";

  @override
  Widget build(context) {
    return Scaffold(
      body: Container(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Container(
              height: MediaQuery.of(context).size.height,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: 40),
                    child: Text(
                      'TOSERBA',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Form(
                      key: Formkey,
                      child: Column(
                        children: [
                          _buildInputField(
                            field: nameField(),
                            icon: Icons.person,
                          ),
                          SizedBox(height: 20),
                          _buildInputField(
                            field: passField(),
                            icon: Icons.lock,
                          ),
                          SizedBox(height: 20),
                          _buildInputField(
                            field: alatField(),
                            icon: Icons.devices,
                          ),
                          SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            height: 45,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 5,
                              ),
                              onPressed: () {
                                if (Formkey.currentState!.validate()) {
                                  Formkey.currentState?.save();
                                  validasiLogin(_nama, _pass, _alat);
                                }
                              },
                              child: Text(
                                'MASUK',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({required Widget field, required IconData icon}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: Icon(icon, color: Colors.blue),
          ),
          Expanded(child: field),
        ],
      ),
    );
  }

  // username
  Widget nameField() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: 'Username',
        border: InputBorder.none,
        labelStyle: TextStyle(color: Colors.grey[700]),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Masukkan Username Anda';
        }
        _nama = value;
        return null;
      },
    );
  }

  // password
  Widget passField() {
    return TextFormField(
      obscureText: true,
      decoration: InputDecoration(
        labelText: 'Password',
        border: InputBorder.none,
        labelStyle: TextStyle(color: Colors.grey[700]),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Masukkan Password Anda';
        }
        _pass = value;
        return null;
      },
    );
  }

  // kode alat
  Widget alatField() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: 'Kode Alat',
        border: InputBorder.none,
        labelStyle: TextStyle(color: Colors.grey[700]),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Masukkan Kode Alat';
        }
        _alat = value;
        return null;
      },
    );
  }

  Future<void> validasiLogin(String username, String password, String alat) async {
    String uri = "http://$iP/toserba/android/loginAndro.php";
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      final response = await http.post(
        Uri.parse(uri), 
        body: {
          "nama": username,
          "password": password,
          "alat": alat
        }
      );

      final responseData = jsonDecode(response.body);
      print("Response dari server: $responseData");

      if (responseData['status'] == 'success') {
        try {
          // Ambil data dari object 'user' dalam response
          final userData = responseData['user'];
          
          // Simpan data termasuk email dari response server
          await prefs.setString('username', username);
          await prefs.setString('kode_alat', alat);
          await prefs.setString('email', userData['email'] ?? ''); // Mengambil email dari userData
          
          print("Data baru tersimpan di SharedPreferences:");
          print("Username: ${prefs.getString('username')}");
          print("Kode Alat: ${prefs.getString('kode_alat')}");
          print("Email: ${prefs.getString('email')}");
          
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/dashboard', 
            (Route<dynamic> route) => false
          );
        } catch (e) {
          print("Error menyimpan SharedPreferences: $e");
        }
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red),
                  SizedBox(width: 10),
                  Text('Login Gagal'),
                ],
              ),
              content: Text(responseData['message'] ?? 'Username atau password salah'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              actions: [
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print("Error: $e");
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                SizedBox(width: 10),
                Text('Kesalahan'),
              ],
            ),
            content: Text('Terjadi kesalahan saat menghubungi server. Silakan coba lagi nanti.'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            actions: [
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }
}
