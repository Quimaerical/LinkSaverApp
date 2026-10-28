class SyncLogModel {
  final int id;
  final int directoryId;
  final String clientType;
  final String action;
  final String status;
  final String details;
  final DateTime timestamp;

  const SyncLogModel({
    required this.id,
    required this.directoryId,
    required this.clientType,
    required this.action,
    required this.status,
    this.details = '',
    required this.timestamp,
  });

  factory SyncLogModel.fromJson(Map<String, dynamic> json) {
    return SyncLogModel(
      id: json['id'] as int? ?? 0,
      directoryId: json['directory_id'] as int? ?? 0,
      clientType: json['client_type'] as String? ?? 'Desconocido',
      action: json['action'] as String? ?? '',
      status: json['status'] as String? ?? '',
      details: json['details'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
