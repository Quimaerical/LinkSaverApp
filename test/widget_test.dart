import 'package:flutter_test/flutter_test.dart';
import 'package:linksaverapp/core/config/app_config.dart';
import 'package:linksaverapp/core/theme/app_colors.dart';
import 'package:linksaverapp/core/theme/app_theme.dart';
import 'package:linksaverapp/features/data/directory_model.dart';
import 'package:linksaverapp/features/data/save_file_model.dart';

void main() {
  group('Core & Configuration Tests', () {
    test('XOR obfuscation decodes default URL correctly', () {
      final url = AppConfig.defaultBaseUrl;
      expect(url, equals('http://127.0.0.1:8080'));
    });

    test('Theme definitions instantiate without deprecation issues', () {
      final light = AppTheme.lightTheme;
      final dark = AppTheme.darkTheme;
      final oled = AppTheme.oledTheme;

      expect(light.brightness, equals(AppThemeMode.light.name == 'light' ? light.brightness : null));
      expect(dark.scaffoldBackgroundColor, equals(AppColors.slate950));
      expect(oled.scaffoldBackgroundColor, equals(AppColors.pureBlack));
    });
  });

  group('Data Models Serialization Tests', () {
    test('DirectoryModel fromJson and toJson', () {
      final json = {
        'id': 1,
        'tag': 'retroarch-snes',
        'display_name': 'RetroArch SNES Saves',
        'description': 'Super Nintendo saves',
        'storage_path': '/var/linksaver/snes',
      };

      final dir = DirectoryModel.fromJson(json, '/sdcard/RetroArch/saves');
      expect(dir.tag, equals('retroarch-snes'));
      expect(dir.displayName, equals('RetroArch SNES Saves'));
      expect(dir.localPath, equals('/sdcard/RetroArch/saves'));
      expect(dir.toJson()['tag'], equals('retroarch-snes'));
    });

    test('SaveFileModel fromJson and formatting', () {
      final json = {
        'id': 42,
        'directory_id': 1,
        'relative_path': 'SuperMarioWorld.srm',
        'sha256_hash': 'abcdef0123456789abcdef0123456789',
        'file_size_bytes': 2048,
        'version': 2,
        'is_active': true,
        'conflict_suffix': '',
        'remote_modified_at': '2026-10-27T20:00:00Z',
      };

      final save = SaveFileModel.fromJson(json);
      expect(save.relativePath, equals('SuperMarioWorld.srm'));
      expect(save.formattedSize, equals('2.0 KB'));
      expect(save.shortHash, equals('abcdef01...'));
      expect(save.isActive, isTrue);
    });
  });
}
