import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/analytics_models.dart';
import '../services/consommation_service.dart';

class AnalyticsService {
  // Obtenir les statistiques de la semaine
  static Future<WeeklyStats> getWeeklyStats(DateTime date) async {
    final weekStart = _getWeekStart(date);
    final weekEnd = weekStart.add(Duration(days: 6));

    final consommations = await _getConsommationsInPeriod(weekStart, weekEnd);

    final totalKwh = consommations.fold(0.0, (sum, c) => sum + c.totalKwh);
    final totalMontant = consommations.fold(
      0.0,
      (sum, c) => sum + c.totalMontant,
    );
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
    final totalMontant = consommations.fold(
      0.0,
      (sum, c) => sum + c.totalMontant,
    );
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
    final nombreConsommations = moisStats.fold(
      0,
      (sum, m) => sum + m.nombreConsommations,
    );
    final moisAvecDonnees =
        moisStats.where((m) => m.nombreConsommations > 0).length;

    return YearlyStats(
      annee: annee,
      moisStats: moisStats,
      totalKwh: totalKwh,
      totalMontant: totalMontant,
      nombreConsommations: nombreConsommations,
      moyenneKwhParMois: moisAvecDonnees > 0 ? totalKwh / moisAvecDonnees : 0,
      moyenneMontantParMois:
          moisAvecDonnees > 0 ? totalMontant / moisAvecDonnees : 0,
    );
  }

  // Obtenir la comparaison mensuelle
  static Future<ComparisonData> getMonthlyComparison(
    int annee,
    int mois,
  ) async {
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
      moisPrecedentDate.month,
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
      pourcentageMontant =
          (differenceMontant / moisPrecedent.totalMontant) * 100;
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
    DateTime end,
  ) async {
    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('consommations')
            .where(
              'dateCreation',
              isGreaterThanOrEqualTo: Timestamp.fromDate(start),
            )
            .where('dateCreation', isLessThanOrEqualTo: Timestamp.fromDate(end))
            .get();

    return querySnapshot.docs
        .map(
          (doc) =>
              Consommation.fromMap(doc.id, doc.data() as Map<String, dynamic>),
        )
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

  // Obtenir les années disponibles
  static Future<List<int>> getAvailableYears() async {
    final querySnapshot =
        await FirebaseFirestore.instance
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

    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('consommations')
            .where(
              'dateCreation',
              isGreaterThanOrEqualTo: Timestamp.fromDate(yearStart),
            )
            .where(
              'dateCreation',
              isLessThanOrEqualTo: Timestamp.fromDate(yearEnd),
            )
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
