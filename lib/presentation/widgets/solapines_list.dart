import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/scan_item.dart';
import '../providers/scan_provider.dart';
import '../providers/settings_provider.dart';
import 'scan_item/scan_item_constants.dart';
import 'scan_item/scan_item_card.dart';
import 'common/empty_state.dart';

class SolapinesList extends StatefulWidget {
  final ScanProvider provider;

  const SolapinesList({
    super.key,
    required this.provider,
  });

  @override
  State<SolapinesList> createState() => _SolapinesListState();
}

class _SolapinesListState extends State<SolapinesList> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  bool _showScrollTopButton = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && widget.provider.hasMoreData) {
        _loadNextPage();
      }
    }
    final hasEnoughItems = widget.provider.items.length > 5;
    if (hasEnoughItems) {
      if (!_showScrollTopButton && _scrollController.offset > 500) {
        setState(() => _showScrollTopButton = true);
      } else if (_showScrollTopButton && _scrollController.offset <= 500) {
        setState(() => _showScrollTopButton = false);
      }
    } else {
      if (_showScrollTopButton) {
        setState(() => _showScrollTopButton = false);
      }
    }
  }

  void _loadNextPage() {
    setState(() => _isLoadingMore = true);
    final nextPage = widget.provider.currentPage + 1;
    final newItems = widget.provider.getItemsPage(nextPage);
    if (newItems.isEmpty) {
      setState(() => _isLoadingMore = false);
      return;
    }
    widget.provider.resetPagination();
    setState(() => _isLoadingMore = false);
  }

  void _scrollToTop() {
    _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  List<ScanItem> _filtrarItems(List<ScanItem> items, FiltroData filtro) {
    return items.where((item) {
      final esMismoDia = item.scannedAt.year == filtro.fecha.year &&
          item.scannedAt.month == filtro.fecha.month &&
          item.scannedAt.day == filtro.fecha.day;
      final mismoEvento = filtro.evento == null || 
          (item.evento != null && item.evento!.displayName == filtro.eventoNombre);
      return esMismoDia && mismoEvento;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final filtro = settings.filtro;

    return Consumer<ScanProvider>(
      builder: (context, provider, _) {
        final allItems = provider.items;
        final itemsFiltrados = _filtrarItems(allItems, filtro);
        final solapineCount = itemsFiltrados.where((item) => item.type == ScanType.solapine).length;
        final tarjetaCount = itemsFiltrados.where((item) => item.type == ScanType.tarjeta).length;

        return Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, solapineCount, tarjetaCount, itemsFiltrados.isNotEmpty, filtro),
                _buildFiltroChips(context, filtro),
                Expanded(child: _buildList(context, itemsFiltrados)),
              ],
            ),
            if (_showScrollTopButton && itemsFiltrados.isNotEmpty && itemsFiltrados.length > 5)
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton.small(
                  heroTag: 'scrollTop',
                  onPressed: _scrollToTop,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: const Icon(Icons.arrow_upward, color: Colors.white),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildFiltroChips(BuildContext context, FiltroData filtro) {
    if (filtro.evento == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Wrap(
        spacing: 8,
        children: [
          Chip(
            label: Text(
              'Fecha: ${filtro.fecha.day}/${filtro.fecha.month}/${filtro.fecha.year}',
              style: const TextStyle(fontSize: 12),
            ),
            onDeleted: () {
              context.read<SettingsProvider>().setFiltro(FiltroData(fecha: filtro.fecha, evento: null));
            },
          ),
          Chip(
            label: Text(filtro.evento!.displayName, style: const TextStyle(fontSize: 12)),
            onDeleted: () {
              context.read<SettingsProvider>().setFiltro(FiltroData(fecha: filtro.fecha, evento: null));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int solapineCount, int tarjetaCount, bool hasItems, FiltroData filtro) {
    final screenHeight = MediaQuery.of(context).size.height;
    final verticalPadding = screenHeight < 600 ? 4.0 : 8.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: verticalPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            ScanItemConstants.getCountText(solapineCount, tarjetaCount),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, List<ScanItem> items) {
    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.qr_code_scanner,
        title: 'Sin resultados',
        subtitle: 'No hay escaneos para los filtros seleccionados',
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: items.length + (_isLoadingMore ? 1 : 0),
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width > 400 ? 16 : 8,
      ),
      itemBuilder: (context, index) {
        if (index >= items.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final item = items[index];
        return ScanItemCard(item: item);
      },
    );
  }
}