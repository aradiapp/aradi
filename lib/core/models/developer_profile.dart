import 'package:cloud_firestore/cloud_firestore.dart';

enum BusinessModel { business, venture, both }

class DeveloperProfile {
  final String id;
  final String userId;
  final String companyName;
  final String companyEmail;
  final String companyPhone;
  final String tradeLicense; // Required
  final String signatoryPassport; // Required
  final String? logoUrl;
  final String? portfolioPdfUrl;
  final BusinessModel businessModel;
  final List<String> areasInterested;
  final int deliveredProjects;
  final int underConstruction;
  final int landsInPipeline;
  final int teamSize;
  final DateTime freeYearStart; // Free first year from profile creation
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isVerified;

  const DeveloperProfile({
    required this.id,
    required this.userId,
    required this.companyName,
    required this.companyEmail,
    required this.companyPhone,
    required this.tradeLicense,
    required this.signatoryPassport,
    this.logoUrl,
    this.portfolioPdfUrl,
    required this.businessModel,
    required this.areasInterested,
    this.deliveredProjects = 0,
    this.underConstruction = 0,
    this.landsInPipeline = 0,
    this.teamSize = 0,
    required this.freeYearStart,
    required this.createdAt,
    required this.updatedAt,
    this.isVerified = false,
  });

  factory DeveloperProfile.fromJson(Map<String, dynamic> json) {
    return DeveloperProfile(
      id: json['id'] as String,
      userId: json['userId'] as String,
      companyName: json['companyName'] as String,
      companyEmail: json['companyEmail'] as String,
      companyPhone: json['companyPhone'] as String,
      tradeLicense: json['tradeLicense'] as String,
      signatoryPassport: json['signatoryPassport'] as String,
      logoUrl: json['logoUrl'] as String?,
      portfolioPdfUrl: json['portfolioPdfUrl'] as String?,
      businessModel: BusinessModel.values.firstWhere(
        (e) => e.toString().split('.').last == json['businessModel'],
        orElse: () => BusinessModel.business,
      ),
      areasInterested: (json['areasInterested'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      deliveredProjects: json['deliveredProjects'] as int? ?? 0,
      underConstruction: json['underConstruction'] as int? ?? 0,
      landsInPipeline: json['landsInPipeline'] as int? ?? 0,
      teamSize: json['teamSize'] as int? ?? 0,
      freeYearStart: (json['freeYearStart'] as Timestamp).toDate(),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
      isVerified: json['isVerified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'companyName': companyName,
      'companyEmail': companyEmail,
      'companyPhone': companyPhone,
      'tradeLicense': tradeLicense,
      'signatoryPassport': signatoryPassport,
      'logoUrl': logoUrl,
      'portfolioPdfUrl': portfolioPdfUrl,
      'businessModel': businessModel.toString().split('.').last,
      'areasInterested': areasInterested,
      'deliveredProjects': deliveredProjects,
      'underConstruction': underConstruction,
      'landsInPipeline': landsInPipeline,
      'teamSize': teamSize,
      'freeYearStart': Timestamp.fromDate(freeYearStart),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isVerified': isVerified,
    };
  }

  DeveloperProfile copyWith({
    String? id,
    String? userId,
    String? companyName,
    String? companyEmail,
    String? companyPhone,
    String? tradeLicense,
    String? signatoryPassport,
    String? logoUrl,
    String? portfolioPdfUrl,
    BusinessModel? businessModel,
    List<String>? areasInterested,
    int? deliveredProjects,
    int? underConstruction,
    int? landsInPipeline,
    int? teamSize,
    DateTime? freeYearStart,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isVerified,
  }) {
    return DeveloperProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      companyName: companyName ?? this.companyName,
      companyEmail: companyEmail ?? this.companyEmail,
      companyPhone: companyPhone ?? this.companyPhone,
      tradeLicense: tradeLicense ?? this.tradeLicense,
      signatoryPassport: signatoryPassport ?? this.signatoryPassport,
      logoUrl: logoUrl ?? this.logoUrl,
      portfolioPdfUrl: portfolioPdfUrl ?? this.portfolioPdfUrl,
      businessModel: businessModel ?? this.businessModel,
      areasInterested: areasInterested ?? this.areasInterested,
      deliveredProjects: deliveredProjects ?? this.deliveredProjects,
      underConstruction: underConstruction ?? this.underConstruction,
      landsInPipeline: landsInPipeline ?? this.landsInPipeline,
      teamSize: teamSize ?? this.teamSize,
      freeYearStart: freeYearStart ?? this.freeYearStart,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  // Business Logic Methods
  bool get isInFreeYear {
    final now = DateTime.now();
    final freeYearEnd = freeYearStart.add(const Duration(days: 365));
    return now.isBefore(freeYearEnd);
  }

  int get totalProjects => deliveredProjects + underConstruction + landsInPipeline;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeveloperProfile && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'DeveloperProfile(id: $id, companyName: $companyName, businessModel: $businessModel)';
  }
}
