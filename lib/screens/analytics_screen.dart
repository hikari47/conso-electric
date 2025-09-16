import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:conso_famille/theme/app_theme.dart';
import '../models/analytics_models.dart';
import '../services/analytics_service.dart';

class AnalyticsScreen extends StatefulWidget {
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with TickerProviderStateMixin {
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

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          switch (_tabController.index) {
            case 0:
              _selectedPeriod = AnalyticsPeriod.semaine;
              break;
            case 1:
              _selectedPeriod = AnalyticsPeriod.mois;
              break;
            case 2:
              _selectedPeriod = AnalyticsPeriod.annee;
              break;
          }
        });
        _loadData();
      }
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
      _error = e.toString();
    } finally {
      setState(() {
        _isLoading = false;
      });
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
          'Analyses & Statistiques',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [Tab(text: 'Semaine'), Tab(text: 'Mois'), Tab(text: 'Année')],
        ),
      ),
      body: Column(
        children: [
          // Sélecteurs de période
          Container(
            color: Colors.white,
            padding: EdgeInsets.all(16),
            child: _buildPeriodSelectors(),
          ),

          // Contenu principal
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildWeeklyContent(),
                _buildMonthlyContent(),
                _buildYearlyContent(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelectors() {
    switch (_selectedPeriod) {
      case AnalyticsPeriod.semaine:
        return _buildWeekSelector();
      case AnalyticsPeriod.mois:
        return _buildMonthSelector();
      case AnalyticsPeriod.annee:
        return _buildYearSelector();
    }
  }

  Widget _buildWeekSelector() {
    return Row(
      children: [
        Icon(Icons.calendar_today, color: AppTheme.primaryColor),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'Semaine du ${_formatDate(_selectedDate)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => _selectWeek(),
          icon: Icon(Icons.edit_calendar, size: 18),
          label: Text('Changer'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthSelector() {
    return Row(
      children: [
        Icon(Icons.calendar_month, color: AppTheme.primaryColor),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            '${_getMonthName(_selectedMonth)} $_selectedYear',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => _selectMonth(),
          icon: Icon(Icons.edit_calendar, size: 18),
          label: Text('Changer'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildYearSelector() {
    return Row(
      children: [
        Icon(CupertinoIcons.calendar, color: AppTheme.primaryColor),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'Année $_selectedYear',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => _selectYear(),
          icon: Icon(Icons.edit_calendar, size: 18),
          label: Text('Changer'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyContent() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    if (_error != null) {
      return _buildErrorWidget();
    }

    if (_weeklyStats == null) {
      return _buildEmptyWidget('Aucune donnée disponible pour cette semaine');
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsCard(
            'Consommation hebdomadaire',
            '${_weeklyStats!.totalKwh.toStringAsFixed(1)} kWh',
            '${_weeklyStats!.totalMontant.toStringAsFixed(0)} FCFA',
            Icons.electrical_services,
            AppTheme.primaryColor,
          ),
          SizedBox(height: 16),
          _buildInfoCard([
            _buildInfoRow(
              'Consommations',
              '${_weeklyStats!.nombreConsommations}',
            ),
            _buildInfoRow(
              'Moyenne/jour',
              '${_weeklyStats!.moyenneKwhParJour.toStringAsFixed(1)} kWh',
            ),
            _buildInfoRow(
              'Dépense/jour',
              '${_weeklyStats!.moyenneMontantParJour.toStringAsFixed(0)} FCFA',
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildMonthlyContent() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    if (_error != null) {
      return _buildErrorWidget();
    }

    if (_monthlyStats == null) {
      return _buildEmptyWidget('Aucune donnée disponible pour ce mois');
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsCard(
            'Consommation mensuelle',
            '${_monthlyStats!.totalKwh.toStringAsFixed(1)} kWh',
            '${_monthlyStats!.totalMontant.toStringAsFixed(0)} FCFA',
            Icons.calendar_month,
            AppTheme.primaryColor,
          ),
          SizedBox(height: 16),
          if (_comparisonData != null) ...[
            _buildComparisonCard(),
            SizedBox(height: 16),
          ],
          _buildInfoCard([
            _buildInfoRow(
              'Consommations',
              '${_monthlyStats!.nombreConsommations}',
            ),
            _buildInfoRow(
              'Moyenne/jour',
              '${_monthlyStats!.moyenneKwhParJour.toStringAsFixed(1)} kWh',
            ),
            _buildInfoRow(
              'Dépense/jour',
              '${_monthlyStats!.moyenneMontantParJour.toStringAsFixed(0)} FCFA',
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildYearlyContent() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    if (_error != null) {
      return _buildErrorWidget();
    }

    if (_yearlyStats == null) {
      return _buildEmptyWidget('Aucune donnée disponible pour cette année');
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsCard(
            'Consommation annuelle',
            '${_yearlyStats!.totalKwh.toStringAsFixed(1)} kWh',
            '${_yearlyStats!.totalMontant.toStringAsFixed(0)} FCFA',
            CupertinoIcons.calendar,
            AppTheme.primaryColor,
          ),
          SizedBox(height: 16),
          _buildMonthlyBreakdown(),
          SizedBox(height: 16),
          _buildInfoCard([
            _buildInfoRow(
              'Total consommations',
              '${_yearlyStats!.nombreConsommations}',
            ),
            _buildInfoRow(
              'Moyenne/mois',
              '${_yearlyStats!.moyenneKwhParMois.toStringAsFixed(1)} kWh',
            ),
            _buildInfoRow(
              'Dépense/mois',
              '${_yearlyStats!.moyenneMontantParMois.toStringAsFixed(0)} FCFA',
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildStatsCard(
    String title,
    String kwh,
    String montant,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Consommation',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        kwh,
                        style: Theme.of(
                          context,
                        ).textTheme.headlineMedium?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dépense',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        montant,
                        style: Theme.of(
                          context,
                        ).textTheme.headlineMedium?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comparaison avec le mois précédent',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 16),
            _buildComparisonRow(
              'Consommation',
              '${_comparisonData!.differenceKwh} kWh',
              _comparisonData!.pourcentageKwh ?? 0,
            ),
            _buildComparisonRow(
              'Dépense',
              '${_comparisonData!.differenceMontant} FCFA',
              _comparisonData!.pourcentageMontant ?? 0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonRow(String label, String value, double percentage) {
    final isPositive = percentage >= 0;
    final color = isPositive ? AppTheme.successColor : AppTheme.errorColor;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(width: 12),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${isPositive ? '+' : ''}${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyBreakdown() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Détail par mois',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 16),
            ...(_yearlyStats!.moisStats.map(
              (month) => Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _getMonthName(month.mois),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      '${month.totalKwh.toStringAsFixed(1)} kWh',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 16),
                    Text(
                      '${month.totalMontant.toStringAsFixed(0)} FCFA',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Détails',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
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
            _error!,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: AppTheme.textSecondary,
          ),
          SizedBox(height: 16),
          Text(
            'Aucune donnée',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppTheme.textSecondary),
          ),
          SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
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
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(_selectedYear, _selectedMonth),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _selectedYear = date.year;
        _selectedMonth = date.month;
      });
      _loadData();
    }
  }

  Future<void> _selectYear() async {
    final year = await showDialog<int>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Sélectionner une année'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                DateTime.now().year - 2019,
                (index) => ListTile(
                  title: Text('${DateTime.now().year - index}'),
                  onTap:
                      () => Navigator.pop(context, DateTime.now().year - index),
                ),
              ),
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

  String _getMonthName(int month) {
    const months = [
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
    return months[month - 1];
  }
}
