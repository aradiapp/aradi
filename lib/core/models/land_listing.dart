import 'package:cloud_firestore/cloud_firestore.dart';

enum OwnershipType { freehold, leasehold, gcc }
enum PermissionType { residential, commercial, hotel, mix }
enum ListingStatus { pending_verification, active, sold, expired }

class LandListing {
  final String id;
  final String sellerId;
  final String sellerName;
  final double landSize; // in square meters
  final double gfa; // Gross Floor Area
  final String location;
  final String area;
  final double askingPrice;
  final OwnershipType ownershipType;
  final List<PermissionType> permissions;
  final List<String> photoUrls;
  final List<String> desiredDevelopers;
  final ListingStatus status;
  final double? matchingScore;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? verifiedAt;
  final String? verifiedBy;
  
  // Additional properties for listing details
  final String title;
  final String description;
  final String city;
  final String state;
  final String zipCode;
  final List<String> developmentPermissions;
  final String zoning;

  const LandListing({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.landSize,
    required this.gfa,
    required this.location,
    required this.area,
    required this.askingPrice,
    required this.ownershipType,
    required this.permissions,
    required this.photoUrls,
    this.desiredDevelopers = const [],
    this.status = ListingStatus.pending_verification,
    this.matchingScore,
    required this.createdAt,
    required this.updatedAt,
    this.verifiedAt,
    this.verifiedBy,
    required this.title,
    required this.description,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.developmentPermissions,
    required this.zoning,
  });

  factory LandListing.fromJson(Map<String, dynamic> json) {
    return LandListing(
      id: json['id'] as String,
      sellerId: json['sellerId'] as String,
      sellerName: json['sellerName'] as String,
      landSize: (json['landSize'] as num).toDouble(),
      gfa: (json['gfa'] as num).toDouble(),
      location: json['location'] as String,
      area: json['area'] as String,
      askingPrice: (json['askingPrice'] as num).toDouble(),
      ownershipType: OwnershipType.values.firstWhere(
        (e) => e.toString().split('.').last == json['ownershipType'],
        orElse: () => OwnershipType.freehold,
      ),
      permissions: (json['permissions'] as List<dynamic>)
          .map((e) => PermissionType.values.firstWhere(
                (p) => p.toString().split('.').last == e,
                orElse: () => PermissionType.residential,
              ))
          .toList(),
      photoUrls: (json['photoUrls'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      desiredDevelopers: (json['desiredDevelopers'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      status: ListingStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => ListingStatus.pending_verification,
      ),
      matchingScore: json['matchingScore'] != null
          ? (json['matchingScore'] as num).toDouble()
          : null,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
      verifiedAt: json['verifiedAt'] != null
          ? (json['verifiedAt'] as Timestamp).toDate()
          : null,
      verifiedBy: json['verifiedBy'] as String?,
      title: json['title'] as String? ?? 'Land Listing',
      description: json['description'] as String? ?? 'Premium land plot available for development',
      city: json['city'] as String? ?? 'Dubai',
      state: json['state'] as String? ?? 'Dubai',
      zipCode: json['zipCode'] as String? ?? '00000',
      developmentPermissions: (json['developmentPermissions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? ['Residential', 'Commercial'],
      zoning: json['zoning'] as String? ?? 'Mixed Use',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'landSize': landSize,
      'gfa': gfa,
      'location': location,
      'area': area,
      'askingPrice': askingPrice,
      'ownershipType': ownershipType.toString().split('.').last,
      'permissions': permissions
          .map((e) => e.toString().split('.').last)
          .toList(),
      'photoUrls': photoUrls,
      'desiredDevelopers': desiredDevelopers,
      'status': status.toString().split('.').last,
      'matchingScore': matchingScore,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'verifiedAt': verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
      'verifiedBy': verifiedBy,
      'title': title,
      'description': description,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'developmentPermissions': developmentPermissions,
      'zoning': zoning,
    };
  }

  LandListing copyWith({
    String? id,
    String? sellerId,
    String? sellerName,
    double? landSize,
    double? gfa,
    String? location,
    String? area,
    double? askingPrice,
    OwnershipType? ownershipType,
    List<PermissionType>? permissions,
    List<String>? photoUrls,
    List<String>? desiredDevelopers,
    ListingStatus? status,
    double? matchingScore,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? verifiedAt,
    String? verifiedBy,
    String? title,
    String? description,
    String? city,
    String? state,
    String? zipCode,
    List<String>? developmentPermissions,
    String? zoning,
  }) {
    return LandListing(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      landSize: landSize ?? this.landSize,
      gfa: gfa ?? this.gfa,
      location: location ?? this.location,
      area: area ?? this.area,
      askingPrice: askingPrice ?? this.askingPrice,
      ownershipType: ownershipType ?? this.ownershipType,
      permissions: permissions ?? this.permissions,
      photoUrls: photoUrls ?? this.photoUrls,
      desiredDevelopers: desiredDevelopers ?? this.desiredDevelopers,
      status: status ?? this.status,
      matchingScore: matchingScore ?? this.matchingScore,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      title: title ?? this.title,
      description: description ?? this.description,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      developmentPermissions: developmentPermissions ?? this.developmentPermissions,
      zoning: zoning ?? this.zoning,
    );
  }

  // Business Logic Methods
  bool get isActive => status == ListingStatus.active;
  bool get isPendingVerification => status == ListingStatus.pending_verification;
  bool get isSold => status == ListingStatus.sold;
  bool get isExpired => status == ListingStatus.expired;

  double get pricePerSqm => askingPrice / landSize;
  double get gfaRatio => gfa / landSize;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LandListing && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'LandListing(id: $id, location: $location, price: $askingPrice, status: $status)';
  }
}
