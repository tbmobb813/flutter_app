import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;

class PresetLoader {
  static final _rng = Random();

  /// Returns a list of asset paths for this mode, e.g. focus_1.json, focus_2.json…
  static Future<List<String>> candidatesFor(String mode) async {
    // Asset manifest lists all bundled assets
    final manifestStr = await rootBundle.loadString('AssetManifest.json');
    final manifest = json.decode(manifestStr) as Map<String, dynamic>;
    final allAssets = manifest.keys.toList();
    final prefix = 'assets/presets/${mode.toLowerCase()}_';
    const suffix = '.json';
    return allAssets
        .where((p) => p.startsWith(prefix) && p.endsWith(suffix))
        .toList()
      ..sort(); // stable order
  }

  static Future<Map<String, dynamic>> loadJson(String assetPath) async {
    final s = await rootBundle.loadString(assetPath);
    return json.decode(s) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>?> tryLoadFirst(String mode) async {
    final list = await candidatesFor(mode);
    if (list.isEmpty) return null;
    return loadJson(list.first);
  }

  static Future<Map<String, dynamic>?> pickRandom(String mode,
      {String? excludeAsset}) async {
    final list = await candidatesFor(mode);
    if (list.isEmpty) return null;
    final filtered = excludeAsset == null
        ? list
        : list.where((p) => p != excludeAsset).toList();
    if (filtered.isEmpty) return null;
    final chosen = filtered[_rng.nextInt(filtered.length)];
    final json = await loadJson(chosen);
    json['_assetPath'] = chosen; // remember which one we used
    return json;
  }
}
