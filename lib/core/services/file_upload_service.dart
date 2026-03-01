import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class FileUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  // Upload a single file
  Future<String> uploadFile(File file, String folder) async {
    try {
      // Ensure file exists (picker may return a path that was deleted). If not, use bytes if we have a valid path for content type.
      File fileToUpload = file;
      if (!file.existsSync()) {
        throw Exception(
          'The selected file is no longer available. Please pick the file again and submit immediately.',
        );
      }
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
      final ref = _storage.ref().child('$folder/$fileName');
      final metadata = SettableMetadata(
        contentType: _getContentType(file.path),
        cacheControl: 'max-age=31536000',
      );
      final uploadTask = await ref.putFile(fileToUpload, metadata);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }
  
  // Get content type based on file extension
  String _getContentType(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  // Upload multiple files
  Future<List<String>> uploadFiles(List<File> files, String folder) async {
    try {
      final List<String> urls = [];
      
      for (final file in files) {
        final url = await uploadFile(file, folder);
        urls.add(url);
      }
      
      return urls;
    } catch (e) {
      throw Exception('Failed to upload files: $e');
    }
  }

  // Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image != null) {
        return await _copyToAppTemp(File(image.path), path.basename(image.path));
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick image from gallery: $e');
    }
  }

  // Pick image from camera
  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image != null) {
        return await _copyToAppTemp(File(image.path), path.basename(image.path));
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick image from camera: $e');
    }
  }

  /// Pick a document (PDF, Word, or image). Use for deeds, licenses, passports, etc.
  /// Copies the file into the app temp dir so the path stays valid until upload.
  Future<File?> pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      );
      if (result == null) return null;
      final platformFile = result.files.single;
      final name = platformFile.name;
      if (platformFile.bytes != null) {
        return await _writeBytesToAppTemp(platformFile.bytes!, name);
      }
      if (platformFile.path != null) {
        final source = File(platformFile.path!);
        if (source.existsSync()) {
          return await _copyToAppTemp(source, name);
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick document: $e');
    }
  }

  /// Copy a file to app temp dir so the path remains valid for upload.
  Future<File> _copyToAppTemp(File source, String baseName) async {
    final dir = await getTemporaryDirectory();
    final ext = path.extension(baseName);
    final name = path.basenameWithoutExtension(baseName);
    final dest = File('${dir.path}/aradi_${DateTime.now().millisecondsSinceEpoch}_${name}$ext');
    await source.copy(dest.path);
    return dest;
  }

  /// Write bytes to app temp file (e.g. when picker only provides bytes).
  Future<File> _writeBytesToAppTemp(List<int> bytes, String baseName) async {
    final dir = await getTemporaryDirectory();
    final ext = path.extension(baseName);
    final name = path.basenameWithoutExtension(baseName);
    final dest = File('${dir.path}/aradi_${DateTime.now().millisecondsSinceEpoch}_${name}$ext');
    await dest.writeAsBytes(bytes);
    return dest;
  }

  // Pick multiple images
  Future<List<File>> pickMultipleImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      return images.map((image) => File(image.path)).toList();
    } catch (e) {
      throw Exception('Failed to pick multiple images: $e');
    }
  }

  // Upload KYC documents
  Future<Map<String, String>> uploadKYCDocuments({
    File? passport,
    File? emiratesId,
    File? tradeLicense,
    File? signatoryPassport,
    File? logo,
  }) async {
    try {
      final Map<String, String> urls = {};
      
      if (passport != null) {
        urls['passport'] = await uploadFile(passport, 'kyc/passports');
      }
      
      if (emiratesId != null) {
        urls['emiratesId'] = await uploadFile(emiratesId, 'kyc/emirates_ids');
      }
      
      if (tradeLicense != null) {
        urls['tradeLicense'] = await uploadFile(tradeLicense, 'kyc/trade_licenses');
      }
      
      if (signatoryPassport != null) {
        urls['signatoryPassport'] = await uploadFile(signatoryPassport, 'kyc/signatory_passports');
      }
      
      if (logo != null) {
        urls['logo'] = await uploadFile(logo, 'kyc/logos');
      }
      
      return urls;
    } catch (e) {
      throw Exception('Failed to upload KYC documents: $e');
    }
  }

  // Upload listing photos
  Future<List<String>> uploadListingPhotos(List<File> photos) async {
    try {
      return await uploadFiles(photos, 'listings/photos');
    } catch (e) {
      throw Exception('Failed to upload listing photos: $e');
    }
  }

  // Upload portfolio PDF
  Future<String> uploadPortfolioPDF(File pdfFile) async {
    try {
      return await uploadFile(pdfFile, 'portfolios');
    } catch (e) {
      throw Exception('Failed to upload portfolio PDF: $e');
    }
  }

  // Delete file from storage
  Future<void> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  // Delete multiple files
  Future<void> deleteFiles(List<String> urls) async {
    try {
      for (final url in urls) {
        await deleteFile(url);
      }
    } catch (e) {
      throw Exception('Failed to delete files: $e');
    }
  }

  // Get file size in MB
  double getFileSizeInMB(File file) {
    final bytes = file.lengthSync();
    return bytes / (1024 * 1024);
  }

  // Validate file size (max 10MB)
  bool isValidFileSize(File file, {double maxSizeMB = 10.0}) {
    return getFileSizeInMB(file) <= maxSizeMB;
  }

  // Validate image file
  bool isValidImageFile(File file) {
    final extension = path.extension(file.path).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.webp'].contains(extension);
  }

  // Validate PDF file
  bool isValidPDFFile(File file) {
    final extension = path.extension(file.path).toLowerCase();
    return extension == '.pdf';
  }

  // Compress image (basic implementation)
  Future<File> compressImage(File file) async {
    // This is a basic implementation. In a real app, you might want to use
    // a proper image compression library like flutter_image_compress
    return file;
  }
}
