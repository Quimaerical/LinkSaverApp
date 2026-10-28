import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/glass_button.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/glass_input.dart';
import '../../shared/widgets/page_header.dart';
import '../controllers/theme_controller.dart';

class SettingsView extends StatefulWidget {
  final ThemeController themeController;
  final ApiClient apiClient;
  final SharedPreferences prefs;

  const SettingsView({
    super.key,
    required this.themeController,
    required this.apiClient,
    required this.prefs,
  });

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late final TextEditingController _urlController;
  String? _pingResult;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.apiClient.baseUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveUrl() async {
    final newUrl = _urlController.text.trim();
    if (newUrl.isEmpty) return;

    widget.apiClient.updateBaseUrl(newUrl);
    await widget.prefs.setString('api_base_url', newUrl);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('URL del servidor actualizada')),
    );
  }

  Future<void> _handleTestPing() async {
    setState(() {
      _isTesting = true;
      _pingResult = null;
    });

    try {
      final res = await widget.apiClient.get('/api/v1/ping');
      if (!mounted) return;
      setState(() {
        _isTesting = false;
        _pingResult = 'Conexión exitosa: ${res is Map ? res['message'] ?? 'OK' : 'OK'}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isTesting = false;
        _pingResult = 'Fallo al conectar: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = widget.themeController.currentMode;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Ajustes y Personalización',
            subtitle: 'Configura el tema visual y los parámetros del servidor LinkSaverBack',
            icon: CupertinoIcons.gear_alt_fill,
            themeMode: mode,
          ),
          const SizedBox(height: 18),

          // Selector de Tema Visual (Claro / Oscuro / OLED)
          GlassCard(
            themeMode: mode,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tema Visual (Paleta Azul y Gris)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Elige la estética que mejor se adapte a tu pantalla y preferencias',
                  style: TextStyle(
                    fontSize: 12,
                    color: mode == AppThemeMode.light ? AppColors.slate600 : AppColors.slate400,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _ThemeOptionCard(
                        title: 'Modo Claro',
                        subtitle: 'Gris perla y azul cobalto',
                        icon: CupertinoIcons.sun_max_fill,
                        isSelected: mode == AppThemeMode.light,
                        activeColor: AppColors.primaryBlue,
                        onTap: () => widget.themeController.setThemeMode(AppThemeMode.light),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ThemeOptionCard(
                        title: 'Modo Oscuro',
                        subtitle: 'Slate noche y zafiro',
                        icon: CupertinoIcons.moon_fill,
                        isSelected: mode == AppThemeMode.dark,
                        activeColor: AppColors.sapphireBlue,
                        onTap: () => widget.themeController.setThemeMode(AppThemeMode.dark),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ThemeOptionCard(
                        title: 'OLED Dark',
                        subtitle: 'Negro puro (#000000)',
                        icon: CupertinoIcons.circle_fill,
                        isSelected: mode == AppThemeMode.oled,
                        activeColor: AppColors.iceBlue,
                        onTap: () => widget.themeController.setThemeMode(AppThemeMode.oled),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Configuración del Servidor Backend
          GlassCard(
            themeMode: mode,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Conexión al Servidor LinkSaverBack',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Dirección IP o URL de la API de sincronización',
                  style: TextStyle(
                    fontSize: 12,
                    color: mode == AppThemeMode.light ? AppColors.slate600 : AppColors.slate400,
                  ),
                ),
                const SizedBox(height: 14),
                GlassInput(
                  controller: _urlController,
                  label: 'Endpoint Base',
                  hintText: 'http://192.168.1.100:8080',
                  themeMode: mode,
                  isMonospace: true,
                  prefixIcon: CupertinoIcons.link,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: GlassButton(
                        themeMode: mode,
                        isPrimary: false,
                        isLoading: _isTesting,
                        onPressed: _handleTestPing,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.waveform_path_ecg, size: 16),
                            SizedBox(width: 6),
                            Text('Probar Conexión'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GlassButton(
                        themeMode: mode,
                        isPrimary: true,
                        onPressed: _handleSaveUrl,
                        child: const Text('Guardar'),
                      ),
                    ),
                  ],
                ),
                if (_pingResult != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _pingResult!,
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: _pingResult!.startsWith('Conexión') ? AppColors.successGreen : AppColors.errorRose,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _ThemeOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.18) : Colors.black.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? activeColor : Colors.white.withValues(alpha: 0.10),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: isSelected ? activeColor : AppColors.slate400),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.slate300,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 9, color: AppColors.slate500),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
