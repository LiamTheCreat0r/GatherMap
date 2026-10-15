import 'package:flutter/widgets.dart';
import 'package:gathermap/logs.dart';
import 'package:gathermap/main.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Logs.init();
  // Test.test();
}

// USAGE
// class Test {
//   static final _log = Logs.forClass('Test'); Add this line to a class

//   static Future<void> test() async {
//     try {
//       _log.info('Tentative de connexion');
//     } catch (e, s) {
//       _log.severe('Connexion échouée', e, s);
//     }
//   }
// }