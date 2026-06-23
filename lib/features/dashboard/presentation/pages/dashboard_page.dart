import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_inno/core/network/providers.dart';
import 'package:flutter_inno/features/dashboard/dashboard.dart';

const _kBg = Color(0xFF0F1923);
const _kCard = Color(0xFF152030);
const _kBorder = Color(0xFF1E3048);
const _kAccent = Color(0xFF3B9EFF);
const _kTextPrimary = Color(0xFFF0F6FF);
const _kTextSecondary = Color(0xFF5A7A9A);
const _kSuccess = Color(0xFF2ECC71);
const _kWarning = Color(0xFFFFB84D);

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final storage = ref.read(secureStorageProvider);
      final token = await storage.getAccessToken();
      if (token == null) {
        if (!mounted) return;
        context.replace('/login');
        return;
      }

      final documento = await storage.getDocumento() ?? '';
      if (documento.isEmpty) {
        if (!mounted) return;
        context.replace('/login');
        return;
      }

      final repo = ref.read(dashboardRepositoryProvider);
      final data = await repo.getClienteDashboard(documento);
      if (mounted) setState(() { _data = data; _isLoading = false; });
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await ref.read(secureStorageProvider).deleteTokens();
        if (!mounted) return;
        context.replace('/login');
        return;
      }
      if (mounted) setState(() { _error = 'Error al cargar el dashboard'; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Error inesperado'; _isLoading = false; });
    }
  }

  int get _vehiculos => (_data?['vehiculos'] as num?)?.toInt() ?? 0;
  int get _activas => (_data?['ordenesActivas'] as num?)?.toInt() ?? 0;
  int get _finalizadas => (_data?['ordenesFinalizadas'] as num?)?.toInt() ?? 0;
  int get _cotizaciones => (_data?['cotizacionesPendientes'] as num?)?.toInt() ?? 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _kAccent))
          : _error != null
              ? _buildError()
              : _buildContent(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, color: _kTextSecondary, size: 48),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: _kTextPrimary, fontSize: 16), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(backgroundColor: _kAccent),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SafeArea(
      child: RefreshIndicator(
        color: _kAccent,
        backgroundColor: _kCard,
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 8),
                  _buildWelcome(),
                  const SizedBox(height: 24),
                  _buildStats(),
                  const SizedBox(height: 28),
                  _buildSectionLabel('Resumen'),
                  const SizedBox(height: 12),
                  _buildOrderSummary(),
                  const SizedBox(height: 100),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      backgroundColor: _kBg,
      elevation: 0,
      pinned: false,
      floating: true,
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded, color: _kTextPrimary),
        onPressed: () {},
      ),
      title: const Text(
        'InnoGarage',
        style: TextStyle(color: _kAccent, fontWeight: FontWeight.w700, fontSize: 18),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: _kTextPrimary),
          onPressed: () {},
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: _kBorder,
            child: const Icon(Icons.person_rounded, color: _kTextSecondary, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcome() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Bienvenido,', style: TextStyle(color: _kTextSecondary, fontSize: 13)),
        const SizedBox(height: 2),
        const Text(
          'Panel de cliente',
          style: TextStyle(color: _kTextPrimary, fontSize: 26, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildStats() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _statCard(icon: Icons.directions_car_rounded, label: 'Vehículos', value: '$_vehiculos'),
        _statCard(icon: Icons.build_rounded, label: 'Órdenes activas', value: '$_activas', iconColor: _kWarning, highlight: true),
        _statCard(icon: Icons.check_circle_outline, label: 'Finalizadas', value: '$_finalizadas', iconColor: _kSuccess),
        _statCard(icon: Icons.description_outlined, label: 'Cotizaciones', value: '$_cotizaciones'),
      ],
    );
  }

  Widget _statCard({
    required IconData icon, required String label, required String value,
    Color iconColor = _kAccent, bool highlight = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: highlight ? _kWarning : _kBorder, width: highlight ? 1.2 : 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: iconColor, size: 20),
              Text(value, style: const TextStyle(color: _kTextPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
            ],
          ),
          Text(label, style: const TextStyle(color: _kTextSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(color: _kTextPrimary, fontSize: 15, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _kAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _kAccent.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline, color: _kAccent, size: 12),
                    SizedBox(width: 4),
                    Text('EN CURSO', style: TextStyle(color: _kAccent, fontSize: 10, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1B2A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _kBorder),
                ),
                child: const Icon(Icons.directions_car_filled_rounded, color: Color(0xFF1E3048), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$_activas órdenes activas', style: const TextStyle(color: _kTextPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('$_finalizadas finalizadas', style: const TextStyle(color: _kTextSecondary, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: _kBorder, height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.description_outlined, color: _kAccent, size: 16),
              const SizedBox(width: 8),
              Text('$_cotizaciones cotizaciones pendientes', style: const TextStyle(color: _kTextPrimary, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.directions_car_rounded, color: _kSuccess, size: 16),
              const SizedBox(width: 8),
              Text('$_vehiculos vehículos registrados', style: const TextStyle(color: _kTextPrimary, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        border: const Border(top: BorderSide(color: _kBorder, width: 1)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(icon: Icons.home_rounded, label: 'Inicio', active: true, onTap: () {}),
              _navItem(icon: Icons.directions_car_rounded, label: 'Vehículos', active: false, onTap: () {}),
              _navItem(icon: Icons.description_outlined, label: 'Órdenes', active: false, onTap: () {}),
              _navItem(icon: Icons.person_outline, label: 'Perfil', active: false, onTap: () {}),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem({required IconData icon, required String label, required bool active, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? _kAccent : _kTextSecondary, size: 22),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: active ? _kAccent : _kTextSecondary, fontSize: 10, fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}
