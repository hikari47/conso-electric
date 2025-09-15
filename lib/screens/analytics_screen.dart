import 'package:flutter/material.dart';
import '../models/analytics_models.dart';
import '../services/analytics_service.dart';


class AnalyticsScreen extends StatefulWidget {
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  AnalyticsPeriod _selectedPeriod = AnalyticsPeriod.semaine;
  DateTime _selectedDate = DateTime.now();
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  WeeklyStats? _weeklyStats;
  MonthlyStats? _monthlyStats;
  YearlyStats? _yearlyStats;
  ComparisonData? _comparisonData;

  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      switch (_selectedPeriod) {
        case AnalyticsPeriod.semaine:
          _weeklyStats = await AnalyticsService.getWeeklyStats(_selectedDate);
          break;
        case AnalyticsPeriod.mois:
          _monthlyStats = await AnalyticsService.getMonthlyStats(
            _selectedYear,
            _selectedMonth,
          );
          _comparisonData = await AnalyticsService.getMonthlyComparison(
            _selectedYear,
            _selectedMonth,
          );
          break;
        case AnalyticsPeriod.annee:
          _yearlyStats = await AnalyticsService.getYearlyStats(_selectedYear);
          break;
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Analyse des Consommations'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildPeriodSelector(),
          _buildDateSelector(),
          Expanded(
            child:
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : _error != null
                    ? _buildErrorWidget()
                    : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Card(
      margin: EdgeInsets.all(8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Période d\'analyse',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<AnalyticsPeriod>(
                    title: Text('Semaine'),
                    value: AnalyticsPeriod.semaine,
                    groupValue: _selectedPeriod,
                    onChanged: (value) {
                      setState(() {
                        _selectedPeriod = value!;
                      });
                      _loadData();
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<AnalyticsPeriod>(
                    title: Text('Mois'),
                    value: AnalyticsPeriod.mois,
                    groupValue: _selectedPeriod,
                    onChanged: (value) {
                      setState(() {
                        _selectedPeriod = value!;
                      });
                      _loadData();
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<AnalyticsPeriod>(
                    title: Text('Année'),
                    value: AnalyticsPeriod.annee,
                    groupValue: _selectedPeriod,
                    onChanged: (value) {
                      setState(() {
                        _selectedPeriod = value!;
                      });
                      _loadData();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            if (_selectedPeriod == AnalyticsPeriod.semaine) ...[
              ListTile(
                leading: Icon(Icons.calendar_today),
                title: Text('Semaine du'),
                subtitle: Text(_formatDate(_selectedDate)),
                trailing: Icon(Icons.arrow_drop_down),
                onTap: _selectWeek,
              ),
            ],
            if (_selectedPeriod == AnalyticsPeriod.mois) ...[
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      leading: Icon(Icons.calendar_month),
                      title: Text('Mois'),
                      subtitle: Text(_getMonthName(_selectedMonth)),
                      trailing: Icon(Icons.arrow_drop_down),
                      onTap: _selectMonth,
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      leading: Icon(Icons.calendar_view_year),
                      title: Text('Année'),
                      subtitle: Text(_selectedYear.toString()),
                      trailing: Icon(Icons.arrow_drop_down),
                      onTap: _selectYear,
                    ),
                  ),
                ],
              ),
            ],
            if (_selectedPeriod == AnalyticsPeriod.annee) ...[
              ListTile(
                leading: Icon(Icons.calendar_view_year),
                title: Text('Année'),
                subtitle: Text(_selectedYear.toString()),
                trailing: Icon(Icons.arrow_drop_down),
                onTap: _selectYear,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedPeriod) {
      case AnalyticsPeriod.semaine:
        return _weeklyStats != null ? _buildWeeklyContent() : Container();
      case AnalyticsPeriod.mois:
        return _monthlyStats != null ? _buildMonthlyContent() : Container();
      case AnalyticsPeriod.annee:
        return _yearlyStats != null ? _buildYearlyContent() : Container();
    }
  }

  Widget _buildWeeklyContent() {
    final stats = _weeklyStats!;
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistiques de la semaine',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          _buildStatsTable([
            {
              'Métrique': 'Période',
              'Valeur':
                  '${_formatDate(stats.weekStart)} - ${_formatDate(stats.weekEnd)}',
            },
            {
              'Métrique': 'Total kWh',
              'Valeur': '${stats.totalKwh.toStringAsFixed(1)} kWh',
            },
            {
              'Métrique': 'Total Montant',
              'Valeur': '${stats.totalMontant.toStringAsFixed(0)} FCFA',
            },
            {
              'Métrique': 'Nombre de Consommations',
              'Valeur': '${stats.nombreConsommations}',
            },
            {
              'Métrique': 'Moyenne kWh/jour',
              'Valeur': '${stats.moyenneKwhParJour.toStringAsFixed(1)} kWh',
            },
            {
              'Métrique': 'Moyenne Montant/jour',
              'Valeur':
                  '${stats.moyenneMontantParJour.toStringAsFixed(0)} FCFA',
            },
          ]),
        ],
      ),
    );
  }

  Widget _buildMonthlyContent() {
    final stats = _monthlyStats!;
    final comparison = _comparisonData!;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistiques du mois',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          _buildStatsTable([
            {
              'Métrique': 'Période',
              'Valeur': '${stats.nomMois} ${stats.annee}',
            },
            {
              'Métrique': 'Total kWh',
              'Valeur': '${stats.totalKwh.toStringAsFixed(1)} kWh',
            },
            {
              'Métrique': 'Total Montant',
              'Valeur': '${stats.totalMontant.toStringAsFixed(0)} FCFA',
            },
            {
              'Métrique': 'Nombre de Consommations',
              'Valeur': '${stats.nombreConsommations}',
            },
            {
              'Métrique': 'Moyenne kWh/jour',
              'Valeur': '${stats.moyenneKwhParJour.toStringAsFixed(1)} kWh',
            },
            {
              'Métrique': 'Moyenne Montant/jour',
              'Valeur':
                  '${stats.moyenneMontantParJour.toStringAsFixed(0)} FCFA',
            },
          ]),

          if (comparison.moisPrecedent != null) ...[
            SizedBox(height: 24),
            Text(
              'Comparaison avec le mois précédent',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            _buildComparisonTable(comparison),
          ],
        ],
      ),
    );
  }

  Widget _buildYearlyContent() {
    final stats = _yearlyStats!;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistiques de l\'année ${stats.annee}',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          _buildStatsTable([
            {
              'Métrique': 'Total kWh',
              'Valeur': '${stats.totalKwh.toStringAsFixed(1)} kWh',
            },
            {
              'Métrique': 'Total Montant',
              'Valeur': '${stats.totalMontant.toStringAsFixed(0)} FCFA',
            },
            {
              'Métrique': 'Nombre de Consommations',
              'Valeur': '${stats.nombreConsommations}',
            },
            {
              'Métrique': 'Moyenne kWh/mois',
              'Valeur': '${stats.moyenneKwhParMois.toStringAsFixed(1)} kWh',
            },
            {
              'Métrique': 'Moyenne Montant/mois',
              'Valeur':
                  '${stats.moyenneMontantParMois.toStringAsFixed(0)} FCFA',
            },
          ]),

          SizedBox(height: 24),
          Text(
            'Détail par mois',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          _buildMonthlyDetailsTable(stats.moisStats),
        ],
      ),
    );
  }

  Widget _buildStatsTable(List<Map<String, String>> data) {
    return Card(
      child: Table(
        border: TableBorder.all(color: Colors.grey.shade300),
        children:
            data
                .map(
                  (row) => TableRow(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          row['Métrique']!,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(row['Valeur']!),
                      ),
                    ],
                  ),
                )
                .toList(),
      ),
    );
  }

  Widget _buildComparisonTable(ComparisonData comparison) {
    return Card(
      child: Table(
        border: TableBorder.all(color: Colors.grey.shade300),
        children: [
          TableRow(
            decoration: BoxDecoration(color: Colors.grey.shade100),
            children: [
              Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Métrique',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Mois actuel',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Mois précédent',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Différence',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          TableRow(
            children: [
              Padding(padding: EdgeInsets.all(12), child: Text('kWh')),
              Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  '${comparison.moisActuel.totalKwh.toStringAsFixed(1)}',
                ),
              ),
              Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  '${comparison.moisPrecedent?.totalKwh.toStringAsFixed(1) ?? 'N/A'}',
                ),
              ),
              Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  comparison.differenceKwh != null
                      ? '${comparison.differenceKwh!.toStringAsFixed(1)} (${comparison.pourcentageKwh!.toStringAsFixed(1)}%)'
                      : 'N/A',
                  style: TextStyle(
                    color:
                        comparison.differenceKwh != null &&
                                comparison.differenceKwh! > 0
                            ? Colors.red
                            : Colors.green,
                  ),
                ),
              ),
            ],
          ),
          TableRow(
            children: [
              Padding(
                padding: EdgeInsets.all(12),
                child: Text('Montant (FCFA)'),
              ),
              Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  '${comparison.moisActuel.totalMontant.toStringAsFixed(0)}',
                ),
              ),
              Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  '${comparison.moisPrecedent?.totalMontant.toStringAsFixed(0) ?? 'N/A'}',
                ),
              ),
              Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  comparison.differenceMontant != null
                      ? '${comparison.differenceMontant!.toStringAsFixed(0)} (${comparison.pourcentageMontant!.toStringAsFixed(1)}%)'
                      : 'N/A',
                  style: TextStyle(
                    color:
                        comparison.differenceMontant != null &&
                                comparison.differenceMontant! > 0
                            ? Colors.red
                            : Colors.green,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyDetailsTable(List<MonthlyStats> moisStats) {
    return Card(
      child: Table(
        border: TableBorder.all(color: Colors.grey.shade300),
        children: [
          TableRow(
            decoration: BoxDecoration(color: Colors.grey.shade100),
            children: [
              Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Mois',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'kWh',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Montant (FCFA)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Consommations',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          ...moisStats
              .map(
                (mois) => TableRow(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(mois.nomMois),
                    ),
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(mois.totalKwh.toStringAsFixed(1)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(mois.totalMontant.toStringAsFixed(0)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(mois.nombreConsommations.toString()),
                    ),
                  ],
                ),
              )
              .toList(),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text('Erreur: $_error'),
          SizedBox(height: 16),
          ElevatedButton(onPressed: _loadData, child: Text('Réessayer')),
        ],
      ),
    );
  }

  Future<void> _selectWeek() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
      _loadData();
    }
  }

  Future<void> _selectMonth() async {
    final months = List.generate(12, (index) => index + 1);
    final month = await showDialog<int>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Sélectionner le mois'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  months
                      .map(
                        (m) => ListTile(
                          title: Text(_getMonthName(m)),
                          onTap: () => Navigator.pop(context, m),
                        ),
                      )
                      .toList(),
            ),
          ),
    );
    if (month != null) {
      setState(() {
        _selectedMonth = month;
      });
      _loadData();
    }
  }

  Future<void> _selectYear() async {
    final years = await AnalyticsService.getAvailableYears();
    final year = await showDialog<int>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Sélectionner l\'année'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  years
                      .map(
                        (y) => ListTile(
                          title: Text(y.toString()),
                          onTap: () => Navigator.pop(context, y),
                        ),
                      )
                      .toList(),
            ),
          ),
    );
    if (year != null) {
      setState(() {
        _selectedYear = year;
      });
      _loadData();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getMonthName(int mois) {
    const moisNoms = [
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
    return moisNoms[mois];
  }
}
