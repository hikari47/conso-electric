import 'package:conso_famille/screens/auth_screen.dart';
import 'package:conso_famille/screens/bienvenue_screen.dart';
import 'package:conso_famille/screens/inscription_screen.dart';
import 'package:conso_famille/screens/consommation_list.dart';
import 'package:conso_famille/screens/modifier_profil_screen.dart';
import 'package:go_router/go_router.dart';


final router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) =>  BienvenueScreen()),
    GoRoute(path: '/auth', builder: (context, state) =>  AuthScreen()),
    GoRoute(path: '/inscription', builder: (context, state) =>  InscriptionScreen()),
    GoRoute(path: '/consommations', builder: (context, state) =>  ConsommationList()),
    GoRoute(path: '/profil', builder: (context, state) =>  ModifierProfilScreen(nomInitial: 'nomInitial', numeroInitial: 'numeroInitial')),
  ],
);