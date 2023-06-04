import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class JoinCampaignScreen extends StatefulWidget {
  @override
  _JoinCampaignScreenState createState() => _JoinCampaignScreenState();
}

class _JoinCampaignScreenState extends State<JoinCampaignScreen> {
  final TextEditingController _nomeCampagnaController = TextEditingController();
  final TextEditingController _passwordCampagnaController = TextEditingController();
  String? _nomePersonaggioSelezionato;

  @override
  void initState() {
    super.initState();
    initializeState();
  }

  void initializeState() {
    _nomePersonaggioSelezionato = null;
  }

  void _unisciti(BuildContext context) {
    final String nomeCampagna = _nomeCampagnaController.text;
    final String passwordCampagna = _passwordCampagnaController.text;

    FirebaseFirestore.instance
        .collection('campagne')
        .where('nome', isEqualTo: nomeCampagna)
        .where('password', isEqualTo: passwordCampagna)
        .get()
        .then((snapshot) {
      if (snapshot.size == 0) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Errore'),
              content: const Text('Controlla i campi inseriti'),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
        return;
      }

      final campagnaDocument = snapshot.docs[0];
      final campagnaId = campagnaDocument.id;
      final partecipanti =
      campagnaDocument.get('partecipanti') as List<dynamic>;

      final userId = FirebaseAuth.instance.currentUser?.uid;
      final campagnaMasterId =
      campagnaDocument.get('masterId') as String;

      if (partecipanti.contains(userId)) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Errore'),
              content: const Text('Partecipi già a questa campagna'),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
        return;
      }

      if (userId == campagnaMasterId) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Errore'),
              content: const Text('Sei già il master di questa campagna'),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
        return;
      }

      final updates = <String, dynamic>{
        'partecipanti': FieldValue.arrayUnion([userId]),
      };

      if (_nomePersonaggioSelezionato != null &&
          _nomePersonaggioSelezionato!.isNotEmpty) {
        updates['personaggi'] =
            FieldValue.arrayUnion([_nomePersonaggioSelezionato]);

        FirebaseFirestore.instance
            .collection('personaggi')
            .where('nome', isEqualTo: _nomePersonaggioSelezionato)
            .get()
            .then((snapshot) {
          for (var document in snapshot.docs) {
            document.reference.update({'campagna': nomeCampagna});
          }
        });
      }

      FirebaseFirestore.instance
          .collection('campagne')
          .doc(campagnaId)
          .update(updates)
          .then((_) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Successo'),
              content: const Text('Sei stato aggiunto alla campagna'),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }).catchError((error) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Errore'),
              content: const Text(
                  'Si è verificato un errore durante l\'unione alla campagna'),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Partecipa'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _nomeCampagnaController,
                decoration: const InputDecoration(
                  labelText: 'Nome della campagna',
                ),
              ),
              TextField(
                controller: _passwordCampagnaController,
                decoration: const InputDecoration(
                  labelText: 'Password della campagna',
                ),
              ),
              const SizedBox(height: 16.0),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('personaggi')
                    .where('campagna', isEqualTo: '')
                    .where('utenteId',
                    isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('Si è verificato un errore.'),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }

                  final personaggiDisponibili = snapshot.data?.docs
                      .map((doc) => doc.get('nome') as String)
                      .toSet()
                      .toList();

                  if (personaggiDisponibili == null ||
                      personaggiDisponibili.isEmpty) {
                    return const Text('Nessun personaggio disponibile');
                  }

                  if (_nomePersonaggioSelezionato != null &&
                      !_nomePersonaggioSelezionato!.isEmpty &&
                      !personaggiDisponibili.contains(_nomePersonaggioSelezionato)) {
                    _nomePersonaggioSelezionato = null;
                  }

                  return DropdownButton<String>(
                    items: personaggiDisponibili.map((personaggio) {
                      return DropdownMenuItem<String>(
                        value: personaggio,
                        child: Text(personaggio),
                      );
                    }).toList(),
                    value: _nomePersonaggioSelezionato,
                    onChanged: (value) {
                      setState(() {
                        _nomePersonaggioSelezionato = value;
                      });
                    },
                    hint: const Text('Seleziona un personaggio'),
                    isExpanded: true,
                  );
                },
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () => _unisciti(context),
                child: const Text('Unisciti'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
