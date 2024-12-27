import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static Future<void> initializeNotification() async {
    await AwesomeNotifications().initialize(
      'resource://drawable/logo', // Ikon kecil (small icon) diambil dari drawable Android
      [
        NotificationChannel(
          channelKey: 'water_alerts',
          channelName: 'Water Alerts',
          channelDescription: 'Notifikasi untuk kondisi air',
          defaultColor: Colors.blue,
          ledColor: Colors.blue,
          importance: NotificationImportance.High,
          playSound: true,
          enableVibration: true,
        )
      ],
    );

    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  static Future<void> showWaterQualityNotification({
    required String title,
    required String body,
    required String notifKey,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final currentUsername = prefs.getString('username');
    final currentKodeAlat = prefs.getString('kode_alat');

    final uniqueNotifKey = '${currentUsername}_${currentKodeAlat}_$notifKey';
    final lastNotifStatus = prefs.getString(uniqueNotifKey);

    if (lastNotifStatus != body) {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: 'water_alerts',
          title: '$title (Alat: $currentKodeAlat)',
          body: body,
          notificationLayout: NotificationLayout.Default,
          icon: 'resource://drawable/logo',
          bigPicture: 'asset://assets/logo.png',
          payload: {
            'username': currentUsername ?? '',
            'kode_alat': currentKodeAlat ?? '',
          },
        ),
      );

      await prefs.setString(uniqueNotifKey, body);
    }
  }

  static Future<void> checkWaterConditions(double kekeruhan, double ketinggian) async {
  final prefs = await SharedPreferences.getInstance();
  final currentUsername = prefs.getString('username');
  final currentKodeAlat = prefs.getString('kode_alat');

  print('Checking water conditions:');
  print('Tipe data ketinggian: ${ketinggian.runtimeType}');
  print('Nilai ketinggian: $ketinggian cm');
  print('Tipe data kekeruhan: ${kekeruhan.runtimeType}');
  print('Nilai kekeruhan: $kekeruhan NTU');

  if (currentUsername == null || currentKodeAlat == null) {
    print('Tidak ada user yang aktif');
    return;
  }

  final ketinggianRendahKey = '${currentUsername}_${currentKodeAlat}_ketinggian_rendah_status';
  final ketinggianTinggiKey = '${currentUsername}_${currentKodeAlat}_ketinggian_tinggi_status';
  final kekeruhanKey = '${currentUsername}_${currentKodeAlat}_kekeruhan_status';

  // Cek ketinggian (termasuk nilai 0)
  if (ketinggian <= 6.0) {  // Sekarang mencakup nilai 0
    print('Memicu notifikasi air rendah: $ketinggian cm');
    final lastStatus = prefs.getString(ketinggianRendahKey);
    if (lastStatus == null) {
      await showWaterQualityNotification(
        title: 'Peringatan Air Rendah!',
        body: 'Ketinggian air: ${ketinggian.toStringAsFixed(1)} cm. Air hampir habis!',
        notifKey: 'ketinggian_rendah_status',
      );
      await prefs.setString(ketinggianRendahKey, 'triggered');
    }
  } else if (ketinggian >= 12.0) {
    print('Memicu notifikasi air tinggi: $ketinggian cm');
    final lastStatus = prefs.getString(ketinggianTinggiKey);
    if (lastStatus == null) {
      await showWaterQualityNotification(
        title: 'Peringatan Air Tinggi!',
        body: 'Ketinggian air: ${ketinggian.toStringAsFixed(1)} cm. Air terlalu tinggi!',
        notifKey: 'ketinggian_tinggi_status',
      );
      await prefs.setString(ketinggianTinggiKey, 'triggered');
    }
  } else {
    print('Ketinggian normal: $ketinggian cm');
    await prefs.remove(ketinggianRendahKey);
    await prefs.remove(ketinggianTinggiKey);
  }

  // Cek kekeruhan
  if (kekeruhan <= 200) {
    print('Memicu notifikasi air keruh: $kekeruhan NTU');
    final lastStatus = prefs.getString(kekeruhanKey);
    if (lastStatus == null) {
      await showWaterQualityNotification(
        title: 'Peringatan Air Keruh!',
        body: 'Nilai kekeruhan air: ${kekeruhan.toStringAsFixed(1)} NTU. Air terlalu keruh!',
        notifKey: 'kekeruhan_status',
      );
      await prefs.setString(kekeruhanKey, 'triggered');
    }
  } else {
      print('Kekeruhan normal: $kekeruhan NTU');
      await prefs.remove(kekeruhanKey);
    }
  }
}
