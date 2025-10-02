import 'package:cloud_firestore/cloud_firestore.dart';

enum OfferType { buy, jv, both }
enum OfferStatus { sent, pending, countered, accepted, rejected }

class JVProposal {
  final double sellerPercentage;
  final double developerPercentage;
  final double investmentAmount;
  final String? notes;

  const JVProposal({
    required this.sellerPercentage,
    required this.developerPercentage,
    required this.investmentAmount,
    this.notes,
  });

  factory JVProposal.fromJson(Map<String, dynamic> json) {
    return JVProposal(
      sellerPercentage: (json['sellerPercentage'] as num).toDouble(),
      developerPercentage: (json['developerPercentage'] as num).toDouble(),
      investmentAmount: (json['investmentAmount'] as num).toDouble(),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sellerPercentage': sellerPercentage,
      'developerPercentage': developerPercentage,
      'investmentAmount': investmentAmount,
      'notes': notes,
    };
  }

  JVProposal copyWith({
    double? sellerPercentage,
    double? developerPercentage,
    double? investmentAmount,
    String? notes,
  }) {
    return JVProposal(
      sellerPercentage: sellerPercentage ?? this.sellerPercentage,
      developerPercentage: developerPercentage ?? this.developerPercentage,
      investmentAmount: investmentAmount ?? this.investmentAmount,
      notes: notes ?? this.notes,
    );
  }

  // Validation: JV proposal must sum to 100%
  static bool validateSumIs100(List<JVProposal> proposals) {
    final total = proposals.fold<double>(
      0.0,
      (sum, proposal) => sum + proposal.sellerPercentage + proposal.developerPercentage,
    );
    return (total - 100.0).abs() < 0.01; // Allow for floating point precision
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is JVProposal && 
           other.sellerPercentage == sellerPercentage &&
           other.developerPercentage == developerPercentage;
  }

  @override
  int get hashCode => sellerPercentage.hashCode ^ developerPercentage.hashCode;

  @override
  String toString() {
    return 'JVProposal(seller: ${sellerPercentage}%, developer: ${developerPercentage}%)';
  }
}

class Offer {
  final String id;
  final String listingId;
  final String developerId;
  final String developerName;
  final OfferType type;
  final double? buyPrice; // Required for buy offers
  final JVProposal? jvProposal; // Required for JV offers
  final OfferStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? respondedAt;
  final String? responseNotes;

  const Offer({
    required this.id,
    required this.listingId,
    required this.developerId,
    required this.developerName,
    required this.type,
    this.buyPrice,
    this.jvProposal,
    this.status = OfferStatus.sent,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.respondedAt,
    this.responseNotes,
  });

  factory Offer.fromJson(Map<String, dynamic> json) {
    return Offer(
      id: json['id'] as String,
      listingId: json['listingId'] as String,
      developerId: json['developerId'] as String,
      developerName: json['developerName'] as String,
      type: OfferType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => OfferType.buy,
      ),
      buyPrice: json['buyPrice'] != null
          ? (json['buyPrice'] as num).toDouble()
          : null,
      jvProposal: json['jvProposal'] != null
          ? JVProposal.fromJson(json['jvProposal'] as Map<String, dynamic>)
          : null,
      status: OfferStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => OfferStatus.sent,
      ),
      notes: json['notes'] as String?,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
      respondedAt: json['respondedAt'] != null
          ? (json['respondedAt'] as Timestamp).toDate()
          : null,
      responseNotes: json['responseNotes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'listingId': listingId,
      'developerId': developerId,
      'developerName': developerName,
      'type': type.toString().split('.').last,
      'buyPrice': buyPrice,
      'jvProposal': jvProposal?.toJson(),
      'status': status.toString().split('.').last,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
      'responseNotes': responseNotes,
    };
  }

  Offer copyWith({
    String? id,
    String? listingId,
    String? developerId,
    String? developerName,
    OfferType? type,
    double? buyPrice,
    JVProposal? jvProposal,
    OfferStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? respondedAt,
    String? responseNotes,
  }) {
    return Offer(
      id: id ?? this.id,
      listingId: listingId ?? this.listingId,
      developerId: developerId ?? this.developerId,
      developerName: developerName ?? this.developerName,
      type: type ?? this.type,
      buyPrice: buyPrice ?? this.buyPrice,
      jvProposal: jvProposal ?? this.jvProposal,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      respondedAt: respondedAt ?? this.respondedAt,
      responseNotes: responseNotes ?? this.responseNotes,
    );
  }

  // Validation Methods
  static bool validateBuyBounds(double offerAmount, double askingPrice) {
    final minPrice = askingPrice * 0.8; // -20%
    final maxPrice = askingPrice * 1.2; // +20%
    return offerAmount >= minPrice && offerAmount <= maxPrice;
  }

  bool get isValid {
    switch (type) {
      case OfferType.buy:
        return buyPrice != null;
      case OfferType.jv:
        return jvProposal != null;
      case OfferType.both:
        return buyPrice != null && jvProposal != null;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Offer && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Offer(id: $id, type: $type, status: $status, developer: $developerName)';
  }
}
