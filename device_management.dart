import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DeviceManagementScreen extends StatefulWidget {
  @override
  _DeviceManagementScreenState createState() => _DeviceManagementScreenState();
}

class _DeviceManagementScreenState extends State<DeviceManagementScreen> {
  String currentDevice = '';
  String username = '';
  final TextEditingController deviceCodeController = TextEditingController();
  bool isLoading = true;
  List<Map<String, dynamic>> userDevices = [];
  String iP = "192.168.0.40";

  @override
  void initState() {
    super.initState();
    _loadCurrentDevice();
    _loadUserDevices();
  }

  Future<void> _loadCurrentDevice() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        currentDevice = prefs.getString('kode_alat') ?? 'Belum ada device';
        username = prefs.getString('username') ?? '';
        isLoading = false;
      });
    } catch (e) {
      print('Error loading device: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _verifyAndAddDevice() async {
    if (deviceCodeController.text.isEmpty) {
      _showNotification('Mohon masukkan kode alat', isSuccess: false);
      return;
    }

    try {
      setState(() => isLoading = true);
      
      final prefs = await SharedPreferences.getInstance();
      final String nama = prefs.getString('username') ?? '';

      print('Sending request with:');
      print('nama: $nama');
      print('alat: ${deviceCodeController.text}');

      final response = await http.post(
        Uri.parse('http://$iP/toserba/android/verifyDevice.php'),
        body: {
          'nama': nama,
          'alat': deviceCodeController.text,
        },
      );

      print('Response: ${response.body}');

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final responseData = json.decode(response.body);
        
        if (responseData['status'] == 'success') {
          await prefs.setString('kode_alat', deviceCodeController.text);
          _showNotification('Device berhasil ditambahkan', isSuccess: true);
          await Future.delayed(Duration(seconds: 1));
          Navigator.pushReplacementNamed(context, '/dashboard');
        } else {
          _showNotification(
            responseData['message'] ?? 'Kode alat tidak valid', 
            isSuccess: false
          );
        }
      } else {
        throw Exception('Server error');
      }
    } catch (e) {
      print('Error verifying device: $e');
      _showNotification('Terjadi kesalahan. Silakan coba lagi.', isSuccess: false);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showNotification(String message, {required bool isSuccess}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.error_outline,
                color: isSuccess ? Colors.green : Colors.red,
              ),
              SizedBox(width: 10),
              Text(isSuccess ? 'Berhasil' : 'Gagal'),
            ],
          ),
          content: Text(message),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                if (!isSuccess) {
                  deviceCodeController.clear();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadUserDevices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('username') ?? '';
      
      print('Loading devices for username: $username');
      
      final response = await http.get(
        Uri.parse('http://$iP/toserba/android/getUserDevices.php?username=$username'),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            userDevices = List<Map<String, dynamic>>.from(data['devices']);
          });
          print('Loaded devices: $userDevices');
        }
      }
    } catch (e) {
      print('Error loading devices: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Manajemen Device'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Device Aktif',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(currentDevice),
              SizedBox(height: 24),
              Text(
                'Daftar Device Anda',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: userDevices.length,
                itemBuilder: (context, index) {
                  final device = userDevices[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text('Kode: ${device['kode_alat']}'),
                      subtitle: Text(
                        'Nilai Keruh: ${device['nilai_keruh']}\n'
                        'Nilai Tinggi: ${device['nilai_tinggi']}'
                      ),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: device['kode_alat'] == currentDevice 
                            ? Colors.green 
                            : Colors.blue,
                        ),
                        child: Text(
                          device['kode_alat'] == currentDevice 
                            ? 'Aktif'
                            : 'Aktifkan',
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: device['kode_alat'] == currentDevice 
                          ? null 
                          : () => _activateDevice(device['kode_alat']),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 24),
              Text(
                'Tambah Device Baru',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 16),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: deviceCodeController,
                        decoration: InputDecoration(
                          labelText: 'Masukkan Kode Alat',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: Icon(Icons.qr_code),
                        ),
                      ),
                      SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _verifyAndAddDevice,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Tambah Device',
                            style: TextStyle(fontSize: 16),
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
    );
  }

  Future<void> _activateDevice(String kodeAlat) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('kode_alat', kodeAlat);
    setState(() {
      currentDevice = kodeAlat;
    });
    
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
          content: Text('Device berhasil diaktifkan'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog
                // Navigasi ke dashboard
                Navigator.pushReplacementNamed(context, '/dashboard');
              },
            ),
          ],
        );
      },
    );
  } catch (e) {
    print('Error activating device: $e');
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Gagal mengaktifkan device'))
    );
  }
}
}
