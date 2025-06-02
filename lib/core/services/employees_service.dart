import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/employee.dart';

class EmployeesService {
  static const String _employeesKey = 'employees_data';
  static const String _departmentsKey = 'departments_data';
  final _uuid = const Uuid();

  // Departamentos de exemplo
  static final List<Department> _sampleDepartments = [
    Department(
      id: '1',
      name: 'Recursos Humanos',
      description: 'Gestão de pessoas e desenvolvimento organizacional',
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
    ),
    Department(
      id: '2',
      name: 'Tecnologia da Informação',
      description: 'Desenvolvimento e manutenção de sistemas',
      createdAt: DateTime.now().subtract(const Duration(days: 300)),
    ),
    Department(
      id: '3',
      name: 'Vendas',
      description: 'Comercialização de produtos e serviços',
      createdAt: DateTime.now().subtract(const Duration(days: 250)),
    ),
    Department(
      id: '4',
      name: 'Marketing',
      description: 'Estratégias de marketing e comunicação',
      createdAt: DateTime.now().subtract(const Duration(days: 200)),
    ),
    Department(
      id: '5',
      name: 'Financeiro',
      description: 'Gestão financeira e contábil',
      createdAt: DateTime.now().subtract(const Duration(days: 150)),
    ),
    Department(
      id: '6',
      name: 'Operações',
      description: 'Gestão operacional e logística',
      createdAt: DateTime.now().subtract(const Duration(days: 100)),
    ),
  ];

  Future<List<Employee>> getEmployees() async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simula delay de rede
    
    final prefs = await SharedPreferences.getInstance();
    final employeesJson = prefs.getString(_employeesKey);
    
    if (employeesJson == null) {
      // Retorna funcionários de exemplo na primeira execução
      final sampleEmployees = _generateSampleEmployees();
      await _saveEmployees(sampleEmployees);
      return sampleEmployees;
    }
    
    try {
      final employeesList = jsonDecode(employeesJson) as List<dynamic>;
      return employeesList
          .map((json) => Employee.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<Employee?> getEmployeeById(String id) async {
    final employees = await getEmployees();
    try {
      return employees.firstWhere((employee) => employee.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<Employee> createEmployee({
    required String name,
    required String email,
    String? phone,
    String? document,
    required String department,
    required String position,
    required EmployeeRole role,
    required double salary,
    required DateTime hireDate,
    String? address,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800)); // Simula delay de rede

    // Validações
    if (name.trim().isEmpty) {
      throw Exception('Nome é obrigatório');
    }

    if (email.trim().isEmpty || !_isValidEmail(email)) {
      throw Exception('Email válido é obrigatório');
    }

    if (department.trim().isEmpty) {
      throw Exception('Departamento é obrigatório');
    }

    if (position.trim().isEmpty) {
      throw Exception('Cargo é obrigatório');
    }

    if (salary <= 0) {
      throw Exception('Salário deve ser maior que zero');
    }

    // Verifica se email já existe
    final existingEmployees = await getEmployees();
    final emailExists = existingEmployees.any(
      (emp) => emp.email.toLowerCase() == email.toLowerCase().trim(),
    );

    if (emailExists) {
      throw Exception('Email já está em uso por outro funcionário');
    }

    final employee = Employee(
      id: _uuid.v4(),
      name: name.trim(),
      email: email.toLowerCase().trim(),
      phone: phone?.trim(),
      document: document?.trim(),
      department: department.trim(),
      position: position.trim(),
      role: role,
      status: EmployeeStatus.active,
      salary: salary,
      hireDate: hireDate,
      address: address?.trim(),
      createdAt: DateTime.now(),
    );

    final employees = await getEmployees();
    employees.insert(0, employee); // Adiciona no início da lista
    await _saveEmployees(employees);

    return employee;
  }

  Future<Employee> updateEmployee(String employeeId, {
    String? name,
    String? email,
    String? phone,
    String? document,
    String? department,
    String? position,
    EmployeeRole? role,
    EmployeeStatus? status,
    double? salary,
    DateTime? hireDate,
    DateTime? terminationDate,
    String? address,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final employees = await getEmployees();
    final employeeIndex = employees.indexWhere((emp) => emp.id == employeeId);
    
    if (employeeIndex == -1) {
      throw Exception('Funcionário não encontrado');
    }

    final currentEmployee = employees[employeeIndex];

    // Verifica se o novo email já existe (se foi alterado)
    if (email != null && email.toLowerCase().trim() != currentEmployee.email) {
      final emailExists = employees.any(
        (emp) => emp.id != employeeId && emp.email.toLowerCase() == email.toLowerCase().trim(),
      );

      if (emailExists) {
        throw Exception('Email já está em uso por outro funcionário');
      }
    }

    final updatedEmployee = currentEmployee.copyWith(
      name: name?.trim(),
      email: email?.toLowerCase().trim(),
      phone: phone?.trim(),
      document: document?.trim(),
      department: department?.trim(),
      position: position?.trim(),
      role: role,
      status: status,
      salary: salary,
      hireDate: hireDate,
      terminationDate: terminationDate,
      address: address?.trim(),
      updatedAt: DateTime.now(),
    );

    employees[employeeIndex] = updatedEmployee;
    await _saveEmployees(employees);

    return updatedEmployee;
  }

  Future<void> deleteEmployee(String employeeId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final employees = await getEmployees();
    final employeeExists = employees.any((emp) => emp.id == employeeId);
    
    if (!employeeExists) {
      throw Exception('Funcionário não encontrado');
    }

    employees.removeWhere((emp) => emp.id == employeeId);
    await _saveEmployees(employees);
  }

  Future<List<Department>> getDepartments() async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final prefs = await SharedPreferences.getInstance();
    final departmentsJson = prefs.getString(_departmentsKey);
    
    if (departmentsJson == null) {
      await _saveDepartments(_sampleDepartments);
      return _sampleDepartments;
    }
    
    try {
      final departmentsList = jsonDecode(departmentsJson) as List<dynamic>;
      return departmentsList
          .map((json) => Department.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return _sampleDepartments;
    }
  }

  Future<List<Employee>> getEmployeesByDepartment(String department) async {
    final employees = await getEmployees();
    return employees.where((emp) => emp.department == department).toList();
  }

  Future<List<Employee>> getEmployeesByStatus(EmployeeStatus status) async {
    final employees = await getEmployees();
    return employees.where((emp) => emp.status == status).toList();
  }

  Future<List<Employee>> searchEmployees(String query) async {
    final employees = await getEmployees();
    final lowercaseQuery = query.toLowerCase();
    
    return employees.where((emp) {
      return emp.name.toLowerCase().contains(lowercaseQuery) ||
             emp.email.toLowerCase().contains(lowercaseQuery) ||
             emp.department.toLowerCase().contains(lowercaseQuery) ||
             emp.position.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  Future<void> _saveEmployees(List<Employee> employees) async {
    final prefs = await SharedPreferences.getInstance();
    final employeesJson = jsonEncode(employees.map((emp) => emp.toJson()).toList());
    await prefs.setString(_employeesKey, employeesJson);
  }

  Future<void> _saveDepartments(List<Department> departments) async {
    final prefs = await SharedPreferences.getInstance();
    final departmentsJson = jsonEncode(departments.map((dept) => dept.toJson()).toList());
    await prefs.setString(_departmentsKey, departmentsJson);
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  List<Employee> _generateSampleEmployees() {
    final now = DateTime.now();
    return [
      Employee(
        id: _uuid.v4(),
        name: 'Ana Silva Santos',
        email: 'ana.silva@empresa.com',
        phone: '(11) 99999-1111',
        document: '123.456.789-01',
        department: 'Recursos Humanos',
        position: 'Gerente de RH',
        role: EmployeeRole.manager,
        status: EmployeeStatus.active,
        salary: 8500.00,
        hireDate: now.subtract(const Duration(days: 730)),
        address: 'Rua das Flores, 123 - São Paulo/SP',
        createdAt: now.subtract(const Duration(days: 730)),
      ),
      Employee(
        id: _uuid.v4(),
        name: 'Carlos Eduardo Lima',
        email: 'carlos.lima@empresa.com',
        phone: '(11) 88888-2222',
        document: '234.567.890-12',
        department: 'Tecnologia da Informação',
        position: 'Desenvolvedor Senior',
        role: EmployeeRole.employee,
        status: EmployeeStatus.active,
        salary: 7200.00,
        hireDate: now.subtract(const Duration(days: 500)),
        address: 'Av. Paulista, 456 - São Paulo/SP',
        createdAt: now.subtract(const Duration(days: 500)),
      ),
      Employee(
        id: _uuid.v4(),
        name: 'Mariana Costa Oliveira',
        email: 'mariana.costa@empresa.com',
        phone: '(11) 77777-3333',
        document: '345.678.901-23',
        department: 'Vendas',
        position: 'Consultora de Vendas',
        role: EmployeeRole.employee,
        status: EmployeeStatus.active,
        salary: 4500.00,
        hireDate: now.subtract(const Duration(days: 300)),
        address: 'Rua Augusta, 789 - São Paulo/SP',
        createdAt: now.subtract(const Duration(days: 300)),
      ),
      Employee(
        id: _uuid.v4(),
        name: 'Roberto Ferreira',
        email: 'roberto.ferreira@empresa.com',
        phone: '(11) 66666-4444',
        document: '456.789.012-34',
        department: 'Marketing',
        position: 'Analista de Marketing',
        role: EmployeeRole.employee,
        status: EmployeeStatus.active,
        salary: 5200.00,
        hireDate: now.subtract(const Duration(days: 180)),
        address: 'Rua Oscar Freire, 321 - São Paulo/SP',
        createdAt: now.subtract(const Duration(days: 180)),
      ),
      Employee(
        id: _uuid.v4(),
        name: 'Juliana Mendes',
        email: 'juliana.mendes@empresa.com',
        phone: '(11) 55555-5555',
        document: '567.890.123-45',
        department: 'Financeiro',
        position: 'Supervisora Financeira',
        role: EmployeeRole.supervisor,
        status: EmployeeStatus.active,
        salary: 6800.00,
        hireDate: now.subtract(const Duration(days: 400)),
        address: 'Rua Consolação, 654 - São Paulo/SP',
        createdAt: now.subtract(const Duration(days: 400)),
      ),
      Employee(
        id: _uuid.v4(),
        name: 'Pedro Henrique Souza',
        email: 'pedro.souza@empresa.com',
        phone: '(11) 44444-6666',
        document: '678.901.234-56',
        department: 'Operações',
        position: 'Estagiário',
        role: EmployeeRole.intern,
        status: EmployeeStatus.active,
        salary: 1800.00,
        hireDate: now.subtract(const Duration(days: 90)),
        address: 'Rua da Liberdade, 987 - São Paulo/SP',
        createdAt: now.subtract(const Duration(days: 90)),
      ),
    ];
  }
}

