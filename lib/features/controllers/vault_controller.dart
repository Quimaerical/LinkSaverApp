import 'package:flutter/foundation.dart';
import '../data/linksaver_repository.dart';
import '../data/save_file_model.dart';
import '../data/sync_log_model.dart';

enum VaultFilterMode { all, activeOnly, historyOnly }

class VaultController extends ChangeNotifier {
  final LinkSaverRepository repository;

  String? _selectedTag;
  List<SaveFileModel> _saves = [];
  List<SyncLogModel> _logs = [];
  bool _isLoading = false;
  String? _errorMessage;

  String _searchQuery = '';
  VaultFilterMode _filterMode = VaultFilterMode.all;

  VaultController(this.repository);

  String? get selectedTag => _selectedTag;
  List<SaveFileModel> get saves => _saves;
  List<SyncLogModel> get logs => _logs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  VaultFilterMode get filterMode => _filterMode;

  List<SaveFileModel> get filteredSaves {
    return _saves.where((s) {
      if (_filterMode == VaultFilterMode.activeOnly && !s.isActive) return false;
      if (_filterMode == VaultFilterMode.historyOnly && s.isActive) return false;
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.trim().toLowerCase();
        final matchPath = s.relativePath.toLowerCase().contains(query);
        final matchName = s.displayName.toLowerCase().contains(query);
        return matchPath || matchName;
      }
      return true;
    }).toList();
  }

  int get activeSavesCount => _saves.where((s) => s.isActive).length;
  int get versionHistoryCount => _saves.where((s) => !s.isActive).length;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilterMode(VaultFilterMode mode) {
    _filterMode = mode;
    notifyListeners();
  }

  Future<void> selectTag(String tag) async {
    _selectedTag = tag;
    _searchQuery = '';
    _filterMode = VaultFilterMode.all;
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
