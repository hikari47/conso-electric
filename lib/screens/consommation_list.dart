import 'package:conso_famille/screens/consommation_detail_screen.dart';
import 'package:conso_famille/screens/modifier_profil_screen.dart';
import 'package:conso_famille/services/user_service.dart';
import 'package:conso_famille/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/consommation_service.dart';
import 'analytics_screen.dart';

class ConsommationList extends StatefulWidget {
  @override
  State<ConsommationList> createState() => _ConsommationListState();
}

class _ConsommationListState extends State<ConsommationList> {
  Future<void> _ajouterConsommationDialog(BuildContext context) async {
    final _formKey = GlobalKey<FormState>();
    double? kwh;
    double? montant;

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.add_circle_outline, color: AppTheme.primaryColor),
                SizedBox(width: 12),
                Text(
                  'Nouvelle consommation',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.warningColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppTheme.warningColor,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Créer une nouvelle consommation fermera automatiquement la consommation active actuelle.',
                            style: TextStyle(
                              color: AppTheme.warningColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Consommation (kWh)',
                            prefixIcon: Icon(
                              Icons.electrical_services,
                              color: AppTheme.primaryColor,
                            ),
                            hintText: 'Ex: 150.5',
                          ),
                          keyboardType: TextInputType.number,
                          validator:
                              (val) =>
                                  val == null || val.isEmpty
                                      ? 'Entrez les kWh'
                                      : null,
                          onChanged: (val) => kwh = double.tryParse(val),
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Montant (FCFA)',
                            prefixIcon: Icon(
                              Icons.monetization_on,
                              color: AppTheme.primaryColor,
                            ),
                            hintText: 'Ex: 25000',
                          ),
                          keyboardType: TextInputType.number,
                          validator:
                              (val) =>
                                  val == null || val.isEmpty
                                      ? 'Entrez le montant'
                                      : null,
                          onChanged: (val) => montant = double.tryParse(val),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate() &&
                      kwh != null &&
                      montant != null) {
                    Navigator.of(context).pop();
                    await ajouterConsommation(kwh!, montant!);
                    setState(() {});
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('Créer'),
              ),
            ],
          ),
    );
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
          'Mes Consommations',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(Icons.analytics_outlined, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AnalyticsScreen()),
                );
              },
              tooltip: 'Analyser les consommations',
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(Icons.person_outline, color: Colors.white),
              onPressed: () async {
                final infoUser = await recupererProfilUtilisateur();
                final nom = infoUser!['nom'];
                final email = infoUser!['email'];
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => ModifierProfilScreen(
                          nomInitial: nom,
                          numeroInitial: email,
                        ),
                  ),
                );
              },
              tooltip: 'Profil',
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<Consommation>>(
        stream: getConsommationsStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }

          final consommations = snapshot.data!;

          if (consommations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.electrical_services_outlined,
                      size: 64,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Aucune consommation enregistrée',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Appuyez sur + pour créer la première consommation',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppTheme.primaryColor,
            onRefresh: () async {
              setState(() {});
            },
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: consommations.length,
              itemBuilder: (context, index) {
                final consommation = consommations[index];
                final isActive = consommation.statut == 'active';

                return Container(
                  margin: EdgeInsets.only(bottom: 16),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => ConsommationDetailScreen(
                                  consommationId: consommation.id,
                                ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color:
                                        isActive
                                            ? AppTheme.successColor
                                            : AppTheme.textSecondary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    isActive ? Icons.play_arrow : Icons.stop,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${consommation.totalKwh.toStringAsFixed(1)} kWh',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleLarge?.copyWith(
                                          color: AppTheme.textPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${consommation.totalMontant.toStringAsFixed(0)} FCFA',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium?.copyWith(
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isActive
                                            ? AppTheme.successColor.withOpacity(
                                              0.1,
                                            )
                                            : AppTheme.textSecondary
                                                .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color:
                                          isActive
                                              ? AppTheme.successColor
                                              : AppTheme.textSecondary,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    isActive ? 'ACTIVE' : 'FERMÉE',
                                    style: TextStyle(
                                      color:
                                          isActive
                                              ? AppTheme.successColor
                                              : AppTheme.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: 16,
                                  color: AppTheme.textSecondary,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Créée par ${consommation.nom}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 16,
                                  color: AppTheme.textSecondary,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  _formatDate(consommation.dateCreation),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.group_outlined,
                                  size: 16,
                                  color: AppTheme.textSecondary,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '${consommation.contributions.length} contribution(s)',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                            if (consommation.statut == 'closed' &&
                                consommation.fermeParNom != null) ...[
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.lock_outline,
                                    size: 16,
                                    color: AppTheme.errorColor,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Fermée par ${consommation.fermeParNom}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: AppTheme.errorColor),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _ajouterConsommationDialog(context),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: Icon(Icons.add),
        label: Text('Nouvelle consommation'),
        elevation: 6,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
