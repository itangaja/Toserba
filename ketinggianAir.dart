import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class KetinggianAirScreen extends StatefulWidget {
  @override
  _KetinggianAirScreenState createState() => _KetinggianAirScreenState();
}

class _KetinggianAirScreenState extends State<KetinggianAirScreen> {
  double ketinggian = 0.0;
  String keterangan = '';
  final double maxKetinggian = 15.0; // Batas maksimum ketinggian air
  String iP = "192.168.0.40";

  int currentIndex = 1;
  String kodeAlat = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadKodeAlat();
    _startRealtimeUpdates();
  }

  void _startRealtimeUpdates() {
    // Update setiap 1 detik
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _fetchKetinggianData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadKodeAlat() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      kodeAlat = prefs.getString('kode_alat') ?? '';
    });
    _fetchKetinggianData();
  }

  Future<void> _fetchKetinggianData() async {
    try {
      // Tambahkan print untuk debug
      print('Kode alat: $kodeAlat');
      
      if (kodeAlat.isEmpty) {
        throw Exception('Kode alat tidak tersedia');
      }

      final response = await http.get(
        Uri.parse('http://$iP/toserba/android/bacaketinggian.php?kode_alat=$kodeAlat')
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            ketinggian = data['data']['ketinggian'] != null ? 
                double.parse(data['data']['ketinggian'].toString()) : 0.0;
            keterangan = _getKeterangan(ketinggian);
          });
        } else {
          throw Exception(data['message'] ?? 'Data tidak berhasil dimuat');
        }
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        ketinggian = 0.0;
        keterangan = 'Error';
      });
    }
  }

  String _getKeterangan(double value) {
    if (value < 0 || value <= 6) {
      return 'Rendah';
    } else if (value <= 9) {
      return 'Sedang';
    } else if (value <= 11) {
      return 'Tinggi';
    } else {
      return 'Warning';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Rendah':
        return Colors.red;
      case 'Sedang':
        return Colors.yellow;
      case 'Tinggi':
        return Colors.green;
      case 'Warning':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ketinggian Air'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Nilai Ketinggian Air',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 60),
            Container(
              width: 150,
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    width: double.infinity,
                    height: ketinggian < 0 ? 
                      0 : // Jika nilai negatif, tinggi air 0
                      (ketinggian / maxKetinggian) * 300, // Jika positif, hitung seperti biasa
                    decoration: BoxDecoration(
                      color: _getStatusColor(keterangan),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${ketinggian.toStringAsFixed(1)} cm',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatusIndicator('Rendah', Colors.red, keterangan == 'Rendah'),
                _buildStatusIndicator('Sedang', Colors.yellow, keterangan == 'Sedang'),
                _buildStatusIndicator('Tinggi', Colors.green, keterangan == 'Tinggi'),
              ],
            ),
          ],
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

  Widget _buildStatusIndicator(String label, Color color, bool isActive) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? color : Colors.grey[300], // Warna aktif atau tidak
          ),
        ),
        SizedBox(height: 8),
        Text(
            label,
          style: TextStyle(fontSize: 18.0),
        ),
      ],
    );
  }
}
