import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/ep_progress.dart';
import '../models/photo_archive_item.dart';
import '../models/scene_entry.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../theme/terminal_theme.dart';
import '../widgets/terminal_widgets.dart';

class PhaseThreeAdminScreen extends StatefulWidget {
  const PhaseThreeAdminScreen({super.key, required this.gateway});

  final PhaseThreeGateway? gateway;

  @override
  State<PhaseThreeAdminScreen> createState() => _PhaseThreeAdminScreenState();
}

class _PhaseThreeAdminScreenState extends State<PhaseThreeAdminScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final gateway = widget.gateway;
    if (gateway == null) {
      return const Center(
        child: Text(
          'FASE 3 // SERVICIO FIRESTORE NO DISPONIBLE',
          style: TextStyle(color: TerminalTheme.red),
        ),
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              for (var index = 0; index < 3; index++) ...[
                if (index > 0) const SizedBox(width: 5),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _tab = index),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _tab == index
                          ? Colors.black
                          : TerminalTheme.red,
                      backgroundColor: _tab == index
                          ? TerminalTheme.red
                          : Colors.black,
                      side: const BorderSide(color: TerminalTheme.red),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 3,
                        vertical: 8,
                      ),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                      textStyle: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 8,
                      ),
                    ),
                    child: Text(
                      [
                        '[ PROGRESO EP ]',
                        '[ ESCENA // RED ]',
                        '[ CARRETE ]',
                      ][index],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: _tab,
            children: [
              _EpProgressAdmin(gateway: gateway),
              _SceneDirectoryAdmin(gateway: gateway),
              _PhotoArchiveAdmin(gateway: gateway),
            ],
          ),
        ),
      ],
    );
  }
}

class _EpProgressAdmin extends StatefulWidget {
  const _EpProgressAdmin({required this.gateway});

  final PhaseThreeGateway gateway;

  @override
  State<_EpProgressAdmin> createState() => _EpProgressAdminState();
}

class _EpProgressAdminState extends State<_EpProgressAdmin> {
  final _formKey = GlobalKey<FormState>();
  final _project = TextEditingController();
  final _stage = TextEditingController();
  final _percentage = TextEditingController();
  final _note = TextEditingController();
  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _project.dispose();
    _stage.dispose();
    _percentage.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.gateway.saveEpProgress(
        EpProgress(
          projectName: _project.text.trim(),
          stage: _stage.text.trim(),
          percentage: int.parse(_percentage.text.trim()),
          statusNote: _note.text.trim(),
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PROGRESO DEL EP ACTUALIZADO.'),
            backgroundColor: Colors.black,
          ),
        );
      }
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('ERROR DE PROGRESO EP: $error')));
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<EpProgress>(
    stream: widget.gateway.watchEpProgress(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(
          child: Text(
            'ERROR AL LEER PROGRESO: ${snapshot.error}',
            style: const TextStyle(color: TerminalTheme.red),
          ),
        );
      }
      if (snapshot.hasData && !_loaded) {
        final value = snapshot.data!;
        _project.text = value.projectName;
        _stage.text = value.stage;
        _percentage.text = value.percentage.toString();
        _note.text = value.statusNote;
        _loaded = true;
      }
      return ListView(
        padding: const EdgeInsets.all(14),
        children: [
          const Text(
            '> [ PROGRESO DEL EP ]',
            style: TextStyle(color: TerminalTheme.red, fontSize: 11),
          ),
          const SizedBox(height: 10),
          TerminalPanel(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _TerminalField(controller: _project, label: 'PROYECTO'),
                  _TerminalField(controller: _stage, label: 'ETAPA'),
                  _TerminalField(
                    controller: _percentage,
                    label: 'PORCENTAJE (0-100)',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final number = int.tryParse(value?.trim() ?? '');
                      return number != null && number >= 0 && number <= 100
                          ? null
                          : 'Usa un entero entre 0 y 100.';
                    },
                  ),
                  _TerminalField(
                    controller: _note,
                    label: 'NOTA DE ESTADO',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 8),
                  _ActionButton(
                    label: _saving
                        ? '[ GUARDANDO... ]'
                        : '[ ACTUALIZAR EN VIVO ]',
                    onPressed: _saving ? null : _save,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _SceneDirectoryAdmin extends StatelessWidget {
  const _SceneDirectoryAdmin({required this.gateway});

  final PhaseThreeGateway gateway;

  Future<void> _edit(BuildContext context, [SceneEntry? entry]) async {
    final name = TextEditingController(text: entry?.name ?? '');
    final category = TextEditingController(text: entry?.category ?? 'BANDA');
    final city = TextEditingController(text: entry?.city ?? '');
    final description = TextEditingController(text: entry?.description ?? '');
    final url = TextEditingController(text: entry?.externalUrl ?? '');
    final formKey = GlobalKey<FormState>();
    try {
      final saved = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => _EditorDialog(
          title: entry == null ? '> NUEVA FICHA DE ESCENA' : '> EDITAR FICHA',
          formKey: formKey,
          children: [
            _TerminalField(controller: name, label: 'NOMBRE'),
            _TerminalField(controller: category, label: 'CATEGORÍA'),
            _TerminalField(controller: city, label: 'CIUDAD'),
            _TerminalField(
              controller: description,
              label: 'DESCRIPCIÓN',
              maxLines: 3,
            ),
            _TerminalField(
              controller: url,
              label: 'ENLACE EXTERNO',
              keyboardType: TextInputType.url,
              validator: _validateUrl,
            ),
          ],
        ),
      );
      if (saved != true || !context.mounted) return;
      await gateway.saveSceneEntry(
        SceneEntry(
          id: entry?.id ?? '',
          name: name.text.trim(),
          category: category.text.trim().toUpperCase(),
          city: city.text.trim(),
          description: description.text.trim(),
          externalUrl: url.text.trim(),
        ),
      );
    } catch (error) {
      if (context.mounted) _showError(context, error);
    } finally {
      name.dispose();
      category.dispose();
      city.dispose();
      description.dispose();
      url.dispose();
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<List<SceneEntry>>(
    stream: gateway.watchSceneDirectory(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(
          child: Text(
            'ERROR AL CARGAR DIRECTORIO: ${snapshot.error}',
            style: const TextStyle(color: TerminalTheme.red),
          ),
        );
      }
      if (!snapshot.hasData) {
        return const Center(
          child: CircularProgressIndicator(color: TerminalTheme.red),
        );
      }
      final entries = snapshot.data!;
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    '> DIRECTORIO ESCENA // RED',
                    style: TextStyle(color: TerminalTheme.red, fontSize: 10),
                  ),
                ),
                TextButton(
                  onPressed: () => _edit(context),
                  child: const Text(
                    '[ NUEVA FICHA ]',
                    style: TextStyle(color: TerminalTheme.red, fontSize: 9),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: entries.isEmpty
                ? const Center(child: Text('DIRECTORIO VACÍO.'))
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      for (final entry in entries)
                        TerminalPanel(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${entry.name} // ${entry.category} // ${entry.city}',
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ),
                              IconButton(
                                onPressed: () => _edit(context, entry),
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  color: TerminalTheme.red,
                                  size: 18,
                                ),
                              ),
                              IconButton(
                                onPressed: () => _delete(context, entry),
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: TerminalTheme.red,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      );
    },
  );

  Future<void> _delete(BuildContext context, SceneEntry entry) async {
    try {
      await gateway.deleteSceneEntry(entry.id);
    } catch (error) {
      if (context.mounted) _showError(context, error);
    }
  }
}

class _PhotoArchiveAdmin extends StatefulWidget {
  const _PhotoArchiveAdmin({required this.gateway});

  final PhaseThreeGateway gateway;

  @override
  State<_PhotoArchiveAdmin> createState() => _PhotoArchiveAdminState();
}

class _PhotoArchiveAdminState extends State<_PhotoArchiveAdmin> {
  final StorageService _storage = StorageService();
  bool _uploading = false;

  Future<void> _addPhoto() async {
    final PlatformFile file;
    final Uint8List bytes;
    try {
      final selected = await FilePicker.pickFile(
        type: FileType.image,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
      );
      if (selected == null) return;
      file = selected;
      bytes = await selected.readAsBytes();
    } catch (error) {
      if (mounted) _showError(context, error);
      return;
    }
    if (!mounted) return;
    if (bytes.isEmpty || bytes.length > 20 * 1024 * 1024) {
      _showError(
        context,
        const FormatException('La foto debe pesar entre 1 byte y 20 MB.'),
      );
      return;
    }
    final caption = TextEditingController();
    final date = ValueNotifier<DateTime?>(null);
    final formKey = GlobalKey<FormState>();
    try {
      final saved = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => _EditorDialog(
          title: '> PUBLICAR EN CARRETE',
          formKey: formKey,
          children: [
            TextFormField(
              controller: caption,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'PIE DE FOTO'),
              validator: (value) => value?.trim().isNotEmpty == true
                  ? null
                  : 'Agrega un pie de foto.',
            ),
            ValueListenableBuilder<DateTime?>(
              valueListenable: date,
              builder: (context, value, _) => Row(
                children: [
                  Expanded(
                    child: Text(
                      value == null
                          ? 'FECHA DEL EVENTO // OPCIONAL'
                          : value.toLocal().toString().split(' ').first,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final selected = await showDatePicker(
                        context: context,
                        initialDate: value ?? DateTime.now(),
                        firstDate: DateTime(1970),
                        lastDate: DateTime(2100),
                        builder: _terminalDatePicker,
                      );
                      if (selected != null) date.value = selected;
                    },
                    child: const Text(
                      '[ FECHA ]',
                      style: TextStyle(color: TerminalTheme.red),
                    ),
                  ),
                  if (value != null)
                    IconButton(
                      onPressed: () => date.value = null,
                      icon: const Icon(
                        Icons.close,
                        color: TerminalTheme.red,
                        size: 16,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
      if (saved != true || !mounted) return;
      setState(() => _uploading = true);
      final imageUrl = await _storage.pickAndUploadFile(
        folder: 'photo_archive',
        fileName: file.name,
        bytes: bytes,
      );
      await widget.gateway.savePhotoArchiveItem(
        PhotoArchiveItem(
          id: '',
          imageUrl: imageUrl,
          caption: caption.text.trim(),
          eventDate: date.value,
        ),
      );
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      caption.dispose();
      date.dispose();
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<List<PhotoArchiveItem>>(
    stream: widget.gateway.watchPhotoArchive(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(
          child: Text(
            'ERROR AL LEER CARRETE: ${snapshot.error}',
            style: const TextStyle(color: TerminalTheme.red),
          ),
        );
      }
      if (!snapshot.hasData) {
        return const Center(
          child: CircularProgressIndicator(color: TerminalTheme.red),
        );
      }
      final photos = snapshot.data!;
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    '> CARRETE // CONTACT SHEET',
                    style: TextStyle(color: TerminalTheme.red, fontSize: 10),
                  ),
                ),
                TextButton(
                  onPressed: _uploading ? null : _addPhoto,
                  child: Text(
                    _uploading ? '[ SUBIENDO... ]' : '[ SUBIR FOTO ]',
                    style: const TextStyle(
                      color: TerminalTheme.red,
                      fontSize: 9,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: photos.isEmpty
                ? const Center(child: Text('CARRETE VACÍO.'))
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      for (final photo in photos)
                        TerminalPanel(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  photo.caption,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ),
                              IconButton(
                                onPressed: () => _delete(photo),
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: TerminalTheme.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      );
    },
  );

  Future<void> _delete(PhotoArchiveItem item) async {
    try {
      await widget.gateway.deletePhotoArchiveItem(item.id);
    } catch (error) {
      if (mounted) _showError(context, error);
    }
  }
}

class _TerminalField extends StatelessWidget {
  const _TerminalField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    maxLines: maxLines,
    decoration: InputDecoration(labelText: label),
    validator:
        validator ??
        (value) => value?.trim().isNotEmpty == true
            ? null
            : 'Este campo es obligatorio.',
  );
}

class _EditorDialog extends StatelessWidget {
  const _EditorDialog({
    required this.title,
    required this.formKey,
    required this.children,
  });

  final String title;
  final GlobalKey<FormState> formKey;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: Colors.black,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    title: Text(
      title,
      style: const TextStyle(color: TerminalTheme.red, fontSize: 12),
    ),
    content: SizedBox(
      width: 420,
      child: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final child in children) ...[
                child,
                const SizedBox(height: 9),
              ],
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: const Text('CANCELAR', style: TextStyle(color: Colors.white70)),
      ),
      TextButton(
        onPressed: () {
          if (formKey.currentState!.validate()) {
            Navigator.pop(context, true);
          }
        },
        child: const Text(
          'CONTINUAR',
          style: TextStyle(color: TerminalTheme.red),
        ),
      ),
    ],
  );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: TerminalTheme.red,
        side: const BorderSide(color: TerminalTheme.red),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
      child: Text(label),
    ),
  );
}

String? _validateUrl(String? value) {
  final uri = Uri.tryParse(value?.trim() ?? '');
  return uri != null &&
          uri.hasAuthority &&
          {'http', 'https'}.contains(uri.scheme)
      ? null
      : 'Ingresa una URL http o https válida.';
}

Widget _terminalDatePicker(BuildContext context, Widget? child) => Theme(
  data: ThemeData.dark().copyWith(
    colorScheme: const ColorScheme.dark(
      primary: TerminalTheme.red,
      surface: Colors.black,
    ),
  ),
  child: child!,
);

void _showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('ERROR EN CONSOLA FASE 3: $error'),
      backgroundColor: TerminalTheme.red,
    ),
  );
}
