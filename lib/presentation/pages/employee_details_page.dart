import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/employees_provider.dart';
import '../../data/models/employee.dart';
import 'employee_form_page.dart';

class EmployeeDetailsPage extends StatelessWidget {
  final Employee employee;

  const EmployeeDetailsPage({super.key, required this.employee});

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Funcionário'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EmployeeFormPage(employee: employee),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _showDeleteConfirmation(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Excluir', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com foto e informações básicas
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withAlpha(204),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white.withAlpha(51),
                    child: Text(
                      employee.name
                          .split(' ')
                          .map((n) => n[0])
                          .take(2)
                          .join()
                          .toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    employee.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    employee.position,
                    style: TextStyle(
                      color: Colors.white.withAlpha(229),
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    employee.department,
                    style: TextStyle(
                      color: Colors.white.withAlpha(204),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _getStatusColor(employee.status).withAlpha(51),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor(employee.status).withAlpha(127),
                      ),
                    ),
                    child: Text(
                      employee.status.label,
                      style: TextStyle(
                        color: _getStatusColor(employee.status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Informações de Contato
            _buildSection(
              'Informações de Contato',
              [
                _buildInfoRow(Icons.email, 'Email', employee.email),
                if (employee.phone != null)
                  _buildInfoRow(Icons.phone, 'Telefone', employee.phone!),
                if (employee.document != null)
                  _buildInfoRow(
                      Icons.badge, 'CPF', _formatCPF(employee.document!)),
                if (employee.address != null)
                  _buildInfoRow(
                      Icons.location_on, 'Endereço', employee.address!),
              ],
            ),

            const SizedBox(height: 24),

            // Informações Profissionais
            _buildSection(
              'Informações Profissionais',
              [
                _buildInfoRow(
                    Icons.business, 'Departamento', employee.department),
                _buildInfoRow(Icons.work, 'Cargo', employee.position),
                _buildInfoRow(
                    Icons.admin_panel_settings, 'Função', employee.role.label),
                _buildInfoRow(Icons.attach_money, 'Salário',
                    currencyFormat.format(employee.salary)),
                _buildInfoRow(Icons.calendar_today, 'Data de Contratação',
                    dateFormat.format(employee.hireDate)),
                if (employee.terminationDate != null)
                  _buildInfoRow(Icons.event_busy, 'Data de Desligamento',
                      dateFormat.format(employee.terminationDate!)),
              ],
            ),

            const SizedBox(height: 24),

            // Informações do Sistema
            _buildSection(
              'Informações do Sistema',
              [
                _buildInfoRow(Icons.person_add, 'Cadastrado em',
                    dateFormat.format(employee.createdAt)),
                if (employee.updatedAt != null)
                  _buildInfoRow(Icons.update, 'Última atualização',
                      dateFormat.format(employee.updatedAt!)),
                _buildInfoRow(Icons.fingerprint, 'ID do Sistema', employee.id),
              ],
            ),

            const SizedBox(height: 32),

            // Botões de Ação
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EmployeeFormPage(employee: employee),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showDeleteConfirmation(context),
                    icon: const Icon(Icons.delete),
                    label: const Text('Excluir'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
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

  String _formatCPF(String cpf) {
    if (cpf.length == 11) {
      return '${cpf.substring(0, 3)}.${cpf.substring(3, 6)}.${cpf.substring(6, 9)}-${cpf.substring(9)}';
    }
    return cpf;
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: Text(
            'Tem certeza que deseja excluir o funcionário "${employee.name}"?\n\nEsta ação não pode ser desfeita.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            Consumer<EmployeesProvider>(
              builder: (context, employeesProvider, child) {
                return ElevatedButton(
                  onPressed: employeesProvider.isLoading
                      ? null
                      : () async {
                          final success = await employeesProvider
                              .deleteEmployee(employee.id);
                          if (success && context.mounted) {
                            Navigator.of(context).pop(); // Fecha o dialog
                            Navigator.of(context).pop(); // Volta para a lista
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Funcionário excluído com sucesso!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: employeesProvider.isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Excluir'),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
