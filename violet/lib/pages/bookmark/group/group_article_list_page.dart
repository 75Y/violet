// This source code is a part of Project Violet.
// Copyright (C) 2020-2024. violet-team. Licensed under the Apache-2.0 License.

import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:violet/database/query.dart';
import 'package:violet/database/user/bookmark.dart';
import 'package:violet/locale/locale.dart';
import 'package:violet/log/log.dart';
import 'package:violet/other/dialogs.dart';
import 'package:violet/pages/bookmark/group/group_artist_article_list.dart';
import 'package:violet/pages/bookmark/group/group_artist_list.dart';
import 'package:violet/pages/search/search_page.dart';
import 'package:violet/pages/search/search_type.dart';
import 'package:violet/pages/segment/card_panel.dart';
import 'package:violet/pages/segment/filter_page.dart';
import 'package:violet/pages/segment/filter_page_controller.dart';
import 'package:violet/pages/segment/platform_navigator.dart';
import 'package:violet/settings/settings.dart';
import 'package:violet/style/palette.dart';
import 'package:violet/widgets/dots_indicator.dart';
import 'package:violet/widgets/floating_button.dart';
import 'package:violet/widgets/search_bar.dart';

class GroupArticleListPage extends StatefulWidget {
  final String name;
  final int groupId;

  const GroupArticleListPage({
    super.key,
    required this.name,
    required this.groupId,
  });

  @override
  State<GroupArticleListPage> createState() => _GroupArticleListPageState();
}

class _GroupArticleListPageState extends State<GroupArticleListPage> {
  final PageController _controller = PageController(
    initialPage: 0,
  );

  static const _kDuration = Duration(milliseconds: 300);
  static const _kCurve = Curves.ease;

  final ScrollController _scroll = ScrollController();

  Map<String, GlobalKey> itemKeys = <String, GlobalKey>{};

  bool _shouldRebuild = false;
  Widget? _cachedList;
  ObjectKey sliverKey = ObjectKey(const Uuid().v4());
  SearchResultType alignType = SearchResultType.detail;

  final FilterController _filterController =
      FilterController(heroKey: 'searchtype2');

  bool isFilterUsed = false;

  List<QueryResult> queryResult = <QueryResult>[];
  List<QueryResult> filterResult = <QueryResult>[];

  bool checkMode = false;
  bool checkModePre = false;
  List<int> checked = [];

  @override
  void initState() {
    super.initState();
    refresh();
    if (Platform.isAndroid || Platform.isIOS) {
      FirebaseAnalytics.instance.logEvent(name: 'open_bookmark');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _rebuild() {
    _shouldRebuild = true;
    itemKeys.clear();
    // https://github.com/flutter/flutter/issues/81684
    // https://github.com/flutter/flutter/issues/82109
    // https://github.com/fluttercommunity/chewie/blob/09659cc32a898c1c308a53e7461ac405fa36b615/lib/src/cupertino_controls.dart#L603
    if (!mounted) {
      Logger.warning(
          '[_GroupArticleListPageState][_rebuild] _element was null don\'t do setState');
      return;
    }
    setState(() {
      _shouldRebuild = true;
      sliverKey = ObjectKey(const Uuid().v4());
    });
  }

  Future<void> _loadBookmarkAlignType() async {
    final prefs = await SharedPreferences.getInstance();
    alignType = SearchResultType
        .values[prefs.getInt('bookmark_${widget.groupId}') ?? 3];
  }

  Future<void> _refreshAsync() async {
    _loadBookmarkAlignType();

    final bookmark = await Bookmark.getInstance();
    final articles = await bookmark.getArticle();

    final articleList = articles
        .where((e) => e.group() == widget.groupId)
        .toList()
        .reversed
        .toList();

    if (articleList.isEmpty) {
      queryResult = <QueryResult>[];
      filterResult = queryResult;
      _rebuild();
      return;
    }

    final queryIds = await QueryManager.queryIds(
        articleList.map((e) => int.parse(e.article())).toList());
    final queryResultById = Map<String, QueryResult>.fromIterable(queryIds,
        key: (e) => e.id().toString());

    queryResult = articleList
        .map((e) =>
            queryResultById[e.article()] ??
            QueryResult(result: {'Id': int.parse(e.article())}))
        .toList();

    _applyFilter();
    _rebuild();
  }

  void refresh() {
    _refreshAsync();
  }

  @override
  Widget build(BuildContext context) {
    if (_cachedList == null || _shouldRebuild) {
      final list = ResultPanelWidget(
        searchResultType: alignType,
        resultList: filterResult,
        sliverKey: sliverKey,
        itemKeys: itemKeys,
        keyPrefix: 'group',
        bookmarkMode: true,
        bookmarkCallback: longpress,
        bookmarkCheckCallback: check,
        isCheckMode: checkMode,
        checkedArticle: checked,
      );

      _shouldRebuild = false;
      _cachedList = list;
    }

    final scrollView = CustomScrollView(
      physics: const BouncingScrollPhysics(),
      primary: true,
      slivers: <Widget>[
        SliverPersistentHeader(
          floating: true,
          delegate: AnimatedOpacitySliver(
            searchBar: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Stack(children: <Widget>[
                  _filter(),
                  _title(),
                ])),
          ),
        ),
        _cachedList!
      ],
    );

    // TODO: fix bug that all sub widgets are loaded simultaneously
    // so, this occured memory leak and app crash
    final articleList = alignType.isGridLike
        ? scrollView
        : PrimaryScrollController(
            controller: _scroll,
            child: CupertinoScrollbar(
              scrollbarOrientation: Settings.bookmarkScrollbarPositionToLeft
                  ? ScrollbarOrientation.left
                  : ScrollbarOrientation.right,
              child: scrollView,
            ),
          );

    return CardPanel.build(
      context,
      child: Stack(
        children: [
          PageView(
            controller: _controller,
            children: [
              Scaffold(
                resizeToAvoidBottomInset: false,
                // resizeToAvoidBottomPadding: false,
                floatingActionButton: Visibility(
                  visible: checkMode,
                  child: AnimatedOpacity(
                    opacity: checkModePre ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    child: _floatingButton(),
                  ),
                ),
                // floatingActionButton: Container(child: Text('asdf')),
                body: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                  child: articleList,
                ),
              ),
              GroupArtistList(name: widget.name, groupId: widget.groupId),
              GroupArtistArticleList(
                  name: widget.name, groupId: widget.groupId),
            ],
          ),
          Positioned(
            bottom: 0.0,
            left: 0.0,
            right: 0.0,
            child: Container(
              color: null,
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: DotsIndicator(
                  controller: _controller,
                  itemCount: 3,
                  onPageSelected: (int page) {
                    _controller.animateToPage(
                      page,
                      duration: _kDuration,
                      curve: _kCurve,
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _floatingButton() {
    return AnimatedFloatingActionButton(
      fabButtons: <Widget>[
        FloatingActionButton(
          onPressed: () {
            for (var element in filterResult) {
              checked.add(element.id());
            }
            _shouldRebuild = true;
            setState(() {
              _shouldRebuild = true;
            });
          },
          elevation: 4,
          heroTag: 'a',
          child: const Icon(MdiIcons.checkAll),
        ),
        FloatingActionButton(
          onPressed: () async {
            if (await showYesNoDialog(
                context,
                Translations.instance!
                    .trans('deletebookmarkmsg')
                    .replaceAll('%s', checked.length.toString()),
                Translations.instance!.trans('bookmark'))) {
              var bookmark = await Bookmark.getInstance();
              for (var element in checked) {
                await bookmark.unbookmark(element);
              }
              checked.clear();
              refresh();
            }
          },
          elevation: 4,
          heroTag: 'b',
          child: const Icon(MdiIcons.delete),
        ),
        FloatingActionButton(
          onPressed: moveChecked,
          elevation: 4,
          heroTag: 'c',
          child: const Icon(MdiIcons.folderMove),
        ),
      ],
      animatedIconData: AnimatedIcons.menu_close,
      exitCallback: () {
        _shouldRebuild = true;
        setState(() {
          _shouldRebuild = true;
          checkModePre = false;
          checked.clear();
        });
        Future.delayed(const Duration(milliseconds: 500)).then((value) {
          _shouldRebuild = true;
          setState(() {
            _shouldRebuild = true;
            checkMode = false;
          });
        });
      },
    );
  }

  Widget _filter() {
    return Align(
      alignment: Alignment.centerRight,
      child: Hero(
        tag: 'searchtype\$bookmark',
        child: Card(
          color: Palette.themeColor,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(8.0),
            ),
          ),
          elevation: !Settings.themeFlat ? 100 : 0,
          clipBehavior: Clip.antiAliasWithSaveLayer,
          child: InkWell(
            onTap: alignOnTap,
            onLongPress: filterOnTap,
            child: const SizedBox(
              height: 48,
              width: 48,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  Icon(
                    MdiIcons.formatListText,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  alignOnTap() async {
    if (checkMode) return;

    final newAlignType = await Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      transitionDuration: const Duration(milliseconds: 500),
      transitionsBuilder: (BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation, Widget wi) {
        return FadeTransition(opacity: animation, child: wi);
      },
      pageBuilder: (_, __, ___) => SearchType(
        heroTag: 'searchtype\$bookmark',
        previousType: alignType,
      ),
      barrierColor: Colors.black12,
      barrierDismissible: true,
    ));

    if (newAlignType == null || alignType == newAlignType) return;
    alignType = newAlignType;
    itemKeys.clear();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('bookmark_${widget.groupId}', alignType.index);
    await Future.delayed(const Duration(milliseconds: 50), () {
      _shouldRebuild = true;
      setState(() {
        _shouldRebuild = true;
      });
    });
  }

  filterOnTap() async {
    if (checkMode) return;
    isFilterUsed = true;

    await PlatformNavigator.navigateFade(
      context,
      Provider<FilterController>.value(
        value: _filterController,
        child: FilterPage(
          queryResult: queryResult,
        ),
      ),
    );

    _applyFilter();
    _shouldRebuild = true;
    setState(() {
      _shouldRebuild = true;
      sliverKey = ObjectKey(const Uuid().v4());
    });
  }

  Widget _title() {
    return Padding(
      padding: const EdgeInsets.only(top: 24, left: 12),
      child: Text(widget.name,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    );
  }

  void _applyFilter() {
    filterResult = _filterController.applyFilter(queryResult);
    isFilterUsed = true;
  }

  List<QueryResult> filter() {
    if (!isFilterUsed) return queryResult;
    return filterResult;
  }

  void longpress(int article) {
    print(article);
    if (!checkMode) {
      checkMode = true;
      checkModePre = true;
      checked.add(article);
      _shouldRebuild = true;
      setState(() {
        _shouldRebuild = true;
      });
    }
  }

  void check(int article, bool check) {
    if (check) {
      checked.add(article);
    } else {
      checked.removeWhere((element) => element == article);
      if (checked.isEmpty) {
        _shouldRebuild = true;
        setState(() {
          _shouldRebuild = true;
          checkModePre = false;
          checked.clear();
        });
        Future.delayed(const Duration(milliseconds: 500)).then((value) {
          _shouldRebuild = true;
          setState(() {
            _shouldRebuild = true;
            checkMode = false;
          });
        });
      }
    }
  }

  Future<void> moveChecked() async {
    var groups = await (await Bookmark.getInstance()).getGroup();
    var currentGroup = widget.groupId;
    groups =
        groups.where((e) => e.id() != currentGroup && e.id() != 1).toList();

    if (!mounted) return;
    final whereToMove = await showDialog<int>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(Translations.instance!.trans('wheretomove')),
        actions: <Widget>[
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Settings.majorColor,
            ),
            child: Text(Translations.instance!.trans('cancel')),
            onPressed: () {
              Navigator.pop(context, 0);
            },
          ),
        ],
        content: SizedBox(
          width: 200,
          height: 300,
          child: ListView.builder(
            itemCount: groups.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(groups[index].name()),
                subtitle: Text(groups[index].description()),
                onTap: () {
                  Navigator.pop(context, index);
                },
              );
            },
          ),
        ),
      ),
    );

    if (whereToMove == null || !mounted) return;
    if (await showYesNoDialog(
        context,
        Translations.instance!
            .trans('movetoto')
            .replaceAll('%1', groups[whereToMove].name())
            .replaceAll('%2', checked.length.toString()),
        Translations.instance!.trans('movebookmark'))) {
      // There is a way to change only the group, but there is also re-register a new bookmark.
      // I chose the latter to suit the user's intentions.

      // Atomic!!
      // 0. Sort Checked
      var invIdIndex = <int, int>{};
      for (int i = 0; i < queryResult.length; i++) {
        invIdIndex[queryResult[i].id()] = i;
      }
      checked.sort((x, y) => invIdIndex[x]!.compareTo(invIdIndex[y]!));

      // 1. Get bookmark articles on source groupid
      var bm = await Bookmark.getInstance();
      // var article = await bm.getArticle();
      // var src = article
      //     .where((element) => element.group() == currentGroup)
      //     .toList();

      // 2. Save source bookmark for fault torlerance!
      // final cacheDir = await getTemporaryDirectory();
      // final path = File('${cacheDir.path}/bookmark_cache+${Uuid().v4()}');
      // path.writeAsString(jsonEncode(checked));

      for (var e in checked.reversed) {
        // 3. Delete source bookmarks
        await bm.unbookmark(e);
        // 4. Add src bookmarks with new groupid
        await bm.insertArticle(
            e.toString(), DateTime.now(), groups[whereToMove].id());
      }

      // 5. Update UI
      _shouldRebuild = true;
      setState(() {
        _shouldRebuild = true;
        checkModePre = false;
        checked.clear();
      });
      _shouldRebuild = true;
      Future.delayed(const Duration(milliseconds: 500)).then((value) {
        setState(() {
          _shouldRebuild = true;
          checkMode = false;
        });
      });
      refresh();
    }
  }
}
