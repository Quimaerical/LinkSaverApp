class SaveFileModel {
  final int id;
  final int directoryId;
  final String relativePath;
  final String fileName;
  final String originalName;
  final String sha256Hash;
  final int fileSizeBytes;
  final int version;
  final bool isActive;
  final String conflictSuffix;
  final DateTime remoteModifiedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SaveFileModel({
    required this.id,
    required this.directoryId,
    required this.relativePath,
    this.fileName = '',
    this.originalName = '',
    required this.sha256Hash,
    required this.fileSizeBytes,
    required this.version,
    required this.isActive,
    this.conflictSuffix = '',
    required this.remoteModifiedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory SaveFileModel.fromJson(Map<String, dynamic> json) {
    return SaveFileModel(
      id: json['id'] as int? ?? 0,
      directoryId: json['directory_id'] as int? ?? 0,
      relativePath: json['relative_path'] as String? ?? '',
      fileName: json['file_name'] as String? ?? '',
      originalName: json['original_name'] as String? ?? '',
      sha256Hash: json['sha256_hash'] as String? ?? '',
      fileSizeBytes: json['file_size_bytes'] as int? ?? 0,
      version: json['version'] as int? ?? 1,
      isActive: json['is_active'] as bool? ?? false,
      conflictSuffix: json['conflict_suffix'] as String? ?? '',
      remoteModifiedAt: json['remote_modified_at'] != null
          ? DateTime.tryParse(json['remote_modified_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  String get displayName {
    if (fileName.isNotEmpty) return fileName;
    final parts = relativePath.split('/');
    return parts.isNotEmpty ? parts.last : relativePath;
  }

  String get directoryBreadcrumb {
    final parts = relativePath.split('/');
    if (parts.length > 1) {
      return parts.sublist(0, parts.length - 1).join(' / ');
    }
    return '';
  }

  String get fileExtension {
    final name = displayName;
    final dot = name.lastIndexOf('.');
    if (dot != -1 && dot < name.length - 1) {
      return name.substring(dot + 1).toUpperCase();
    }
    return 'SAVE';
  }

  String get formattedSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  String get shortHash {
    if (sha256Hash.length <= 10) return sha256Hash;
    return '${sha256Hash.substring(0, 8)}...';
  }
}
