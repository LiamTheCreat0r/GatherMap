import 'package:flutter/material.dart';
import 'package:gathermap/controllers/requests/request.dart';
import 'package:gathermap/controllers/utils/http_container.dart';
import 'package:gathermap/controllers/utils/type_object.dart';

//Move it to the test file
void main() async{
  //Test Get
  Object blockedUser = await RequestBlockedUser.get(BigInt.from(5));
  print("Result get ${blockedUser.toString()}");

  //Test Post
  // BlockedUser blockedUserTest = BlockedUser(
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
  // await RequestBlockedUser.post(blockedUserTest.toJson());

  //Test Put
  // BlockedUser blockedUserTestPut = BlockedUser(
  //     id: BigInt.from(8),
  //     ownerId: BigInt.from(21),
  //     scheduledAt: DateTime.now(),
  //     location: 'DIZAPOJDOIZANDNZAOI',
  //     createdAt: DateTime.now(),
  //     name: "TestPut",
  //     emojiIcon: '🤷‍♀️',
  //     color: 'post',
  //     isPublic: true);
  // await RequestBlockedUser.put(blockedUserTestPut.id!,blockedUserTestPut.toJson());

  //Test Post
  // BlockedUser blockedUserTestPost = BlockedUser(
  //     id: BigInt.from(8),
  //     ownerId: BigInt.from(21),
  //     scheduledAt: DateTime.now(),
  //     location: 'Here',
  //     createdAt: DateTime.now(),
  //     name: "TestPatch",
  //     emojiIcon: '🤷‍♀️',
  //     color: 'black',
  //     isPublic: true);
  // await RequestBlockedUser.patch(blockedUserTestPost.id!,blockedUserTestPost.toJson());

  //Test Delete
  // await RequestBlockedUser.delete(BigInt.from(14));
}

class RequestBlockedUser {
  // URI to blockedUser endpoint
  static final TypeObject _type = TypeObject.BLOCKED_USER;

  static Future<Object> get(BigInt? id) async {
    HTTPContainer recuperation = await Request.get(_type,id);
    if(recuperation.getCode()!=200){
      return false;
    }
    return recuperation.getData()!;
  }

  // Create a new blockedUser
  static Future<HTTPContainer> post(Map<String, dynamic> data) async {
    return await Request.post(_type, data);
  }

  // delete an blockedUser
  static Future<HTTPContainer> delete(BigInt id) async {
    return await Request.delete(_type, id);
  }

  // Update an blockedUser
  static Future<HTTPContainer> put(BigInt id, Map<String, dynamic> data) async {
    return await Request.put(_type, id, data);
  }

  // Patch an blockedUser
  static Future<HTTPContainer> patch(BigInt id, Map<String, dynamic> data) async {
    return await Request.patch(_type, id, data);
  }
}