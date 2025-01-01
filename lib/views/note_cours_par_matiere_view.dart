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
  bool isUploading = false;
  bool isDownloading = false;
  List<Map<String, dynamic>> notes = [];
  final ImagePicker _picker = ImagePicker();
  File? _file;
  String fileName = '';
  String noteDescription = '';
  String? selectedType;
  DateTime? _selectedDate;
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
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final response = await http.get(
        Uri.parse('${Config.sander}/getNotes?subjectName=${widget.subjectName}'),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          notes = List<Map<String, dynamic>>.from(data);
          isLoading = false;
        });
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (error) {
      print("Erreur lors de la récupération des notes : $error");
      setState(() {
        hasError = true;
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement des notes: $error')),
      );
    }
  }

  // Fonction pour ouvrir le formulaire d'upload
  Future<void> uploadNote() async {
    setState(() {
      _file = null;
      fileName = '';
      noteDescription = '';
      selectedType = null;
      _selectedDate = null;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          decoration: InputDecoration(
                            labelText: "Nom du fichier",
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) => setModalState(() => fileName = value),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          decoration: InputDecoration(
                            labelText: "Description des notes",
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                          onChanged: (value) => setModalState(() => noteDescription = value),
                        ),
                        SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: "Type de contenu",
                            border: OutlineInputBorder(),
                          ),
                          value: selectedType,
                          items: contentTypes.map((String type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                          onChanged: (value) => setModalState(() => selectedType = value),
                        ),
                        SizedBox(height: 10),
                        InkWell(
                          onTap: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            );
                            if (pickedDate != null) {
                              setModalState(() => _selectedDate = pickedDate);
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Date de prise de note',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              _selectedDate != null
                                  ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                  : 'Sélectionnez une date',
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: Icon(Icons.camera_alt),
                                label: Text('Camera'),
                                onPressed: () async {
                                  final pickedImage = await _picker.pickImage(source: ImageSource.camera);
                                  if (pickedImage != null) {
                                    setModalState(() => _file = File(pickedImage.path));
                                  }
                                },
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: Icon(Icons.folder),
                                label: Text('Galerie'),
                                onPressed: () async {
                                  final pickedImage = await _picker.pickImage(source: ImageSource.gallery);
                                  if (pickedImage != null) {
                                    setModalState(() => _file = File(pickedImage.path));
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        if (_file != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Fichier sélectionné: ${_file!.path.split('/').last}',
                              style: TextStyle(color: Colors.green),
                            ),
                          ),
                        SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: EdgeInsets.symmetric(vertical: 15),
                            ),
                            onPressed: _file != null &&
                                    fileName.isNotEmpty &&
                                    noteDescription.isNotEmpty &&
                                    selectedType != null &&
                                    _selectedDate != null
                                ? () async {
                                    Navigator.pop(context);
                                    await uploadFileToServer();
                                  }
                                : null,
                            child: isUploading
                                ? CircularProgressIndicator(color: Colors.white)
                                : Text("Upload"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Fonction pour envoyer le fichier au serveur
  Future<void> uploadFileToServer() async {
    try {
      if (_file == null || fileName.isEmpty || noteDescription.isEmpty || _selectedDate == null) {
        throw Exception("Veuillez remplir tous les champs");
      }

      setState(() => isUploading = true);

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

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Note ajoutée avec succès')),
        );
        await fetchNotes();
      } else {
        throw Exception("Erreur lors de l'upload: ${response.statusCode}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      setState(() => isUploading = false);
    }
  }

  // Fonction pour télécharger et ouvrir un fichier
  Future<void> downloadAndOpenFile(Map<String, dynamic> note) async {
    if (isDownloading) return;

    try {
      setState(() => isDownloading = true);

      final String? noteId = note['_id'] ?? note['id'];
      if (noteId == null) {
        throw Exception("ID de la note manquant");
      }

      final dir = await getApplicationDocumentsDirectory();
      final fileName = note['fileName'] ?? 'fichier';
      final filePath = '${dir.path}/$fileName';

      // Vérifier si le fichier existe déjà
      if (await File(filePath).exists()) {
        await OpenFile.open(filePath);
        return;
      }

      await _dio.download(
        '${Config.sander}/downloadNote/$noteId',
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            print('Download progress: ${(received / total * 100).toStringAsFixed(0)}%');
          }
        },
      );

      final result = await OpenFile.open(filePath);
      if (result.type != ResultType.done) {
        throw Exception('Impossible d\'ouvrir le fichier: ${result.message}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      setState(() => isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            icon: Icon(Icons.refresh),
            onPressed: fetchNotes,
            tooltip: 'Rafraîchir',
          ),
          IconButton(
            icon: Icon(Icons.upload_file),
            onPressed: uploadNote,
            tooltip: 'Ajouter une note',
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Erreur lors du chargement des notes"),
                      ElevatedButton(
                        onPressed: fetchNotes,
                        child: Text("Réessayer"),
                      ),
                    ],
                  ),
                )
              : groupedNotes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Aucune note disponible"),
                          ElevatedButton.icon(
                            icon: Icon(Icons.upload_file),
                            label: Text("Ajouter une note"),
                            onPressed: uploadNote,
                          ),
                        ],
                      ),
                    )
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
                                      Text('Description: ${note['noteDescription'] ?? 'Aucune description'}'),
                                      Text('Date: ${note['noteDate'] ?? 'Non spécifiée'}'),
                                    ],
                                  ),
                                  trailing: isDownloading
                                      ? CircularProgressIndicator()
                                      : Icon(Icons.file_download),
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

  @override
  void dispose() {
    _dio.close();
    super.dispose();
  }
}