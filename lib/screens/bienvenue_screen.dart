import 'package:flutter/material.dart';
import 'consommation_list.dart';

class BienvenueScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bienvenue')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 100, color: Colors.green),
            SizedBox(height: 20),
            Text(
              'Inscription réussie !',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Votre compte a été créé avec succès.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => ConsommationList()),
                );
              },
              child: Text('Commencer'),
            ),
          ],
        ),
      ),
    );
  }
}
