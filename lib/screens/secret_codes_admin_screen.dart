import 'package:flutter/material.dart';

import '../models/secret_code.dart';
import '../services/firestore_service.dart';
import '../theme/terminal_theme.dart';
import '../widgets/terminal_widgets.dart';

class SecretCodesAdminScreen extends StatelessWidget {
  const SecretCodesAdminScreen({super.key, required this.gateway});

  final PhaseTwoGateway? gateway;

  Future<void> _edit(BuildContext context, {SecretCode? code}) async {
    final service = gateway;
    if (service == null) return;
    final formKey = GlobalKey<FormState>();
    final codeController = TextEditingController(text: code?.code ?? '');
    final titleController = TextEditingController(
      text: code?.rewardTitle ?? '',
    );
    final descriptionController = TextEditingController(
      text: code?.rewardDescription ?? '',
    );
    final urlController = TextEditingController(text: code?.secretUrl ?? '');
    var active = code?.active ?? true;
    var saving = false;
    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            backgroundColor: Colors.black,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
            title: Text(
              code == null ? '> NUEVO CÓDIGO SECRETO' : '> EDITAR CÓDIGO',
              style: const TextStyle(
                color: TerminalTheme.red,
                fontSize: 13,
                fontFamily: 'monospace',
              ),
            ),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: codeController,
                        enabled: code == null,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'CÓDIGO // EJ. PECERA2026',
                        ),
                        validator: (value) => RegExp(
                              r'^[A-Z0-9_-]{3,40}$',
                            ).hasMatch(value?.trim().toUpperCase() ?? '')
                            ? null
                            : 'Usa 3-40 caracteres A-Z, 0-9, guion o guion bajo.',
                        onChanged: code == null
                            ? (value) {
                                final uppercase = value.toUpperCase();
                                if (value != uppercase) {
                                  codeController.value = TextEditingValue(
                                    text: uppercase,
                                    selection: TextSelection.collapsed(
                                      offset: uppercase.length,
                                    ),
                                  );
                                }
                              }
                            : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'TÍTULO DE LA RECOMPENSA',
                        ),
                        validator: _requiredValidator,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: descriptionController,
                        minLines: 2,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'DESCRIPCIÓN',
                        ),
                        validator: _requiredValidator,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: urlController,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(
                          labelText: 'URL SECRETA (OPCIONAL)',
                        ),
                        validator: _urlValidator,
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'CÓDIGO ACTIVO',
                          style: TextStyle(fontSize: 11),
                        ),
                        value: active,
                        activeTrackColor: TerminalTheme.red,
                        onChanged: (value) =>
                            setDialogState(() => active = value),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving
                    ? null
                    : () => Navigator.pop(dialogContext),
                child: const Text('CANCELAR'),
              ),
              TextButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() => saving = true);
                        try {
                          await service.saveSecretCode(
                            SecretCode(
                              code: codeController.text.trim().toUpperCase(),
                              rewardTitle: titleController.text.trim(),
                              rewardDescription:
                                  descriptionController.text.trim(),
                              secretUrl: urlController.text.trim().isEmpty
                                  ? null
                                  : urlController.text.trim(),
                              active: active,
                            ),
                          );
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                        } catch (error) {
                          if (dialogContext.mounted) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                content: Text('NO SE PUDO GUARDAR EL CÓDIGO: $error'),
                                backgroundColor: TerminalTheme.red,
                              ),
                            );
                          }
                        } finally {
                          if (dialogContext.mounted) {
                            setDialogState(() => saving = false);
                          }
                        }
                      },
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: TerminalTheme.red,
                        ),
                      )
                    : const Text(
                        '[ GUARDAR ]',
                        style: TextStyle(color: TerminalTheme.red),
                      ),
              ),
            ],
          ),
        ),
      );
    } finally {
      codeController.dispose();
      titleController.dispose();
      descriptionController.dispose();
      urlController.dispose();
    }
  }

  static String? _requiredValidator(String? value) =>
      value?.trim().isNotEmpty == true ? null : 'Campo obligatorio.';

  static String? _urlValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final uri = Uri.tryParse(text);
    return uri != null &&
            uri.hasAuthority &&
            const {'http', 'https'}.contains(uri.scheme)
        ? null
        : 'Ingresa una URL http o https válida.';
  }

  Future<void> _delete(BuildContext context, SecretCode code) async {
    final service = gateway;
    if (service == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.black,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: const Text(
          'ELIMINAR CÓDIGO',
          style: TextStyle(color: TerminalTheme.red),
        ),
        content: Text('¿Eliminar ${code.code}?'),
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
    if (confirmed != true || !context.mounted) return;
    try {
      await service.deleteSecretCode(code.code);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('NO SE PUDO ELIMINAR EL CÓDIGO: $error'),
            backgroundColor: TerminalTheme.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = gateway;
    if (service == null) {
      return const Center(
        child: Text(
          'CÓDIGOS // SERVICIO FIRESTORE NO DISPONIBLE',
          style: TextStyle(color: TerminalTheme.red),
        ),
      );
    }
    return StreamBuilder<List<SecretCode>>(
      stream: service.watchSecretCodes(activeOnly: false),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'ERROR AL CARGAR CÓDIGOS: ${snapshot.error}',
              style: const TextStyle(color: TerminalTheme.red),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: TerminalTheme.red),
          );
        }
        final codes = snapshot.data!;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      '> BÓVEDA DE CÓDIGOS SECRETOS',
                      style: TextStyle(
                        color: TerminalTheme.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _edit(context),
                    icon: const Icon(Icons.add, size: 15),
                    label: const Text(
                      'NUEVO CÓDIGO',
                      style: TextStyle(fontSize: 9),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: codes.isEmpty
                  ? const Center(child: Text('NO HAY CÓDIGOS SECRETOS.'))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      itemCount: codes.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final code = codes[index];
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
                                      '${code.code} // ${code.active ? 'ACTIVO' : 'INACTIVO'}',
                                      style: const TextStyle(
                                        color: TerminalTheme.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      code.rewardTitle,
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                    Text(
                                      code.rewardDescription,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Editar código',
                                onPressed: () => _edit(context, code: code),
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  color: TerminalTheme.red,
                                  size: 18,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Eliminar código',
                                onPressed: () => _delete(context, code),
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
      },
    );
  }
}
