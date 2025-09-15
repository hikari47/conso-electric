// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import '../screens/auth_screen.dart';
// import '../screens/inscription_screen.dart';
// import '../screens/consommation_list.dart';
// import '../screens/consommation_detail_screen.dart';
// import '../screens/modifier_profil_screen.dart';
// import '../services/user_service.dart';

// class AppRouter {
//   static final _rootNavigatorKey = GlobalKey<NavigatorState>();

//   // État de chargement global
//   static bool _isLoading = false;

//   // Fonction pour vérifier l'authentification
//   static Future<bool> _isUserAuthenticated() async {
//     final user = FirebaseAuth.instance.currentUser;
//     return user != null;
//   }

//   // Fonction pour vérifier si le profil existe
//   static Future<bool> _hasUserProfile() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return false;

//     try {
//       final profil = await recupererProfilUtilisateur();
//       return profil != null;
//     } catch (e) {
//       return false;
//     }
//   }

//   // Fonction de redirection principale
//   static Future<String?> _redirectLogic(
//     BuildContext context,
//     GoRouterState state,
//   ) async {
//     final isAuthenticated = await _isUserAuthenticated();
//     final hasProfile = await _hasUserProfile();
//     final currentLocation = state.uri.path; // ✅ Correction ici

//     // Routes publiques (accessibles sans authentification)
//     final publicRoutes = ['/auth', '/inscription', '/error'];
//     final isPublicRoute = publicRoutes.any(
//       (route) => currentLocation.startsWith(route),
//     );

//     // Routes protégées (nécessitent une authentification)
//     final protectedRoutes = ['/consommations', '/consommation', '/profil'];
//     final isProtectedRoute = protectedRoutes.any(
//       (route) => currentLocation.startsWith(route),
//     );

//     // Si l'utilisateur n'est pas connecté
//     if (!isAuthenticated) {
//       // Rediriger vers l'authentification si ce n'est pas une route publique
//       if (!isPublicRoute) {
//         return '/auth';
//       }
//       return null; // Pas de redirection pour les routes publiques
//     }

//     // Si l'utilisateur est connecté mais n'a pas de profil
//     if (isAuthenticated && !hasProfile) {
//       // Rediriger vers l'inscription si ce n'est pas déjà l'inscription
//       if (currentLocation != '/inscription') {
//         return '/inscription';
//       }
//       return null;
//     }

//     // Si l'utilisateur est connecté et a un profil
//     if (isAuthenticated && hasProfile) {
//       // Rediriger vers les consommations si sur auth/inscription
//       if (currentLocation == '/auth' || currentLocation == '/inscription') {
//         return '/consommations';
//       }
//     }

//     return null; // Pas de redirection
//   }

//   static final GoRouter router = GoRouter(
//     navigatorKey: _rootNavigatorKey,
//     initialLocation: '/auth',
//     redirect: _redirectLogic,
//     routes: [
//       // Route d'authentification
//       GoRoute(
//         path: '/auth',
//         name: 'auth',
//         builder: (context, state) => AuthScreen(),
//         onExit: (context, state) async {
//           // Vérifier si l'utilisateur s'est connecté
//           final isAuthenticated = await _isUserAuthenticated();
//           if (isAuthenticated) {
//             // Rediriger vers les consommations après connexion
//             context.go('/consommations');
//           }
//           return true;
//         },
//       ),

//       // Route d'inscription
//       GoRoute(
//         path: '/inscription',
//         name: 'inscription',
//         builder: (context, state) => InscriptionScreen(),
//         onExit: (context, state) async {
//           // Vérifier si l'utilisateur a un profil
//           final hasProfile = await _hasUserProfile();
//           if (hasProfile) {
//             // Rediriger vers les consommations après inscription
//             context.go('/consommations');
//           }
//           return true;
//         },
//       ),

//       // Route principale - Liste des consommations
//       GoRoute(
//         path: '/consommations',
//         name: 'consommations',
//         builder:
//             (context, state) => Scaffold(
//               appBar: AppBar(
//                 title: Text('Consommations'),
//                 actions: [
//                   IconButton(
//                     icon: Icon(Icons.person),
//                     onPressed: () => context.go('/profil'),
//                     tooltip: 'Profil',
//                   ),
//                 ],
//               ),
//               body: ConsommationList(),
//             ),
//         redirect: (context, state) async {
//           // Vérifier l'authentification avant d'entrer
//           final isAuthenticated = await _isUserAuthenticated();
//           if (!isAuthenticated) {
//             return '/auth';

//           }
//           return '/consommations';
//         },
//       ),

//       // Route de détail d'une consommation
//       GoRoute(
//         path: '/consommation/:id',
//         name: 'consommation-detail',
//         builder: (context, state) {
//           final consommationId = state.pathParameters['id'];
//           if (consommationId == null || consommationId.isEmpty) {
//             // Rediriger vers la liste si l'ID est invalide
//             context.go('/consommations');
//             return Scaffold(body: Center(child: CircularProgressIndicator()));
//           }
//           return ConsommationDetailScreen(consommationId: consommationId);
//         },
//         onEnter: (context, state) async {
//           // Vérifier l'authentification et la validité de l'ID
//           final isAuthenticated = await _isUserAuthenticated();
//           if (!isAuthenticated) {
//             context.go('/auth');
//             return false;
//           }

//           final consommationId = state.pathParameters['id'];
//           if (consommationId == null || consommationId.isEmpty) {
//             context.go('/consommations');
//             return false;
//           }

//           return true;
//         },
//       ),

//       // Route de modification du profil
//       GoRoute(
//         path: '/profil',
//         name: 'profil',
//         builder: (context, state) => ModifierProfilScreen(),
//         onEnter: (context, state) async {
//           // Vérifier l'authentification avant d'entrer
//           final isAuthenticated = await _isUserAuthenticated();
//           if (!isAuthenticated) {
//             context.go('/auth');
//             return false;
//           }
//           return true;
//         },
//       ),

//       // Route de déconnexion
//       GoRoute(
//         path: '/logout',
//         name: 'logout',
//         builder:
//             (context, state) =>
//                 Scaffold(body: Center(child: CircularProgressIndicator())),
//         onEnter: (context, state) async {
//           // Déconnecter l'utilisateur
//           await FirebaseAuth.instance.signOut();
//           // Rediriger vers l'authentification
//           context.go('/auth');
//           return false;
//         },
//       ),

//       // Route d'erreur
//       GoRoute(
//         path: '/error',
//         name: 'error',
//         builder: (context, state) {
//           final error =
//               state.uri.queryParameters['message'] ?? 'Une erreur est survenue';
//           return Scaffold(
//             appBar: AppBar(title: Text('Erreur')),
//             body: Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.error, size: 64, color: Colors.red),
//                   SizedBox(height: 16),
//                   Text(
//                     'Erreur',
//                     style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//                   ),
//                   SizedBox(height: 8),
//                   Text(error, textAlign: TextAlign.center),
//                   SizedBox(height: 16),
//                   ElevatedButton(
//                     onPressed: () => context.go('/consommations'),
//                     child: Text('Retour à l\'accueil'),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     ],

//     // Gestionnaire d'erreurs global
//     errorBuilder:
//         (context, state) => Scaffold(
//           appBar: AppBar(title: Text('Erreur')),
//           body: Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(Icons.error_outline, size: 64, color: Colors.red),
//                 SizedBox(height: 16),
//                 Text(
//                   'Page non trouvée',
//                   style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//                 ),
//                 SizedBox(height: 8),
//                 Text(
//                   'La page ${state.uri.path} n\'existe pas', // ✅ Correction ici aussi
//                   textAlign: TextAlign.center,
//                 ),
//                 SizedBox(height: 16),
//                 ElevatedButton(
//                   onPressed: () => context.go('/consommations'),
//                   child: Text('Retour à l\'accueil'),
//                 ),
//               ],
//             ),
//           ),
//         ),

//     // Gestionnaire de redirection en cas d'erreur
//     redirect: (context, state) async {
//       try {
//         return await _redirectLogic(context, state);
//       } catch (e) {
//         // En cas d'erreur, rediriger vers la page d'erreur
//         return '/error?message=${Uri.encodeComponent(e.toString())}';
//       }
//     },
//   );

//   // Méthodes utilitaires pour la navigation
//   static void goToAuth(BuildContext context) {
//     context.go('/auth');
//   }

//   static void goToInscription(BuildContext context) {
//     context.go('/inscription');
//   }

//   static void goToConsommations(BuildContext context) {
//     context.go('/consommations');
//   }

//   static void goToConsommationDetail(BuildContext context, String id) {
//     context.go('/consommation/$id');
//   }

//   static void goToProfil(BuildContext context) {
//     context.go('/profil');
//   }

//   static void logout(BuildContext context) {
//     context.go('/logout');
//   }

//   static void goToError(BuildContext context, String message) {
//     context.go('/error?message=${Uri.encodeComponent(message)}');
//   }

//   // Méthode pour vérifier si une route est accessible
//   static Future<bool> canAccessRoute(String route) async {
//     final isAuthenticated = await _isUserAuthenticated();
//     final hasProfile = await _hasUserProfile();

//     // Routes publiques
//     if (['/auth', '/inscription', '/error'].contains(route)) {
//       return true;
//     }

//     // Routes protégées
//     if (['/consommations', '/consommation', '/profil'].contains(route)) {
//       return isAuthenticated && hasProfile;
//     }

//     return false;
//   }

//   // Méthode pour obtenir la route de redirection appropriée
//   static Future<String> getRedirectRoute() async {
//     final isAuthenticated = await _isUserAuthenticated();
//     final hasProfile = await _hasUserProfile();

//     if (!isAuthenticated) {
//       return '/auth';
//     }

//     if (!hasProfile) {
//       return '/inscription';
//     }

//     return '/consommations';
//   }
// }
