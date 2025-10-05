import 'package:cloud_firestore/cloud_firestore.dart';

enum OwnershipType { freehold, leasehold, gcc }
enum PermissionType { residential, commercial, hotel, mix }
enum ListingStatus { pending_verification, active, sold, expired, rejected }
enum ListingType { buy, jv, both }

class LandListing {
  final String id;
  final String sellerId;
  final String sellerName;
  final double landSize; // in square meters
  final double gfa; // Gross Floor Area
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
  final String description;
  final String emirate;
  final String city;
  final List<String> developmentPermissions;
  final ListingType listingType;
  final bool isActive;
  final bool isVerified;
  final List<String> photos;
  
  // New fields for title deed and building specs
  final String? titleDeedDocumentUrl;
  final String? dcrDocumentUrl;
  final String? buildingSpecs;
  final String? gFloorSpecs;
  final String? technicalSpecs;
  final List<String> preferredDeveloperIds;

  const LandListing({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.landSize,
    required this.gfa,
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
    required this.description,
    required this.emirate,
    required this.city,
    required this.developmentPermissions,
    this.listingType = ListingType.both,
    this.isActive = true,
    this.isVerified = false,
    this.photos = const [],
    this.titleDeedDocumentUrl,
    this.dcrDocumentUrl,
    this.buildingSpecs,
    this.gFloorSpecs,
    this.technicalSpecs,
    this.preferredDeveloperIds = const [],
  });

  factory LandListing.fromJson(Map<String, dynamic> json) {
    return LandListing(
      id: json['id'] as String,
      sellerId: json['sellerId'] as String,
      sellerName: json['sellerName'] as String,
      landSize: (json['landSize'] as num).toDouble(),
      gfa: (json['gfa'] as num).toDouble(),
      area: json['area'] as String,
      askingPrice: (json['askingPrice'] as num).toDouble(),
      ownershipType: OwnershipType.values.firstWhere(
        (e) => e.toString().split('.').last == json['ownershipType'],
        orElse: () => OwnershipType.freehold,
      ),
      permissions: (json['permissions'] as List<dynamic>?)
          ?.map((e) {
            final stringValue = e.toString().toLowerCase();
            print('Converting permission: "$e" -> "$stringValue"');
            final result = PermissionType.values.firstWhere(
              (p) => p.toString().split('.').last.toLowerCase() == stringValue,
              orElse: () => PermissionType.residential,
            );
            print('Converted to: $result');
            return result;
          })
          .toList() ?? [],
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
      description: json['description'] as String? ?? 'Premium land plot available for development',
      emirate: json['emirate'] as String? ?? 'Dubai',
      city: json['city'] as String? ?? 'Dubai',
      developmentPermissions: (json['developmentPermissions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? ['Residential', 'Commercial'],
      listingType: ListingType.values.firstWhere(
        (e) => e.toString().split('.').last == json['listingType'],
        orElse: () => ListingType.both,
      ),
      isActive: json['isActive'] as bool? ?? true,
      isVerified: json['isVerified'] as bool? ?? false,
      photos: (json['photos'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      titleDeedDocumentUrl: json['titleDeedDocumentUrl'] as String?,
      dcrDocumentUrl: json['dcrDocumentUrl'] as String?,
      buildingSpecs: json['buildingSpecs'] as String?,
      gFloorSpecs: json['gFloorSpecs'] as String?,
      technicalSpecs: json['technicalSpecs'] as String?,
      preferredDeveloperIds: (json['preferredDeveloperIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'landSize': landSize,
      'gfa': gfa,
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
      'description': description,
      'emirate': emirate,
      'city': city,
      'developmentPermissions': developmentPermissions,
      'listingType': listingType.toString().split('.').last,
      'isActive': isActive,
      'isVerified': isVerified,
      'photos': photos,
      'titleDeedDocumentUrl': titleDeedDocumentUrl,
      'dcrDocumentUrl': dcrDocumentUrl,
      'buildingSpecs': buildingSpecs,
      'gFloorSpecs': gFloorSpecs,
      'technicalSpecs': technicalSpecs,
      'preferredDeveloperIds': preferredDeveloperIds,
    };
  }

  LandListing copyWith({
    String? id,
    String? sellerId,
    String? sellerName,
    double? landSize,
    double? gfa,
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
    String? description,
    String? emirate,
    String? city,
    List<String>? developmentPermissions,
    ListingType? listingType,
    bool? isActive,
    bool? isVerified,
    List<String>? photos,
    String? titleDeedDocumentUrl,
    String? dcrDocumentUrl,
    String? buildingSpecs,
    String? gFloorSpecs,
    String? technicalSpecs,
    List<String>? preferredDeveloperIds,
  }) {
    return LandListing(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      landSize: landSize ?? this.landSize,
      gfa: gfa ?? this.gfa,
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
      description: description ?? this.description,
      emirate: emirate ?? this.emirate,
      city: city ?? this.city,
      developmentPermissions: developmentPermissions ?? this.developmentPermissions,
      listingType: listingType ?? this.listingType,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      photos: photos ?? this.photos,
      titleDeedDocumentUrl: titleDeedDocumentUrl ?? this.titleDeedDocumentUrl,
      dcrDocumentUrl: dcrDocumentUrl ?? this.dcrDocumentUrl,
      buildingSpecs: buildingSpecs ?? this.buildingSpecs,
      gFloorSpecs: gFloorSpecs ?? this.gFloorSpecs,
      technicalSpecs: technicalSpecs ?? this.technicalSpecs,
      preferredDeveloperIds: preferredDeveloperIds ?? this.preferredDeveloperIds,
    );
  }

  // Business Logic Methods
  bool get isActiveStatus => status == ListingStatus.active;
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
    return 'LandListing(id: $id, location: $emirate, $city, price: $askingPrice, status: $status)';
  }
}
