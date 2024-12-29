// This source code is a part of Project Violet.
// Copyright (C) 2020-2024. violet-team. Licensed under the Apache-2.0 License.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_js/flutter_js.dart';
import 'package:html/parser.dart';
import 'package:violet/component/hitomi/hitomi.dart';
import 'package:violet/context/viewer_context.dart';
import 'package:violet/log/log.dart';
import 'package:violet/network/wrapper.dart' as http;
import 'package:violet/script/freezed/script_model.dart';
import 'package:violet/script/script_webview.dart';
import 'package:violet/util/helper.dart';
import 'package:violet/widgets/article_item/image_provider_manager.dart';

class ScriptManager {
  static const String scriptNoCDNUrl =
      'https://github.com/project-violet/scripts/blob/main/hitomi_get_image_list_v3.js';
  static const String scriptUrl =
      'https://raw.githubusercontent.com/project-violet/scripts/main/hitomi_get_image_list_v3.js';
  static const String scriptV4Url =
      'https://github.com/project-violet/scripts/raw/main/hitomi_get_image_list_v4_model.js';
  static bool enableV4 = false;
  static String? v4Cache;
  static String? scriptCache;
  static late JavascriptRuntime runtime;
  static late DateTime latestUpdate;

  static Future<void> init() async {
    Future fallbackFail(Future Function() fn) async {
      await catchUnwind(fn, (e, st) async {
        await Logger.warning('[ScriptManager-init] W: $e\n'
            '$st');
        debugPrint(e.toString());
      });
    }

    fallbackFail(() async {
      final scriptHtml = (await http.get(scriptNoCDNUrl)).body;
      scriptCache = json.decode(parse(scriptHtml)
          .querySelector("script[data-target='react-app.embeddedData']")!
          .text)['payload']['blob']['rawBlob'];
    });

    if (scriptCache == null) {
      fallbackFail(() async {
        scriptCache = (await http.get(scriptUrl)).body;
      });
    }

    fallbackFail(() async {
      v4Cache = (await http.get(scriptV4Url)).body;
    });

    fallbackFail(() async {
      initRuntime();
    });
  }

  static Future<void> refresh() async {
    if (enableV4 && ScriptWebViewProxy.reload != null) {
      ScriptWebViewProxy.reload!();
    }

    if (DateTime.now().difference(latestUpdate).inMinutes < 5) {
      return;
    }

    await refreshV3();
  }

  static Future<void> refreshV3() async {
    final scriptTemp = (await http.get(scriptUrl)).body;
    replaceScriptCacheIfRequired(scriptTemp);
  }

  /// this function may be called by `ScriptWebView`
  static Future<void> setV4(String ggM, String ggB) async {
    enableV4 = true;
    v4Cache ??= (await http.get(scriptV4Url)).body;
    final scriptTemp =
        v4Cache!.replaceAll('%%gg.m%', ggM).replaceAll('%%gg.b%', ggB);
    replaceScriptCacheIfRequired(scriptTemp);
  }

  static void replaceScriptCacheIfRequired(String scriptTemp) {
    if (scriptCache == scriptTemp) {
      return;
    }

    scriptCache = scriptTemp;
    initRuntime();
    ProviderManager.checkMustRefresh();
    ViewerContext.signal((c) => c.refreshImgUrlWhenRequired());
    Logger.info('[Script Manager] Update Sync!');
  }

  static void initRuntime() {
    latestUpdate = DateTime.now();
    runtime = getJavascriptRuntime();
    runtime.evaluate(scriptCache!);
  }

  static Future<String?> getGalleryInfoRaw(String id) async {
    final downloadUrl =
        runtime.evaluate("create_download_url('$id')").stringResult;
    final headers = await runHitomiGetHeaderContent(id.toString());
    final galleryInfo = await http.get(downloadUrl, headers: headers);
    if (galleryInfo.statusCode != 200) return null;
    return galleryInfo.body;
  }

  static Future<ImageList?> runHitomiGetImageList(int id) async {
    if (scriptCache == null) return null;

    try {
      final galleryInfoRaw = await getGalleryInfoRaw(id.toString());
      if (galleryInfoRaw == null) return null;
      runtime.evaluate(galleryInfoRaw);
      final jResult = runtime.evaluate('hitomi_get_image_list()').stringResult;
      final jResultImageList = ScriptImageList.fromJson(jsonDecode(jResult));

      return ImageList(
        urls: jResultImageList.result,
        bigThumbnails: jResultImageList.btresult,
        smallThumbnails: jResultImageList.stresult,
      );
    } catch (e, st) {
      Logger.error('[script-HitomiGetImageList] E: $e\n'
          'Id: $id\n'
          '$st');
      return null;
    }
  }

  static Future<Map<String, String>> runHitomiGetHeaderContent(
      String id) async {
    if (scriptCache == null) return <String, String>{};
    try {
      final jResult =
          runtime.evaluate("hitomi_get_header_content('$id')").stringResult;
      final jResultObject = jsonDecode(jResult);

      if (jResultObject is Map<dynamic, dynamic>) {
        return Map<String, String>.from(jResultObject);
      } else {
        throw Exception('[script-HitomiGetHeaderContent] E: JSError\n'
            'Id: $id\n'
            'Message: $jResult');
      }
    } catch (e, st) {
      Logger.error('[script-HitomiGetHeaderContent] E: $e\n'
          'Id: $id\n'
          '$st');
      rethrow;
    }
  }
}
