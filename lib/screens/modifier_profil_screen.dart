import 'package:flutter/material.dart';
import 'package:conso_famille/theme/app_theme.dart';
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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    nom = widget.nomInitial;
    numero = widget.numeroInitial;
  }

  Future<void> _sauvegarderProfil() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await modifierProfilUtilisateur(nom, numero);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profil mis à jour avec succès'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Modifier le profil',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 20),
                // Avatar/Icon principal
                Center(
                  child: Container(
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
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                ),
                SizedBox(height: 32),
                // Titre
                Text(
                  'Informations personnelles',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Modifiez vos informations de profil',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32),
                // Carte de modification
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Détails du profil',
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 24),
                        TextFormField(
                          initialValue: nom,
                          decoration: InputDecoration(
                            labelText: 'Nom complet',
                            prefixIcon: Icon(
                              Icons.person_outline,
                              color: AppTheme.primaryColor,
                            ),
                            hintText: 'Votre nom et prénom',
                          ),
                          onChanged: (val) => nom = val,
                          validator:
                              (val) => val!.isEmpty ? 'Entrez votre nom' : null,
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          initialValue: numero,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: AppTheme.primaryColor,
                            ),
                            hintText: 'votre@email.com',
                          ),
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (val) => numero = val,
                          validator: (val) {
                            if (val!.isEmpty) {
                              return 'Entrez votre email';
                            }
                            if (!val.contains('@')) {
                              return 'Email invalide';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _sauvegarderProfil,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child:
                                _isLoading
                                    ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : Text(
                                      'Sauvegarder',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),
                // Informations supplémentaires
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppTheme.accentColor,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Informations',
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          '• Votre nom sera affiché dans les consommations que vous créez',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        SizedBox(height: 8),
                        Text(
                          '• Votre email est utilisé pour l\'authentification',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        SizedBox(height: 8),
                        Text(
                          '• Ces informations sont visibles par les autres utilisateurs',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
