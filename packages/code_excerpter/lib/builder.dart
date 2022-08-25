import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';

import 'src/excerpter.dart';

Builder builder(BuilderOptions options) => CodeExcerptBuilder(options);

class CodeExcerptBuilder implements Builder {
  static const outputExtension = '.excerpt.json';

  final BuilderOptions? options;

  CodeExcerptBuilder([this.options]);

  @override
  Future<void> build(BuildStep buildStep) async {
    final assetId = buildStep.inputId;
    if (assetId.package.startsWith(r'$') || assetId.path.endsWith(r'$')) return;

    final String content;
    try {
      content = await buildStep.readAsString(assetId);
    } on FormatException {
      log.finest('Skipped ${assetId.path} due to failing to read as string.');
      return;
    }

    final outputAssetId = assetId.addExtension(outputExtension);

    final excerpter = Excerpter(assetId.path, content);
    final yaml = _toYaml(excerpter.weave().excerpts);
    if (yaml.isNotEmpty) {
      await buildStep.writeAsString(outputAssetId, yaml);
      log.info('wrote $outputAssetId');
    } else {
      log.warning('$outputAssetId has no excerpts');
    }
  }

  @override
  Map<String, List<String>> get buildExtensions => {
        '': [outputExtension],
      };

  String _toYaml(Map<String, List<String>> excerpts) {
    if (excerpts.isEmpty) return '';

    final result = <String, dynamic>{};

    excerpts.forEach((name, lines) {
      result[name] = lines.join('\n');
    });

    return jsonEncode(result);
  }
}
