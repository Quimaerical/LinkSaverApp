class ManifestFileModel {
  final String relativePath;
  final String fileName;
  final String sha256Hash;
  final int fileSizeBytes;
  final DateTime remoteModifiedAt;
  final int version;

  const ManifestFileModel({
    required this.relativePath,
    required this.fileName,
    required this.sha256Hash,
    required this.fileSizeBytes,
    required this.remoteModifiedAt,
    required this.version,
  });

  factory ManifestFileModel.fromJson(Map<String, dynamic> json) {
    return ManifestFileModel(
      relativePath: json['relative_path']?.toString() ?? '',
      fileName: json['file_name']?.toString() ?? '',
      sha256Hash: json['sha256_hash']?.toString() ?? json['sha256']?.toString() ?? '',
      fileSizeBytes: (json['file_size_bytes'] as num?)?.toInt() ?? 0,
      remoteModifiedAt: DateTime.tryParse(json['remote_modified_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      version: (json['version'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'relative_path': relativePath,
        'file_name': fileName,
        'sha256_hash': sha256Hash,
        'file_size_bytes': fileSizeBytes,
        'remote_modified_at': remoteModifiedAt.toIso8601String(),
        'version': version,
      };
}
