import 'package:flutter/material.dart';
import 'package:gathermap/controllers/requests/request.dart';
import 'package:gathermap/controllers/utils/http_container.dart';
import 'package:gathermap/controllers/utils/type_object.dart';
import 'package:gathermap/models/event_invitation.dart';

//Move it to the test file
void main() async{
  //Test Get
  Object eventInvitation = await RequestEventInvitation.get("");
  print("Result get ${eventInvitation.toString()}");

  //Test Post
  // EventInvitation eventInvitationTest = EventInvitation(
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
  // await RequestEventInvitation.post(eventInvitationTest.toJson());

  //Test Put
  // EventInvitation eventInvitationTestPut = EventInvitation(
  //     id: BigInt.from(8),
  //     ownerId: BigInt.from(21),
  //     scheduledAt: DateTime.now(),
  //     location: 'DIZAPOJDOIZANDNZAOI',
  //     createdAt: DateTime.now(),
  //     name: "TestPut",
  //     emojiIcon: '🤷‍♀️',
  //     color: 'post',
  //     isPublic: true);
  // await RequestEventInvitation.put(eventInvitationTestPut.id!,eventInvitationTestPut.toJson());

  //Test Post
  // EventInvitation eventInvitationTestPost = EventInvitation(
  //     id: BigInt.from(8),
  //     ownerId: BigInt.from(21),
  //     scheduledAt: DateTime.now(),
  //     location: 'Here',
  //     createdAt: DateTime.now(),
  //     name: "TestPatch",
  //     emojiIcon: '🤷‍♀️',
  //     color: 'black',
  //     isPublic: true);
  // await RequestEventInvitation.patch(eventInvitationTestPost.id!,eventInvitationTestPost.toJson());

  //Test Delete
  await RequestEventInvitation.delete("");
}

class RequestEventInvitation {
  // URI to eventInvitation endpoint
  static final TypeObject _type = TypeObject.EVENT_INVITATION;

  static Future<Object> get(String? id) async {
    HTTPContainer recuperation = await Request.get(_type,id);
    if(recuperation.getCode()!=200){
      return false;
    }
    return recuperation.getData()!;
  }

  // Create a new eventInvitation
  static Future<HTTPContainer> post(Map<String, dynamic> data) async {
    return await Request.post(_type, data);
  }

  // delete an eventInvitation
  static Future<HTTPContainer> delete(String id) async {
    return await Request.delete(_type, id);
  }

  // Update an eventInvitation
  static Future<HTTPContainer> put(String id, Map<String, dynamic> data) async {
    return await Request.put(_type, id, data);
  }

  // Patch an eventInvitation
  static Future<HTTPContainer> patch(String id, Map<String, dynamic> data) async {
    return await Request.patch(_type, id, data);
  }
}