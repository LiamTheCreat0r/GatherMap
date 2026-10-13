import 'package:flutter/material.dart';

class AccountPageWidget extends StatelessWidget {
  const AccountPageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: AccountPage());
  }
}

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Compte'),
        ),
      body: Column(
        children: [
          Align(alignment: Alignment.center,
            child:Row(
              children:[
                Card(child: Text("Évènement")),
                Card(child: Text("à venir")),
                Card(child: Text("organisée"))]
              )
          ),
          ElevatedButton(onPressed: null, child: Text("Mode Sombre")),
          ElevatedButton(onPressed: null, child: Text("Notifications")),
          ElevatedButton(onPressed: null, child: Text("Confidentialité")),
          ElevatedButton(onPressed: null, child: Text("Demande d'amis")),
          ElevatedButton(onPressed: null, child: Text("Aide")),
          ElevatedButton(onPressed: null, child: Text("Se déconnecter")),
          
          


        ]
        )
    );
  }
}