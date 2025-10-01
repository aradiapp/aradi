import 'package:cloud_firestore/cloud_firestore.dart';

enum DealStatus { pending, completed, cancelled }

class Deal {
  final String id;
  final String listingId;
  final String listingTitle;
  final String sellerId;
  final String sellerName;
  final String buyerId;
  final String buyerName;
  final String? developerId;
  final String? developerName;
  final double finalPrice;
  final DealStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final String? completedBy; // Admin/Broker ID who marked it complete
  final String? notes;

  const Deal({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    required this.sellerId,
    required this.sellerName,
    required this.buyerId,
    required this.buyerName,
    this.developerId,
    this.developerName,
    required this.finalPrice,
    this.status = DealStatus.pending,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.completedBy,
    this.notes,
  });

  factory Deal.fromJson(Map<String, dynamic> json) {
    return Deal(
      id: json['id'] as String,
      listingId: json['listingId'] as String,
      listingTitle: json['listingTitle'] as String,
      sellerId: json['sellerId'] as String,
      sellerName: json['sellerName'] as String,
      buyerId: json['buyerId'] as String,
      buyerName: json['buyerName'] as String,
      developerId: json['developerId'] as String?,
      developerName: json['developerName'] as String?,
      finalPrice: (json['finalPrice'] as num).toDouble(),
      status: DealStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => DealStatus.pending,
      ),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
      completedAt: json['completedAt'] != null
          ? (json['completedAt'] as Timestamp).toDate()
          : null,
      completedBy: json['completedBy'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'listingId': listingId,
      'listingTitle': listingTitle,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'developerId': developerId,
      'developerName': developerName,
      'finalPrice': finalPrice,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'completedBy': completedBy,
      'notes': notes,
    };
  }

  Deal copyWith({
    String? id,
    String? listingId,
    String? listingTitle,
    String? sellerId,
    String? sellerName,
    String? buyerId,
    String? buyerName,
    String? developerId,
    String? developerName,
    double? finalPrice,
    DealStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    String? completedBy,
    String? notes,
  }) {
    return Deal(
      id: id ?? this.id,
      listingId: listingId ?? this.listingId,
      listingTitle: listingTitle ?? this.listingTitle,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      buyerId: buyerId ?? this.buyerId,
      buyerName: buyerName ?? this.buyerName,
      developerId: developerId ?? this.developerId,
      developerName: developerName ?? this.developerName,
      finalPrice: finalPrice ?? this.finalPrice,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      completedBy: completedBy ?? this.completedBy,
      notes: notes ?? this.notes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Deal && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Deal(id: $id, listing: $listingTitle, status: $status)';
  }
}

