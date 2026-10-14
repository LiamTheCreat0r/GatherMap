import 'package:flutter/material.dart';
import 'package:gathermap/controllers/requests/request.dart';
import 'package:gathermap/controllers/utils/http_container.dart';
import 'package:gathermap/controllers/utils/type_object.dart';
import 'package:gathermap/models/event_invitation.dart';

//Move it to the test file
void main() async{
  //Test Get
  Object message = await RequestMessage.get("");
  print("Result get ${message.toString()}");

  //Test Post
  // Message messageTest = Message(
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
  // await RequestMessage.post(messageTest.toJson());

  //Test Put
  // Message messageTestPut = Message(
  //     id: BigInt.from(8),
  //     ownerId: BigInt.from(21),
  //     scheduledAt: DateTime.now(),
  //     location: 'DIZAPOJDOIZANDNZAOI',
  //     createdAt: DateTime.now(),
  //     name: "TestPut",
  //     emojiIcon: '🤷‍♀️',
  //     color: 'post',
  //     isPublic: true);
  // await RequestMessage.put(messageTestPut.id!,messageTestPut.toJson());

  //Test Post
  // Message messageTestPost = Message(
  //     id: BigInt.from(8),
  //     ownerId: BigInt.from(21),
  //     scheduledAt: DateTime.now(),
  //     location: 'Here',
  //     createdAt: DateTime.now(),
  //     name: "TestPatch",
  //     emojiIcon: '🤷‍♀️',
  //     color: 'black',
  //     isPublic: true);
  // await RequestMessage.patch(messageTestPost.id!,messageTestPost.toJson());

  //Test Delete
  await RequestMessage.delete("");
}

class RequestMessage {
  // URI to message endpoint
  static final TypeObject _type = TypeObject.MESSAGE;

  static Future<Object> get(String? id) async {
    HTTPContainer recuperation = await Request.get(_type,id);
    if(recuperation.getCode()!=200){
      return false;
    }
    return recuperation.getData()!;
  }

  // Create a new message
  static Future<HTTPContainer> post(Map<String, dynamic> data) async {
    return await Request.post(_type, data);
  }

  // delete an message
  static Future<HTTPContainer> delete(String id) async {
    return await Request.delete(_type, id);
  }

  // Update an message
  static Future<HTTPContainer> put(String id, Map<String, dynamic> data) async {
    return await Request.put(_type, id, data);
  }

  // Patch an message
  static Future<HTTPContainer> patch(String id, Map<String, dynamic> data) async {
    return await Request.patch(_type, id, data);
  }
}