import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mobile/src/core/di/injection.dart';
import 'package:mobile/src/core/network/api_client.dart';
import 'package:mobile/src/core/storage/secure_storage_service.dart';
import 'package:mobile/src/features/chat/presentation/pages/concierge_screen.dart';
import 'package:mobile/src/features/chat/presentation/state/concierge_cubit.dart';
import 'package:mobile/src/features/profile/presentation/pages/order_history_page.dart';

class PushNotificationService {
  static final navigatorKey = GlobalKey<NavigatorState>();

  final ApiClient _apiClient;
  final SecureStorageService _storageService;
  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;

  bool _initialized = false;

  PushNotificationService({
    required ApiClient apiClient,
    required SecureStorageService storageService,
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
  }) : _apiClient = apiClient,
       _storageService = storageService,
       _messaging = messaging ?? FirebaseMessaging.instance,
       _localNotifications =
           localNotifications ?? FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _initializeLocalNotifications();
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: true,
      sound: false,
    );

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageNavigation);
    _messaging.onTokenRefresh.listen((token) async {
      if (await _storageService.hasTokens) {
        await _registerToken(token);
      }
    });

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleMessageNavigation(initialMessage);
      });
    }
  }

  Future<void> syncTokenIfAuthenticated() async {
    if (!await _storageService.hasTokens) return;

    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) return;
      await _registerToken(token);
    } catch (error) {
      debugPrint('[Push] Failed to sync token: $error');
    }
  }

  Future<void> deregisterCurrentToken() async {
    if (!await _storageService.hasTokens) return;

    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) return;
      await _apiClient.dio.post(
        '/notifications/deregister-token',
        data: {'token': token},
      );
    } on DioException catch (error) {
      debugPrint('[Push] Failed to deregister token: ${error.message}');
    } catch (error) {
      debugPrint('[Push] Failed to deregister token: $error');
    }
  }

  Future<void> _registerToken(String token) async {
    try {
      await _apiClient.dio.post(
        '/notifications/register-token',
        data: {'token': token, 'deviceType': _deviceType},
      );
    } on DioException catch (error) {
      debugPrint('[Push] Failed to register token: ${error.message}');
    } catch (error) {
      debugPrint('[Push] Failed to register token: $error');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNotifications.initialize(
      settings: const InitializationSettings(android: android, iOS: darwin),
      onDidReceiveNotificationResponse: (response) {
        final payloadStr = response.payload;
        if (payloadStr == null) return;
        try {
          final Map<String, dynamic> data =
              jsonDecode(payloadStr) as Map<String, dynamic>;
          final type = data['type'] as String?;
          _navigateByType(type, data);
        } catch (e) {
          debugPrint('[Push] Error decoding payload JSON: $e');
          _navigateByType(payloadStr, const {});
        }
      },
    );

    const channel = AndroidNotificationChannel(
      'gearhub_push',
      'GearHub notifications',
      description: 'Order and chat updates',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? _fallbackTitle(message.data['type']);
    final body = notification?.body ?? '';

    if (title.isEmpty && body.isEmpty) return;

    await _localNotifications.show(
      id: message.hashCode,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'gearhub_push',
          'GearHub notifications',
          channelDescription: 'Order and chat updates',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _handleMessageNavigation(RemoteMessage message) {
    _navigateByType(message.data['type'], message.data);
  }

  void _navigateByType(String? type, Map<String, dynamic> data) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    if (type == 'order') {
      final orderId = data['orderId'] as String?;
      navigator.push(
        MaterialPageRoute(
          builder: (_) => OrderHistoryPage(
            initialStatus: 'ALL',
            initialOrderId: orderId,
          ),
        ),
      );
      return;
    }

    if (type == 'chat') {
      navigator.push(
        MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => getIt<ConciergeCubit>()..open(),
            child: const ConciergeScreen(),
          ),
        ),
      );
    }
  }

  String _fallbackTitle(dynamic type) {
    return type == 'chat' ? 'GearHub chat' : 'GearHub';
  }

  String get _deviceType {
    if (kIsWeb) return 'web';

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      _ => defaultTargetPlatform.name,
    };
  }
}
