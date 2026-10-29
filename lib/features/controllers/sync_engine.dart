import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../../core/services/storage_permission_service.dart';
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

    if (Platform.isAndroid) {
      final hasPermission = await StoragePermissionService.hasStoragePermission();
      if (!hasPermission) {
        _lastError = 'Permiso de acceso a todos los archivos requerido. Por favor concédalo en Ajustes.';
        _syncStatusText = 'Permiso requerido';
        notifyListeners();
        await StoragePermissionService.requestStoragePermission();
        return;
      }
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
      int uploadedCount = 0;
      int downloadedCount = 0;
      int identicalCount = 0;

      // 1. Obtener manifiesto remoto
      debugPrint('[SyncEngine] Consultando manifiesto remoto de "${directory.tag}"...');
      final remoteManifest = await repository.getRemoteManifest(directory.tag);
      debugPrint('[SyncEngine] Manifiesto remoto tiene ${remoteManifest.length} archivos: ${remoteManifest.keys.toList()}');

      // 2. Mapear archivos locales (todos los archivos, sin filtro de extensión)
      _syncStatusText = 'Escaneando archivos locales...';
      _progress = 0.25;
      notifyListeners();

      final localFiles = <String, File>{};
      final localHashes = <String, String>{};
      final localModTimes = <String, DateTime>{};

      final entities = localDir.listSync(recursive: true, followLinks: false);
      for (final entity in entities) {
        if (entity is File) {
          String relPath = p.relative(entity.path, from: localPath).replaceAll('\\', '/');
          while (relPath.startsWith('/')) {
            relPath = relPath.substring(1);
          }
          if (relPath.isNotEmpty) {
            localFiles[relPath] = entity;
            final bytes = entity.readAsBytesSync();
            localHashes[relPath] = sha256.convert(bytes).toString();
            localModTimes[relPath] = entity.lastModifiedSync();
          }
        }
      }
      debugPrint('[SyncEngine] Archivos locales detectados (${localFiles.length}): ${localFiles.keys.toList()}');

      // 3. Sincronizar unión de archivos locales y remotos
      final allKeys = {...localFiles.keys, ...remoteManifest.keys};
      int processed = 0;
      final totalOperations = allKeys.length;

      for (final rel in allKeys) {
        final localFile = localFiles[rel];
        final localHash = localHashes[rel];
        final remoteFile = remoteManifest[rel];

        if (localFile != null && remoteFile == null) {
          // Caso 1: Solo existe en local -> Subir al servidor
          debugPrint('[SyncEngine] [$rel] Solo local -> Subiendo...');
          _syncStatusText = 'Subiendo $rel...';
          notifyListeners();

          final bytes = await localFile.readAsBytes();
          await repository.uploadSaveFile(
            tag: directory.tag,
            relativePath: rel,
            fileBytes: bytes,
            localSha256: localHash!,
          );
          uploadedCount++;
        } else if (localFile == null && remoteFile != null) {
          // Caso 2: Solo existe en remoto -> Descargar a local
          debugPrint('[SyncEngine] [$rel] Solo remoto -> Descargando...');
          _syncStatusText = 'Descargando $rel...';
          notifyListeners();

          try {
            debugPrint('[SyncEngine] [$rel] Invocando downloadSaveFile(tag: ${directory.tag}, rel: $rel)...');
            final bytes = await repository.downloadSaveFile(directory.tag, rel);
            debugPrint('[SyncEngine] [$rel] Descarga completada: ${bytes.length} bytes recibidos.');

            final targetFile = File(p.join(localPath, rel));
            debugPrint('[SyncEngine] [$rel] Preparando guardado en: "${targetFile.path}"');
            debugPrint('[SyncEngine] [$rel] Creando directorio padre: "${targetFile.parent.path}"...');
            targetFile.parent.createSync(recursive: true);

            debugPrint('[SyncEngine] [$rel] Escribiendo archivo en disco...');
            await targetFile.writeAsBytes(bytes, flush: true);
            debugPrint('[SyncEngine] [$rel] Guardado exitoso: ${targetFile.path} (existe: ${targetFile.existsSync()}, tamaño: ${targetFile.lengthSync()} bytes)');
            downloadedCount++;
          } catch (fileErr, stack) {
            debugPrint('[SyncEngine] [$rel] ERROR FATAL AL DESCARGAR O ESCRIBIR: $fileErr\n$stack');
            rethrow;
          }
        } else if (localFile != null && remoteFile != null) {
          // Caso 3: Existe en ambos sitios -> Comparar hashes
          if (localHash!.toLowerCase() == remoteFile.sha256Hash.toLowerCase()) {
            debugPrint('[SyncEngine] [$rel] Idéntico (${localHash.substring(0, min(8, localHash.length))}). Al día.');
            identicalCount++;
          } else {
            // Hashes distintos: resolver por fecha de modificación
            final localMod = localModTimes[rel] ?? DateTime.fromMillisecondsSinceEpoch(0);
            final remoteMod = remoteFile.remoteModifiedAt;
            debugPrint('[SyncEngine] [$rel] Diferencia de hash. Local: $localMod, Remoto: $remoteMod');

            if (remoteMod.isAfter(localMod)) {
              // Servidor es más reciente -> Descargar y sobrescribir
              debugPrint('[SyncEngine] [$rel] Remoto es más reciente -> Descargando actualización...');
              _syncStatusText = 'Actualizando $rel...';
              notifyListeners();

              try {
                debugPrint('[SyncEngine] [$rel] Invocando downloadSaveFile(tag: ${directory.tag}, rel: $rel)...');
                final bytes = await repository.downloadSaveFile(directory.tag, rel);
                debugPrint('[SyncEngine] [$rel] Descarga completada: ${bytes.length} bytes recibidos.');

                final targetFile = File(p.join(localPath, rel));
                targetFile.parent.createSync(recursive: true);
                await targetFile.writeAsBytes(bytes, flush: true);
                debugPrint('[SyncEngine] [$rel] Sobrescrito con versión remota: ${targetFile.path} (tamaño: ${targetFile.lengthSync()})');
                downloadedCount++;
              } catch (fileErr, stack) {
                debugPrint('[SyncEngine] [$rel] ERROR AL ACTUALIZAR: $fileErr\n$stack');
                rethrow;
              }
            } else {
              // Local es más reciente -> Subir al servidor
              debugPrint('[SyncEngine] [$rel] Local es más reciente -> Subiendo nueva versión...');
              _syncStatusText = 'Subiendo $rel...';
              notifyListeners();

              final bytes = await localFile.readAsBytes();
              await repository.uploadSaveFile(
                tag: directory.tag,
                relativePath: rel,
                fileBytes: bytes,
                localSha256: localHash,
              );
              uploadedCount++;
            }
          }
        }

        processed++;
        _progress = 0.25 + (0.75 * (processed / (totalOperations == 0 ? 1 : totalOperations)));
        notifyListeners();
      }

      _syncStatusText = 'Sincronización finalizada: $uploadedCount subidas, $downloadedCount descargadas, $identicalCount al día';
      _progress = 1.0;
      debugPrint('[SyncEngine] $_syncStatusText');
    } catch (e, stack) {
      debugPrint('[SyncEngine] ERROR GENERAL EN SINCRONIZACION: $e\n$stack');
      _lastError = 'Error de sincronización: $e';
      _syncStatusText = 'Fallo en la sincronización: $e';
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
