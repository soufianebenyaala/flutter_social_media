import 'package:flutter/material.dart';

AppBar header(context,
    {bool isAppTitle = true,
    String titleText = "",
    bool removeBackButton = false}) {
  return AppBar(
    automaticallyImplyLeading: !removeBackButton,
    title: Text(
      titleText,
      style: TextStyle(
        color: Colors.white,
        fontFamily: "Signatra",
        fontSize: isAppTitle ? 50.0 : 30.0,
      ),
      overflow: TextOverflow.ellipsis,
    ),
    centerTitle: true,
    backgroundColor: Theme.of(context).accentColor,
  );
}
