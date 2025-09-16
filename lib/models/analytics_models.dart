import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/analytics_models.dart';
import '../services/consommation_service.dart';
import 'package:flutter/material.dart';

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

enum AnalyticsPeriod { semaine, mois, annee }

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

