import 'package:flutter/material.dart';
import 'package:gathermap/views/account_page.dart';
import '../test_page_1.dart';
import '../test_page_2.dart';



class Navbar extends StatelessWidget {
    const Navbar({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: 1,
      length: 4,
      child: Scaffold(
        bottomNavigationBar: BottomAppBar(
          child: const TabBar(
            tabs: <Widget>[
              Tab(icon: Icon(Icons.person)),
              Tab(icon: Icon(Icons.home)),
              Tab(icon: Icon(Icons.play_arrow)),
              Tab(icon: Icon(Icons.settings))
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            ScaffoldExampleApp(),
            ScaffoldExampleApp2(),
            ScaffoldExampleApp(),
            AccountPage()
          ],
        ),
      ),
    );
  }
}
