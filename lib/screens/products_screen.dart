import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../api/api_client.dart';
import '../config.dart';
import '../data/product_images.dart';
import '../services/auth_service.dart';
import 'product_details_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final api = ApiClient();
  final picker = ImagePicker();

  bool lowStockOnly = false;
  String q = '';
  String? role;
  bool loadingRole = true;

  late Future<List<dynamic>> future;

  bool get isAdmin => role == 'ADMIN';

  @override
  void initState() {
    super.initState();
    future = api.getProducts(lowStockOnly: lowStockOnly);
    _loadRole();
  }

  Future<void> _loadRole() async {
    final savedRole = await AuthService().getRole();

    if (!mounted) return;

    setState(() {
      role = savedRole;
      loadingRole = false;
    });
  }

  Future<void> refresh() async {
    setState(() {
      future = api.getProducts(lowStockOnly: lowStockOnly);
    });

    await future;
  }

  void toggleLowStock(bool value) {
    setState(() {
      lowStockOnly = value;
      future = api.getProducts(lowStockOnly: lowStockOnly);
    });
  }

  Future<XFile?> _pickImage(ImageSource source) async {
    return picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1200,
    );
  }

  Future<void> _deleteProduct(Map<String, dynamic> product) async {
    if (!isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tienes permiso para eliminar productos.'),
        ),
      );
      return;
    }

    final id = (product['id'] as num).toInt();
    final name = (product['name'] ?? 'Producto').toString();
    final imageUrl = (product['imageUrl'] ?? '').toString();

    final confirmed = await _showDeleteProductDialog(
      name: name,
      imageUrl: imageUrl,
    );

    if (confirmed != true) return;

    try {
      await api.deleteProduct(id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Producto "$name" eliminado correctamente'),
        ),
      );

      await refresh();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo eliminar el producto. Puede estar asociado a pedidos.\n$e',
          ),
        ),
      );
    }
  }

  Future<bool?> _showDeleteProductDialog({
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
                    _ProductImage(
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
                            'Eliminar producto',
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
                          'Esta acción eliminará el producto del inventario. Si el producto está asociado a pedidos, la API puede impedir eliminarlo.',
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

  Future<void> _openProductSheet({
    Map<String, dynamic>? product,
  }) async {
    if (!isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tienes permiso para modificar productos.'),
        ),
      );
      return;
    }

    final isEditing = product != null;

    final int? productId = isEditing ? (product['id'] as num).toInt() : null;

    final nameCtrl = TextEditingController(
      text: product?['name']?.toString() ?? '',
    );

    final stockCtrl = TextEditingController(
      text: isEditing
          ? ((product['stock'] as num?)?.toInt() ?? 0).toString()
          : '',
    );

    final lowCtrl = TextEditingController(
      text: isEditing
          ? ((product['lowStockThreshold'] as num?)?.toInt() ?? 5).toString()
          : '5',
    );

    final priceCtrl = TextEditingController(
      text: isEditing
          ? ((product['price'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)
          : '',
    );

    XFile? selectedImage;

    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        bool saving = false;

        return StatefulBuilder(
          builder: (context, setLocal) {
            final cs = Theme.of(context).colorScheme;
            final bottom = MediaQuery.of(context).viewInsets.bottom;

            final previewName =
            nameCtrl.text.trim().isEmpty ? 'Producto' : nameCtrl.text.trim();

            final currentImageUrl =
            (product?['imageUrl'] ?? '').toString().trim();

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
                            _ProductImage(
                              name: previewName,
                              imageUrl: currentImageUrl,
                              localImage: selectedImage,
                              size: 64,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isEditing
                                        ? 'Editar producto'
                                        : 'Nuevo producto',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isEditing
                                        ? 'Modifica el producto, su stock, precio y foto.'
                                        : 'Añade un producto nuevo al inventario.',
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
                                  labelText: 'Nombre del producto *',
                                  hintText: 'Ej: Palet mango',
                                  prefixIcon: Icon(Icons.label_rounded),
                                  border: InputBorder.none,
                                ),
                              ),
                              const Divider(height: 1),
                              TextField(
                                controller: stockCtrl,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Stock disponible *',
                                  hintText: 'Ej: 25',
                                  prefixIcon: Icon(Icons.warehouse_rounded),
                                  border: InputBorder.none,
                                ),
                              ),
                              const Divider(height: 1),
                              TextField(
                                controller: lowCtrl,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Umbral de stock bajo *',
                                  hintText: 'Ej: 5',
                                  prefixIcon: Icon(
                                    Icons.warning_amber_rounded,
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                              const Divider(height: 1),
                              TextField(
                                controller: priceCtrl,
                                keyboardType:
                                const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Precio por palet *',
                                  hintText: 'Ej: 12.50',
                                  prefixIcon: Icon(Icons.euro_rounded),
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

                                    final stock = int.tryParse(
                                      stockCtrl.text.trim(),
                                    );

                                    final lowStockThreshold =
                                    int.tryParse(
                                      lowCtrl.text.trim(),
                                    );

                                    final price = double.tryParse(
                                      priceCtrl.text
                                          .trim()
                                          .replaceAll(',', '.'),
                                    );

                                    if (name.isEmpty) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'El nombre del producto es obligatorio',
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    if (stock == null) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'El stock debe ser un número válido',
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    if (lowStockThreshold == null) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'El umbral debe ser un número válido',
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    if (price == null) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'El precio debe ser un número válido',
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    setLocal(() {
                                      saving = true;
                                    });

                                    try {
                                      Map<String, dynamic> savedProduct;

                                      if (isEditing) {
                                        savedProduct =
                                        await api.patchProduct(
                                          productId!,
                                          name: name,
                                          stock: stock,
                                          lowStockThreshold:
                                          lowStockThreshold,
                                          price: price,
                                          imageUrl: currentImageUrl,
                                        );

                                        if (selectedImage != null) {
                                          savedProduct = await api
                                              .uploadProductPhoto(
                                            id: productId,
                                            imageFile: File(
                                              selectedImage!.path,
                                            ),
                                          );
                                        }
                                      } else {
                                        savedProduct =
                                        await api.createProduct(
                                          name: name,
                                          stock: stock,
                                          lowStockThreshold:
                                          lowStockThreshold,
                                          price: price,
                                        );

                                        if (selectedImage != null) {
                                          final newId =
                                          (savedProduct['id'] as num)
                                              .toInt();

                                          savedProduct = await api
                                              .uploadProductPhoto(
                                            id: newId,
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
                                          content: Text(
                                            'Error guardando: $e',
                                          ),
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
                                        ? Icons.save_rounded
                                        : Icons.add_rounded,
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
    ).then((saved) async {
      if (saved == true) {
        await refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (loadingRole) {
      return const SafeArea(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

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
                _ProductsHeader(
                  isAdmin: isAdmin,
                  onRefresh: refresh,
                  onCreate: () async {
                    await _openProductSheet();
                  },
                ),
                const SizedBox(height: 16),
                _SearchBox(
                  hintText: 'Buscar producto...',
                  onChanged: (value) {
                    setState(() {
                      q = value.trim().toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 14),
                _FiltersCard(
                  lowStockOnly: lowStockOnly,
                  onAll: () => toggleLowStock(false),
                  onLowStock: () => toggleLowStock(true),
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
                    'No se pudieron cargar los productos.\n${snapshot.error}',
                    onRetry: refresh,
                  ),
                ] else ...[
                  Builder(
                    builder: (_) {
                      final items = snapshot.data ?? [];

                      final filtered = items.where((item) {
                        final map = item as Map<String, dynamic>;
                        final name =
                        (map['name'] ?? '').toString().toLowerCase();

                        if (q.isEmpty) return true;

                        return name.contains(q);
                      }).toList();

                      if (filtered.isEmpty) {
                        return _EmptyProductsCard(
                          isAdmin: isAdmin,
                        );
                      }

                      final lowCount = items.where((item) {
                        final map = item as Map<String, dynamic>;

                        final stock = (map['stock'] as num?)?.toInt() ?? 0;
                        final low =
                            (map['lowStockThreshold'] as num?)?.toInt() ?? 0;

                        return stock <= low;
                      }).length;

                      return Column(
                        children: [
                          _ProductsSummaryCard(
                            total: items.length,
                            visible: filtered.length,
                            lowStock: lowCount,
                          ),
                          const SizedBox(height: 14),
                          ...filtered.map((item) {
                            final product = item as Map<String, dynamic>;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ProductCard(
                                product: product,
                                isAdmin: isAdmin,
                                onEdit: () => _openProductSheet(
                                  product: product,
                                ),
                                onDelete: () => _deleteProduct(product),
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

/* ---------------- UI Productos ---------------- */

class _ProductsHeader extends StatelessWidget {
  final bool isAdmin;
  final Future<void> Function() onRefresh;
  final VoidCallback onCreate;

  const _ProductsHeader({
    required this.isAdmin,
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
                  Icons.inventory_2_rounded,
                  color: Colors.white,
                  size: 29,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Productos',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isAdmin ? 'Gestión de inventario' : 'Consulta de stock',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
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
            isAdmin
                ? 'Añade nuevos productos, edita nombres, cambia stock, precios y elimina productos si ya no forman parte del inventario.'
                : 'Consulta los productos disponibles, revisa el stock y detecta productos con bajo inventario.',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.78),
              fontSize: 13.5,
              height: 1.35,
            ),
          ),
          if (isAdmin) ...[
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
                icon: const Icon(Icons.add_box_rounded),
                label: const Text(
                  'Añadir nuevo producto',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  final String hintText;
  final ValueChanged<String> onChanged;

  const _SearchBox({
    required this.hintText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
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

class _FiltersCard extends StatelessWidget {
  final bool lowStockOnly;
  final VoidCallback onAll;
  final VoidCallback onLowStock;

  const _FiltersCard({
    required this.lowStockOnly,
    required this.onAll,
    required this.onLowStock,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: cs.outlineVariant.withOpacity(0.45),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _FilterButton(
              selected: !lowStockOnly,
              text: 'Todos',
              icon: Icons.grid_view_rounded,
              onTap: onAll,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _FilterButton(
              selected: lowStockOnly,
              text: 'Stock bajo',
              icon: Icons.warning_amber_rounded,
              onTap: onLowStock,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final bool selected;
  final String text;
  final IconData icon;
  final VoidCallback onTap;

  const _FilterButton({
    required this.selected,
    required this.text,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 46,
        decoration: BoxDecoration(
          color: selected ? cs.primary : const Color(0xFFF4F8FC),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 19,
              color: selected ? cs.onPrimary : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? cs.onPrimary : cs.onSurfaceVariant,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ),
          ],
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
          _ProductImage(
            name: name,
            imageUrl: currentImageUrl,
            localImage: selectedImage,
            size: 66,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Foto del producto',
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

class _ProductsSummaryCard extends StatelessWidget {
  final int total;
  final int visible;
  final int lowStock;

  const _ProductsSummaryCard({
    required this.total,
    required this.visible,
    required this.lowStock,
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
              _summaryText(),
              maxLines: 3,
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

  String _summaryText() {
    if (total == visible) {
      return 'Tienes $total productos registrados. $lowStock necesitan revisión por stock bajo.';
    }

    return 'Mostrando $visible de $total productos. $lowStock necesitan revisión por stock bajo.';
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final bool isAdmin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.product,
    required this.isAdmin,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final name = (product['name'] ?? '').toString();
    final imageUrl = (product['imageUrl'] ?? '').toString();
    final stock = (product['stock'] as num?)?.toInt() ?? 0;
    final low = (product['lowStockThreshold'] as num?)?.toInt() ?? 0;
    final price = (product['price'] as num?)?.toDouble() ?? 0.0;

    final isLow = stock <= low;

    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: isLow
                ? cs.error.withOpacity(0.25)
                : cs.outlineVariant.withOpacity(0.45),
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
            _ProductImage(
              name: name,
              imageUrl: imageUrl,
              localImage: null,
              size: 62,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      if (isLow)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: cs.errorContainer,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Bajo',
                            style: TextStyle(
                              color: cs.onErrorContainer,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _MiniBadge(
                        icon: Icons.warehouse_rounded,
                        text: 'Stock: $stock',
                      ),
                      _MiniBadge(
                        icon: Icons.warning_amber_rounded,
                        text: 'Umbral: $low',
                      ),
                      _MiniBadge(
                        icon: Icons.euro_rounded,
                        text: '${price.toStringAsFixed(2)} €',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            if (isAdmin)
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
              )
            else
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: cs.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String name;
  final String imageUrl;
  final XFile? localImage;
  final double size;

  const _ProductImage({
    required this.name,
    required this.imageUrl,
    required this.localImage,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    if (localImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.28),
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
        borderRadius: BorderRadius.circular(size * 0.28),
        child: Image.network(
          resolvedUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return _AssetProductImage(
              name: name,
              size: size,
            );
          },
        ),
      );
    }

    return _AssetProductImage(
      name: name,
      size: size,
    );
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

class _AssetProductImage extends StatelessWidget {
  final String name;
  final double size;

  const _AssetProductImage({
    required this.name,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final img = productImageFor(name);

    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.28),
      child: Image.asset(
        img,
        width: size,
        height: size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) {
          return Image.asset(
            fallbackProductImage,
            width: size,
            height: size,
            fit: BoxFit.cover,
          );
        },
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

class _EmptyProductsCard extends StatelessWidget {
  final bool isAdmin;

  const _EmptyProductsCard({
    required this.isAdmin,
  });

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
            Icons.inventory_2_outlined,
            size: 46,
            color: cs.primary,
          ),
          const SizedBox(height: 12),
          const Text(
            'No se encontraron productos',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isAdmin
                ? 'Prueba con otra búsqueda, cambia el filtro o añade un producto nuevo.'
                : 'Prueba con otra búsqueda o cambia el filtro.',
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