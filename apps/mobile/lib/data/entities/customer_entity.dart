import 'package:isar/isar.dart';
import 'sync_queue_item.dart';

part 'customer_entity.g.dart';

/// Customer entity for local storage
/// Tracks client information and verification status
@Collection()
class CustomerEntity {
  Id id = Isar.autoIncrement;

  /// Server customer ID (null until synced)
  @Index(unique: true)
  String? serverId;

  /// Telegram ID (if registered via bot)
  @Index(unique: true)
  String? telegramId;

  /// Telegram username
  String? telegramUsername;

  /// First name
  late String firstName;

  /// Last name
  String? lastName;

  /// Full name (computed)
  String get fullName => '$firstName ${lastName ?? ''}'.trim();

  /// Phone number (primary identifier for SMS/Telegram)
  @Index(unique: true)
  late String phone;

  /// Is phone verified via OTP
  bool isPhoneVerified = false;

  /// Verification method: 'telegram', 'sms', 'manual'
  String? verificationMethod;

  /// Delivery address
  String? address;
  double? addressLat;
  double? addressLng;

  /// Additional info
  String? email;
  String? notes;

  /// Customer source: 'sales_app', 'telegram_bot', 'referral'
  late String source;

  /// Referrer info
  String? referralCode;
  String? referredBy;

  /// Sales manager who registered this customer
  String? registeredBy;
  DateTime? registeredAt;

  /// Subscription info (denormalized)
  bool hasActiveSubscription = false;
  String? activeSubscriptionId;
  DateTime? subscriptionEndDate;

  /// Total orders count
  int totalOrders = 0;
  double totalSpent = 0;

  /// Last order date
  DateTime? lastOrderAt;

  /// Customer status: 'active', 'inactive', 'blocked'
  @Index()
  String status = 'active';

  /// Sync status
  SyncStatus? syncStatus;

  /// Local timestamps
  late DateTime createdAt;
  late DateTime updatedAt;

  CustomerEntity({
    required this.firstName,
    this.lastName,
    required this.phone,
    this.telegramId,
    this.telegramUsername,
    this.address,
    this.addressLat,
    this.addressLng,
    this.email,
    this.notes,
    this.source = 'sales_app',
    this.referralCode,
    this.referredBy,
    this.registeredBy,
    this.syncStatus,
  }) {
    createdAt = DateTime.now();
    updatedAt = DateTime.now();
    syncStatus ??= SyncStatus();
    registeredAt = DateTime.now();
    
    // Generate referral code if not provided
    referralCode ??= _generateReferralCode();
  }

  /// Generate unique referral code
  String _generateReferralCode() {
    final random = DateTime.now().millisecondsSinceEpoch % 10000;
    final namePart = firstName.toUpperCase().substring(0, 
      firstName.length > 3 ? 3 : firstName.length);
    return '$namePart$random';
  }

  /// Mark phone as verified
  void markVerified(String method) {
    isPhoneVerified = true;
    verificationMethod = method;
    updatedAt = DateTime.now();
    syncStatus?.hasPendingChanges = true;
  }

  /// Update subscription info
  void updateSubscription({
    required bool hasActive,
    String? subscriptionId,
    DateTime? endDate,
  }) {
    hasActiveSubscription = hasActive;
    activeSubscriptionId = subscriptionId;
    subscriptionEndDate = endDate;
    updatedAt = DateTime.now();
    syncStatus?.hasPendingChanges = true;
  }

  /// Record new order
  void recordOrder(double amount) {
    totalOrders++;
    totalSpent += amount;
    lastOrderAt = DateTime.now();
    updatedAt = DateTime.now();
    syncStatus?.hasPendingChanges = true;
  }

  Map<String, dynamic> toJson() => {
        'id': serverId,
        'telegramId': telegramId,
        'telegramUsername': telegramUsername,
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'isPhoneVerified': isPhoneVerified,
        'address': address,
        'referralCode': referralCode,
        'registeredBy': registeredBy,
        'totalOrders': totalOrders,
        'totalSpent': totalSpent,
        'status': status,
      };
}

/// OTP verification record
@Collection()
class OtpVerification {
  Id id = Isar.autoIncrement;

  /// Phone number being verified
  @Index()
  late String phone;

  /// OTP code (hashed or encrypted in production)
  late String code;

  /// Verification method: 'telegram', 'sms'
  late String method;

  /// Created at
  late DateTime createdAt;

  /// Expires at (5 minutes)
  late DateTime expiresAt;

  /// Is verified
  bool isVerified = false;

  /// Verified at
  DateTime? verifiedAt;

  /// Number of attempts
  int attempts = 0;
  static const int maxAttempts = 3;

  OtpVerification({
    required this.phone,
    required this.code,
    required this.method,
    DateTime? expiresAt,
  }) {
    createdAt = DateTime.now();
    this.expiresAt = expiresAt ?? createdAt.add(const Duration(minutes: 5));
  }

  /// Is expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Can attempt verification
  bool get canAttempt => !isExpired && attempts < maxAttempts && !isVerified;

  /// Record attempt
  bool recordAttempt(String enteredCode) {
    attempts++;
    if (enteredCode == code) {
      isVerified = true;
      verifiedAt = DateTime.now();
      return true;
    }
    return false;
  }

  /// Time remaining in seconds
  int get secondsRemaining {
    final remaining = expiresAt.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }
}

/// Quick order draft (before submission)
@Collection()
class QuickOrder {
  Id id = Isar.autoIncrement;

  /// Customer ID
  @Index()
  String? customerId;

  /// Customer info (denormalized for drafts)
  String? customerName;
  String? customerPhone;
  String? customerAddress;

  /// Sales manager creating the order
  late String salesRepId;

  /// Order items
  List<QuickOrderItem> items = [];

  /// Total amount
  double get totalAmount => items.fold(0, (sum, i) => sum + i.total);

  /// Notes
  String? notes;

  /// Status: 'draft', 'submitted', 'confirmed'
  String status = 'draft';

  /// Created at
  late DateTime createdAt;

  /// Submitted at
  DateTime? submittedAt;

  QuickOrder({
    this.customerId,
    this.customerName,
    this.customerPhone,
    this.customerAddress,
    required this.salesRepId,
    this.items = const [],
    this.notes,
  }) {
    createdAt = DateTime.now();
  }

  void addItem(QuickOrderItem item) {
    items.add(item);
  }

  void removeItem(String productId) {
    items.removeWhere((i) => i.productId == productId);
  }

  void updateQuantity(String productId, double quantity) {
    final item = items.firstWhere((i) => i.productId == productId);
    item.quantity = quantity;
  }
}

@embedded
class QuickOrderItem {
  late String productId;
  late String productName;
  late double price;
  late double quantity;
  late String unit;
  String? imageUrl;

  QuickOrderItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.unit,
    this.imageUrl,
  });

  double get total => price * quantity;
}
