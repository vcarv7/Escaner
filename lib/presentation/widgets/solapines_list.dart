import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/scan_item.dart';
import '../providers/scan_provider.dart';
import 'scan_item_card.dart';

class SolapinesList extends StatefulWidget {
  final ScanProvider provider;

  const SolapinesList({super.key, required this.provider});

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
    if (!_showScrollTopButton && _scrollController.offset > 500) {
      setState(() => _showScrollTopButton = true);
    } else if (_showScrollTopButton && _scrollController.offset <= 500) {
      setState(() => _showScrollTopButton = false);
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

  @override
  Widget build(BuildContext context) {
    return Consumer<ScanProvider>(
      builder: (context, provider, _) {
        final items = provider.items;
        final solapineCount = items.where((item) => item.type == ScanType.solapine).length;
        final tarjetaCount = items.where((item) => item.type == ScanType.tarjeta).length;

        return Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, solapineCount, tarjetaCount, items.isNotEmpty),
                Expanded(child: _buildList(context, items)),
              ],
            ),
            if (_showScrollTopButton)
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

  Widget _buildHeader(BuildContext context, int solapineCount, int tarjetaCount, bool hasItems) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(_getCountText(solapineCount, tarjetaCount), style: Theme.of(context).textTheme.titleMedium),
          if (hasItems)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _showClearConfirmation(context),
              tooltip: 'Eliminar todos',
            ),
        ],
      ),
    );
  }

  String _getCountText(int solapineCount, int tarjetaCount) {
    final solapinText = solapineCount == 1 ? 'Solapín' : 'Solapines';
    final tarjetaText = tarjetaCount == 1 ? 'Tarjeta' : 'Tarjetas';
    if (solapineCount == 0 && tarjetaCount == 0) return 'Sin códigos';
    if (solapineCount == 0) return '$tarjetaCount $tarjetaText';
    if (tarjetaCount == 0) return '$solapineCount $solapinText';
    return '$solapineCount $solapinText y $tarjetaCount $tarjetaText';
  }

  Widget _buildList(BuildContext context, List<ScanItem> items) {
    if (items.isEmpty) {
      return const Center(child: Text('No hay códigos escaneados'));
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: items.length + (_isLoadingMore ? 1 : 0),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (context, index) {
        if (index >= items.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final item = items[index];
        return Dismissible(
          key: ValueKey(item.code),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            color: Colors.orange,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) => widget.provider.deleteItem(item),
          child: ScanItemCard(item: item),
        );
      },
    );
  }

  void _showClearConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar todos los códigos'),
        content: const Text('¿Estás seguro de que quieres eliminar todos los códigos escaneados?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.provider.clearAll();
            },
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.primary),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}