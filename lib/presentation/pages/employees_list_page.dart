import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/employees_provider.dart';
import '../widgets/custom_text_field.dart';
import '../../data/models/employee.dart';
import 'employee_form_page.dart';
import 'employee_details_page.dart';

class EmployeesListPage extends StatefulWidget {
  const EmployeesListPage({super.key});

  @override
  State<EmployeesListPage> createState() => _EmployeesListPageState();
}

class _EmployeesListPageState extends State<EmployeesListPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  EmployeeStatus? _selectedStatus;
  String? _selectedDepartment;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmployeesProvider>().refreshData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Employee> _getFilteredEmployees(List<Employee> employees) {
    var filtered = employees;

    // Filtro por busca
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((emp) {
        final query = _searchQuery.toLowerCase();
        return emp.name.toLowerCase().contains(query) ||
            emp.email.toLowerCase().contains(query) ||
            emp.department.toLowerCase().contains(query) ||
            emp.position.toLowerCase().contains(query);
      }).toList();
    }

    // Filtro por status
    if (_selectedStatus != null) {
      filtered =
          filtered.where((emp) => emp.status == _selectedStatus).toList();
    }

    // Filtro por departamento
    if (_selectedDepartment != null && _selectedDepartment!.isNotEmpty) {
      filtered = filtered
          .where((emp) => emp.department == _selectedDepartment)
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Funcionários'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<EmployeesProvider>().refreshData();
            },
          ),
        ],
      ),
      body: Consumer<EmployeesProvider>(
        builder: (context, employeesProvider, child) {
          if (employeesProvider.isLoading &&
              employeesProvider.employees.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final filteredEmployees =
              _getFilteredEmployees(employeesProvider.employees);

          return Column(
            children: [
              // Barra de busca e filtros
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey[50],
                child: Column(
                  children: [
                    // Campo de busca
                    CustomTextField(
                      controller: _searchController,
                      label: 'Buscar funcionários',
                      hintText: 'Nome, email, departamento ou cargo...',
                      prefixIcon: Icons.search,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    // Filtros
                    Row(
                      children: [
                        // Filtro por status
                        Expanded(
                          child: DropdownButtonFormField<EmployeeStatus?>(
                            value: _selectedStatus,
                            decoration: InputDecoration(
                              labelText: 'Status',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            items: [
                              const DropdownMenuItem<EmployeeStatus?>(
                                value: null,
                                child: Text('Todos'),
                              ),
                              ...EmployeeStatus.values.map(
                                (status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status.label),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedStatus = value;
                              });
                            },
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Filtro por departamento
                        Expanded(
                          child: DropdownButtonFormField<String?>(
                            value: _selectedDepartment,
                            decoration: InputDecoration(
                              labelText: 'Departamento',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('Todos'),
                              ),
                              ...employeesProvider.departments.map(
                                (dept) => DropdownMenuItem(
                                  value: dept.name,
                                  child: Text(dept.name),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedDepartment = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Estatísticas rápidas
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard(
                      'Total',
                      employeesProvider.getTotalEmployeesCount().toString(),
                      Icons.people,
                      Colors.blue,
                    ),
                    _buildStatCard(
                      'Ativos',
                      employeesProvider.getActiveEmployeesCount().toString(),
                      Icons.check_circle,
                      Colors.green,
                    ),
                    _buildStatCard(
                      'Inativos',
                      employeesProvider.getInactiveEmployeesCount().toString(),
                      Icons.pause_circle,
                      Colors.orange,
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Lista de funcionários
              Expanded(
                child: filteredEmployees.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty ||
                                      _selectedStatus != null ||
                                      _selectedDepartment != null
                                  ? 'Nenhum funcionário encontrado com os filtros aplicados'
                                  : 'Nenhum funcionário cadastrado',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => employeesProvider.refreshData(),
                        child: ListView.builder(
                          itemCount: filteredEmployees.length,
                          itemBuilder: (context, index) {
                            final employee = filteredEmployees[index];
                            return _buildEmployeeCard(employee);
                          },
                        ),
                      ),
              ),

              // Mensagem de erro
              if (employeesProvider.error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.red[50],
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          employeesProvider.error!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: employeesProvider.clearError,
                        color: Colors.red[700],
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EmployeeFormPage(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(76)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard(Employee employee) {
    final currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(employee.status),
          child: Text(
            employee.name
                .split(' ')
                .map((n) => n[0])
                .take(2)
                .join()
                .toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        title: Text(
          employee.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(employee.position),
            Text(
              '${employee.department} • ${currencyFormat.format(employee.salary)}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(employee.status).withAlpha(25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getStatusColor(employee.status).withAlpha(76),
                ),
              ),
              child: Text(
                employee.status.label,
                style: TextStyle(
                  color: _getStatusColor(employee.status),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EmployeeDetailsPage(employee: employee),
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(EmployeeStatus status) {
    switch (status) {
      case EmployeeStatus.active:
        return Colors.green;
      case EmployeeStatus.inactive:
        return Colors.orange;
      case EmployeeStatus.suspended:
        return Colors.red;
    }
  }
}
