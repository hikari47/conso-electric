import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> enregistrerProfilUtilisateur(String nom, String email) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
    'nom': nom,
    'email': email,
  });
}

Future<Map<String, dynamic>?> recupererProfilUtilisateur() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;
  final doc =
      await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
  return doc.data();
}

Future<void> modifierProfilUtilisateur(String nom, String email) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
    'nom': nom,
    'email': email,
  });
}
