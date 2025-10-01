import 'package:aradi/core/models/user.dart';
import 'package:aradi/core/models/developer_profile.dart';
import 'package:aradi/core/models/buyer_profile.dart';
import 'package:aradi/core/models/seller_profile.dart';
import 'package:aradi/core/models/land_listing.dart';
import 'package:aradi/core/models/offer.dart';
import 'package:aradi/core/models/negotiation.dart';

abstract class BaseRepository<T> {
  /// Get a single item by ID
  Future<T?> getById(String id);
  
  /// Get all items
  Future<List<T>> getAll();
  
  /// Create a new item
  Future<T> create(T item);
  
  /// Update an existing item
  Future<T> update(T item);
  
  /// Delete an item by ID
  Future<bool> delete(String id);
  
  /// Check if an item exists
  Future<bool> exists(String id);
  
  /// Get items with pagination
  Future<List<T>> getPaginated({
    int page = 1,
    int limit = 20,
    String? orderBy,
    bool descending = true,
  });
  
  /// Search items
  Future<List<T>> search(String query);
  
  /// Get items by field value
  Future<List<T>> getByField(String field, dynamic value);
  
  /// Get items by multiple field values
  Future<List<T>> getByFields(Map<String, dynamic> fields);
}

// User Repository Interface
abstract class UserRepository {
  Future<User?> getCurrentUser();
  Future<User?> getUserById(String userId);
  Future<User> createUser(User user);
  Future<User> updateUser(User user);
  Future<void> deleteUser(String userId);
  
  // Profile methods
  Future<DeveloperProfile?> getDeveloperProfile(String userId);
  Future<DeveloperProfile> createDeveloperProfile(DeveloperProfile profile);
  Future<DeveloperProfile> updateDeveloperProfile(DeveloperProfile profile);
  
  Future<BuyerProfile?> getBuyerProfile(String userId);
  Future<BuyerProfile> createBuyerProfile(BuyerProfile profile);
  Future<BuyerProfile> updateBuyerProfile(BuyerProfile profile);
  
  Future<SellerProfile?> getSellerProfile(String userId);
  Future<SellerProfile> createSellerProfile(SellerProfile profile);
  Future<SellerProfile> updateSellerProfile(SellerProfile profile);
  
  Future<List<DeveloperProfile>> getAllDevelopers();
  Future<List<SellerProfile>> getAllSellers();
}

// Listing Repository Interface
abstract class ListingRepository {
  Future<List<LandListing>> getAllListings();
  Future<List<LandListing>> getListingsBySeller(String sellerId);
  Future<LandListing?> getListingById(String listingId);
  Future<LandListing> createListing(LandListing listing);
  Future<LandListing> updateListing(LandListing listing);
  Future<void> deleteListing(String listingId);
  
  Future<List<LandListing>> searchListings({
    String? location,
    String? area,
    double? minPrice,
    double? maxPrice,
    List<PermissionType>? permissions,
    OwnershipType? ownershipType,
  });
  
  Future<List<Offer>> getOffersForListing(String listingId);
  Future<List<Offer>> getOffersByDeveloper(String developerId);
  Future<Offer> createOffer(Offer offer);
  Future<Offer> updateOffer(Offer offer);
  Future<void> deleteOffer(String offerId);
  
  Future<void> updateListingStatus(String listingId, ListingStatus status);
  Future<void> verifyListing(String listingId, String verifiedBy);
}

// Negotiation Repository Interface
abstract class NegotiationRepository {
  Future<List<Negotiation>> getNegotiationsForUser(String userId);
  Future<Negotiation?> getNegotiationById(String negotiationId);
  Future<Negotiation> createNegotiation(Negotiation negotiation);
  Future<Negotiation> updateNegotiation(Negotiation negotiation);
  
  Future<List<NegotiationMessage>> getMessagesForNegotiation(String negotiationId);
  Future<NegotiationMessage> sendMessage(NegotiationMessage message);
  Future<void> markMessagesAsRead(String negotiationId, String userId);
  Future<int> getUnreadMessageCount(String userId);
  
  Future<Negotiation?> findNegotiationByListingAndDeveloper(String listingId, String developerId);
  Future<void> updateNegotiationStatus(String negotiationId, OfferStatus status);
}
