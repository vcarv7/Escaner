import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/persona_provider.dart';

/// Progreso de sincronización inline: reemplaza al botón Sincronizar
/// ocupando su mismo ancho (`double.infinity` en la card).
///
/// Sin modales: el operador puede seguir navegando mientras descarga.
/// El estado vive en [PersonaProvider], así que al volver a Ajustes el
/// progreso sigue vivo.
class SyncProgressInline extends StatelessWidget {
  const SyncProgressInline({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PersonaProvider>(
      builder: (context, provider, _) {
        final colorScheme = Theme.of(context).colorScheme;
        final textStyle = TextStyle(
          fontSize: 13,
          color: colorScheme.onSurface.withValues(alpha: 0.6),
        );
        final conectando = provider.syncTotalPaginas == 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              label: 'Progreso de sincronización',
              value: provider.isCancelling
                  ? 'Cancelando'
                  : conectando
                      ? 'Conectando con el servidor'
                      : 'Página ${provider.syncPaginaActual} de '
                          '${provider.syncTotalPaginas}, '
                          '${provider.syncRecibidos} personas',
              child: SizedBox(
                height: 10,
                child: LinearProgressIndicator(
                  key: const ValueKey('sync_progress_bar'),
                  value: provider.syncProgress,
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (provider.isCancelling)
              Text('Cancelando...', style: textStyle)
            else if (conectando) ...[
              Semantics(
                liveRegion: true,
                label: 'Conectando con el servidor',
                child: Text(
                  'Conectando con el servidor...',
                  style: textStyle,
                ),
              ),
              Text(
                'Puede tardar 1-2 minutos por las fotos.',
                style: textStyle,
              ),
            ] else
              Semantics(
                liveRegion: true,
                label:
                    'Descargando página ${provider.syncPaginaActual} de '
                    '${provider.syncTotalPaginas}, '
                    '${provider.syncRecibidos} personas',
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Descargando página ${provider.syncPaginaActual} '
                        'de ${provider.syncTotalPaginas} · '
                        '${provider.syncRecibidos} personas',
                        style: textStyle,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // El tiempo cambia cada segundo: fuera del live region
                    // para no saturar al lector de pantalla. Visualmente
                    // sigue en la misma línea.
                    ExcludeSemantics(
                      child: Text(
                        ' · ${formatSyncElapsed(provider.syncElapsed)}',
                        style: textStyle,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const ValueKey('sync_cancel_button'),
                onPressed: provider.isCancelling
                    ? null
                    : () => provider.cancelSync(),
                icon: const Icon(Icons.close_rounded),
                label: Text(
                  provider.isCancelling ? 'Cancelando...' : 'Cancelar',
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Formato `mm:ss` del tiempo transcurrido.
String formatSyncElapsed(Duration d) {
  final m = d.inMinutes.toString().padLeft(2, '0');
  final s = (d.inSeconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}
