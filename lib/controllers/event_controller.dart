import "package:gathermap/controllers/utils/json_utils.dart";
import "package:gathermap/controllers/utils/type_request.dart";

import "../models/event.dart";

class EventController {

  static EventController? _instance;
  EventController._internal();

  static EventController getInstance() {
    _instance ??= EventController._internal();
    return _instance!;
  }

  Future<Set<Event>> getIncomingEvents() async{
    List<dynamic>? json = await JsonUtils.import(_type.getPath());
    Set<Event> listeEvent = <Event>{};

    return listeJoueur;
  }

  Future<Joueur?> getPastEvent(int idRecherche) async {
    // 1. Récupération de la liste
    List<dynamic>? jsonList = await JsonUtils.import(_type.getPath());

    // 2. Vérification si la liste est nulle ou vide
    if (jsonList == null || jsonList.isEmpty) return null;

    try {
      // 3. Recherche de l'élément avec l'ID spécifique
      // On utilise .firstWhere pour s'arrêter dès qu'on trouve le bon
      final joueurData = jsonList.firstWhere(
            (element) => element['id'] == idRecherche,
        orElse: () => null,
      );

      // 4. Conversion du Map JSON en objet Joueur
      if (joueurData != null) {
        return Joueur.fromArray(joueurData);
      }
    } catch (e) {
      print("Erreur lors de la récupération du joueur : $e");
    }
    return null; // Retourne null si rien n'est trouvé
  }

  Future<bool> creerJoueur(Joueur joueur) async {
    // 1. Envoie de la requete
    HTTPContainer result = await JoueurRequetes.post(joueur.toArray());
    if (result.getCode() != 201) {
      return false;
    }
    await JoueurControleur.RafraichirListe();
    return true;
  }

  Future<bool> modifierJoueur(int id,Joueur joueur) async {
import '../Modele/Joueur/Joueur.dart';
import '../Modele/Requetes/JoueurRequetes.dart';
import '../Utils/HTTPContainer.dart';
import '../Utils/JsonUtils.dart';
import '../Utils/Type.dart';

class JoueurControleur {

  static JoueurControleur? _instance;
  static final TypeObjet _type = TypeObjet.JOUEURS;
  JoueurControleur._internal();

  static JoueurControleur getInstance() {
    _instance ??= JoueurControleur._internal();
    return _instance!;
  }

  static Future<bool> RafraichirListe() async{
    bool reussiteImport = await JoueurRequetes.get();
    return reussiteImport;
  }

  Future<Set<Joueur>> getAllJoueurs() async{
    List<dynamic>? json = await JsonUtils.import(_type.getPath());
    Set<Joueur> listeJoueur = <Joueur>{};
    if(json!=null){
      for(Map<String,dynamic> joueurArray in json){
        listeJoueur.add(Joueur.fromArray(joueurArray));
      }
    }

    return listeJoueur;
  }

  Future<Joueur?> getJoueur(int idRecherche) async {
    // 1. Récupération de la liste
    List<dynamic>? jsonList = await JsonUtils.import(_type.getPath());

    // 2. Vérification si la liste est nulle ou vide
    if (jsonList == null || jsonList.isEmpty) return null;

    try {
      // 3. Recherche de l'élément avec l'ID spécifique
      // On utilise .firstWhere pour s'arrêter dès qu'on trouve le bon
      final joueurData = jsonList.firstWhere(
            (element) => element['id'] == idRecherche,
        orElse: () => null,
      );

      // 4. Conversion du Map JSON en objet Joueur
      if (joueurData != null) {
        return Joueur.fromArray(joueurData);
      }
    } catch (e) {
      print("Erreur lors de la récupération du joueur : $e");
    }
    return null; // Retourne null si rien n'est trouvé
  }

  Future<bool> creerJoueur(Joueur joueur) async {
    // 1. Envoie de la requete
    HTTPContainer result = await JoueurRequetes.post(joueur.toArray());
    if (result.getCode() != 201) {
      return false;
    }
    await JoueurControleur.RafraichirListe();
    return true;
  }

  Future<bool> modifierJoueur(int id,Joueur joueur) async {
    // 1. Envoie de la requete
    HTTPContainer result = await JoueurRequetes.put(id,joueur.toArray());
    if (result.getCode() != 204) {
      return false;
    }
    JoueurControleur.RafraichirListe();
    return true;
  }
