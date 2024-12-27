// lib/screens/data_air.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class DataAirScreen extends StatefulWidget {
  @override
  _DataAirScreenState createState() => _DataAirScreenState();
}

class _DataAirScreenState extends State<DataAirScreen> {
  double kekeruhan = 0.0;
  double ketinggian = 0.0;
  String kodeAlat = '';
  Timer? _timer;
  String iP = "192.168.0.40";

  int currentIndex = 1;

  @override
  void initState() {
    super.initState();
    _loadKodeAlat();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadKodeAlat() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedKodeAlat = prefs.getString('kode_alat');
      
      print('Loading kode alat: $savedKodeAlat'); // Debug print
      
      if (savedKodeAlat != null && savedKodeAlat.isNotEmpty) {
        setState(() {
          kodeAlat = savedKodeAlat;
        });
        _startRealtimeUpdates();
      } else {
        print('Kode alat tidak ditemukan');
      }
    } catch (e) {
      print('Error loading kode alat: $e');
    }
  }

  void _startRealtimeUpdates() {
    // Cancel timer yang ada jika ada
    _timer?.cancel();

    // Fetch data pertama kali
    _fetchKekeruhanData();
    _fetchKetinggianData();

    // Set timer untuk update setiap 1 detik (sesuai dengan Arduino)
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        _fetchKekeruhanData();
        _fetchKetinggianData();
      }
    });
  }

  Future<void> _fetchKekeruhanData() async {
    try {
      if (kodeAlat.isEmpty) {
        print('Kode alat kosong');
        return;
      }

      print('Fetching kekeruhan untuk kode alat: $kodeAlat');
      
      final response = await http.get(
        Uri.parse("http://$iP/toserba/android/bacakekeruhan.php?kode_alat=$kodeAlat")
      );
      
      print('Response kekeruhan: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          final newKekeruhan = data['data']['kekeruhan'] != null ? 
              double.parse(data['data']['kekeruhan'].toString()) : 0.0;
              
          if (mounted && newKekeruhan != kekeruhan) {
            setState(() {
              kekeruhan = newKekeruhan;
            });
          }
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

      print('Fetching ketinggian untuk kode alat: $kodeAlat');
      
      final response = await http.get(
        Uri.parse('http://$iP/toserba/android/bacaketinggian.php?kode_alat=$kodeAlat')
      );
      
      print('Response ketinggian: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          final newKetinggian = data['data']['ketinggian'] != null ? 
              double.parse(data['data']['ketinggian'].toString()) : 0.0;
              
          if (mounted && newKetinggian != ketinggian) {
            setState(() {
              ketinggian = newKetinggian;
            });
          }
        }
      }
    } catch (e) {
      print('Error fetching ketinggian: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Data Air')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    children: [
                      _buildDataCard(context, 'Kekeruhan Air', '${kekeruhan.toStringAsFixed(1)} NTU', Icons.water, '/kekeruhan'),
                      SizedBox(height: 20),
                      _buildDataCard(context, 'Ketinggian Air', '${ketinggian.toStringAsFixed(1)} CM', Icons.water, '/ketinggian'),
                      SizedBox(height: 20),
                      _buildDataCard(context, 'Nilai Air', '11,875 steps', Icons.water, '/nilai'),
                      SizedBox(height: 20),
                      _buildDataCard(context, 'Laporan Harian', '7 hr 31 min', Icons.article, '/laporan_harian'),
                      SizedBox(height: 20),
                      _buildDataCard(context, 'Laporan Bulanan', '68 BPM', Icons.article, '/laporan_bulanan'),
                    ],
                  ),
                ),
              ],
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

  Widget _buildDataCard(BuildContext context, String title, String value, IconData icon, String route) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8.0,
            offset: Offset(7, 8),
          ),
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4.0,
            offset: Offset(-5, -6),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, 
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.04,
                    color: Colors.black
                  )
                ),
                Text(value, 
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.05,
                    color: Colors.black
                  )
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios),
        ],
      ),
    );
  }
}