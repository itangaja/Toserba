// lib/screens/data_air.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingScreen extends StatefulWidget {
  @override
  _SettingState createState() => _SettingState();
}

class _SettingState extends State<SettingScreen> {
  int currentIndex = 2; // Misalkan ini adalah halaman ketiga

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Setelan')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.all(30.0),
                  children: [
                    SizedBox(height: 30),
                    _buildDataCard(context, 'Pengaturan Akun', Icons.person, '/pengaturanAkun'),
                    SizedBox(height: 30),
                    _buildDataCard(context, 'Ganti Device', Icons.device_unknown, '/device_management'),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(30.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    await _logout();
                  },
                  child: Text(
                    'Keluar',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.045,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dataset),
            label: 'Data Air',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Setelan',
          ),
        ],
        currentIndex: currentIndex, // Gunakan currentIndex yang disimpan
        selectedItemColor: Colors.blue,
        onTap: (index) {
          setState(() {
            currentIndex = index; // Perbarui currentIndex saat item diklik
          });
          // Tambahkan logika navigasi
          if (index == 0) {
            Navigator.pushNamed(context, '/dashboard'); // Navigasi ke dashboard
          } else if (index == 1) {
            Navigator.pushNamed(context, '/dataair'); // Navigasi ke halaman data air
          } else if (index == 2) {
            Navigator.pushNamed(context, '/setting');
          }
        },
      ),
    );
  }

  Widget _buildDataCard(BuildContext context, String title, IconData icon, String route) {
    return GestureDetector(
      onTap: () {
        print('Navigating to: $route'); // Debug print
        Navigator.pushNamed(context, route);
      },
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(vertical: 8),
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4.0,
              offset: Offset(6, 8),
            ),
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4.0,
              offset: Offset(-4, -6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.02),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: MediaQuery.of(context).size.width * 0.08, color: Colors.white),
            ),
            SizedBox(width: MediaQuery.of(context).size.width * 0.04),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.045,
                  color: Colors.black
                )
              ),
            ),
            Icon(Icons.arrow_forward_ios),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Hapus semua data
      await prefs.clear();
      
      print("SharedPreferences cleared"); // Debug print
      
      // Navigasi ke halaman login dan hapus semua route sebelumnya
      Navigator.of(context).pushNamedAndRemoveUntil('/main', (Route<dynamic> route) => false);
    } catch (e) {
      print("Error during logout: $e");
    }
  }
}