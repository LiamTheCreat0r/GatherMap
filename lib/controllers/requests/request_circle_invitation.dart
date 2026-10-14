import 'package:flutter/material.dart';
import 'package:gathermap/controllers/requests/request.dart';
import 'package:gathermap/controllers/utils/http_container.dart';
import 'package:gathermap/controllers/utils/type_object.dart';
import 'package:gathermap/models/circle_member.dart';

//Move it to the test file
void main() async{
  //Test Get
  Object circle_member = await RequestCircle_Member.get("");
  print("Result get ${circle_member.toString()}");

  //Test Post
  // Circle_Member circle_memberTest = Circle_Member(
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
  // await RequestCircle_Member.post(circle_memberTest.toJson());

  //Test Put
  // Circle_Member circle_memberTestPut = Circle_Member(
  //     id: BigInt.from(8),
  //     ownerId: BigInt.from(21),
  //     scheduledAt: DateTime.now(),
  //     location: 'DIZAPOJDOIZANDNZAOI',
  //     createdAt: DateTime.now(),
  //     name: "TestPut",
  //     emojiIcon: '🤷‍♀️',
  //     color: 'post',
  //     isPublic: true);
  // await RequestCircle_Member.put(circle_memberTestPut.id!,circle_memberTestPut.toJson());

  //Test Post
  // Circle_Member circle_memberTestPost = Circle_Member(
  //     id: BigInt.from(8),
  //     ownerId: BigInt.from(21),
  //     scheduledAt: DateTime.now(),
  //     location: 'Here',
  //     createdAt: DateTime.now(),
  //     name: "TestPatch",
  //     emojiIcon: '🤷‍♀️',
  //     color: 'black',
  //     isPublic: true);
  // await RequestCircle_Member.patch(circle_memberTestPost.id!,circle_memberTestPost.toJson());

  //Test Delete
  await RequestCircle_Member.delete("");
}

class RequestCircle_Member {
  // URI to circle_member endpoint
  static final TypeObject _type = TypeObject.CIRCLE_MEMBER;

  static Future<Object> get(String? id) async {
    HTTPContainer recuperation = await Request.get(_type,id);
    if(recuperation.getCode()!=200){
      return false;
    }
    return recuperation.getData()!;
  }

  // Create a new circle_member
  static Future<HTTPContainer> post(Map<String, dynamic> data) async {
    return await Request.post(_type, data);
  }

  // delete an circle_member
  static Future<HTTPContainer> delete(String id) async {
    return await Request.delete(_type, id);
  }

  // Update an circle_member
  static Future<HTTPContainer> put(String id, Map<String, dynamic> data) async {
    return await Request.put(_type, id, data);
  }

  // Patch an circle_member
  static Future<HTTPContainer> patch(String id, Map<String, dynamic> data) async {
    return await Request.patch(_type, id, data);
  }
}