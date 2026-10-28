import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/glass_button.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/linksaver_logo.dart';
import '../controllers/directory_controller.dart';
import '../controllers/sync_engine.dart';
import '../controllers/theme_controller.dart';
import '../controllers/vault_controller.dart';
import 'audit_logs_view.dart';
import 'directories_view.dart';
import 'settings_view.dart';
import 'vault_view.dart';

class DashboardView extends StatefulWidget {
  final ThemeController themeController;
  final DirectoryController dirController;
  final SyncEngine syncEngine;
  final VaultController vaultController;
  final ApiClient apiClient;
  final SharedPreferences prefs;

  const DashboardView({
    super.key,
    required this.themeController,
    required this.dirController,
    required this.syncEngine,
    required this.vaultController,
    required this.apiClient,
    required this.prefs,
  });

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  int _currentTabIndex = 0;
  String? _vaultInitialTag;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.dirController.loadDirectories();
    });
  }

  void _navigateToVaultWithTag(String tag) {
    setState(() {
      _vaultInitialTag = tag;
      _currentTabIndex = 1;
    });
    widget.vaultController.selectTag(tag);
  }

  @override
  Widget build(BuildContext context) {
    final mode = widget.themeController.currentMode;
    final isLight = mode == AppThemeMode.light;
    final isOled = mode == AppThemeMode.oled;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: isOled ? AppColors.pureBlack : null,
          gradient: isOled
              ? null
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isLight
                      ? [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)]
                      : [const Color(0xFF0F172A), const Color(0xFF020617)],
                ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar Glassmorphic con Logo y Status Global
              _TopBar(
                themeMode: mode,
                syncEngine: widget.syncEngine,
                dirController: widget.dirController,
              ),

              // Contenido de la Vista Activa
              Expanded(
                child: IndexedStack(
                  index: _currentTabIndex,
                  children: [
                    DirectoriesView(
                      dirController: widget.dirController,
                      syncEngine: widget.syncEngine,
                      themeMode: mode,
                      onOpenVault: _navigateToVaultWithTag,
                    ),
                    VaultView(
                      vaultController: widget.vaultController,
                      dirController: widget.dirController,
                      themeMode: mode,
                      initialTag: _vaultInitialTag,
                    ),
                    AuditLogsView(
                      vaultController: widget.vaultController,
                      themeMode: mode,
                    ),
                    SettingsView(
                      themeController: widget.themeController,
                      apiClient: widget.apiClient,
                      prefs: widget.prefs,
                    ),
                  ],
                ),
              ),

              // Barra de Navegación Inferior Flotante Glassmorphic
              _BottomGlassNavBar(
                currentIndex: _currentTabIndex,
                themeMode: mode,
                onTabSelected: (index) => setState(() => _currentTabIndex = index),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final AppThemeMode themeMode;
  final SyncEngine syncEngine;
  final DirectoryController dirController;

  const _TopBar({
    required this.themeMode,
    required this.syncEngine,
    required this.dirController,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = themeMode == AppThemeMode.light;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: GlassCard(
        themeMode: themeMode,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.sapphireBlue.withValues(alpha: 0.40)),
                  ),
                  child: const Center(
                    child: LinkSaverLogo(size: 24),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LinkSaver',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                        color: isLight ? AppColors.slate900 : Colors.white,
                      ),
                    ),
                    const Text(
                      'Mobile Companion',
                      style: TextStyle(fontSize: 10, color: AppColors.slate400),
                    ),
                  ],
                ),
              ],
            ),
            ListenableBuilder(
              listenable: syncEngine,
              builder: (context, _) {
                if (syncEngine.isSyncing) {
                  return GlassButton(
                    themeMode: themeMode,
                    isPrimary: true,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    isLoading: true,
                    onPressed: null,
                    child: const Text('Sincronizando...'),
                  );
                }
                return GlassButton(
                  themeMode: themeMode,
                  isPrimary: true,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  onPressed: () => syncEngine.syncAll(dirController.directories),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.arrow_2_circlepath, size: 13),
                      SizedBox(width: 5),
                      Text('Sincronizar Todo', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomGlassNavBar extends StatelessWidget {
  final int currentIndex;
  final AppThemeMode themeMode;
  final ValueChanged<int> onTabSelected;

  const _BottomGlassNavBar({
    required this.currentIndex,
    required this.themeMode,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: GlassCard(
        themeMode: themeMode,
        borderRadius: 24,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavBarItem(
              icon: CupertinoIcons.folder_fill,
              label: 'Tags',
              isSelected: currentIndex == 0,
              themeMode: themeMode,
              onTap: () => onTabSelected(0),
            ),
            _NavBarItem(
              icon: CupertinoIcons.archivebox_fill,
              label: 'Bóveda',
              isSelected: currentIndex == 1,
              themeMode: themeMode,
              onTap: () => onTabSelected(1),
            ),
            _NavBarItem(
              icon: CupertinoIcons.list_bullet,
              label: 'Logs',
              isSelected: currentIndex == 2,
              themeMode: themeMode,
              onTap: () => onTabSelected(2),
            ),
            _NavBarItem(
              icon: CupertinoIcons.gear_alt_fill,
              label: 'Ajustes',
              isSelected: currentIndex == 3,
              themeMode: themeMode,
              onTap: () => onTabSelected(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final AppThemeMode themeMode;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.themeMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.sapphireBlue;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: activeColor.withValues(alpha: 0.30), width: 1.0)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? activeColor : AppColors.slate400,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? activeColor : AppColors.slate400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
