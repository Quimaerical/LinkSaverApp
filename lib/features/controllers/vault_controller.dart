import 'package:flutter/foundation.dart';
import '../data/linksaver_repository.dart';
import '../data/save_file_model.dart';
import '../data/sync_log_model.dart';

class VaultController extends ChangeNotifier {
  final LinkSaverRepository repository;

  String? _selectedTag;
  List<SaveFileModel> _saves = [];
  List<SyncLogModel> _logs = [];
  bool _isLoading = false;
  String? _errorMessage;

  VaultController(this.repository);

  String? get selectedTag => _selectedTag;
  List<SaveFileModel> get saves => _saves;
  List<SyncLogModel> get logs => _logs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> selectTag(String tag) async {
    _selectedTag = tag;
    await loadVaultForTag(tag);
  }

  Future<void> loadVaultForTag(String tag) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _saves = await repository.getVaultHistory(tag);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> restoreVersion(int fileId) async {
    if (_selectedTag == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      await repository.restoreSaveVersion(_selectedTag!, fileId);
      await loadVaultForTag(_selectedTag!);
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

  Future<void> loadAuditLogs({int limit = 40}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _logs = await repository.getAuditLogs(limit: limit);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
