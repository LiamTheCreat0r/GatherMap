# Feature Specification: Plateforme complète GatherMap (d'après les 29 user stories du tableau GitHub)

**Feature Branch**: `create-gathermap-product-spec`

**Created**: 2026-11-20

**Status**: Draft

**Input**: User description: "Le projet est défini par toutes les user story disponible sur le repo github (https://github.com/users/LiamTheCreat0r/projects/2)"

## User Scenarios & Testing *(mandatory)*

Les scénarios ci-dessous couvrent l'intégralité des 29 user stories du tableau public
« GatherMap Kanban » (projet 2) tel que consulté le 2026-11-20. La référence entre
parenthèses renvoie au numéro de la story sur le tableau, avec sa priorité et son
lot de livraison d'origine. Les stories déjà marquées « Done » sont conservées comme
exigences de non-régression.

### User Story 1 - Créer un compte et se connecter (Priority: P1)

Une personne crée son compte, se connecte et peut quitter la session en toute sécurité.
Toutes les autres fonctionnalités personnelles en dépendent.

**Why this priority**: Priorité P0 du tableau, présente dans les lots 1 (stories #10 et
#68). Aucun autre parcours personnalisé n'est possible sans identité.

**Independent Test**: Créer un compte, se déconnecter, se reconnecter, puis vérifier que
les informations du compte sont retrouvées.

**Acceptance Scenarios**:

1. **Given** une personne sans compte, **When** elle fournit les informations minimales
   demandées et valide, **Then** son compte est créé et elle accède à l'application.
2. **Given** une personne déjà inscrite et déconnectée, **When** elle se connecte puis
   se déconnecte, **Then** l'accès est refusé après la déconnexion et ses données restent
   intactes lors de la connexion suivante.

---

### User Story 2 - Créer un événement avec sa date, son heure et son lieu (Priority: P1)

Un organisateur définit un événement en renseignant ce qu'il fait, quand et où ; les
trois volets font partie du même parcours.

**Why this priority**: Priorité P0, lot 1, sprint 1 (stories #3, #5, #6). C'est la valeur
centrale du produit : sans événement correctement daté et localisé, la carte et l'agenda
n'ont aucun contenu.

**Independent Test**: Créer un événement en choisissant un lieu et une date/heure, puis
le retrouver dans la liste avec ces informations.

**Acceptance Scenarios**:

1. **Given** un utilisateur connecté, **When** il crée un événement avec un titre, une
   date, une heure et un lieu choisi, **Then** l'événement est enregistré et affiché avec
   l'ensemble de ces informations.
2. **Given** un utilisateur qui saisit une date passée ou une fin avant le début,
   **When** il valide, **Then** la création est refusée avec une indication corrigeable
   et aucune donnée n'est perdue.

---

### User Story 3 - Consulter les événements sur une carte (Priority: P1)

Un utilisateur voit où se déroulent les événements et ouvre leur fiche depuis la carte.

**Why this priority**: Priorité P0, lot 1, sprint 1 (story #7). C'est le mode de
découverte signature de GatherMap.

**Independent Test**: Depuis la carte, repérer un événement connu, ouvrir sa fiche et
reconnaître son titre et son lieu.

**Acceptance Scenarios**:

1. **Given** des événements ayant un lieu, **When** l'utilisateur ouvre la carte,
   **Then** chaque événement est représenté à son emplacement et peut être sélectionné.
2. **Given** un événement sélectionné sur la carte, **When** l'utilisateur ouvre sa
   fiche, **Then** il voit un résumé et peut accéder au détail complet.

---

### User Story 4 - Consulter les événements sous forme d'agenda (Priority: P1)

Un utilisateur parcourt les événements dans le temps, indépendamment de leur position
géographique.

**Why this priority**: Priorité P0, lot 1, sprint 1 (story #8). Cela complète la carte
pour les utilisateurs qui planifient par date.

**Independent Test**: Ouvrir l'agenda et vérifier que les événements créés apparaissent
dans l'ordre chronologique.

**Acceptance Scenarios**:

1. **Given** plusieurs événements sur des jours différents, **When** l'utilisateur
   ouvre l'agenda, **Then** ils sont regroupés par jour et classés par heure.
2. **Given** un événement sans lieu précis, **When** l'utilisateur consulte l'agenda,
   **Then** l'événement reste visible et consultable.

---

### User Story 5 - Consulter le détail d'un événement (Priority: P2)

Un utilisateur ouvre la fiche d'un événement pour en connaître toutes les informations
avant de décider d'y participer.

**Why this priority**: Priorité P1 du tableau, lot 1 (story #14). Le détail est le point
d'entrée vers la réponse, les photos et le chat.

**Independent Test**: Ouvrir la fiche d'un événement existant et vérifier que toutes les
informations publiées par l'organisateur y sont lisibles.

**Acceptance Scenarios**:

1. **Given** un événement publié, **When** un utilisateur autorisé ouvre son détail,
   **Then** il voit l'organisateur, la date, l'heure, le lieu, les participants et les
   informations propres au type d'événement.
2. **Given** un événement privé auquel l'utilisateur n'est pas invité, **When** il tente
   d'ouvrir son détail, **Then** aucune information privée n'est révélée.

---

### User Story 6 - Modifier un événement (Priority: P1)

Un organisateur corrige ou fait évoluer un événement après sa création.

**Why this priority**: Priorité P0, lot 1 (story #4). Les événements réels changent
souvent de date, d'heure ou de lieu.

**Independent Test**: Modifier le lieu d'un événement puis vérifier que la nouvelle
valeur apparaît dans le détail et sur la carte.

**Acceptance Scenarios**:

1. **Given** un organisateur sur sa propre fiche, **When** il modifie un champ puis
   enregistre, **Then** la modification est visible partout où l'événement est affiché.
2. **Given** un participant à un événement, **When** il tente de le modifier, **Then**
   l'action lui est refusée sans modifier les données.

---

### User Story 7 - Accepter ou refuser une invitation à un événement (Priority: P1)

Un invité répond à une invitation et l'organisateur connaît le verdict.

**Why this priority**: Priorité P0, lot 1 (story #9). Sans réponse, l'organisateur ne
peut pas savoir qui participe.

**Independent Test**: Inviter un utilisateur, accepter de son côté, puis vérifier qu'il
apparaît comme participant.

**Acceptance Scenarios**:

1. **Given** une invitation en attente, **When** l'invité accepte, **Then** il est
   compté comme participant et l'organisateur voit sa réponse.
2. **Given** une invitation en attente, **When** l'invité refuse, **Then** il n'est pas
   compté comme participant et peut changer d'avis tant que l'événement n'a pas eu lieu.

---

### User Story 8 - Centrer la carte sur sa propre localisation (Priority: P2)

Un utilisateur retrouve rapidement où il se trouve par rapport aux événements.

**Why this priority**: Priorité P1, lot 1 (story #12). Cela réduit l'effort de
recherche sur la carte.

**Independent Test**: Depuis la carte, activer le recentrage et vérifier que la vue
montre la position actuelle et les événements proches.

**Acceptance Scenarios**:

1. **Given** une autorisation de localisation accordée, **When** l'utilisateur active
   le recentrage, **Then** la carte est centrée sur sa position actuelle.
2. **Given** une autorisation refusée ou indisponible, **When** l'utilisateur active le
   recentrage, **Then** un message explicite lui est proposé et la carte reste utilisable.

---

### User Story 9 - Gérer qui ramène quoi (Priority: P1)

Dans un événement de type repas ou auberge espagnole, les participants répartissent les
plats ou objets à apporter afin d'éviter les doublons et les oublis.

**Why this priority**: Priorité P0, lot 1 (story #69). C'est la première fonctionnalité
de coordination concrète entre participants.

**Independent Test**: Créer une liste pour un événement, réserver un élément à deux
utilisateurs différents et vérifier l'état de la liste.

**Acceptance Scenarios**:

1. **Given** une liste d'éléments à apporter, **When** un participant réserve un
   élément encore libre, **Then** son nom est affiché à côté de cet élément pour tous
   les participants.
2. **Given** un élément déjà réservé, **When** un autre participant le réserve aussi,
   **Then** une confirmation ou un choix alternatif lui est proposé avant tout
   écrasement.
3. **Given** une erreur de répartition, **When** l'organisateur corrige l'affectation,
   **Then** la liste est mise à jour pour tous.

---

### User Story 10 - Ajouter des utilisateurs en amis (Priority: P1)

Un utilisateur construit son réseau pour inviter plus tard ses proches à ses événements.

**Why this priority**: Priorité P0, lot 1 (story #13). Le réseau d'amis alimente les
invitations et la conversation directe.

**Independent Test**: Envoyer une demande à un autre utilisateur, l'accepter de son
côté et vérifier que les deux comptes se voient comme amis.

**Acceptance Scenarios**:

1. **Given** un utilisateur trouvé par recherche, **When** une demande d'ami est
   envoyée puis acceptée, **Then** les deux comptes apparaissent dans la liste d'amis.
2. **Given** une demande refusée ou déjà en attente, **When** l'utilisateur recommence,
   **Then** aucun doublon n'est créé et un retour clair est affiché.

---

### User Story 11 - Créer et gérer un groupe (Priority: P2)

Un utilisateur crée un groupe, en définit les options, gère ses membres et modère les
échanges.

**Why this priority**: Priorité P1, lot 1 (stories #11 et #17). Les groupes servent de
cadre aux événements récurrents et aux conversations de groupe.

**Independent Test**: Créer un groupe, ajouter un membre, modifier une option puis
retirer ce membre, et vérifier l'état final du groupe.

**Acceptance Scenarios**:

1. **Given** un utilisateur connecté, **When** il crée un groupe avec un nom et des
   options, **Then** le groupe existe et son créateur en est l'administrateur.
2. **Given** un administrateur de groupe, **When** il ajoute ou retire un membre ou
   modère un contenu, **Then** la modification est effective pour tous les membres.
3. **Given** le dernier administrateur d'un groupe, **When** il tente de quitter le
   groupe sans le transférer, **Then** une étape de transfert ou de dissolution lui est
   demandée.

---

### User Story 12 - Converser dans le chat d'un événement (Priority: P2)

Les participants à un événement échangent au même endroit que la fiche de l'événement.

**Why this priority**: Priorité P1, lot 3 (story #16). Le chat lié à l'événement évite
de disperser les informations logistiques.

**Independent Test**: Participer à un événement, publier un message et vérifier qu'un
autre participant le voit.

**Acceptance Scenarios**:

1. **Given** un participant à un événement, **When** il publie un message dans le chat
   de l'événement, **Then** le message est visible par tous les participants.
2. **Given** une personne qui ne participe pas à un événement privé, **When** elle tente
   d'accéder au chat, **Then** l'accès lui est refusé.

---

### User Story 13 - Converser dans un groupe (Priority: P1)

Les membres d'un groupe discutent entre eux, indépendamment d'un événement donné.

**Why this priority**: Priorité P0, lot 3 (story #18). C'est le canal de discussion
le plus utilisé du tableau.

**Independent Test**: Rejoindre un groupe, publier un message et vérifier qu'un autre
membre le reçoit.

**Acceptance Scenarios**:

1. **Given** un membre d'un groupe, **When** il envoie un message, **Then** tous les
   membres voient le message dans l'historique du groupe.
2. **Given** un ancien membre retiré du groupe, **When** il consulte le groupe, **Then**
   il ne peut plus ni lire ni écrire dans la conversation.

---

### User Story 14 - Converser avec ses amis (Priority: P2)

Deux amis s'envoient des messages en privé.

**Why this priority**: Priorité P1, lot 3 (story #19). Cela complète les conversations
de groupe par un échange direct.

**Independent Test**: Depuis la liste d'amis, ouvrir une conversation et échanger un
message avec un ami.

**Acceptance Scenarios**:

1. **Given** deux utilisateurs devenus amis, **When** l'un envoie un message direct,
   **Then** l'autre le voit dans leur conversation et peut y répondre.
2. **Given** deux utilisateurs qui ne sont pas amis, **When** l'un tente d'écrire à
   l'autre, **Then** une demande de mise en relation est exigée avant tout message.

---

### User Story 15 - Modifier son compte (Priority: P3)

Un utilisateur met à jour les informations de son profil.

**Why this priority**: Priorité P2 du tableau, lot 1 (story #15). Utile, mais non
bloquant pour créer ou rejoindre un événement.

**Independent Test**: Modifier une information du profil puis vérifier qu'elle est
visible là où le profil est affiché.

**Acceptance Scenarios**:

1. **Given** un utilisateur connecté, **When** il modifie son profil et enregistre,
   **Then** la nouvelle information apparaît sur son profil et dans ses participations.
2. **Given** une saisie invalide, **When** l'utilisateur enregistre, **Then** la
   modification est refusée avec une indication précise.

---

### User Story 16 - Supprimer son compte (Priority: P2)

Un utilisateur peut demander la suppression définitive de son compte.

**Why this priority**: Priorité P1 du tableau, lot 1 (story #25). C'est une exigence de
maîtrise des données personnelles.

**Independent Test**: Sur un compte de test, demander la suppression, confirmer, puis
vérifier que le compte n'est plus accessible.

**Acceptance Scenarios**:

1. **Given** un compte sans événement ni groupe à sa charge, **When** l'utilisateur
   demande sa suppression et la confirme, **Then** son compte et ses informations
   personnelles ne sont plus accessibles.
2. **Given** un utilisateur qui organise des événements ou administre un groupe,
   **When** il demande la suppression, **Then** une étape de transfert ou d'archivage
   lui est proposée avant confirmation.

---

### User Story 17 - Déposer des photos dans un événement (Priority: P2)

Les participants ajoutent des photos à un événement pour en garder un souvenir commun.

**Why this priority**: Priorité P1, lot 4 (story #20). Les photos enrichissent
fortement la valeur perçue après l'événement.

**Independent Test**: Déposer une photo dans un événement puis vérifier qu'elle apparaît
dans la galerie de l'événement.

**Acceptance Scenarios**:

1. **Given** un participant à un événement, **When** il dépose une photo, **Then** la
   photo est associée à l'événement et visible par les participants.
2. **Given** un dépôt interrompu ou un fichier non accepté, **When** l'opération
   échoue, **Then** un message clair est affiché et l'événement reste inchangé.

---

### User Story 18 - Consulter les photos d'un événement (Priority: P3)

Les participants parcourent les photos de l'événement.

**Why this priority**: Priorité P2, lot 4 (story #21). Cela dépend du dépôt mais apporte
une valeur de consultation autonome.

**Independent Test**: Déposer deux photos, puis les ouvrir dans la galerie de
l'événement.

**Acceptance Scenarios**:

1. **Given** un événement contenant des photos, **When** un participant ouvre la
   galerie, **Then** il voit toutes les photos et peut les parcourir.
2. **Given** un événement sans photo, **When** un participant ouvre la galerie, **Then**
   un état vide explicite est affiché sans erreur.

---

### User Story 19 - Bénéficier de types d'événements dédiés (Priority: P2)

L'organisateur choisit un type d'événement — anniversaire, sport, voyage, restaurant,
auberge espagnole, etc. — et obtient les informations et fonctionnalités adaptées.

**Why this priority**: Priorité P1, lot 4 (story #22). C'est la brique la plus riche du
lot 4 et elle structure les autres fonctionnalités optionnelles.

**Independent Test**: Créer deux événements de types différents et vérifier que leurs
détails et leurs fonctionnalités diffèrent.

**Acceptance Scenarios**:

1. **Given** un organisateur qui crée un événement, **When** il choisit un type, **Then**
   la fiche propose les champs et les fonctions propres à ce type.
2. **Given** un événement existe déjà, **When** un participant consulte son détail,
   **Then** les informations spécifiques au type sont affichées sans confusion avec les
   champs génériques.

---

### User Story 20 - Ajouter des fonctionnalités complexes aux événements (Priority: P2)

Un organisateur anime son événement avec des sondages et peut partager des GIF dans les
échanges associés.

**Why this priority**: Priorité P1, lot 4 (story #23). Ces outils augmentent
l'engagement après la création de l'événement.

**Independent Test**: Créer un sondage sur un événement, voter, puis publier un GIF dans
la conversation et vérifier l'affichage pour les participants.

**Acceptance Scenarios**:

1. **Given** un événement, **When** l'organisateur crée un sondage et que des
   participants votent, **Then** les résultats sont visibles et chaque vote est compté
   une seule fois par participant.
2. **Given** un participant publie un GIF, **When** les autres participants consultent
   la conversation, **Then** le contenu s'affiche correctement.

---

### User Story 21 - Filtrer les événements (Priority: P3)

Un utilisateur réduit la liste des événements selon ses critères.

**Why this priority**: Priorité P2, lot 4 (story #24). Utile quand le nombre
d'événements augmente, mais non bloquant au démarrage.

**Independent Test**: Appliquer un filtre de date puis vérifier que seuls les
événements correspondants restent affichés.

**Acceptance Scenarios**:

1. **Given** une liste d'événements variés, **When** l'utilisateur applique un ou
   plusieurs filtres, **Then** seuls les événements correspondants sont affichés.
2. **Given** aucun événement ne correspond, **When** le filtre est appliqué, **Then** un
   état vide explicite est affiché avec la possibilité de réinitialiser le filtre.

---

### User Story 22 - Créer, modifier et rejoindre un événement public (Priority: P2)

Un organisateur rend un événement public et toute personne intéressée peut le découvrir
et le rejoindre sans invitation nominative.

**Why this priority**: Priorité P1, lot 5 (story #27). C'est le levier d'acquisition
d'utilisateurs au-delà du cercle d'amis.

**Independent Test**: Publier un événement public, le retrouver sans y être invité puis
le rejoindre, et vérifier l'apparition dans la liste des participants.

**Acceptance Scenarios**:

1. **Given** un événement public, **When** un utilisateur non invité le trouve et
   demande à le rejoindre, **Then** il est ajouté aux participants et accède aux
   fonctions réservées aux participants.
2. **Given** un organisateur d'événement public, **When** il modifie l'événement, **Then**
   les personnes l'ayant rejoint voient la version mise à jour.

---

### User Story 23 - Accéder à une page d'options (Priority: P1)

L'utilisateur dispose d'un point d'accès unique aux réglages de son compte et de
l'application.

**Why this priority**: Priorité P0 du tableau (story #28), malgré son intitulé
« optionnel s'il y a le temps » : sans page d'options, les préférences des stories #15,
#24 et #26 n'ont aucun emplacement naturel.

**Independent Test**: Ouvrir la page d'options depuis l'application et vérifier que les
catégories attendues sont présentes et accessibles.

**Acceptance Scenarios**:

1. **Given** un utilisateur connecté, **When** il ouvre la page d'options, **Then** il
   trouve les sections compte, confidentialité et apparence.
2. **Given** un utilisateur modifie un réglage dans une section, **When** il quitte et
   revient, **Then** le réglage est conservé.

---

### User Story 24 - Personnaliser l'apparence de l'application (Priority: P3)

L'utilisateur adapte l'affichage à ses préférences.

**Why this priority**: Priorité P2, lot 5 (story #26). Cela concerne le confort
d'utilisation, pas la réalisation des tâches principales.

**Independent Test**: Changer le thème puis vérifier que l'interface change et que le
choix persiste à la réouverture.

**Acceptance Scenarios**:

1. **Given** un utilisateur sur la page d'apparence, **When** il choisit un autre thème
   ou une autre taille de texte, **Then** l'interface est mise à jour immédiatement.
2. **Given** un réglage d'apparence choisi, **When** l'utilisateur relance l'application,
   **Then** son choix est conservé.

---

### User Story 25 - Modulariser sa page d'accueil (Priority: P2)

L'utilisateur compose son écran d'accueil avec les blocs qui lui sont utiles.

**Why this priority**: Priorité P1, lot 5, sprint 6 (story #29). Cela améliore l'accès
aux événements et aux conversations sans créer de nouvelle fonctionnalité métier.

**Independent Test**: Ajouter, déplacer et retirer un bloc de l'accueil puis vérifier
la nouvelle disposition après réouverture.

**Acceptance Scenarios**:

1. **Given** la page d'accueil par défaut, **When** l'utilisateur ajoute, réorganise ou
   retire un bloc parmi ceux proposés, **Then** la disposition est mise à jour.
2. **Given** une disposition personnalisée, **When** l'utilisateur quitte puis revient,
   **Then** il retrouve ses blocs et leur ordre.

---

### Edge Cases

- Deux organisateurs modifient simultanément le même événement : la dernière
  modification validée est indiquée et les conflits sur un même champ sont signalés.
- Un événement est supprimé alors que des réponses, photos ou messages existent : les
  participants sont informés et l'accès aux contenus associés est cohérent.
- Un invité accepte après la date de l'événement : l'action est refusée ou classée
  comme tardive sans effacer son intention.
- La localisation est refusée, absente ou temporairement indisponible : les événements
  restent consultables par liste et la carte ne bloque pas l'application.
- Un événement public rejoint par une personne dont le compte est ensuite supprimé :
  sa participation est retirée sans casser l'historique de l'événement.
- Le dernier membre d'un groupe en est l'administrateur : le groupe ne peut pas être
  laissé sans responsable.
- Deux participants réservent le même élément de la liste « qui ramène quoi » en même
  temps : une seule réservation est retenue et l'autre est avertie.
- Un dépôt de photo est interrompu : aucun fichier partiel n'est affiché comme photo
  valide et l'utilisateur peut réessayer.
- Un sondage reçoit des votes après sa clôture ou deux votes de la même personne : les
  résultats restent cohérents.
- Un filtre ne donne aucun résultat, ou les événements filtrés sont tous passés : un
  état vide explicite et une réinitialisation sont proposés.
- Un utilisateur change l'apparence de l'application pendant une conversation : la
  conversation et son historique restent inchangés.
- Une perte de connexion survient pendant la rédaction d'un événement, d'un message ou
  d'une réponse : le contenu rédigé est conservé et l'utilisateur est averti.
- Un utilisateur tente d'accéder à un événement privé, à des photos ou à un chat sans y
  être autorisé : aucune information n'est révélée.
- Un même utilisateur envoie plusieurs demandes d'ami ou plusieurs invitations : aucun
  doublon n'est créé.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001** (US1) : Le système MUST permettre de créer un compte avec les informations
  minimales nécessaires et d'y accéder immédiatement après validation.
- **FR-002** (US1) : Le système MUST permettre de se connecter, de se déconnecter et de
  retrouver ses données lors d'une connexion ultérieure.
- **FR-003** (US2) : Le système MUST permettre de créer un événement avec un titre, une
  date, une heure et un lieu, tous obligatoires ou explicitement facultatifs.
- **FR-004** (US2) : Le système MUST permettre de choisir un lieu depuis une recherche
  ou une carte, avec une saisie manuelle de secours.
- **FR-005** (US2) : Le système MUST refuser une date passée ou une fin antérieure au
  début, sans perdre les données déjà saisies.
- **FR-006** (US3, US5) : Le système MUST afficher chaque événement localisé à son
  emplacement sur la carte et permettre d'ouvrir sa fiche depuis celle-ci.
- **FR-007** (US4) : Le système MUST présenter les événements dans un agenda classé par
  jour et par heure, y compris ceux sans lieu précis.
- **FR-008** (US5) : Le système MUST afficher dans le détail l'organisateur, la date,
  l'heure, le lieu, les participants et les informations du type choisi.
- **FR-009** (US6) : Le système MUST permettre à l'organisateur seul de modifier un
  événement et propager la modification à tous les affichages concernés.
- **FR-010** (US7) : Le système MUST permettre d'inviter un utilisateur, d'accepter ou
  de refuser une invitation, et d'afficher la réponse à l'organisateur.
- **FR-011** (US7) : Le système MUST permettre de changer de réponse tant que
  l'événement n'a pas eu lieu.
- **FR-012** (US8) : Le système MUST permettre de recentrer la carte sur la position
  actuelle et d'expliquer clairement un refus d'accès à la localisation.
- **FR-013** (US9) : Le système MUST permettre aux participants de réserver des éléments
  dans la liste « qui ramène quoi » et à l'organisateur de corriger les affectations.
- **FR-014** (US9) : Le système MUST empêcher qu'un même élément soit attribué à deux
  personnes sans confirmation explicite.
- **FR-015** (US10) : Le système MUST permettre de rechercher un utilisateur, d'envoyer,
  d'accepter ou de refuser une demande d'ami, sans créer de doublon.
- **FR-016** (US11) : Le système MUST permettre de créer un groupe, de définir ses
  options et de gérer ses membres.
- **FR-017** (US11) : Le système MUST permettre à un administrateur de modérer le
  groupe et MUST empêcher le groupe de rester sans administrateur.
- **FR-018** (US12) : Le système MUST permettre aux participants d'un événement de lire
  et d'écrire dans le chat associé, et refuser l'accès aux autres.
- **FR-019** (US13) : Le système MUST permettre aux membres d'un groupe de lire et
  d'écrire dans la conversation du groupe, et d'en retirer l'accès aux anciens membres.
- **FR-020** (US14) : Le système MUST permettre à deux amis d'échanger des messages
  privés et exiger une mise en relation avant tout message entre inconnus.
- **FR-021** (US15) : Le système MUST permettre à un utilisateur de modifier ses
  informations de profil avec validation des saisies.
- **FR-022** (US16) : Le système MUST permettre de supprimer un compte après
  confirmation, avec transfert ou archivage préalable des éléments dont l'utilisateur
  est responsable.
- **FR-023** (US17) : Le système MUST permettre aux participants d'un événement de
  déposer une ou plusieurs photos et d'afficher un échec de dépôt sans corruption.
- **FR-024** (US18) : Le système MUST permettre de parcourir toutes les photos d'un
  événement et afficher un état vide quand il n'y en a pas.
- **FR-025** (US19) : Le système MUST proposer plusieurs types d'événements, dont
  anniversaire, sport, voyage, restaurant et auberge espagnole, chacun avec ses champs
  et fonctions spécifiques.
- **FR-026** (US20) : Le système MUST permettre de créer un sondage, de voter une seule
  fois par participant et d'afficher les résultats.
- **FR-027** (US20) : Le système MUST permettre de publier et d'afficher des GIF dans
  les conversations associées aux événements.
- **FR-028** (US21) : Le système MUST permettre de filtrer les événements par date, par
  type et par participation, de combiner les filtres et de les réinitialiser.
- **FR-029** (US22) : Le système MUST permettre de rendre un événement public, de le
  découvrir sans invitation et de le rejoindre avec un compte.
- **FR-030** (US22) : Le système MUST propager les modifications d'un événement public
  aux personnes qui l'ont rejoint.
- **FR-031** (US23) : Le système MUST fournir une page d'options regroupant au minimum
  les sections compte, confidentialité et apparence, avec conservation des réglages.
- **FR-032** (US24) : Le système MUST permettre de choisir un thème et une taille de
  texte, avec application immédiate et conservation du choix.
- **FR-033** (US25) : Le système MUST permettre d'ajouter, de réorganiser et de retirer
  des blocs sur la page d'accueil et de conserver la disposition choisie.
- **FR-034** (Global) : Le système MUST limiter l'accès aux événements privés, photos,
  chats et groupes aux seules personnes autorisées.
- **FR-035** (Global) : Le système MUST présenter les erreurs dans un langage compréhensible
  et demander confirmation avant toute action irréversible.
- **FR-036** (Global) : Le système MUST préserver le contenu en cours de rédaction et
  avertir l'utilisateur en cas de perte de connexion.
- **FR-037** (Global) : Le système MUST éviter les doublons d'invitations, de demandes
  d'ami et d'inscriptions au même événement.

### Key Entities *(include if feature involves data)*

- **Utilisateur / Profil** : personne identifiée, avec ses informations de contact, son
  nom affiché et ses préférences (apparence, disposition de l'accueil).
- **Événement** : activité avec un titre, un type, une date, une heure, un lieu, un
  organisateur, une visibilité (privée ou publique) et des participants.
- **Type d'événement** : catégorie (anniversaire, sport, voyage, restaurant, auberge
  espagnole, etc.) qui détermine les champs et les fonctions disponibles.
- **Invitation / Participation** : lien entre un utilisateur et un événement, avec un
  statut (en attente, accepté, refusé) et une date de réponse.
- **Affectation « qui ramène quoi »** : élément à apporter associé à un événement et à
  un participant, avec son état de réservation.
- **Groupe** : ensemble d'utilisateurs avec un nom, des options, des administrateurs et
  des membres.
- **Conversation / Message** : échange de messages rattaché à un événement, à un groupe
  ou à deux amis, avec son historique.
- **Photo** : fichier partagé rattaché à un événement et à son contributeur.
- **Sondage / Vote** : question posée dans un événement avec les réponses proposées et
  les votes des participants.
- **Contenu enrichi** : GIF ou autre média publié dans une conversation.
- **Bloc d'accueil** : élément configurable de la page d'accueil (prochains événements,
  événements proches, invitations, groupes) avec sa position choisie par l'utilisateur.
- **Réglage** : préférence utilisateur conservée entre les sessions (apparence,
  confidentialité, compte).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Lors d'un essai avec 10 participants non accompagnés, 100 % d'entre eux
  créent un compte et publient un premier événement complet en moins de 5 minutes.
- **SC-002**: Au moins 95 % des participants à un essai trouvent un événement connu via
  la carte ou l'agenda en moins de 30 secondes.
- **SC-003**: 100 % des modifications d'événement et des réponses à une invitation sont
  visibles par les personnes concernées en moins d'une minute.
- **SC-004**: Dans un pilote de 30 invitations, au moins 90 % reçoivent une réponse
  (acceptation ou refus) dans les 24 heures.
- **SC-005**: Au moins 95 % des utilisateurs d'un essai rejoignent un événement public
  sans aide et sans créer de doublon de participation.
- **SC-006**: Aucune donnée rédigée n'est perdue lors d'une interruption de connexion
  simulée pendant la création d'un événement, d'un message ou d'une réponse (0 perte sur
  20 scénarios).
- **SC-007**: Aucune information d'un événement privé, d'un chat ou d'un groupe n'est
  accessible à une personne non autorisée lors des 20 scénarios de contrôle d'accès.
- **SC-008**: Au moins 90 % des participants à une enquête de satisfaction de 20
  personnes jugent les parcours principaux « faciles » ou « très faciles ».
- **SC-009**: Les 29 user stories du tableau sont couvertes par au moins un scénario
  d'acceptation vérifiable (29/29) et les exigences déjà réalisées restent sans
  régression.

## Assumptions

- La source de vérité est le tableau public « GatherMap Kanban » (projet 2 de
  LiamTheCreat0r) consulté le 2026-11-20 : 29 stories, réparties sur les lots 1, 3, 4
  et 5 et les sprints 1 à 6. Aucun élément du tableau n'est volontairement exclu.
- Les stories déjà marquées « Done » (#3, #5, #6, #7, #8, #10, #68) sont traitées comme
  des exigences à préserver, pas comme de simples archives.
- Cette unique spécification décrit le produit complet ; la planification pourra
  ensuite la découper par lot ou par sprint sans changer le périmètre fonctionnel.
- Les priorités P1/P2/P3 de cette spécification correspondent aux priorités P0/P1/P2 du
  tableau, la priorité P1 étant la plus élevée dans le format de spécification.
- L'interface est francophone, les dates et heures sont exprimées dans le fuseau de
  l'utilisateur, et les utilisateurs disposent d'un moyen d'identification personnel.
- La découverte des événements publics est ouverte à toute personne ; la participation,
  les invitations et les conversations nécessitent un compte.
- Les groupes sont privés par défaut ; seuls leurs membres en voient le contenu.
- La liste « qui ramène quoi » est réservée aux participants de l'événement : chacun
  réserve ses propres éléments et l'organisateur peut corriger les affectations.
- La page d'options est traitée comme une exigence à part entière, malgré son intitulé
  « optionnel », afin d'accueillir les réglages de compte, de confidentialité et
  d'apparence ; les réglages de notification, le paiement et la géo-zone ne sont pas
  inclus.
- Les objectifs chiffrés des critères de succès sont des cibles de pilote, pas des
  engagements contractuels.
- Les capacités d'hébergement des médias et les limites de taille des fichiers seront
  fixées lors de la planification ; elles ne modifient pas le besoin de dépôt et de
  consultation des photos et des GIF.
