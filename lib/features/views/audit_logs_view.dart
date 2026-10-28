import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/glass_button.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/status_pill.dart';
import '../controllers/vault_controller.dart';
import '../data/sync_log_model.dart';

class AuditLogsView extends StatefulWidget {
  final VaultController vaultController;
  final AppThemeMode themeMode;

  const AuditLogsView({
    super.key,
    required this.vaultController,
    required this.themeMode,
  });

  @override
  State<AuditLogsView> createState() => _AuditLogsViewState();
}

class _AuditLogsViewState extends State<AuditLogsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.vaultController.loadAuditLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.vaultController,
      builder: (context, _) {
        final logs = widget.vaultController.logs;
        final isLoading = widget.vaultController.isLoading;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: 'Auditoría de Sincronización',
                subtitle: 'Historial de actividades reportadas por Switch, Android y PC',
                icon: CupertinoIcons.list_bullet_below_rectangle,
                themeMode: widget.themeMode,
                trailing: GlassButton(
                  themeMode: widget.themeMode,
                  isPrimary: false,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  onPressed: () => widget.vaultController.loadAuditLogs(),
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

              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (logs.isEmpty)
                GlassCard(
                  themeMode: widget.themeMode,
                  child: const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 30.0),
                      child: Text('No hay registros de auditoría aún en el servidor.'),
                    ),
                  ),
                )
              else
                ...logs.map((log) => _LogItemCard(
                      log: log,
                      themeMode: widget.themeMode,
                    )),
            ],
          ),
        );
      },
    );
  }
}

class _LogItemCard extends StatelessWidget {
  final SyncLogModel log;
  final AppThemeMode themeMode;

  const _LogItemCard({
    required this.log,
    required this.themeMode,
  });

  @override
  Widget build(BuildContext context) {
    final isSuccess = log.status == 'success';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: GlassCard(
        themeMode: themeMode,
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSuccess
                    ? AppColors.successGreen.withValues(alpha: 0.15)
                    : AppColors.errorRose.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isSuccess ? CupertinoIcons.check_mark_circled : CupertinoIcons.xmark_circle,
                size: 18,
                color: isSuccess ? AppColors.successGreen : AppColors.errorRose,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      StatusPill(
                        label: log.clientType,
                        variant: log.clientType.toLowerCase().contains('switch')
                            ? PillVariant.error
                            : PillVariant.info,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        log.action,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                  if (log.details.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      log.details,
                      style: TextStyle(
                        fontSize: 11,
                        color: themeMode == AppThemeMode.light ? AppColors.slate700 : AppColors.slate300,
                      ),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    log.timestamp.toLocal().toString().split('.').first,
                    style: TextStyle(
                      fontSize: 10,
                      color: themeMode == AppThemeMode.light ? AppColors.slate500 : AppColors.slate500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
