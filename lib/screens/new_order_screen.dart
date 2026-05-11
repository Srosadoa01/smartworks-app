import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../config.dart';
import '../data/product_images.dart';

class NewOrderScreen extends StatefulWidget {
  const NewOrderScreen({super.key});

  @override
  State<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends State<NewOrderScreen> {
  final api = ApiClient();

  int? customerId;

  List<dynamic> customers = [];
  List<dynamic> products = [];

  final List<Map<String, int>> lines = [];

  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final loadedCustomers = await api.getCustomers();
      final loadedProducts = await api.getProducts(lowStockOnly: false);

      setState(() {
        customers = loadedCustomers;
        products = loadedProducts;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cargando datos: $e'),
        ),
      );
    }
  }

  Map<String, dynamic>? _selectedCustomer() {
    if (customerId == null) return null;

    try {
      return customers.firstWhere(
            (item) => ((item['id'] as num).toInt()) == customerId,
      ) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _productById(int productId) {
    return products.firstWhere(
          (item) => ((item['id'] as num).toInt()) == productId,
    ) as Map<String, dynamic>;
  }

  double _priceOf(int productId) {
    final product = _productById(productId);

    return (product['price'] as num?)?.toDouble() ?? 0.0;
  }

  int get _totalUnits {
    return lines.fold<int>(0, (acc, line) {
      return acc + (line['quantity'] ?? 0);
    });
  }

  double get _totalAmount {
    return lines.fold<double>(0.0, (acc, line) {
      final productId = line['productId']!;
      final qty = line['quantity']!;

      return acc + (qty * _priceOf(productId));
    });
  }

  Future<void> _create() async {
    if (customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un cliente'),
        ),
      );
      return;
    }

    if (lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Añade al menos un producto al pedido'),
        ),
      );
      return;
    }

    if (_totalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El total es 0€. Revisa los precios de los productos.'),
        ),
      );
      return;
    }

    setState(() {
      saving = true;
    });

    try {
      await api.createOrder(
        customerId: customerId!,
        lines: lines.map((line) {
          return {
            'productId': line['productId'],
            'quantity': line['quantity'],
          };
        }).toList(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pedido creado correctamente'),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creando pedido: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  Future<void> _openAddLineSheet() async {
    int? selectedProductId;
    final qtyCtrl = TextEditingController(text: '1');

    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            final cs = Theme.of(context).colorScheme;
            final bottom = MediaQuery.of(context).viewInsets.bottom;

            Map<String, dynamic>? selectedProduct;

            if (selectedProductId != null) {
              try {
                selectedProduct = _productById(selectedProductId!);
              } catch (_) {
                selectedProduct = null;
              }
            }

            final selectedName =
            (selectedProduct?['name'] ?? 'Producto').toString();

            final selectedImageUrl =
            (selectedProduct?['imageUrl'] ?? '').toString();

            final selectedStock =
                (selectedProduct?['stock'] as num?)?.toInt() ?? 0;

            final selectedPrice =
                (selectedProduct?['price'] as num?)?.toDouble() ?? 0.0;

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
                              name: selectedName,
                              imageUrl: selectedImageUrl,
                              size: 62,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Añadir producto',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Selecciona un producto y la cantidad de palets.',
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

                        _InputCard(
                          child: Column(
                            children: [
                              DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: selectedProductId,
                                  isExpanded: true,
                                  hint: const Text('Selecciona un producto'),
                                  items: products.map((item) {
                                    final product =
                                    item as Map<String, dynamic>;

                                    final id =
                                    (product['id'] as num).toInt();

                                    final name =
                                    (product['name'] ?? 'Producto')
                                        .toString();

                                    final stock =
                                        (product['stock'] as num?)?.toInt() ??
                                            0;

                                    final price =
                                        (product['price'] as num?)
                                            ?.toDouble() ??
                                            0.0;

                                    return DropdownMenuItem<int>(
                                      value: id,
                                      child: Text(
                                        '$name · Stock: $stock · ${price.toStringAsFixed(2)} €',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setLocal(() {
                                      selectedProductId = value;
                                    });
                                  },
                                ),
                              ),
                              const Divider(height: 1),
                              TextField(
                                controller: qtyCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Cantidad de palets',
                                  hintText: 'Ej: 2',
                                  prefixIcon: Icon(Icons.numbers_rounded),
                                  border: InputBorder.none,
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (selectedProduct != null) ...[
                          const SizedBox(height: 14),
                          _SelectedProductResume(
                            stock: selectedStock,
                            price: selectedPrice,
                          ),
                        ],

                        const SizedBox(height: 18),

                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 52,
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(
                                    context,
                                    false,
                                  ),
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
                                  onPressed: () {
                                    final qty = int.tryParse(
                                      qtyCtrl.text.trim(),
                                    );

                                    if (selectedProductId == null) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Selecciona un producto',
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    if (qty == null || qty <= 0) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Introduce una cantidad válida',
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    setState(() {
                                      final index = lines.indexWhere((line) {
                                        return line['productId'] ==
                                            selectedProductId;
                                      });

                                      if (index >= 0) {
                                        lines[index]['quantity'] =
                                            (lines[index]['quantity'] ?? 0) +
                                                qty;
                                      } else {
                                        lines.add({
                                          'productId': selectedProductId!,
                                          'quantity': qty,
                                        });
                                      }
                                    });

                                    Navigator.pop(context, true);
                                  },
                                  style: FilledButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                  icon: const Icon(Icons.add_rounded),
                                  label: const Text(
                                    'Añadir',
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
    final customer = _selectedCustomer();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),
      body: SafeArea(
        child: loading
            ? const Center(
          child: CircularProgressIndicator(),
        )
            : ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 150),
          children: [
            _NewOrderHeader(
              onBack: () => Navigator.pop(context),
            ),

            const SizedBox(height: 16),

            _SectionHeader(
              title: 'Cliente',
              subtitle: 'Selecciona el cliente asociado al pedido',
            ),

            const SizedBox(height: 12),

            _InputCard(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: customerId,
                  hint: const Text('Selecciona un cliente'),
                  isExpanded: true,
                  items: customers.map((item) {
                    final customer = item as Map<String, dynamic>;

                    final id = (customer['id'] as num).toInt();
                    final name =
                    (customer['name'] ?? 'Cliente').toString();

                    return DropdownMenuItem<int>(
                      value: id,
                      child: Text(
                        '$name (#$id)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      customerId = value;
                    });
                  },
                ),
              ),
            ),

            if (customer != null) ...[
              const SizedBox(height: 12),
              _CustomerPreviewCard(customer: customer),
            ],

            const SizedBox(height: 24),

            _LinesHeader(
              onAdd: _openAddLineSheet,
            ),

            const SizedBox(height: 12),

            if (lines.isEmpty)
              const _EmptyLinesCard()
            else
              Column(
                children: List.generate(lines.length, (index) {
                  final line = lines[index];

                  final productId = line['productId']!;
                  final qty = line['quantity']!;

                  final product = _productById(productId);

                  final name =
                  (product['name'] ?? 'Producto').toString();

                  final imageUrl =
                  (product['imageUrl'] ?? '').toString();

                  final unitPrice = _priceOf(productId);
                  final lineTotal = unitPrice * qty;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _OrderLineCard(
                      name: name,
                      imageUrl: imageUrl,
                      quantity: qty,
                      unitPrice: unitPrice,
                      total: lineTotal,
                      onDelete: () {
                        setState(() {
                          lines.removeAt(index);
                        });
                      },
                      onDecrease: () {
                        setState(() {
                          if (qty <= 1) {
                            lines.removeAt(index);
                          } else {
                            lines[index]['quantity'] = qty - 1;
                          }
                        });
                      },
                      onIncrease: () {
                        setState(() {
                          lines[index]['quantity'] = qty + 1;
                        });
                      },
                    ),
                  );
                }),
              ),

            const SizedBox(height: 14),

            _OrderResumeCard(
              totalUnits: _totalUnits,
              totalAmount: _totalAmount,
            ),

            const SizedBox(height: 18),

            SizedBox(
              height: 54,
              child: FilledButton.icon(
                onPressed: saving ? null : _create,
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
                    : const Icon(Icons.check_rounded),
                label: const Text(
                  'Crear pedido',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ---------------- UI Nuevo Pedido ---------------- */

class _NewOrderHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _NewOrderHeader({
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
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
              IconButton(
                onPressed: onBack,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.12),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nuevo pedido',
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
                      'Crear operación de venta',
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
            ],
          ),

          const SizedBox(height: 18),

          Text(
            'Selecciona un cliente, añade productos al pedido y revisa el resumen antes de confirmar.',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.78),
              fontSize: 13.5,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: cs.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _LinesHeader extends StatelessWidget {
  final VoidCallback onAdd;

  const _LinesHeader({
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: _SectionHeader(
            title: 'Productos',
            subtitle: 'Añade líneas al pedido',
          ),
        ),
        FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add_rounded),
          label: const Text(
            'Añadir',
            style: TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _CustomerPreviewCard extends StatelessWidget {
  final Map<String, dynamic> customer;

  const _CustomerPreviewCard({
    required this.customer,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final name = (customer['name'] ?? 'Cliente').toString();
    final phone = (customer['phone'] ?? '').toString();
    final email = (customer['email'] ?? '').toString();
    final imageUrl = (customer['imageUrl'] ?? '').toString();

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
            imageUrl: imageUrl,
            size: 54,
          ),
          const SizedBox(width: 13),
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
                    fontSize: 15.5,
                  ),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
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
        ],
      ),
    );
  }
}

class _SelectedProductResume extends StatelessWidget {
  final int stock;
  final double price;

  const _SelectedProductResume({
    required this.stock,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SmallInfoCard(
            title: 'Stock',
            value: stock.toString(),
            icon: Icons.warehouse_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SmallInfoCard(
            title: 'Precio',
            value: '${price.toStringAsFixed(2)} €',
            icon: Icons.euro_rounded,
          ),
        ),
      ],
    );
  }
}

class _SmallInfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _SmallInfoCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: cs.outlineVariant.withOpacity(0.45),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: cs.primary,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
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

class _OrderLineCard extends StatelessWidget {
  final String name;
  final String imageUrl;
  final int quantity;
  final double unitPrice;
  final double total;
  final VoidCallback onDelete;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const _OrderLineCard({
    required this.name,
    required this.imageUrl,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    required this.onDelete,
    required this.onDecrease,
    required this.onIncrease,
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          _ProductImage(
            name: name,
            imageUrl: imageUrl,
            size: 58,
          ),

          const SizedBox(width: 13),

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
                    fontSize: 15.5,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${unitPrice.toStringAsFixed(2)} € / palet',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Total: ${total.toStringAsFixed(2)} €',
                  style: TextStyle(
                    color: cs.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Column(
            children: [
              Row(
                children: [
                  _QtyButton(
                    icon: Icons.remove_rounded,
                    onTap: onDecrease,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    child: Text(
                      quantity.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  _QtyButton(
                    icon: Icons.add_rounded,
                    onTap: onIncrease,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                color: cs.error,
                tooltip: 'Eliminar línea',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 18,
          color: cs.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _OrderResumeCard extends StatelessWidget {
  final int totalUnits;
  final double totalAmount;

  const _OrderResumeCard({
    required this.totalUnits,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF061A2D),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF061A2D).withOpacity(0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.summarize_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Resumen del pedido',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalUnits palets seleccionados',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.72),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${totalAmount.toStringAsFixed(2)} €',
              style: TextStyle(
                color: cs.onPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyLinesCard extends StatelessWidget {
  const _EmptyLinesCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
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
            Icons.add_shopping_cart_rounded,
            size: 44,
            color: cs.primary,
          ),
          const SizedBox(height: 12),
          const Text(
            'Todavía no hay productos',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pulsa en Añadir para seleccionar productos del inventario.',
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

class _ProductImage extends StatelessWidget {
  final String name;
  final String imageUrl;
  final double size;

  const _ProductImage({
    required this.name,
    required this.imageUrl,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
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

class _CustomerAvatar extends StatelessWidget {
  final String name;
  final String imageUrl;
  final double size;

  const _CustomerAvatar({
    required this.name,
    required this.imageUrl,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initial = _initialFromName(name);
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