import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:isibappmoodle/config/config';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class NotesPage extends StatefulWidget {
  final String subjectName;

  NotesPage({required this.subjectName});

  @override
  _NotesPageState createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  bool isLoading = true;
  bool hasError = false;
  List<Map<String, dynamic>> notes = [];
  final ImagePicker _picker = ImagePicker();
  File? _file;
  String fileName = '';
  String noteDescription = '';
  String? selectedType;
  DateTime? _selectedDate; // Utilisation de DateTime pour la date de prise de note
  final Dio _dio = Dio();

  final List<String> contentTypes = [
    'cours oral',
    'exercices',
    'solutions des exercices',
    'laboratoire',
  ];

  @override
  void initState() {
    super.initState();
    fetchNotes();
  }

  // Fonction pour récupérer les notes depuis le serveur
  Future<void> fetchNotes() async {
  try {
    final response = await http.get(
      Uri.parse('${Config.sander}/getNotes?subjectName=${widget.subjectName}'),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      print('Notes data: $data'); // Log pour debug
      setState(() {
        notes = List<Map<String, dynamic>>.from(data);
        isLoading = false;
      });
    } else {
      print('Error response: ${response.body}'); // Log pour debug
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  } catch (error) {
    print("Erreur lors de la récupération des notes : $error");
    setState(() {
      hasError = true;
      isLoading = false;
    });
  }
}

  // Fonction pour ouvrir le formulaire d'upload
  Future<void> uploadNote() async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: InputDecoration(labelText: "Nom du fichier"),
                    onChanged: (value) => fileName = value,
                  ),
                  SizedBox(height: 10),
                  TextField(
                    decoration: InputDecoration(labelText: "Description des notes"),
                    onChanged: (value) => noteDescription = value,
                  ),
                  SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: "Type de contenu"),
                    value: selectedType,
                    items: contentTypes.map((String type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (value) => selectedType = value,
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Date de prise de note',
                      hintText: 'Sélectionnez une date',
                    ),
                    controller: TextEditingController(
                      text: _selectedDate != null
                          ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                          : '',
                    ),
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                      );
                      if (pickedDate != null) {
                        setState(() => _selectedDate = pickedDate);
                      }
                    },
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        icon: Icon(Icons.camera),
                        label: Text('Camera'),
                        onPressed: () async {
                          final pickedImage = await _picker.pickImage(source: ImageSource.camera);
                          if (pickedImage != null) {
                            setState(() => _file = File(pickedImage.path));
                          }
                        },
                      ),
                      ElevatedButton.icon(
                        icon: Icon(Icons.folder),
                        label: Text('Galerie'),
                        onPressed: () async {
                          final pickedImage = await _picker.pickImage(source: ImageSource.gallery);
                          if (pickedImage != null) {
                            setState(() => _file = File(pickedImage.path));
                          }
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _file != null &&
                            fileName.isNotEmpty &&
                            noteDescription.isNotEmpty &&
                            selectedType != null &&
                            _selectedDate != null
                        ? () {
                            uploadFileToServer();
                            Navigator.pop(context); // Ferme le formulaire après upload
                          }
                        : null,
                    child: Text("Upload"),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Fonction pour envoyer le fichier au serveur
  Future<void> uploadFileToServer() async {
    try {
      if (_file == null || fileName.isEmpty || noteDescription.isEmpty || _selectedDate == null) {
        return;
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${Config.sander}/uploadNote'),
      );

      var mimeType = lookupMimeType(_file!.path);
      var multipartFile = await http.MultipartFile.fromPath(
        'file',
        _file!.path,
        contentType: mimeType != null ? MediaType.parse(mimeType) : null,
      );

      request.files.add(multipartFile);
      request.fields['subjectName'] = widget.subjectName;
      request.fields['fileName'] = fileName;
      request.fields['noteDescription'] = noteDescription;
      request.fields['contentType'] = selectedType!;
      request.fields['noteDate'] = '${_selectedDate!.year}-${_selectedDate!.month}-${_selectedDate!.day}';

      var response = await request.send();

      if (response.statusCode == 200) {
        print("Fichier uploadé avec succès");
        fetchNotes();
      } else {
        print("Erreur lors de l'upload : ${response.statusCode}");
      }
    } catch (e) {
      print("Erreur : $e");
    }
  }

  // Fonction pour télécharger et ouvrir un fichier
  Future<void> downloadAndOpenFile(Map<String, dynamic> note) async {
    try {
      // Vérification de la présence de l'ID
      final String? noteId = note['_id'] ?? note['id']; // Vérifie les deux formats possibles
      if (noteId == null) {
        throw Exception("ID de la note manquant");
      }

      // Afficher un indicateur de progression
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(child: CircularProgressIndicator());
        },
      );

      final dir = await getApplicationDocumentsDirectory();
      final fileName = note['fileName'] ?? 'fichier';
      final filePath = '${dir.path}/$fileName';

      // Log pour debug
      print('Downloading from: ${Config.sander}/downloadNote/$noteId');

      // Utilisation de Dio avec logs détaillés
      final response = await _dio.download(
        '${Config.sander}/downloadNote/$noteId',
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            print('Download progress: ${(received / total * 100).toStringAsFixed(0)}%');
          }
        },
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      // Vérifier le statut de la réponse
      if (response.statusCode != 200) {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }

      Navigator.pop(context); // Ferme le dialogue de progression

      // Ouvrir le fichier
      final result = await OpenFile.open(filePath);
      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible d\'ouvrir le fichier: ${result.message}')),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Ferme le dialogue de progression en cas d'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du téléchargement: $e')),
      );
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    // Organiser les notes par type
    final Map<String, List<Map<String, dynamic>>> groupedNotes = {};
    for (var note in notes) {
      final type = note['contentType'] ?? 'Autre';
      if (!groupedNotes.containsKey(type)) {
        groupedNotes[type] = [];
      }
      groupedNotes[type]!.add(note);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.subjectName} - Notes'),
        actions: [
          IconButton(
            icon: Icon(Icons.upload_file),
            tooltip: 'Ajouter une note',
            onPressed: uploadNote,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : hasError
              ? Center(child: Text("Erreur lors du chargement des notes"))
              : groupedNotes.isEmpty
                  ? Center(child: Text("Aucune note disponible"))
                  : ListView(
                      children: groupedNotes.entries.map((entry) {
                        final contentType = entry.key;
                        final notesOfType = entry.value;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            child: ExpansionTile(
                              title: Text(
                                contentType,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              children: notesOfType.map((note) {
                                return ListTile(
                                  title: Text(note['fileName'] ?? 'Sans titre'),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Description : ${note['noteDescription'] ?? 'Aucune description'}'),
                                      Text('Date : ${note['noteDate'] ?? 'Non spécifiée'}'),
                                    ],
                                  ),
                                  trailing: Icon(Icons.file_download),
                                  onTap: () => downloadAndOpenFile(note),
                                );
                              }).toList(),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
    );
  }

}
