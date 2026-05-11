import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/api_client.dart';
import '../config.dart';
import '../data/product_images.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final api = ApiClient();

  int? year;
  int? month;

  late Future<Map<String, dynamic>> future;
  bool generatingPdf = false;

  @override
  void initState() {
    super.initState();
    future = api.getMonthlyAnalytics();
  }

  Future<void> refresh() async {
    setState(() {
      future = api.getMonthlyAnalytics(
        year: year,
        month: month,
      );
    });

    await future;
  }

  Future<void> _generatePdf() async {
    setState(() {
      generatingPdf = true;
    });

    try {
      final report = await api.generateMonthlyReport(
        year: year,
        month: month,
      );

      final id = (report['id'] as num).toInt();
      final url = api.reportDownloadUrl(id);
      final uri = Uri.parse(url);

      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reporte generado correctamente'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generando PDF: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          generatingPdf = false;
        });
      }
    }
  }

  Future<void> _openMonthDialog() async {
    final now = DateTime.now();

    final initial = DateTime(
      year ?? now.year,
      month ?? now.month,
      1,
    );

    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        int selectedYear = initial.year;
        int selectedMonth = initial.month;

        return StatefulBuilder(
          builder: (context, setLocal) {
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
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(
                            Icons.calendar_month_rounded,
                            color: cs.onPrimaryContainer,
                            size: 29,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Seleccionar periodo',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Elige el mes y año para analizar.',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 13,
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _InputCard(
                      child: Column(
                        children: [
                          DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: selectedYear,
                              isExpanded: true,
                              items: List.generate(5, (i) {
                                final value = now.year - i;

                                return DropdownMenuItem<int>(
                                  value: value,
                                  child: Text(value.toString()),
                                );
                              }),
                              onChanged: (value) {
                                if (value == null) return;

                                setLocal(() {
                                  selectedYear = value;
                                });
                              },
                            ),
                          ),
                          const Divider(height: 1),
                          DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: selectedMonth,
                              isExpanded: true,
                              items: List.generate(12, (i) {
                                final value = i + 1;

                                return DropdownMenuItem<int>(
                                  value: value,
                                  child: Text(
                                    '${value.toString().padLeft(2, '0')} · ${_monthName(value)}',
                                  ),
                                );
                              }),
                              onChanged: (value) {
                                if (value == null) return;

                                setLocal(() {
                                  selectedMonth = value;
                                });
                              },
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
                              onPressed: () => Navigator.pop(context),
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
                                Navigator.pop(
                                  context,
                                  DateTime(
                                    selectedYear,
                                    selectedMonth,
                                    1,
                                  ),
                                );
                              },
                              style: FilledButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              icon: const Icon(Icons.check_rounded),
                              label: const Text(
                                'Aplicar',
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
      },
    );

    if (picked == null) return;

    setState(() {
      year = picked.year;
      month = picked.month;
      future = api.getMonthlyAnalytics(
        year: year,
        month: month,
      );
    });
  }

  void _clearMonthFilter() {
    setState(() {
      year = null;
      month = null;
      future = api.getMonthlyAnalytics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: FutureBuilder<Map<String, dynamic>>(
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
                _AnalyticsHeader(
                  onRefresh: refresh,
                ),

                const SizedBox(height: 16),

                _MonthSelectorCard(
                  year: year,
                  month: month,
                  onChange: _openMonthDialog,
                  onClear: _clearMonthFilter,
                ),

                const SizedBox(height: 18),

                if (loading) ...[
                  const _LoadingCard(height: 138),
                  const SizedBox(height: 12),
                  const _LoadingCard(height: 250),
                  const SizedBox(height: 12),
                  const _LoadingCard(height: 300),
                ] else if (hasError) ...[
                  _ErrorCard(
                    message:
                    'No se pudo cargar el analizador.\n${snapshot.error}',
                    onRetry: refresh,
                  ),
                ] else ...[
                  Builder(
                    builder: (_) {
                      final data = snapshot.data ?? <String, dynamic>{};

                      final selectedYear =
                          (data['year'] as num?)?.toInt() ??
                              year ??
                              DateTime.now().year;

                      final selectedMonth =
                          (data['month'] as num?)?.toInt() ??
                              month ??
                              DateTime.now().month;

                      final orders =
                          (data['ordersThisMonth'] as num?)?.toInt() ?? 0;

                      final ordersChange = _number(data['ordersChangePct']);

                      final revenue = _number(data['revenueThisMonth']);

                      final revenueChange = _number(data['revenueChangePct']);

                      final units =
                          (data['unitsSoldThisMonth'] as num?)?.toInt() ?? 0;

                      final avgOrderValue =
                      _number(data['avgOrderValueThisMonth']);

                      final avgDeliveryHours =
                      _number(data['avgDeliveryHoursThisMonth']);

                      final avgDeliveryChange =
                      _number(data['avgDeliveryChangePct']);

                      final pending =
                          (data['pendingThisMonth'] as num?)?.toInt() ?? 0;

                      final completed =
                          (data['completedThisMonth'] as num?)?.toInt() ?? 0;

                      final cancelled =
                          (data['cancelledThisMonth'] as num?)?.toInt() ?? 0;

                      final topProducts =
                      (data['topProductsByUnits'] as List<dynamic>? ?? []);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _PeriodResumeCard(
                            year: selectedYear,
                            month: selectedMonth,
                          ),

                          const SizedBox(height: 18),

                          const _SectionHeader(
                            title: 'Indicadores principales',
                            subtitle:
                            'Resumen mensual de ventas y actividad',
                          ),

                          const SizedBox(height: 12),

                          _KpiGrid(
                            items: [
                              _KpiData(
                                title: 'Pedidos',
                                value: orders.toString(),
                                subtitle:
                                '${_formatPercent(ordersChange)} vs mes anterior',
                                icon: Icons.receipt_long_rounded,
                                color: const Color(0xFF1AA6FF),
                                background: const Color(0xFFEAF6FF),
                              ),
                              _KpiData(
                                title: 'Facturación',
                                value: _formatMoney(revenue),
                                subtitle:
                                '${_formatPercent(revenueChange)} vs mes anterior',
                                icon: Icons.euro_rounded,
                                color: const Color(0xFF009688),
                                background: const Color(0xFFE6F7F5),
                              ),
                              _KpiData(
                                title: 'Palets vendidos',
                                value: units.toString(),
                                subtitle: 'Unidades totales',
                                icon: Icons.inventory_2_rounded,
                                color: const Color(0xFFFF8A00),
                                background: const Color(0xFFFFF4E5),
                              ),
                              _KpiData(
                                title: 'Ticket medio',
                                value: _formatMoney(avgOrderValue),
                                subtitle: 'Media por pedido',
                                icon: Icons.paid_rounded,
                                color: const Color(0xFF7C4DFF),
                                background: const Color(0xFFF0EAFF),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          _OrdersStatusChartCard(
                            pending: pending,
                            completed: completed,
                            cancelled: cancelled,
                          ),

                          const SizedBox(height: 24),

                          _TopProductsBarChartCard(
                            products: topProducts,
                          ),

                          const SizedBox(height: 24),

                          _DeliveryCard(
                            avgDeliveryHours: avgDeliveryHours,
                            changePct: avgDeliveryChange,
                          ),

                          const SizedBox(height: 24),

                          _ReportCard(
                            generatingPdf: generatingPdf,
                            onGenerate: _generatePdf,
                          ),
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

/* ---------------- UI Analizador ---------------- */

class _AnalyticsHeader extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _AnalyticsHeader({
    required this.onRefresh,
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
                  Icons.analytics_rounded,
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
                      'Analizador',
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
                      'Métricas y gráficos',
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
            'Consulta ventas, pedidos, productos destacados y genera reportes PDF para tu exposición del TFG.',
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

class _MonthSelectorCard extends StatelessWidget {
  final int? year;
  final int? month;
  final VoidCallback onChange;
  final VoidCallback onClear;

  const _MonthSelectorCard({
    required this.year,
    required this.month,
    required this.onChange,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();

    final currentYear = year ?? now.year;
    final currentMonth = month ?? now.month;
    final isCurrent = year == null || month == null;

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
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.calendar_month_rounded,
              color: cs.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCurrent
                      ? 'Mes actual'
                      : '${_monthName(currentMonth)} $currentYear',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isCurrent
                      ? '${_monthName(currentMonth)} $currentYear'
                      : 'Periodo personalizado aplicado',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              if (value == 'change') {
                onChange();
              } else if (value == 'clear') {
                onClear();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'change',
                child: Text('Cambiar mes'),
              ),
              PopupMenuItem(
                value: 'clear',
                child: Text('Volver al mes actual'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PeriodResumeCard extends StatelessWidget {
  final int year;
  final int month;

  const _PeriodResumeCard({
    required this.year,
    required this.month,
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
              Icons.query_stats_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Periodo analizado',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_monthName(month)} de $year',
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
              '${month.toString().padLeft(2, '0')}/$year',
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

class _KpiData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color background;

  const _KpiData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.background,
  });
}

class _KpiGrid extends StatelessWidget {
  final List<_KpiData> items;

  const _KpiGrid({
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _KpiCard(data: items[0])),
            const SizedBox(width: 12),
            Expanded(child: _KpiCard(data: items[1])),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _KpiCard(data: items[2])),
            const SizedBox(width: 12),
            Expanded(child: _KpiCard(data: items[3])),
          ],
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final _KpiData data;

  const _KpiCard({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      height: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: cs.outlineVariant.withOpacity(0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: data.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              data.icon,
              color: data.color,
              size: 25,
            ),
          ),
          const Spacer(),
          Text(
            data.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            data.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            data.subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 11.2,
              height: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrdersStatusChartCard extends StatelessWidget {
  final int pending;
  final int completed;
  final int cancelled;

  const _OrdersStatusChartCard({
    required this.pending,
    required this.completed,
    required this.cancelled,
  });

  @override
  Widget build(BuildContext context) {
    final total = pending + completed + cancelled;

    return _AnalyticsCard(
      title: 'Estado de pedidos',
      subtitle: 'Distribución mensual por estado',
      icon: Icons.donut_large_rounded,
      child: total == 0
          ? const _EmptyChartCard(
        text: 'Todavía no hay pedidos suficientes para mostrar el gráfico.',
      )
          : Column(
        children: [
          SizedBox(
            height: 230,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 52,
                sectionsSpace: 4,
                sections: [
                  PieChartSectionData(
                    value: pending.toDouble(),
                    title: '${_percent(pending, total)}%',
                    color: const Color(0xFFFF8A00),
                    radius: 68,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                  PieChartSectionData(
                    value: completed.toDouble(),
                    title: '${_percent(completed, total)}%',
                    color: const Color(0xFF009688),
                    radius: 68,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                  PieChartSectionData(
                    value: cancelled.toDouble(),
                    title: '${_percent(cancelled, total)}%',
                    color: const Color(0xFFD32F2F),
                    radius: 68,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _LegendItem(
                  title: 'Pendientes',
                  value: pending,
                  color: const Color(0xFFFF8A00),
                ),
              ),
              Expanded(
                child: _LegendItem(
                  title: 'Completados',
                  value: completed,
                  color: const Color(0xFF009688),
                ),
              ),
              Expanded(
                child: _LegendItem(
                  title: 'Cancelados',
                  value: cancelled,
                  color: const Color(0xFFD32F2F),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _percent(int value, int total) {
    if (total == 0) return 0;
    return ((value / total) * 100).round();
  }
}

class _TopProductsBarChartCard extends StatelessWidget {
  final List<dynamic> products;

  const _TopProductsBarChartCard({
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    final items = products.take(5).map((item) {
      final map = item as Map<String, dynamic>;

      final name = (map['name'] ?? 'Producto').toString();

      final quantity =
          (map['quantity'] as num?)?.toInt() ??
              (map['units'] as num?)?.toInt() ??
              0;

      final imageUrl = (map['imageUrl'] ?? '').toString();

      return _TopProductData(
        name: name,
        quantity: quantity,
        imageUrl: imageUrl,
      );
    }).toList();

    final maxQuantity = items.isEmpty
        ? 1
        : items.map((e) => e.quantity).reduce((a, b) => a > b ? a : b);

    return _AnalyticsCard(
      title: 'Top productos',
      subtitle: 'Productos con más palets vendidos',
      icon: Icons.bar_chart_rounded,
      child: items.isEmpty
          ? const _EmptyChartCard(
        text:
        'Cuando haya pedidos completados, aparecerán aquí los productos más vendidos.',
      )
          : Column(
        children: [
          SizedBox(
            height: 260,
            child: BarChart(
              BarChartData(
                maxY: maxQuantity.toDouble() + 2,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 2,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: const Color(0xFFE5EAF0),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();

                        if (index < 0 || index >= items.length) {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF061A2D),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(items.length, (index) {
                  final item = items[index];

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: item.quantity.toDouble(),
                        width: 22,
                        borderRadius: BorderRadius.circular(8),
                        color: const Color(0xFF1AA6FF),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _TopProductRow(
                  index: index + 1,
                  data: item,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _TopProductData {
  final String name;
  final int quantity;
  final String imageUrl;

  const _TopProductData({
    required this.name,
    required this.quantity,
    required this.imageUrl,
  });
}

class _TopProductRow extends StatelessWidget {
  final int index;
  final _TopProductData data;

  const _TopProductRow({
    required this.index,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              index.toString(),
              style: TextStyle(
                color: cs.onPrimaryContainer,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _ProductImage(
          name: data.name,
          imageUrl: data.imageUrl,
          size: 42,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            data.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 13.5,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'x${data.quantity}',
          style: TextStyle(
            color: cs.primary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String title;
  final int value;
  final Color color;

  const _LegendItem({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value.toString(),
          style: TextStyle(
            color: color,
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
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 10.5,
          ),
        ),
      ],
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  final double avgDeliveryHours;
  final double changePct;

  const _DeliveryCard({
    required this.avgDeliveryHours,
    required this.changePct,
  });

  @override
  Widget build(BuildContext context) {
    return _AnalyticsCard(
      title: 'Tiempo medio de entrega',
      subtitle: 'Promedio de horas hasta completar pedidos',
      icon: Icons.schedule_rounded,
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF6FF),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.local_shipping_rounded,
              color: Color(0xFF1AA6FF),
              size: 32,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${avgDeliveryHours.toStringAsFixed(1)} h',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatPercent(changePct)} respecto al mes anterior',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
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

class _ReportCard extends StatelessWidget {
  final bool generatingPdf;
  final VoidCallback onGenerate;

  const _ReportCard({
    required this.generatingPdf,
    required this.onGenerate,
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
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reporte mensual',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Genera un PDF con el resumen del periodo seleccionado.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.72),
                        fontSize: 12.5,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: generatingPdf ? null : onGenerate,
              style: FilledButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: generatingPdf
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
                  : const Icon(Icons.download_rounded),
              label: const Text(
                'Generar PDF del mes',
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

class _AnalyticsCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  const _AnalyticsCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
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
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(
                  icon,
                  color: cs.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.3,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _EmptyChartCard extends StatelessWidget {
  final String text;

  const _EmptyChartCard({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FC),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Icon(
            Icons.bar_chart_rounded,
            size: 44,
            color: cs.primary,
          ),
          const SizedBox(height: 10),
          const Text(
            'Sin datos suficientes',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15.5,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 12.5,
              height: 1.3,
            ),
          ),
        ],
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

class _LoadingCard extends StatelessWidget {
  final double height;

  const _LoadingCard({
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      height: height,
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

double _number(dynamic value) {
  if (value is num) return value.toDouble();

  return double.tryParse(value?.toString() ?? '') ?? 0.0;
}

String _formatMoney(double value) {
  return '${value.toStringAsFixed(2)} €';
}

String _formatPercent(double value) {
  final sign = value > 0 ? '+' : '';

  return '$sign${value.toStringAsFixed(1)}%';
}

String _monthName(int month) {
  switch (month) {
    case 1:
      return 'Enero';
    case 2:
      return 'Febrero';
    case 3:
      return 'Marzo';
    case 4:
      return 'Abril';
    case 5:
      return 'Mayo';
    case 6:
      return 'Junio';
    case 7:
      return 'Julio';
    case 8:
      return 'Agosto';
    case 9:
      return 'Septiembre';
    case 10:
      return 'Octubre';
    case 11:
      return 'Noviembre';
    case 12:
      return 'Diciembre';
    default:
      return 'Mes';
  }
}