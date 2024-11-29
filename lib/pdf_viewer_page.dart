import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:io';

class PdfViewerPage extends StatefulWidget {
  final String filePath;

  const PdfViewerPage({Key? key, required this.filePath}) : super(key: key);

  @override
  _PdfViewerPageState createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  late PdfViewerController _pdfViewerController;
  final FlutterTts flutterTts = FlutterTts();
  double _fontSize = 1.0;
  bool _highContrast = false;
  String _currentFont = 'Arial';
  late String _currentFilePath;

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
    _currentFilePath = widget.filePath; // Inicializa el archivo actual
  }

  @override
  void dispose() {
    flutterTts.stop(); // Detiene cualquier lectura activa
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visor de PDF'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_open),
            onPressed: _openPdfFile, // Acción para abrir un archivo
          ),
        ],
      ),
      body: Stack(
        children: [
          SfPdfViewer.file(
            File(_currentFilePath), // Cargar el archivo seleccionado
            controller: _pdfViewerController,
            pageLayoutMode: PdfPageLayoutMode.single,
            canShowScrollHead: true,
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              child: const Icon(Icons.accessibility_new),
              onPressed: _showAccessibilityMenu,
            ),
          ),
        ],
      ),
    );
  }

  // Abrir el selector de archivos y cargar un nuevo PDF
  void _openPdfFile() async {
    // Abrir el selector de archivos
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'], // Solo permitir archivos PDF
    );

    if (result != null && result.files.isNotEmpty) {
      // Si se selecciona un archivo PDF
      String? path = result.files.single.path;
      if (path != null) {
        setState(() {
          _currentFilePath = path; // Actualiza la ruta del archivo
        });
      }
    }
  }

  // Mostrar el menú de accesibilidad
  void _showAccessibilityMenu() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Lector de voz
                  ListTile(
                    leading: const Icon(Icons.record_voice_over),
                    title: const Text('Lector de voz'),
                    onTap: () async {
                      try {
                        final PdfDocument document = PdfDocument(
                            inputBytes:
                                File(_currentFilePath).readAsBytesSync());
                        final String text =
                            PdfTextExtractor(document).extractText();
                        document.dispose();

                        // Leer el texto con FlutterTTS
                        await flutterTts.speak(text);
                      } catch (e) {
                        print('Error al extraer texto del PDF: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('No se pudo extraer el texto del PDF')),
                        );
                      }
                    },
                  ),
                  // Ajuste de tamaño de letra
                  ListTile(
                    leading: const Icon(Icons.format_size),
                    title: const Text('Tamaño de letra'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            setModalState(() {
                              _fontSize = (_fontSize - 0.1).clamp(0.5, 2.0);
                              _pdfViewerController.zoomLevel = _fontSize;
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            setModalState(() {
                              _fontSize = (_fontSize + 0.1).clamp(0.5, 2.0);
                              _pdfViewerController.zoomLevel = _fontSize;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  // Cambiar fuente
                  ListTile(
                    leading: const Icon(Icons.font_download),
                    title: const Text('Cambiar fuente'),
                    trailing: DropdownButton<String>(
                      value: _currentFont,
                      items: <String>[
                        'Arial',
                        'Helvetica',
                        'Times New Roman',
                        'Courier'
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setModalState(() {
                            _currentFont = newValue;
                            // Aquí deberías implementar la lógica para cambiar la fuente del PDF
                          });
                        }
                      },
                    ),
                  ),
                  // Activar/desactivar alto contraste
                  SwitchListTile(
                    title: const Text('Alto contraste'),
                    value: _highContrast,
                    onChanged: (bool value) {
                      setModalState(() {
                        _highContrast = value;
                        // Aquí deberías implementar la lógica para activar/desactivar el alto contraste
                      });
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
