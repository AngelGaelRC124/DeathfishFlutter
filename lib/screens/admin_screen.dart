import 'package:flutter/material.dart';

import '../models/feed_item.dart';
import '../models/merch_item.dart';
import '../models/track.dart';
import '../services/data_service.dart';
import '../theme/terminal_theme.dart';
import '../widgets/terminal_widgets.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key, required this.dataService});

  final DataService dataService;

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  DataService get data => widget.dataService;

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
    List<Widget> fields,
  ) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    final route = DialogRoute<bool>(
      context: context,
      themes: InheritedTheme.capture(from: context, to: navigator.context),
      builder: (dialogContext) => Dialog(
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
                          for (var index = 0; index < fields.length; index++)
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
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text(
                            'CANCELAR',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              Navigator.pop(dialogContext, true);
                            }
                          },
                          child: const Text(
                            'GUARDAR',
                            style: TextStyle(color: TerminalTheme.red),
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
        await data.saveFeedItem(
          FeedItem(
            id: item?.id ?? 'post_${DateTime.now().microsecondsSinceEpoch}',
            date: date.text.trim(),
            title: title.text.trim(),
            location: location.text.trim(),
            description: description.text.trim(),
            tag: tag.text.trim(),
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
            final uri = Uri.tryParse(value?.trim() ?? '');
            return uri != null &&
                    uri.hasAuthority &&
                    {'http', 'https'}.contains(uri.scheme)
                ? null
                : 'Ingresa una URL http o https válida.';
          },
        ),
        _field(lyrics, 'LETRA', maxLines: 6),
      ],
    );
    if (saved == true && mounted) {
      try {
        await data.saveTrack(
          Track(
            id: track?.id ?? 'trk_${DateTime.now().microsecondsSinceEpoch}',
            number: number.text.trim(),
            title: title.text.trim(),
            album: album.text.trim(),
            duration: duration.text.trim(),
            lyrics: lyrics.text.trim(),
            youtubeUrl: url.text.trim(),
          ),
        );
        setState(() {});
      } catch (error) {
        _reportError(error);
      }
    }
    number.dispose();
    title.dispose();
    album.dispose();
    duration.dispose();
    url.dispose();
    lyrics.dispose();
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
    final image = TextEditingController(text: item?.image ?? '');
    final description = TextEditingController(text: item?.description ?? '');
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
        _field(image, 'RUTA DE IMAGEN (ASSETS/...)'),
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
        await data.saveMerchItem(
          MerchItem(
            id: item?.id ?? 'mrc_${DateTime.now().microsecondsSinceEpoch}',
            name: name.text.trim(),
            category: category.text.trim(),
            price: double.parse(price.text.trim()),
            sizes: parsedSizes,
            stock: int.parse(stock.text.trim()),
            image: image.text.trim(),
            description: description.text.trim(),
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
    image.dispose();
    description.dispose();
  }

  Future<void> _delete(
    String type,
    String title,
    Future<void> Function() action,
  ) async {
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
      if (mounted) setState(() {});
    } catch (error) {
      _reportError(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            labelColor: TerminalTheme.red,
            unselectedLabelColor: Colors.white70,
            indicatorColor: TerminalTheme.red,
            tabs: [
              Tab(text: 'TABLÓN'),
              Tab(text: 'CANCIONES / VIDEOS'),
              Tab(text: 'MERCH'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _AdminSection(
                  title: 'COMUNICADOS DEL TABLÓN',
                  addLabel: 'NUEVO COMUNICADO',
                  entries: data.feed
                      .map(
                        (item) => _AdminEntry(
                          title: item.title,
                          subtitle: '${item.date} // ${item.location}',
                        ),
                      )
                      .toList(),
                  onAdd: () => _editFeedItem(),
                  onEdit: (index) => _editFeedItem(data.feed[index]),
                  onDelete: (index) => _delete(
                    'COMUNICADO',
                    data.feed[index].title,
                    () => data.deleteFeedItem(data.feed[index].id),
                  ),
                ),
                _AdminSection(
                  title: 'CANCIONES Y ENLACES DE VIDEO',
                  addLabel: 'NUEVA CANCIÓN / VIDEO',
                  entries: data.tracks
                      .map(
                        (item) => _AdminEntry(
                          title: item.title,
                          subtitle: '${item.album} // ${item.youtubeUrl}',
                        ),
                      )
                      .toList(),
                  onAdd: () => _editTrack(),
                  onEdit: (index) => _editTrack(data.tracks[index]),
                  onDelete: (index) => _delete(
                    'CANCIÓN',
                    data.tracks[index].title,
                    () => data.deleteTrack(data.tracks[index].id),
                  ),
                ),
                _AdminSection(
                  title: 'PRODUCTOS DE MERCH',
                  addLabel: 'NUEVO PRODUCTO',
                  entries: data.merch
                      .map(
                        (item) => _AdminEntry(
                          title: item.name,
                          subtitle:
                              '\$${item.price.toStringAsFixed(2)} // STOCK ${item.stock}',
                        ),
                      )
                      .toList(),
                  onAdd: () => _editMerch(),
                  onEdit: (index) => _editMerch(data.merch[index]),
                  onDelete: (index) => _delete(
                    'PRODUCTO',
                    data.merch[index].name,
                    () => data.deleteMerchItem(data.merch[index].id),
                  ),
                ),
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
