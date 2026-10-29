import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api/api_client.dart';
import 'directory_model.dart';
import 'save_file_model.dart';
import 'sync_log_model.dart';

abstract class LinkSaverRepository {
  Future<List<DirectoryModel>> getDirectories();
  Future<DirectoryModel> registerDirectory({
    required String tag,
    required String displayName,
    String description = '',
    String storagePath = '',
  });
  Future<void> updateStoragePath(String tag, String newPath);
  Future<List<SaveFileModel>> getVaultHistory(String tag);
  Future<void> restoreSaveVersion(String tag, int fileId);
  Future<List<SyncLogModel>> getAuditLogs({int limit = 50});
  Future<Map<String, String>> getRemoteManifest(String tag);
  Future<void> uploadSaveFile({
    required String tag,
    required String relativePath,
    required List<int> fileBytes,
    required String localSha256,
  });
  Future<List<int>> downloadSaveFile(String tag, String relativePath);
  Future<void> saveLocalPathForTag(String tag, String localPath);
  Future<String?> getLocalPathForTag(String tag);
}

class HttpLinkSaverRepository implements LinkSaverRepository {
  final ApiClient apiClient;
  final SharedPreferences prefs;

  HttpLinkSaverRepository({
    required this.apiClient,
    required this.prefs,
  });

  static const String _localPathPrefix = 'local_path_';

  @override
  Future<List<DirectoryModel>> getDirectories() async {
    final response = await apiClient.get('/api/v1/directories');
    if (response is List) {
      return response.map((item) {
        final dir = DirectoryModel.fromJson(Map<String, dynamic>.from(item));
        final local = prefs.getString('$_localPathPrefix${dir.tag}');
        return dir.copyWith(localPath: local);
      }).toList();
    }
    return [];
  }

  @override
  Future<DirectoryModel> registerDirectory({
    required String tag,
    required String displayName,
    String description = '',
    String storagePath = '',
  }) async {
    final response = await apiClient.post(
      '/api/v1/directories/register',
      body: {
        'tag': tag,
        'display_name': displayName,
        'description': description,
        'storage_path': storagePath,
      },
    );
    final dir = DirectoryModel.fromJson(Map<String, dynamic>.from(response));
    final local = prefs.getString('$_localPathPrefix${dir.tag}');
    return dir.copyWith(localPath: local);
  }

  @override
  Future<void> updateStoragePath(String tag, String newPath) async {
    await apiClient.put(
      '/api/v1/directories/$tag/storage-path',
      body: {'storage_path': newPath},
    );
  }

  @override
  Future<List<SaveFileModel>> getVaultHistory(String tag) async {
    final response = await apiClient.get('/api/v1/vault/$tag/history');
    if (response is List) {
      return response.map((item) => SaveFileModel.fromJson(Map<String, dynamic>.from(item))).toList();
    }
    return [];
  }

  @override
  Future<void> restoreSaveVersion(String tag, int fileId) async {
    await apiClient.post(
      '/api/v1/vault/$tag/restore',
      body: {'file_id': fileId},
    );
  }

  @override
  Future<List<SyncLogModel>> getAuditLogs({int limit = 50}) async {
    final response = await apiClient.get('/api/v1/logs?limit=$limit');
    if (response is List) {
      return response.map((item) => SyncLogModel.fromJson(Map<String, dynamic>.from(item))).toList();
    }
    return [];
  }

  @override
  Future<Map<String, String>> getRemoteManifest(String tag) async {
    final response = await apiClient.get('/api/v1/sync/manifest/$tag');
    final manifestMap = <String, String>{};
    if (response is Map && response['files'] is List) {
      final filesList = response['files'] as List;
      for (final item in filesList) {
        if (item is Map) {
          final relPath = item['relative_path']?.toString();
          final hash = item['sha256_hash']?.toString() ?? item['sha256']?.toString();
          if (relPath != null && relPath.isNotEmpty && hash != null) {
            manifestMap[relPath] = hash;
          }
        }
      }
    }
    return manifestMap;
  }

  @override
  Future<void> uploadSaveFile({
    required String tag,
    required String relativePath,
    required List<int> fileBytes,
    required String localSha256,
  }) async {
    await apiClient.postMultipart(
      endpoint: '/api/v1/sync/upload/$tag',
      fileParamName: 'file',
      fileBytes: fileBytes,
      filename: p.basename(relativePath),
      fields: {
        'relative_path': relativePath,
        'sha256': localSha256,
        'client_type': 'Android',
      },
    );
  }

  @override
  Future<List<int>> downloadSaveFile(String tag, String relativePath) async {
    final encodedPath = Uri.encodeQueryComponent(relativePath);
    return await apiClient.getRawBytes('/api/v1/sync/download/$tag?path=$encodedPath');
  }

  @override
  Future<void> saveLocalPathForTag(String tag, String localPath) async {
    await prefs.setString('$_localPathPrefix$tag', localPath);
  }

  @override
  Future<String?> getLocalPathForTag(String tag) async {
    return prefs.getString('$_localPathPrefix$tag');
  }
}
