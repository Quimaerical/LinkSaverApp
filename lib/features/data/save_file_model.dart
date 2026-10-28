class SaveFileModel {
  final int id;
  final int directoryId;
  final String relativePath;
  final String sha256Hash;
  final int fileSizeBytes;
  final int version;
  final bool isActive;
  final String conflictSuffix;
  final DateTime remoteModifiedAt;

  const SaveFileModel({
    required this.id,
    required this.directoryId,
    required this.relativePath,
    required this.sha256Hash,
    required this.fileSizeBytes,
    required this.version,
    required this.isActive,
    this.conflictSuffix = '',
    required this.remoteModifiedAt,
  });

  factory SaveFileModel.fromJson(Map<String, dynamic> json) {
    return SaveFileModel(
      id: json['id'] as int? ?? 0,
      directoryId: json['directory_id'] as int? ?? 0,
      relativePath: json['relative_path'] as String? ?? '',
      sha256Hash: json['sha256_hash'] as String? ?? '',
      fileSizeBytes: json['file_size_bytes'] as int? ?? 0,
      version: json['version'] as int? ?? 1,
      isActive: json['is_active'] as bool? ?? false,
      conflictSuffix: json['conflict_suffix'] as String? ?? '',
      remoteModifiedAt: json['remote_modified_at'] != null
          ? DateTime.tryParse(json['remote_modified_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
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
