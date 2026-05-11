import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../config.dart';
import '../data/product_images.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final api = ApiClient();

  late Future<List<dynamic>> future;
  String q = '';

  @override
  void initState() {
    super.initState();
    future = api.getOrders();
  }

  Future<void> refresh() async {
    setState(() {
      future = api.getOrders();
    });

    await future;
  }

  Future<void> _openCreateOrderSheet() async {
    try {
      final customers = await api.getCustomers();
      final products = await api.getProducts();

      if (!mounted) return;

      final created = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) {
          return _CreateOrderSheet(
            customers: customers,
            products: products,
            api: api,
          );
        },
      );

      if (created == true) {
        await refresh();
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }
  }

  Future<void> _openOrderDetails(Map<String, dynamic> order) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => OrderDetailsScreen(
          order: order,
          api: api,
        ),
      ),
    );

    if (updated == true) {
      await refresh();
    }
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
                _OrdersHeader(
                  onRefresh: refresh,
                  onCreate: _openCreateOrderSheet,
                ),

                const SizedBox(height: 16),

                _SearchBox(
                  onChanged: (value) {
                    setState(() {
                      q = value.trim().toLowerCase();
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
                    'No se pudieron cargar los pedidos.\n${snapshot.error}',
                    onRetry: refresh,
                  ),
                ] else ...[
                  Builder(
                    builder: (_) {
                      final items = snapshot.data ?? [];

                      final filtered = items.where((item) {
                        final order = item as Map<String, dynamic>;

                        final id = (order['id'] ?? '').toString();
                        final status = (order['status'] ?? '').toString();
                        final customer = _customerName(order).toLowerCase();

                        if (q.isEmpty) return true;

                        return id.contains(q) ||
                            status.toLowerCase().contains(q) ||
                            customer.contains(q);
                      }).toList();

                      filtered.sort((a, b) {
                        final aId = ((a as Map<String, dynamic>)['id'] ?? 0);
                        final bId = ((b as Map<String, dynamic>)['id'] ?? 0);

                        return (bId as num).compareTo(aId as num);
                      });

                      if (filtered.isEmpty) {
                        return const _EmptyOrdersCard();
                      }

                      final pending = items.where((item) {
                        final order = item as Map<String, dynamic>;
                        return _status(order) == 'PENDING';
                      }).length;

                      final completed = items.where((item) {
                        final order = item as Map<String, dynamic>;
                        return _status(order) == 'COMPLETED';
                      }).length;

                      final cancelled = items.where((item) {
                        final order = item as Map<String, dynamic>;
                        return _status(order) == 'CANCELLED';
                      }).length;

                      return Column(
                        children: [
                          _OrdersSummaryCard(
                            total: items.length,
                            visible: filtered.length,
                            pending: pending,
                            completed: completed,
                            cancelled: cancelled,
                          ),
                          const SizedBox(height: 14),
                          ...filtered.map((item) {
                            final order = item as Map<String, dynamic>;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _OrderCard(
                                order: order,
                                onTap: () => _openOrderDetails(order),
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

/* ---------------- Crear Pedido ---------------- */

class _CreateOrderSheet extends StatefulWidget {
  final List<dynamic> customers;
  final List<dynamic> products;
  final ApiClient api;

  const _CreateOrderSheet({
    required this.customers,
    required this.products,
    required this.api,
  });

  @override
  State<_CreateOrderSheet> createState() => _CreateOrderSheetState();
}

class _CreateOrderSheetState extends State<_CreateOrderSheet> {
  int? selectedCustomerId;
  final List<_OrderLineDraft> lines = [];
  bool saving = false;

  @override
  void initState() {
    super.initState();

    if (widget.customers.isNotEmpty) {
      final first = widget.customers.first as Map<String, dynamic>;
      selectedCustomerId = (first['id'] as num?)?.toInt();
    }
  }

  Map<String, dynamic>? get selectedCustomer {
    if (selectedCustomerId == null) return null;

    for (final item in widget.customers) {
      final customer = item as Map<String, dynamic>;
      final id = (customer['id'] as num?)?.toInt();

      if (id == selectedCustomerId) {
        return customer;
      }
    }

    return null;
  }

  double get total {
    double result = 0;

    for (final line in lines) {
      final price = (line.product['price'] as num?)?.toDouble() ?? 0.0;
      result += price * line.quantity;
    }

    return result;
  }

  int get totalUnits {
    int result = 0;

    for (final line in lines) {
      result += line.quantity;
    }

    return result;
  }

  bool get hasStockProblems {
    return lines.any((line) {
      final stock = (line.product['stock'] as num?)?.toInt() ?? 0;
      return line.quantity > stock;
    });
  }

  String? get stockProblemMessage {
    for (final line in lines) {
      final stock = (line.product['stock'] as num?)?.toInt() ?? 0;
      final name = (line.product['name'] ?? 'Producto').toString();

      if (line.quantity > stock) {
        return 'No hay stock suficiente para $name. Stock disponible: $stock. Cantidad seleccionada: ${line.quantity}.';
      }
    }

    return null;
  }

  Future<void> _addProduct() async {
    if (widget.products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay productos disponibles para añadir.'),
        ),
      );
      return;
    }

    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _SelectProductSheet(
          products: widget.products,
        );
      },
    );

    if (selected == null) return;

    final productId = (selected['id'] as num).toInt();

    final existingIndex = lines.indexWhere((line) {
      final currentId = (line.product['id'] as num).toInt();
      return currentId == productId;
    });

    setState(() {
      if (existingIndex == -1) {
        lines.add(
          _OrderLineDraft(
            product: selected,
            quantity: 1,
          ),
        );
      } else {
        lines[existingIndex].quantity++;
      }
    });
  }

  Future<void> _createOrder() async {
    if (selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes seleccionar un cliente.'),
        ),
      );
      return;
    }

    if (lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes añadir al menos un producto al pedido.'),
        ),
      );
      return;
    }

    if (hasStockProblems) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            stockProblemMessage ?? 'Hay productos con stock insuficiente.',
          ),
        ),
      );
      return;
    }

    setState(() {
      saving = true;
    });

    try {
      final requestLines = lines.map((line) {
        return {
          'productId': (line.product['id'] as num).toInt(),
          'quantity': line.quantity,
        };
      }).toList();

      await widget.api.createOrder(
        customerId: selectedCustomerId!,
        lines: requestLines,
      );

      if (!mounted) return;

      Navigator.pop(context, true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pedido creado correctamente'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
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

  void _increase(_OrderLineDraft line) {
    setState(() {
      line.quantity++;
    });
  }

  void _decrease(_OrderLineDraft line) {
    setState(() {
      if (line.quantity > 1) {
        line.quantity--;
      }
    });
  }

  void _remove(_OrderLineDraft line) {
    setState(() {
      lines.remove(line);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    final customer = selectedCustomer;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.94,
        decoration: const BoxDecoration(
          color: Color(0xFFF4F8FC),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(32),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                  children: [
                    Container(
                      width: 44,
                      height: 5,
                      margin: const EdgeInsets.only(
                        left: 145,
                        right: 145,
                        bottom: 18,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),

                    _CreateOrderHeader(
                      onBack: () => Navigator.pop(context, false),
                    ),

                    const SizedBox(height: 18),

                    const _SectionHeader(
                      title: 'Cliente',
                      subtitle: 'Selecciona el cliente asociado al pedido',
                    ),

                    const SizedBox(height: 10),

                    _InputCard(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: selectedCustomerId,
                          isExpanded: true,
                          hint: const Text('Selecciona un cliente'),
                          items: widget.customers.map((item) {
                            final customer = item as Map<String, dynamic>;
                            final id = (customer['id'] as num).toInt();
                            final name =
                            (customer['name'] ?? 'Cliente').toString();

                            return DropdownMenuItem<int>(
                              value: id,
                              child: Text('$name (#$id)'),
                            );
                          }).toList(),
                          onChanged: saving
                              ? null
                              : (value) {
                            setState(() {
                              selectedCustomerId = value;
                            });
                          },
                        ),
                      ),
                    ),

                    if (customer != null) ...[
                      const SizedBox(height: 10),
                      _SelectedCustomerCard(customer: customer),
                    ],

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        const Expanded(
                          child: _SectionHeader(
                            title: 'Productos',
                            subtitle: 'Añade líneas al pedido',
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: saving ? null : _addProduct,
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
                      ],
                    ),

                    const SizedBox(height: 12),

                    if (lines.isEmpty)
                      const _EmptyLinesCard()
                    else
                      ...lines.map((line) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _DraftLineCard(
                            line: line,
                            onIncrease: () => _increase(line),
                            onDecrease: () => _decrease(line),
                            onRemove: () => _remove(line),
                          ),
                        );
                      }),

                    if (hasStockProblems) ...[
                      const SizedBox(height: 4),
                      _StockWarningCard(
                        message: stockProblemMessage ??
                            'Hay productos con stock insuficiente.',
                      ),
                    ],

                    const SizedBox(height: 12),

                    _OrderTotalCard(
                      total: total,
                      totalUnits: totalUnits,
                    ),

                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton.icon(
                        onPressed:
                        saving || hasStockProblems ? null : _createOrder,
                        style: FilledButton.styleFrom(
                          backgroundColor: cs.primary,
                          foregroundColor: cs.onPrimary,
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
                          hasStockProblems
                              ? Icons.warning_amber_rounded
                              : Icons.check_rounded,
                        ),
                        label: Text(
                          hasStockProblems ? 'Corrige el stock' : 'Crear pedido',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderLineDraft {
  final Map<String, dynamic> product;
  int quantity;

  _OrderLineDraft({
    required this.product,
    required this.quantity,
  });
}

/* ---------------- Detalle Pedido ---------------- */

class OrderDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  final ApiClient api;

  const OrderDetailsScreen({
    super.key,
    required this.order,
    required this.api,
  });

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late Map<String, dynamic> order;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    order = Map<String, dynamic>.from(widget.order);
  }

  Future<void> _changeStatus(String status) async {
    final id = (order['id'] as num).toInt();

    setState(() {
      saving = true;
    });

    try {
      final updated = await widget.api.patchOrderStatus(
        id,
        status,
      );

      if (!mounted) return;

      setState(() {
        order = updated;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Estado actualizado a ${_statusLabel(status)}'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
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

  @override
  Widget build(BuildContext context) {
    final id = (order['id'] ?? '').toString();
    final status = _status(order);
    final customerName = _customerName(order);
    final lines = _lines(order);
    final total = _orderTotal(order);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 130),
          children: [
            _OrderDetailsHeader(
              id: id,
              status: status,
              onBack: () => Navigator.pop(context, true),
            ),

            const SizedBox(height: 18),

            _OrderCustomerCard(
              customerName: customerName,
              order: order,
            ),

            const SizedBox(height: 22),

            const _SectionHeader(
              title: 'Productos del pedido',
              subtitle: 'Detalle de líneas, cantidades e importes',
            ),

            const SizedBox(height: 12),

            if (lines.isEmpty)
              const _EmptyLinesCard()
            else
              ...lines.map((line) {
                final map = line as Map<String, dynamic>;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _OrderLineCard(
                    line: map,
                  ),
                );
              }),

            const SizedBox(height: 12),

            _OrderTotalCard(
              total: total,
              totalUnits: _orderUnits(order),
            ),

            const SizedBox(height: 24),

            const _SectionHeader(
              title: 'Estado del pedido',
              subtitle: 'Actualiza el estado de la operación',
            ),

            const SizedBox(height: 12),

            _StatusActionsCard(
              currentStatus: status,
              saving: saving,
              onChange: _changeStatus,
            ),
          ],
        ),
      ),
    );
  }
}

/* ---------------- Seleccionar Producto ---------------- */

class _SelectProductSheet extends StatefulWidget {
  final List<dynamic> products;

  const _SelectProductSheet({
    required this.products,
  });

  @override
  State<_SelectProductSheet> createState() => _SelectProductSheetState();
}

class _SelectProductSheetState extends State<_SelectProductSheet> {
  String q = '';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final filtered = widget.products.where((item) {
      final product = item as Map<String, dynamic>;
      final name = (product['name'] ?? '').toString().toLowerCase();

      if (q.trim().isEmpty) return true;

      return name.contains(q.trim().toLowerCase());
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
      decoration: const BoxDecoration(
        color: Color(0xFFF4F8FC),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
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
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.inventory_2_rounded,
                    color: cs.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 13),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Añadir producto',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Selecciona un producto para el pedido',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            _SearchBox(
              onChanged: (value) {
                setState(() {
                  q = value;
                });
              },
            ),

            const SizedBox(height: 14),

            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                child: Text('No se encontraron productos'),
              )
                  : ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final product =
                  filtered[index] as Map<String, dynamic>;

                  return _SelectableProductCard(
                    product: product,
                    onTap: () => Navigator.pop(context, product),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ---------------- UI Principal ---------------- */

class _OrdersHeader extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final VoidCallback onCreate;

  const _OrdersHeader({
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
                  Icons.receipt_long_rounded,
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
                      'Pedidos',
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
                      'Operaciones de venta',
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
            'Crea pedidos, selecciona clientes, añade productos y controla el estado de cada operación.',
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
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Añadir nuevo pedido',
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

class _CreateOrderHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _CreateOrderHeader({
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF061A2D),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
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
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Crear operación de venta',
                  style: TextStyle(
                    color: Color(0xFFB7C8D8),
                    fontSize: 13,
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

class _OrderDetailsHeader extends StatelessWidget {
  final String id;
  final String status;
  final VoidCallback onBack;

  const _OrderDetailsHeader({
    required this.id,
    required this.status,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final statusData = _statusData(status);

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
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pedido #$id',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Detalle de operación',
                      style: TextStyle(
                        color: Color(0xFFB7C8D8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: statusData.background,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  statusData.icon,
                  color: statusData.color,
                  size: 18,
                ),
                const SizedBox(width: 7),
                Text(
                  statusData.label,
                  style: TextStyle(
                    color: statusData.color,
                    fontWeight: FontWeight.w900,
                    fontSize: 12.5,
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
        hintText: 'Buscar pedido, cliente o estado...',
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

class _OrdersSummaryCard extends StatelessWidget {
  final int total;
  final int visible;
  final int pending;
  final int completed;
  final int cancelled;

  const _OrdersSummaryCard({
    required this.total,
    required this.visible,
    required this.pending,
    required this.completed,
    required this.cancelled,
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
    final base = total == visible
        ? 'Tienes $total pedidos registrados.'
        : 'Mostrando $visible de $total pedidos.';

    return '$base Pendientes: $pending, completados: $completed, cancelados: $cancelled.';
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onTap;

  const _OrderCard({
    required this.order,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final id = (order['id'] ?? '').toString();
    final customerName = _customerName(order);
    final status = _status(order);
    final statusData = _statusData(status);
    final total = _orderTotal(order);
    final units = _orderUnits(order);
    final createdAt = _createdAtText(order);

    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: onTap,
      child: Container(
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
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: statusData.background,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                statusData.icon,
                color: statusData.color,
                size: 29,
              ),
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
                          'Pedido #$id',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      _StatusBadge(status: status),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    customerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _MiniBadge(
                        icon: Icons.inventory_2_rounded,
                        text: '$units palets',
                      ),
                      _MiniBadge(
                        icon: Icons.euro_rounded,
                        text: '${total.toStringAsFixed(2)} €',
                      ),
                      if (createdAt.isNotEmpty)
                        _MiniBadge(
                          icon: Icons.schedule_rounded,
                          text: createdAt,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedCustomerCard extends StatelessWidget {
  final Map<String, dynamic> customer;

  const _SelectedCustomerCard({
    required this.customer,
  });

  @override
  Widget build(BuildContext context) {
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
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.45),
        ),
      ),
      child: Row(
        children: [
          _CustomerAvatar(
            name: name,
            imageUrl: imageUrl,
            size: 56,
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
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
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

class _SelectableProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onTap;

  const _SelectableProductCard({
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = (product['name'] ?? 'Producto').toString();
    final imageUrl = (product['imageUrl'] ?? '').toString();
    final price = (product['price'] as num?)?.toDouble() ?? 0.0;
    final stock = (product['stock'] as num?)?.toInt() ?? 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color:
            Theme.of(context).colorScheme.outlineVariant.withOpacity(0.45),
          ),
        ),
        child: Row(
          children: [
            _ProductImage(
              name: name,
              imageUrl: imageUrl,
              size: 56,
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
                      fontSize: 15,
                    ),
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
                        icon: Icons.euro_rounded,
                        text: '${price.toStringAsFixed(2)} €',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _DraftLineCard extends StatelessWidget {
  final _OrderLineDraft line;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onRemove;

  const _DraftLineCard({
    required this.line,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final product = line.product;

    final name = (product['name'] ?? 'Producto').toString();
    final imageUrl = (product['imageUrl'] ?? '').toString();
    final price = (product['price'] as num?)?.toDouble() ?? 0.0;
    final stock = (product['stock'] as num?)?.toInt() ?? 0;
    final lineTotal = price * line.quantity;

    final hasStockProblem = line.quantity > stock;

    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: hasStockProblem
              ? cs.error.withOpacity(0.45)
              : cs.outlineVariant.withOpacity(0.45),
        ),
        boxShadow: [
          if (hasStockProblem)
            BoxShadow(
              color: cs.error.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
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
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${price.toStringAsFixed(2)} € / palet',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
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
                      icon: Icons.euro_rounded,
                      text: 'Total: ${lineTotal.toStringAsFixed(2)} €',
                    ),
                  ],
                ),
                if (hasStockProblem) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: cs.errorContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: cs.onErrorContainer,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Stock insuficiente. Disponible: $stock.',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: cs.onErrorContainer,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  _QtyButton(
                    icon: Icons.remove_rounded,
                    onTap: onDecrease,
                  ),
                  SizedBox(
                    width: 34,
                    child: Text(
                      line.quantity.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: hasStockProblem ? cs.error : cs.onSurface,
                      ),
                    ),
                  ),
                  _QtyButton(
                    icon: Icons.add_rounded,
                    onTap: onIncrease,
                  ),
                ],
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_rounded),
                color: Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StockWarningCard extends StatelessWidget {
  final String message;

  const _StockWarningCard({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: cs.error.withOpacity(0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_rounded,
            color: cs.onErrorContainer,
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: cs.onErrorContainer,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderLineCard extends StatelessWidget {
  final Map<String, dynamic> line;

  const _OrderLineCard({
    required this.line,
  });

  @override
  Widget build(BuildContext context) {
    final product = (line['product'] as Map<String, dynamic>?) ?? {};
    final name = (product['name'] ?? 'Producto').toString();
    final imageUrl = (product['imageUrl'] ?? '').toString();
    final price = (product['price'] as num?)?.toDouble() ?? 0.0;
    final quantity = (line['quantity'] as num?)?.toInt() ?? 0;
    final total = price * quantity;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.45),
        ),
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
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _MiniBadge(
                      icon: Icons.inventory_2_rounded,
                      text: 'Cantidad: $quantity',
                    ),
                    _MiniBadge(
                      icon: Icons.euro_rounded,
                      text: '${total.toStringAsFixed(2)} €',
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

class _OrderCustomerCard extends StatelessWidget {
  final String customerName;
  final Map<String, dynamic> order;

  const _OrderCustomerCard({
    required this.customerName,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    final customer = (order['customer'] as Map<String, dynamic>?) ?? {};
    final imageUrl = (customer['imageUrl'] ?? '').toString();

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.45),
        ),
      ),
      child: Row(
        children: [
          _CustomerAvatar(
            name: customerName,
            imageUrl: imageUrl,
            size: 58,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cliente',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  customerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
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

class _OrderTotalCard extends StatelessWidget {
  final double total;
  final int totalUnits;

  const _OrderTotalCard({
    required this.total,
    required this.totalUnits,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF061A2D),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
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
                    fontSize: 16,
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
              horizontal: 13,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${total.toStringAsFixed(2)} €',
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

class _StatusActionsCard extends StatelessWidget {
  final String currentStatus;
  final bool saving;
  final ValueChanged<String> onChange;

  const _StatusActionsCard({
    required this.currentStatus,
    required this.saving,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _StatusActionButton(
          title: 'Pendiente',
          subtitle: 'El pedido sigue abierto',
          status: 'PENDING',
          currentStatus: currentStatus,
          icon: Icons.pending_actions_rounded,
          saving: saving,
          onChange: onChange,
        ),
        const SizedBox(height: 10),
        _StatusActionButton(
          title: 'Completado',
          subtitle: 'El pedido ya ha sido finalizado',
          status: 'COMPLETED',
          currentStatus: currentStatus,
          icon: Icons.check_circle_rounded,
          saving: saving,
          onChange: onChange,
        ),
        const SizedBox(height: 10),
        _StatusActionButton(
          title: 'Cancelado',
          subtitle: 'El pedido no se realizará',
          status: 'CANCELLED',
          currentStatus: currentStatus,
          icon: Icons.cancel_rounded,
          saving: saving,
          onChange: onChange,
        ),
      ],
    );
  }
}

class _StatusActionButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  final String currentStatus;
  final IconData icon;
  final bool saving;
  final ValueChanged<String> onChange;

  const _StatusActionButton({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.currentStatus,
    required this.icon,
    required this.saving,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final selected = status == currentStatus;
    final data = _statusData(status);
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: saving || selected ? null : () => onChange(status),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: selected ? data.background : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected
                ? data.color.withOpacity(0.35)
                : cs.outlineVariant.withOpacity(0.45),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: data.color,
              size: 28,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: selected ? data.color : cs.onSurface,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(
                Icons.check_rounded,
                color: data.color,
              ),
          ],
        ),
      ),
    );
  }
}

/* ---------------- Componentes comunes ---------------- */

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

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final data = _statusData(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: data.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        data.label,
        style: TextStyle(
          color: data.color,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
        ),
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: cs.onPrimaryContainer,
          size: 19,
        ),
      ),
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
    final initial = name.trim().isEmpty
        ? '?'
        : name.trim().characters.first.toUpperCase();

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
            size: 42,
            color: cs.primary,
          ),
          const SizedBox(height: 10),
          const Text(
            'Sin productos añadidos',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15.5,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Añade productos para crear el pedido.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyOrdersCard extends StatelessWidget {
  const _EmptyOrdersCard();

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
            Icons.receipt_long_outlined,
            size: 46,
            color: cs.primary,
          ),
          const SizedBox(height: 12),
          const Text(
            'No se encontraron pedidos',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Prueba con otra búsqueda o crea un nuevo pedido.',
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
      height: 104,
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

/* ---------------- Helpers ---------------- */

String _status(Map<String, dynamic> order) {
  return (order['status'] ?? 'PENDING').toString();
}

String _customerName(Map<String, dynamic> order) {
  final customer = order['customer'];

  if (customer is Map<String, dynamic>) {
    return (customer['name'] ?? 'Cliente').toString();
  }

  return 'Cliente';
}

List<dynamic> _lines(Map<String, dynamic> order) {
  final lines = order['lines'];

  if (lines is List<dynamic>) {
    return lines;
  }

  if (order['orderLines'] is List<dynamic>) {
    return order['orderLines'] as List<dynamic>;
  }

  return [];
}

double _orderTotal(Map<String, dynamic> order) {
  final directTotal = order['total'];

  if (directTotal is num) {
    return directTotal.toDouble();
  }

  double result = 0;

  for (final item in _lines(order)) {
    final line = item as Map<String, dynamic>;
    final product = (line['product'] as Map<String, dynamic>?) ?? {};
    final price = (product['price'] as num?)?.toDouble() ?? 0.0;
    final quantity = (line['quantity'] as num?)?.toInt() ?? 0;

    result += price * quantity;
  }

  return result;
}

int _orderUnits(Map<String, dynamic> order) {
  int result = 0;

  for (final item in _lines(order)) {
    final line = item as Map<String, dynamic>;
    final quantity = (line['quantity'] as num?)?.toInt() ?? 0;

    result += quantity;
  }

  return result;
}

String _createdAtText(Map<String, dynamic> order) {
  final raw = order['createdAt']?.toString();

  if (raw == null || raw.isEmpty) return '';

  try {
    final date = DateTime.parse(raw);

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month $hour:$minute';
  } catch (_) {
    return raw;
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'COMPLETED':
      return 'Completado';
    case 'CANCELLED':
      return 'Cancelado';
    case 'PENDING':
    default:
      return 'Pendiente';
  }
}

_StatusData _statusData(String status) {
  switch (status) {
    case 'COMPLETED':
      return const _StatusData(
        label: 'Completado',
        icon: Icons.check_circle_rounded,
        color: Color(0xFF009688),
        background: Color(0xFFE6F7F5),
      );
    case 'CANCELLED':
      return const _StatusData(
        label: 'Cancelado',
        icon: Icons.cancel_rounded,
        color: Color(0xFFD32F2F),
        background: Color(0xFFFFEBEE),
      );
    case 'PENDING':
    default:
      return const _StatusData(
        label: 'Pendiente',
        icon: Icons.pending_actions_rounded,
        color: Color(0xFFFF8A00),
        background: Color(0xFFFFF4E5),
      );
  }
}

class _StatusData {
  final String label;
  final IconData icon;
  final Color color;
  final Color background;

  const _StatusData({
    required this.label,
    required this.icon,
    required this.color,
    required this.background,
  });
}