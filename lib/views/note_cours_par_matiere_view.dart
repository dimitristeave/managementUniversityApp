import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:isibappmoodle/config/config';

class NotesPage extends StatefulWidget {
  final String subjectName;

  const NotesPage({super.key, required this.subjectName});

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
      setState(() {
        hasError = true;
        isLoading = false;
      });
      _showSnackBar('Erreur lors du chargement des notes: $error');
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF1976D2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void uploadNote() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Ajouter une nouvelle note",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1976D2),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildFormField(
                          "Nom du fichier",
                          onChanged: (value) => setModalState(() => fileName = value),
                        ),
                        const SizedBox(height: 16),
                        _buildFormField(
                          "Description",
                          maxLines: 3,
                          onChanged: (value) => setModalState(() => noteDescription = value),
                        ),
                        const SizedBox(height: 16),
                        _buildDropdown(
                          "Type de contenu",
                          contentTypes,
                          selectedType,
                          (value) => setModalState(() => selectedType = value),
                        ),
                        const SizedBox(height: 16),
                        _buildDatePicker(context, setModalState),
                        const SizedBox(height: 24),
                        _buildFileButtons(setModalState),
                        if (_file != null) _buildFilePreview(),
                        const SizedBox(height: 24),
                        _buildSubmitButton(),
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

  Widget _buildFormField(String label, {
    int maxLines = 1,
    required Function(String) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade700),
          floatingLabelStyle: const TextStyle(color: Color(0xFF1976D2)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> items,
    String? value,
    Function(String?) onChanged,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade700),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        items: items.map((String type) {
          return DropdownMenuItem<String>(
            value: type,
            child: Text(type),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context, StateSetter setModalState) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () async {
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: _selectedDate ?? DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2101),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: Color(0xFF1976D2),
                  ),
                ),
                child: child!,
              );
            },
          );
          if (picked != null) {
            setModalState(() => _selectedDate = picked);
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Date de prise de note',
            labelStyle: TextStyle(color: Colors.grey.shade700),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(16),
          ),
          child: Text(
            _selectedDate != null
                ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                : 'Sélectionnez une date',
          ),
        ),
      ),
    );
  }

  Widget _buildFileButtons(StateSetter setModalState) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.camera_alt, color: Colors.white),
            label: const Text('Camera', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final pickedImage = await _picker.pickImage(source: ImageSource.camera);
              if (pickedImage != null) {
                setModalState(() => _file = File(pickedImage.path));
              }
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.folder, color: Colors.white),
            label: const Text('Galerie', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final pickedImage = await _picker.pickImage(source: ImageSource.gallery);
              if (pickedImage != null) {
                setModalState(() => _file = File(pickedImage.path));
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilePreview() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file, color: Color(0xFF1976D2)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _file!.path.split('/').last,
              style: const TextStyle(color: Color(0xFF1976D2)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1976D2),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: isUploading ? null : () {
          if (_file != null &&
              fileName.isNotEmpty &&
              noteDescription.isNotEmpty &&
              selectedType != null &&
              _selectedDate != null) {
            Navigator.pop(context);
            uploadFileToServer();
          } else {
            _showSnackBar('Veuillez remplir tous les champs');
          }
        },
        child: isUploading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: Colors.white),
              )
            : const Text(
                "Upload",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
      ),
    );
  }

  // ... (Garder les autres méthodes existantes uploadFileToServer, downloadAndOpenFile, etc.)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        elevation: 0,
        title: Text(
          '${widget.subjectName} - Notes',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: fetchNotes,
            tooltip: 'Rafraîchir',
          ),
          IconButton(
            icon: const Icon(Icons.upload_file, color: Colors.white),
            onPressed: uploadNote,
            tooltip: 'Ajouter une note',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1976D2).withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: _buildNotesList(),
      ),
    );
  }

  Widget _buildNotesList() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
        ),
      );
    }

    if (hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Color(0xFF1976D2)),
            const SizedBox(height: 16),
            const Text(
              "Erreur lors du chargement des notes",
              style: TextStyle(fontSize: 18, color: Color(0xFF1976D2)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: fetchNotes,
              child: const Text("Réessayer", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (notes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.note_add, size: 60, color: Color(0xFF1976D2)),
            const SizedBox(height: 16),
            const Text(
              "Aucune note disponible",
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFF1976D2),
                fontWeight: FontWeight.bold,
                ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_file, color: Colors.white),
              label: const Text(
                "Ajouter une note",
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: uploadNote,
            ),
          ],
        ),
      );
    }

    // Grouper les notes par type
    final Map<String, List<Map<String, dynamic>>> groupedNotes = {};
    for (var note in notes) {
      final type = note['contentType'] ?? 'Autre';
      if (!groupedNotes.containsKey(type)) {
        groupedNotes[type] = [];
      }
      groupedNotes[type]!.add(note);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedNotes.length,
      itemBuilder: (context, index) {
        final type = groupedNotes.keys.elementAt(index);
        final notesOfType = groupedNotes[type]!;

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(
              color: const Color(0xFF1976D2).withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: Text(
                type,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1976D2),
                ),
              ),
              children: notesOfType.map((note) {
                return _buildNoteItem(note);
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoteItem(Map<String, dynamic> note) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          note['fileName'] ?? 'Sans titre',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF1976D2),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Description: ${note['noteDescription'] ?? 'Aucune description'}',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 2),
            Text(
              'Date: ${note['noteDate'] ?? 'Non spécifiée'}',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
        trailing: isDownloading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
                ),
              )
            : Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1976D2),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  Icons.file_download,
                  color: Colors.white,
                  size: 20,
                ),
              ),
        onTap: () => downloadAndOpenFile(note),
      ),
    );
  }

  Future<void> uploadFileToServer() async {
    if (_file == null ||
        fileName.isEmpty ||
        noteDescription.isEmpty ||
        selectedType == null ||
        _selectedDate == null) {
      _showSnackBar('Veuillez remplir tous les champs');
      return;
    }

    setState(() => isUploading = true);

    try {
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
      request.fields.addAll({
        'subjectName': widget.subjectName,
        'fileName': fileName,
        'noteDescription': noteDescription,
        'contentType': selectedType!,
        'noteDate': '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
      });

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        _showSnackBar('Note ajoutée avec succès', isError: false);
        await fetchNotes();
      } else {
        throw Exception("Erreur lors de l'upload: ${response.statusCode}");
      }
    } catch (e) {
      _showSnackBar('Erreur: $e');
    } finally {
      setState(() => isUploading = false);
    }
  }

  Future<void> downloadAndOpenFile(Map<String, dynamic> note) async {
    if (isDownloading) return;

    setState(() => isDownloading = true);
    try {
      final String? noteId = note['_id'] ?? note['id'];
      if (noteId == null) {
        throw Exception("ID de la note manquant");
      }

      final dir = await getApplicationDocumentsDirectory();
      final fileName = note['fileName'] ?? 'fichier';
      final filePath = '${dir.path}/$fileName';

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
      _showSnackBar('Erreur: $e');
    } finally {
      setState(() => isDownloading = false);
    }
  }

  @override
  void dispose() {
    _dio.close();
    super.dispose();
  }
}