// This source code is a part of Project Violet.
// Copyright (C) 2020. violet-team. Licensed under the MIT License.

import 'dart:ui';

import 'package:auto_animated/auto_animated.dart';
import 'package:fading_edge_scrollview/fading_edge_scrollview.dart';
import 'package:flare_flutter/flare.dart';
import 'package:flare_dart/math/mat2d.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flare_flutter/flare_cache.dart';
import 'package:flare_flutter/flare_controller.dart';
import 'package:flare_flutter/flare_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:infinite_listview/infinite_listview.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:tuple/tuple.dart';
import 'package:violet/component/hitomi/hitomi.dart';
import 'package:violet/database.dart';
import 'package:violet/locale.dart';
import 'package:violet/other/flare_artboard.dart';
import 'package:violet/settings.dart';
import 'package:violet/widgets/article_list_item_widget.dart';
// import 'package:infinite_listview/infinite_listview.dart';
// import 'package:keyboard_visibility/keyboard_visibility.dart';

class SearchPage extends StatefulWidget {
  SearchPage({Key key}) : super(key: key) {
    // SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    //   statusBarColor: Colors.transparent,
    //   statusBarBrightness: Brightness.light,
    //   statusBarIconBrightness: Brightness.dark,
    //   systemNavigationBarColor: Colors.white,
    //   systemNavigationBarIconBrightness: Brightness.dark,
    // ));
  }

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  Color color = Colors.green;
  //double radius = 0;
  bool into = false;

  TextEditingController _controller = new TextEditingController();
  //FocusNode _focus = new FocusNode();
  final FlareControls heroFlareControls = FlareControls();
  FlutterActorArtboard artboard;

  @override
  void initState() {
    super.initState();

    (() async {
      var asset =
          await cachedActor(rootBundle, 'assets/flare/search_close.flr');
      asset.ref();
      artboard = asset.actor.artboard.makeInstance() as FlutterActorArtboard;
      artboard.initializeGraphics();
      artboard.advance(0);
    })();
    Future.delayed(Duration(milliseconds: 500),
        () => heroFlareControls.play('close2search'));
    // SchedulerBinding.instance.addPostFrameCallback((_) async => {
    //       heroFlareControls.play('close2search')
    //     });
    WidgetsBinding.instance
        .addPostFrameCallback((_) => heroFlareControls.play('close2search'));
    // KeyboardVisibilityNotification().addNewListener(
    //   onChange: (bool visible) {
    //     //print('asd');
    //     setState(() {
    //       into = visible;
    //     });
    //   },
    // );
    //_focus.addListener(_onFocusChange);
  }

  // void _onFocusChange(){
  //   print("Focus: "+_focus.hasFocus.toString());
  // }

  Tuple2<QueryManager, String> latestQuery;

  @override
  Widget build(BuildContext context) {
    final InfiniteScrollController _infiniteController =
        InfiniteScrollController(
      initialScrollOffset: 0.0,
    );
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    double width = MediaQuery.of(context).size.width;
    // double _sigmaX = 8.0; // from 0-10
    // double _sigmaY = 8.0; // from 0-10
    // TextEditingController _searchController = TextEditingController();
    //color = Colors.green;

    return Container(
      //color: Colors.white,// Colors.black.withOpacity(0.1),
      //padding: EdgeInsets.fromLTRB(8, statusBarHeight + 4, 60, 0),
      //child: BackdropFilter(
      //   filter: ImageFilter.blur(sigmaX: _sigmaX, sigmaY: _sigmaY),
      child: Column(
        children: <Widget>[
          // GestureDetector(
          //     onTap: () {
          //       setState(() {
          //         into = !into;
          //       });
          //     },
          Stack(children: <Widget>[
            Container(
              // color: Colors.white,// Colors.black.withOpacity(0.1),
              padding: EdgeInsets.fromLTRB(8, statusBarHeight + 8, 72, 0),
              child: SizedBox(
                  height: 64,
                  child: Hero(
                    tag: "searchbar",
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(8.0),
                        ),
                      ),
                      elevation: 100,
                      clipBehavior: Clip.antiAliasWithSaveLayer,
                      child: Stack(
                        children: <Widget>[
                          Column(
                            children: <Widget>[
                              // AspectRatio(
                              //   aspectRatio: 485.0 / 384.0,
                              //   child: Image.network(
                              //       ""),
                              // ),
                              Material(
                                color: Settings.themeWhat
                                    ? Colors.grey.shade900.withOpacity(0.4)
                                    : Colors.grey.shade100.withOpacity(0.4),
                                child: ListTile(
                                  title: TextFormField(
                                    cursorColor: Colors.black,
                                    //keyboardType: inputType,
                                    // Search Controller Not Working Why?
                                    // controller: _searchController,
                                    decoration: new InputDecoration(
                                        border: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        errorBorder: InputBorder.none,
                                        disabledBorder: InputBorder.none,
                                        contentPadding: EdgeInsets.only(
                                            left: 15,
                                            bottom: 11,
                                            top: 11,
                                            right: 15),
                                        hintText: latestQuery != null &&
                                                latestQuery.item2.trim() != ''
                                            ? latestQuery.item2
                                            : Translations.of(context)
                                                .trans('search')),
                                  ), //Text("검색"),
                                  leading: SizedBox(
                                    width: 25,
                                    height: 25,
                                    child: FlareArtboard(artboard,
                                        controller: heroFlareControls),
                                  ),
                                  //Icon(Icons.search),
                                  //subtitle: Text("This is item #2"),
                                ),
                              )
                              //Text('zxcv')
                            ],
                          ),
                          Positioned(
                            left: 0.0,
                            top: 0.0,
                            bottom: 0.0,
                            right: 0.0,
                            child: Material(
                              type: MaterialType.transparency,
                              child: InkWell(
                                onTap: () async {
                                  await Future.delayed(
                                      Duration(milliseconds: 200));
                                  heroFlareControls.play('search2close');
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) {
                                        return new SearchBar(
                                          artboard: artboard,
                                          heroController: heroFlareControls,
                                        );
                                      },
                                      fullscreenDialog: true,
                                    ),

                                    //PageRouteBuilder(
                                    //    transitionDuration: Duration(seconds: 2),
                                    //    pageBuilder: (_, __, ___) => SearchBar()),
                                  ).then((value) async {
                                    setState(() {
                                      heroFlareControls.play('close2search');
                                    });
                                    if (value == null) return;
                                    latestQuery = value;
                                    queryResult = List<QueryResult>();
                                    await loadNextQuery();
                                  });
                                  // print(latestQuery);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  // child: Padding(
                  //   padding: EdgeInsets.fromLTRB(8, statusBarHeight, 8, 0),
                  //   child: Center(
                  //     child: Column(
                  //       children: <Widget>[
                  //         AnimatedContainer(
                  //           duration: Duration(microseconds: 15000),
                  //           color: color,
                  //           child: TextField(
                  //             onTap: () {
                  //               setState(() {
                  //                 print('asdf');
                  //                 color = Colors.red;
                  //               });
                  //             },
                  //           ),
                  //         )
                  //       ],
                  //     ),
                  //   ),
                  // ),
                  ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                  width - 8 - 64, statusBarHeight + 8, 8, 0),
              child: SizedBox(
                height: 64,
                child: Hero(
                  tag: "searchtype",
                  child: Card(
                    // color: Colors.grey.shade200,
                    color: Settings.themeWhat
                        ? Colors.grey.shade800.withOpacity(0.4)
                        : Colors.grey.shade100.withOpacity(0.9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(8.0),
                      ),
                    ),
                    elevation: 100,
                    clipBehavior: Clip.antiAliasWithSaveLayer,
                    child: InkWell(
                      child: SizedBox(
                        height: 64,
                        width: 64,
                        child: Icon(
                          MdiIcons.formatListText,
                          color: Colors.grey,
                        ),
                      ),
                      onTap: () async {
                        Navigator.of(context).push(PageRouteBuilder(
                          opaque: false,
                          transitionDuration: Duration(milliseconds: 500),
                          pageBuilder: (_, __, ___) => SearchType(),
                        ));
                      },
                    ),
                  ),
                ),
              ),
            ),
          ]),
          // Container(
          //   padding:
          //       EdgeInsets.fromLTRB(width - 8 - 64, statusBarHeight + 4, 8, 0),
          //   child: SizedBox(
          //     height: 64,
          //     child: Hero(
          //       tag: "searchmenu",
          //       child: Card(
          //         color: Colors.grey.shade200,
          //         shape: RoundedRectangleBorder(
          //           borderRadius: BorderRadius.all(
          //             Radius.circular(8.0),
          //           ),
          //         ),
          //         elevation: 100,
          //         clipBehavior: Clip.antiAliasWithSaveLayer,
          //         child: SizedBox(
          //           height: 64,
          //           width: 64,
          //           child: Icon(Icons.star),
          //         ),
          //       ),
          //     ),
          //   ),
          // ),
          // InfiniteListView.builder()
          Expanded(child: makeResult()),
        ],
      ),
      //),
    );
  }

  List<QueryResult> queryResult = List<QueryResult>();

  Future<void> loadNextQuery() async {
    var nn = await latestQuery.item1.next();
    setState(() {
      queryResult.addAll(nn);
    });
  }

  Widget makeResult() {
    switch (Settings.searchResultType) {
      case 0:
        return ListView.builder(
          physics: const BouncingScrollPhysics(), // new
          itemCount: queryResult.length,
          itemBuilder: (context, index) {
            return Align(
                alignment: Alignment.center,
                child: ArticleListItemVerySimpleWidget(
                    addBottomPadding: true, queryResult: queryResult[index])
                //FadeInImage(placeholder: Text('loading'), image: ,)
                // Text(
                //   queryResult[index].title(),
                // ),

                // Card(
                //   elevation: 10,
                //   child: Container(
                //     width: width - 100,
                //     height: 200,
                //     child: Text(
                //       queryResult[index].title(),
                //     ),
                //   ),
                // ),
                );
          },
        );
      case 1:
        return LiveGrid(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.all(16),
          showItemInterval: Duration(milliseconds: 50),
          showItemDuration: Duration(milliseconds: 150),
          visibleFraction: 0.001,
          itemCount: queryResult.length,
          shrinkWrap: false,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 3 / 4,
          ),
          itemBuilder: (context, index, animation) {
            return FadeTransition(
              opacity: Tween<double>(
                begin: 0,
                end: 1,
              ).animate(animation),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(0, -0.1),
                  end: Offset.zero,
                ).animate(animation),
                child: Padding(
                  padding: EdgeInsets.zero,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child:
                        // Text(queryResult[index].title())
                        SizedBox(
                      // height: 250,
                      // width: 100,
                      child:
                          //               ClipRRect(
                          //   borderRadius: BorderRadius.circular(4),
                          //   child: Material(
                          //     color: Colors.white,
                          //     child: Center(
                          //       child: Text(
                          //         queryResult[index].title(),
                          //         style: Theme.of(context).textTheme.headline4,
                          //       ),
                          //     ),
                          //   ),
                          // ),

                          // Text(queryResult[index].title())
                          ArticleListItemVerySimpleWidget(
                        queryResult: queryResult[index],
                        addBottomPadding: false,
                      ),
                    ),
                  ),
                ),
              ),
            );
            // Align(
            //   alignment: Alignment.center,
            //   child: ArticleListItemVerySimpleWidget(
            //     queryResult: queryResult[index],
            //   ),
            // );
          },
        );

      default:
        return Container(
          child: Center(
            child: Text('Error :('),
          ),
        );
    }
  }
}

class SearchBar extends StatefulWidget {
  final FlareControls heroController;
  final FlutterActorArtboard artboard;
  const SearchBar({Key key, this.artboard, this.heroController})
      : super(key: key);

  @override
  _SearchBarState createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar>
    with SingleTickerProviderStateMixin {
  AnimationController controller;
  List<Tuple3<String, String, int>> _searchLists =
      List<Tuple3<String, String, int>>();

  TextEditingController _searchController = TextEditingController();
  int _insertPos, _insertLength;
  String _searchText;
  bool _nothing = false;
  bool _onChip = false;
  bool _tagTranslation = false;
  bool _showCount = true;
  int _searchResultMaximum = 60;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
      reverseDuration: Duration(milliseconds: 400),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    controller.forward();

    if (_searchLists.length == 0 && !_nothing) {
      _searchLists.add(Tuple3<String, String, int>('prefix', 'female', 0));
      _searchLists.add(Tuple3<String, String, int>('prefix', 'male', 0));
      _searchLists.add(Tuple3<String, String, int>('prefix', 'tag', 0));
      _searchLists.add(Tuple3<String, String, int>('prefix', 'lang', 0));
      _searchLists.add(Tuple3<String, String, int>('prefix', 'series', 0));
      _searchLists.add(Tuple3<String, String, int>('prefix', 'artist', 0));
      _searchLists.add(Tuple3<String, String, int>('prefix', 'group', 0));
      _searchLists.add(Tuple3<String, String, int>('prefix', 'uploader', 0));
      _searchLists.add(Tuple3<String, String, int>('prefix', 'character', 0));
      _searchLists.add(Tuple3<String, String, int>('prefix', 'type', 0));
      _searchLists.add(Tuple3<String, String, int>('prefix', 'class', 0));
      _searchLists.add(Tuple3<String, String, int>('prefix', 'recent', 0));
    }

    return Container(
        color: Settings.themeWhat ? Colors.grey.shade900 : Colors.white,
        padding: EdgeInsets.fromLTRB(2, statusBarHeight + 2, 0, 0),
        child: Stack(children: <Widget>[
          Hero(
            tag: "searchbar",
            child: Card(
              elevation: 100,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
              child: Material(
                child: Container(
                  child: Column(
                    children: <Widget>[
                      Material(
                        child: ListTile(
                          title: TextFormField(
                            cursorColor: Colors.black,
                            onChanged: (String str) async {
                              await searchProcess(
                                  str, _searchController.selection);
                            },
                            controller: _searchController,
                            decoration: new InputDecoration(
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              suffixIcon: IconButton(
                                onPressed: () async {
                                  _searchController.clear();
                                  _searchController.selection = TextSelection(
                                      baseOffset: 0, extentOffset: 0);
                                  await searchProcess(
                                      '', _searchController.selection);
                                },
                                icon: Icon(Icons.clear),
                              ),
                              contentPadding: EdgeInsets.only(
                                  left: 15, bottom: 11, top: 11, right: 15),
                              hintText:
                                  Translations.of(context).trans('search'),
                            ),
                          ),
                          leading: SizedBox(
                            width: 25,
                            height: 25,
                            child: RawMaterialButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                shape: CircleBorder(),
                                child: FlareArtboard(widget.artboard,
                                    controller: widget.heroController)),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.0),
                        child: Container(
                          height: 1.0,
                          color: Colors.black12,
                        ),
                      ),
                      SizedBox(
                        height: 40,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(8, 2, 8, 2),
                          child: ButtonTheme(
                            minWidth: double.infinity,
                            height: 30,
                            child: RaisedButton(
                              color: Settings.majorColor,
                              textColor: Colors.white,
                              child: Text(
                                  Translations.of(context).trans('search')),
                              onPressed: () async {
                                final query = HitomiManager.translate2query(
                                    _searchController.text);
                                final result =
                                    QueryManager.queryPagination(query);
                                Navigator.pop(
                                    context,
                                    Tuple2<QueryManager, String>(
                                        result, _searchController.text));
                              },
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.0),
                        child: Container(
                          height: 1.0,
                          color: Colors.black12,
                        ),
                      ),
                      Expanded(
                        child: _searchLists.length == 0 || _nothing
                            ? Center(
                                child: Text(_nothing
                                    ? Translations.of(context)
                                        .trans('nosearchresult')
                                    : Translations.of(context)
                                        .trans('inputsearchtoken')))
                            : Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: FadingEdgeScrollView
                                    .fromSingleChildScrollView(
                                  child: SingleChildScrollView(
                                    controller: ScrollController(),
                                    child: Wrap(
                                      spacing: 4.0,
                                      runSpacing: -10.0,
                                      children: _searchLists
                                          .map((item) => chip(item))
                                          .toList(),
                                    ),
                                  ),
                                  gradientFractionOnEnd: 0.1,
                                  gradientFractionOnStart: 0.1,
                                ),
                              ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.0),
                        child: Container(
                          height: 1.0,
                          color: Colors.black12,
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(10, 4, 10, 4),
                          child: LayoutBuilder(builder: (BuildContext context,
                              BoxConstraints constraints) {
                            return SingleChildScrollView(
                              controller: ScrollController(),
                              child: ConstrainedBox(
                                constraints: constraints.copyWith(
                                  minHeight: constraints.maxHeight,
                                  maxHeight: double.infinity,
                                ),
                                child: IntrinsicHeight(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: <Widget>[
                                      ListTile(
                                        leading: Icon(Icons.translate,
                                            color: Settings.majorColor),
                                        title: Text(Translations.of(context)
                                            .trans('tagtranslation')),
                                        trailing: Switch(
                                          value: _tagTranslation,
                                          onChanged: (value) {
                                            setState(() {
                                              _tagTranslation = value;
                                            });
                                          },
                                          activeTrackColor: Settings.majorColor,
                                          activeColor:
                                              Settings.majorAccentColor,
                                        ),
                                      ),
                                      Container(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 8.0,
                                        ),
                                        width: double.infinity,
                                        height: 1.0,
                                        color: Colors.grey.shade400,
                                      ),
                                      ListTile(
                                        leading: Icon(MdiIcons.counter,
                                            color: Settings.majorColor),
                                        title: Text(Translations.of(context)
                                            .trans('showcount')),
                                        trailing: Switch(
                                          value: _showCount,
                                          onChanged: (value) {
                                            setState(() {
                                              _showCount = value;
                                            });
                                          },
                                          activeTrackColor: Settings.majorColor,
                                          activeColor:
                                              Settings.majorAccentColor,
                                        ),
                                      ),
                                      Expanded(
                                        child: Align(
                                          alignment: Alignment.bottomLeft,
                                          child: Container(
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 2,
                                              vertical: 8,
                                            ),
                                            width: double.infinity,
                                            height: 60,
                                            child: RaisedButton(
                                              color: Settings.themeWhat
                                                  ? Colors.grey.shade800
                                                  : Colors.grey,
                                              child: Icon(MdiIcons.autoFix),
                                              onPressed: () {
                                                magicProcess();
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ]));
  }

  Future<void> searchProcess(String target, TextSelection selection) async {
    _nothing = false;
    _onChip = false;
    if (target.trim() == '') {
      setState(() {
        _searchLists.clear();
      });
      return;
    }

    int pos = selection.base.offset - 1;
    for (; pos > 0; pos--)
      if (target[pos] == ' ') {
        pos++;
        break;
      }

    var last = target.indexOf(' ', pos);
    var token =
        target.substring(pos, last == -1 ? target.length : last + 1).trim();

    if (pos != target.length && target[pos] == '-') {
      token = token.substring(1);
      pos++;
    }
    if (token == '') {
      setState(() {
        _searchLists.clear();
      });
      return;
    }

    _insertPos = pos;
    _insertLength = token.length;
    _searchText = target;
    final result = (await HitomiManager.queryAutoComplete(token))
        .take(_searchResultMaximum)
        .toList();
    if (result.length == 0) _nothing = true;
    setState(() {
      _searchLists = result;
    });
  }

  void magicProcess() {
    var text = _searchController.text;
    var selection = _searchController.selection;

    if (_nothing) {
      if (text == null || text.trim() == '') return;

      // DateTime()
    }
  }

  // Create tag-chip
  // group, name, counts
  Widget chip(Tuple3<String, String, int> info) {
    var tagRaw = info.item2;
    var count = '';
    var color = Colors.grey;

    if (_tagTranslation) // Korean
      tagRaw =
          HitomiManager.mapSeries2Kor(HitomiManager.mapTag2Kor(info.item2));

    if (info.item3 > 0 && _showCount) count = ' (${info.item3})';

    if (info.item1 == 'female')
      color = Colors.pink;
    else if (info.item1 == 'male')
      color = Colors.blue;
    else if (info.item1 == 'prefix') color = Colors.orange;

    var fc = RawChip(
      labelPadding: EdgeInsets.all(0.0),
      avatar: CircleAvatar(
        backgroundColor: Colors.grey.shade600,
        child: Text(info.item1[0].toUpperCase()),
      ),
      label: Text(
        ' ' + tagRaw + count,
        style: TextStyle(
          color: Colors.white,
        ),
      ),
      backgroundColor: color,
      elevation: 6.0,
      shadowColor: Colors.grey[60],
      padding: EdgeInsets.all(6.0),
      onPressed: () async {
        // Insert text to cursor.
        if (info.item1 != 'prefix') {
          var insert = info.item2.replaceAll(' ', '_');
          if (info.item1 != 'female' && info.item1 != 'male')
            insert = info.item1 + ':' + insert;

          _searchController.text = _searchText.substring(0, _insertPos) +
              insert +
              _searchText.substring(
                  _insertPos + _insertLength, _searchText.length);
          _searchController.selection = TextSelection(
            baseOffset: _insertPos + insert.length,
            extentOffset: _insertPos + insert.length,
          );
        } else {
          var offset = _searchController.selection.baseOffset;
          if (offset != -1) {
            _searchController.text = _searchController.text
                    .substring(0, _searchController.selection.base.offset) +
                info.item2 +
                ': ' +
                _searchController.text
                    .substring(_searchController.selection.base.offset);
            _searchController.selection = TextSelection(
              baseOffset: offset + info.item2.length + 1,
              extentOffset: offset + info.item2.length + 1,
            );
          } else {
            _searchController.text = info.item2 + ': ';
            _searchController.selection = TextSelection(
              baseOffset: info.item2.length + 1,
              extentOffset: info.item2.length + 1,
            );
          }
          _onChip = true;
          await searchProcess(
              _searchController.text, _searchController.selection);
        }
      },
    );
    return fc;
  }
}

class SearchType extends StatefulWidget {
  @override
  _SearchTypeState createState() => _SearchTypeState();
}

class _SearchTypeState extends State<SearchType> {
  @override
  Widget build(BuildContext context) {
    return Container(
      // color: Settings.themeWhat ? Colors.grey.shade900 : Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Hero(
            tag: "searchtype",
            child: Card(
              // color: Colors.grey.shade200,
              color: Settings.themeWhat
                  ? Colors.grey.shade800.withOpacity(0.4)
                  : Colors.grey.shade100.withOpacity(0.9),
              child:  SizedBox(
              child: Container(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: Column(
                  children: <Widget>[
                  ],
                ),
                width: 250,
                height: 300,
              ),
            ),
            ),
          ),
        ],
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(1)),
        // color: Colors.black,
        boxShadow: [
          BoxShadow(
            color: Settings.themeWhat
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 1,
            offset: Offset(0, 3), // changes position of shadow
          ),
        ],
      ),
    );
  }
}
