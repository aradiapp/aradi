import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { developer, buyer, seller, admin }

class User {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final UserRole role;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isEmailVerified;
  final bool isProfileComplete;
  final bool isKycVerified; // Admin verification status
  final bool wasKycRejected; // Track if user was previously approved then rejected
  final String? kycRejectionReason; // Reason for KYC rejection
  final Map<String, dynamic>? profileData;
  final List<String>? interests;
  final String? avatarUrl;
  final String? profilePictureUrl;

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    required this.role,
    required this.createdAt,
    this.lastLoginAt,
    this.isEmailVerified = false,
    this.isProfileComplete = false,
    this.isKycVerified = false,
    this.wasKycRejected = false,
    this.kycRejectionReason,
    this.profileData,
    this.interests,
    this.avatarUrl,
    this.profilePictureUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == json['role'],
      ),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      lastLoginAt: json['lastLoginAt'] != null
          ? (json['lastLoginAt'] as Timestamp).toDate()
          : null,
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      isProfileComplete: json['isProfileComplete'] as bool? ?? false,
      isKycVerified: json['isKycVerified'] as bool? ?? false,
      wasKycRejected: json['wasKycRejected'] as bool? ?? false,
      kycRejectionReason: json['kycRejectionReason'] as String?,
      profileData: json['profileData'] as Map<String, dynamic>?,
      interests: (json['interests'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      avatarUrl: json['avatarUrl'] as String?,
      profilePictureUrl: json['profilePictureUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'role': role.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
        'isEmailVerified': isEmailVerified,
        'isProfileComplete': isProfileComplete,
        'isKycVerified': isKycVerified,
        'wasKycRejected': wasKycRejected,
        'kycRejectionReason': kycRejectionReason,
        'profileData': profileData,
      'interests': interests,
      'avatarUrl': avatarUrl,
      'profilePictureUrl': profilePictureUrl,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    UserRole? role,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isEmailVerified,
    bool? isProfileComplete,
    bool? isKycVerified,
    bool? wasKycRejected,
    String? kycRejectionReason,
    Map<String, dynamic>? profileData,
    List<String>? interests,
    String? avatarUrl,
    String? profilePictureUrl,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      isKycVerified: isKycVerified ?? this.isKycVerified,
      wasKycRejected: wasKycRejected ?? this.wasKycRejected,
      kycRejectionReason: kycRejectionReason ?? this.kycRejectionReason,
      profileData: profileData ?? this.profileData,
      interests: interests ?? this.interests,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'User(id: $id, email: $email, name: $name, role: $role)';
  }
}
