import 'package:flutter/material.dart';
import '../core/theme/custom_colors.dart';
import './widgets/page_header.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CustomColors>()!;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      
      backgroundColor: colors.mainBackgroundColor,
      body: Column(
        spacing: 10,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          const PageHeader(title: 'Mon Compte'),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            
            children: [
            Container(
            constraints: BoxConstraints(
              minWidth: 100,
              maxWidth: 400,
              // Fixe la hauteur maximale à 25% de la hauteur de l'écran
              maxHeight: screenHeight * 0.25, 
              minHeight: 100,
            ), child: 
              Card(child: Text("Évenements"))
            ),
            
            Spacer(flex: 2),
            Container(
            constraints: BoxConstraints(
              minWidth: 100,
              maxWidth: 400,
              // Fixe la hauteur maximale à 25% de la hauteur de l'écran
              maxHeight: screenHeight * 0.25, 
              minHeight: 100,
            ), child: 
              Card(child: Text("A venir"))
            ),
            
            Spacer(flex: 2),

            Container(
            constraints: BoxConstraints(
              minWidth: 100,
              maxWidth: 400,
              // Fixe la hauteur maximale à 25% de la hauteur de l'écran
              maxHeight: screenHeight * 0.25, 
              minHeight: 100,
            ), child: 
              Card(child: Text("Organisés"))
            )
            ]
          ),

          
          
          ElevatedButton(
            onPressed: null, 
            child: Text("Notifications"),
            ),
          
          ElevatedButton(onPressed: null, child: Text("Confidentialité")),
          
          ElevatedButton(onPressed: null, child: Text("Demande d'amis")),
          
          ElevatedButton(onPressed: null, child: Text("Aide")),
          
          ElevatedButton(onPressed: null, child: Text("Se déconnecter")),

        ]
        )
    );
  }
}