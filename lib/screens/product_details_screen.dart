import 'package:flutter/material.dart';

import '../config.dart';
import '../data/product_images.dart';

class ProductDetailScreen extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final name = (product['name'] ?? 'Producto').toString();
    final imageUrl = (product['imageUrl'] ?? '').toString();

    final stock = (product['stock'] as num?)?.toInt() ?? 0;
    final lowStockThreshold =
        (product['lowStockThreshold'] as num?)?.toInt() ?? 0;
    final price = (product['price'] as num?)?.toDouble() ?? 0.0;

    final status = _productStatus(
      stock: stock,
      lowStockThreshold: lowStockThreshold,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 150),
          children: [
            _ProductDetailHeader(
              name: name,
              status: status,
              onBack: () => Navigator.pop(context),
            ),

            const SizedBox(height: 16),

            _ProductHeroImage(
              name: name,
              imageUrl: imageUrl,
              status: status,
            ),

            const SizedBox(height: 18),

            _ProductInfoCard(
              name: name,
              status: status,
            ),

            const SizedBox(height: 22),

            const _SectionHeader(
              title: 'Datos del producto',
              subtitle: 'Información principal del inventario',
            ),

            const SizedBox(height: 12),

            _MetricWideCard(
              title: 'Stock disponible',
              value: stock.toString(),
              subtitle: 'Palets disponibles actualmente en inventario',
              icon: Icons.warehouse_rounded,
              color: status.color,
              background: status.background,
            ),

            const SizedBox(height: 12),

            _MetricWideCard(
              title: 'Umbral de stock bajo',
              value: lowStockThreshold.toString(),
              subtitle: 'Cuando el stock sea igual o inferior a este valor, se mostrará alerta',
              icon: Icons.warning_amber_rounded,
              color: const Color(0xFFFF8A00),
              background: const Color(0xFFFFF4E5),
            ),

            const SizedBox(height: 12),

            _PriceCard(
              price: price,
            ),

            const SizedBox(height: 24),

            const _SectionHeader(
              title: 'Recomendación',
              subtitle: 'Acción sugerida según el estado actual',
            ),

            const SizedBox(height: 12),

            _RecommendationCard(
              stock: stock,
              lowStockThreshold: lowStockThreshold,
              status: status,
            ),
          ],
        ),
      ),
    );
  }
}

/* ---------------- UI Detalle Producto ---------------- */

class _ProductDetailHeader extends StatelessWidget {
  final String name;
  final _ProductStatus status;
  final VoidCallback onBack;

  const _ProductDetailHeader({
    required this.name,
    required this.status,
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
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Detalle del producto',
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

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: status.background,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  status.icon,
                  color: status.color,
                  size: 18,
                ),
                const SizedBox(width: 7),
                Text(
                  status.label,
                  style: TextStyle(
                    color: status.color,
                    fontWeight: FontWeight.w900,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'Consulta la imagen, stock, umbral de alerta, precio y estado actual del producto.',
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

class _ProductHeroImage extends StatelessWidget {
  final String name;
  final String imageUrl;
  final _ProductStatus status;

  const _ProductHeroImage({
    required this.name,
    required this.imageUrl,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
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
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: _ProductImage(
                name: name,
                imageUrl: imageUrl,
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: status.background,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    status.icon,
                    color: status.color,
                    size: 16,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    status.shortLabel,
                    style: TextStyle(
                      color: status.color,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductInfoCard extends StatelessWidget {
  final String name;
  final _ProductStatus status;

  const _ProductInfoCard({
    required this.name,
    required this.status,
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
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: status.background,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              status.icon,
              color: status.color,
              size: 29,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  status.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 12.5,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
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

class _MetricWideCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color background;

  const _MetricWideCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.background,
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
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(19),
            ),
            child: Icon(
              icon,
              color: color,
              size: 29,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15.5,
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
                    fontSize: 12.3,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            constraints: const BoxConstraints(
              minWidth: 54,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  final double price;

  const _PriceCard({
    required this.price,
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
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.euro_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Precio por palet',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Valor registrado en inventario',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
              '${price.toStringAsFixed(2)} €',
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

class _RecommendationCard extends StatelessWidget {
  final int stock;
  final int lowStockThreshold;
  final _ProductStatus status;

  const _RecommendationCard({
    required this.stock,
    required this.lowStockThreshold,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final recommendation = _recommendationText(
      stock: stock,
      lowStockThreshold: lowStockThreshold,
    );

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
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: status.background,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.lightbulb_rounded,
              color: status.color,
              size: 29,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              recommendation,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 13,
                height: 1.3,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _recommendationText({
    required int stock,
    required int lowStockThreshold,
  }) {
    if (stock <= 0) {
      return 'Este producto está sin stock. Es recomendable reponerlo cuanto antes si sigue teniendo demanda.';
    }

    if (stock <= lowStockThreshold) {
      return 'Este producto está por debajo o igual al umbral definido. Conviene revisarlo y preparar reposición.';
    }

    return 'El producto tiene stock suficiente. No requiere ninguna acción inmediata.';
  }
}

class _ProductImage extends StatelessWidget {
  final String name;
  final String imageUrl;

  const _ProductImage({
    required this.name,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = _resolveImageUrl(imageUrl);

    if (resolvedUrl.isNotEmpty) {
      return Image.network(
        resolvedUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return _AssetProductImage(name: name);
        },
      );
    }

    return _AssetProductImage(name: name);
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

  const _AssetProductImage({
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    final img = productImageFor(name);

    return Image.asset(
      img,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) {
        return Image.asset(
          fallbackProductImage,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
        );
      },
    );
  }
}

/* ---------------- Helpers ---------------- */

class _ProductStatus {
  final String label;
  final String shortLabel;
  final String description;
  final IconData icon;
  final Color color;
  final Color background;

  const _ProductStatus({
    required this.label,
    required this.shortLabel,
    required this.description,
    required this.icon,
    required this.color,
    required this.background,
  });
}

_ProductStatus _productStatus({
  required int stock,
  required int lowStockThreshold,
}) {
  if (stock <= 0) {
    return const _ProductStatus(
      label: 'Producto sin stock',
      shortLabel: 'Sin stock',
      description: 'No hay unidades disponibles actualmente.',
      icon: Icons.remove_shopping_cart_rounded,
      color: Color(0xFFD32F2F),
      background: Color(0xFFFFEBEE),
    );
  }

  if (stock <= lowStockThreshold) {
    return const _ProductStatus(
      label: 'Producto con stock bajo',
      shortLabel: 'Stock bajo',
      description: 'El producto está por debajo del nivel recomendado.',
      icon: Icons.warning_amber_rounded,
      color: Color(0xFFFF8A00),
      background: Color(0xFFFFF4E5),
    );
  }

  return const _ProductStatus(
    label: 'Producto disponible',
    shortLabel: 'Disponible',
    description: 'El producto tiene stock suficiente en inventario.',
    icon: Icons.check_circle_rounded,
    color: Color(0xFF009688),
    background: Color(0xFFE6F7F5),
  );
}