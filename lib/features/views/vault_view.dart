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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialTag != null && widget.initialTag!.isNotEmpty) {
        widget.vaultController.selectTag(widget.initialTag!);
      } else if (widget.dirController.directories.isNotEmpty && widget.vaultController.selectedTag == null) {
        widget.vaultController.selectTag(widget.dirController.directories.first.tag);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.vaultController, widget.dirController]),
      builder: (context, _) {
        final dirs = widget.dirController.directories;
        final selectedTag = widget.vaultController.selectedTag;
        final saves = widget.vaultController.saves;
        final isLoading = widget.vaultController.isLoading;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: 'Bóveda de Guardados',
                subtitle: 'Explora partidas activas, historial de versiones y resuelve colisiones',
                icon: CupertinoIcons.archivebox_fill,
                themeMode: widget.themeMode,
                trailing: selectedTag != null
                    ? GlassButton(
                        themeMode: widget.themeMode,
                        isPrimary: false,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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

              // Selector de Tag
              GlassCard(
                themeMode: widget.themeMode,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Seleccionar Etiqueta de Guardado', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: dirs.any((d) => d.tag == selectedTag) ? selectedTag : null,
                          isExpanded: true,
                          hint: const Text('Selecciona un tag...', style: TextStyle(fontSize: 13, color: AppColors.slate400)),
                          dropdownColor: widget.themeMode == AppThemeMode.oled ? AppColors.pureBlack : AppColors.slate900,
                          icon: const Icon(CupertinoIcons.chevron_down, size: 16, color: AppColors.sapphireBlue),
                          items: dirs.map((d) {
                            return DropdownMenuItem<String>(
                              value: d.tag,
                              child: Text(
                                '${d.displayName} (${d.tag})',
                                style: const TextStyle(fontSize: 13, color: Colors.white),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              widget.vaultController.selectTag(val);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (selectedTag == null)
                GlassCard(
                  themeMode: widget.themeMode,
                  child: const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 30.0),
                      child: Text('Elige una etiqueta arriba para explorar sus partidas.'),
                    ),
                  ),
                )
              else if (saves.isEmpty)
                GlassCard(
                  themeMode: widget.themeMode,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30.0),
                      child: Text('No hay archivos de guardado en la bóveda para "$selectedTag".'),
                    ),
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Partidas y Versiones ($selectedTag)', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        StatusPill(label: '${saves.length} archivos', variant: PillVariant.info),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...saves.map((s) => _SaveFileItem(
                          saveFile: s,
                          themeMode: widget.themeMode,
                          onRestore: () => _handleRestore(s),
                        )),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleRestore(SaveFileModel save) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Restaurar Versión'),
        content: Text('¿Deseas restaurar la versión #${save.version} (${save.conflictSuffix}) como la partida activa?'),
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
          const SnackBar(content: Text('Versión restaurada con éxito')),
        );
      }
    }
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          saveFile.relativePath,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      StatusPill(
                        label: saveFile.isActive ? 'Activo' : 'v${saveFile.version} ${saveFile.conflictSuffix}',
                        variant: saveFile.isActive ? PillVariant.success : PillVariant.warning,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'SHA: ${saveFile.shortHash}  •  ${saveFile.formattedSize}',
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: themeMode == AppThemeMode.light ? AppColors.slate600 : AppColors.slate400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Modificado: ${saveFile.remoteModifiedAt.toLocal().toString().split('.').first}',
                    style: TextStyle(
                      fontSize: 10,
                      color: themeMode == AppThemeMode.light ? AppColors.slate500 : AppColors.slate500,
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
