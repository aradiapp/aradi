import 'package:cloud_firestore/cloud_firestore.dart';

enum SubscriptionStatus { active, expired, cancelled, pending }
enum SubscriptionPlan { monthly, yearly, lifetime }

class Subscription {
  final String id;
  final String userId;
  final SubscriptionPlan plan;
  final SubscriptionStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final double amount;
  final String? paymentMethodId;
  final String? stripeSubscriptionId;
  final int boughtLandCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;

  const Subscription({
    required this.id,
    required this.userId,
    required this.plan,
    this.status = SubscriptionStatus.pending,
    required this.startDate,
    required this.endDate,
    required this.amount,
    this.paymentMethodId,
    this.stripeSubscriptionId,
    this.boughtLandCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.cancelledAt,
    this.cancellationReason,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as String,
      userId: json['userId'] as String,
      plan: SubscriptionPlan.values.firstWhere(
        (e) => e.toString().split('.').last == json['plan'],
        orElse: () => SubscriptionPlan.monthly,
      ),
      status: SubscriptionStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => SubscriptionStatus.pending,
      ),
      startDate: (json['startDate'] as Timestamp).toDate(),
      endDate: (json['endDate'] as Timestamp).toDate(),
      amount: (json['amount'] as num).toDouble(),
      paymentMethodId: json['paymentMethodId'] as String?,
      stripeSubscriptionId: json['stripeSubscriptionId'] as String?,
      boughtLandCount: json['boughtLandCount'] as int? ?? 0,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
      cancelledAt: json['cancelledAt'] != null
          ? (json['cancelledAt'] as Timestamp).toDate()
          : null,
      cancellationReason: json['cancellationReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'plan': plan.toString().split('.').last,
      'status': status.toString().split('.').last,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'amount': amount,
      'paymentMethodId': paymentMethodId,
      'stripeSubscriptionId': stripeSubscriptionId,
      'boughtLandCount': boughtLandCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'cancellationReason': cancellationReason,
    };
  }

  Subscription copyWith({
    String? id,
    String? userId,
    SubscriptionPlan? plan,
    SubscriptionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    double? amount,
    String? paymentMethodId,
    String? stripeSubscriptionId,
    int? boughtLandCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? cancelledAt,
    String? cancellationReason,
  }) {
    return Subscription(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      plan: plan ?? this.plan,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      amount: amount ?? this.amount,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      stripeSubscriptionId: stripeSubscriptionId ?? this.stripeSubscriptionId,
      boughtLandCount: boughtLandCount ?? this.boughtLandCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
    );
  }

  // Business Logic Methods
  bool get isActive => status == SubscriptionStatus.active;
  bool get isExpired => status == SubscriptionStatus.expired;
  bool get isCancelled => status == SubscriptionStatus.cancelled;

  bool get isNearExpiry {
    final now = DateTime.now();
    final daysUntilExpiry = endDate.difference(now).inDays;
    return daysUntilExpiry <= 7 && daysUntilExpiry > 0;
  }

  int get daysUntilExpiry {
    final now = DateTime.now();
    return endDate.difference(now).inDays;
  }

  double get dailyCost {
    final days = endDate.difference(startDate).inDays;
    if (days == 0) return amount;
    return amount / days;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Subscription && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Subscription(id: $id, plan: $plan, status: $status, amount: $amount)';
  }
}
