import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../providers/scan_provider.dart';

class AppDrawer extends StatefulWidget {
  final VoidCallback onImport;
  final VoidCallback onExport;

  const AppDrawer({
    super.key,
    required this.onImport,
    required this.onExport,
  });

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            _buildProfileSection(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  const Divider(),
                  _buildMenuItem(
                    icon: Icons.login,
                    title: 'Iniciar Sesión',
                    subtitle: 'Gestiona tu cuenta',
                    onTap: () {},
                    isLoginButton: true,
                  ),
                  const Divider(),
                  _buildMenuItem(
                    icon: Icons.file_upload_outlined,
                    title: 'Importar Excel',
                    subtitle: 'Cargar códigos desde archivo',
                    onTap: widget.onImport,
                  ),
                  _buildMenuItem(
                    icon: Icons.file_download_outlined,
                    title: 'Exportar Excel',
                    subtitle: 'Guardar códigos en archivo',
                    onTap: widget.onExport,
                  ),
                  const Divider(),
                  _buildTrashSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.primary.withValues(alpha: 0.1),
                Colors.white,
              ],
            ),
          ),
          child: Column(
            children: [
              _AnimatedAvatar(),
              const SizedBox(height: 16),
              const Text('Usuario', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.onSurface)),
              Text('usuario@uci.cu', style: TextStyle(fontSize: 14, color: AppTheme.onSurface.withValues(alpha: 0.6))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({required IconData icon, required String title, required String subtitle, required VoidCallback onTap, bool isLoginButton = false}) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isLoginButton ? AppTheme.primary.withValues(alpha: 0.3) : AppTheme.primary.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isLoginButton ? AppTheme.primary.withValues(alpha: 0.1) : AppTheme.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primary),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: isLoginButton ? AppTheme.primary : AppTheme.onSurface)),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.chevron_right, color: AppTheme.primary),
      ),
    );
  }

  Widget _buildTrashSection() {
    return Consumer<ScanProvider>(
      builder: (context, provider, _) {
        final trashItems = provider.trashItems;
        return ExpansionTile(
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.delete_outline, color: Colors.orange),
          ),
          title: const Text('Papelera', style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('${trashItems.length} elementos'),
          children: [
            if (trashItems.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('La papelera está vacía', style: TextStyle(color: Colors.grey)),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ElevatedButton.icon(
                  onPressed: trashItems.isEmpty ? null : () => provider.restoreAll(),
                  icon: const Icon(Icons.restore, size: 20),
                  label: Text('Restaurar todos (${trashItems.length})'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: TextButton.icon(
                  onPressed: () => _showClearTrashDialog(),
                  icon: const Icon(Icons.delete_sweep, color: Colors.red),
                  label: const Text('Vaciar papelera', style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  void _showClearTrashDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [Icon(Icons.delete_forever, color: Colors.red), SizedBox(width: 8), Text('Vaciar papelera')]),
        content: const Text('¿Estás seguro de que quieres eliminar permanentemente todos los elementos de la papelera?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<ScanProvider>().clearTrash();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Vaciar'),
          ),
        ],
      ),
    );
  }
}

class _AnimatedAvatar extends StatefulWidget {
  @override
  State<_AnimatedAvatar> createState() => _AnimatedAvatarState();
}

class _AnimatedAvatarState extends State<_AnimatedAvatar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppTheme.primary,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 8))],
        ),
        child: const Center(child: Text('U', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white))),
      ),
    );
  }
}