import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gathermap/controllers/requests/environment.dart';
import 'package:gathermap/models/event.dart';

//Move it to the test file
void main() async{
  //Test Get
  await dotenv.load(fileName: '.env');
  print("Result URL ${Environment.getUrl()}");
  print("Result KEY ${Environment.getServApi()}");
}