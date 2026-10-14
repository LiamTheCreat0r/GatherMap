import 'package:flutter/material.dart';
import 'package:gathermap/controllers/requests/request.dart';
import 'package:gathermap/controllers/utils/http_container.dart';
import 'package:gathermap/controllers/utils/type_object.dart';
import 'package:gathermap/models/chat.dart';

//Move it to the test file
void main() async{
  //Test Get
  Object chat = await RequestChat.get("");
  print("Result get ${chat.toString()}");

  //Test Post
  // Chat chatTest = Chat(
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
  // await RequestChat.post(chatTest.toJson());

  //Test Put
  // Chat chatTestPut = Chat(
  //     id: BigInt.from(8),
  //     ownerId: BigInt.from(21),
  //     scheduledAt: DateTime.now(),
  //     location: 'DIZAPOJDOIZANDNZAOI',
  //     createdAt: DateTime.now(),
  //     name: "TestPut",
  //     emojiIcon: '🤷‍♀️',
  //     color: 'post',
  //     isPublic: true);
  // await RequestChat.put(chatTestPut.id!,chatTestPut.toJson());

  //Test Post
  // Chat chatTestPost = Chat(
  //     id: BigInt.from(8),
  //     ownerId: BigInt.from(21),
  //     scheduledAt: DateTime.now(),
  //     location: 'Here',
  //     createdAt: DateTime.now(),
  //     name: "TestPatch",
  //     emojiIcon: '🤷‍♀️',
  //     color: 'black',
  //     isPublic: true);
  // await RequestChat.patch(chatTestPost.id!,chatTestPost.toJson());

  //Test Delete
  await RequestChat.delete("");
}

class RequestChat {
  // URI to chat endpoint
  static final TypeObject _type = TypeObject.CHAT;

  static Future<Object> get(String? id) async {
    HTTPContainer recuperation = await Request.get(_type,id);
    if(recuperation.getCode()!=200){
      return false;
    }
    return recuperation.getData()!;
  }

  // Create a new chat
  static Future<HTTPContainer> post(Map<String, dynamic> data) async {
    return await Request.post(_type, data);
  }

  // delete an chat
  static Future<HTTPContainer> delete(String id) async {
    return await Request.delete(_type, id);
  }

  // Update an chat
  static Future<HTTPContainer> put(String id, Map<String, dynamic> data) async {
    return await Request.put(_type, id, data);
  }

  // Patch an chat
  static Future<HTTPContainer> patch(String id, Map<String, dynamic> data) async {
    return await Request.patch(_type, id, data);
  }
}