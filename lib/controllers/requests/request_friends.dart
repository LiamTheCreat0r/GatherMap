import 'package:flutter/material.dart';
import 'package:gathermap/controllers/requests/request.dart';
import 'package:gathermap/controllers/utils/http_container.dart';
import 'package:gathermap/controllers/utils/type_object.dart';
import 'package:gathermap/models/event_invitation.dart';

//Move it to the test file
void main() async{
  //Test Get
  Object Friend = await RequestFriend.get(BigInt.from(5));
  print("Result get ${Friend.toString()}");

  //Test Post
  // Friend FriendTest = Friend(
  //     id: null,
  //     ownerId: BigInt.from(21),
  //     scheduledAt: DateTime.now(),
  //     location: 'Here',
  //     createdAt: null,
  //     name: "Test2Post",
  //     emojiIcon: '🤷‍♀️',
  //     color: 'black',
  //     isPublic: true
  // );
  // await RequestFriend.post(FriendTest.toJson());

  //Test Put
  // Friend FriendTestPut = Friend(
  //     id: BigInt.from(8),
  //     ownerId: BigInt.from(21),
  //     scheduledAt: DateTime.now(),
  //     location: 'DIZAPOJDOIZANDNZAOI',
  //     createdAt: DateTime.now(),
  //     name: "TestPut",
  //     emojiIcon: '🤷‍♀️',
  //     color: 'post',
  //     isPublic: true);
  // await RequestFriend.put(FriendTestPut.id!,FriendTestPut.toJson());

  //Test Post
  // Friend FriendTestPost = Friend(
  //     id: BigInt.from(8),
  //     ownerId: BigInt.from(21),
  //     scheduledAt: DateTime.now(),
  //     location: 'Here',
  //     createdAt: DateTime.now(),
  //     name: "TestPatch",
  //     emojiIcon: '🤷‍♀️',
  //     color: 'black',
  //     isPublic: true);
  // await RequestFriend.patch(FriendTestPost.id!,FriendTestPost.toJson());

  //Test Delete
  await RequestFriend.delete(BigInt.from(14));
}

class RequestFriend {
  // URI to Friend endpoint
  static final TypeObject _type = TypeObject.FRIEND;

  static Future<Object> get(BigInt? id) async {
    HTTPContainer recuperation = await Request.get(_type,id);
    if(recuperation.getCode()!=200){
      return false;
    }
    return recuperation.getData()!;
  }

  // Create a new Friend
  static Future<HTTPContainer> post(Map<String, dynamic> data) async {
    return await Request.post(_type, data);
  }

  // delete an Friend
  static Future<HTTPContainer> delete(BigInt id) async {
    return await Request.delete(_type, id);
  }

  // Update an Friend
  static Future<HTTPContainer> put(BigInt id, Map<String, dynamic> data) async {
    return await Request.put(_type, id, data);
  }

  // Patch an Friend
  static Future<HTTPContainer> patch(BigInt id, Map<String, dynamic> data) async {
    return await Request.patch(_type, id, data);
  }
}