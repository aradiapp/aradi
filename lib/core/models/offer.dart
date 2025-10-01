import 'package:cloud_firestore/cloud_firestore.dart';

enum OfferType { buy, jv, both }
enum OfferStatus { sent, countered, accepted, rejected }

class JVProposal {
  final String developerId;
  final String developerName;
  final double percentage;
  final String? notes;

  const JVProposal({
    required this.developerId,
    required this.developerName,
    required this.percentage,
    this.notes,
  });

  factory JVProposal.fromJson(Map<String, dynamic> json) {
    return JVProposal(
      developerId: json['developerId'] as String,
      developerName: json['developerName'] as String,
      percentage: (json['percentage'] as num).toDouble(),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'developerId': developerId,
      'developerName': developerName,
      'percentage': percentage,
      'notes': notes,
    };
  }

  JVProposal copyWith({
    String? developerId,
    String? developerName,
    double? percentage,
    String? notes,
  }) {
    return JVProposal(
      developerId: developerId ?? this.developerId,
      developerName: developerName ?? this.developerName,
      percentage: percentage ?? this.percentage,
      notes: notes ?? this.notes,
    );
  }

  // Validation: JV proposal must sum to 100%
  static bool validateSumIs100(List<JVProposal> proposals) {
    final total = proposals.fold<double>(
      0.0,
      (sum, proposal) => sum + proposal.percentage,
    );
    return (total - 100.0).abs() < 0.01; // Allow for floating point precision
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is JVProposal && other.developerId == developerId;
  }

  @override
  int get hashCode => developerId.hashCode;

  @override
  String toString() {
    return 'JVProposal(developer: $developerName, percentage: $percentage%)';
  }
}

class Offer {
  final String id;
  final String listingId;
  final String developerId;
  final String developerName;
  final OfferType type;
  final double? buyAmount; // Required for buy offers
  final List<JVProposal>? jvProposals; // Required for JV offers
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
    this.buyAmount,
    this.jvProposals,
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
      buyAmount: json['buyAmount'] != null
          ? (json['buyAmount'] as num).toDouble()
          : null,
      jvProposals: json['jvProposals'] != null
          ? (json['jvProposals'] as List<dynamic>)
              .map((e) => JVProposal.fromJson(e as Map<String, dynamic>))
              .toList()
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
      'buyAmount': buyAmount,
      'jvProposals': jvProposals?.map((e) => e.toJson()).toList(),
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
    double? buyAmount,
    List<JVProposal>? jvProposals,
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
      buyAmount: buyAmount ?? this.buyAmount,
      jvProposals: jvProposals ?? this.jvProposals,
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
        return buyAmount != null;
      case OfferType.jv:
        return jvProposals != null && 
               jvProposals!.isNotEmpty && 
               JVProposal.validateSumIs100(jvProposals!);
      case OfferType.both:
        return buyAmount != null && 
               jvProposals != null && 
               jvProposals!.isNotEmpty && 
               JVProposal.validateSumIs100(jvProposals!);
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
