import 'package:conso_famille/screens/auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/user_service.dart';
import 'screens/inscription_screen.dart';
import 'screens/consommation_list.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: AuthGate());
  }
}

class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          // Affiche un message puis redirige après 2 secondes
          Future.delayed(Duration(seconds: 2), () {
            Navigator.of(
              context,
            ).pushReplacement(MaterialPageRoute(builder: (_) => AuthScreen()));
          });
          return Scaffold(
            body: Center(
              child: Text(
                'Vous serez redirigé vers la page d\'authentification...',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return FutureBuilder<Map<String, dynamic>?>(
          future: recupererProfilUtilisateur(),
          builder: (context, profilSnapshot) {
            if (!profilSnapshot.hasData) return CircularProgressIndicator();
            if (profilSnapshot.data == null) {
              return InscriptionScreen();
            } else {
              return Scaffold(
                appBar: AppBar(title: Text('Consommations')),
                body: ConsommationList(),
              );
            }
          },
        );
      },
    );
  }
}
