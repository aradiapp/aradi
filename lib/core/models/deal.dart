import 'package:cloud_firestore/cloud_firestore.dart';

enum DealStatus { pending, completed, cancelled }
enum DealType { buy, jv }

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
  final double? offerAmount; // Original offer amount
  final double askingPrice; // Original asking price from listing
  final DealType type; // buy or jv
  final double? sellerPercentage; // For JV deals
  final double? developerPercentage; // For JV deals
  final DealStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? acceptedAt; // When the deal was accepted
  final DateTime? completedAt;
  final DateTime? cancelledAt; // When the deal was cancelled
  final String? completedBy; // Admin/Broker ID who marked it complete
  final String? notes;
  final String? rejectionReason; // Reason for cancellation
  final Map<String, String> contractDocuments; // Contract A, B, F URLs

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
    this.offerAmount,
    required this.askingPrice,
    required this.type,
    this.sellerPercentage,
    this.developerPercentage,
    this.status = DealStatus.pending,
    required this.createdAt,
    required this.updatedAt,
    this.acceptedAt,
    this.completedAt,
    this.cancelledAt,
    this.completedBy,
    this.notes,
    this.rejectionReason,
    this.contractDocuments = const {},
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
      offerAmount: json['offerAmount'] != null
          ? (json['offerAmount'] as num).toDouble()
          : null,
      askingPrice: (json['askingPrice'] as num).toDouble(),
      type: DealType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => DealType.buy,
      ),
      sellerPercentage: json['sellerPercentage'] != null
          ? (json['sellerPercentage'] as num).toDouble()
          : null,
      developerPercentage: json['developerPercentage'] != null
          ? (json['developerPercentage'] as num).toDouble()
          : null,
      status: DealStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => DealStatus.pending,
      ),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
      acceptedAt: json['acceptedAt'] != null
          ? (json['acceptedAt'] as Timestamp).toDate()
          : null,
      completedAt: json['completedAt'] != null
          ? (json['completedAt'] as Timestamp).toDate()
          : null,
      cancelledAt: json['cancelledAt'] != null
          ? (json['cancelledAt'] as Timestamp).toDate()
          : null,
      completedBy: json['completedBy'] as String?,
      notes: json['notes'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      contractDocuments: Map<String, String>.from(json['contractDocuments'] ?? {}),
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
      'offerAmount': offerAmount,
      'askingPrice': askingPrice,
      'type': type.toString().split('.').last,
      'sellerPercentage': sellerPercentage,
      'developerPercentage': developerPercentage,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'completedBy': completedBy,
      'notes': notes,
      'rejectionReason': rejectionReason,
      'contractDocuments': contractDocuments,
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
    double? offerAmount,
    double? askingPrice,
    DealType? type,
    double? sellerPercentage,
    double? developerPercentage,
    DealStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? acceptedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    String? completedBy,
    String? notes,
    String? rejectionReason,
    Map<String, String>? contractDocuments,
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
      offerAmount: offerAmount ?? this.offerAmount,
      askingPrice: askingPrice ?? this.askingPrice,
      type: type ?? this.type,
      sellerPercentage: sellerPercentage ?? this.sellerPercentage,
      developerPercentage: developerPercentage ?? this.developerPercentage,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      completedBy: completedBy ?? this.completedBy,
      notes: notes ?? this.notes,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      contractDocuments: contractDocuments ?? this.contractDocuments,
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

