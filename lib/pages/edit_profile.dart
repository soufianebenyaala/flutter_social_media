import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import "package:flutter/material.dart";
import 'package:flutter_social_network/models/user.dart';
import 'package:flutter_social_network/pages/home.dart';
import 'package:flutter_social_network/widgets/progress.dart';

class EditProfile extends StatefulWidget {
  final String currentUserId;

  EditProfile({this.currentUserId});

  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _scaffoldkey = GlobalKey<ScaffoldState>();
  TextEditingController displayNameController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  bool isLoading = false;
  User user;

  bool _bioValid = true;
  bool _displayNameValid = true;

  @override
  void initState() {
    super.initState();
    getUser();
  }

  getUser() async {
    setState(() {
      isLoading = true;
    });
    DocumentSnapshot doc = await usersRef.document(widget.currentUserId).get();

    user = User.fromDocument(doc);
    displayNameController.text = user.displayName;
    bioController.text = user.bio;
    setState(() {
      isLoading = false;
    });
  }

  Column buildDisplayNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 12.0),
          child: Text(
            "Display Name",
            style: TextStyle(color: Colors.grey),
          ),
        ),
        TextField(
          controller: displayNameController,
          decoration: InputDecoration(
              hintText: "Update Display Name",
              errorText: _displayNameValid ? null : "Display Name too Short"),
        )
      ],
    );
  }

  Column buildBioField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 12.0),
          child: Text(
            "Bio",
            style: TextStyle(color: Colors.grey),
          ),
        ),
        TextField(
          controller: bioController,
          decoration: InputDecoration(
              hintText: "Update Bio",
              errorText: _bioValid ? null : "Bio is too long"),
        )
      ],
    );
  }

  updateProfileData() {
    setState(() {
      displayNameController.text.trim().length < 3 ||
              displayNameController.text.isEmpty
          ? _displayNameValid = false
          : _displayNameValid = true;
      bioController.text.length > 200 ? _bioValid = false : _bioValid = true;
    });

    if (_displayNameValid && _bioValid) {
      usersRef.document(widget.currentUserId).updateData({
        "displayName": displayNameController.text,
        "bio": bioController.text
      });
      SnackBar snackbar = SnackBar(content: Text("Profile Updated! "));
      _scaffoldkey.currentState.showSnackBar(snackbar);
    }
  }

  logout() async {
    await googleSignIn.signOut();
    Navigator.push(context, MaterialPageRoute(builder: (context) => Home()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldkey,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text(
            "Edit Profile",
            style: TextStyle(
              color: Theme.of(context).accentColor,
            ),
          ),
          actions: <Widget>[
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.done,
                size: 30.0,
                color: Colors.green,
              ),
            )
          ],
        ),
        body: isLoading
            ? circularProgress()
            : ListView(
                children: <Widget>[
                  Container(
                    child: Column(
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.only(top: 16.0, bottom: 8.0),
                          child: CircleAvatar(
                            backgroundImage:
                                CachedNetworkImageProvider(user.photoUrl),
                            radius: 50.0,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            children: <Widget>[
                              buildDisplayNameField(),
                              buildBioField(),
                            ],
                          ),
                        ),
                        RaisedButton(
                          onPressed: updateProfileData,
                          child: Text(
                            "Update profile",
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(16.0),
                          child: FlatButton.icon(
                            onPressed: logout,
                            icon: Icon(Icons.cancel, color: Colors.grey),
                            label: Text(
                              "Logout",
                              style:
                                  TextStyle(color: Colors.red, fontSize: 20.0),
                            ),
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ));
  }
}
