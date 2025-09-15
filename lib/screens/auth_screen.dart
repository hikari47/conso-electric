import 'package:conso_famille/screens/consommation_list.dart';
import 'package:conso_famille/screens/inscription_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthScreen extends StatefulWidget {
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? error;
  bool _isLoading = false;

  Future<bool> _connecter() async {
    if (!_formKey.currentState!.validate()) return false;

    setState(() {
      _isLoading = true;
      error = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      return true;
      // L'utilisateur sera automatiquement redirigé par AuthGate
    } on FirebaseAuthException catch (e) {
      String message = 'Erreur lors de la connexion';
      switch (e.code) {
        case 'user-not-found':
          message = 'Aucun utilisateur trouvé avec cet email';
          break;
        case 'wrong-password':
          message = 'Mot de passe incorrect';
          break;
        case 'invalid-email':
          message = 'Email invalide';
          break;
        case 'user-disabled':
          message = 'Ce compte a été désactivé';
          break;
        case 'too-many-requests':
          message = 'Trop de tentatives. Réessayez plus tard';
          break;
      }
      setState(() => error = message);
      return false;
    } catch (e) {
      setState(() => error = "Erreur lors de la connexion");
      return false;
    }
    //  finally {
    //   setState(() => _isLoading = false);
    //   return false;
    // }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Connexion')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Connexion',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
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
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_isLoading) {
                      return;
                    }
                    final result = await _connecter();
                    print(
                      '-----------result: $result --------------------------------',
                    );
                    if (result) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ConsommationList(),
                        ),
                      );
                    }
                  },
                  child:
                      _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text('Se connecter'),
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
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InscriptionScreen(),
                    ),
                  );
                },
                child: Text('Pas de compte ? S\'inscrire'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
