// This source code is a part of Project Violet.
// Copyright (C) 2020-2024. violet-team. Licensed under the Apache-2.0 License.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:violet/component/eh/eh_parser.dart';
import 'package:violet/component/hentai.dart';
import 'package:violet/database/query.dart';
import 'package:violet/settings/settings.dart';

void main() {
  setUp(() async {
    WidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({
      'eh_cookies':
          'ipb_member_id=2742770; ipb_pass_hash=622fcc2be82c922135bb0516e0ee497d; sk=t8inbzaqn45ttyn9f78eanzuqizh; igneous=rcrmcztqgf1v8p1e0'
    });

    Settings.searchCategory = 1;
    Settings.searchExpunged = false;
    Settings.ignoreTimeout = true;
    Settings.includeTagNetwork = false;
    Settings.excludeTagNetwork = false;
  });

  test('EHentai Gallery Parse', () async {
    final result =
        await HentaiManager.searchEHentai('"female:big breasts"', 0, false);
    expect(result.length >= 25, true);
  });

  test('ExHentai Gallery Parse', () async {
    final result =
        await HentaiManager.searchEHentai('"female:big breasts"', 0, true);
    expect(result.length >= 25, true);
  });

  test('EHentai Get Original Image Address', () async {
    const body =
        'lass="mr" /> <a href="https://e-hentai.org/fullimg.php?gid=1344011&amp;page=2&amp;key=3m0vqlp9ta0">Download original 2078 x 3000 4.44 MB source<';
    const result =
        'https://e-hentai.org/fullimg.php?gid=1344011&amp;page=2&amp;key=3m0vqlp9ta0';

    expect(EHParser.getOriginalImageAddress(body), result);
  });

  test('EHentai Get Thumbnail Images Address', () async {
    const body = '''
Page 20: 020.jpg" src="https://exhentai.org/t/66/55/6655fb520e13eff74ebf9aa49c210cfb7fdfc1d9-1069560-2120-3000-jpg_l.jpg" /></a></div><
 src="https://ehgt.org/f5/f8/f5f8425827e4c8c0658385b4d3cb80adc23e1b94-518399-1280-1810-jpg_l.jpg" /></a
        ''';

    expect(EHParser.getThumbnailImages(body).length, 2);
  });

  test('EHentai Image Provider', () async {
    // https://exhentai.org/g/3175025/58a5600a77/
    Settings.routingRule = ['ExHentai', 'EHentai'];
    final query = QueryResult(result: {'Id': 3175025, 'EHash': '58a5600a77'});
    final provider = await HentaiManager.getImageProvider(query);
    expect(provider.length(), 25);
  });
}
