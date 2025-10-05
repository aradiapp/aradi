import 'package:cloud_firestore/cloud_firestore.dart';

class SellerProfile {
  final String id;
  final String userId;
  final String name;
  final String phone;
  final String email;
  final String? tradeLicense;
  final String? companyTradeLicense;
  final String? tradeLicenseDocumentUrl;
  final String passportOrEmiratesId;
  final String? logoUrl;
  final List<String> interestedDevelopers;
  final int totalListings;
  final int activeListings;
  final int completedDeals;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isVerified;

  const SellerProfile({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    required this.email,
    this.tradeLicense,
    this.companyTradeLicense,
    this.tradeLicenseDocumentUrl,
    required this.passportOrEmiratesId,
    this.logoUrl,
    this.interestedDevelopers = const [],
    this.totalListings = 0,
    this.activeListings = 0,
    this.completedDeals = 0,
    required this.createdAt,
    required this.updatedAt,
    this.isVerified = false,
  });

  factory SellerProfile.fromJson(Map<String, dynamic> json) {
    return SellerProfile(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String,
      tradeLicense: json['tradeLicense'] as String?,
      companyTradeLicense: json['companyTradeLicense'] as String?,
      tradeLicenseDocumentUrl: json['tradeLicenseDocumentUrl'] as String?,
      passportOrEmiratesId: json['passportOrEmiratesId'] as String,
      logoUrl: json['logoUrl'] as String?,
      interestedDevelopers: (json['interestedDevelopers'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      totalListings: json['totalListings'] as int? ?? 0,
      activeListings: json['activeListings'] as int? ?? 0,
      completedDeals: json['completedDeals'] as int? ?? 0,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
      isVerified: json['isVerified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'phone': phone,
      'email': email,
      'tradeLicense': tradeLicense,
      'companyTradeLicense': companyTradeLicense,
      'tradeLicenseDocumentUrl': tradeLicenseDocumentUrl,
      'passportOrEmiratesId': passportOrEmiratesId,
      'logoUrl': logoUrl,
      'interestedDevelopers': interestedDevelopers,
      'totalListings': totalListings,
      'activeListings': activeListings,
      'completedDeals': completedDeals,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isVerified': isVerified,
    };
  }

  SellerProfile copyWith({
    String? id,
    String? userId,
    String? name,
    String? phone,
    String? email,
    String? tradeLicense,
    String? companyTradeLicense,
    String? tradeLicenseDocumentUrl,
    String? passportOrEmiratesId,
    String? logoUrl,
    List<String>? interestedDevelopers,
    int? totalListings,
    int? activeListings,
    int? completedDeals,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isVerified,
  }) {
    return SellerProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      tradeLicense: tradeLicense ?? this.tradeLicense,
      companyTradeLicense: companyTradeLicense ?? this.companyTradeLicense,
      tradeLicenseDocumentUrl: tradeLicenseDocumentUrl ?? this.tradeLicenseDocumentUrl,
      passportOrEmiratesId: passportOrEmiratesId ?? this.passportOrEmiratesId,
      logoUrl: logoUrl ?? this.logoUrl,
      interestedDevelopers: interestedDevelopers ?? this.interestedDevelopers,
      totalListings: totalListings ?? this.totalListings,
      activeListings: activeListings ?? this.activeListings,
      completedDeals: completedDeals ?? this.completedDeals,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  // Business Logic Methods
  double get successRate {
    if (totalListings == 0) return 0.0;
    return (completedDeals / totalListings) * 100;
  }

  bool get hasInterestedDevelopers => interestedDevelopers.isNotEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SellerProfile && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'SellerProfile(id: $id, name: $name, activeListings: $activeListings)';
  }
}
