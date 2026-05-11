import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../api/api_client.dart';
import '../config.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final api = ApiClient();
  final picker = ImagePicker();

  late Future<List<dynamic>> future;
  String q = '';

  @override
  void initState() {
    super.initState();
    future = api.getCustomers();
  }

  Future<void> refresh() async {
    setState(() {
      future = api.getCustomers();
    });

    await future;
  }

  Future<XFile?> _pickImage(ImageSource source) async {
    return picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1200,
    );
  }

  Future<void> _deleteCustomer(Map<String, dynamic> customer) async {
    final id = (customer['id'] as num).toInt();
    final name = (customer['name'] ?? 'Cliente').toString();
    final imageUrl = (customer['imageUrl'] ?? '').toString();

    final confirmed = await _showDeleteCustomerDialog(
      name: name,
      imageUrl: imageUrl,
    );

    if (confirmed != true) return;

    try {
      await api.deleteCustomer(id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cliente "$name" eliminado correctamente'),
        ),
      );

      await refresh();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo eliminar el cliente. Puede estar asociado a pedidos.\n$e',
          ),
        ),
      );
    }
  }

  Future<bool?> _showDeleteCustomerDialog({
    required String name,
    required String imageUrl,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final cs = Theme.of(context).colorScheme;

        return Container(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          decoration: const BoxDecoration(
            color: Color(0xFFF4F8FC),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(32),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),

                Row(
                  children: [
                    _CustomerAvatar(
                      name: name,
                      imageUrl: imageUrl,
                      localImage: null,
                      size: 64,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Eliminar cliente',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 13,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.errorContainer,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: cs.onErrorContainer,
                        size: 30,
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Text(
                          'Esta acción eliminará el cliente. Si el cliente tiene pedidos asociados, la API puede impedir eliminarlo para proteger los datos.',
                          style: TextStyle(
                            color: cs.onErrorContainer,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: FilledButton.icon(
                          onPressed: () => Navigator.pop(context, true),
                          style: FilledButton.styleFrom(
                            backgroundColor: cs.error,
                            foregroundColor: cs.onError,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          icon: const Icon(Icons.delete_rounded),
                          label: const Text(
                            'Eliminar',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool?> _openCustomerSheet({
    Map<String, dynamic>? customer,
  }) {
    final isEditing = customer != null;

    final nameCtrl = TextEditingController(
      text: customer?['name']?.toString() ?? '',
    );

    final phoneCtrl = TextEditingController(
      text: customer?['phone']?.toString() ?? '',
    );

    final emailCtrl = TextEditingController(
      text: customer?['email']?.toString() ?? '',
    );

    XFile? selectedImage;

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        bool saving = false;

        return StatefulBuilder(
          builder: (context, setLocal) {
            final cs = Theme.of(context).colorScheme;
            final bottom = MediaQuery.of(context).viewInsets.bottom;

            final previewName = nameCtrl.text.trim().isEmpty
                ? 'Cliente'
                : nameCtrl.text.trim();

            final currentImageUrl =
            (customer?['imageUrl'] ?? '').toString().trim();

            return Padding(
              padding: EdgeInsets.only(bottom: bottom),
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                decoration: const BoxDecoration(
                  color: Color(0xFFF4F8FC),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 44,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: 18),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),

                        Row(
                          children: [
                            _CustomerAvatar(
                              name: previewName,
                              imageUrl: currentImageUrl,
                              localImage: selectedImage,
                              size: 62,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isEditing
                                        ? 'Editar cliente'
                                        : 'Nuevo cliente',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isEditing
                                        ? 'Actualiza los datos y cambia la foto.'
                                        : 'Añade un cliente y sube una foto.',
                                    style: TextStyle(
                                      color: cs.onSurfaceVariant,
                                      fontSize: 13,
                                      height: 1.25,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        _PhotoPickerCard(
                          selectedImage: selectedImage,
                          currentImageUrl: currentImageUrl,
                          name: previewName,
                          onGallery: saving
                              ? null
                              : () async {
                            final image = await _pickImage(
                              ImageSource.gallery,
                            );

                            if (image != null) {
                              setLocal(() {
                                selectedImage = image;
                              });
                            }
                          },
                          onCamera: saving
                              ? null
                              : () async {
                            final image = await _pickImage(
                              ImageSource.camera,
                            );

                            if (image != null) {
                              setLocal(() {
                                selectedImage = image;
                              });
                            }
                          },
                          onRemoveSelected: selectedImage == null || saving
                              ? null
                              : () {
                            setLocal(() {
                              selectedImage = null;
                            });
                          },
                        ),

                        const SizedBox(height: 16),

                        _InputCard(
                          child: Column(
                            children: [
                              TextField(
                                controller: nameCtrl,
                                textInputAction: TextInputAction.next,
                                onChanged: (_) => setLocal(() {}),
                                decoration: const InputDecoration(
                                  labelText: 'Nombre *',
                                  hintText: 'Ej: Juan Pérez',
                                  prefixIcon: Icon(Icons.person_rounded),
                                  border: InputBorder.none,
                                ),
                              ),
                              const Divider(height: 1),
                              TextField(
                                controller: phoneCtrl,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Teléfono',
                                  hintText: 'Ej: 600 123 123',
                                  prefixIcon: Icon(Icons.phone_rounded),
                                  border: InputBorder.none,
                                ),
                              ),
                              const Divider(height: 1),
                              TextField(
                                controller: emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  hintText: 'Ej: cliente@email.com',
                                  prefixIcon: Icon(Icons.email_rounded),
                                  border: InputBorder.none,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 52,
                                child: OutlinedButton(
                                  onPressed: saving
                                      ? null
                                      : () => Navigator.pop(context, false),
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                  child: const Text(
                                    'Cancelar',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 52,
                                child: FilledButton.icon(
                                  onPressed: saving
                                      ? null
                                      : () async {
                                    final name = nameCtrl.text.trim();
                                    final phone = phoneCtrl.text.trim();
                                    final email = emailCtrl.text.trim();

                                    if (name.isEmpty) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'El nombre es obligatorio',
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    setLocal(() {
                                      saving = true;
                                    });

                                    try {
                                      Map<String, dynamic> savedCustomer;

                                      if (isEditing) {
                                        final id =
                                        (customer['id'] as num)
                                            .toInt();

                                        savedCustomer =
                                        await api.updateCustomer(
                                          id: id,
                                          name: name,
                                          phone: phone,
                                          email: email,
                                          imageUrl: currentImageUrl,
                                        );

                                        if (selectedImage != null) {
                                          savedCustomer = await api
                                              .uploadCustomerPhoto(
                                            id: id,
                                            imageFile: File(
                                              selectedImage!.path,
                                            ),
                                          );
                                        }
                                      } else {
                                        savedCustomer =
                                        await api.createCustomer(
                                          name: name,
                                          phone: phone,
                                          email: email,
                                        );

                                        if (selectedImage != null) {
                                          final id =
                                          (savedCustomer['id'] as num)
                                              .toInt();

                                          savedCustomer = await api
                                              .uploadCustomerPhoto(
                                            id: id,
                                            imageFile: File(
                                              selectedImage!.path,
                                            ),
                                          );
                                        }
                                      }

                                      if (!context.mounted) return;

                                      Navigator.pop(context, true);
                                    } catch (e) {
                                      if (!context.mounted) return;

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text('Error: $e'),
                                        ),
                                      );
                                    } finally {
                                      if (context.mounted) {
                                        setLocal(() {
                                          saving = false;
                                        });
                                      }
                                    }
                                  },
                                  style: FilledButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                  icon: saving
                                      ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                      : Icon(
                                    isEditing
                                        ? Icons.edit_rounded
                                        : Icons.save_rounded,
                                  ),
                                  label: Text(
                                    isEditing ? 'Guardar' : 'Crear',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
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
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: FutureBuilder<List<dynamic>>(
        future: future,
        builder: (context, snapshot) {
          final loading = snapshot.connectionState != ConnectionState.done;
          final hasError = snapshot.hasError;

          return RefreshIndicator(
            color: cs.primary,
            onRefresh: refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 150),
              children: [
                _CustomersHeader(
                  onRefresh: refresh,
                  onCreate: () async {
                    final created = await _openCustomerSheet();

                    if (created == true) {
                      await refresh();
                    }
                  },
                ),

                const SizedBox(height: 16),

                _SearchBox(
                  onChanged: (v) {
                    setState(() {
                      q = v.trim().toLowerCase();
                    });
                  },
                ),

                const SizedBox(height: 18),

                if (loading) ...[
                  const _LoadingCard(),
                  const SizedBox(height: 12),
                  const _LoadingCard(),
                  const SizedBox(height: 12),
                  const _LoadingCard(),
                ] else if (hasError) ...[
                  _ErrorCard(
                    message:
                    'No se pudieron cargar los clientes.\n${snapshot.error}',
                    onRetry: refresh,
                  ),
                ] else ...[
                  Builder(
                    builder: (_) {
                      final items = snapshot.data ?? [];

                      final filtered = items.where((c) {
                        final map = c as Map<String, dynamic>;

                        final name =
                        (map['name'] ?? '').toString().toLowerCase();

                        final email =
                        (map['email'] ?? '').toString().toLowerCase();

                        final phone =
                        (map['phone'] ?? '').toString().toLowerCase();

                        if (q.isEmpty) return true;

                        return name.contains(q) ||
                            email.contains(q) ||
                            phone.contains(q);
                      }).toList();

                      filtered.sort((a, b) {
                        final aId = ((a as Map<String, dynamic>)['id'] ?? 0);
                        final bId = ((b as Map<String, dynamic>)['id'] ?? 0);

                        return (bId as num).compareTo(aId as num);
                      });

                      if (filtered.isEmpty) {
                        return const _EmptyCustomersCard();
                      }

                      return Column(
                        children: [
                          _CustomersSummaryCard(
                            total: items.length,
                            visible: filtered.length,
                          ),
                          const SizedBox(height: 14),
                          ...filtered.map((c) {
                            final customer = c as Map<String, dynamic>;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _CustomerCard(
                                customer: customer,
                                onEdit: () async {
                                  final updated = await _openCustomerSheet(
                                    customer: customer,
                                  );

                                  if (updated == true) {
                                    await refresh();
                                  }
                                },
                                onDelete: () => _deleteCustomer(customer),
                              ),
                            );
                          }),
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/* ---------------- UI Clientes ---------------- */

class _CustomersHeader extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final VoidCallback onCreate;

  const _CustomersHeader({
    required this.onRefresh,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF061A2D),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF061A2D).withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.14),
                  ),
                ),
                child: const Icon(
                  Icons.groups_rounded,
                  color: Colors.white,
                  size: 29,
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Clientes',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Gestión de contactos',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFFB7C8D8),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onRefresh,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.12),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Text(
            'Controla la información de tus clientes, actualiza sus datos, sube fotos y elimina contactos cuando sea necesario.',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.78),
              fontSize: 13.5,
              height: 1.35,
            ),
          ),

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: onCreate,
              style: FilledButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text(
                'Añadir nuevo cliente',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const _SearchBox({
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Buscar por nombre, teléfono o email...',
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(
            color: cs.outlineVariant.withOpacity(0.5),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(
            color: cs.outlineVariant.withOpacity(0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(
            color: cs.primary,
            width: 1.4,
          ),
        ),
      ),
    );
  }
}

class _PhotoPickerCard extends StatelessWidget {
  final XFile? selectedImage;
  final String currentImageUrl;
  final String name;
  final VoidCallback? onGallery;
  final VoidCallback? onCamera;
  final VoidCallback? onRemoveSelected;

  const _PhotoPickerCard({
    required this.selectedImage,
    required this.currentImageUrl,
    required this.name,
    required this.onGallery,
    required this.onCamera,
    required this.onRemoveSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: cs.outlineVariant.withOpacity(0.45),
        ),
      ),
      child: Row(
        children: [
          _CustomerAvatar(
            name: name,
            imageUrl: currentImageUrl,
            localImage: selectedImage,
            size: 64,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Foto del cliente',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  selectedImage == null
                      ? 'Elige una imagen desde galería o cámara.'
                      : 'Nueva foto seleccionada.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: onGallery,
                      icon: const Icon(Icons.photo_library_rounded),
                      label: const Text('Galería'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: onCamera,
                      icon: const Icon(Icons.photo_camera_rounded),
                      label: const Text('Cámara'),
                    ),
                    if (selectedImage != null)
                      IconButton.filledTonal(
                        onPressed: onRemoveSelected,
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'Quitar foto seleccionada',
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomersSummaryCard extends StatelessWidget {
  final int total;
  final int visible;

  const _CustomersSummaryCard({
    required this.total,
    required this.visible,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: cs.outlineVariant.withOpacity(0.45),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.insights_rounded,
              color: cs.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              _summaryText(total, visible),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 13,
                height: 1.25,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _summaryText(int total, int visible) {
    if (total == visible) {
      return 'Tienes $total clientes registrados en SmartWorks.';
    }

    return 'Mostrando $visible de $total clientes registrados.';
  }
}

class _CustomerCard extends StatelessWidget {
  final Map<String, dynamic> customer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CustomerCard({
    required this.customer,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final id = (customer['id'] ?? '').toString();
    final name = (customer['name'] ?? 'Cliente').toString();
    final email = (customer['email'] ?? '').toString();
    final phone = (customer['phone'] ?? '').toString();
    final imageUrl = (customer['imageUrl'] ?? '').toString();

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: cs.outlineVariant.withOpacity(0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _CustomerAvatar(
            name: name,
            imageUrl: imageUrl,
            localImage: null,
            size: 58,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _MiniBadge(
                      icon: Icons.tag_rounded,
                      text: '#$id',
                    ),
                    if (phone.isNotEmpty)
                      _MiniBadge(
                        icon: Icons.phone_rounded,
                        text: phone,
                      ),
                    if (email.isNotEmpty)
                      _MiniBadge(
                        icon: Icons.email_rounded,
                        text: email,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert_rounded,
              color: cs.onSurfaceVariant,
            ),
            onSelected: (value) {
              if (value == 'edit') {
                onEdit();
              } else if (value == 'delete') {
                onDelete();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_rounded),
                    SizedBox(width: 10),
                    Text('Editar'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_rounded,
                      color: cs.error,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Eliminar',
                      style: TextStyle(
                        color: cs.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CustomerAvatar extends StatelessWidget {
  final String name;
  final String imageUrl;
  final XFile? localImage;
  final double size;

  const _CustomerAvatar({
    required this.name,
    required this.imageUrl,
    required this.localImage,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final initial = _initialFromName(name);

    if (localImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.32),
        child: Image.file(
          File(localImage!.path),
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }

    final resolvedUrl = _resolveImageUrl(imageUrl);

    if (resolvedUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.32),
        child: Image.network(
          resolvedUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return _FallbackAvatar(
              initial: initial,
              size: size,
            );
          },
        ),
      );
    }

    return _FallbackAvatar(
      initial: initial,
      size: size,
    );
  }

  String _initialFromName(String value) {
    final clean = value.trim();

    if (clean.isEmpty) return '?';

    return clean.characters.first.toUpperCase();
  }

  String _resolveImageUrl(String value) {
    final clean = value.trim();

    if (clean.isEmpty) return '';

    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return clean;
    }

    if (clean.startsWith('/')) {
      return '$baseUrl$clean';
    }

    return '$baseUrl/$clean';
  }
}

class _FallbackAvatar extends StatelessWidget {
  final String initial;
  final double size;

  const _FallbackAvatar({
    required this.initial,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: cs.onPrimaryContainer,
            fontWeight: FontWeight.w900,
            fontSize: size * 0.38,
          ),
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MiniBadge({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: cs.outlineVariant.withOpacity(0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: cs.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  final Widget child;

  const _InputCard({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: cs.outlineVariant.withOpacity(0.45),
        ),
      ),
      child: child,
    );
  }
}

class _EmptyCustomersCard extends StatelessWidget {
  const _EmptyCustomersCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: cs.outlineVariant.withOpacity(0.45),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.person_search_rounded,
            size: 46,
            color: cs.primary,
          ),
          const SizedBox(height: 12),
          const Text(
            'No se encontraron clientes',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Prueba con otra búsqueda o añade un nuevo cliente.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 13,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      height: 94,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: cs.outlineVariant.withOpacity(0.45),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorCard({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Error',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: cs.onErrorContainer,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: cs.onErrorContainer,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}