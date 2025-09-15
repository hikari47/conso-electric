import 'package:flutter/material.dart';
import '../services/consommation_service.dart';

class ConsommationDetailScreen extends StatefulWidget {
  final String consommationId;

  const ConsommationDetailScreen({Key? key, required this.consommationId})
    : super(key: key);

  @override
  State<ConsommationDetailScreen> createState() =>
      _ConsommationDetailScreenState();
}

class _ConsommationDetailScreenState extends State<ConsommationDetailScreen> {
  Consommation? consommation;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadConsommation();
  }

  Future<void> _loadConsommation() async {
    try {
      final consom = await getConsommationById(widget.consommationId);
      setState(() {
        consommation = consom;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _ajouterContributionDialog() async {
    final formKey = GlobalKey<FormState>();
    double? kwh;
    double? montant;

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Ajouter une contribution'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                    decoration: InputDecoration(labelText: 'Montant (FCFA)'),
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
            actions: [
              TextButton(
                child: Text('Annuler'),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                child: Text('Ajouter'),
                onPressed: () async {
                  if (formKey.currentState!.validate() &&
                      kwh != null &&
                      montant != null) {
                    try {
                      await ajouterContribution(
                        widget.consommationId,
                        kwh!,
                        montant!,
                      );
                      Navigator.pop(context);
                      _loadConsommation(); // Recharger les données
                    } catch (e) {
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

  Future<void> _fermerConsommation() async {
    // Confirmation avant fermeture
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Fermer la consommation'),
            content: Text(
              'Êtes-vous sûr de vouloir fermer cette consommation ?',
            ),
            actions: [
              TextButton(
                child: Text('Annuler'),
                onPressed: () => Navigator.pop(context, false),
              ),
              ElevatedButton(
                child: Text('Fermer'),
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await fermerConsommation(widget.consommationId);
        _loadConsommation(); // Recharger les données
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Consommation fermée')));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Détails')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: Text('Détails')),
        body: Center(child: Text('Erreur: $error')),
      );
    }

    if (consommation == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Détails')),
        body: Center(child: Text('Consommation introuvable')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Consommation'),
        actions: [
          if (consommation!.statut == 'active') ...[
            IconButton(
              icon: Icon(Icons.add),
              onPressed: _ajouterContributionDialog,
              tooltip: 'Ajouter contribution',
            ),
            IconButton(
              icon: Icon(Icons.close),
              onPressed: _fermerConsommation,
              tooltip: 'Fermer consommation',
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec statut
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Statut: ${consommation!.statut == 'active' ? 'En cours' : 'Fermée'}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color:
                                consommation!.statut == 'active'
                                    ? Colors.green
                                    : Colors.red,
                          ),
                        ),
                        Chip(
                          label: Text(
                            consommation!.statut == 'active'
                                ? 'Active'
                                : 'Fermée',
                          ),
                          backgroundColor:
                              consommation!.statut == 'active'
                                  ? Colors.green
                                  : Colors.red,
                          labelStyle: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text('Créée par: ${consommation!.nom}'),
                    Text(
                      'Créée le: ${_formatDate(consommation!.dateCreation)}',
                    ),
                    if (consommation!.dateFermeture != null) ...[
                      Text(
                        'Fermée par: ${consommation!.fermeParNom ?? 'Inconnu'}',
                      ),
                      Text(
                        'Fermée le: ${_formatDate(consommation!.dateFermeture!)}',
                      ),
                    ],
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Totaux
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Totaux',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              '${consommation!.totalKwh.toStringAsFixed(1)} kWh',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Énergie',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              '${consommation!.totalMontant.toStringAsFixed(0)} FCFA',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Montant',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Liste des contributions
            Text(
              'Contributions (${consommation!.contributions.length})',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),

            ...consommation!.contributions
                .map(
                  (contribution) => Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            contribution.type == 'initial'
                                ? Colors.blue
                                : Colors.orange,
                        child: Icon(
                          contribution.type == 'initial'
                              ? Icons.person
                              : Icons.add,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(contribution.nom),
                      subtitle: Text('${_formatDate(contribution.date)}'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${contribution.kwh.toStringAsFixed(1)} kWh',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${contribution.montant.toStringAsFixed(0)} FCFA',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
