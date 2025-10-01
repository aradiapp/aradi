import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:aradi/core/models/file_upload.dart';

class FileService {
  static final ImagePicker _imagePicker = ImagePicker();

  static Future<FileUpload?> pickImage({
    ImageSource source = ImageSource.gallery,
    int? maxWidth,
    int? maxHeight,
    int? imageQuality,
  }) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: maxWidth?.toDouble(),
        maxHeight: maxHeight?.toDouble(),
        imageQuality: imageQuality,
      );

      if (image == null) return null;

      final file = File(image.path);
      final bytes = await file.readAsBytes();
      final fileSize = bytes.length;

      return FileUpload(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        fileName: image.name,
        filePath: image.path,
        fileSize: fileSize,
        mimeType: _getMimeType(image.name),
        uploadDate: DateTime.now(),
        uploadStatus: UploadStatus.uploading,
        uploadProgress: 0.0,
      );
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  static Future<List<FileUpload>> pickMultipleImages({
    int? maxWidth,
    int? maxHeight,
    int? imageQuality,
  }) async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: maxWidth?.toDouble(),
        maxHeight: maxHeight?.toDouble(),
        imageQuality: imageQuality,
      );

      List<FileUpload> uploads = [];
      for (final image in images) {
        final file = File(image.path);
        final bytes = await file.readAsBytes();
        final fileSize = bytes.length;

        uploads.add(FileUpload(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          fileName: image.name,
          filePath: image.path,
          fileSize: fileSize,
          mimeType: _getMimeType(image.name),
          uploadDate: DateTime.now(),
          uploadStatus: UploadStatus.uploading,
          uploadProgress: 0.0,
        ));
      }

      return uploads;
    } catch (e) {
      print('Error picking multiple images: $e');
      return [];
    }
  }

  static Future<FileUpload?> takePhoto({
    int? maxWidth,
    int? maxHeight,
    int? imageQuality,
  }) async {
    return pickImage(
      source: ImageSource.camera,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );
  }

  static String _getMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  static bool isValidFileType(String fileName, List<String> allowedExtensions) {
    final extension = fileName.split('.').last.toLowerCase();
    return allowedExtensions.contains(extension);
  }

  static bool isValidFileSize(int fileSize, int maxSizeInBytes) {
    return fileSize <= maxSizeInBytes;
  }

  static Future<bool> uploadFile(FileUpload upload) async {
    try {
      // Simulate upload delay
      await Future.delayed(const Duration(seconds: 2));
      
      // Simulate random success/failure
      final success = DateTime.now().millisecondsSinceEpoch % 10 != 0;
      
      if (success) {
        // Simulate successful upload
        print('File uploaded successfully: ${upload.fileName}');
        return true;
      } else {
        // Simulate upload failure
        print('File upload failed: ${upload.fileName}');
        return false;
      }
    } catch (e) {
      print('Error uploading file: $e');
      return false;
    }
  }

  static Future<List<bool>> uploadMultipleFiles(List<FileUpload> uploads) async {
    List<bool> results = [];
    for (final upload in uploads) {
      final result = await uploadFile(upload);
      results.add(result);
    }
    return results;
  }

  static Future<bool> deleteFile(FileUpload upload) async {
    try {
      // Simulate file deletion
      await Future.delayed(const Duration(milliseconds: 500));
      print('File deleted: ${upload.fileName}');
      return true;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getFileInfo(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final stat = await file.stat();
        return {
          'size': stat.size,
          'modified': stat.modified,
          'accessed': stat.accessed,
          'created': stat.changed,
        };
      }
      return null;
    } catch (e) {
      print('Error getting file info: $e');
      return null;
    }
  }
}

