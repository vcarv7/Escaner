import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/scan_item.dart';
import '../providers/scan_provider.dart';
import '../providers/settings_provider.dart';
import 'scan_item/scan_item_constants.dart';
import 'scan_item/scan_item_card.dart';
import 'common/empty_state.dart';
import 'common/math_curve_loader.dart';

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
    final position = _scrollController.position;
    
    if (position.pixels >= position.maxScrollExtent - 200) {
      if (!_isLoadingMore && widget.provider.hasMoreData) {
        _loadNextPage();
      }
    }

    final hasEnoughItems = widget.provider.items.length > 5;
    final shouldShowButton = hasEnoughItems && _scrollController.offset > 500;
    
    if (_showScrollTopButton != shouldShowButton) {
      setState(() => _showScrollTopButton = shouldShowButton);
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
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  List<ScanItem> _filtrarItems(List<ScanItem> items, FiltroData filtro) {
    return items.where((item) {
      final fechaValida = filtro.fechaEnRango(item.scannedAt);
      final mismoEvento = filtro.evento == null || 
          (item.evento != null && item.evento!.displayName == filtro.eventoNombre);
      return fechaValida && mismoEvento;
    }).toList();
  }

@override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final filtro = settings.filtro;
    final orden = settings.ordenScaneados;

    return Consumer<ScanProvider>(
      builder: (context, provider, _) {
        final allItems = provider.items;
        final itemsFiltrados = _filtrarItems(allItems, filtro);
        
        final sortedItems = _ordenarItems(itemsFiltrados, orden);
        
        final solapineCount = sortedItems
            .where((item) => item.type == ScanType.solapine)
            .length;
        final tarjetaCount = sortedItems
            .where((item) => item.type == ScanType.tarjeta)
            .length;

        return Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, solapineCount, tarjetaCount, orden),
                _buildFiltroChips(context, filtro),
                Expanded(child: _buildList(context, sortedItems)),
              ],
            ),
            if (_showScrollTopButton && sortedItems.length > 5)
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton.small(
                  heroTag: 'scrollTop',
                  onPressed: _scrollToTop,
                  child: const Icon(Icons.arrow_upward, color: Colors.white),
                ),
              ),
          ],
        );
      },
    );
  }

  List<ScanItem> _ordenarItems(List<ScanItem> items, OrdenScaneados orden) {
    final sorted = List<ScanItem>.from(items);
    sorted.sort((a, b) => orden == OrdenScaneados.ascendente
        ? a.scannedAt.compareTo(b.scannedAt)
        : b.scannedAt.compareTo(a.scannedAt));
    return sorted;
  }

  Widget _buildHeader(BuildContext context, int solapineCount, int tarjetaCount, OrdenScaneados orden) {
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
          IconButton(
            icon: Icon(
              orden == OrdenScaneados.descendente 
                  ? Icons.arrow_downward 
                  : Icons.arrow_upward,
              size: 20,
            ),
            tooltip: orden == OrdenScaneados.descendente 
                ? 'Más recientes abajo' 
                : 'Más recientes arriba',
            onPressed: () {
              final nuevos = orden == OrdenScaneados.descendente
                  ? OrdenScaneados.ascendente
                  : OrdenScaneados.descendente;
              context.read<SettingsProvider>().setOrdenScaneados(nuevos);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFiltroChips(BuildContext context, FiltroData filtro) {
    if (filtro.evento == null && filtro.tipoRangoEffective == TipoRangoFecha.unico) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Wrap(
        spacing: 8,
        children: [
          if (filtro.tipoRangoEffective != TipoRangoFecha.unico)
            Chip(
              label: Text(
                filtro.fechaDisplayText,
                style: const TextStyle(fontSize: 12),
              ),
              onDeleted: () {
                context.read<SettingsProvider>().setFiltro(
                  FiltroData(fecha: DateTime.now()),
                );
              },
            ),
          if (filtro.evento != null)
            Chip(
              label: Text(
                filtro.evento!.displayName,
                style: const TextStyle(fontSize: 12),
              ),
              onDeleted: () {
                context.read<SettingsProvider>().setFiltro(
                  filtro.copyWith(evento: null),
                );
              },
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

    final horizontalPadding = MediaQuery.of(context).size.width > 400 ? 16.0 : 8.0;

    return ListView.builder(
      controller: _scrollController,
      itemCount: items.length + (_isLoadingMore ? 1 : 0),
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      itemBuilder: (context, index) {
        if (index >= items.length) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: MathCurveLoader.epicycloid(
                size: 60,
                color: Theme.of(context).colorScheme.primary,
                duration: const Duration(milliseconds: 1500),
                particleCount: 50,
                trailSpan: 0.4,
                strokeWidth: 4,
              ),
            ),
          );
        }
        return ScanItemCard(item: items[index]);
      },
    );
  }
}