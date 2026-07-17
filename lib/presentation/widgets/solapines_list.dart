import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/filter_service.dart';
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
    final hasEnoughItems = widget.provider.items.length > 5;
    final shouldShowButton = hasEnoughItems && _scrollController.offset > 500;

    if (_showScrollTopButton != shouldShowButton) {
      setState(() => _showScrollTopButton = shouldShowButton);
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final filtro = settings.filtro;
    final orden = settings.ordenScaneados;

    return Consumer<ScanProvider>(
      builder: (context, provider, _) {
        final allItems = provider.items;
        final itemsFiltrados = FilterService.aplicarFiltros(allItems, filtro);
        
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
                child: Semantics(
                  label: 'Volver al inicio de la lista',
                  child: FloatingActionButton.small(
                    heroTag: 'scrollTop',
                    onPressed: _scrollToTop,
                    child: const Icon(Icons.arrow_upward, color: Colors.white),
                  ),
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
          Semantics(
            label: 'Cambiar orden de escaneos',
            child: IconButton(
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
                  filtro.copyWith(
                    tipoRango: TipoRangoFecha.unico,
                    fecha: DateTime.now(),
                    fechaInicio: null,
                    fechaFin: null,
                  ),
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
      itemCount: items.length,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      itemBuilder: (context, index) => ScanItemCard(item: items[index]),
    );
  }
}