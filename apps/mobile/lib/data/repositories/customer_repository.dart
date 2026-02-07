import 'dart:convert';
import 'dart:math';
import 'package:isar/isar.dart';
import '../../core/database/isar_database.dart';
import '../../core/sync/sync_engine.dart';
import '../entities/customer_entity.dart';
import '../entities/sync_queue_item.dart';

/// Repository for Customer operations
/// Handles registration, verification, and sync
class CustomerRepository {
  final _syncEngine = SyncEngine();
  final _random = Random();

  /// Search customers by name or phone
  Future<List<CustomerEntity>> searchCustomers(String query) async {
    final db = await IsarDatabase.instance;

    if (query.isEmpty) {
      return await db.customers
          .where()
          .sortByCreatedAtDesc()
          .limit(50)
          .findAll();
    }

    // Search by phone
    final byPhone = await db.customers
        .filter()
        .phoneContains(query)
        .findAll();

    // Search by name
    final byName = await db.customers
        .filter()
        .firstNameContains(query, caseSensitive: false)
        .or()
        .lastNameContains(query, caseSensitive: false)
        .findAll();

    // Combine and deduplicate
    final results = <CustomerEntity>{...byPhone, ...byName}.toList();
    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return results;
  }

  /// Get customer by ID
  Future<CustomerEntity?> getCustomerById(String customerId) async {
    final db = await IsarDatabase.instance;

    // Try by local ID
    if (int.tryParse(customerId) != null) {
      final byLocalId = await db.customers.get(int.parse(customerId));
      if (byLocalId != null) return byLocalId;
    }

    // Try by server ID
    final byServerId =
        await db.customers.filter().serverIdEqualTo(customerId).findFirst();
    if (byServerId != null) return byServerId;

    // Try by phone
    final byPhone =
        await db.customers.filter().phoneEqualTo(customerId).findFirst();
    return byPhone;
  }

  /// Get customer by phone
  Future<CustomerEntity?> getCustomerByPhone(String phone) async {
    final db = await IsarDatabase.instance;
    return await db.customers.filter().phoneEqualTo(phone).findFirst();
  }

  /// Register new customer
  /// Works offline, syncs when online
  Future<CustomerEntity> registerCustomer({
    required String firstName,
    String? lastName,
    required String phone,
    String? address,
    String? telegramId,
    String? telegramUsername,
    required String salesRepId,
    String? referralCode,
  }) async {
    final db = await IsarDatabase.instance;

    // Check if customer already exists
    final existing = await getCustomerByPhone(phone);
    if (existing != null) {
      throw Exception('Клиент с таким номером уже существует');
    }

    final customer = CustomerEntity(
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      telegramId: telegramId,
      telegramUsername: telegramUsername,
      address: address,
      source: 'sales_app',
      referralCode: referralCode,
      registeredBy: salesRepId,
    );

    await db.writeTxn(() async {
      // Save customer
      await db.customers.put(customer);

      // Add to sync queue
      await _queueCustomerCreate(db, customer);
    });

    // Trigger sync
    _syncEngine.sync();

    return customer;
  }

  /// Send OTP via Telegram
  /// Returns verification record
  Future<OtpVerification> sendTelegramOtp(String phone, String telegramId) async {
    final db = await IsarDatabase.instance;

    // Generate 4-digit code
    final code = _generateOtpCode();

    // Create verification record
    final verification = OtpVerification(
      phone: phone,
      code: code,
      method: 'telegram',
    );

    await db.writeTxn(() async {
      // Invalidate old codes for this phone
      final oldCodes = await db.otpVerifications
          .filter()
          .phoneEqualTo(phone)
          .and()
          .isVerifiedEqualTo(false)
          .findAll();

      for (final old in oldCodes) {
        await db.otpVerifications.delete(old.id);
      }

      // Save new code
      await db.otpVerifications.put(verification);

      // TODO: Send actual Telegram message via API
      // For now, we queue it for sync
      final queueItem = SyncQueueItem(
        entityType: 'telegram_otp',
        localId: verification.id.toString(),
        operation: 'send',
        payload: jsonEncode({
          'phone': phone,
          'telegramId': telegramId,
          'code': code,
        }),
        priority: 1,
        syncImmediately: true,
      );
      await db.syncQueue.put(queueItem);
    });

    // Trigger immediate sync
    _syncEngine.sync();

    return verification;
  }

  /// Verify OTP code
  /// Returns true if verified successfully
  Future<bool> verifyOtp(String phone, String code) async {
    final db = await IsarDatabase.instance;

    final verification = await db.otpVerifications
        .filter()
        .phoneEqualTo(phone)
        .and()
        .isVerifiedEqualTo(false)
        .sortByCreatedAtDesc()
        .findFirst();

    if (verification == null) {
      throw Exception('Код не найден или истек');
    }

    if (verification.isExpired) {
      throw Exception('Код истек, запросите новый');
    }

    if (!verification.canAttempt) {
      throw Exception('Слишком много попыток, запросите новый код');
    }

    final success = verification.recordAttempt(code);

    await db.writeTxn(() async {
      await db.otpVerifications.put(verification);
    });

    if (success) {
      // Mark customer as verified
      final customer = await getCustomerByPhone(phone);
      if (customer != null) {
        await db.writeTxn(() async {
          customer.markVerified('telegram');
          await db.customers.put(customer);
          await _queueCustomerUpdate(db, customer, 'verify');
        });
        _syncEngine.sync();
      }
    }

    return success;
  }

  /// Get my customers (registered by me)
  Future<List<CustomerEntity>> getMyCustomers(
    String salesRepId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await IsarDatabase.instance;

    return await db.customers
        .filter()
        .registeredByEqualTo(salesRepId)
        .sortByCreatedAtDesc()
        .offset(offset)
        .limit(limit)
        .findAll();
  }

  /// Get customer stats
  Future<CustomerStats> getCustomerStats(String salesRepId) async {
    final db = await IsarDatabase.instance;

    final total = await db.customers
        .filter()
        .registeredByEqualTo(salesRepId)
        .count();

    final verified = await db.customers
        .filter()
        .registeredByEqualTo(salesRepId)
        .and()
        .isPhoneVerifiedEqualTo(true)
        .count();

    final withSubscriptions = await db.customers
        .filter()
        .registeredByEqualTo(salesRepId)
        .and()
        .hasActiveSubscriptionEqualTo(true)
        .count();

    // Today's new customers
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final todayCount = await db.customers
        .filter()
        .registeredByEqualTo(salesRepId)
        .and()
        .createdAtGreaterThan(startOfDay)
        .count();

    return CustomerStats(
      total: total,
      verified: verified,
      withSubscriptions: withSubscriptions,
      todayNew: todayCount,
    );
  }

  /// Update customer info
  Future<void> updateCustomer(
    String customerId, {
    String? firstName,
    String? lastName,
    String? address,
    String? notes,
  }) async {
    final db = await IsarDatabase.instance;

    final customer = await getCustomerById(customerId);
    if (customer == null) {
      throw Exception('Клиент не найден');
    }

    await db.writeTxn(() async {
      if (firstName != null) customer.firstName = firstName;
      if (lastName != null) customer.lastName = lastName;
      if (address != null) customer.address = address;
      if (notes != null) customer.notes = notes;

      customer.updatedAt = DateTime.now();
      customer.syncStatus?.hasPendingChanges = true;

      await db.customers.put(customer);
      await _queueCustomerUpdate(db, customer, 'update');
    });

    _syncEngine.sync();
  }

  /// Watch customers for real-time updates
  Stream<List<CustomerEntity>> watchMyCustomers(String salesRepId) async* {
    final db = await IsarDatabase.instance;

    yield* db.customers
        .filter()
        .registeredByEqualTo(salesRepId)
        .sortByCreatedAtDesc()
        .watch(fireImmediately: true);
  }

  /// Generate 4-digit OTP
  String _generateOtpCode() {
    return (1000 + _random.nextInt(9000)).toString();
  }

  /// Queue customer creation
  Future<void> _queueCustomerCreate(Isar db, CustomerEntity customer) async {
    final queueItem = SyncQueueItem(
      entityType: 'customer',
      localId: customer.id.toString(),
      operation: 'create',
      payload: jsonEncode(customer.toJson()),
      priority: 2,
    );
    await db.syncQueue.put(queueItem);
  }

  /// Queue customer update
  Future<void> _queueCustomerUpdate(
    Isar db,
    CustomerEntity customer,
    String operation,
  ) async {
    final queueItem = SyncQueueItem(
      entityType: 'customer',
      localId: customer.id.toString(),
      serverId: customer.serverId,
      operation: operation,
      payload: jsonEncode(customer.toJson()),
      priority: 2,
    );
    await db.syncQueue.put(queueItem);
  }
}

/// Customer statistics
class CustomerStats {
  final int total;
  final int verified;
  final int withSubscriptions;
  final int todayNew;

  CustomerStats({
    required this.total,
    required this.verified,
    required this.withSubscriptions,
    required this.todayNew,
  });

  double get verificationRate => total > 0 ? verified / total : 0;
  double get subscriptionRate => total > 0 ? withSubscriptions / total : 0;

  String get formattedVerificationRate =>
      '${(verificationRate * 100).toStringAsFixed(0)}%';
  String get formattedSubscriptionRate =>
      '${(subscriptionRate * 100).toStringAsFixed(0)}%';
}
