import 'package:flutter/material.dart';
import 'package:gathermap/controllers/requests/request.dart';
import 'package:gathermap/controllers/utils/http_container.dart';
import 'package:gathermap/controllers/utils/type_object.dart';
import 'package:gathermap/models/user.dart';

//Move it to the test file
void main() async{
  //Test Get
  Object user = await RequestUser.get("");
  print("Result get ${user.toString()}");

  //Test Post
  // User userTest = User(
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
  // await RequestUser.post(userTest.toJson());

  //Test Put
  // User userTestPut = User(
  //     id: BigInt.from(8),
  //     ownerId: BigInt.from(21),
  //     scheduledAt: DateTime.now(),
  //     location: 'DIZAPOJDOIZANDNZAOI',
  //     createdAt: DateTime.now(),
  //     name: "TestPut",
  //     emojiIcon: '🤷‍♀️',
  //     color: 'post',
  //     isPublic: true);
  // await RequestUser.put(userTestPut.id!,userTestPut.toJson());

  //Test Post
  // User userTestPost = User(
  //     id: BigInt.from(8),
  //     ownerId: BigInt.from(21),
  //     scheduledAt: DateTime.now(),
  //     location: 'Here',
  //     createdAt: DateTime.now(),
  //     name: "TestPatch",
  //     emojiIcon: '🤷‍♀️',
  //     color: 'black',
  //     isPublic: true);
  // await RequestUser.patch(userTestPost.id!,userTestPost.toJson());

  //Test Delete
  await RequestUser.delete("");
}

class RequestUser {
  // URI to user endpoint
  static final TypeObject _type = TypeObject.USER;

  static Future<Object> get(String? id) async {
    HTTPContainer recuperation = await Request.get(_type,id);
    if(recuperation.getCode()!=200){
      return false;
    }
    return recuperation.getData()!;
  }

  // Create a new user
  static Future<HTTPContainer> post(Map<String, dynamic> data) async {
    return await Request.post(_type, data);
  }

  // delete an user
  static Future<HTTPContainer> delete(String id) async {
    return await Request.delete(_type, id);
  }

  // Update an user
  static Future<HTTPContainer> put(String id, Map<String, dynamic> data) async {
    return await Request.put(_type, id, data);
  }

  // Patch an user
  static Future<HTTPContainer> patch(String id, Map<String, dynamic> data) async {
    return await Request.patch(_type, id, data);
  }
}