import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aradi/core/models/offer.dart';
import 'package:aradi/core/models/land_listing.dart';

class OfferService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new offer
  Future<String> createOffer(Offer offer) async {
    try {
      // Validate offer before creating
      await _validateOffer(offer);

      final docRef = await _firestore
          .collection('offers')
          .add(offer.toJson());

      return docRef.id;
    } catch (e) {
      print('Error creating offer: $e');
      throw Exception('Failed to create offer: $e');
    }
  }

  /// Get offers for a specific listing
  Future<List<Offer>> getOffersForListing(String listingId) async {
    try {
      final querySnapshot = await _firestore
          .collection('offers')
          .where('listingId', isEqualTo: listingId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Offer.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching offers for listing: $e');
      return [];
    }
  }

  /// Get offers by a specific developer
  Future<List<Offer>> getOffersByDeveloper(String developerId) async {
    try {
      final querySnapshot = await _firestore
          .collection('offers')
          .where('developerId', isEqualTo: developerId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Offer.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching offers by developer: $e');
      return [];
    }
  }

  /// Get offers for a specific seller
  Future<List<Offer>> getOffersForSeller(String sellerId) async {
    try {
      // First get all listings by this seller
      final listingsQuery = await _firestore
          .collection('land_listings')
          .where('sellerId', isEqualTo: sellerId)
          .get();

      if (listingsQuery.docs.isEmpty) {
        return [];
      }

      final listingIds = listingsQuery.docs.map((doc) => doc.id).toList();

      // Get all offers for these listings
      final offersQuery = await _firestore
          .collection('offers')
          .where('listingId', whereIn: listingIds)
          .get();

      return offersQuery.docs
          .map((doc) => Offer.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching offers for seller: $e');
      return [];
    }
  }

  /// Update offer status
  Future<void> updateOfferStatus(String offerId, OfferStatus status) async {
    try {
      await _firestore
          .collection('offers')
          .doc(offerId)
          .update({
        'status': status.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating offer status: $e');
      throw Exception('Failed to update offer status: $e');
    }
  }

  /// Accept an offer
  Future<void> acceptOffer(String offerId) async {
    try {
      await _firestore
          .collection('offers')
          .doc(offerId)
          .update({
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error accepting offer: $e');
      throw Exception('Failed to accept offer: $e');
    }
  }

  /// Reject an offer
  Future<void> rejectOffer(String offerId) async {
    try {
      await _firestore
          .collection('offers')
          .doc(offerId)
          .update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error rejecting offer: $e');
      throw Exception('Failed to reject offer: $e');
    }
  }

  /// Get a specific offer by ID
  Future<Offer?> getOfferById(String offerId) async {
    try {
      final doc = await _firestore
          .collection('offers')
          .doc(offerId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return Offer.fromJson(doc.data()!);
    } catch (e) {
      print('Error fetching offer: $e');
      return null;
    }
  }

  /// Delete an offer
  Future<void> deleteOffer(String offerId) async {
    try {
      await _firestore
          .collection('offers')
          .doc(offerId)
          .delete();
    } catch (e) {
      print('Error deleting offer: $e');
      throw Exception('Failed to delete offer: $e');
    }
  }

  /// Get pending offers for admin review
  Future<List<Offer>> getPendingOffers() async {
    try {
      final querySnapshot = await _firestore
          .collection('offers')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Offer.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching pending offers: $e');
      return [];
    }
  }

  /// Validate offer before creation
  Future<void> _validateOffer(Offer offer) async {
    // Get the listing to validate against
    final listingDoc = await _firestore
        .collection('land_listings')
        .doc(offer.listingId)
        .get();

    if (!listingDoc.exists) {
      throw Exception('Listing not found');
    }

    final listing = LandListing.fromJson(listingDoc.data()!);

    // Validate buy offer
    if (offer.type == OfferType.buy) {
      final askingPrice = listing.askingPrice;
      final offerPrice = offer.buyPrice!;
      
      // Check if offer is within ±20% of asking price
      final minPrice = askingPrice * 0.8;
      final maxPrice = askingPrice * 1.2;
      
      if (offerPrice < minPrice || offerPrice > maxPrice) {
        throw Exception('Buy offer must be within ±20% of asking price (${askingPrice.toStringAsFixed(0)} AED)');
      }
    }

    // Validate JV proposal
    if (offer.type == OfferType.jv) {
      final jvProposal = offer.jvProposal!;
      
      // Check if partnership percentages sum to 100%
      final totalPercentage = jvProposal.sellerPercentage + jvProposal.developerPercentage;
      if (totalPercentage != 100.0) {
        throw Exception('Partnership percentages must sum to 100%');
      }
    }

    // Check if listing is active
    if (!listing.isActive) {
      throw Exception('Cannot make offers on inactive listings');
    }

    // Check if listing is verified
    if (!listing.isVerified) {
      throw Exception('Cannot make offers on unverified listings');
    }
  }

  /// Get offer statistics for a developer
  Future<Map<String, int>> getOfferStatsForDeveloper(String developerId) async {
    try {
      final offers = await getOffersByDeveloper(developerId);
      
      final stats = <String, int>{
        'total': offers.length,
        'pending': offers.where((o) => o.status == OfferStatus.pending).length,
        'accepted': offers.where((o) => o.status == OfferStatus.accepted).length,
        'rejected': offers.where((o) => o.status == OfferStatus.rejected).length,
      };

      return stats;
    } catch (e) {
      print('Error fetching offer stats: $e');
      return {'total': 0, 'pending': 0, 'accepted': 0, 'rejected': 0};
    }
  }

  /// Get offer statistics for a seller
  Future<Map<String, int>> getOfferStatsForSeller(String sellerId) async {
    try {
      final offers = await getOffersForSeller(sellerId);
      
      final stats = <String, int>{
        'total': offers.length,
        'pending': offers.where((o) => o.status == OfferStatus.pending).length,
        'accepted': offers.where((o) => o.status == OfferStatus.accepted).length,
        'rejected': offers.where((o) => o.status == OfferStatus.rejected).length,
      };

      return stats;
    } catch (e) {
      print('Error fetching offer stats: $e');
      return {'total': 0, 'pending': 0, 'accepted': 0, 'rejected': 0};
    }
  }
}
