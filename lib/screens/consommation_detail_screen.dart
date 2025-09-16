import 'package:flutter/material.dart';
import 'package:conso_famille/theme/app_theme.dart';
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.add_circle_outline, color: AppTheme.primaryColor),
                SizedBox(width: 12),
                Text(
                  'Ajouter une contribution',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'kWh à ajouter',
                      prefixIcon: Icon(
                        Icons.electrical_services,
                        color: AppTheme.primaryColor,
                      ),
                      hintText: 'Ex: 25.5',
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
                      labelText: 'Montant à ajouter (FCFA)',
                      prefixIcon: Icon(
                        Icons.monetization_on,
                        color: AppTheme.primaryColor,
                      ),
                      hintText: 'Ex: 5000',
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
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate() &&
                      kwh != null &&
                      montant != null) {
                    Navigator.of(context).pop();
                    try {
                      await ajouterContribution(
                        widget.consommationId,
                        kwh!,
                        montant!,
                      );
                      _loadConsommation();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Contribution ajoutée avec succès'),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur: ${e.toString()}'),
                          backgroundColor: AppTheme.errorColor,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('Ajouter'),
              ),
            ],
          ),
    );
  }

  Future<void> _fermerConsommation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.lock_outline, color: AppTheme.errorColor),
                SizedBox(width: 12),
                Text(
                  'Fermer la consommation',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            content: Text(
              'Êtes-vous sûr de vouloir fermer cette consommation ? Cette action est irréversible.',
            ),
            actions: [
              TextButton(
                child: Text('Annuler'),
                onPressed: () => Navigator.pop(context, false),
              ),
              ElevatedButton(
                child: Text('Fermer'),
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await fermerConsommation(widget.consommationId);
        _loadConsommation();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Consommation fermée avec succès'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text('Détails de la consommation'),
        ),
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }

    if (error != null || consommation == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text('Détails de la consommation'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
              SizedBox(height: 16),
              Text(
                'Erreur lors du chargement',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: AppTheme.errorColor),
              ),
              SizedBox(height: 8),
              Text(
                error ?? 'Consommation introuvable',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isLoading = true;
                    error = null;
                  });
                  _loadConsommation();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    final isActive = consommation!.statut == 'active';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('Détails de la consommation'),
        actions: [
          if (isActive) ...[
            Container(
              margin: EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: Icon(Icons.add, color: Colors.white),
                onPressed: _ajouterContributionDialog,
                tooltip: 'Ajouter une contribution',
              ),
            ),
            Container(
              margin: EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: Icon(Icons.lock_outline, color: Colors.white),
                onPressed: _fermerConsommation,
                tooltip: 'Fermer la consommation',
              ),
            ),
          ],
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryColor,
        onRefresh: _loadConsommation,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Carte principale des informations
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  isActive
                                      ? AppTheme.successColor
                                      : AppTheme.textSecondary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isActive ? Icons.play_arrow : Icons.stop,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${consommation!.totalKwh.toStringAsFixed(1)} kWh',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineMedium?.copyWith(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${consommation!.totalMontant.toStringAsFixed(0)} FCFA',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleLarge?.copyWith(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isActive
                                      ? AppTheme.successColor.withOpacity(0.1)
                                      : AppTheme.textSecondary.withOpacity(0.1),
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
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      _buildInfoRow(
                        Icons.person_outline,
                        'Créée par',
                        consommation!.nom,
                      ),
                      _buildInfoRow(
                        Icons.calendar_today_outlined,
                        'Créée le',
                        _formatDate(consommation!.dateCreation),
                      ),
                      _buildInfoRow(
                        Icons.group_outlined,
                        'Contributions',
                        '${consommation!.contributions.length} contribution(s)',
                      ),
                      if (consommation!.statut == 'closed' &&
                          consommation!.fermeParNom != null)
                        _buildInfoRow(
                          Icons.lock_outline,
                          'Fermée par',
                          consommation!.fermeParNom!,
                          color: AppTheme.errorColor,
                        ),
                      if (consommation!.statut == 'closed' &&
                          consommation!.dateFermeture != null)
                        _buildInfoRow(
                          Icons.calendar_today_outlined,
                          'Fermée le',
                          _formatDate(consommation!.dateFermeture!),
                          color: AppTheme.errorColor,
                        ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Titre des contributions
              Text(
                'Contributions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 16),

              // Liste des contributions
              if (consommation!.contributions.isEmpty)
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.group_outlined,
                          size: 48,
                          color: AppTheme.textSecondary,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Aucune contribution',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Les contributions apparaîtront ici',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: consommation!.contributions.length,
                  itemBuilder: (context, index) {
                    final contribution = consommation!.contributions[index];
                    final isInitial = contribution.type == 'initial';

                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      isInitial
                                          ? AppTheme.primaryColor.withOpacity(
                                            0.1,
                                          )
                                          : AppTheme.accentColor.withOpacity(
                                            0.1,
                                          ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  isInitial
                                      ? Icons.add_circle
                                      : Icons.person_add,
                                  color:
                                      isInitial
                                          ? AppTheme.primaryColor
                                          : AppTheme.accentColor,
                                  size: 20,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      contribution.nom,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '${contribution.kwh.toStringAsFixed(1)} kWh • ${contribution.montant.toStringAsFixed(0)} FCFA',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.copyWith(
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      _formatDateTime(contribution.date),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isInitial
                                          ? AppTheme.primaryColor.withOpacity(
                                            0.1,
                                          )
                                          : AppTheme.accentColor.withOpacity(
                                            0.1,
                                          ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isInitial ? 'INITIAL' : 'CONTRIBUTION',
                                  style: TextStyle(
                                    color:
                                        isInitial
                                            ? AppTheme.primaryColor
                                            : AppTheme.accentColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? color,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? AppTheme.textSecondary),
          SizedBox(width: 12),
          Text(
            '$label: ',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color ?? AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
