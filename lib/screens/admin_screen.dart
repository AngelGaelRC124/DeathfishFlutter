import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/contact_message.dart';
import '../models/feed_item.dart';
import '../models/merch_item.dart';
import '../models/track.dart';
import '../models/user_session.dart';
import '../services/data_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../theme/terminal_theme.dart';
import '../widgets/terminal_widgets.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({
    super.key,
    required this.dataService,
    required this.firestoreService,
    required this.session,
  });

  final DataService dataService;
  final FirestoreGateway firestoreService;
  final UserSession session;

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  DataService get data => widget.dataService;
  FirestoreGateway get firestore => widget.firestoreService;
  final StorageService _storageService = StorageService();

  void _reportError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('NO SE PUDO GUARDAR EL CAMBIO: $error'),
        backgroundColor: Colors.black87,
      ),
    );
  }

  Future<bool?> _showEditor(
    String title,
    GlobalKey<FormState> formKey,
    List<Widget> fields, {
    Future<void> Function()? onSave,
  }) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    var isSaving = false;
    final route = DialogRoute<bool>(
      context: context,
      themes: InheritedTheme.capture(from: context, to: navigator.context),
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => PopScope(
          canPop: !isSaving,
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(18),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 480,
                maxHeight: MediaQuery.of(dialogContext).size.height * 0.88,
              ),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(
                    color: TerminalTheme.red.withValues(alpha: 0.5),
                  ),
                  borderRadius: BorderRadius.zero,
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: TerminalTheme.red,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              for (
                                var index = 0;
                                index < fields.length;
                                index++
                              )
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: fields[index],
                                ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: isSaving
                                  ? null
                                  : () => Navigator.pop(dialogContext, false),
                              child: const Text(
                                'CANCELAR',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextButton(
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                      if (!formKey.currentState!.validate()) {
                                        return;
                                      }
                                      if (onSave == null) {
                                        Navigator.pop(dialogContext, true);
                                        return;
                                      }
                                      setDialogState(() => isSaving = true);
                                      try {
                                        await onSave();
                                        if (dialogContext.mounted) {
                                          Navigator.pop(dialogContext, true);
                                        }
                                      } catch (error) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                            ..hideCurrentSnackBar()
                                            ..showSnackBar(
                                              SnackBar(
                                                content: Text(error.toString()),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                        }
                                      } finally {
                                        if (dialogContext.mounted) {
                                          setDialogState(
                                            () => isSaving = false,
                                          );
                                        }
                                      }
                                    },
                              child: isSaving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: TerminalTheme.red,
                                      ),
                                    )
                                  : const Text(
                                      'GUARDAR',
                                      style: TextStyle(
                                        color: TerminalTheme.red,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final result = await navigator.push(route);
    await route.completed;
    return result;
  }

  TextFormField _field(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label),
      validator:
          validator ??
          (value) => value?.trim().isNotEmpty == true
              ? null
              : 'Este campo es obligatorio.',
    );
  }

  Future<void> _removeStoredMedia(String? mediaId) async {
    if (mediaId == null) return;
    try {
      await data.deleteMedia(mediaId);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'REGISTRO GUARDADO; NO SE PUDO BORRAR UN ARCHIVO: $error',
            ),
          ),
        );
      }
    }
  }

  Future<void> _editFeedItem([FeedItem? item]) async {
    final formKey = GlobalKey<FormState>();
    final date = TextEditingController(text: item?.date ?? '');
    final title = TextEditingController(text: item?.title ?? '');
    final location = TextEditingController(text: item?.location ?? '');
    final description = TextEditingController(text: item?.description ?? '');
    final tag = TextEditingController(text: item?.tag ?? 'COMUNICADO');
    final saved = await _showEditor(
      item == null ? '> NUEVO COMUNICADO' : '> EDITAR COMUNICADO',
      formKey,
      [
        _field(date, 'FECHA (AAAA-MM-DD)'),
        _field(title, 'TÍTULO'),
        _field(location, 'UBICACIÓN'),
        _field(tag, 'ETIQUETA'),
        _field(description, 'DESCRIPCIÓN', maxLines: 4),
      ],
    );
    if (saved == true && mounted) {
      try {
        await firestore.saveFeedItem(
          FeedItem(
            id: item?.id ?? 'post_${DateTime.now().microsecondsSinceEpoch}',
            date: date.text.trim(),
            title: title.text.trim(),
            location: location.text.trim(),
            description: description.text.trim(),
            tag: tag.text.trim(),
            attendeeIds: item?.attendeeIds ?? const [],
          ),
        );
        setState(() {});
      } catch (error) {
        _reportError(error);
      }
    }
    date.dispose();
    title.dispose();
    location.dispose();
    description.dispose();
    tag.dispose();
  }

  Future<void> _editTrack([Track? track]) async {
    final formKey = GlobalKey<FormState>();
    final number = TextEditingController(text: track?.number ?? '');
    final title = TextEditingController(text: track?.title ?? '');
    final album = TextEditingController(text: track?.album ?? '');
    final duration = TextEditingController(text: track?.duration ?? '');
    final url = TextEditingController(text: track?.youtubeUrl ?? '');
    final lyrics = TextEditingController(text: track?.lyrics ?? '');
    _PickedMedia? selectedAudio;
    _PickedMedia? selectedVideo;
    _PickedMedia? selectedArt;
    var removeAudio = false;
    var removeVideo = false;
    var removeArt = false;
    final soloFans = ValueNotifier<bool>(track?.soloFans ?? false);
    String? uploadedAudioUrl;
    String? uploadedVideoUrl;
    String? uploadedArtUrl;
    final saved = await _showEditor(
      track == null ? '> NUEVA CANCIÓN / VIDEO' : '> EDITAR CANCIÓN / VIDEO',
      formKey,
      [
        _field(number, 'NÚMERO DE CANCIÓN'),
        _field(title, 'TÍTULO'),
        _field(album, 'ÁLBUM / LANZAMIENTO'),
        _field(duration, 'DURACIÓN'),
        _field(
          url,
          'URL DE YOUTUBE',
          keyboardType: TextInputType.url,
          validator: (value) {
            final enteredUrl = value?.trim() ?? '';
            if (enteredUrl.isEmpty &&
                (selectedAudio != null ||
                    selectedVideo != null ||
                    (!removeAudio &&
                        (track?.audioMediaId != null ||
                            track?.audioUrl != null)) ||
                    (!removeVideo && track?.videoUrl != null))) {
              return null;
            }
            final uri = Uri.tryParse(enteredUrl);
            return uri != null &&
                    uri.hasAuthority &&
                    {'http', 'https'}.contains(uri.scheme)
                ? null
                : 'Ingresa una URL http o https válida.';
          },
        ),
        _field(lyrics, 'LETRA', maxLines: 6),
        _AdminMediaPicker(
          title: 'ARCHIVO DE AUDIO (MP3 / WAV)',
          type: FileType.custom,
          allowedExtensions: const ['mp3', 'wav'],
          initialName:
              track?.audioName ??
              (track?.audioUrl == null ? null : 'AUDIO REMOTO'),
          onPicked: (file) {
            selectedAudio = file;
            uploadedAudioUrl = null;
            removeAudio = false;
          },
          onRemove: track?.audioMediaId == null && track?.audioUrl == null
              ? null
              : () {
                  selectedAudio = null;
                  removeAudio = true;
                },
        ),
        _AdminMediaPicker(
          title: 'VIDEO MP4',
          type: FileType.custom,
          allowedExtensions: const ['mp4'],
          initialName:
              track?.videoName ??
              (track?.videoUrl == null ? null : 'VIDEO REMOTO'),
          onPicked: (file) {
            selectedVideo = file;
            uploadedVideoUrl = null;
            removeVideo = false;
          },
          onRemove: track?.videoUrl == null
              ? null
              : () {
                  selectedVideo = null;
                  removeVideo = true;
                },
        ),
        ValueListenableBuilder<bool>(
          valueListenable: soloFans,
          builder: (context, value, _) => SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'SOLO FANS REGISTRADOS',
              style: TextStyle(color: Colors.white, fontSize: 11),
            ),
            subtitle: const Text(
              'Restringe la reproducción a cuentas fan.',
              style: TextStyle(color: Colors.white54, fontSize: 9),
            ),
            value: value,
            activeTrackColor: TerminalTheme.red,
            onChanged: (enabled) => soloFans.value = enabled,
          ),
        ),
        _AdminMediaPicker(
          title: 'ARTE CONCEPTUAL / ZINE',
          type: FileType.image,
          initialName: track?.artUrl == null ? null : 'ARTE REMOTO',
          onPicked: (file) {
            selectedArt = file;
            uploadedArtUrl = null;
            removeArt = false;
          },
          onRemove: track?.artUrl == null
              ? null
              : () {
                  selectedArt = null;
                  removeArt = true;
                },
        ),
      ],
      onSave: () async {
        final trackId =
            track?.id ?? 'trk_${DateTime.now().microsecondsSinceEpoch}';
        if (selectedAudio != null) {
          uploadedAudioUrl ??= await _storageService.pickAndUploadFile(
            folder: 'tracks/$trackId/audio',
            fileName: selectedAudio!.name,
            bytes: selectedAudio!.bytes,
          );
        }
        if (selectedVideo != null) {
          uploadedVideoUrl ??= await _storageService.pickAndUploadFile(
            folder: 'tracks/$trackId/video',
            fileName: selectedVideo!.name,
            bytes: selectedVideo!.bytes,
          );
        }
        if (selectedArt != null) {
          uploadedArtUrl ??= await _storageService.pickAndUploadFile(
            folder: 'tracks/$trackId/art',
            fileName: selectedArt!.name,
            bytes: selectedArt!.bytes,
          );
        }
        final audioName =
            selectedAudio?.name ?? (removeAudio ? null : track?.audioName);
        final audioMimeType = selectedAudio != null
            ? _audioMimeType(selectedAudio!.name)
            : removeAudio
            ? null
            : track?.audioMimeType;
        final videoName =
            selectedVideo?.name ?? (removeVideo ? null : track?.videoName);
        await firestore.saveTrack(
          Track(
            id: trackId,
            number: number.text.trim(),
            title: title.text.trim(),
            album: album.text.trim(),
            duration: duration.text.trim(),
            lyrics: lyrics.text.trim(),
            youtubeUrl: url.text.trim(),
            audioMediaId: selectedAudio != null || removeAudio
                ? null
                : track?.audioMediaId,
            audioName: audioName,
            audioMimeType: audioMimeType,
            audioUrl: selectedAudio != null
                ? uploadedAudioUrl
                : removeAudio
                ? null
                : track?.audioUrl,
            videoUrl: selectedVideo != null
                ? uploadedVideoUrl
                : removeVideo
                ? null
                : track?.videoUrl,
            videoName: videoName,
            soloFans: soloFans.value,
            artUrl: selectedArt != null
                ? uploadedArtUrl
                : removeArt
                ? null
                : track?.artUrl,
          ),
        );
        if (selectedAudio != null || removeAudio) {
          await _removeStoredMedia(track?.audioMediaId);
        }
      },
    );
    if (saved == true && mounted) setState(() {});
    number.dispose();
    title.dispose();
    album.dispose();
    duration.dispose();
    url.dispose();
    lyrics.dispose();
    soloFans.dispose();
  }

  Future<void> _editMerch([MerchItem? item]) async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController(text: item?.name ?? '');
    final category = TextEditingController(text: item?.category ?? '');
    final price = TextEditingController(
      text: item == null ? '' : item.price.toString(),
    );
    final sizes = TextEditingController(text: item?.sizes.join(', ') ?? '');
    final stock = TextEditingController(
      text: item == null ? '' : item.stock.toString(),
    );
    final description = TextEditingController(text: item?.description ?? '');
    _PickedMedia? selectedImage;
    final saved = await _showEditor(
      item == null ? '> NUEVO PRODUCTO' : '> EDITAR PRODUCTO',
      formKey,
      [
        _field(name, 'NOMBRE DEL PRODUCTO'),
        _field(category, 'CATEGORÍA'),
        _field(
          price,
          'PRECIO (MXN)',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            final parsed = double.tryParse(value?.trim() ?? '');
            return parsed != null && parsed >= 0
                ? null
                : 'Ingresa un precio válido.';
          },
        ),
        _field(sizes, 'TALLAS (SEPARADAS POR COMAS)'),
        _field(
          stock,
          'STOCK',
          keyboardType: TextInputType.number,
          validator: (value) {
            final parsed = int.tryParse(value?.trim() ?? '');
            return parsed != null && parsed >= 0
                ? null
                : 'Ingresa un stock válido.';
          },
        ),
        _AdminMediaPicker(
          title: 'IMAGEN DEL PRODUCTO',
          type: FileType.image,
          initialName:
              item?.imageName ??
              (item?.imageUrl == null ? null : 'IMAGEN REMOTA'),
          requiredForNewItem: item == null,
          onPicked: (file) => selectedImage = file,
        ),
        _field(description, 'DESCRIPCIÓN', maxLines: 4),
      ],
    );
    if (saved == true && mounted) {
      try {
        final parsedSizes = sizes.text
            .split(',')
            .map((size) => size.trim().toUpperCase())
            .where((size) => size.isNotEmpty)
            .toSet()
            .toList();
        final itemId =
            item?.id ?? 'mrc_${DateTime.now().microsecondsSinceEpoch}';
        final imageUrl = selectedImage == null
            ? item?.imageUrl
            : await _storageService.pickAndUploadFile(
                folder: 'merch/$itemId/images',
                fileName: selectedImage!.name,
                bytes: selectedImage!.bytes,
              );
        await firestore.saveMerchItem(
          MerchItem(
            id: itemId,
            name: name.text.trim(),
            category: category.text.trim(),
            price: double.parse(price.text.trim()),
            sizes: parsedSizes,
            stock: int.parse(stock.text.trim()),
            image: item?.image ?? selectedImage?.name ?? '',
            description: description.text.trim(),
            imageMediaId: selectedImage == null ? item?.imageMediaId : null,
            imageName: selectedImage?.name ?? item?.imageName,
            imageUrl: imageUrl,
          ),
        );
        setState(() {});
      } catch (error) {
        _reportError(error);
      }
    }
    name.dispose();
    category.dispose();
    price.dispose();
    sizes.dispose();
    stock.dispose();
    description.dispose();
  }

  String _audioMimeType(String fileName) {
    return fileName.toLowerCase().endsWith('.mp3') ? 'audio/mpeg' : 'audio/wav';
  }

  Future<void> _delete(
    String type,
    String title,
    Future<void> Function() action, {
    String? mediaId,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.black,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(
          'ELIMINAR $type',
          style: const TextStyle(color: TerminalTheme.red),
        ),
        content: Text('¿Eliminar "$title"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'ELIMINAR',
              style: TextStyle(color: TerminalTheme.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await action();
      await _removeStoredMedia(mediaId);
      if (mounted) setState(() {});
    } catch (error) {
      _reportError(error);
    }
  }

  Widget _messageInbox() => StreamBuilder<List<ContactMessage>>(
    stream: firestore.watchMessages(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(
          child: Text(
            'ERROR AL CARGAR MENSAJES: ${snapshot.error}',
            style: const TextStyle(color: TerminalTheme.red),
            textAlign: TextAlign.center,
          ),
        );
      }
      if (!snapshot.hasData) {
        return const Center(
          child: CircularProgressIndicator(color: TerminalTheme.red),
        );
      }
      final messages = snapshot.data!;
      if (messages.isEmpty) {
        return const Center(
          child: Text(
            'BANDEJA DE ENTRADA VACÍA.',
            style: TextStyle(color: Colors.white70),
          ),
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.all(14),
        itemCount: messages.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final message = messages[index];
          return TerminalPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        message.subject,
                        style: const TextStyle(
                          color: TerminalTheme.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      message.status.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${message.sender} // ${message.email}',
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
                if (message.createdAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    message.createdAt!.toLocal().toString(),
                    style: const TextStyle(color: Colors.white54, fontSize: 9),
                  ),
                ],
                const Divider(height: 18),
                SelectableText(
                  message.body,
                  style: const TextStyle(color: Colors.white, height: 1.4),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: message.status == 'leído'
                          ? null
                          : () async {
                              try {
                                await firestore.updateMessageStatus(
                                  message.id,
                                  'leído',
                                );
                              } catch (error) {
                                _reportError(error);
                              }
                            },
                      icon: const Icon(
                        Icons.mark_email_read_outlined,
                        size: 17,
                      ),
                      label: const Text('MARCAR LEÍDO'),
                      style: TextButton.styleFrom(
                        foregroundColor: TerminalTheme.red,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Eliminar mensaje',
                      onPressed: () => _delete(
                        'MENSAJE',
                        message.subject,
                        () => firestore.deleteMessage(message.id),
                      ),
                      icon: const Icon(
                        Icons.delete_outline,
                        color: TerminalTheme.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );

  Widget _streamSection<T>({
    required Stream<List<T>> stream,
    required String title,
    required String addLabel,
    required _AdminEntry Function(T) toEntry,
    required String Function(T) itemTitle,
    required String? Function(T) mediaId,
    required Future<void> Function(T) onDelete,
    required void Function(T) onEdit,
    required VoidCallback onAdd,
    required String deleteType,
  }) {
    return StreamBuilder<List<T>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'ERROR AL CARGAR $title: ${snapshot.error}',
              style: const TextStyle(color: TerminalTheme.red),
              textAlign: TextAlign.center,
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: TerminalTheme.red),
          );
        }
        final items = snapshot.data!;
        return _AdminSection(
          title: title,
          addLabel: addLabel,
          entries: items.map(toEntry).toList(),
          onAdd: onAdd,
          onEdit: (index) => onEdit(items[index]),
          onDelete: (index) => _delete(
            deleteType,
            itemTitle(items[index]),
            () => onDelete(items[index]),
            mediaId: mediaId(items[index]),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.session.isAdmin) {
      return const TerminalMessageScreen(
        message: 'ACCESO ADMINISTRADOR REQUERIDO',
      );
    }
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          const TabBar(
            isScrollable: true,
            labelColor: TerminalTheme.red,
            unselectedLabelColor: Colors.white70,
            indicatorColor: TerminalTheme.red,
            tabs: [
              Tab(text: 'TABLÓN'),
              Tab(text: 'CANCIONES / VIDEOS'),
              Tab(text: 'MERCH'),
              Tab(text: 'BANDEJA DE ENTRADA'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _streamSection(
                  stream: firestore.watchFeed(),
                  title: 'COMUNICADOS DEL TABLÓN',
                  addLabel: 'NUEVO COMUNICADO',
                  toEntry: (item) => _AdminEntry(
                    title: item.title,
                    subtitle: '${item.date} // ${item.location}',
                  ),
                  itemTitle: (item) => item.title,
                  mediaId: (_) => null,
                  onDelete: (item) => firestore.deleteFeedItem(item.id),
                  onEdit: _editFeedItem,
                  onAdd: () => _editFeedItem(),
                  deleteType: 'COMUNICADO',
                ),
                _streamSection(
                  stream: firestore.watchTracks(),
                  title: 'CANCIONES Y ENLACES DE VIDEO',
                  addLabel: 'NUEVA CANCIÓN / VIDEO',
                  toEntry: (item) => _AdminEntry(
                    title: item.title,
                    subtitle: '${item.album} // ${item.youtubeUrl}',
                  ),
                  itemTitle: (item) => item.title,
                  mediaId: (item) => item.audioMediaId,
                  onDelete: (item) => firestore.deleteTrack(item.id),
                  onEdit: _editTrack,
                  onAdd: () => _editTrack(),
                  deleteType: 'CANCIÓN',
                ),
                _streamSection(
                  stream: firestore.watchMerch(),
                  title: 'PRODUCTOS DE MERCH',
                  addLabel: 'NUEVO PRODUCTO',
                  toEntry: (item) => _AdminEntry(
                    title: item.name,
                    subtitle:
                        '\$${item.price.toStringAsFixed(2)} // STOCK ${item.stock}',
                  ),
                  itemTitle: (item) => item.name,
                  mediaId: (item) => item.imageMediaId,
                  onDelete: (item) => firestore.deleteMerchItem(item.id),
                  onEdit: _editMerch,
                  onAdd: () => _editMerch(),
                  deleteType: 'PRODUCTO',
                ),
                _messageInbox(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminEntry {
  const _AdminEntry({required this.title, required this.subtitle});

  final String title;
  final String subtitle;
}

class _PickedMedia {
  const _PickedMedia({
    required this.name,
    required this.extension,
    required this.bytes,
  });

  final String name;
  final String extension;
  final Uint8List bytes;
}

class _AdminMediaPicker extends StatefulWidget {
  const _AdminMediaPicker({
    required this.title,
    required this.type,
    required this.onPicked,
    this.allowedExtensions,
    this.initialName,
    this.requiredForNewItem = false,
    this.onRemove,
  });

  final String title;
  final FileType type;
  final List<String>? allowedExtensions;
  final String? initialName;
  final bool requiredForNewItem;
  final ValueChanged<_PickedMedia> onPicked;
  final VoidCallback? onRemove;

  @override
  State<_AdminMediaPicker> createState() => _AdminMediaPickerState();
}

class _AdminMediaPickerState extends State<_AdminMediaPicker> {
  static const _maxFileBytes = 100 * 1024 * 1024;
  _PickedMedia? _selectedMedia;
  String? _error;
  bool _isPicking = false;
  bool _removed = false;

  Future<void> _pickFile(FormFieldState<_PickedMedia> field) async {
    setState(() {
      _isPicking = true;
      _error = null;
    });
    try {
      final file = await FilePicker.pickFile(
        type: widget.type,
        allowedExtensions: widget.allowedExtensions,
      );
      if (file == null) return;
      final fileSize = await file.length();
      if (fileSize != null && fileSize > _maxFileBytes) {
        throw const FormatException('El archivo no puede superar 100 MB.');
      }
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        throw const FormatException('El archivo seleccionado está vacío.');
      }
      if (bytes.length > _maxFileBytes) {
        throw const FormatException('El archivo no puede superar 100 MB.');
      }
      final extension = file.extension?.toLowerCase() ?? '';
      if (widget.allowedExtensions != null &&
          !widget.allowedExtensions!.contains(extension)) {
        throw const FormatException('Selecciona un archivo MP3 o WAV.');
      }
      final selected = _PickedMedia(
        name: file.name,
        extension: extension,
        bytes: bytes,
      );
      if (!mounted) return;
      setState(() {
        _selectedMedia = selected;
        _removed = false;
      });
      widget.onPicked(selected);
      field.didChange(selected);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormField<_PickedMedia>(
      validator: (_) =>
          widget.requiredForNewItem &&
              _selectedMedia == null &&
              widget.initialName == null
          ? 'Selecciona una imagen desde tu dispositivo.'
          : null,
      builder: (field) {
        final displayedName =
            _selectedMedia?.name ?? (_removed ? null : widget.initialName);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.title,
              style: const TextStyle(color: TerminalTheme.red, fontSize: 11),
            ),
            const SizedBox(height: 7),
            OutlinedButton.icon(
              onPressed: _isPicking ? null : () => _pickFile(field),
              icon: _isPicking
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: TerminalTheme.red,
                      ),
                    )
                  : const Icon(Icons.folder_open, size: 17),
              label: Text(_isPicking ? 'LEYENDO ARCHIVO...' : 'ELEGIR ARCHIVO'),
              style: OutlinedButton.styleFrom(
                foregroundColor: TerminalTheme.red,
                side: BorderSide(
                  color: TerminalTheme.red.withValues(alpha: 0.4),
                ),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
            ),
            if (displayedName != null) ...[
              const SizedBox(height: 5),
              Text(
                'SELECCIONADO: $displayedName',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 10),
              ),
            ],
            if (_error != null || field.errorText != null) ...[
              const SizedBox(height: 5),
              Text(
                _error ?? field.errorText!,
                style: const TextStyle(color: TerminalTheme.red, fontSize: 10),
              ),
            ],
            if (widget.onRemove != null && displayedName != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedMedia = null;
                      _removed = true;
                    });
                    widget.onRemove!();
                    field.didChange(null);
                  },
                  child: const Text(
                    'QUITAR ARCHIVO',
                    style: TextStyle(color: TerminalTheme.red, fontSize: 10),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _AdminSection extends StatelessWidget {
  const _AdminSection({
    required this.title,
    required this.addLabel,
    required this.entries,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final String title;
  final String addLabel;
  final List<_AdminEntry> entries;
  final VoidCallback onAdd;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '> $title',
                  style: const TextStyle(
                    color: TerminalTheme.red,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 15),
                label: Text(addLabel, style: const TextStyle(fontSize: 9)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: TerminalTheme.red,
                  side: BorderSide(
                    color: TerminalTheme.red.withValues(alpha: 0.4),
                  ),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: entries.isEmpty
              ? const Center(
                  child: Text(
                    'SIN REGISTROS. USA EL BOTÓN + PARA AGREGAR.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return TerminalPanel(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  entry.subtitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Editar',
                            onPressed: () => onEdit(index),
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: TerminalTheme.red,
                              size: 18,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Eliminar',
                            onPressed: () => onDelete(index),
                            icon: const Icon(
                              Icons.delete_outline,
                              color: TerminalTheme.red,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
