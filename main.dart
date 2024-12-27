// lib/main.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';
import 'signIn.dart'; // Pastikan untuk mengimpor file SignInScreen
import 'dashboard.dart';
import 'kekeruhanAir.dart';
import 'dataAir.dart';
import 'ketinggianAir.dart'; // Pastikan untuk mengimpor file KetinggianAirScreen
import 'setting.dart';
import 'pengaturanAkun.dart';
import 'device_management.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inisialisasi notifikasi
  await NotificationService.initializeNotification();
  
  try {
    await SharedPreferences.getInstance();
  } catch (e) {
    print('Error in initialization: $e');
  }

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: LaunchScreen(),
    routes: {
      '/main': (context) => LaunchScreen(),
      '/signIn': (context) => SignInScreen(),
      '/dashboard': (context) => HomeDashboard(),
      '/kekeruhan': (context) => KekeruhanAirScreen(),
      '/ketinggian': (context) => KetinggianAirScreen(),
      '/dataair': (context) => DataAirScreen(),
      '/setting': (context) => SettingScreen(),
      '/pengaturanAkun': (context) => PengaturanAkun(),
      '/device_management': (context) => DeviceManagementScreen(),
    },
  ));
}

class LaunchScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Dapatkan ukuran layar
    final screenSize = MediaQuery.of(context).size;
    
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            height: screenSize.height,
            width: screenSize.width,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: screenSize.width * 0.8, // 80% dari lebar layar
                  height: screenSize.height * 0.4, // 40% dari tinggi layar
                  child: Image.asset(
                    'assets/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: screenSize.height * 0.05), // 5% dari tinggi layar
                
                // Text
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenSize.width * 0.1, // 10% padding horizontal
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Pantau Ketinggian',
                        style: TextStyle(
                          fontSize: screenSize.width * 0.06, // 6% dari lebar layar
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Jaga Kebersihan',
                        style: TextStyle(
                          fontSize: screenSize.width * 0.06, // 6% dari lebar layar
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: screenSize.height * 0.05),
                
                // Button
                Container(
                  width: screenSize.width * 0.5, // 50% dari lebar layar
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/signIn');
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: screenSize.height * 0.02, // 2% dari tinggi layar
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      'Mulai',
                      style: TextStyle(
                        fontSize: screenSize.width * 0.045, // 4.5% dari lebar layar
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: screenSize.height * 0.1), // 10% dari tinggi layar
              ],
            ),
          ),
        ),
      ),
    );
  }
}
