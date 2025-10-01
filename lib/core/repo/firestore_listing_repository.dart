import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aradi/core/models/land_listing.dart';
import 'package:aradi/core/models/offer.dart';
import 'package:aradi/core/repo/base_repository.dart';

class FirestoreListingRepository implements ListingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<LandListing>> getAllListings() async {
    try {
      final snapshot = await _firestore
          .collection('listings')
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return LandListing.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error getting all listings: $e');
      return [];
    }
  }

  @override
  Future<List<LandListing>> getListingsBySeller(String sellerId) async {
    try {
      final snapshot = await _firestore
          .collection('listings')
          .where('sellerId', isEqualTo: sellerId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return LandListing.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error getting listings by seller: $e');
      return [];
    }
  }

  @override
  Future<LandListing?> getListingById(String listingId) async {
    try {
      final doc = await _firestore.collection('listings').doc(listingId).get();
      if (!doc.exists) return null;
      
      final data = doc.data()!;
      data['id'] = doc.id;
      return LandListing.fromJson(data);
    } catch (e) {
      print('Error getting listing by ID: $e');
      return null;
    }
  }

  @override
  Future<LandListing> createListing(LandListing listing) async {
    try {
      final docRef = await _firestore.collection('listings').add(listing.toJson());
      return listing.copyWith(id: docRef.id);
    } catch (e) {
      print('Error creating listing: $e');
      rethrow;
    }
  }

  @override
  Future<LandListing> updateListing(LandListing listing) async {
    try {
      await _firestore.collection('listings').doc(listing.id).update(listing.toJson());
      return listing;
    } catch (e) {
      print('Error updating listing: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteListing(String listingId) async {
    try {
      await _firestore.collection('listings').doc(listingId).delete();
    } catch (e) {
      print('Error deleting listing: $e');
      rethrow;
    }
  }

  @override
  Future<List<LandListing>> searchListings({
    String? location,
    String? area,
    double? minPrice,
    double? maxPrice,
    List<PermissionType>? permissions,
    OwnershipType? ownershipType,
  }) async {
    try {
      Query query = _firestore.collection('listings').where('status', isEqualTo: 'active');

      if (location != null && location.isNotEmpty) {
        query = query.where('location', isEqualTo: location);
      }

      if (area != null && area.isNotEmpty) {
        query = query.where('area', isEqualTo: area);
      }

      if (minPrice != null) {
        query = query.where('askingPrice', isGreaterThanOrEqualTo: minPrice);
      }

      if (maxPrice != null) {
        query = query.where('askingPrice', isLessThanOrEqualTo: maxPrice);
      }

      if (ownershipType != null) {
        query = query.where('ownershipType', isEqualTo: ownershipType.toString().split('.').last);
      }

      final snapshot = await query.orderBy('createdAt', descending: true).get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return LandListing.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error searching listings: $e');
      return [];
    }
  }

  @override
  Future<List<Offer>> getOffersForListing(String listingId) async {
    try {
      final snapshot = await _firestore
          .collection('offers')
          .where('listingId', isEqualTo: listingId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Offer.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error getting offers for listing: $e');
      return [];
    }
  }

  @override
  Future<List<Offer>> getOffersByDeveloper(String developerId) async {
    try {
      final snapshot = await _firestore
          .collection('offers')
          .where('developerId', isEqualTo: developerId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Offer.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error getting offers by developer: $e');
      return [];
    }
  }

  @override
  Future<Offer> createOffer(Offer offer) async {
    try {
      final docRef = await _firestore.collection('offers').add(offer.toJson());
      return offer.copyWith(id: docRef.id);
    } catch (e) {
      print('Error creating offer: $e');
      rethrow;
    }
  }

  @override
  Future<Offer> updateOffer(Offer offer) async {
    try {
      await _firestore.collection('offers').doc(offer.id).update(offer.toJson());
      return offer;
    } catch (e) {
      print('Error updating offer: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteOffer(String offerId) async {
    try {
      await _firestore.collection('offers').doc(offerId).delete();
    } catch (e) {
      print('Error deleting offer: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateListingStatus(String listingId, ListingStatus status) async {
    try {
      await _firestore.collection('listings').doc(listingId).update({
        'status': status.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating listing status: $e');
      rethrow;
    }
  }

  @override
  Future<void> verifyListing(String listingId, String verifiedBy) async {
    try {
      await _firestore.collection('listings').doc(listingId).update({
        'status': 'active',
        'verifiedAt': FieldValue.serverTimestamp(),
        'verifiedBy': verifiedBy,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error verifying listing: $e');
      rethrow;
    }
  }
}
