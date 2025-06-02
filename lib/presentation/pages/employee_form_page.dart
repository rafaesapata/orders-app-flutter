import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/employees_provider.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../../data/models/employee.dart';

class EmployeeFormPage extends StatefulWidget {
  final Employee? employee;

  const EmployeeFormPage({super.key, this.employee});

  @override
  State<EmployeeFormPage> createState() => _EmployeeFormPageState();
}

class _EmployeeFormPageState extends State<EmployeeFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _documentController = TextEditingController();
  final _positionController = TextEditingController();
  final _salaryController = TextEditingController();
  final _addressController = TextEditingController();
  
  String? _selectedDepartment;
  EmployeeRole _selectedRole = EmployeeRole.employee;
  EmployeeStatus _selectedStatus = EmployeeStatus.active;
  DateTime _selectedHireDate = DateTime.now();

  bool get isEditing => widget.employee != null;

  @override
  void initState() {
    super.initState();
    _loadEmployeeData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmployeesProvider>().loadDepartments();
    });
  }

  void _loadEmployeeData() {
    if (widget.employee != null) {
      final employee = widget.employee!;
      _nameController.text = employee.name;
      _emailController.text = employee.email;
      _phoneController.text = employee.phone ?? '';
      _documentController.text = employee.document ?? '';
      _positionController.text = employee.position;
      _salaryController.text = employee.salary.toStringAsFixed(2);
      _addressController.text = employee.address ?? '';
      _selectedDepartment = employee.department;
      _selectedRole = employee.role;
      _selectedStatus = employee.status;
      _selectedHireDate = employee.hireDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _documentController.dispose();
    _positionController.dispose();
    _salaryController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedHireDate,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    
    if (date != null) {
      setState(() {
        _selectedHireDate = date;
      });
    }
  }

  Future<void> _saveEmployee() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDepartment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione um departamento'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final employeesProvider = context.read<EmployeesProvider>();
    bool success;

    if (isEditing) {
      success = await employeesProvider.updateEmployee(
        widget.employee!.id,
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text.isEmpty ? null : _phoneController.text,
        document: _documentController.text.isEmpty ? null : _documentController.text,
        department: _selectedDepartment!,
        position: _positionController.text,
        role: _selectedRole,
        status: _selectedStatus,
        salary: double.parse(_salaryController.text.replaceAll(',', '.')),
        hireDate: _selectedHireDate,
        address: _addressController.text.isEmpty ? null : _addressController.text,
      );
    } else {
      success = await employeesProvider.createEmployee(
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text.isEmpty ? null : _phoneController.text,
        document: _documentController.text.isEmpty ? null : _documentController.text,
        department: _selectedDepartment!,
        position: _positionController.text,
        role: _selectedRole,
        salary: double.parse(_salaryController.text.replaceAll(',', '.')),
        hireDate: _selectedHireDate,
        address: _addressController.text.isEmpty ? null : _addressController.text,
      );
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing 
                ? 'Funcionário atualizado com sucesso!'
                : 'Funcionário cadastrado com sucesso!',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Funcionário' : 'Novo Funcionário'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<EmployeesProvider>(
        builder: (context, employeesProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Informações Pessoais
                  _buildSectionHeader('Informações Pessoais'),
                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: _nameController,
                    label: 'Nome Completo *',
                    hintText: 'Digite o nome completo',
                    prefixIcon: Icons.person,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nome é obrigatório';
                      }
                      if (value.trim().length < 2) {
                        return 'Nome deve ter pelo menos 2 caracteres';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: _emailController,
                    label: 'Email *',
                    hintText: 'Digite o email',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email é obrigatório';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Email inválido';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _phoneController,
                          label: 'Telefone',
                          hintText: '(11) 99999-9999',
                          keyboardType: TextInputType.phone,
                          prefixIcon: Icons.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(11),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CustomTextField(
                          controller: _documentController,
                          label: 'CPF',
                          hintText: '000.000.000-00',
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.badge,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(11),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: _addressController,
                    label: 'Endereço',
                    hintText: 'Digite o endereço completo',
                    prefixIcon: Icons.location_on,
                    maxLines: 2,
                  ),

                  const SizedBox(height: 24),

                  // Informações Profissionais
                  _buildSectionHeader('Informações Profissionais'),
                  const SizedBox(height: 16),

                  // Departamento
                  DropdownButtonFormField<String>(
                    value: _selectedDepartment,
                    decoration: InputDecoration(
                      labelText: 'Departamento *',
                      prefixIcon: const Icon(Icons.business),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    items: employeesProvider.departments.map((dept) {
                      return DropdownMenuItem(
                        value: dept.name,
                        child: Text(dept.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDepartment = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Departamento é obrigatório';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: _positionController,
                    label: 'Cargo *',
                    hintText: 'Digite o cargo',
                    prefixIcon: Icons.work,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Cargo é obrigatório';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      // Função
                      Expanded(
                        child: DropdownButtonFormField<EmployeeRole>(
                          value: _selectedRole,
                          decoration: InputDecoration(
                            labelText: 'Função',
                            prefixIcon: const Icon(Icons.admin_panel_settings),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          items: EmployeeRole.values.map((role) {
                            return DropdownMenuItem(
                              value: role,
                              child: Text(role.label),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedRole = value;
                              });
                            }
                          },
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Status (apenas para edição)
                      if (isEditing)
                        Expanded(
                          child: DropdownButtonFormField<EmployeeStatus>(
                            value: _selectedStatus,
                            decoration: InputDecoration(
                              labelText: 'Status',
                              prefixIcon: const Icon(Icons.toggle_on),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            items: EmployeeStatus.values.map((status) {
                              return DropdownMenuItem(
                                value: status,
                                child: Text(status.label),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedStatus = value;
                                });
                              }
                            },
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      // Salário
                      Expanded(
                        child: CustomTextField(
                          controller: _salaryController,
                          label: 'Salário *',
                          hintText: '0,00',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          prefixIcon: Icons.attach_money,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Salário é obrigatório';
                            }
                            final salary = double.tryParse(value.replaceAll(',', '.'));
                            if (salary == null || salary <= 0) {
                              return 'Salário deve ser maior que zero';
                            }
                            return null;
                          },
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Data de Contratação
                      Expanded(
                        child: InkWell(
                          onTap: _selectDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey[50],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, color: Colors.grey),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Data de Contratação *',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat('dd/MM/yyyy').format(_selectedHireDate),
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Mensagem de erro
                  if (employeesProvider.error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              employeesProvider.error!,
                              style: TextStyle(color: Colors.red[700]),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: employeesProvider.clearError,
                            color: Colors.red[700],
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),

                  // Botões
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: isEditing ? 'Atualizar' : 'Cadastrar',
                          onPressed: employeesProvider.isLoading ? null : _saveEmployee,
                          isLoading: employeesProvider.isLoading,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).primaryColor,
      ),
    );
  }
}

