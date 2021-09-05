// This source code is a part of Project Violet.
// Copyright (C) 2020-2021.violet-team. Licensed under the Apache-2.0 License.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:violet/settings/settings.dart';
import 'package:violet/variables.dart';

class ToastWrapper extends StatefulWidget {
  final bool isCheck;
  final bool isWarning;
  final String msg;

  ToastWrapper({this.isCheck, this.isWarning, this.msg});

  @override
  _ToastWrapperState createState() => _ToastWrapperState();
}

class _ToastWrapperState extends State<ToastWrapper>
    with SingleTickerProviderStateMixin {
  double opacity = 0.0;
  AnimationController controller;
  Animation<Offset> offset;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 100)).then((value) {
      // setState(() {
      //   opacity = 1.0;
      // });

      controller.reverse(from: 0.8);
      setState(() {
        opacity = 1.0;
      });
    });
    Future.delayed(Duration(milliseconds: 3000)).then((value) {
      setState(() {
        opacity = 0.0;
      });
      controller.forward();
    });
    controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 700));
    offset = Tween<Offset>(begin: Offset.zero, end: Offset(0.0, 1.0))
        .animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var color = widget.isCheck
        ? Colors.greenAccent.withOpacity(0.8)
        : widget.isWarning != null && widget.isWarning
            ? Colors.orangeAccent.withOpacity(0.8)
            : Colors.redAccent.withOpacity(0.8);

    return Padding(
      padding:
          EdgeInsets.only(bottom: Variables.bottomBarHeight.toDouble() + 6),
      child: SlideTransition(
        position: offset,
        child: AnimatedOpacity(
          duration: Duration(milliseconds: 500),
          opacity: opacity,
          curve: Curves.easeInOut,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25.0),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                decoration: BoxDecoration(
                    color: Settings.themeWhat
                        ? Colors.black.withOpacity(0.6)
                        : Colors.grey.withOpacity(0.1)),
                // decoration: BoxDecoration(
                //   borderRadius: BorderRadius.circular(25.0),
                //   color: widget.isCheck
                //       ? Colors.greenAccent.withOpacity(0.8)
                //       : widget.isWarning != null && widget.isWarning
                //           ? Colors.orangeAccent.withOpacity(0.8)
                //           : Colors.redAccent.withOpacity(0.8),
                // ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.isCheck
                          ? Icons.check
                          : widget.isWarning != null && widget.isWarning
                              ? Icons.warning
                              : Icons.cancel,
                      color: color,
                    ),
                    SizedBox(
                      width: 12.0,
                    ),
                    Text(widget.msg, style: TextStyle(color: color)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
