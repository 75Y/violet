// This source code is a part of Project Violet.
// Copyright (C) 2020-2022. violet-team. Licensed under the Apache-2.0 License.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:violet/component/downloadable.dart';
import 'package:violet/component/hitomi/hitomi.dart';
import 'package:violet/database/user/download.dart';
import 'package:violet/locale/locale.dart';
import 'package:violet/pages/download/download_item_menu.dart';
import 'package:violet/pages/download/download_routine.dart';
import 'package:violet/pages/viewer/viewer_page.dart';
import 'package:violet/pages/viewer/viewer_page_provider.dart';
import 'package:violet/script/script_manager.dart';
import 'package:violet/settings/settings.dart';
import 'package:violet/widgets/toast.dart';

class DownloadListItem {
  bool addBottomPadding;
  bool showDetail;
  double width;

  DownloadListItem({
    @required this.addBottomPadding,
    @required this.showDetail,
    @required this.width,
  });
}

typedef DownloadListItemCallback = void Function(DownloadListItem);
typedef DownloadListItemCallbackCallback = void Function(
    DownloadListItemCallback);

class DownloadItemWidget extends StatefulWidget {
  // final double width;
  final DownloadItemModel item;
  final DownloadListItem initialStyle;
  bool download;
  final VoidCallback refeshCallback;

  DownloadItemWidget({
    // this.width,
    this.item,
    this.initialStyle,
    this.download,
    this.refeshCallback,
  });

  @override
  _DownloadItemWidgetState createState() => _DownloadItemWidgetState();
}

class _DownloadItemWidgetState extends State<DownloadItemWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  double scale = 1.0;
  String fav = '';
  int cur = 0;
  int max = 0;

  double download = 0;
  double downloadSec = 0;
  int downloadTotalFileCount = 0;
  int downloadedFileCount = 0;
  int errorFileCount = 0;
  String downloadSpeed = ' KB/S';
  bool once = false;
  double thisWidth, thisHeight;
  DownloadListItem style;

  @override
  void initState() {
    super.initState();

    if (ExtractorManager.instance.existsExtractor(widget.item.url())) {
      var extractor = ExtractorManager.instance.getExtractor(widget.item.url());
      if (extractor != null) fav = extractor.fav();
    }

    _styleCallback(widget.initialStyle);

    _downloadProcedure();
  }

  _styleCallback(DownloadListItem item) {
    style = item;

    thisWidth = item.showDetail
        ? item.width - 16
        : item.width - (item.addBottomPadding ? 100 : 0);
    thisHeight = item.showDetail
        ? 130.0
        : item.addBottomPadding
            ? 500.0
            : item.width * 4 / 3;

    setState(() {});
  }

  _downloadProcedure() {
    Future.delayed(Duration(milliseconds: 500)).then((value) async {
      if (once) return;
      once = true;
      // var downloader = await BuiltinDownloader.getInstance();

      var routine = DownloadRoutine(widget.item, () => setState(() {}));

      if (!await routine.checkValidState() || !await routine.checkValidUrl())
        return;
      await routine.selectExtractor();

      if (!widget.download) {
        await routine.setToStop();
        return;
      }

      await routine.createTasks(
        progressCallback: (cur, max) async {
          setState(() {
            this.cur = cur;
            if (this.max < max) this.max = max;
          });
        },
      );

      if (await routine.checkNothingToDownload()) return;

      downloadTotalFileCount = routine.tasks.length;

      await routine.extractFilePath();

      var _timer = Timer.periodic(Duration(milliseconds: 100), (Timer timer) {
        setState(() {
          if (downloadSec / 1024 < 500.0)
            downloadSpeed = (downloadSec / 1024).toStringAsFixed(1) + " KB/S";
          else
            downloadSpeed =
                (downloadSec / 1024 / 1024).toStringAsFixed(1) + " MB/S";
          downloadSec = 0;
        });
      });

      await routine.appendDownloadTasks(
        completeCallback: () {
          downloadedFileCount++;
        },
        downloadCallback: (byte) {
          download += byte;
          downloadSec += byte;
        },
        errorCallback: (err) {
          downloadedFileCount++;
          errorFileCount++;
        },
      );

      // Wait for download complete
      while (downloadTotalFileCount != downloadedFileCount) {
        await Future.delayed(Duration(milliseconds: 500));
      }
      _timer.cancel();

      await routine.setDownloadComplete();

      FlutterToast(context).showToast(
        child: ToastWrapper(
          isCheck: true,
          isWarning: false,
          icon: Icons.download,
          msg: widget.item.info().split('[')[1].split(']').first +
              Translations.of(context).trans('download') +
              " " +
              Translations.of(context).trans('complete'),
        ),
        gravity: ToastGravity.BOTTOM,
        toastDuration: Duration(seconds: 4),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return GestureDetector(
      child: SizedBox(
        width: thisWidth,
        height: thisHeight,
        child: AnimatedContainer(
          // alignment: FractionalOffset.center,
          curve: Curves.easeInOut,
          duration: Duration(milliseconds: 300),
          // padding: EdgeInsets.all(pad),
          transform: Matrix4.identity()
            ..translate(thisWidth / 2, thisHeight / 2)
            ..scale(scale)
            ..translate(-thisWidth / 2, -thisHeight / 2),
          child: buildBody(),
        ),
      ),
      onLongPress: () async {
        setState(() {
          scale = 1.0;
        });

        var v = await showDialog(
          context: context,
          builder: (BuildContext context) => DownloadImageMenu(),
        );

        if (v == -1) {
          await widget.item.delete();
          widget.refeshCallback();
        } else if (v == 2) {
          Clipboard.setData(ClipboardData(text: widget.item.url()));
          FlutterToast(context).showToast(
            child: ToastWrapper(
              isCheck: true,
              isWarning: false,
              msg: 'URL Copied!',
            ),
            gravity: ToastGravity.BOTTOM,
            toastDuration: Duration(seconds: 4),
          );
        } else if (v == 1) {
          var copy = Map<String, dynamic>.from(widget.item.result);
          copy['State'] = 1;
          widget.item.result = copy;
          once = false;
          widget.download = true;
          _downloadProcedure();
          setState(() {});
        }
      },
      onTap: () async {
        if (widget.item.state() == 0 && widget.item.files() != null) {
          if (!Settings.disableFullScreen)
            SystemChrome.setEnabledSystemUIOverlays([]);

          Navigator.push(
            context,
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (context) {
                return Provider<ViewerPageProvider>.value(
                    value: ViewerPageProvider(
                      uris: widget.item.filesWithoutThumbnail(),
                      useFileSystem: true,
                      id: int.tryParse(widget.item.url()),
                      title: widget.item.info(),
                    ),
                    child: ViewerPage());
              },
            ),
          );
        }
      },
      onTapDown: (details) {
        setState(() {
          scale = 0.95;
        });
      },
      onTapUp: (details) {
        setState(() {
          scale = 1.0;
        });
      },
      onTapCancel: () {
        setState(() {
          scale = 1.0;
        });
      },
    );
  }

  Widget buildBody() {
    return Container(
      // margin: const EdgeInsets.only(bottom: 6),
      margin: style.addBottomPadding
          ? style.showDetail
              ? const EdgeInsets.only(bottom: 6)
              : const EdgeInsets.only(bottom: 50)
          : EdgeInsets.zero,
      decoration: !Settings.themeFlat
          ? BoxDecoration(
              color: style.showDetail
                  ? Settings.themeWhat
                      ? Settings.themeBlack
                          ? const Color(0xFF141414)
                          : Colors.grey.shade800
                      : Colors.white70
                  : Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.all(Radius.circular(5)),
              boxShadow: [
                BoxShadow(
                  color: Settings.themeWhat
                      ? Colors.grey.withOpacity(0.08)
                      : Colors.grey.withOpacity(0.4),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: Offset(0, 3), // changes position of shadow
                ),
              ],
            )
          : null,
      color: !Settings.themeFlat || !style.showDetail
          ? null
          : Settings.themeWhat
              ? Colors.black26
              : Colors.white,
      child: style.showDetail
          ? Row(
              children: <Widget>[
                buildThumbnail(),
                Expanded(
                  child: buildDetail(),
                ),
              ],
            )
          : buildThumbnail(),
    );
  }

  Widget buildThumbnail() {
    return Visibility(
      visible: widget.item.thumbnail() != null,
      child: widget.item.tryThumbnailFile() != null
          ? _FileThumbnailWidget(
              showDetail: style.showDetail,
              thumbnailPath: widget.item.tryThumbnailFile(),
              thumbnailTag: (widget.item.thumbnail() == null
                      ? ''
                      : widget.item.thumbnail()) +
                  widget.item.dateTime().toString(),
            )
          : _ThumbnailWidget(
              showDetail: style.showDetail,
              id: int.tryParse(widget.item.url()),
              thumbnail: widget.item.thumbnail(),
              thumbnailTag: (widget.item.thumbnail() == null
                      ? ''
                      : widget.item.thumbnail()) +
                  widget.item.dateTime().toString(),
              thumbnailHeader: widget.item.thumbnailHeader(),
            ),
    );
  }

  Widget buildDetail() {
    var title = widget.item.url();

    if (widget.item.info() != null) {
      title = widget.item.info();
    }

    var state = 'None';
    var pp =
        '${Translations.instance.trans('date')}: ' + widget.item.dateTime();

    var statecolor = !Settings.themeWhat ? Colors.black : Colors.white;
    var statebold = FontWeight.normal;

    switch (widget.item.state()) {
      case 0:
        state = Translations.instance.trans('complete');
        break;
      case 1:
        state = Translations.instance.trans('waitqueue');
        pp = Translations.instance.trans('progress') +
            ': ' +
            Translations.instance.trans('waitdownload');
        break;
      case 2:
        if (max == 0) {
          state = Translations.instance.trans('extracting');
          pp = Translations.instance.trans('progress') +
              ': ' +
              Translations.instance
                  .trans('count')
                  .replaceAll('%s', cur.toString());
        } else {
          state = Translations.instance.trans('extracting') + '[$cur/$max]';
          pp = Translations.instance.trans('progress') + ': ';
        }
        break;

      case 3:
        // state =
        //     '[$downloadedFileCount/$downloadTotalFileCount] ($downloadSpeed ${(download / 1024.0 / 1024.0).toStringAsFixed(1)} MB)';
        state = '[$downloadedFileCount/$downloadTotalFileCount]';
        pp = Translations.instance.trans('progress') + ': ';
        break;

      case 6:
        state = Translations.instance.trans('stop');
        pp = '';
        statecolor = Colors.orange;
        // statebold = FontWeight.bold;
        break;
      case 7:
        state = Translations.instance.trans('unknownerr');
        pp = '';
        statecolor = Colors.red;
        // statebold = FontWeight.bold;
        break;
      case 8:
        state = Translations.instance.trans('urlnotsupport');
        pp = '';
        statecolor = Colors.redAccent;
        // statebold = FontWeight.bold;
        break;
      case 9:
        state = Translations.instance.trans('tryagainlogin');
        pp = '';
        statecolor = Colors.redAccent;
        // statebold = FontWeight.bold;
        break;
      case 11:
        state = Translations.instance.trans('nothingtodownload');
        pp = '';
        statecolor = Colors.orangeAccent;
        // statebold = FontWeight.bold;
        break;
    }

    return AnimatedContainer(
      margin: EdgeInsets.fromLTRB(8, 4, 4, 4),
      duration: Duration(milliseconds: 300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(Translations.instance.trans('dinfo') + ': ' + title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          Container(
            height: 2,
          ),
          Text(Translations.instance.trans('state') + ': ' + state,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 15, color: statecolor, fontWeight: statebold)),
          Container(
            height: 2,
          ),
          widget.item.state() != 3
              ? Text(pp,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 15))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(pp,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 15)),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: 16),
                        child: LinearProgressIndicator(
                          value: downloadedFileCount / downloadTotalFileCount,
                          minHeight: 18,
                        ),
                      ),
                    ),
                  ],
                ),
          Expanded(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(children: <Widget>[
                    Padding(
                      padding: EdgeInsets.fromLTRB(0, 0, 0, 4),
                      child: fav != '' && fav != null
                          ? CachedNetworkImage(
                              imageUrl: fav,
                              width: 25,
                              height: 25,
                              fadeInDuration: Duration(microseconds: 500),
                              fadeInCurve: Curves.easeIn)
                          : Container(),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThumbnailWidget extends StatelessWidget {
  final String thumbnail;
  final String thumbnailHeader;
  final String thumbnailTag;
  final bool showDetail;
  final int id;

  _ThumbnailWidget({
    this.thumbnail,
    this.thumbnailHeader,
    this.thumbnailTag,
    this.showDetail,
    this.id,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      child: thumbnail != null
          ? ClipRRect(
              borderRadius: showDetail
                  ? const BorderRadius.horizontal(left: Radius.circular(5.0))
                  : const BorderRadius.all(Radius.circular(5.0)),
              child: _thumbnailImage(),
            )
          : FlareActor(
              "assets/flare/Loading2.flr",
              alignment: Alignment.center,
              fit: BoxFit.fitHeight,
              animation: "Alarm",
            ),
    );
  }

  Widget _thumbnailImage() {
    if (id == null) {
      Map<String, String> headers = {};
      if (thumbnailHeader != null) {
        var hh = jsonDecode(thumbnailHeader) as Map<String, dynamic>;
        hh.entries.forEach((element) {
          headers[element.key] = element.value as String;
        });
      }
      return Hero(
        tag: thumbnailTag,
        child: CachedNetworkImage(
          imageUrl: thumbnail,
          fit: BoxFit.cover,
          httpHeaders: headers,
          imageBuilder: (context, imageProvider) => Container(
            decoration: BoxDecoration(
              image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
            ),
            child: Container(),
          ),
          placeholder: (b, c) {
            return FlareActor(
              "assets/flare/Loading2.flr",
              alignment: Alignment.center,
              fit: BoxFit.fitHeight,
              animation: "Alarm",
            );
          },
        ),
      );
    } else {
      return FutureBuilder(
        future: HitomiManager.getImageList(id.toString()).then((value) async {
          if (value == null) return null;
          var header =
              await ScriptManager.runHitomiGetHeaderContent(id.toString());
          return [value.item1[0], header];
        }),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return FlareActor(
              "assets/flare/Loading2.flr",
              alignment: Alignment.center,
              fit: BoxFit.fitHeight,
              animation: "Alarm",
            );
          }

          return Hero(
            tag: thumbnailTag,
            child: CachedNetworkImage(
              imageUrl: snapshot.data[0],
              fit: BoxFit.cover,
              httpHeaders: snapshot.data[1],
              imageBuilder: (context, imageProvider) => Container(
                decoration: BoxDecoration(
                  image:
                      DecorationImage(image: imageProvider, fit: BoxFit.cover),
                ),
                child: Container(),
              ),
              placeholder: (b, c) {
                return FlareActor(
                  "assets/flare/Loading2.flr",
                  alignment: Alignment.center,
                  fit: BoxFit.fitHeight,
                  animation: "Alarm",
                );
              },
            ),
          );
        },
      );
    }
  }
}

class _FileThumbnailWidget extends StatelessWidget {
  final String thumbnailPath;
  final String thumbnailTag;
  final bool showDetail;

  _FileThumbnailWidget({
    this.thumbnailPath,
    this.thumbnailTag,
    this.showDetail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      child: thumbnailPath != null
          ? ClipRRect(
              borderRadius: showDetail
                  ? const BorderRadius.horizontal(left: Radius.circular(5.0))
                  : const BorderRadius.all(Radius.circular(5.0)),
              child: _thumbnailImage(),
            )
          : FlareActor(
              "assets/flare/Loading2.flr",
              alignment: Alignment.center,
              fit: BoxFit.fitHeight,
              animation: "Alarm",
            ),
    );
  }

  Widget _thumbnailImage() {
    return Hero(
      tag: thumbnailTag,
      child: Image.file(
        File(thumbnailPath),
        fit: BoxFit.cover,
        errorBuilder: (context, obj, st) {
          return FlareActor(
            "assets/flare/Loading2.flr",
            alignment: Alignment.center,
            fit: BoxFit.fitHeight,
            animation: "Alarm",
          );
        },
      ),
    );
  }
}
