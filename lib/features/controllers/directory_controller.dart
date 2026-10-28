import 'package:flutter/foundation.dart';
import '../data/directory_model.dart';
import '../data/linksaver_repository.dart';

class DirectoryController extends ChangeNotifier {
  final LinkSaverRepository repository;

  List<DirectoryModel> _directories = [];
  bool _isLoading = false;
  String? _errorMessage;

  DirectoryController(this.repository);

  List<DirectoryModel> get directories => _directories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadDirectories() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _directories = await repository.getDirectories();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> registerDirectory({
    required String tag,
    required String displayName,
    String description = '',
    String storagePath = '',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newDir = await repository.registerDirectory(
        tag: tag,
        displayName: displayName,
        description: description,
        storagePath: storagePath,
      );
      _directories.removeWhere((d) => d.tag == newDir.tag);
      _directories.insert(0, newDir);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setLocalPath(String tag, String localPath) async {
    await repository.saveLocalPathForTag(tag, localPath);
    final index = _directories.indexWhere((d) => d.tag == tag);
    if (index != -1) {
      _directories[index] = _directories[index].copyWith(localPath: localPath);
      notifyListeners();
    }
  }

  Future<bool> updateServerStoragePath(String tag, String newStoragePath) async {
    try {
      await repository.updateStoragePath(tag, newStoragePath);
      final index = _directories.indexWhere((d) => d.tag == tag);
      if (index != -1) {
        _directories[index] = _directories[index].copyWith(storagePath: newStoragePath);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
