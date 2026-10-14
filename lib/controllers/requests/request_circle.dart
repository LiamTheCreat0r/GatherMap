import 'package:flutter/material.dart';
import 'package:gathermap/controllers/requests/request.dart';
import 'package:gathermap/controllers/utils/http_container.dart';
import 'package:gathermap/controllers/utils/type_object.dart';
import 'package:gathermap/models/circle.dart';

//Move it to the test file
void main() async{
  //Test Get
  Object circle = await RequestCircle.get("");
  print("Result get ${circle.toString()}");

  //Test Post
  // Circle circleTest = Circle(
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
  // await RequestCircle.post(circleTest.toJson());

  //Test Put
  // Circle circleTestPut = Circle(
  //     id: BigInt.from(8),
  //     ownerId: BigInt.from(21),
  //     scheduledAt: DateTime.now(),
  //     location: 'DIZAPOJDOIZANDNZAOI',
  //     createdAt: DateTime.now(),
  //     name: "TestPut",
  //     emojiIcon: '🤷‍♀️',
  //     color: 'post',
  //     isPublic: true);
  // await RequestCircle.put(circleTestPut.id!,circleTestPut.toJson());

  //Test Post
  // Circle circleTestPost = Circle(
  //     id: BigInt.from(8),
  //     ownerId: BigInt.from(21),
  //     scheduledAt: DateTime.now(),
  //     location: 'Here',
  //     createdAt: DateTime.now(),
  //     name: "TestPatch",
  //     emojiIcon: '🤷‍♀️',
  //     color: 'black',
  //     isPublic: true);
  // await RequestCircle.patch(circleTestPost.id!,circleTestPost.toJson());

  //Test Delete
  await RequestCircle.delete("");
}

class RequestCircle {
  // URI to circle endpoint
  static final TypeObject _type = TypeObject.CIRCLE;

  static Future<Object> get(String? id) async {
    HTTPContainer recuperation = await Request.get(_type,id);
    if(recuperation.getCode()!=200){
      return false;
    }
    return recuperation.getData()!;
  }

  // Create a new circle
  static Future<HTTPContainer> post(Map<String, dynamic> data) async {
    return await Request.post(_type, data);
  }

  // delete an circle
  static Future<HTTPContainer> delete(String id) async {
    return await Request.delete(_type, id);
  }

  // Update an circle
  static Future<HTTPContainer> put(String id, Map<String, dynamic> data) async {
    return await Request.put(_type, id, data);
  }

  // Patch an circle
  static Future<HTTPContainer> patch(String id, Map<String, dynamic> data) async {
    return await Request.patch(_type, id, data);
  }
}