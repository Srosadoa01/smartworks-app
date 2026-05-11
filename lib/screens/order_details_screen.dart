import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../config.dart';
import '../data/product_images.dart';

class OrderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderDetailScreen({
    super.key,
    required this.order,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final api = ApiClient();

  late Map<String, dynamic> order;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    order = Map<String, dynamic>.from(widget.order);
  }

  int get _orderId {
    return (order['id'] as num).toInt();
  }

  List<dynamic> get _lines {
    return (order['lines'] as List<dynamic>?) ?? [];
  }

  int get _totalUnits {
    return _lines.fold<int>(0, (acc, item) {
      final line = item as Map<String, dynamic>;
      return acc + ((line['quantity'] as num?)?.toInt() ?? 0);
    });
  }

  double get _totalAmount {
    return _lines.fold<double>(0.0, (acc, item) {
      final line = item as Map<String, dynamic>;
      final qty = (line['quantity'] as num?)?.toInt() ?? 0;

      final product = line['product'] as Map<String, dynamic>?;
      final price = (product?['price'] as num?)?.toDouble() ?? 0.0;

      return acc + (qty * price);
    });
  }

  Future<void> _setStatus(String status) async {
    setState(() {
      saving = true;
    });

    try {
      final updated = await api.patchOrderStatus(_orderId, status);

      setState(() {
        order = updated;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Estado actualizado a ${_statusInfo(status).label}'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error actualizando estado: $e'),
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

  String _formatDate(String value) {
    if (value.isEmpty) return 'Sin fecha';

    final clean = value.replaceAll('T', ' ');

    if (clean.length >= 16) {
      return clean.substring(0, 16);
    }

    return clean;
  }

  @override
  Widget build(BuildContext context) {
    final customer = order['customer'] as Map<String, dynamic>?;

    final customerName = (customer?['name'] ?? 'Cliente').toString();
    final customerPhone = (customer?['phone'] ?? '').toString();
    final customerEmail = (customer?['email'] ?? '').toString();
    final customerImageUrl = (customer?['imageUrl'] ?? '').toString();

    final status = (order['status'] ?? 'PENDING').toString();
    final createdAt = _formatDate((order['createdAt'] ?? '').toString());

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 150),
          children: [
            _OrderDetailHeader(
              orderId: _orderId,
              status: status,
              createdAt: createdAt,
              onBack: () => Navigator.pop(context),
            ),

            const SizedBox(height: 16),

            _CustomerCard(
              name: customerName,
              phone: customerPhone,
              email: customerEmail,
              imageUrl: customerImageUrl,
            ),

            const SizedBox(height: 16),

            _OrderResumeCard(
              totalUnits: _totalUnits,
              totalAmount: _totalAmount,
              totalLines: _lines.length,
            ),

            const SizedBox(height: 24),

            const _SectionHeader(
              title: 'Líneas del pedido',
              subtitle: 'Productos incluidos en esta operación',
            ),

            const SizedBox(height: 12),

            if (_lines.isEmpty)
              const _EmptyLinesCard()
            else
              Column(
                children: _lines.map((item) {
                  final line = item as Map<String, dynamic>;

                  final product = line['product'] as Map<String, dynamic>?;

                  final productName =
                  (product?['name'] ?? 'Producto').toString();

                  final productImageUrl =
                  (product?['imageUrl'] ?? '').toString();

                  final quantity =
                      (line['quantity'] as num?)?.toInt() ?? 0;

                  final unitPrice =
                      (product?['price'] as num?)?.toDouble() ?? 0.0;

                  final lineTotal = unitPrice * quantity;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _LineCard(
                      productName: productName,
                      productImageUrl: productImageUrl,
                      quantity: quantity,
                      unitPrice: unitPrice,
                      total: lineTotal,
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 24),

            const _SectionHeader(
              title: 'Cambiar estado',
              subtitle: 'Actualiza el estado actual del pedido',
            ),

            const SizedBox(height: 12),

            _StatusActionsCard(
              currentStatus: status,
              saving: saving,
              onPending: () => _setStatus('PENDING'),
              onCompleted: () => _setStatus('COMPLETED'),
              onCancelled: () => _setStatus('CANCELLED'),
            ),
          ],
        ),
      ),
    );
  }
}

/* ---------------- UI Detalle Pedido ---------------- */

class _OrderDetailHeader extends StatelessWidget {
  final int orderId;
  final String status;
  final String createdAt;
  final VoidCallback onBack;

  const _OrderDetailHeader({
    required this.orderId,
    required this.status,
    required this.createdAt,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final info = _statusInfo(status);

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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pedido #$orderId',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      createdAt,
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
            ],
          ),

          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: info.background,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  info.icon,
                  color: info.color,
                  size: 18,
                ),
                const SizedBox(width: 7),
                Text(
                  info.label,
                  style: TextStyle(
                    color: info.color,
                    fontWeight: FontWeight.w900,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'Consulta el cliente, productos incluidos y cambia el estado del pedido cuando sea necesario.',
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

class _CustomerCard extends StatelessWidget {
  final String name;
  final String phone;
  final String email;
  final String imageUrl;

  const _CustomerCard({
    required this.name,
    required this.phone,
    required this.email,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
            size: 58,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cliente',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
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
                const SizedBox(height: 7),
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

class _OrderResumeCard extends StatelessWidget {
  final int totalUnits;
  final double totalAmount;
  final int totalLines;

  const _OrderResumeCard({
    required this.totalUnits,
    required this.totalAmount,
    required this.totalLines,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: cs.outlineVariant.withOpacity(0.45),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ResumeMetric(
              icon: Icons.list_alt_rounded,
              title: 'Líneas',
              value: totalLines.toString(),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ResumeMetric(
              icon: Icons.inventory_2_rounded,
              title: 'Palets',
              value: totalUnits.toString(),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ResumeMetric(
              icon: Icons.euro_rounded,
              title: 'Total',
              value: totalAmount.toStringAsFixed(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResumeMetric extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _ResumeMetric({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: cs.primary,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              fontSize: 11,
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

class _LineCard extends StatelessWidget {
  final String productName;
  final String productImageUrl;
  final int quantity;
  final double unitPrice;
  final double total;

  const _LineCard({
    required this.productName,
    required this.productImageUrl,
    required this.quantity,
    required this.unitPrice,
    required this.total,
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
            name: productName,
            imageUrl: productImageUrl,
            size: 58,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
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
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
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
                      icon: Icons.inventory_2_rounded,
                      text: 'x$quantity',
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

class _StatusActionsCard extends StatelessWidget {
  final String currentStatus;
  final bool saving;
  final VoidCallback onPending;
  final VoidCallback onCompleted;
  final VoidCallback onCancelled;

  const _StatusActionsCard({
    required this.currentStatus,
    required this.saving,
    required this.onPending,
    required this.onCompleted,
    required this.onCancelled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.45),
        ),
      ),
      child: Column(
        children: [
          _StatusActionButton(
            label: 'Marcar como pendiente',
            icon: Icons.pending_actions_rounded,
            selected: currentStatus == 'PENDING',
            color: const Color(0xFFFF8A00),
            background: const Color(0xFFFFF4E5),
            onTap: saving ? null : onPending,
          ),
          const SizedBox(height: 10),
          _StatusActionButton(
            label: 'Marcar como completado',
            icon: Icons.check_circle_rounded,
            selected: currentStatus == 'COMPLETED',
            color: const Color(0xFF009688),
            background: const Color(0xFFE6F7F5),
            onTap: saving ? null : onCompleted,
          ),
          const SizedBox(height: 10),
          _StatusActionButton(
            label: 'Marcar como cancelado',
            icon: Icons.cancel_rounded,
            selected: currentStatus == 'CANCELLED',
            color: const Color(0xFFD32F2F),
            background: const Color(0xFFFFEBEE),
            onTap: saving ? null : onCancelled,
          ),
        ],
      ),
    );
  }
}

class _StatusActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final Color background;
  final VoidCallback? onTap;

  const _StatusActionButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.background,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? background : const Color(0xFFF4F8FC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? color.withOpacity(0.35) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? color : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? color : cs.onSurfaceVariant,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (selected)
              Icon(
                Icons.check_rounded,
                color: color,
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusInfo {
  final String label;
  final IconData icon;
  final Color color;
  final Color background;

  const _StatusInfo({
    required this.label,
    required this.icon,
    required this.color,
    required this.background,
  });
}

_StatusInfo _statusInfo(String status) {
  switch (status) {
    case 'COMPLETED':
      return const _StatusInfo(
        label: 'Completado',
        icon: Icons.check_circle_rounded,
        color: Color(0xFF009688),
        background: Color(0xFFE6F7F5),
      );
    case 'CANCELLED':
      return const _StatusInfo(
        label: 'Cancelado',
        icon: Icons.cancel_rounded,
        color: Color(0xFFD32F2F),
        background: Color(0xFFFFEBEE),
      );
    default:
      return const _StatusInfo(
        label: 'Pendiente',
        icon: Icons.pending_actions_rounded,
        color: Color(0xFFFF8A00),
        background: Color(0xFFFFF4E5),
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
            Icons.receipt_long_outlined,
            size: 44,
            color: cs.primary,
          ),
          const SizedBox(height: 12),
          const Text(
            'Este pedido no tiene líneas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'No hay productos asociados a este pedido.',
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