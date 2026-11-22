import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@pragma('vm:entry-point')
Future<void> berberimFirebaseBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
}

class PushNotifications {
  PushNotifications._();

  static const String _channelId = 'berberim_notifications';
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    _channelId,
    'Berberim Bildirimleri',
    description: 'Randevu ve hesap bildirimleri',
    importance: Importance.high,
  );

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static String? _userId;
  static String? _currentFid;
  static SupabaseClient? _supabase;
  static StreamSubscription<String>? _registrationSubscription;

  static Future<void> initialize() async {
    if ((!Platform.isAndroid && !Platform.isIOS) || _initialized) return;

    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(
        berberimFirebaseBackgroundHandler,
      );

      if (Platform.isAndroid) {
        await _local.initialize(
          settings: const InitializationSettings(
            android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          ),
        );

        final android = _local.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        await android?.createNotificationChannel(_channel);
        FirebaseMessaging.onMessage.listen(_showForegroundNotification);
      } else {
        await _messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      _initialized = true;
    } catch (error) {
      debugPrint('Berberim push initialization failed: $error');
    }
  }

  static Future<void> register({
    required SupabaseClient supabase,
    required String userId,
  }) async {
    if ((!Platform.isAndroid && !Platform.isIOS) || !_initialized) return;

    _supabase = supabase;
    _userId = userId;

    try {
      final permission = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (permission.authorizationStatus == AuthorizationStatus.denied) {
        return;
      }

      if (Platform.isIOS) {
        String? apnsToken = await _messaging.getAPNSToken();
        for (var attempt = 0; apnsToken == null && attempt < 20; attempt++) {
          await Future<void>.delayed(const Duration(milliseconds: 500));
          apnsToken = await _messaging.getAPNSToken();
        }
        if (apnsToken == null) {
          debugPrint(
            'Berberim push registration waiting: APNs token is not available.',
          );
          return;
        }
      }

      await _registrationSubscription?.cancel();
      _registrationSubscription = _messaging.onRegistered.listen((fid) {
        _currentFid = fid;
        unawaited(_saveFid(fid));
      });
      await _messaging.register();
    } catch (error) {
      debugPrint('Berberim push token registration failed: $error');
    }
  }

  static Future<void> _saveFid(String fid) async {
    final client = _supabase;
    final userId = _userId;
    if (client == null || userId == null) return;

    try {
      await client.rpc(
        'register_push_fid',
        params: {
          'p_fid': fid,
          'p_platform': Platform.isIOS ? 'ios' : 'android',
        },
      );
    } catch (error) {
      debugPrint('Berberim FID sync failed: $error');
    }
  }

  static Future<void> unregister(SupabaseClient supabase) async {
    final userId = _userId ?? supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final fid = _currentFid;
      if (fid != null) {
        await supabase.rpc(
          'unregister_push_fid',
          params: {'p_fid': fid},
        );
      }
    } catch (error) {
      debugPrint('Berberim push token cleanup failed: $error');
    }

    await _registrationSubscription?.cancel();
    _registrationSubscription = null;
    _userId = null;
    _currentFid = null;
    _supabase = null;
  }

  static Future<void> _showForegroundNotification(
    RemoteMessage message,
  ) async {
    final notification = message.notification;
    if (notification == null) return;

    await _local.show(
      id: message.messageId?.hashCode ??
          DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      title: notification.title ?? 'Berberim',
      body: notification.body ?? '',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Berberim Bildirimleri',
          channelDescription: 'Randevu ve hesap bildirimleri',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }
}
