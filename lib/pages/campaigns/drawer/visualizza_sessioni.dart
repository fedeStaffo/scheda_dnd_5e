import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dettagli_sessione.dart';

class VisualizzaSessioni extends StatefulWidget {
  final String? campagna;

  VisualizzaSessioni({required this.campagna});

  @override
  _VisualizzaSessioniState createState() => _VisualizzaSessioniState();
}

class _VisualizzaSessioniState extends State<VisualizzaSessioni> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Visualizza Sessioni',
          style: TextStyle(fontSize: 24),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('sessioni')
            .where('campagna', isEqualTo: widget.campagna)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Si è verificato un errore durante il recupero delle sessioni.',
                style: TextStyle(fontSize: 20),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final sessioniList = snapshot.data!.docs;

          if (sessioniList.isEmpty) {
            return const Center(
              child: Text(
                'Nessuna sessione presente in questa campagna.',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            itemCount: sessioniList.length,
            itemBuilder: (context, index) {
              final sessioneData = sessioniList[index].data() as Map<String, dynamic>;
              final numero = sessioneData['numero'];
              final giorno = sessioneData['giorno'];

              return Card(
                child: ListTile(
                  title: Text(
                    'Sessione: $numero',
                    style: const TextStyle(fontSize: 26),
                  ),
                  subtitle: Text(
                    'Giorno: $giorno',
                    style: const TextStyle(fontSize: 24),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SessioneDettagli(
                          numero: numero,
                          campagna: widget.campagna!,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}