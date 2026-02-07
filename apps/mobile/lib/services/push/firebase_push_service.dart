import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../core/theme/ios_theme.dart';

/// Firebase Cloud Messaging service for push notifications
/// Handles: OTP notifications, new orders, sync status, AI tips
class FirebasePushService {
  static final FirebasePushService _instance = FirebasePushService._internal();
  factory FirebasePushService() => _instance;
  FirebasePushService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();

  final _messageController = StreamController<PushMessage>.broadcast();
  String? _fcmToken;

  /// Stream of incoming push messages
  Stream<PushMessage> get messageStream => _messageController.stream;

  /// Get FCM token for this device
  String? get fcmToken => _fcmToken;

  /// Initialize Firebase and push notifications
  Future<void> initialize() async {
    // Initialize Firebase
    await Firebase.initializeApp();

    // Request permissions
    await _requestPermissions();

    // Initialize local notifications (for foreground)
    await _initLocalNotifications();

    // Get FCM token
    _fcmToken = await _fcm.getToken();
    print('FCM Token: $_fcmToken');

    // Listen for token refresh
    _fcm.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      _onTokenRefresh(newToken);
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background/terminated messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle notification clicks (when app is opened from notification)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } else {
      // Android - request permission for Android 13+
      await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  /// Initialize local notifications for foreground display
  Future<void> _initLocalNotifications() async {
    const initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/ic_notification');
    
    const initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTapped,
    );
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    print('Foreground message received: ${message.notification?.title}');
    
    final pushMessage = PushMessage.fromRemoteMessage(message);
    _messageController.add(pushMessage);

    // Show local notification
    _showLocalNotification(pushMessage);
  }

  /// Handle notification tap when app is in background/terminated
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('App opened from notification: ${message.notification?.title}');
    
    final pushMessage = PushMessage.fromRemoteMessage(message);
    _messageController.add(pushMessage.copyWith(wasTapped: true));
  }

  /// Show local notification (for foreground)
  Future<void> _showLocalNotification(PushMessage message) async {
    // Don't show for some silent notification types
    if (message.type == PushType.syncComplete) return;

    final androidDetails = AndroidNotificationDetails(
      message.channelId,
      message.channelName,
      channelDescription: message.channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@drawable/ic_notification',
      color: const Color(0xFF007AFF),
    );

    final iosDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.title,
      message.body,
      details,
      payload: jsonEncode(message.toJson()),
    );
  }

  /// Handle local notification tap
  void _onLocalNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      final data = jsonDecode(response.payload!);
      final message = PushMessage.fromJson(data);
      _messageController.add(message.copyWith(wasTapped: true));
    }
  }

  /// Subscribe to topics
  Future<void> subscribeToTopic(String topic) async {
    await _fcm.subscribeToTopic(topic);
    print('Subscribed to topic: $topic');
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _fcm.unsubscribeFromTopic(topic);
    print('Unsubscribed from topic: $topic');
  }

  /// Subscribe to driver topics
  Future<void> subscribeAsDriver(String driverId) async {
    await subscribeToTopic('drivers');
    await subscribeToTopic('driver_$driverId');
  }

  /// Subscribe to sales topics
  Future<void> subscribeAsSales(String salesRepId) async {
    await subscribeToTopic('sales');
    await subscribeToTopic('sales_$salesRepId');
  }

  /// Clear badge count (iOS)
  Future<void> clearBadge() async {
    await _fcm.setForegroundNotificationPresentationOptions(
      badge: false,
    );
  }

  /// Handle token refresh
  void _onTokenRefresh(String newToken) {
    // TODO: Send new token to backend
    print('FCM Token refreshed: $newToken');
  }

  /// Dispose
  void dispose() {
    _messageController.close();
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Background message received: ${message.notification?.title}');
  
  // Handle background message (e.g., sync data)
  // Note: UI updates not possible here
}

/// Push message model
class PushMessage {
  final String? messageId;
  final String title;
  final String body;
  final PushType type;
  final Map<String, dynamic> data;
  final DateTime receivedAt;
  final bool wasTapped;

  String get channelId => _getChannelId(type);
  String get channelName => _getChannelName(type);
  String get channelDescription => _getChannelDescription(type);

  PushMessage({
    this.messageId,
    required this.title,
    required this.body,
    required this.type,
    this.data = const {},
    DateTime? receivedAt,
    this.wasTapped = false,
  }) : receivedAt = receivedAt ?? DateTime.now();

  factory PushMessage.fromRemoteMessage(RemoteMessage message) {
    final data = message.data;
    final type = PushType.fromString(data['type'] ?? 'unknown');

    return PushMessage(
      messageId: message.messageId,
      title: message.notification?.title ?? 'Новое уведомление',
      body: message.notification?.body ?? '',
      type: type,
      data: data,
    );
  }

  factory PushMessage.fromJson(Map<String, dynamic> json) {
    return PushMessage(
      messageId: json['messageId'],
      title: json['title'],
      body: json['body'],
      type: PushType.fromString(json['type']),
      data: json['data'] ?? {},
      receivedAt: DateTime.parse(json['receivedAt']),
      wasTapped: json['wasTapped'] ?? false,
    );
  }

  PushMessage copyWith({
    bool? wasTapped,
  }) {
    return PushMessage(
      messageId: messageId,
      title: title,
      body: body,
      type: type,
      data: data,
      receivedAt: receivedAt,
      wasTapped: wasTapped ?? this.wasTapped,
    );
  }

  Map<String, dynamic> toJson() => {
        'messageId': messageId,
        'title': title,
        'body': body,
        'type': type.name,
        'data': data,
        'receivedAt': receivedAt.toIso8601String(),
        'wasTapped': wasTapped,
      };

  static String _getChannelId(PushType type) {
    switch (type) {
      case PushType.otp:
        return 'otp_channel';
      case PushType.newOrder:
        return 'orders_channel';
      case PushType.syncComplete:
        return 'sync_channel';
      case PushType.aiTip:
        return 'ai_channel';
      default:
        return 'default_channel';
    }
  }

  static String _getChannelName(PushType type) {
    switch (type) {
      case PushType.otp:
        return 'Код подтверждения';
      case PushType.newOrder:
        return 'Новые заказы';
      case PushType.syncComplete:
        return 'Синхронизация';
      case PushType.aiTip:
        return 'AI Подсказки';
      default:
        return 'Уведомления';
    }
  }

  static String _getChannelDescription(PushType type) {
    switch (type) {
      case PushType.otp:
        return 'Уведомления с кодами подтверждения';
      case PushType.newOrder:
        return 'Уведомления о новых заказах и назначениях';
      case PushType.syncComplete:
        return 'Статус синхронизации данных';
      case PushType.aiTip:
        return 'Подсказки от AI ассистента';
      default:
        return 'Общие уведомления';
    }
  }
}

/// Push notification types
enum PushType {
  otp,          // OTP code sent
  newOrder,     // New order assigned
  orderUpdated, // Order status changed
  syncComplete, // Data sync completed
  aiTip,        // AI assistant tip
  unknown,      // Unknown type
}

extension PushTypeExtension on PushType {
  static PushType fromString(String value) {
    switch (value) {
      case 'otp':
        return PushType.otp;
      case 'newOrder':
        return PushType.newOrder;
      case 'orderUpdated':
        return PushType.orderUpdated;
      case 'syncComplete':
        return PushType.syncComplete;
      case 'aiTip':
        return PushType.aiTip;
      default:
        return PushType.unknown;
    }
  }

  bool get isHighPriority => this == PushType.otp || this == PushType.newOrder;
}

/// Push notification handlers
class PushHandlers {
  /// Handle OTP notification
  static void handleOtp(PushMessage message, Function(String code) onCode) {
    final code = message.data['code'];
    if (code != null) {
      onCode(code.toString());
    }
  }

  /// Handle new order notification
  static void handleNewOrder(PushMessage message, Function(String orderId) onOrder) {
    final orderId = message.data['orderId'];
    if (orderId != null) {
      onOrder(orderId.toString());
    }
  }

  /// Handle sync complete
  static void handleSyncComplete(Function() onSync) {
    onSync();
  }
}
