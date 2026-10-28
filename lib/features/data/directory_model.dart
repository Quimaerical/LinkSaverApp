class DirectoryModel {
  final int id;
  final String tag;
  final String displayName;
  final String description;
  final String storagePath;
  final String? localPath;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DirectoryModel({
    required this.id,
    required this.tag,
    required this.displayName,
    this.description = '',
    required this.storagePath,
    this.localPath,
    this.createdAt,
    this.updatedAt,
  });

  factory DirectoryModel.fromJson(Map<String, dynamic> json, [String? localPath]) {
    return DirectoryModel(
      id: json['id'] as int? ?? 0,
      tag: json['tag'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      storagePath: json['storage_path'] as String? ?? '',
      localPath: localPath,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tag': tag,
      'display_name': displayName,
      'description': description,
      'storage_path': storagePath,
    };
  }

  DirectoryModel copyWith({
    int? id,
    String? tag,
    String? displayName,
    String? description,
    String? storagePath,
    String? localPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DirectoryModel(
      id: id ?? this.id,
      tag: tag ?? this.tag,
      displayName: displayName ?? this.displayName,
      description: description ?? this.description,
      storagePath: storagePath ?? this.storagePath,
      localPath: localPath ?? this.localPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
