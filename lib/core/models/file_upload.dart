import 'dart:typed_data';

enum UploadStatus { uploading, completed, failed, cancelled }

class FileUpload {
  final String id;
  final String fileName;
  final String filePath;
  final int fileSize;
  final String mimeType;
  final DateTime uploadDate;
  UploadStatus uploadStatus;
  String? errorMessage;
  Uint8List? thumbnail;
  String? downloadUrl;
  double uploadProgress;

  FileUpload({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    required this.mimeType,
    required this.uploadDate,
    this.uploadStatus = UploadStatus.uploading,
    this.errorMessage,
    this.thumbnail,
    this.downloadUrl,
    this.uploadProgress = 0.0,
  });

  // Basic getters
  bool get isUploading => uploadStatus == UploadStatus.uploading;
  bool get isCompleted => uploadStatus == UploadStatus.completed;
  bool get isFailed => uploadStatus == UploadStatus.failed;
  bool get isCancelled => uploadStatus == UploadStatus.cancelled;

  // File type helpers
  bool get isImage => mimeType.startsWith('image/');
  bool get isDocument => mimeType.startsWith('application/') && 
                        (mimeType.contains('pdf') || 
                         mimeType.contains('word') || 
                         mimeType.contains('document'));

  // File size helpers
  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    if (fileSize < 1024 * 1024 * 1024) return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // Status helpers
  String get statusText {
    switch (uploadStatus) {
      case UploadStatus.uploading:
        return 'Uploading...';
      case UploadStatus.completed:
        return 'Completed';
      case UploadStatus.failed:
        return 'Failed';
      case UploadStatus.cancelled:
        return 'Cancelled';
    }
  }

  // Copy with method for immutability
  FileUpload copyWith({
    String? id,
    String? fileName,
    String? filePath,
    int? fileSize,
    String? mimeType,
    DateTime? uploadDate,
    UploadStatus? uploadStatus,
    String? errorMessage,
    Uint8List? thumbnail,
    String? downloadUrl,
    double? uploadProgress,
  }) {
    return FileUpload(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      uploadDate: uploadDate ?? this.uploadDate,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      errorMessage: errorMessage ?? this.errorMessage,
      thumbnail: thumbnail ?? this.thumbnail,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      uploadProgress: uploadProgress ?? this.uploadProgress,
    );
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'filePath': filePath,
      'fileSize': fileSize,
      'mimeType': mimeType,
      'uploadDate': uploadDate.toIso8601String(),
      'uploadStatus': uploadStatus.name,
      'errorMessage': errorMessage,
      'downloadUrl': downloadUrl,
      'uploadProgress': uploadProgress,
    };
  }

  factory FileUpload.fromJson(Map<String, dynamic> json) {
    return FileUpload(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      filePath: json['filePath'] as String,
      fileSize: json['fileSize'] as int,
      mimeType: json['mimeType'] as String,
      uploadDate: DateTime.parse(json['uploadDate'] as String),
      uploadStatus: UploadStatus.values.firstWhere(
        (e) => e.name == json['uploadStatus'],
        orElse: () => UploadStatus.uploading,
      ),
      errorMessage: json['errorMessage'] as String?,
      downloadUrl: json['downloadUrl'] as String?,
      uploadProgress: (json['uploadProgress'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  String toString() {
    return 'FileUpload(id: $id, fileName: $fileName, status: $uploadStatus)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FileUpload && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

