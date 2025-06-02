import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../presentation/providers/auth_provider.dart';
import '../presentation/pages/login_page.dart';
import '../presentation/pages/home_page.dart';
import '../presentation/pages/orders_list_page.dart';
import '../presentation/pages/order_form_page.dart';
import '../presentation/pages/employees_list_page.dart';
import '../presentation/pages/employee_form_page.dart';

class AppRouter {
  static GoRouter createRouter() {
    return GoRouter(
      initialLocation: '/login',
      redirect: (context, state) {
        final authProvider = context.read<AuthProvider>();
        final isAuthenticated = authProvider.isAuthenticated;
        final isLoggingIn = state.matchedLocation == '/login';

        // Se não está autenticado e não está na tela de login, redireciona para login
        if (!isAuthenticated && !isLoggingIn) {
          return '/login';
        }

        // Se está autenticado e está na tela de login, redireciona para home
        if (isAuthenticated && isLoggingIn) {
          return '/home';
        }

        return null; // Não redireciona
      },
      routes: [
        // Rota de Login
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginPage(),
        ),

        // Rota Principal (Home)
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (context, state) => const HomePage(),
        ),

        // Rotas de Pedidos
        GoRoute(
          path: '/orders',
          name: 'orders',
          builder: (context, state) => const OrdersListPage(),
          routes: [
            GoRoute(
              path: '/new',
              name: 'new-order',
              builder: (context, state) => const OrderFormPage(),
            ),
            GoRoute(
              path: '/edit/:id',
              name: 'edit-order',
              builder: (context, state) {
                final orderId = state.pathParameters['id']!;
                return OrderFormPage(orderId: orderId);
              },
            ),
          ],
        ),

        // Rotas de Funcionários
        GoRoute(
          path: '/employees',
          name: 'employees',
          builder: (context, state) => const EmployeesListPage(),
          routes: [
            GoRoute(
              path: '/new',
              name: 'new-employee',
              builder: (context, state) => const EmployeeFormPage(),
            ),
            GoRoute(
              path: '/edit/:id',
              name: 'edit-employee',
              builder: (context, state) {
                // Aqui você pode buscar o funcionário pelo ID se necessário
                return const EmployeeFormPage();
              },
            ),
          ],
        ),

        // Rota de Perfil
        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) => const ProfilePage(),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(
          title: const Text('Página não encontrada'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                'Página não encontrada',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'A página "${state.matchedLocation}" não existe.',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                child: const Text('Voltar ao Início'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Página de perfil simples
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.user;
          
          if (user == null) {
            return const Center(
              child: Text('Usuário não encontrado'),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Theme.of(context).primaryColor,
                        child: Text(
                          user.name.split(' ').map((n) => n[0]).take(2).join().toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Informações da Conta',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow('ID', user.id),
                        _buildInfoRow('Email', user.email),
                        _buildInfoRow('Nome', user.name),
                        if (user.lastLogin != null)
                          _buildInfoRow(
                            'Último Login',
                            '${user.lastLogin!.day}/${user.lastLogin!.month}/${user.lastLogin!.year} às ${user.lastLogin!.hour}:${user.lastLogin!.minute.toString().padLeft(2, '0')}',
                          ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await authProvider.logout();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Sair'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

