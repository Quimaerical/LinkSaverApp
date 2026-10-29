import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class StoragePermissionService {
  static const MethodChannel _channel = MethodChannel('com.example.linksaverapp/storage_permission');

  static Future<bool> hasStoragePermission() async {
    if (!Platform.isAndroid) return true;
    try {
      final bool? granted = await _channel.invokeMethod<bool>('checkStoragePermission');
      return granted ?? false;
    } catch (e) {
      debugPrint('[StoragePermissionService] Error al verificar permiso: $e');
      return false;
    }
  }

  static Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid) return true;
    try {
      final bool? result = await _channel.invokeMethod<bool>('requestStoragePermission');
      return result ?? false;
    } catch (e) {
      debugPrint('[StoragePermissionService] Error al solicitar permiso: $e');
      return false;
    }
  }
}
