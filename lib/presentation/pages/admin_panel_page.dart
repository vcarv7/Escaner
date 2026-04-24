import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:escaner_1/core/theme/app_theme.dart';
import 'package:escaner_1/presentation/providers/auth_provider.dart';
import 'package:escaner_1/presentation/widgets/login/login_constants.dart';
import 'package:escaner_1/presentation/widgets/overlay/overlay_message.dart';

class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({super.key});

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: LoginConstants.animationDuration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            if (authProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final users = authProvider.users;

            if (users.isEmpty) {
              return _buildEmptyState(colorScheme);
            }

            return ListView.builder(
              padding: const EdgeInsets.all(LoginConstants.spacingMedium),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return _UserCard(
                  user: user,
                  onDelete: () => _deleteUser(context, authProvider, user.username),
                  onToggleAdmin: () => _toggleAdmin(context, authProvider, user.username),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FadeTransition(
        opacity: _fadeAnimation,
        child: FloatingActionButton.extended(
          onPressed: () => _showAddUserDialog(context),
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.person_add),
          label: const Text('Agregar Usuario'),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_off,
            size: 80,
            color: colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: LoginConstants.spacingMedium),
          Text(
            'No hay usuarios registrados',
            style: TextStyle(
              fontSize: LoginConstants.titleFontSize,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: LoginConstants.spacingSmall),
          Text(
            'Agrega usuarios para que puedan acceder',
            style: TextStyle(
              fontSize: LoginConstants.subtitleFontSize,
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser(
    BuildContext context,
    AuthProvider authProvider,
    String username,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Usuario'),
        content: Text('¿Estás seguro de eliminar a "$username"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await authProvider.deleteUser(username);
      if (!mounted) return;
      OverlayMessage.success(context, 'Usuario eliminado');
    }
  }

  Future<void> _toggleAdmin(
    BuildContext context,
    AuthProvider authProvider,
    String username,
  ) async {
    await authProvider.toggleAdmin(username);
    if (!mounted) return;
    OverlayMessage.success(context, 'Permisos actualizados');
  }

  Future<void> _showAddUserDialog(BuildContext context) async {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isAdmin = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nuevo Usuario'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Usuario',
                    hintText: 'Nombre de usuario',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: LoginConstants.spacingMedium),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    hintText: 'Contraseña',
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: LoginConstants.spacingMedium),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar Contraseña',
                    hintText: 'Confirmar contraseña',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: LoginConstants.spacingMedium),
                SwitchListTile(
                  title: const Text('Es Admin'),
                  subtitle: const Text('Permite gestionar usuarios'),
                  value: isAdmin,
                  onChanged: (value) => setState(() => isAdmin = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (usernameController.text.trim().isEmpty) {
                  OverlayMessage.error(context, 'Ingresa un usuario');
                  return;
                }
                if (passwordController.text.isEmpty) {
                  OverlayMessage.error(context, 'Ingresa una contraseña');
                  return;
                }
                if (passwordController.text != confirmPasswordController.text) {
                  OverlayMessage.error(context, 'Las contraseñas no coinciden');
                  return;
                }
                if (passwordController.text.length < 4) {
                  OverlayMessage.error(context, 'Mínimo 4 caracteres');
                  return;
                }
                Navigator.of(context).pop(true);
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      final authProvider = context.read<AuthProvider>();
      await authProvider.createUser(
        username: usernameController.text.trim(),
        password: passwordController.text,
        isAdmin: isAdmin,
      );
      if (!mounted) return;
      OverlayMessage.success(context, 'Usuario creado');
    }
  }
}

class _UserCard extends StatelessWidget {
  final dynamic user;
  final VoidCallback onDelete;
  final VoidCallback onToggleAdmin;

  const _UserCard({
    required this.user,
    required this.onDelete,
    required this.onToggleAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: LoginConstants.spacingSmall),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LoginConstants.cardRadius),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: LoginConstants.spacingMedium,
          vertical: LoginConstants.spacingSmall,
        ),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: user.isAdmin ? AppTheme.primary : colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Icon(
            user.isAdmin ? Icons.admin_panel_settings : Icons.person,
            color: user.isAdmin ? Colors.white : colorScheme.onSurface,
          ),
        ),
        title: Text(
          user.username,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          user.isAdmin ? 'Administrador' : 'Usuario',
          style: TextStyle(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'toggle_admin') {
              onToggleAdmin();
            } else if (value == 'delete') {
              onDelete();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'toggle_admin',
              child: Row(
                children: [
                  Icon(
                    user.isAdmin ? Icons.remove_circle : Icons.add_circle,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: LoginConstants.spacingSmall),
                  Text(user.isAdmin ? 'Quitar Admin' : 'Hacer Admin'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: LoginConstants.spacingSmall),
                  Text('Eliminar', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}