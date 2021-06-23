// This source code is a part of Project Violet.
// Copyright (C) 2020-2021.violet-team. Licensed under the Apache-2.0 License.

import 'package:flutter/material.dart';
import 'package:violet/other/dialogs.dart';
import 'package:violet/server/community/session.dart';
import 'package:violet/settings/settings.dart';

class SignInDialog extends StatefulWidget {
  @override
  _SignInDialogState createState() => _SignInDialogState();
}

class _SignInDialogState extends State<SignInDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    Widget yesButton = TextButton(
      style: TextButton.styleFrom(primary: Settings.majorColor),
      child: Text('Log In'),
      onPressed: () async {
        var id = _nameController.text.trim();
        var pw = _descController.text.trim();

        if (await VioletCommunitySession.signIn(id, pw) == null) {
          await showOkDialog(context,
              'User is not registered, or password is different. If you continue to get this, please contact the developer.');
          return;
        }

        Navigator.pop(context, [_nameController.text, _descController.text]);
      },
    );
    Widget noButton = TextButton(
      style: TextButton.styleFrom(primary: Settings.majorColor),
      child: Text('Cancel'),
      onPressed: () {
        Navigator.pop(context, null);
      },
    );

    return AlertDialog(
      title: Text('Log In'),
      contentPadding: EdgeInsets.fromLTRB(12, 8, 12, 8),
      actions: [
        yesButton,
        noButton,
      ],
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(children: [
            Text('Id: '),
            Expanded(
              child: TextField(
                controller: _nameController,
              ),
            ),
          ]),
          Row(
            children: [
              Text('Pw: '),
              Expanded(
                child: TextField(
                  obscureText: true,
                  enableSuggestions: false,
                  autocorrect: false,
                  controller: _descController,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
