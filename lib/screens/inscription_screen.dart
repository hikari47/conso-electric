import 'package:conso_famille/screens/consommation_list.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';

class InscriptionScreen extends StatefulWidget {
  @override
  State<InscriptionScreen> createState() => _InscriptionScreenState();
}

class _InscriptionScreenState extends State<InscriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? error;
  bool _isLoading = false;

  Future<void> _inscrire() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => error = 'Les mots de passe ne correspondent pas');
      return;
    }

    setState(() {
      _isLoading = true;
      error = null;
    });

    try {
      // Créer l'utilisateur avec email et mot de passe
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      // Enregistrer le profil utilisateur dans Firestore
      await enregistrerProfilUtilisateur(
        _nomController.text.trim(),
        _emailController.text.trim(),
      );

      // L'utilisateur sera automatiquement redirigé par AuthGate
    } on FirebaseAuthException catch (e) {
      String message = 'Erreur lors de l\'inscription';
      switch (e.code) {
        case 'weak-password':
          message = 'Le mot de passe est trop faible';
          break;
        case 'email-already-in-use':
          message = 'Un compte existe déjà avec cet email';
          break;
        case 'invalid-email':
          message = 'Email invalide';
          break;
        case 'operation-not-allowed':
          message = 'L\'inscription par email est désactivée';
          break;
      }
      setState(() => error = message);
    } catch (e) {
      setState(() => error = 'Erreur lors de l\'inscription: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Inscription')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Créer un compte',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32),
                TextFormField(
                  controller: _nomController,
                  decoration: InputDecoration(
                    labelText: 'Nom complet',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Entrez votre nom';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Entrez votre email';
                    }
                    if (!val.contains('@')) {
                      return 'Email invalide';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Entrez votre mot de passe';
                    }
                    if (val.length < 6) {
                      return 'Le mot de passe doit contenir au moins 6 caractères';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirmer le mot de passe',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Confirmez votre mot de passe';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _inscrire,
                    child:
                        _isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text('S\'inscrire'),
                  ),
                ),
                if (error != null) ...[
                  SizedBox(height: 16),
                  Text(
                    error!,
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
                SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Déjà un compte ? Se connecter'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
