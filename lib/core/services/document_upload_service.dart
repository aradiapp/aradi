import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

class DocumentUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload a document file to Firebase Storage
  Future<String> uploadDocument(File file, String dealId, String documentType) async {
    try {
      print('DocumentUploadService: Starting upload for $documentType');
      // Create a unique filename
      final fileName = '${documentType}_${DateTime.now().millisecondsSinceEpoch}${path.extension(file.path)}';
      final storagePath = 'contracts/$dealId/$fileName';
      print('DocumentUploadService: Storage path: $storagePath');
      
      // Upload file to Firebase Storage with proper metadata
      final ref = _storage.ref().child(storagePath);
      print('DocumentUploadService: Created storage reference');
      
      // Create metadata to avoid null pointer exception
      final metadata = SettableMetadata(
        contentType: _getContentType(file.path),
        cacheControl: 'max-age=31536000', // 1 year cache
      );
      print('DocumentUploadService: Created metadata with content type: ${metadata.contentType}');
      
      final uploadTask = ref.putFile(file, metadata);
      print('DocumentUploadService: Started upload task with metadata');
      
      // Wait for upload to complete
      print('DocumentUploadService: Waiting for upload to complete...');
      final snapshot = await uploadTask;
      print('DocumentUploadService: Upload completed, getting download URL...');
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      print('DocumentUploadService: Got download URL: $downloadUrl');
      
      return downloadUrl;
    } catch (e) {
      print('DocumentUploadService: Error uploading document: $e');
      throw Exception('Failed to upload document: $e');
    }
  }

  /// Get content type based on file extension
  String _getContentType(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    switch (extension) {
      case '.pdf':
        return 'application/pdf';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }

  /// Pick a document from device storage
  Future<File?> pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      );
      
      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
      return null;
    } catch (e) {
      print('Error picking document: $e');
      throw Exception('Failed to pick document: $e');
    }
  }

  /// Delete a document from Firebase Storage
  Future<void> deleteDocument(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (e) {
      print('Error deleting document: $e');
      throw Exception('Failed to delete document: $e');
    }
  }

  /// Get file size in MB
  double getFileSizeInMB(File file) {
    final bytes = file.lengthSync();
    return bytes / (1024 * 1024);
  }

  /// Validate file type (allow PDF, DOC, DOCX, JPG, PNG)
  bool isValidFileType(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    const allowedExtensions = ['.pdf', '.doc', '.docx', '.jpg', '.jpeg', '.png'];
    return allowedExtensions.contains(extension);
  }

  /// Validate file size (max 10MB)
  bool isValidFileSize(File file) {
    return getFileSizeInMB(file) <= 10.0;
  }
}
