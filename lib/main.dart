import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api/api_client.dart';
import 'screens/products_screen.dart';
import 'screens/orders_screens.dart';
import 'screens/customers_screen.dart';
import 'screens/analtytics_screen.dart';
import 'screens/chatbot_screen.dart';

void main() {
  runApp(const SmartWorksApp());
}

class SmartWorksApp extends StatelessWidget {
  const SmartWorksApp({super.key});

  @override
  Widget build(BuildContext context) {
    const skyBlue = Color(0xFF1AA6FF);
    const deepNavy = Color(0xFF061A2D);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartWorks',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: skyBlue,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F8FC),
      ),
      home: const SplashScreen(
        duration: Duration(seconds: 5),
        background: deepNavy,
      ),
    );
  }
}

/* ---------------- Splash ---------------- */

class SplashScreen extends StatefulWidget {
  final Duration duration;
  final Color background;

  const SplashScreen({
    super.key,
    required this.duration,
    required this.background,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fade = CurvedAnimation(
      parent: _c,
      curve: Curves.easeOut,
    );

    _scale = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _c,
        curve: Curves.easeOutBack,
      ),
    );

    _c.forward();

    Future.delayed(widget.duration, () {
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const HomeShell(),
        ),
      );
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: widget.background,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Image.asset(
                    'assets/images/logo_smartworks.png',
                    width: 220,
                    height: 220,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'SMARTWORKS',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 140,
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    backgroundColor: Colors.white.withOpacity(0.15),
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ---------------- Shell ---------------- */

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(
        onNavigate: (pageIndex) {
          setState(() {
            index = pageIndex;
          });
        },
      ),
      const ProductsScreen(),
      const OrdersScreen(),
      const CustomersScreen(),
      const AnalyticsScreen(),
    ];

    return Scaffold(
      body: pages[index],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ChatbotScreen(),
            ),
          );
        },
        icon: const Icon(Icons.smart_toy_rounded),
        label: const Text('Chatbot'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          setState(() {
            index = i;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_rounded),
            label: 'Productos',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_rounded),
            label: 'Pedidos',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_rounded),
            label: 'Clientes',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_rounded),
            label: 'Analizador',
          ),
        ],
      ),
    );
  }
}

/* ---------------- Dashboard ---------------- */

class DashboardScreen extends StatefulWidget {
  final void Function(int pageIndex) onNavigate;

  const DashboardScreen({
    super.key,
    required this.onNavigate,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final api = ApiClient();
  late Future<Map<String, dynamic>> future;

  @override
  void initState() {
    super.initState();
    future = api.getDashboard();
  }

  Future<void> refresh() async {
    setState(() {
      future = api.getDashboard();
    });

    await future;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<Map<String, dynamic>>(
        future: future,
        builder: (context, snapshot) {
          final loading = snapshot.connectionState != ConnectionState.done;
          final hasError = snapshot.hasError;

          final data = snapshot.data ?? <String, dynamic>{};

          final lowStock = loading
              ? '—'
              : (data['lowStockProducts'] ?? 0).toString();

          final pendingOrders = loading
              ? '—'
              : (data['pendingOrders'] ?? 0).toString();

          return RefreshIndicator(
            onRefresh: refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 150),
              children: [
                _DashboardHeader(
                  onRefresh: refresh,
                ),

                const SizedBox(height: 18),

                _StatusOverviewCard(
                  lowStock: lowStock,
                  pendingOrders: pendingOrders,
                  loading: loading,
                  hasError: hasError,
                  onProducts: () => widget.onNavigate(1),
                  onOrders: () => widget.onNavigate(2),
                ),

                if (hasError) ...[
                  const SizedBox(height: 16),
                  _ErrorCard(
                    message:
                    'No se pudo cargar el resumen.\n${snapshot.error}',
                    onRetry: refresh,
                  ),
                ],

                const SizedBox(height: 26),

                const _SectionHeader(
                  title: 'Centro de operaciones',
                  subtitle: 'Gestiona las áreas principales de SmartWorks',
                ),

                const SizedBox(height: 14),

                _ModuleCard(
                  title: 'Inventario',
                  subtitle:
                  'Controla productos, stock disponible y alertas de bajo inventario.',
                  icon: Icons.inventory_2_rounded,
                  badge: 'Stock',
                  color: const Color(0xFF1AA6FF),
                  background: const Color(0xFFEAF6FF),
                  onTap: () => widget.onNavigate(1),
                ),

                const SizedBox(height: 14),

                _ModuleCard(
                  title: 'Pedidos',
                  subtitle:
                  'Revisa pedidos pendientes, completados y cancelados.',
                  icon: Icons.receipt_long_rounded,
                  badge: 'Ventas',
                  color: const Color(0xFF7C4DFF),
                  background: const Color(0xFFF0EAFF),
                  onTap: () => widget.onNavigate(2),
                ),

                const SizedBox(height: 14),

                _ModuleCard(
                  title: 'Clientes',
                  subtitle:
                  'Gestiona clientes, datos de contacto y perfiles.',
                  icon: Icons.people_alt_rounded,
                  badge: 'CRM',
                  color: const Color(0xFF009688),
                  background: const Color(0xFFE6F7F5),
                  onTap: () => widget.onNavigate(3),
                ),

                const SizedBox(height: 14),

                _ModuleCard(
                  title: 'Análisis',
                  subtitle:
                  'Consulta estadísticas, métricas y gráficos del negocio.',
                  icon: Icons.query_stats_rounded,
                  badge: 'Datos',
                  color: const Color(0xFFFF8A00),
                  background: const Color(0xFFFFF4E5),
                  onTap: () => widget.onNavigate(4),
                ),

                const SizedBox(height: 26),

                const _SectionHeader(
                  title: 'Herramientas',
                  subtitle: 'Accesos rápidos complementarios',
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: _ToolCard(
                        title: 'Chatbot',
                        subtitle: 'Asistente IA',
                        icon: Icons.smart_toy_rounded,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ChatbotScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _ToolCard(
                        title: 'Web',
                        subtitle: 'Página oficial',
                        icon: Icons.language_rounded,
                        onTap: () async {
                          final Uri url = Uri.parse(
                            'https://smartworks.webcindario.com/',
                          );

                          if (!await launchUrl(
                            url,
                            mode: LaunchMode.externalApplication,
                          )) {
                            throw Exception(
                              'No se pudo abrir el enlace',
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 26),

                const _SystemResumeCard(),
              ],
            ),
          );
        },
      ),
    );
  }
}

/* ---------------- Dashboard Widgets ---------------- */

class _DashboardHeader extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _DashboardHeader({
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF061A2D),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF061A2D).withOpacity(0.22),
            blurRadius: 26,
            offset: const Offset(0, 14),
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
                    color: Colors.white.withOpacity(0.16),
                  ),
                ),
                child: const Icon(
                  Icons.business_center_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SmartWorks',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Panel empresarial',
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

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF1AA6FF).withOpacity(0.18),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: const Color(0xFF1AA6FF).withOpacity(0.35),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_rounded,
                  color: Color(0xFF5CC6FF),
                  size: 17,
                ),
                SizedBox(width: 6),
                Text(
                  'Sistema conectado',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            'Control total de tu negocio',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              height: 1.1,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            'Gestiona inventario, pedidos, clientes y análisis desde una interfaz rápida y profesional.',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.76),
              fontSize: 13.5,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusOverviewCard extends StatelessWidget {
  final String lowStock;
  final String pendingOrders;
  final bool loading;
  final bool hasError;
  final VoidCallback onProducts;
  final VoidCallback onOrders;

  const _StatusOverviewCard({
    required this.lowStock,
    required this.pendingOrders,
    required this.loading,
    required this.hasError,
    required this.onProducts,
    required this.onOrders,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: cs.outlineVariant.withOpacity(0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.055),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: 'Stock bajo',
                  value: hasError ? '!' : lowStock,
                  subtitle: 'Productos por revisar',
                  icon: Icons.warning_amber_rounded,
                  color: const Color(0xFFFF8A00),
                  background: const Color(0xFFFFF4E5),
                  onTap: onProducts,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  title: 'Pendientes',
                  value: hasError ? '!' : pendingOrders,
                  subtitle: 'Pedidos abiertos',
                  icon: Icons.pending_actions_rounded,
                  color: const Color(0xFF1AA6FF),
                  background: const Color(0xFFEAF6FF),
                  onTap: onOrders,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFFF6FAFF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: cs.outlineVariant.withOpacity(0.45),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: hasError
                        ? cs.errorContainer
                        : const Color(0xFFE9F8EF),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    hasError
                        ? Icons.error_outline_rounded
                        : Icons.cloud_done_rounded,
                    color: hasError
                        ? cs.onErrorContainer
                        : const Color(0xFF1B8E4B),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hasError
                        ? 'Problema cargando los datos del dashboard.'
                        : loading
                        ? 'Actualizando información del sistema...'
                        : 'Datos sincronizados correctamente.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                      height: 1.25,
                    ),
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

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.background,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: color.withOpacity(0.15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),

            const SizedBox(height: 14),

            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: cs.onSurface,
                letterSpacing: -0.6,
              ),
            ),

            const SizedBox(height: 3),

            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
                color: cs.onSurface,
              ),
            ),

            const SizedBox(height: 3),

            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.2,
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
          ],
        ),
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
            fontSize: 19,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: cs.onSurfaceVariant,
            fontSize: 13.5,
          ),
        ),
      ],
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.color,
    required this.background,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
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
                color: background,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                color: color,
                size: 30,
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
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: background,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          badge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: color,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 12.2,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: cs.onSurfaceVariant,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ToolCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFF061A2D),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF061A2D).withOpacity(0.14),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: const Color(0xFF5CC6FF),
              size: 30,
            ),
            const SizedBox(height: 18),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.68),
                fontSize: 12,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SystemResumeCard extends StatelessWidget {
  const _SystemResumeCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: cs.outlineVariant.withOpacity(0.45),
        ),
      ),
      child: const Column(
        children: [
          _SystemLine(
            icon: Icons.api_rounded,
            title: 'API Spring Boot',
            subtitle:
            'Backend preparado para productos, pedidos, clientes y chatbot.',
            color: Color(0xFF1AA6FF),
          ),
          Divider(height: 24),
          _SystemLine(
            icon: Icons.storage_rounded,
            title: 'Base de datos MySQL',
            subtitle:
            'Información centralizada para la gestión del negocio.',
            color: Color(0xFF009688),
          ),
          Divider(height: 24),
          _SystemLine(
            icon: Icons.analytics_rounded,
            title: 'Análisis empresarial',
            subtitle:
            'Próximo paso: gráficos visuales para la exposición del TFG.',
            color: Color(0xFFFF8A00),
          ),
        ],
      ),
    );
  }
}

class _SystemLine extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _SystemLine({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            color: color,
            size: 25,
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
                  fontSize: 14.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 12.5,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
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
            'Error al cargar datos',
            style: TextStyle(
              color: cs.onErrorContainer,
              fontWeight: FontWeight.w900,
              fontSize: 15,
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

/* ---------------- Placeholder ---------------- */

class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}