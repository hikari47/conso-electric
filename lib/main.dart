import 'package:conso_famille/screens/auth_screen.dart';
import 'package:conso_famille/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/user_service.dart';
import 'screens/inscription_screen.dart';
import 'screens/consommation_list.dart';
import 'screens/bienvenue_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Conso Famille',
      theme: AppTheme.lightTheme,
      home: AuthGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          // Affiche un écran de chargement moderne
          Future.delayed(Duration(seconds: 2), () {
            Navigator.of(
              context,
            ).pushReplacement(MaterialPageRoute(builder: (_) => AuthScreen()));
          });
          return Scaffold(
            backgroundColor: AppTheme.backgroundColor,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(Icons.bolt, size: 50, color: Colors.white),
                  ),
                  SizedBox(height: 32),
                  Text(
                    'Conso Famille',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  CircularProgressIndicator(color: AppTheme.primaryColor),
                  SizedBox(height: 24),
                  Text(
                    'Chargement...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return FutureBuilder<Map<String, dynamic>?>(
          future: recupererProfilUtilisateur(),
          builder: (context, profilSnapshot) {
            if (!profilSnapshot.hasData) {
              return Scaffold(
                backgroundColor: AppTheme.backgroundColor,
                body: Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryColor,
                  ),
                ),
              );
            }
            if (profilSnapshot.data == null) {
              return InscriptionScreen();
            } else {
              final nom = profilSnapshot.data!['nom'] ?? 'Utilisateur';
              return BienvenueScreen(nom: nom);
            }
          },
        );
      },
    );
  }
}
