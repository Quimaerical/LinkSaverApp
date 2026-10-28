import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/glass_button.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/glass_input.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/status_pill.dart';
import '../controllers/directory_controller.dart';
import '../controllers/sync_engine.dart';
import '../data/directory_model.dart';

class DirectoriesView extends StatefulWidget {
  final DirectoryController dirController;
  final SyncEngine syncEngine;
  final AppThemeMode themeMode;
  final ValueChanged<String>? onOpenVault;

  const DirectoriesView({
    super.key,
    required this.dirController,
    required this.syncEngine,
    required this.themeMode,
    this.onOpenVault,
  });

  @override
  State<DirectoriesView> createState() => _DirectoriesViewState();
}

class _DirectoriesViewState extends State<DirectoriesView> {
  final _tagController = TextEditingController();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _serverPathController = TextEditingController();

  bool _isRegistering = false;

  @override
  void dispose() {
    _tagController.dispose();
    _nameController.dispose();
    _descController.dispose();
    _serverPathController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final tag = _tagController.text.trim();
    final name = _nameController.text.trim();
    if (tag.isEmpty || name.isEmpty) return;

    setState(() => _isRegistering = true);
    final success = await widget.dirController.registerDirectory(
      tag: tag,
      displayName: name,
      description: _descController.text.trim(),
      storagePath: _serverPathController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isRegistering = false);

    if (success) {
      _tagController.clear();
      _nameController.clear();
      _descController.clear();
      _serverPathController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tag registrado correctamente')),
      );
    }
  }

  Future<void> _pickLocalFolder(DirectoryModel dir) async {
    final selectedDir = await FilePicker.getDirectoryPath(
      dialogTitle: 'Selecciona la carpeta local para ${dir.displayName}',
    );
    if (selectedDir != null && mounted) {
      await widget.dirController.setLocalPath(dir.tag, selectedDir);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.dirController, widget.syncEngine]),
      builder: (context, _) {
        final dirs = widget.dirController.directories;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: 'Mapeo de Directorios',
                subtitle: 'Asocia etiquetas lógicas con carpetas locales y sincroniza partidas',
                icon: CupertinoIcons.folder_badge_plus,
                themeMode: widget.themeMode,
                trailing: GlassButton(
                  themeMode: widget.themeMode,
                  onPressed: () => widget.dirController.loadDirectories(),
                  isPrimary: false,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.arrow_clockwise, size: 14),
                      SizedBox(width: 6),
                      Text('Refrescar'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Formulario Glassmorphic de Registro
              GlassCard(
                themeMode: widget.themeMode,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Registrar Nueva Etiqueta (Tag)',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Crea una etiqueta común entre Nintendo Switch, PC y móvil',
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.themeMode == AppThemeMode.light ? AppColors.slate600 : AppColors.slate400,
                      ),
                    ),
                    const SizedBox(height: 14),
                    GlassInput(
                      controller: _tagController,
                      label: 'Tag Lógico (ID único)',
                      hintText: 'ej. retroarch-gba',
                      isMonospace: true,
                      themeMode: widget.themeMode,
                      prefixIcon: CupertinoIcons.tag,
                    ),
                    const SizedBox(height: 12),
                    GlassInput(
                      controller: _nameController,
                      label: 'Nombre Descriptivo',
                      hintText: 'ej. RetroArch GBA Saves',
                      themeMode: widget.themeMode,
                      prefixIcon: CupertinoIcons.text_quote,
                    ),
                    const SizedBox(height: 12),
                    GlassInput(
                      controller: _descController,
                      label: 'Descripción (Opcional)',
                      hintText: 'ej. Partidas de Pokémon y Zelda',
                      themeMode: widget.themeMode,
                      prefixIcon: CupertinoIcons.doc_text,
                    ),
                    const SizedBox(height: 16),
                    GlassButton(
                      themeMode: widget.themeMode,
                      isLoading: _isRegistering,
                      onPressed: _handleRegister,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.add, size: 16),
                          SizedBox(width: 8),
                          Text('Crear Etiqueta'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Lista de Directorios Registrados
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Etiquetas Registradas',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  StatusPill(
                    label: '${dirs.length} tags',
                    variant: PillVariant.info,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (dirs.isEmpty)
                GlassCard(
                  themeMode: widget.themeMode,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Text(
                        'No hay etiquetas registradas aún.',
                        style: TextStyle(
                          color: widget.themeMode == AppThemeMode.light ? AppColors.slate500 : AppColors.slate400,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                )
              else
                ...dirs.map((dir) => _DirectoryItemCard(
                      directory: dir,
                      themeMode: widget.themeMode,
                      isSyncing: widget.syncEngine.isSyncing,
                      onSelectFolder: () => _pickLocalFolder(dir),
                      onSync: () => widget.syncEngine.syncDirectory(dir),
                      onOpenVault: widget.onOpenVault != null ? () => widget.onOpenVault!(dir.tag) : null,
                    )),
            ],
          ),
        );
      },
    );
  }
}

class _DirectoryItemCard extends StatelessWidget {
  final DirectoryModel directory;
  final AppThemeMode themeMode;
  final bool isSyncing;
  final VoidCallback onSelectFolder;
  final VoidCallback onSync;
  final VoidCallback? onOpenVault;

  const _DirectoryItemCard({
    required this.directory,
    required this.themeMode,
    required this.isSyncing,
    required this.onSelectFolder,
    required this.onSync,
    this.onOpenVault,
  });

  @override
  Widget build(BuildContext context) {
    final hasLocal = directory.localPath != null && directory.localPath!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GlassCard(
        themeMode: themeMode,
        isInteractive: true,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        directory.displayName,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      StatusPill(label: directory.tag, variant: PillVariant.neutral),
                    ],
                  ),
                ),
                if (onOpenVault != null)
                  GlassButton(
                    themeMode: themeMode,
                    isPrimary: false,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    onPressed: onOpenVault,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.archivebox, size: 14),
                        SizedBox(width: 4),
                        Text('Bóveda'),
                      ],
                    ),
                  ),
              ],
            ),
            if (directory.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                directory.description,
                style: TextStyle(
                  fontSize: 12,
                  color: themeMode == AppThemeMode.light ? AppColors.slate600 : AppColors.slate400,
                ),
              ),
            ],
            const SizedBox(height: 10),

            // Ruta local
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    hasLocal ? CupertinoIcons.folder_fill : CupertinoIcons.folder_badge_minus,
                    size: 16,
                    color: hasLocal ? AppColors.sapphireBlue : AppColors.slate500,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hasLocal ? directory.localPath! : 'Sin ruta local asignada',
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: hasLocal
                            ? (themeMode == AppThemeMode.light ? AppColors.slate800 : AppColors.slate200)
                            : AppColors.slate500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: GlassButton(
                    themeMode: themeMode,
                    isPrimary: false,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    onPressed: onSelectFolder,
                    child: Text(hasLocal ? 'Cambiar Carpeta' : 'Asignar Carpeta Local'),
                  ),
                ),
                const SizedBox(width: 10),
                GlassButton(
                  themeMode: themeMode,
                  isPrimary: true,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  onPressed: hasLocal && !isSyncing ? onSync : null,
                  child: const Row(
                    children: [
                      Icon(CupertinoIcons.arrow_2_circlepath, size: 14),
                      SizedBox(width: 6),
                      Text('Sincronizar'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
