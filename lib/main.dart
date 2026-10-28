import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/api/api_client.dart';
import 'core/config/app_config.dart';
import 'features/controllers/directory_controller.dart';
import 'features/controllers/sync_engine.dart';
import 'features/controllers/theme_controller.dart';
import 'features/controllers/vault_controller.dart';
import 'features/data/linksaver_repository.dart';
import 'features/views/dashboard_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  final savedBaseUrl = prefs.getString('api_base_url') ?? AppConfig.defaultBaseUrl;
  final apiClient = ApiClient(baseUrl: savedBaseUrl);
  final repository = HttpLinkSaverRepository(apiClient: apiClient, prefs: prefs);

  final themeController = ThemeController(prefs);
  final dirController = DirectoryController(repository);
  final syncEngine = SyncEngine(repository);
  final vaultController = VaultController(repository);

  runApp(LinkSaverApp(
    themeController: themeController,
    dirController: dirController,
    syncEngine: syncEngine,
    vaultController: vaultController,
    apiClient: apiClient,
    prefs: prefs,
  ));
}

class LinkSaverApp extends StatelessWidget {
  final ThemeController themeController;
  final DirectoryController dirController;
  final SyncEngine syncEngine;
  final VaultController vaultController;
  final ApiClient apiClient;
  final SharedPreferences prefs;

  const LinkSaverApp({
    super.key,
    required this.themeController,
    required this.dirController,
    required this.syncEngine,
    required this.vaultController,
    required this.apiClient,
    required this.prefs,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) {
        return MaterialApp(
          title: AppConfig.appName,
          debugShowCheckedModeBanner: false,
          theme: themeController.themeData,
          home: DashboardView(
            themeController: themeController,
            dirController: dirController,
            syncEngine: syncEngine,
            vaultController: vaultController,
            apiClient: apiClient,
            prefs: prefs,
          ),
        );
      },
    );
  }
}
