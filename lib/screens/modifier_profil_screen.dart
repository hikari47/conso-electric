import 'package:flutter/material.dart';
import '../services/user_service.dart';

class ModifierProfilScreen extends StatefulWidget {
  final String nomInitial;
  final String numeroInitial;

  ModifierProfilScreen({required this.nomInitial, required this.numeroInitial});

  @override
  _ModifierProfilScreenState createState() => _ModifierProfilScreenState();
}

class _ModifierProfilScreenState extends State<ModifierProfilScreen> {
  final _formKey = GlobalKey<FormState>();
  late String nom;
  late String numero;

  @override
  void initState() {
    super.initState();
    nom = widget.nomInitial;
    numero = widget.numeroInitial;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Modifier le profil')),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              initialValue: nom,
              decoration: InputDecoration(labelText: 'Nom'),
              onChanged: (val) => nom = val,
              validator: (val) => val!.isEmpty ? 'Entrez votre nom' : null,
            ),
            TextFormField(
              initialValue: numero,
              decoration: InputDecoration(labelText: 'Numéro'),
              onChanged: (val) => numero = val,
              validator: (val) => val!.isEmpty ? 'Entrez votre numéro' : null,
            ),
            ElevatedButton(
              child: Text('Enregistrer'),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  await modifierProfilUtilisateur(nom, numero);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
