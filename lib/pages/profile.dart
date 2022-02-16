import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_social_network/models/user.dart';
import 'package:flutter_social_network/pages/edit_profile.dart';
import 'package:flutter_social_network/pages/home.dart';
import 'package:flutter_social_network/widgets/custom_image.dart';
import 'package:flutter_social_network/widgets/header.dart';
import 'package:flutter_social_network/widgets/post.dart';
import 'package:flutter_social_network/widgets/post_tile.dart';
import 'package:flutter_social_network/widgets/progress.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Profile extends StatefulWidget {
  final String profileId;

  Profile({this.profileId});
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  bool isFollowing = false;
  final String currentUserId = currentUser?.id;
  bool isGridView = true;
  bool isLoading = false;
  int postCount = 0;
  int followersCount = 0;
  int followingCount = 0;
  List<Post> posts = [];
  @override
  void initState() {
    super.initState();
    getProfilePosts();
    getFollowers();
    getFollowing();
    checkIfFollowing();
  }

  checkIfFollowing() async {
    DocumentSnapshot doc = await followersRef
        .document(widget.profileId)
        .collection("userFollowers")
        .document(currentUserId)
        .get();
    setState(() {
      isFollowing = doc.exists;
    });
  }

  getFollowers() async {
    QuerySnapshot docs = await followersRef
        .document(widget.profileId)
        .collection("userFollowers")
        .getDocuments();
    setState(() {
      followersCount = docs.documents.length;
    });
  }

  getFollowing() async {
    QuerySnapshot docs = await followersRef
        .document(widget.profileId)
        .collection("userFollowing")
        .getDocuments();
    setState(() {
      followingCount = docs.documents.length;
    });
  }

  getProfilePosts() async {
    setState(() {
      isLoading = true;
    });
    QuerySnapshot snapshot = await postsRef
        .document(widget.profileId)
        .collection('userPosts')
        .orderBy('timestamp', descending: true)
        .getDocuments();

    setState(() {
      isLoading = false;
      postCount = snapshot.documents.length;
      snapshot.documents.map((doc) {
        print(doc.data);
      });
      List<Post> tmpPosts =
          snapshot.documents.map((e) => Post.fromDocument(e)).toList();
      tmpPosts.forEach((element) {
        Post p = Post(
          description: element.description,
          postId: element.postId,
          ownerId: element.ownerId,
          location: element.location,
          mediaUrl: element.mediaUrl,
          username: element.username,
          likes: element.likes,
        );
        posts.add(p);
      });
    });
  }

  Column buildCountColumn(String label, int count) {
    print("Building column with label : $label and count $count");
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          count.toString(),
          style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
        ),
        Container(
          margin: EdgeInsets.only(top: 4.0),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 15.0,
              fontWeight: FontWeight.w400,
            ),
          ),
        )
      ],
    );
  }

  buildButton({String text, Function function}) {
    return Container(
      padding: EdgeInsets.only(top: 2.0),
      child: FlatButton(
        onPressed: function,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.5,
          height: 27.0,
          child: Text(
            text,
            style: TextStyle(
              color: isFollowing ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color:
                  isFollowing ? Colors.white : Theme.of(context).primaryColor,
              border: Border.all(
                color:
                    isFollowing ? Colors.grey : Theme.of(context).primaryColor,
              ),
              borderRadius: BorderRadius.circular(5.0)),
        ),
      ),
    );
  }

  editProfile() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => EditProfile(currentUserId: currentUserId)));
  }

  buildProfileButton() {
    bool isProfileOwner = currentUserId == widget.profileId;
    if (isProfileOwner) {
      return buildButton(text: "Edit Profile", function: editProfile);
    } else if (isFollowing) {
      return buildButton(text: "Unfollow", function: handleUnfollowUser);
    } else if (!isFollowing) {
      return buildButton(text: "follow", function: handleFollowUser);
    }
  }

  handleFollowUser() {
    setState(() {
      isFollowing = true;
      followersCount++;
    });
    followersRef
        .document(widget.profileId)
        .collection("userFollowers")
        .document(currentUserId)
        .setData({});
    followingRef
        .document(currentUserId)
        .collection("userFollowing")
        .document(widget.profileId)
        .setData({});
    activityFeedRef
        .document(widget.profileId)
        .collection("feedItems")
        .document(currentUserId)
        .setData({
      "type": "follow",
      "owernId": widget.profileId,
      "username": currentUser.username,
      "userId": currentUserId,
      "userProfileImg": currentUser.photoUrl,
      "timestamp": DateTime.now()
    });
  }

  handleUnfollowUser() {
    setState(() {
      isFollowing = false;
      followersCount--;
    });
    followersRef
        .document(widget.profileId)
        .collection("userFollowers")
        .document(currentUserId)
        .get()
        .then((value) {
      if (value.exists) value.reference.delete();
    });
    followingRef
        .document(currentUserId)
        .collection("userFollowing")
        .document(widget.profileId)
        .get()
        .then((value) {
      if (value.exists) value.reference.delete();
    });
  }

  buildProfileHeader() {
    return FutureBuilder(
      future: usersRef.document(widget.profileId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        User user = User.fromDocument(snapshot.data);
        return Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 40.0,
                    backgroundColor: Colors.grey,
                    backgroundImage: CachedNetworkImageProvider(user.photoUrl),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: <Widget>[
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            buildCountColumn("posts", postCount),
                            buildCountColumn("followers", followersCount),
                            buildCountColumn("following", followingCount),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            buildProfileButton(),
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 12.0),
                child: Text(
                  user.username,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 4.0),
                child: Text(
                  user.displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 2.0),
                child: Text(
                  user.bio,
                ),
              )
            ],
          ),
        );
      },
    );
  }

  buildProfilePosts() {
    if (isLoading) return circularProgress();

    if (posts.isEmpty) {
      return Container(
        child: Center(
          child: ListView(
            shrinkWrap: true,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 15.0),
                child: SvgPicture.asset(
                  'assets/images/no_content.svg',
                  height: 200.0,
                ),
              ),
              Text(
                "No Posts yet",
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.redAccent,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                    fontSize: 60.0),
              )
            ],
          ),
        ),
      );
    }

    if (isGridView) {
      List<GridTile> gridTiles = [];
      posts.forEach((element) {
        gridTiles.add(GridTile(child: PostTile(element)));
      });
      return GridView.count(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        mainAxisSpacing: 1.5,
        crossAxisSpacing: 1.5,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        children: gridTiles,
      );
    } else {
      return Column(
        children: posts,
      );
    }
  }

  toggleOrientation(int type) {
    setState(() {
      isGridView = type == 0;
    });
  }

  buildTogglePostOrientation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        IconButton(
          icon: Icon(Icons.grid_on),
          color: isGridView ? Theme.of(context).primaryColor : Colors.grey,
          onPressed: () => toggleOrientation(0),
        ),
        IconButton(
            icon: Icon(Icons.list),
            color: !isGridView ? Theme.of(context).primaryColor : Colors.grey,
            onPressed: () => toggleOrientation(1)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, isAppTitle: false, titleText: "Profile"),
      body: ListView(
        children: <Widget>[
          buildProfileHeader(),
          Divider(),
          buildTogglePostOrientation(),
          Divider(
            height: 0.0,
          ),
          buildProfilePosts(),
        ],
      ),
    );
  }
}
