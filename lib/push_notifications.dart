import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@pragma('vm:entry-point')
Future<void> berberimFirebaseBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid && Firebase.apps.isEmpty) {
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
  static String? _currentToken;
  static SupabaseClient? _supabase;
  static StreamSubscription<String>? _tokenRefreshSubscription;

  static Future<void> initialize() async {
    if (!Platform.isAndroid || _initialized) return;

    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(
        berberimFirebaseBackgroundHandler,
      );

      await _local.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );

      final android = _local.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(_channel);

      FirebaseMessaging.onMessage.listen(_showForegroundNotification);
      _initialized = true;
    } catch (error) {
      debugPrint('Berberim push initialization failed: $error');
    }
  }

  static Future<void> register({
    required SupabaseClient supabase,
    required String userId,
  }) async {
    if (!Platform.isAndroid || !_initialized) return;

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

      final token = await _messaging.getToken();
      if (token != null) {
        _currentToken = token;
        await _saveToken(token);
      }

      await _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((nextToken) {
        _currentToken = nextToken;
        unawaited(_saveToken(nextToken));
      });
    } catch (error) {
      debugPrint('Berberim push token registration failed: $error');
    }
  }

  static Future<void> _saveToken(String token) async {
    final client = _supabase;
    final userId = _userId;
    if (client == null || userId == null) return;

    await client.from('push_tokens').upsert(
      {
        'user_id': userId,
        'token': token,
        'platform': 'android',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'user_id,token',
    );
  }

  static Future<void> unregister(SupabaseClient supabase) async {
    final userId = _userId ?? supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final token = _currentToken ?? await _messaging.getToken();
      if (token != null) {
        await supabase
            .from('push_tokens')
            .delete()
            .eq('user_id', userId)
            .eq('token', token);
      }
    } catch (error) {
      debugPrint('Berberim push token cleanup failed: $error');
    }

    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _userId = null;
    _currentToken = null;
    _supabase = null;
  }

  static Future<void> _showForegroundNotification(
    RemoteMessage message,
  ) async {
    final notification = message.notification;
    if (notification == null) return;

    await _local.show(
      message.messageId?.hashCode ??
          DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      notification.title ?? 'Berberim',
      notification.body ?? '',
      const NotificationDetails(
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
