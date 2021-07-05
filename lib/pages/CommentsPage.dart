import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:postme_app/pages/HomePage.dart';
import 'package:postme_app/widgets/HeaderWidget.dart';
import 'package:postme_app/widgets/ProgressWidget.dart';
import 'package:postme_app/widgets/PostWidget.dart';
import 'package:timeago/timeago.dart' as tAgo;

import 'ProfilePage.dart';

class CommentsPage extends StatefulWidget {
  final String postId;
  final String postOwnerId;
  final String postImageUrl;

  CommentsPage({this.postId, this.postOwnerId, this.postImageUrl});

  @override
  CommentsPageState createState() => CommentsPageState(postId: postId, postOwnerId: postOwnerId, postImageUrl: postImageUrl);
}

class CommentsPageState extends State<CommentsPage> {
  final String postId;
  final String postOwnerId;
  final String postImageUrl;
  TextEditingController commentTextEditingController = TextEditingController();

  CommentsPageState({this.postId, this.postOwnerId, this.postImageUrl});

  retrieveComments() {
    return StreamBuilder(
      stream: commentsReference.document(postId).collection("comments").orderBy("timestamp", descending: false).snapshots(),
      builder: (context, dataSnapshot) {
        if(dataSnapshot.data == null)
          return circularProgress();
        List<Comment> comments = [];
        dataSnapshot.data.documents.forEach((document){
          comments.add(Comment.fromDocument(document));
          countTotalComments = dataSnapshot.data.documents.length;
        });
        return ListView(
            children: comments
        );
      },
    );
  }

  saveComment() {
    if (commentTextEditingController.text != "") {
      commentsReference.document(postId).collection("comments").add({
        "username": currentUser.username,
        "comment": commentTextEditingController.text,
        "timestamp": DateTime.now(),
        "url": currentUser.url,
        "userId": currentUser.id
      });
      bool isNotPostOwner = (postOwnerId != currentUser.id);
      if (isNotPostOwner) {
        activityFeedReference.document(postOwnerId).collection("feedItems").add({
          "type": "comment",
          "commentData": commentTextEditingController.text,
          "postId": postId,
          "userId": currentUser.id,
          "username": currentUser.username,
          "userProfileImg": currentUser.url,
          "url": postImageUrl,
          "timestamp": DateTime.now(),
          "userProfileName": currentUser.profileName
        });
      }
      commentTextEditingController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, strTitle: "Comments"),
      body: Column(
        children: <Widget>[
          Expanded(
            child: retrieveComments(),
          ),
          Divider(),
          ListTile(
            title: TextFormField(
              controller: commentTextEditingController,
              decoration: InputDecoration(
                  labelText: "Write something about this Favour...",
                  labelStyle: TextStyle(fontSize: 13, fontFamily: 'MontserratMedium', color: Color(0xFF5F7ED9)),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xff607dd9))),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white))
              ),
              style: TextStyle(color: Color(0xFF2849A6)),
            ),
            trailing: OutlineButton(
                onPressed: saveComment,
                borderSide: BorderSide.none,
                child: Text("Send", style: TextStyle(color: Color(0xFF05268D), fontFamily: 'MontserratBold'))
            ),
          ),
        ],
      ),
    );
  }
}

class Comment extends StatelessWidget {
  final String username;
  final String userId;
  final String url;
  final String comment;
  final Timestamp timestamp;

  Comment({this.username, this.userId, this.url, this.comment, this.timestamp});

  factory Comment.fromDocument(DocumentSnapshot documentSnapshot) {
    return Comment(
        username: documentSnapshot["username"],
        userId: documentSnapshot["userId"],
        url: documentSnapshot["url"],
        comment: documentSnapshot["comment"],
        timestamp: documentSnapshot["timestamp"]
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.0),
      child: Container(
        color: Colors.white,
        child: Column(
          children: <Widget>[
            ListTile(
              onTap: () => displayUserProfile(context, userProfileId: userId, userUsrName: username, userProfileImg: url),
                title: RichText(
                  text: TextSpan(
                    text: "$username: ",
                    style: TextStyle(fontSize: 15.0, color: Color(0xFF05268D), fontFamily: 'MontserratSemiBold'),
                    children: <TextSpan>[
                      TextSpan(
                          text: "$comment",
                          style: TextStyle(fontSize: 15.0, color: Color(0xFF2849A6), fontFamily: 'MontserratMedium')
                      ),
                    ],
                  ),
                ),
                leading: CircleAvatar(
                  backgroundImage: CachedNetworkImageProvider(url),
                ),
                subtitle: Text(tAgo.format(timestamp.toDate()), style: TextStyle(color: Color(0xFF5F7ED9), fontFamily: 'MontserratMedium'))
            ),
          ],
        ),
      ),
    );
  }
  displayUserProfile(BuildContext context, {String userProfileId, String userUsrName, String userProfileImg}) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage(userProfileId: userProfileId, userUsrName: userUsrName,  userProfileImg: userProfileImg)));
  }
}

