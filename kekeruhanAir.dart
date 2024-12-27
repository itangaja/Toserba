import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class KekeruhanAirScreen extends StatefulWidget {
  @override
  _KekeruhanAirScreenState createState() => _KekeruhanAirScreenState();
}

class _KekeruhanAirScreenState extends State<KekeruhanAirScreen> {
  double kekeruhan = 0.0;
  String keterangan = '';
  final double maxKekeruhan = 600.0; // Batas maksimum kekeruhan
  int currentIndex = 1;
  String kodeAlat = '';
  Timer? _timer;
  String iP = "192.168.0.40";

  @override
  void initState() {
    super.initState();
    _loadKodeAlat();
    _startRealtimeUpdates();
  }

  void _startRealtimeUpdates() {
    // Update setiap 1 detik
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _fetchKekeruhanData();
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
    _fetchKekeruhanData();
  }

  Future<void> _fetchKekeruhanData() async {
    try {
      print('Kode alat: $kodeAlat');
      
      if (kodeAlat.isEmpty) {
        throw Exception('Kode alat tidak tersedia');
      }

      final response = await http.get(
        Uri.parse("http://$iP/toserba/android/bacakekeruhan.php?kode_alat=$kodeAlat")
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            kekeruhan = data['data']['kekeruhan'] != null ? 
                double.parse(data['data']['kekeruhan'].toString()) : 0.0;
            keterangan = _getKeterangan(kekeruhan);
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
        kekeruhan = 0.0;
        keterangan = 'Error';
      });
    }
  }

  String _getKeterangan(double value) {
    if (value >= 500) {
      return 'Bersih';
    } else if (value >= 400) {
      return 'Agak Keruh';
    } else {
      return 'Keruh';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Keruh':
        return Color(0xFF795C32);
      case 'Agak Keruh':
        return Colors.yellow;
      case 'Bersih':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kekeruhan Air'),
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
            // Nilai Kekeruhan Air
            Text(
              'Nilai Kekeruhan Air',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 60),
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 250,
                  height: 250,
                  child: CircularProgressIndicator(
                    value: kekeruhan / maxKekeruhan, // Rasio kekeruhan
                    strokeWidth: 40,
                    backgroundColor: Colors.blue[100],
                    valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor(keterangan)),
                  ),
                ),
                Text(
                  '${kekeruhan.toStringAsFixed(1)} NTU', // Menampilkan nilai kekeruhan
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 80),
            // Status Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatusIndicator('Keruh', Color(0xFF795C32), keterangan == 'Keruh'),
                _buildStatusIndicator('Agak Keruh', Colors.yellow, keterangan == 'Agak Keruh'),
                _buildStatusIndicator('Bersih', Colors.cyan, keterangan == 'Bersih'),
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
          width: 60,
          height: 60,
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
