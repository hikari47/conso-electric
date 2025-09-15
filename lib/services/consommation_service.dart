import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Modèle de données pour une contribution
class Contribution {
  final String userId;
  final String nom;
  final double kwh;
  final double montant;
  final DateTime date;
  final String type; // 'initial' ou 'contribution'

  Contribution({
    required this.userId,
    required this.nom,
    required this.kwh,
    required this.montant,
    required this.date,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'nom': nom,
      'kwh': kwh,
      'montant': montant,
      'date': Timestamp.fromDate(date),
      'type': type,
    };
  }

  factory Contribution.fromMap(Map<String, dynamic> map) {
    return Contribution(
      userId: map['userId'] ?? '',
      nom: map['nom'] ?? '',
      kwh: (map['kwh'] ?? 0).toDouble(),
      montant: (map['montant'] ?? 0).toDouble(),
      date: (map['date'] as Timestamp).toDate(),
      type: map['type'] ?? 'contribution',
    );
  }
}

// Modèle de données pour une consommation
class Consommation {
  final String id;
  final String userId; // Créateur original
  final String nom; // Nom du créateur
  final String statut; // 'active' ou 'closed'
  final DateTime dateCreation;
  final DateTime? dateFermeture;
  final String? fermeParUserId; // Qui a fermé la consommation
  final String? fermeParNom; // Nom de qui a fermé
  final double totalKwh;
  final double totalMontant;
  final List<Contribution> contributions;

  Consommation({
    required this.id,
    required this.userId,
    required this.nom,
    required this.statut,
    required this.dateCreation,
    this.dateFermeture,
    this.fermeParUserId,
    this.fermeParNom,
    required this.totalKwh,
    required this.totalMontant,
    required this.contributions,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'nom': nom,
      'statut': statut,
      'dateCreation': Timestamp.fromDate(dateCreation),
      'dateFermeture':
          dateFermeture != null ? Timestamp.fromDate(dateFermeture!) : null,
      'fermeParUserId': fermeParUserId,
      'fermeParNom': fermeParNom,
      'totalKwh': totalKwh,
      'totalMontant': totalMontant,
      'contributions': contributions.map((c) => c.toMap()).toList(),
    };
  }

  factory Consommation.fromMap(String id, Map<String, dynamic> map) {
    return Consommation(
      id: id,
      userId: map['userId'] ?? '',
      nom: map['nom'] ?? '',
      statut: map['statut'] ?? 'active',
      dateCreation: (map['dateCreation'] as Timestamp).toDate(),
      dateFermeture:
          map['dateFermeture'] != null
              ? (map['dateFermeture'] as Timestamp).toDate()
              : null,
      fermeParUserId: map['fermeParUserId'],
      fermeParNom: map['fermeParNom'],
      totalKwh: (map['totalKwh'] ?? 0).toDouble(),
      totalMontant: (map['totalMontant'] ?? 0).toDouble(),
      contributions:
          (map['contributions'] as List<dynamic>? ?? [])
              .map((c) => Contribution.fromMap(c as Map<String, dynamic>))
              .toList(),
    );
  }
}

// Fermer toutes les consommations actives (n'importe qui peut le faire)
Future<void> _fermerConsommationsActives() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw Exception('Utilisateur non connecté');

  // Récupérer le nom de l'utilisateur qui ferme
  final userDoc =
      await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
  final nom = userDoc.data()?['nom'] ?? '';

  final querySnapshot =
      await FirebaseFirestore.instance
          .collection('consommations')
          .where('statut', isEqualTo: 'active')
          .get();

  final batch = FirebaseFirestore.instance.batch();
  for (var doc in querySnapshot.docs) {
    batch.update(doc.reference, {
      'statut': 'closed',
      'dateFermeture': FieldValue.serverTimestamp(),
      'fermeParUserId': user.uid,
      'fermeParNom': nom,
    });
  }
  await batch.commit();
}

// Créer une nouvelle consommation (n'importe qui peut créer)
Future<String> creerNouvelleConsommation(double kwh, double montant) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw Exception('Utilisateur non connecté');

  // Récupérer le nom de l'utilisateur
  final userDoc =
      await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
  final nom = userDoc.data()?['nom'] ?? '';

  // Fermer toutes les consommations actives (n'importe qui peut fermer)
  await _fermerConsommationsActives();

  // Créer la nouvelle consommation
  final contribution = Contribution(
    userId: user.uid,
    nom: nom,
    kwh: kwh,
    montant: montant,
    date: DateTime.now(),
    type: 'initial',
  );

  final consommationData = {
    'userId': user.uid,
    'nom': nom,
    'statut': 'active',
    'dateCreation': FieldValue.serverTimestamp(),
    'dateFermeture': null,
    'fermeParUserId': null,
    'fermeParNom': null,
    'totalKwh': kwh,
    'totalMontant': montant,
    'contributions': [contribution.toMap()],
  };

  final docRef = await FirebaseFirestore.instance
      .collection('consommations')
      .add(consommationData);

  return docRef.id;
}

// Ajouter une contribution à une consommation active (n'importe qui peut contribuer)
Future<void> ajouterContribution(
  String consommationId,
  double kwh,
  double montant,
) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw Exception('Utilisateur non connecté');

  // Récupérer le nom de l'utilisateur
  final userDoc =
      await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
  final nom = userDoc.data()?['nom'] ?? '';

  // Récupérer la consommation
  final consommationDoc =
      await FirebaseFirestore.instance
          .collection('consommations')
          .doc(consommationId)
          .get();

  if (!consommationDoc.exists) {
    throw Exception('Consommation introuvable');
  }

  final data = consommationDoc.data()!;
  if (data['statut'] != 'active') {
    throw Exception('Cette consommation est fermée');
  }

  // Créer la nouvelle contribution
  final contribution = Contribution(
    userId: user.uid,
    nom: nom,
    kwh: kwh,
    montant: montant,
    date: DateTime.now(),
    type: 'contribution',
  );

  // Mettre à jour la consommation
  final contributions =
      (data['contributions'] as List<dynamic>)
          .map((c) => Contribution.fromMap(c as Map<String, dynamic>))
          .toList();

  contributions.add(contribution);

  final totalKwh = contributions.fold(0.0, (sum, c) => sum + c.kwh);
  final totalMontant = contributions.fold(0.0, (sum, c) => sum + c.montant);

  await FirebaseFirestore.instance
      .collection('consommations')
      .doc(consommationId)
      .update({
        'totalKwh': totalKwh,
        'totalMontant': totalMontant,
        'contributions': contributions.map((c) => c.toMap()).toList(),
      });
}

// Fermer une consommation manuellement (n'importe qui peut fermer)
Future<void> fermerConsommation(String consommationId) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw Exception('Utilisateur non connecté');

  // Récupérer le nom de l'utilisateur qui ferme
  final userDoc =
      await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
  final nom = userDoc.data()?['nom'] ?? '';

  await FirebaseFirestore.instance
      .collection('consommations')
      .doc(consommationId)
      .update({
        'statut': 'closed',
        'dateFermeture': FieldValue.serverTimestamp(),
        'fermeParUserId': user.uid,
        'fermeParNom': nom,
      });
}

// Récupérer toutes les consommations
Stream<List<Consommation>> getConsommationsStream() {
  return FirebaseFirestore.instance
      .collection('consommations')
      .orderBy('dateCreation', descending: true)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs
                .map(
                  (doc) => Consommation.fromMap(
                    doc.id,
                    doc.data() as Map<String, dynamic>,
                  ),
                )
                .toList(),
      );
}

// Récupérer la consommation active
Future<Consommation?> getConsommationActive() async {
  final querySnapshot =
      await FirebaseFirestore.instance
          .collection('consommations')
          .where('statut', isEqualTo: 'active')
          .limit(1)
          .get();

  if (querySnapshot.docs.isEmpty) return null;

  final doc = querySnapshot.docs.first;
  return Consommation.fromMap(doc.id, doc.data() as Map<String, dynamic>);
}

// Récupérer une consommation par ID
Future<Consommation?> getConsommationById(String id) async {
  final doc =
      await FirebaseFirestore.instance
          .collection('consommations')
          .doc(id)
          .get();

  if (!doc.exists) return null;
  return Consommation.fromMap(doc.id, doc.data() as Map<String, dynamic>);
}

// Fonctions de compatibilité avec l'ancien système (pour éviter les erreurs)
@Deprecated('Utilisez creerNouvelleConsommation à la place')
Future<void> ajouterConsommation(double kilo, double montant) async {
  await creerNouvelleConsommation(kilo, montant);
}

@Deprecated('Utilisez getConsommationsStream à la place')
Stream<QuerySnapshot> getConsommationsStreamOld() {
  return FirebaseFirestore.instance
      .collection('consommations')
      .orderBy('date', descending: true)
      .snapshots();
}
