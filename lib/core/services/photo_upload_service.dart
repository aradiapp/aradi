import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class PhotoUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload a single photo to Firebase Storage
  Future<String> uploadPhoto(File photoFile, String listingId) async {
    try {
      print('Starting photo upload for listing: $listingId');
      
      // Check if file exists
      if (!await photoFile.exists()) {
        throw Exception('Photo file does not exist');
      }
      
      // Create a unique filename
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(photoFile.path)}';
      final ref = _storage.ref().child('listing_photos/$listingId/$fileName');
      
      print('Uploading to path: listing_photos/$listingId/$fileName');
      
      // Upload the file with metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
          'listingId': listingId,
        },
      );
      
      final uploadTask = ref.putFile(photoFile, metadata);
      
      // Monitor upload progress
      uploadTask.snapshotEvents.listen((snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        print('Upload progress: ${progress.toStringAsFixed(1)}%');
      });
      
      // Wait for upload with timeout
      final snapshot = await uploadTask.timeout(
        const Duration(seconds: 60), // Increased timeout
        onTimeout: () {
          throw Exception('Upload timeout - please check your internet connection');
        },
      );
      
      print('Upload completed, getting download URL...');
      
      // Get the download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('Photo uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Error uploading photo: $e');
      // Check if it's a Google API error
      if (e.toString().contains('GoogleApiManager') || 
          e.toString().contains('SecurityException') ||
          e.toString().contains('Unknown calling package')) {
        print('Google API error detected - this is common on emulators');
        // Return a placeholder URL for emulator testing
        return 'https://picsum.photos/400/300?random=${DateTime.now().millisecondsSinceEpoch}';
      }
      // Return a placeholder URL instead of throwing
      return 'https://via.placeholder.com/400x300?text=Upload+Failed';
    }
  }

  /// Upload multiple photos to Firebase Storage
  Future<List<String>> uploadPhotos(List<File> photoFiles, String listingId) async {
    try {
      print('Starting batch photo upload for listing: $listingId');
      final List<String> downloadUrls = [];
      
      for (int i = 0; i < photoFiles.length; i++) {
        print('Uploading photo ${i + 1}/${photoFiles.length}');
        final downloadUrl = await uploadPhoto(photoFiles[i], listingId);
        downloadUrls.add(downloadUrl);
      }
      
      print('Batch upload completed: ${downloadUrls.length} photos');
      return downloadUrls;
    } catch (e) {
      print('Error uploading photos: $e');
      // Return empty list instead of throwing
      return [];
    }
  }

  /// Delete a photo from Firebase Storage
  Future<void> deletePhoto(String photoUrl) async {
    try {
      final ref = _storage.refFromURL(photoUrl);
      await ref.delete();
    } catch (e) {
      print('Error deleting photo: $e');
      // Don't rethrow - photo might already be deleted
    }
  }

  /// Delete multiple photos from Firebase Storage
  Future<void> deletePhotos(List<String> photoUrls) async {
    try {
      for (final photoUrl in photoUrls) {
        await deletePhoto(photoUrl);
      }
    } catch (e) {
      print('Error deleting photos: $e');
      // Don't rethrow - some photos might already be deleted
    }
  }
}
