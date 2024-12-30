// This source code is a part of Project Violet.
// Copyright (C) 2020-2024. violet-team. Licensed under the Apache-2.0 License.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:http/http.dart' as http;
import 'package:violet/component/eh/eh_parser.dart';

void main() {
  setUp(() async {
    WidgetsFlutterBinding.ensureInitialized();
  });

  test('Test Parse ExHentai', () async {
    final html = (await http.get(
            Uri.parse('https://exhentai.org/g/2504057/6757b3c4b8/'),
            headers: {
          'Cookie':
              'ipb_member_id=2742770; ipb_pass_hash=622fcc2be82c922135bb0516e0ee497d; sk=t8inbzaqn45ttyn9f78eanzuqizh; igneous=rcrmcztqgf1v8p1e0'
        }))
        .body;

    expect(EHParser.parseArticleData(html).comment!.isNotEmpty, true);
  });
}
