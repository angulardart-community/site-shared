import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';

import 'src/excerpter.dart';
import 'src/util/line.dart';

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
    final raw = excerpter.weave().excerpts;

    if (raw.isNotEmpty) {
      final json = jsonEncode(raw.map((region, lines) =>
          MapEntry<String, String>(region, lines.join(eol))));
      await buildStep.writeAsString(outputAssetId, json);
      log.info('wrote $outputAssetId');
    }
  }

  @override
  Map<String, List<String>> get buildExtensions => {
        '': [outputExtension]
      };
}
