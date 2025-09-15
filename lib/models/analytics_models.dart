import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/analytics_models.dart';
import '../services/consommation_service.dart';


class WeeklyStats {
  final DateTime weekStart;
  final DateTime weekEnd;
  final double totalKwh;
  final double totalMontant;
  final int nombreConsommations;
  final double moyenneKwhParJour;
  final double moyenneMontantParJour;

  WeeklyStats({
    required this.weekStart,
    required this.weekEnd,
    required this.totalKwh,
    required this.totalMontant,
    required this.nombreConsommations,
    required this.moyenneKwhParJour,
    required this.moyenneMontantParJour,
  });

  Map<String, dynamic> toMap() {
    return {
      'weekStart': weekStart.toIso8601String(),
      'weekEnd': weekEnd.toIso8601String(),
      'totalKwh': totalKwh,
      'totalMontant': totalMontant,
      'nombreConsommations': nombreConsommations,
      'moyenneKwhParJour': moyenneKwhParJour,
      'moyenneMontantParJour': moyenneMontantParJour,
    };
  }
}

class MonthlyStats {
  final int annee;
  final int mois;
  final String nomMois;
  final double totalKwh;
  final double totalMontant;
  final int nombreConsommations;
  final double moyenneKwhParJour;
  final double moyenneMontantParJour;
  final int nombreJours;

  MonthlyStats({
    required this.annee,
    required this.mois,
    required this.nomMois,
    required this.totalKwh,
    required this.totalMontant,
    required this.nombreConsommations,
    required this.moyenneKwhParJour,
    required this.moyenneMontantParJour,
    required this.nombreJours,
  });

  Map<String, dynamic> toMap() {
    return {
      'annee': annee,
      'mois': mois,
      'nomMois': nomMois,
      'totalKwh': totalKwh,
      'totalMontant': totalMontant,
      'nombreConsommations': nombreConsommations,
      'moyenneKwhParJour': moyenneKwhParJour,
      'moyenneMontantParJour': moyenneMontantParJour,
      'nombreJours': nombreJours,
    };
  }
}

class YearlyStats {
  final int annee;
  final List<MonthlyStats> moisStats;
  final double totalKwh;
  final double totalMontant;
  final int nombreConsommations;
  final double moyenneKwhParMois;
  final double moyenneMontantParMois;

  YearlyStats({
    required this.annee,
    required this.moisStats,
    required this.totalKwh,
    required this.totalMontant,
    required this.nombreConsommations,
    required this.moyenneKwhParMois,
    required this.moyenneMontantParMois,
  });

  Map<String, dynamic> toMap() {
    return {
      'annee': annee,
      'moisStats': moisStats.map((m) => m.toMap()).toList(),
      'totalKwh': totalKwh,
      'totalMontant': totalMontant,
      'nombreConsommations': nombreConsommations,
      'moyenneKwhParMois': moyenneKwhParMois,
      'moyenneMontantParMois': moyenneMontantParMois,
    };
  }
}

class ComparisonData {
  final MonthlyStats moisActuel;
  final MonthlyStats? moisPrecedent;
  final double? differenceKwh;
  final double? differenceMontant;
  final double? pourcentageKwh;
  final double? pourcentageMontant;

  ComparisonData({
    required this.moisActuel,
    this.moisPrecedent,
    this.differenceKwh,
    this.differenceMontant,
    this.pourcentageKwh,
    this.pourcentageMontant,
  });

  Map<String, dynamic> toMap() {
    return {
      'moisActuel': moisActuel.toMap(),
      'moisPrecedent': moisPrecedent?.toMap(),
      'differenceKwh': differenceKwh,
      'differenceMontant': differenceMontant,
      'pourcentageKwh': pourcentageKwh,
      'pourcentageMontant': pourcentageMontant,
    };
  }
}

enum AnalyticsPeriod {
  semaine,
  mois,
  annee,
}

class AnalyticsFilter {
  final AnalyticsPeriod period;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? annee;
  final int? mois;

  AnalyticsFilter({
    required this.period,
    this.startDate,
    this.endDate,
    this.annee,
    this.mois,
  });
}

class AnalyticsService {
  // Obtenir les statistiques de la semaine
  static Future<WeeklyStats> getWeeklyStats(DateTime date) async {
    final weekStart = _getWeekStart(date);
    final weekEnd = weekStart.add(Duration(days: 6));
    
    final consommations = await _getConsommationsInPeriod(weekStart, weekEnd);
    
    final totalKwh = consommations.fold(0.0, (sum, c) => sum + c.totalKwh);
    final totalMontant = consommations.fold(0.0, (sum, c) => sum + c.totalMontant);
    final nombreConsommations = consommations.length;
    final nombreJours = 7;
    
    return WeeklyStats(
      weekStart: weekStart,
      weekEnd: weekEnd,
      totalKwh: totalKwh,
      totalMontant: totalMontant,
      nombreConsommations: nombreConsommations,
      moyenneKwhParJour: totalKwh / nombreJours,
      moyenneMontantParJour: totalMontant / nombreJours,
    );
  }

  // Obtenir les statistiques du mois
  static Future<MonthlyStats> getMonthlyStats(int annee, int mois) async {
    final monthStart = DateTime(annee, mois, 1);
    final monthEnd = DateTime(annee, mois + 1, 0);
    
    final consommations = await _getConsommationsInPeriod(monthStart, monthEnd);
    
    final totalKwh = consommations.fold(0.0, (sum, c) => sum + c.totalKwh);
    final totalMontant = consommations.fold(0.0, (sum, c) => sum + c.totalMontant);
    final nombreConsommations = consommations.length;
    final nombreJours = monthEnd.day;
    
    return MonthlyStats(
      annee: annee,
      mois: mois,
      nomMois: _getMonthName(mois),
      totalKwh: totalKwh,
      totalMontant: totalMontant,
      nombreConsommations: nombreConsommations,
      moyenneKwhParJour: totalKwh / nombreJours,
      moyenneMontantParJour: totalMontant / nombreJours,
      nombreJours: nombreJours,
    );
  }

  // Obtenir les statistiques de l'année
  static Future<YearlyStats> getYearlyStats(int annee) async {
    final List<MonthlyStats> moisStats = [];
    
    for (int mois = 1; mois <= 12; mois++) {
      final monthlyStats = await getMonthlyStats(annee, mois);
      moisStats.add(monthlyStats);
    }
    
    final totalKwh = moisStats.fold(0.0, (sum, m) => sum + m.totalKwh);
    final totalMontant = moisStats.fold(0.0, (sum, m) => sum + m.totalMontant);
    final nombreConsommations = moisStats.fold(0, (sum, m) => sum + m.nombreConsommations);
    final moisAvecDonnees = moisStats.where((m) => m.nombreConsommations > 0).length;
    
    return YearlyStats(
      annee: annee,
      moisStats: moisStats,
      totalKwh: totalKwh,
      totalMontant: totalMontant,
      nombreConsommations: nombreConsommations,
      moyenneKwhParMois: moisAvecDonnees > 0 ? totalKwh / moisAvecDonnees : 0,
      moyenneMontantParMois: moisAvecDonnees > 0 ? totalMontant / moisAvecDonnees : 0,
    );
  }

  // Obtenir la comparaison mensuelle
  static Future<ComparisonData> getMonthlyComparison(int annee, int mois) async {
    final moisActuel = await getMonthlyStats(annee, mois);
    
    // Calculer le mois précédent
    DateTime moisPrecedentDate;
    if (mois == 1) {
      moisPrecedentDate = DateTime(annee - 1, 12);
    } else {
      moisPrecedentDate = DateTime(annee, mois - 1);
    }
    
    final moisPrecedent = await getMonthlyStats(
      moisPrecedentDate.year, 
      moisPrecedentDate.month
    );
    
    // Calculer les différences
    double? differenceKwh;
    double? differenceMontant;
    double? pourcentageKwh;
    double? pourcentageMontant;
    
    if (moisPrecedent.totalKwh > 0) {
      differenceKwh = moisActuel.totalKwh - moisPrecedent.totalKwh;
      pourcentageKwh = (differenceKwh / moisPrecedent.totalKwh) * 100;
    }
    
    if (moisPrecedent.totalMontant > 0) {
      differenceMontant = moisActuel.totalMontant - moisPrecedent.totalMontant;
      pourcentageMontant = (differenceMontant / moisPrecedent.totalMontant) * 100;
    }
    
    return ComparisonData(
      moisActuel: moisActuel,
      moisPrecedent: moisPrecedent,
      differenceKwh: differenceKwh,
      differenceMontant: differenceMontant,
      pourcentageKwh: pourcentageKwh,
      pourcentageMontant: pourcentageMontant,
    );
  }

  // Obtenir les consommations dans une période
  static Future<List<Consommation>> _getConsommationsInPeriod(
    DateTime start, 
    DateTime end
  ) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('consommations')
        .where('dateCreation', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('dateCreation', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();

    return querySnapshot.docs
        .map((doc) => Consommation.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Obtenir le début de la semaine (lundi)
  static DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  // Obtenir le nom du mois
  static String _getMonthName(int mois) {
    const moisNoms = [
      '', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return moisNoms[mois];
  }

  // Obtenir les années disponibles
  static Future<List<int>> getAvailableYears() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('consommations')
        .orderBy('dateCreation', descending: true)
        .get();

    final years = <int>{};
    for (var doc in querySnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final date = (data['dateCreation'] as Timestamp).toDate();
      years.add(date.year);
    }

    return years.toList()..sort((a, b) => b.compareTo(a));
  }

  // Obtenir les mois disponibles pour une année
  static Future<List<int>> getAvailableMonths(int annee) async {
    final yearStart = DateTime(annee, 1, 1);
    final yearEnd = DateTime(annee, 12, 31);
    
    final querySnapshot = await FirebaseFirestore.instance
        .collection('consommations')
        .where('dateCreation', isGreaterThanOrEqualTo: Timestamp.fromDate(yearStart))
        .where('dateCreation', isLessThanOrEqualTo: Timestamp.fromDate(yearEnd))
        .get();

    final months = <int>{};
    for (var doc in querySnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final date = (data['dateCreation'] as Timestamp).toDate();
      months.add(date.month);
    }

    return months.toList()..sort((a, b) => b.compareTo(a));
  }
}


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
          _monthlyStats = await AnalyticsService.getMonthlyStats(_selectedYear, _selectedMonth);
          _comparisonData = await AnalyticsService.getMonthlyComparison(_selectedYear, _selectedMonth);
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
            child: _isLoading
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
            Text('Période d\'analyse', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
            {'Métrique': 'Période', 'Valeur': '${_formatDate(stats.weekStart)} - ${_formatDate(stats.weekEnd)}'},
            {'Métrique': 'Total kWh', 'Valeur': '${stats.totalKwh.toStringAsFixed(1)} kWh'},
            {'Métrique': 'Total Montant', 'Valeur': '${stats.totalMontant.toStringAsFixed(0)} FCFA'},
            {'Métrique': 'Nombre de Consommations', 'Valeur': '${stats.nombreConsommations}'},
            {'Métrique': 'Moyenne kWh/jour', 'Valeur': '${stats.moyenneKwhParJour.toStringAsFixed(1)} kWh'},
            {'Métrique': 'Moyenne Montant/jour', 'Valeur': '${stats.moyenneMontantParJour.toStringAsFixed(0)} FCFA'},
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
            {'Métrique': 'Période', 'Valeur': '${stats.nomMois} ${stats.annee}'},
            {'Métrique': 'Total kWh', 'Valeur': '${stats.totalKwh.toStringAsFixed(1)} kWh'},
            {'Métrique': 'Total Montant', 'Valeur': '${stats.totalMontant.toStringAsFixed(0)} FCFA'},
            {'Métrique': 'Nombre de Consommations', 'Valeur': '${stats.nombreConsommations}'},
            {'Métrique': 'Moyenne kWh/jour', 'Valeur': '${stats.moyenneKwhParJour.toStringAsFixed(1)} kWh'},
            {'Métrique': 'Moyenne Montant/jour', 'Valeur': '${stats.moyenneMontantParJour.toStringAsFixed(0)} FCFA'},
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
            {'Métrique': 'Total kWh', 'Valeur': '${stats.totalKwh.toStringAsFixed(1)} kWh'},
            {'Métrique': 'Total Montant', 'Valeur': '${stats.totalMontant.toStringAsFixed(0)} FCFA'},
            {'Métrique': 'Nombre de Consommations', 'Valeur': '${stats.nombreConsommations}'},
            {'Métrique': 'Moyenne kWh/mois', 'Valeur': '${stats.moyenneKwhParMois.toStringAsFixed(1)} kWh'},
            {'Métrique': 'Moyenne Montant/mois', 'Valeur': '${stats.moyenneMontantParMois.toStringAsFixed(0)} FCFA'},
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
        children: data.map((row) => TableRow(
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
        )).toList(),
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
                child: Text('Métrique', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              Padding(
                padding: EdgeInsets.all(12),
                child: Text('Mois actuel', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              Padding(
                padding: EdgeInsets.all(12),
                child: Text('Mois précédent', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              Padding(
                padding: EdgeInsets.all(12),
                child: Text('Différence', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          TableRow(
            children: [
              Padding(
                padding: EdgeInsets.all(12),
                child: Text('kWh'),
              ),
              Padding(
                padding: EdgeInsets.all(12),
                child: Text('${comparison.moisActuel.totalKwh.toStringAsFixed(1)}'),
              ),
              Padding(
                padding: EdgeInsets.all(12),
                child: Text('${comparison.moisPrecedent?.totalKwh.toStringAsFixed(1) ?? 'N/A'}'),
              ),
              Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  comparison.differenceKwh != null 
                    ? '${comparison.differenceKwh!.toStringAsFixed(1)} (${comparison.pourcentageKwh!.toStringAsFixed(1)}%)'
                    : 'N/A',
                  style: TextStyle(
                    color: comparison.differenceKwh != null && comparison.differenceKwh! > 0 
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
                child: Text('${comparison.moisActuel.totalMontant.toStringAsFixed(0)}'),
              ),
              Padding(
                padding: EdgeInsets.all(12),
                child: Text('${comparison.moisPrecedent?.totalMontant.toStringAsFixed(0) ?? 'N/A'}'),
              ),
              Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  comparison.differenceMontant != null 
                    ? '${comparison.differenceMontant!.toStringAsFixed(0)} (${comparison.pourcentageMontant!.toStringAsFixed(1)}%)'
                    : 'N/A',
                  style: TextStyle(
                    color: comparison.differenceMontant != null && comparison.differenceMontant! > 0 
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
                child: Text('Mois', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              Padding(
                padding: EdgeInsets.all(12),
                child: Text('kWh', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              Padding(
                padding: EdgeInsets.all(12),
                child: Text('Montant (FCFA)', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              Padding(
                padding: EdgeInsets.all(12),
                child: Text('Consommations', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          ...moisStats.map((mois) => TableRow(
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
          )).toList(),
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
          ElevatedButton(
            onPressed: _loadData,
            child: Text('Réessayer'),
          ),
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
      builder: (context) => AlertDialog(
        title: Text('Sélectionner le mois'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: months.map((m) => ListTile(
            title: Text(_getMonthName(m)),
            onTap: () => Navigator.pop(context, m),
          )).toList(),
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
      builder: (context) => AlertDialog(
        title: Text('Sélectionner l\'année'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: years.map((y) => ListTile(
            title: Text(y.toString()),
            onTap: () => Navigator.pop(context, y),
          )).toList(),
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
      '', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return moisNoms[mois];
  }
}
```

## **4. Ajouter le bouton dans l'AppBar de consommation_list.dart :**

```dart:lib/screens/consommation_list.dart
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
  // ... (garder tout le code existant) ...

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
                MaterialPageRoute(
                  builder: (context) => AnalyticsScreen(),
                ),
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
        // ... (garder tout le code existant du body) ...
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _ajouterConsommationDialog(context),
        child: Icon(Icons.add),
        tooltip: 'Nouvelle consommation',
      ),
    );
  }

  // ... (garder tout le reste du code existant) ...
}
```
