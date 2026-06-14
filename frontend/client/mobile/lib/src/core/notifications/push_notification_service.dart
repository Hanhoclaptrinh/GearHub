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

///quản lý vòng đời push notification của app
///xin quyền nhận thông báo, khởi tạo local notification
///đồng bộ fcm token với backend và điều hướng khi người dùng mở thông báo
class PushNotificationService {
  ///navigator dùng để điều hướng từ callback notification nằm ngoài widget tree
  static final navigatorKey = GlobalKey<NavigatorState>();

  final ApiClient _apiClient;
  final SecureStorageService _storageService;
  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;

  bool _initialized = false;

  ///tạo service push notification với các dependency cần thiết
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

  ///khởi tạo toàn bộ pipeline nhận và xử lý push notification
  ///bao gồm khởi tạo local notification, xin quyền nhận thông báo, cấu hình
  ///hiển thị foreground, lắng nghe message/token refresh và xử lý thông báo
  ///đã mở app từ trạng thái terminated
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
      //chỉ đăng ký token mới khi người dùng đang có phiên đăng nhập hợp lệ
      if (await _storageService.hasTokens) {
        await _registerToken(token);
      }
    });

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      //đợi frame đầu tiên hoàn tất để navigator sẵn sàng nhận lệnh điều hướng
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleMessageNavigation(initialMessage);
      });
    }
  }

  ///đồng bộ fcm token hiện tại lên backend nếu người dùng đã đăng nhập
  ///được gọi sau khi xác thực thành công hoặc khi cần bảo đảm backend có token
  ///mới nhất của thiết bị hiện tại
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

  ///hủy đăng ký fcm token hiện tại khỏi backend
  ///dùng trong luồng đăng xuất để backend không tiếp tục gửi thông báo
  ///đến thiết bị cho tài khoản vừa rời phiên
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

  ///đăng ký fcm token với backend kèm loại thiết bị hiện tại
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

  ///khởi tạo local notification plugin và channel android
  ///callback tap notification sẽ giải mã payload json để tái sử dụng cùng logic
  ///điều hướng với remote message từ firebase
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
          //payload được lưu dạng json từ message.data khi hiển thị foreground
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

    //channel android bắt buộc để notification foreground có độ ưu tiên cao
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

  ///hiển thị local notification khi firebase message đến trong foreground
  ///firebase foreground presentation trên app đang được tắt phần alert/sound,
  ///vì vậy local notification được dùng để kiểm soát giao diện và payload tap
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

  ///xử lý điều hướng khi người dùng mở remote notification
  void _handleMessageNavigation(RemoteMessage message) {
    _navigateByType(message.data['type'], message.data);
  }

  ///điều hướng theo loại thông báo do backend gửi trong payload
  ///hỗ trợ order để mở lịch sử đơn hàng và chat để mở màn concierge
  ///không thực hiện điều hướng nếu không nhận được response từ backend
  void _navigateByType(String? type, Map<String, dynamic> data) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    if (type == 'order') {
      final orderId = data['orderId'] as String?;
      navigator.push(
        MaterialPageRoute(
          builder: (_) =>
              OrderHistoryPage(initialStatus: 'ALL', initialOrderId: orderId),
        ),
      );
      return;
    }

    if (type == 'chat') {
      //tạo cubit mới cho màn chat để bảo đảm phiên concierge được mở khi vào màn
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

  ///trả về tiêu đề mặc định khi remote notification không có title
  String _fallbackTitle(dynamic type) {
    return type == 'chat' ? 'GearHub chat' : 'GearHub';
  }

  ///xác định loại thiết bị gửi lên backend khi đăng ký token
  String get _deviceType {
    if (kIsWeb) return 'web';

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      _ => defaultTargetPlatform.name,
    };
  }
}
