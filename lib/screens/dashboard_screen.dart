import 'package:flutter/material.dart';
import '../theme/theme.dart';
import '../my_widgets/circular_stat_card.dart';
import '../my_widgets/simple_line_chart.dart';
import '../services/consommation_service.dart';
import 'analytics_screen.dart';
import 'consommation_list.dart';
import '../models/analytics_models.dart';

class DashboardScreen extends StatefulWidget {
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  AnalyticsPeriod _selectedPeriod = AnalyticsPeriod.mois;
  List<Consommation> _consommations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final consommations = await getConsommationsStream().first;
      setState(() => _consommations = consommations);
    } catch (e) {
      print('Erreur lors du chargement: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Consommations Électriques'),
        actions: [
          IconButton(
            icon: Icon(Icons.analytics),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AnalyticsScreen()),
              );
            },
            tooltip: 'Analyses détaillées',
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPeriodSelector(),
                      SizedBox(height: 20),
                      _buildStatsCards(),
                      SizedBox(height: 20),
                      _buildConsumptionChart(),
                      SizedBox(height: 20),
                      _buildRecentConsumptions(),
                    ],
                  ),
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ConsommationList()),
          );
        },
        backgroundColor: AppTheme.primaryColor,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Période d\'analyse',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(height: 12),
            Row(
              children: [
                _buildPeriodTab('Semaine', AnalyticsPeriod.semaine),
                SizedBox(width: 8),
                _buildPeriodTab('Mois', AnalyticsPeriod.mois),
                SizedBox(width: 8),
                _buildPeriodTab('Année', AnalyticsPeriod.annee),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodTab(String label, AnalyticsPeriod period) {
    final isSelected = _selectedPeriod == period;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPeriod = period;
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[700],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    final currentMonthStats = _calculateCurrentMonthStats();
    final activeConsumption = _getActiveConsumption();

    return Row(
      children: [
        Expanded(
          child: CircularStatCard(
            title: 'Consommation',
            value: '${currentMonthStats['kwh']?.toStringAsFixed(1) ?? '0'} kWh',
            subtitle:
                '${_getCurrentMonthName()} ${currentMonthStats['montant']?.toStringAsFixed(0) ?? '0'} FCFA',
            percentage: _calculatePercentage(currentMonthStats['kwh'] ?? 0),
            color: AppTheme.primaryColor,
            icon: Icons.electrical_services,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: CircularStatCard(
            title: 'Dépenses',
            value:
                '${currentMonthStats['montant']?.toStringAsFixed(0) ?? '0'} FCFA',
            subtitle:
                '${_getCurrentMonthName()} ${currentMonthStats['count'] ?? 0} consommations',
            percentage: _calculatePercentage(
              currentMonthStats['montant'] ?? 0,
              isAmount: true,
            ),
            color: AppTheme.warningColor,
            icon: Icons.payment,
          ),
        ),
      ],
    );
  }

  Widget _buildConsumptionChart() {
    final weeklyData = _getWeeklyData();
    return SimpleLineChart(
      data: weeklyData['values'] ?? [],
      labels: weeklyData['labels'] ?? [],
      title: 'Évolution hebdomadaire',
    );
  }

  Widget _buildRecentConsumptions() {
    final recentConsumptions = _consommations.take(5).toList();

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Consommations récentes',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ConsommationList(),
                      ),
                    );
                  },
                  child: Text('Voir tout'),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (recentConsumptions.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.electrical_services,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Aucune consommation',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Commencez par ajouter votre première consommation',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ...recentConsumptions
                  .map((consommation) => _buildConsumptionTile(consommation))
                  .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildConsumptionTile(Consommation consommation) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor:
            consommation.statut == 'active'
                ? AppTheme.successColor
                : Colors.grey,
        child: Icon(
          consommation.statut == 'active' ? Icons.play_arrow : Icons.stop,
          color: Colors.white,
        ),
      ),
      title: Text(
        '${consommation.totalKwh.toStringAsFixed(1)} kWh',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        '${consommation.totalMontant.toStringAsFixed(0)} FCFA • ${_formatDate(consommation.dateCreation)}',
      ),
      trailing: Text(
        consommation.statut == 'active' ? 'Active' : 'Fermée',
        style: TextStyle(
          color:
              consommation.statut == 'active'
                  ? AppTheme.successColor
                  : Colors.grey,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Map<String, dynamic> _calculateCurrentMonthStats() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    final monthConsommations =
        _consommations.where((c) {
          return c.dateCreation.isAfter(monthStart) &&
              c.dateCreation.isBefore(monthEnd);
        }).toList();

    final totalKwh = monthConsommations.fold(0.0, (sum, c) => sum + c.totalKwh);
    final totalMontant = monthConsommations.fold(
      0.0,
      (sum, c) => sum + c.totalMontant,
    );

    return {
      'kwh': totalKwh,
      'montant': totalMontant,
      'count': monthConsommations.length,
    };
  }

  Consommation? _getActiveConsumption() {
    try {
      return _consommations.firstWhere((c) => c.statut == 'active');
    } catch (e) {
      return null;
    }
  }

  double _calculatePercentage(double value, {bool isAmount = false}) {
    // Pourcentage basé sur une valeur de référence (exemple: 1000 kWh ou 100000 FCFA)
    final reference = isAmount ? 100000.0 : 1000.0;
    return (value / reference * 100).clamp(0, 100);
  }

  Map<String, dynamic> _getWeeklyData() {
    final now = DateTime.now();
    final weeks = <String>[];
    final values = <double>[];

    for (int i = 3; i >= 0; i--) {
      final weekDate = now.subtract(Duration(days: i * 7));
      weeks.add('Semaine ${4 - i}');

      final weekStart = weekDate.subtract(Duration(days: weekDate.weekday - 1));
      final weekEnd = weekStart.add(Duration(days: 6));

      final weekConsommations =
          _consommations.where((c) {
            return c.dateCreation.isAfter(weekStart) &&
                c.dateCreation.isBefore(weekEnd);
          }).toList();

      final weekTotal = weekConsommations.fold(
        0.0,
        (sum, c) => sum + c.totalKwh,
      );
      values.add(weekTotal);
    }

    return {'labels': weeks, 'values': values};
  }

  String _getCurrentMonthName() {
    const months = [
      '',
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre',
    ];
    return months[DateTime.now().month];
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
