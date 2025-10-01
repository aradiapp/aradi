import 'package:cloud_firestore/cloud_firestore.dart';

class BuyerProfile {
  final String id;
  final String userId;
  final String name;
  final String passport;
  final String email;
  final String phone;
  final List<String> areasInterested;
  final Map<String, double>? gfaRange;
  final Map<String, double>? budgetRange;
  final bool hasActiveSubscription;
  final DateTime? subscriptionExpiry;
  final int boughtLandCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BuyerProfile({
    required this.id,
    required this.userId,
    required this.name,
    required this.passport,
    required this.email,
    required this.phone,
    this.areasInterested = const [],
    this.gfaRange,
    this.budgetRange,
    this.hasActiveSubscription = false,
    this.subscriptionExpiry,
    this.boughtLandCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BuyerProfile.fromJson(Map<String, dynamic> json) {
    return BuyerProfile(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      passport: json['passport'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      areasInterested: (json['areasInterested'] as List?)?.map((e) => e as String).toList() ?? [],
      gfaRange: json['gfaRange'] != null ? Map<String, double>.from(json['gfaRange']) : null,
      budgetRange: json['budgetRange'] != null ? Map<String, double>.from(json['budgetRange']) : null,
      hasActiveSubscription: json['hasActiveSubscription'] as bool? ?? false,
      subscriptionExpiry: json['subscriptionExpiry'] != null
          ? (json['subscriptionExpiry'] as Timestamp).toDate()
          : null,
      boughtLandCount: json['boughtLandCount'] as int? ?? 0,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'passport': passport,
      'email': email,
      'phone': phone,
      'areasInterested': areasInterested,
      'gfaRange': gfaRange,
      'budgetRange': budgetRange,
      'hasActiveSubscription': hasActiveSubscription,
      'subscriptionExpiry': subscriptionExpiry != null
          ? Timestamp.fromDate(subscriptionExpiry!)
          : null,
      'boughtLandCount': boughtLandCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  BuyerProfile copyWith({
    String? id,
    String? userId,
    String? name,
    String? passport,
    String? email,
    String? phone,
    List<String>? areasInterested,
    Map<String, double>? gfaRange,
    Map<String, double>? budgetRange,
    bool? hasActiveSubscription,
    DateTime? subscriptionExpiry,
    int? boughtLandCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BuyerProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      passport: passport ?? this.passport,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      areasInterested: areasInterested ?? this.areasInterested,
      gfaRange: gfaRange ?? this.gfaRange,
      budgetRange: budgetRange ?? this.budgetRange,
      hasActiveSubscription: hasActiveSubscription ?? this.hasActiveSubscription,
      subscriptionExpiry: subscriptionExpiry ?? this.subscriptionExpiry,
      boughtLandCount: boughtLandCount ?? this.boughtLandCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Business Logic Methods
  bool get canAccessListings => hasActiveSubscription;

  bool get isSubscriptionExpired {
    if (subscriptionExpiry == null) return true;
    return DateTime.now().isAfter(subscriptionExpiry!);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BuyerProfile && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'BuyerProfile(id: $id, name: $name, hasSubscription: $hasActiveSubscription)';
  }
}
