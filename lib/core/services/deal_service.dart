import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aradi/core/models/deal.dart';
import 'package:aradi/core/models/negotiation.dart';
import 'package:aradi/core/models/land_listing.dart';
import 'package:aradi/core/models/offer.dart';
import 'package:aradi/core/services/land_listing_service.dart';
import 'package:aradi/core/services/negotiation_service.dart';
import 'package:aradi/core/services/auth_service.dart';

class DealService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LandListingService _landListingService = LandListingService();
  final NegotiationService _negotiationService = NegotiationService();
  final AuthService _authService = AuthService();

  /// Create a deal from an accepted negotiation
  Future<Deal> createDealFromNegotiation(Negotiation negotiation) async {
    try {
      // Get the listing details
      final listing = await _landListingService.getListingById(negotiation.listingId);
      if (listing == null) {
        throw Exception('Listing not found');
      }

      // Get actual seller name from seller profile (not the masked "Property Owner" from negotiation)
      final sellerProfile = await _authService.getSellerProfile(negotiation.sellerId);
      final actualSellerName = sellerProfile?.name ?? 'Unknown Seller';

      // Determine deal type and extract relevant data
      final isJV = negotiation.messages.any((message) => 
        message.content.contains('JV Proposal:') || 
        message.content.contains('% Landowner') ||
        message.content.contains('% Developer'));

      final dealType = isJV ? DealType.jv : DealType.buy;
      
      // Extract offer amount from negotiation messages
      double? offerAmount;
      double? finalAgreedPrice;
      double? sellerPercentage;
      double? developerPercentage;
      
      if (negotiation.messages.isEmpty) {
        throw Exception('No messages found in negotiation');
      }
      
      print('Negotiation ${negotiation.id} has ${negotiation.messages.length} messages:');
      for (int i = 0; i < negotiation.messages.length; i++) {
        print('  Message $i: ${negotiation.messages[i].content}');
      }
      
      // Find the initial offer message
      final offerMessage = negotiation.messages.firstWhere(
        (msg) => msg.content.contains('Made an offer of AED') || msg.content.contains('JV Proposal:'),
        orElse: () => negotiation.messages.first,
      );

      if (isJV) {
        // For JV deals, look for the final agreed percentages in all messages
        double? finalSellerPercentage;
        double? finalDeveloperPercentage;
        
        // Check all messages for JV percentages (in reverse order to get the latest)
        for (final message in negotiation.messages.reversed) {
          // First check for JV Counter (most recent negotiation)
          final jvCounterRegex = RegExp(r'JV Counter:\s*(\d+)%\s*Landowner.*?(\d+)%\s*Developer');
          final jvCounterMatch = jvCounterRegex.firstMatch(message.content);
          if (jvCounterMatch != null) {
            finalSellerPercentage = double.parse(jvCounterMatch.group(1)!);
            finalDeveloperPercentage = double.parse(jvCounterMatch.group(2)!);
            break; // Found the most recent JV counter percentages
          }
          
          // If no JV Counter found, check for JV Proposal
          final jvProposalRegex = RegExp(r'JV Proposal:\s*(\d+)%\s*Landowner.*?(\d+)%\s*Developer');
          final jvProposalMatch = jvProposalRegex.firstMatch(message.content);
          if (jvProposalMatch != null) {
            finalSellerPercentage = double.parse(jvProposalMatch.group(1)!);
            finalDeveloperPercentage = double.parse(jvProposalMatch.group(2)!);
            break; // Found JV proposal percentages
          }
        }
        
        // Fallback to initial offer if no percentages found
        if (finalSellerPercentage == null || finalDeveloperPercentage == null) {
          final jvRegex = RegExp(r'JV Proposal:\s*(\d+)%\s*Landowner.*?(\d+)%\s*Developer');
          final jvMatch = jvRegex.firstMatch(offerMessage.content);
          if (jvMatch != null) {
            finalSellerPercentage = double.parse(jvMatch.group(1)!);
            finalDeveloperPercentage = double.parse(jvMatch.group(2)!);
          }
        }
        
        sellerPercentage = finalSellerPercentage;
        developerPercentage = finalDeveloperPercentage;
        offerAmount = listing.askingPrice; // For JV, use asking price as reference
        finalAgreedPrice = listing.askingPrice; // For JV, final price is the asking price
      } else {
        // Extract buy offer amount from initial offer
        final amountRegex = RegExp(r'Made an offer of AED ([\d.,]+[KM]?)');
        final amountMatch = amountRegex.firstMatch(offerMessage.content);
        if (amountMatch != null) {
          final amountStr = amountMatch.group(1)!;
          offerAmount = _parseFormattedPrice(amountStr);
        }
        
        // Look for counter offers to find the final agreed price
        // Check all messages for counter offers (messages containing "AED" amounts)
        double? lastCounterOffer;
        for (final message in negotiation.messages.reversed) {
          final counterRegex = RegExp(r'AED ([\d.,]+[KM]?)');
          final counterMatch = counterRegex.firstMatch(message.content);
          if (counterMatch != null) {
            final counterStr = counterMatch.group(1)!;
            lastCounterOffer = _parseFormattedPrice(counterStr);
            break; // Found the most recent counter offer
          }
        }
        
        // Use the last counter offer as final price, or initial offer if no counter
        finalAgreedPrice = lastCounterOffer ?? offerAmount;
      }

      final deal = Deal(
        id: negotiation.id, // Use negotiation ID as deal ID
        listingId: negotiation.listingId,
        listingTitle: negotiation.listingTitle,
        sellerId: negotiation.sellerId,
        sellerName: actualSellerName,
        buyerId: negotiation.developerId,
        buyerName: negotiation.developerName,
        developerId: negotiation.developerId,
        developerName: negotiation.developerName,
        finalPrice: finalAgreedPrice ?? offerAmount ?? listing.askingPrice,
        offerAmount: offerAmount,
        askingPrice: listing.askingPrice,
        type: dealType,
        sellerPercentage: sellerPercentage,
        developerPercentage: developerPercentage,
        status: DealStatus.pending,
        createdAt: negotiation.createdAt,
        updatedAt: DateTime.now(),
        acceptedAt: DateTime.now(),
        contractDocuments: {},
      );

      // Save deal to Firestore
      await _firestore
          .collection('deals')
          .doc(deal.id)
          .set(deal.toJson());

      return deal;
    } catch (e) {
      print('Error creating deal from negotiation: $e');
      throw Exception('Failed to create deal: $e');
    }
  }

  /// Get all deals
  Future<List<Deal>> getAllDeals() async {
    try {
      final snapshot = await _firestore
          .collection('deals')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Deal.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error getting deals: $e');
      throw Exception('Failed to get deals: $e');
    }
  }

  /// Update existing deals with correct seller names
  Future<void> updateDealsWithCorrectSellerNames() async {
    try {
      final allDeals = await getAllDeals();
      print('Found ${allDeals.length} deals to update');
      
      for (final deal in allDeals) {
        if (deal.sellerName == 'Property Owner') {
          print('Updating deal ${deal.id} with correct seller name');
          
          // Get actual seller name from seller profile
          final sellerProfile = await _authService.getSellerProfile(deal.sellerId);
          final actualSellerName = sellerProfile?.name ?? 'Unknown Seller';
          
          // Update the deal with correct seller name
          await _firestore.collection('deals').doc(deal.id).update({
            'sellerName': actualSellerName,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          
          print('✅ Updated deal ${deal.id} with seller name: $actualSellerName');
        }
      }
    } catch (e) {
      print('Error updating deals with correct seller names: $e');
      throw Exception('Failed to update deals: $e');
    }
  }

  /// Get deals by status
  Future<List<Deal>> getDealsByStatus(DealStatus status) async {
    try {
      final snapshot = await _firestore
          .collection('deals')
          .where('status', isEqualTo: status.toString().split('.').last)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Deal.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error getting deals by status: $e');
      throw Exception('Failed to get deals by status: $e');
    }
  }

  /// Update deal status
  Future<void> updateDealStatus(String dealId, DealStatus status, {String? rejectionReason, String? completedBy}) async {
    try {
      final updateData = {
        'status': status.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      switch (status) {
        case DealStatus.completed:
          updateData['completedAt'] = FieldValue.serverTimestamp();
          if (completedBy != null) {
            updateData['completedBy'] = completedBy;
          }
          break;
        case DealStatus.cancelled:
          updateData['cancelledAt'] = FieldValue.serverTimestamp();
          if (rejectionReason != null) {
            updateData['rejectionReason'] = rejectionReason;
          }
          break;
        case DealStatus.pending:
          break;
      }

      await _firestore
          .collection('deals')
          .doc(dealId)
          .update(updateData);

      // Also update the corresponding negotiation status
      if (status == DealStatus.completed) {
        await _negotiationService.updateNegotiationStatus(dealId, OfferStatus.completed);
        
        // Update listing status to sold
        final deal = await getDealById(dealId);
        if (deal != null) {
          await _landListingService.markListingAsSold(deal.listingId);
        }
      } else if (status == DealStatus.cancelled) {
        await _negotiationService.updateNegotiationStatus(dealId, OfferStatus.rejected);
        
        // Reactivate the listing so it shows up for developers again
        final deal = await getDealById(dealId);
        if (deal != null) {
          await _landListingService.reactivateListing(deal.listingId);
        }
      }
    } catch (e) {
      print('Error updating deal status: $e');
      throw Exception('Failed to update deal status: $e');
    }
  }

  /// Upload contract document
  Future<void> uploadContractDocument(String dealId, String documentType, String documentUrl) async {
    try {
      await _firestore
          .collection('deals')
          .doc(dealId)
          .update({
        'contractDocuments.$documentType': documentUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error uploading contract document: $e');
      throw Exception('Failed to upload contract document: $e');
    }
  }

  /// Check if all required documents are uploaded for a deal
  bool hasAllRequiredDocuments(Deal deal) {
    if (deal.type == DealType.buy) {
      // Buy deals need Contract A, B, F
      final requiredDocs = ['Contract A', 'Contract B', 'Contract F'];
      return requiredDocs.every((doc) => deal.contractDocuments.containsKey(doc));
    } else if (deal.type == DealType.jv) {
      // JV deals need JV Agreement
      return deal.contractDocuments.containsKey('JV Agreement');
    }
    return true;
  }

  /// Get deal by ID
  Future<Deal?> getDealById(String dealId) async {
    try {
      final doc = await _firestore
          .collection('deals')
          .doc(dealId)
          .get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      data['id'] = doc.id;
      return Deal.fromJson(data);
    } catch (e) {
      print('Error getting deal by ID: $e');
      throw Exception('Failed to get deal: $e');
    }
  }


  /// Parse formatted price string (e.g., "2.5M" -> 2500000)
  double _parseFormattedPrice(String priceStr) {
    try {
      if (priceStr.endsWith('M')) {
        final number = double.parse(priceStr.replaceAll('M', ''));
        return number * 1000000;
      } else if (priceStr.endsWith('K')) {
        final number = double.parse(priceStr.replaceAll('K', ''));
        return number * 1000;
      } else {
        return double.parse(priceStr.replaceAll(',', ''));
      }
    } catch (e) {
      return 0.0;
    }
  }
}
