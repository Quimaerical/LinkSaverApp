import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../data/directory_model.dart';
import '../data/linksaver_repository.dart';

class SyncEngine extends ChangeNotifier {
  final LinkSaverRepository repository;

  bool _isSyncing = false;
  String _syncStatusText = 'Inactivo';
  double _progress = 0.0;
  String? _lastError;

  SyncEngine(this.repository);

  bool get isSyncing => _isSyncing;
  String get syncStatusText => _syncStatusText;
  double get progress => _progress;
  String? get lastError => _lastError;

  Future<void> syncDirectory(DirectoryModel directory) async {
    final localPath = directory.localPath;
    if (localPath == null || localPath.isEmpty) {
      _lastError = 'El tag "${directory.tag}" no tiene una ruta local asignada.';
      notifyListeners();
      return;
    }

    final localDir = Directory(localPath);
    if (!localDir.existsSync()) {
      _lastError = 'La carpeta local no existe: $localPath';
      notifyListeners();
      return;
    }

    _isSyncing = true;
    _lastError = null;
    _syncStatusText = 'Consultando manifiesto remoto de "${directory.tag}"...';
    _progress = 0.1;
    notifyListeners();

    try {
      // 1. Obtener manifiesto remoto
      final remoteManifest = await repository.getRemoteManifest(directory.tag);

      // 2. Mapear archivos locales (todos los archivos, sin filtro de extensión)
      _syncStatusText = 'Escaneando archivos locales...';
      _progress = 0.25;
      notifyListeners();

      final localFiles = <String, File>{};
      final localHashes = <String, String>{};

      final entities = localDir.listSync(recursive: true, followLinks: false);
      for (final entity in entities) {
        if (entity is File) {
          final relPath = p.relative(entity.path, from: localPath).replaceAll('\\', '/');
          localFiles[relPath] = entity;
          final bytes = entity.readAsBytesSync();
          localHashes[relPath] = sha256.convert(bytes).toString();
        }
      }

      // 3. Subir archivos locales nuevos o modificados
      int processed = 0;
      final totalOperations = localFiles.length + remoteManifest.length;

      for (final entry in localFiles.entries) {
        final rel = entry.key;
        final file = entry.value;
        final localHash = localHashes[rel]!;
        final remoteHash = remoteManifest[rel];

        if (remoteHash == null || remoteHash.toLowerCase() != localHash.toLowerCase()) {
          _syncStatusText = 'Subiendo $rel...';
          notifyListeners();
          final bytes = await file.readAsBytes();
          await repository.uploadSaveFile(
            tag: directory.tag,
            relativePath: rel,
            fileBytes: bytes,
            localSha256: localHash,
          );
        }
        processed++;
        _progress = 0.25 + (0.50 * (processed / (totalOperations == 0 ? 1 : totalOperations)));
        notifyListeners();
      }

      // 4. Descargar archivos que están en el servidor pero no en local
      for (final remoteEntry in remoteManifest.entries) {
        final rel = remoteEntry.key;
        final localHash = localHashes[rel];

        if (localHash == null) {
          _syncStatusText = 'Descargando $rel...';
          notifyListeners();
          final bytes = await repository.downloadSaveFile(directory.tag, rel);
          final targetFile = File(p.join(localPath, rel));
          targetFile.parent.createSync(recursive: true);
          await targetFile.writeAsBytes(bytes);
        }
        processed++;
        _progress = 0.25 + (0.50 * (processed / (totalOperations == 0 ? 1 : totalOperations)));
        notifyListeners();
      }

      _syncStatusText = 'Sincronización completada exitosamente';
      _progress = 1.0;
    } catch (e) {
      _lastError = 'Error de sincronización: $e';
      _syncStatusText = 'Fallo en la sincronización';
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> syncAll(List<DirectoryModel> directories) async {
    _isSyncing = true;
    _lastError = null;
    notifyListeners();

    for (final dir in directories) {
      if (dir.localPath != null && dir.localPath!.isNotEmpty) {
        await syncDirectory(dir);
      }
    }

    _isSyncing = false;
    _syncStatusText = 'Sincronización global finalizada';
    notifyListeners();
  }
}
