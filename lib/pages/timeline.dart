import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_social_network/models/user.dart';
import 'package:flutter_social_network/widgets/header.dart';
import 'package:flutter_social_network/widgets/post.dart';
import 'package:flutter_social_network/widgets/progress.dart';
import 'package:lottie/lottie.dart';

import 'home.dart';

final usersRef = Firestore.instance.collection('users');

class Timeline extends StatefulWidget {
  final User currentUser;

  Timeline({
    this.currentUser,
  });

  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  List<Post> posts;
  @override
  void initState() {
    super.initState();
    getTimeline();
  }

  getTimeline() async {
    List<Post> allPosts = [];
    QuerySnapshot followingUsersSnapshot = await followingRef
        .document(widget.currentUser.id)
        .collection("userFollowing")
        .getDocuments();
    List<DocumentSnapshot> tmp = followingUsersSnapshot.documents;
    for (var element in tmp) {
      QuerySnapshot followingUserPostsSnapshot = await postsRef
          .document(element.documentID)
          .collection("userPosts")
          .getDocuments();
      List<DocumentSnapshot> tmp2 = followingUserPostsSnapshot.documents;
      tmp2.forEach((element) {
        allPosts.add(Post.fromDocument(element));
      });
    }
    setState(() {
      posts = allPosts;
    });
  }

  buidTimeline() {
    if (posts == null) {
      return circularProgress();
    } else if (posts.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            height: 250.0,
            child: Lottie.asset(
              'assets/lottie/empty.json',
              repeat: true,
              reverse: true,
              animate: true,
            ),
          ),
          Text("No newsfeed items, yet"),
        ],
      );
    }
    return ListView(
      children: posts,
    );
  }

  @override
  Widget build(context) {
    return Scaffold(
      appBar: header(context,
          isAppTitle: true,
          titleText: "Social Network",
          removeBackButton: true),
      body: RefreshIndicator(
        onRefresh: () => getTimeline(),
        child: buidTimeline(),
      ),
    );
  }
}
