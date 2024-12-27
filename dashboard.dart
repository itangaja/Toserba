// lib/dashboard.dart
import 'package:flutter/material.dart';
import 'kekeruhanAir.dart'; // Pastikan untuk mengimpor file KekeruhanAirScreen
import 'package:intl/intl.dart'; // Tambahkan impor ini
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'notification_service.dart';

class HomeDashboard extends StatefulWidget {
  @override
  _HomeDashboardState createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  double kekeruhan = 0.0;
  double ketinggian = 0.0;
  int currentIndex = 0;
  String username = '';
  String kodeAlat = '';
  Timer? _timer;
  bool _isLoading = true;
  String iP = "192.168.0.40";

  @override
  void initState() {
    super.initState();
    _resetData();
    _loadUsername();
  }

  void _resetData() {
    setState(() {
      kekeruhan = 0.0;
      ketinggian = 0.0;
      username = '';
      kodeAlat = '';
      _isLoading = true;
    });
  }

  Future<void> _loadUsername() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUsername = prefs.getString('username');
      final savedKodeAlat = prefs.getString('kode_alat');
      
      print("Loading data from SharedPreferences:");
      print("Username: $savedUsername");
      print("Kode Alat: $savedKodeAlat");
      
      if (savedUsername == null || savedKodeAlat == null) {
        print("No saved credentials found");
        Navigator.of(context).pushReplacementNamed('/signIn');
        return;
      }
      
      setState(() {
        username = savedUsername;
        kodeAlat = savedKodeAlat;
        _isLoading = false;
      });
      
      // Start fetching data
      _startDataFetching();
    } catch (e) {
      print("Error loading data: $e");
      Navigator.of(context).pushReplacementNamed('/signIn');
    }
  }

  void _startDataFetching() {
    // Cancel existing timer if any
    _timer?.cancel();
    
    // Fetch immediately
    _fetchKekeruhanData();
    _fetchKetinggianData();
    
    // Start new timer
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _fetchKekeruhanData();
      _fetchKetinggianData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    String greeting;

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (now.hour >= 4 && now.hour <= 12) {
      greeting = 'Selamat Pagi';
    } else if (now.hour > 12 && now.hour <= 15) {
      greeting = 'Selamat Siang';
    } else if (now.hour > 15 && now.hour <= 18) {
      greeting = 'Selamat Sore';
    } else {
      greeting = 'Selamat Malam';
    }

    String formattedDate = DateFormat('EEEE, dd MMMM yyyy').format(now);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGreeting(username),
                  _buildDate(formattedDate),
                  SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8.0,
                          offset: Offset(2, 8), // Bayangan untuk efek melayang
                        ),
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8.0,
                          offset: Offset(-2, -8), // Bayangan untuk efek melayang
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tandon Anda Aman',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                        SizedBox(height: 4),
                        Text('Dengan nilai air bersih dan airnya tinggi'),
                        SizedBox(height: 8),
                        TextButton(
                          onPressed: () {},
                          child: Text('Selengkapnya'),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 40),
                  Text('Data Air', style: TextStyle(color: Colors.white,fontSize: 25, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/kekeruhan');
                        },
                        child: _buildDataCard(
                          context,
                          'Kekeruhan Air',
                          '${kekeruhan.toStringAsFixed(1)} NTU',
                          'updated 15 min ago',
                          Colors.blue.shade100,
                          '/kekeruhan',
                          Icon(
                            Icons.water_drop,
                            size: 40.0,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/ketinggian');
                        },
                        child: _buildDataCard(
                          context,
                          'Ketinggian Air',
                          '${ketinggian.toStringAsFixed(1)} CM',
                          'updated 30 min ago',
                          Colors.orange.shade100,
                          '/ketinggian',
                          Icon(
                            Icons.water,
                            size: 40.0,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/harian');
                        },
                        child: _buildDataCard(
                          context,
                          'Laporan',
                          'Harian',
                          'updated 15 min ago',
                          Colors.purple.shade100,
                          '/harian',
                          Icon(
                            Icons.sticky_note_2,
                            size: 40.0,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/bulanan');
                        },
                        child: _buildDataCard(
                          context,
                          'Laporan',
                          'Bulanan',
                          'updated 30 min ago',
                          Colors.brown.shade100,
                          '/bulanan',
                          Icon(
                            Icons.sticky_note_2,
                            size: 40.0,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
        currentIndex: currentIndex,
        selectedItemColor: Colors.blue,
        onTap: (index) {
          if (currentIndex == index) {
            // Jika mengklik tab yang sudah aktif, jangan lakukan apa-apa
            return;
          }
          
          setState(() {
            currentIndex = index;
          });
          
          if (index == 0) {
            // Jangan gunakan pushNamed jika sudah di halaman yang sama
            if (ModalRoute.of(context)?.settings.name != '/dashboard') {
              Navigator.pushNamed(context, '/dashboard');
            }
          } else if (index == 1) {
            Navigator.pushNamed(context, '/dataair');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/setting');
          }
        },
      ),
    );
  }

  Future<void> _fetchKekeruhanData() async {
    try {
      if (kodeAlat.isEmpty) return;

      final response = await http.get(
        Uri.parse('http://$iP/toserba/android/bacakekeruhan.php?kode_alat=$kodeAlat')
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Response data kekeruhan: $data');
        
        if (data['success']) {
          final rawKekeruhan = data['data']['kekeruhan'];
          double newKekeruhan;
          
          try {
            if (rawKekeruhan is int) {
              newKekeruhan = rawKekeruhan.toDouble();
            } else {
              newKekeruhan = double.parse(rawKekeruhan.toString());
            }
            print('Raw kekeruhan dari DB (${rawKekeruhan.runtimeType}): $rawKekeruhan');
            print('Kekeruhan setelah konversi (${newKekeruhan.runtimeType}): $newKekeruhan');
          } catch (e) {
            print('Error konversi kekeruhan: $e');
            return;
          }
            
          setState(() {
            kekeruhan = newKekeruhan;
          });
          
          await NotificationService.checkWaterConditions(kekeruhan, ketinggian);
        }
      }
    } catch (e) {
      print('Error fetching kekeruhan: $e');
    }
  }

  Future<void> _fetchKetinggianData() async {
    try {
      if (kodeAlat.isEmpty) {
        print('Kode alat kosong');
        return;
      }

      final response = await http.get(
        Uri.parse('http://$iP/toserba/android/bacaketinggian.php?kode_alat=$kodeAlat')
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Response data ketinggian: $data');
        
        if (data['success']) {
          // Ambil nilai mentah dari database (int)
          final rawKetinggian = data['data']['ketinggian'];
          double newKetinggian;
          
          try {
            // Konversi dari int ke double
            if (rawKetinggian is int) {
              newKetinggian = rawKetinggian.toDouble();
            } else {
              newKetinggian = double.parse(rawKetinggian.toString());
            }
            print('Raw ketinggian dari DB (${rawKetinggian.runtimeType}): $rawKetinggian');
            print('Ketinggian setelah konversi (${newKetinggian.runtimeType}): $newKetinggian');
          } catch (e) {
            print('Error konversi ketinggian: $e');
            return;
          }
            
          setState(() {
            ketinggian = newKetinggian;
          });
          
          // Cek kondisi air dengan nilai yang sudah dikonversi
          await NotificationService.checkWaterConditions(kekeruhan, ketinggian);
        }
      }
    } catch (e) {
      print('Error fetching ketinggian: $e');
    }
  }

  Widget _buildDataCard(BuildContext context, String title, String value, String updated, Color color, String route, Widget icon) {
    return Container(
      margin: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4.0,
            offset: Offset(3, 5),
          ),
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4.0,
            offset: Offset(-2, -4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                icon,
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              updated,
              style: TextStyle(
                color: Colors.black45,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: screenWidth * 0.02),
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8.0,
            offset: Offset(4, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: screenWidth * 0.045,  // Ukuran font responsif
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: screenWidth * 0.02),
          Text(
            value,
            style: TextStyle(
              fontSize: screenWidth * 0.04,  // Ukuran font responsif
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting(String username) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Selamat Datang,',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      Text(
        username,
        style: TextStyle(
          fontSize: 20,
          color: Colors.white,
        ),
      ),
    ],
  );
}

  Widget _buildDate(String date) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Text(
      date,
      style: TextStyle(
        fontSize: screenWidth * 0.035,  // Ukuran font responsif
        color: Colors.white70,
      ),
    );
  }
}