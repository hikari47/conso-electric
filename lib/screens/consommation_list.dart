import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/consommation_service.dart';
import '../router/app_routes.dart';
import 'analytics_screen.dart'; // ✅ Ajouter cet import

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
            title: Text('Nouvelle consommation'),
            content: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Créer une nouvelle consommation fermera automatiquement la consommation active actuelle.',
                    style: TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                  SizedBox(height: 16),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          decoration: InputDecoration(labelText: 'kWh'),
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
                child: Text('Annuler'),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                child: Text('Créer'),
                onPressed: () async {
                  print('one');
                  print(kwh);
                  print(montant);
                  if (_formKey.currentState!.validate() &&
                      kwh != null &&
                      montant != null) {
                    print('two');
                    try {
                      print('three');
                      // kwh = double.tryParse(kwh!.toString());
                      // montant = double.tryParse(montant!.toString());
                      print('four');
                      await creerNouvelleConsommation(kwh!, montant!);
                      print('five');
                      Navigator.pop(context, true);
                      print('six');
                    } catch (e) {
                      print('seven');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erreur: ${e.toString()}')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Consommations'),
        actions: [
          // ✅ Ajouter le bouton d'analyse
          IconButton(
            icon: Icon(Icons.analytics),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AnalyticsScreen()),
              );
            },
            tooltip: 'Analyser les consommations',
          ),
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () => context.go(AppRoutes.profil),
            tooltip: 'Profil',
          ),
        ],
      ),
      body: StreamBuilder<List<Consommation>>(
        stream: getConsommationsStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final consommations = snapshot.data!;

          if (consommations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.electrical_services, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Aucune consommation enregistrée'),
                  SizedBox(height: 8),
                  Text('Appuyez sur + pour créer la première'),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: consommations.length,
            itemBuilder: (context, index) {
              final consommation = consommations[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        consommation.statut == 'active'
                            ? Colors.green
                            : Colors.grey,
                    child: Icon(
                      consommation.statut == 'active'
                          ? Icons.play_arrow
                          : Icons.stop,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    '${consommation.totalKwh.toStringAsFixed(1)} kWh - ${consommation.totalMontant.toStringAsFixed(0)} FCFA',
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Créée par: ${consommation.nom}'),
                      Text(
                        'Créée le: ${_formatDate(consommation.dateCreation)}',
                      ),
                      Text(
                        '${consommation.contributions.length} contribution(s)',
                      ),
                      if (consommation.statut == 'active')
                        Text(
                          'EN COURS',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      if (consommation.statut == 'closed' &&
                          consommation.fermeParNom != null)
                        Text(
                          'Fermée par: ${consommation.fermeParNom}',
                          style: TextStyle(color: Colors.red),
                        ),
                    ],
                  ),
                  trailing: Icon(Icons.arrow_forward_ios),
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
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _ajouterConsommationDialog(context),
        child: Icon(Icons.add),
        tooltip: 'Nouvelle consommation',
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
