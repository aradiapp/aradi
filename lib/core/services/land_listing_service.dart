import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aradi/core/models/land_listing.dart';
import 'package:aradi/core/models/developer_profile.dart';
import 'package:aradi/core/services/matching_service.dart';
import 'package:aradi/core/services/notification_service.dart';

class LandListingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all active land listings
  Future<List<LandListing>> getActiveListings() async {
    try {
      final querySnapshot = await _firestore
          .collection('land_listings')
          .where('isActive', isEqualTo: true)
          .get();

      print('Found ${querySnapshot.docs.length} active listings');
      
      final listings = querySnapshot.docs
          .map((doc) => LandListing.fromJson({
            ...doc.data(),
            'id': doc.id,
          }))
          .toList();

      // Filter out listings with accepted negotiations
      final availableListings = <LandListing>[];
      for (final listing in listings) {
        final hasAcceptedNegotiation = await _hasAcceptedNegotiation(listing.id);
        if (!hasAcceptedNegotiation) {
          availableListings.add(listing);
        }
      }

      print('Found ${availableListings.length} available listings (excluding accepted ones)');
      return availableListings;
    } catch (e) {
      print('Error fetching active listings: $e');
      return [];
    }
  }

  /// Check if a listing has any accepted negotiations
  Future<bool> _hasAcceptedNegotiation(String listingId) async {
    try {
      final querySnapshot = await _firestore
          .collection('negotiations')
          .where('listingId', isEqualTo: listingId)
          .where('status', isEqualTo: 'accepted')
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking accepted negotiations for listing $listingId: $e');
      return false;
    }
  }

  /// Get land listings for a specific seller
  Future<List<LandListing>> getListingsBySeller(String sellerId) async {
    try {
      final querySnapshot = await _firestore
          .collection('land_listings')
          .where('sellerId', isEqualTo: sellerId)
          .get();

      return querySnapshot.docs
          .map((doc) => LandListing.fromJson({
            ...doc.data(),
            'id': doc.id,
          }))
          .toList();
    } catch (e) {
      print('Error fetching seller listings: $e');
      return [];
    }
  }

  /// Get land listings sorted by matching score for a developer
  Future<List<LandListing>> getListingsForDeveloper(String developerId) async {
    try {
      // First get the developer profile
      final developerDoc = await _firestore
          .collection('developer_profiles')
          .doc(developerId)
          .get();

      if (!developerDoc.exists) {
        print('Developer profile not found: $developerId');
        return [];
      }

      final developer = DeveloperProfile.fromJson(developerDoc.data()!);

      // Get all active listings
      final listings = await getActiveListings();

      // Sort by matching score
      return MatchingService.sortByMatchingScore(listings, developer);
    } catch (e) {
      print('Error fetching listings for developer: $e');
      return [];
    }
  }

  /// Get a specific land listing by ID
  Future<LandListing?> getListingById(String listingId) async {
    try {
      final doc = await _firestore
          .collection('land_listings')
          .doc(listingId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return LandListing.fromJson({
        ...doc.data()!,
        'id': doc.id,
      });
    } catch (e) {
      print('Error fetching listing: $e');
      return null;
    }
  }

  /// Create a new land listing
  Future<String> createListing(LandListing listing) async {
    try {
      final docRef = await _firestore
          .collection('land_listings')
          .add(listing.toJson());

      return docRef.id;
    } catch (e) {
      print('Error creating listing: $e');
      throw Exception('Failed to create listing: $e');
    }
  }

  /// Update a land listing
  Future<void> updateListing(String listingId, LandListing listing) async {
    try {
      await _firestore
          .collection('land_listings')
          .doc(listingId)
          .update(listing.toJson());
    } catch (e) {
      print('Error updating listing: $e');
      throw Exception('Failed to update listing: $e');
    }
  }

  /// Delete a land listing
  Future<void> deleteListing(String listingId) async {
    try {
      await _firestore
          .collection('land_listings')
          .doc(listingId)
          .delete();
    } catch (e) {
      print('Error deleting listing: $e');
      throw Exception('Failed to delete listing: $e');
    }
  }

  /// Get pending listings for admin approval
  Future<List<LandListing>> getPendingListings() async {
    try {
      final querySnapshot = await _firestore
          .collection('land_listings')
          .where('isVerified', isEqualTo: false)
          .get();

      // Filter out rejected listings
      return querySnapshot.docs
          .map((doc) => LandListing.fromJson({
            ...doc.data(),
            'id': doc.id,
          }))
          .where((listing) => listing.status != ListingStatus.rejected)
          .toList();
    } catch (e) {
      print('Error fetching pending listings: $e');
      return [];
    }
  }

  /// Verify a listing (admin action)
  Future<void> verifyListing(String listingId, bool isVerified) async {
    try {
      // Get the listing first to get seller info
      final listing = await getListingById(listingId);
      if (listing == null) {
        throw Exception('Listing not found');
      }

      await _firestore
          .collection('land_listings')
          .doc(listingId)
          .update({
        'isVerified': isVerified,
        'isActive': isVerified, // Activate listing when verified
        'status': isVerified ? 'active' : 'rejected',
        'verifiedAt': FieldValue.serverTimestamp(),
      });

      // Send notifications if listing is approved
      if (isVerified) {
        try {
          final notificationService = NotificationService();
          
          // Send notification to seller
          await notificationService.notifyListingApproval(
            recipientId: listing.sellerId,
            listingTitle: '${listing.emirate}, ${listing.city}',
          );
          
          // Send notifications to preferred developers
          if (listing.preferredDeveloperIds.isNotEmpty) {
            print('=== SENDING PREFERRED DEVELOPER NOTIFICATIONS (ADMIN APPROVAL) ===');
            print('Preferred developers: ${listing.preferredDeveloperIds}');
            
            for (final developerId in listing.preferredDeveloperIds) {
              try {
                await notificationService.notifyPreferredDeveloper(
                  developerId: developerId,
                  listingTitle: '${listing.emirate}, ${listing.city}',
                  listingId: listing.id,
                  listingPrice: 'AED ${listing.askingPrice.toStringAsFixed(0)}',
                  area: listing.area,
                );
                print('Preferred developer notification sent to: $developerId');
              } catch (e) {
                print('Error sending notification to developer $developerId: $e');
              }
            }
          } else {
            print('No preferred developers to notify');
          }
        } catch (e) {
          print('Error sending approval notifications: $e');
        }
      }
    } catch (e) {
      print('Error verifying listing: $e');
      throw Exception('Failed to verify listing: $e');
    }
  }

  /// Reject a listing (admin action)
  Future<void> rejectListing(String listingId, {String? rejectionReason}) async {
    try {
      await _firestore
          .collection('land_listings')
          .doc(listingId)
          .update({
        'isVerified': false,
        'isActive': false,
        'status': 'rejected',
        'rejectionReason': rejectionReason,
        'rejectedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error rejecting listing: $e');
      throw Exception('Failed to reject listing: $e');
    }
  }

  /// Search listings by area or permissions
  Future<List<LandListing>> searchListings(String query) async {
    try {
      final listings = await getActiveListings();
      
      return listings.where((listing) {
        final areaMatch = listing.area.toLowerCase().contains(query.toLowerCase());
        final permissionMatch = listing.developmentPermissions.any(
          (permission) => permission.toLowerCase().contains(query.toLowerCase())
        );
        return areaMatch || permissionMatch;
      }).toList();
    } catch (e) {
      print('Error searching listings: $e');
      return [];
    }
  }

  /// Get listings by area
  Future<List<LandListing>> getListingsByArea(String area) async {
    try {
      final querySnapshot = await _firestore
          .collection('land_listings')
          .where('isActive', isEqualTo: true)
          .where('area', isEqualTo: area)
          .get();

      return querySnapshot.docs
          .map((doc) => LandListing.fromJson({
            ...doc.data(),
            'id': doc.id,
          }))
          .toList();
    } catch (e) {
      print('Error fetching listings by area: $e');
      return [];
    }
  }

  /// Get listings by permission type
  Future<List<LandListing>> getListingsByPermission(String permission) async {
    try {
      final querySnapshot = await _firestore
          .collection('land_listings')
          .where('isActive', isEqualTo: true)
          .where('developmentPermissions', arrayContains: permission)
          .get();

      return querySnapshot.docs
          .map((doc) => LandListing.fromJson({
            ...doc.data(),
            'id': doc.id,
          }))
          .toList();
    } catch (e) {
      print('Error fetching listings by permission: $e');
      return [];
    }
  }

  /// Mark a listing as sold when a negotiation is accepted
  Future<void> markListingAsSold(String listingId) async {
    try {
      await _firestore
          .collection('land_listings')
          .doc(listingId)
          .update({
        'isActive': false,
        'status': 'sold',
        'soldAt': FieldValue.serverTimestamp(),
      });
      print('Listing $listingId marked as sold');
    } catch (e) {
      print('Error marking listing as sold: $e');
      throw Exception('Failed to mark listing as sold: $e');
    }
  }

  /// Reactivate a listing when a deal is cancelled
  Future<void> reactivateListing(String listingId) async {
    try {
      await _firestore
          .collection('land_listings')
          .doc(listingId)
          .update({
        'isActive': true,
        'status': 'active',
        'soldAt': FieldValue.delete(), // Remove soldAt field
      });
      print('Listing $listingId reactivated');
    } catch (e) {
      print('Error reactivating listing: $e');
      throw Exception('Failed to reactivate listing: $e');
    }
  }
}
