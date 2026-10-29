import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/glass_button.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/status_pill.dart';
import '../controllers/directory_controller.dart';
import '../controllers/vault_controller.dart';
import '../data/directory_model.dart';
import '../data/save_file_model.dart';

class VaultView extends StatefulWidget {
  final VaultController vaultController;
  final DirectoryController dirController;
  final AppThemeMode themeMode;
  final String? initialTag;

  const VaultView({
    super.key,
    required this.vaultController,
    required this.dirController,
    required this.themeMode,
    this.initialTag,
  });

  @override
  State<VaultView> createState() => _VaultViewState();
}

class _VaultViewState extends State<VaultView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSelection();
    });
  }

  void _initSelection() {
    if (widget.initialTag != null && widget.initialTag!.isNotEmpty) {
      widget.vaultController.selectTag(widget.initialTag!);
    } else if (widget.dirController.directories.isNotEmpty && widget.vaultController.selectedTag == null) {
      widget.vaultController.selectTag(widget.dirController.directories.first.tag);
    } else if (widget.dirController.directories.isEmpty) {
      widget.dirController.loadDirectories().then((_) {
        if (mounted && widget.dirController.directories.isNotEmpty && widget.vaultController.selectedTag == null) {
          widget.vaultController.selectTag(widget.dirController.directories.first.tag);
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    await widget.dirController.loadDirectories();
    final tag = widget.vaultController.selectedTag;
    if (tag != null) {
      await widget.vaultController.loadVaultForTag(tag);
    } else if (widget.dirController.directories.isNotEmpty) {
      await widget.vaultController.selectTag(widget.dirController.directories.first.tag);
    }
  }

  Future<void> _handleRestore(SaveFileModel save) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Restaurar Versión'),
        content: Text('¿Deseas restaurar la versión #${save.version} (${save.conflictSuffix.isNotEmpty ? save.conflictSuffix : 'historial'}) como la partida activa de "${save.displayName}"?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Restaurar'),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final ok = await widget.vaultController.restoreVersion(save.id);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Versión restaurada con éxito en el servidor')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.vaultController, widget.dirController]),
      builder: (context, _) {
        final dirs = widget.dirController.directories;
        final selectedTag = widget.vaultController.selectedTag;
        final filteredSaves = widget.vaultController.filteredSaves;
        final totalSaves = widget.vaultController.saves;
        final isLoading = widget.vaultController.isLoading || widget.dirController.isLoading;
        final currentFilter = widget.vaultController.filterMode;

        // Auto-select first tag if selection became available
        if (selectedTag == null && dirs.isNotEmpty && !isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && widget.vaultController.selectedTag == null) {
              widget.vaultController.selectTag(dirs.first.tag);
            }
          });
        }

        DirectoryModel? selectedDir;
        if (selectedTag != null && dirs.any((d) => d.tag == selectedTag)) {
          selectedDir = dirs.firstWhere((d) => d.tag == selectedTag);
        }

        return RefreshIndicator(
          onRefresh: _handleRefresh,
          color: AppColors.sapphireBlue,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PageHeader(
                  title: 'Bóveda de Guardados',
                  subtitle: 'Explora partidas almacenadas en el servidor, versiones históricas y resuelve colisiones',
                  icon: CupertinoIcons.archivebox_fill,
                  themeMode: widget.themeMode,
                  trailing: selectedTag != null
                      ? GlassButton(
                          themeMode: widget.themeMode,
                          isPrimary: false,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          onPressed: () => widget.vaultController.loadVaultForTag(selectedTag),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(CupertinoIcons.arrow_clockwise, size: 14),
                              SizedBox(width: 6),
                              Text('Refrescar'),
                            ],
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 18),

                // Sección 1: Directorios almacenados en el Backend
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Directorios en el Servidor',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    StatusPill(
                      label: '${dirs.length} registrados',
                      variant: dirs.isNotEmpty ? PillVariant.info : PillVariant.neutral,
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (dirs.isEmpty && isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (dirs.isEmpty)
                  GlassCard(
                    themeMode: widget.themeMode,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          const Icon(CupertinoIcons.folder_badge_minus, size: 40, color: AppColors.slate400),
                          const SizedBox(height: 12),
                          const Text(
                            'No se encontraron directorios en el backend',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Verifica la conexión al servidor o crea un tag desde la pestaña Directorios.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: AppColors.slate400),
                          ),
                          const SizedBox(height: 14),
                          GlassButton(
                            themeMode: widget.themeMode,
                            onPressed: () => widget.dirController.loadDirectories(),
                            child: const Text('Cargar Directorios'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 92,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: dirs.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 12),
                      itemBuilder: (context, idx) {
                        final dir = dirs[idx];
                        final isSelected = dir.tag == selectedTag;
                        return _DirectoryTagCard(
                          directory: dir,
                          isSelected: isSelected,
                          themeMode: widget.themeMode,
                          onTap: () => widget.vaultController.selectTag(dir.tag),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 24),

                // Sección 2: Búsqueda y Filtros de Archivos
                if (selectedTag != null) ...[
                  GlassCard(
                    themeMode: widget.themeMode,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Barra de búsqueda
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                          ),
                          child: Row(
                            children: [
                              const Icon(CupertinoIcons.search, size: 16, color: AppColors.slate400),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  style: const TextStyle(fontSize: 13, color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: 'Buscar archivo de guardado en "$selectedTag"...',
                                    hintStyle: const TextStyle(fontSize: 12, color: AppColors.slate400),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                  onChanged: (val) => widget.vaultController.setSearchQuery(val),
                                ),
                              ),
                              if (_searchController.text.isNotEmpty)
                                GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                    widget.vaultController.setSearchQuery('');
                                  },
                                  child: const Icon(CupertinoIcons.clear_circled_solid, size: 16, color: AppColors.slate400),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Filtros y contadores
                        Row(
                          children: [
                            _FilterChip(
                              label: 'Todos (${totalSaves.length})',
                              isSelected: currentFilter == VaultFilterMode.all,
                              onTap: () => widget.vaultController.setFilterMode(VaultFilterMode.all),
                              themeMode: widget.themeMode,
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Activos (${widget.vaultController.activeSavesCount})',
                              isSelected: currentFilter == VaultFilterMode.activeOnly,
                              onTap: () => widget.vaultController.setFilterMode(VaultFilterMode.activeOnly),
                              themeMode: widget.themeMode,
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Historial (${widget.vaultController.versionHistoryCount})',
                              isSelected: currentFilter == VaultFilterMode.historyOnly,
                              onTap: () => widget.vaultController.setFilterMode(VaultFilterMode.historyOnly),
                              themeMode: widget.themeMode,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Cabecera de partidas
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selectedDir != null
                            ? '${selectedDir.displayName} ($selectedTag)'
                            : 'Partidas ($selectedTag)',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      StatusPill(
                        label: '${filteredSaves.length} mostrados',
                        variant: filteredSaves.isNotEmpty ? PillVariant.success : PillVariant.warning,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                // Sección 3: Contenido de Archivos
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (selectedTag == null)
                  GlassCard(
                    themeMode: widget.themeMode,
                    child: const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 36.0),
                        child: Text(
                          'Selecciona un directorio arriba para explorar sus archivos almacenados.',
                          style: TextStyle(color: AppColors.slate300),
                        ),
                      ),
                    ),
                  )
                else if (totalSaves.isEmpty)
                  GlassCard(
                    themeMode: widget.themeMode,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 36.0, horizontal: 16.0),
                        child: Column(
                          children: [
                            const Icon(CupertinoIcons.tray, size: 40, color: AppColors.slate400),
                            const SizedBox(height: 12),
                            Text(
                              'No hay partidas guardadas en el servidor para "$selectedTag".',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Sube o sincroniza archivos desde tus dispositivos para comenzar a respaldar.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: AppColors.slate400),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else if (filteredSaves.isEmpty)
                  GlassCard(
                    themeMode: widget.themeMode,
                    child: const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 30.0),
                        child: Text(
                          'No se encontraron archivos que coincidan con la búsqueda o filtro seleccionado.',
                          style: TextStyle(color: AppColors.slate300, fontSize: 13),
                        ),
                      ),
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: filteredSaves
                        .map((s) => _SaveFileItem(
                              saveFile: s,
                              themeMode: widget.themeMode,
                              onRestore: () => _handleRestore(s),
                            ))
                        .toList(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DirectoryTagCard extends StatelessWidget {
  final DirectoryModel directory;
  final bool isSelected;
  final AppThemeMode themeMode;
  final VoidCallback onTap;

  const _DirectoryTagCard({
    required this.directory,
    required this.isSelected,
    required this.themeMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isOled = themeMode == AppThemeMode.oled;
    final borderColor = isSelected
        ? AppColors.sapphireBlue
        : Colors.white.withValues(alpha: isOled ? 0.15 : 0.20);
    final bgColor = isSelected
        ? AppColors.sapphireBlue.withValues(alpha: isOled ? 0.25 : 0.20)
        : (isOled ? AppColors.slate950 : Colors.white.withValues(alpha: 0.05));

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 170,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: isSelected ? 1.8 : 1.0),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.sapphireBlue.withValues(alpha: 0.30),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(
                  isSelected ? CupertinoIcons.folder_fill : CupertinoIcons.folder,
                  size: 16,
                  color: isSelected ? AppColors.sapphireBlue : AppColors.slate400,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    directory.displayName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.30),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                directory.tag,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: isSelected ? AppColors.sapphireBlue : AppColors.slate300,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final AppThemeMode themeMode;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.themeMode,
  });

  @override
  Widget build(BuildContext context) {
    final isOled = themeMode == AppThemeMode.oled;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.sapphireBlue.withValues(alpha: 0.25)
              : (isOled ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.15)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.sapphireBlue : Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.slate400,
          ),
        ),
      ),
    );
  }
}

class _SaveFileItem extends StatelessWidget {
  final SaveFileModel saveFile;
  final AppThemeMode themeMode;
  final VoidCallback onRestore;

  const _SaveFileItem({
    required this.saveFile,
    required this.themeMode,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final breadcrumb = saveFile.directoryBreadcrumb;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: GlassCard(
        themeMode: themeMode,
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: saveFile.isActive
                    ? AppColors.successGreen.withValues(alpha: 0.15)
                    : AppColors.warningAmber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                saveFile.isActive ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.clock,
                size: 20,
                color: saveFile.isActive ? AppColors.successGreen : AppColors.warningAmber,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (breadcrumb.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(CupertinoIcons.folder, size: 11, color: AppColors.slate400),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            breadcrumb,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.slate400,
                              fontFamily: 'monospace',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          saveFile.displayName,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      StatusPill(
                        label: saveFile.isActive
                            ? 'Activo'
                            : (saveFile.conflictSuffix.isNotEmpty
                                ? 'v${saveFile.version} • ${saveFile.conflictSuffix}'
                                : 'v${saveFile.version}'),
                        variant: saveFile.isActive ? PillVariant.success : PillVariant.warning,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          saveFile.fileExtension,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.slate300,
                          ),
                        ),
                      ),
                      Text(
                        saveFile.formattedSize,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: themeMode == AppThemeMode.light ? AppColors.slate600 : AppColors.slate300,
                        ),
                      ),
                      Text(
                        'SHA: ${saveFile.shortHash}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                          color: AppColors.slate400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Modificado: ${saveFile.remoteModifiedAt.toLocal().toString().split('.').first}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.slate400,
                    ),
                  ),
                ],
              ),
            ),
            if (!saveFile.isActive) ...[
              const SizedBox(width: 8),
              GlassButton(
                themeMode: themeMode,
                isPrimary: false,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                onPressed: onRestore,
                child: const Text('Restaurar', style: TextStyle(fontSize: 11)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
