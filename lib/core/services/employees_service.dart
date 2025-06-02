import 'dart:convert';
import '../config/api_config.dart';
import 'api_client.dart';
import '../../data/models/employee.dart';

class EmployeesService {
  static final EmployeesService _instance = EmployeesService._internal();
  factory EmployeesService() => _instance;
  EmployeesService._internal();

  final ApiClient _apiClient = ApiClient();

  /// Busca todos os funcionários
  Future<List<Employee>> getEmployees({
    int page = 1,
    int limit = 50,
    String? department,
    EmployeeStatus? status,
    String? search,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (department != null && department.isNotEmpty) {
        queryParams['department'] = department;
      }

      if (status != null) {
        queryParams['status'] = status.value;
      }

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final endpoint = '${ApiConfig.employeesEndpoint}?$queryString';
      final response = await _apiClient.get(endpoint);

      final employeesData = response['data'] as List<dynamic>? ?? response['employees'] as List<dynamic>? ?? [];
      return employeesData.map((json) => Employee.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar funcionários: $e');
    }
  }

  /// Busca um funcionário específico por ID
  Future<Employee?> getEmployeeById(String id) async {
    try {
      final response = await _apiClient.get('${ApiConfig.employeesEndpoint}/$id');
      return Employee.fromJson(response['data'] ?? response);
    } catch (e) {
      return null;
    }
  }

  /// Cria um novo funcionário
  Future<Employee> createEmployee({
    required String name,
    required String email,
    required String position,
    required String department,
    required EmployeeRole role,
    required double salary,
    required DateTime hireDate,
    String? phone,
    String? document,
    String? address,
    EmployeeStatus status = EmployeeStatus.active,
  }) async {
    try {
      final employeeData = {
        'name': name,
        'email': email,
        'position': position,
        'department': department,
        'role': role.value,
        'salary': salary,
        'hire_date': hireDate.toIso8601String(),
        'phone': phone,
        'document': document,
        'address': address,
        'status': status.value,
      };

      final response = await _apiClient.post(ApiConfig.employeesEndpoint, data: employeeData);
      return Employee.fromJson(response['data'] ?? response);
    } catch (e) {
      throw Exception('Erro ao criar funcionário: $e');
    }
  }

  /// Atualiza um funcionário existente
  Future<Employee> updateEmployee(String id, {
    String? name,
    String? email,
    String? position,
    String? department,
    EmployeeRole? role,
    double? salary,
    DateTime? hireDate,
    String? phone,
    String? document,
    String? address,
    EmployeeStatus? status,
    DateTime? terminationDate,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (name != null) updateData['name'] = name;
      if (email != null) updateData['email'] = email;
      if (position != null) updateData['position'] = position;
      if (department != null) updateData['department'] = department;
      if (role != null) updateData['role'] = role.value;
      if (salary != null) updateData['salary'] = salary;
      if (hireDate != null) updateData['hire_date'] = hireDate.toIso8601String();
      if (phone != null) updateData['phone'] = phone;
      if (document != null) updateData['document'] = document;
      if (address != null) updateData['address'] = address;
      if (status != null) updateData['status'] = status.value;
      if (terminationDate != null) updateData['termination_date'] = terminationDate.toIso8601String();

      final response = await _apiClient.put('${ApiConfig.employeesEndpoint}/$id', data: updateData);
      return Employee.fromJson(response['data'] ?? response);
    } catch (e) {
      throw Exception('Erro ao atualizar funcionário: $e');
    }
  }

  /// Atualiza apenas o status de um funcionário
  Future<bool> updateEmployeeStatus(String id, EmployeeStatus status) async {
    try {
      await _apiClient.put(
        '${ApiConfig.employeesEndpoint}/$id/status',
        data: {'status': status.value},
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Exclui um funcionário
  Future<bool> deleteEmployee(String id) async {
    try {
      await _apiClient.delete('${ApiConfig.employeesEndpoint}/$id');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Busca departamentos disponíveis
  Future<List<String>> getDepartments() async {
    try {
      final response = await _apiClient.get('${ApiConfig.employeesEndpoint}/departments');
      final departmentsData = response['data'] as List<dynamic>? ?? response['departments'] as List<dynamic>? ?? [];
      return departmentsData.map((dept) => dept.toString()).toList();
    } catch (e) {
      // Retorna departamentos padrão em caso de erro
      return [
        'Tecnologia da Informação',
        'Recursos Humanos',
        'Vendas',
        'Marketing',
        'Operações',
        'Financeiro',
        'Atendimento ao Cliente',
        'Logística',
      ];
    }
  }

  /// Busca cargos disponíveis por departamento
  Future<List<String>> getPositionsByDepartment(String department) async {
    try {
      final response = await _apiClient.get('${ApiConfig.employeesEndpoint}/positions?department=${Uri.encodeComponent(department)}');
      final positionsData = response['data'] as List<dynamic>? ?? response['positions'] as List<dynamic>? ?? [];
      return positionsData.map((pos) => pos.toString()).toList();
    } catch (e) {
      // Retorna cargos padrão baseados no departamento
      return _getDefaultPositions(department);
    }
  }

  /// Busca estatísticas de funcionários
  Future<Map<String, dynamic>> getEmployeesStats() async {
    try {
      final response = await _apiClient.get('${ApiConfig.employeesEndpoint}/stats');
      return response['data'] ?? response;
    } catch (e) {
      // Retorna estatísticas vazias em caso de erro
      return {
        'total_employees': 0,
        'active_employees': 0,
        'inactive_employees': 0,
        'suspended_employees': 0,
        'departments_count': 0,
        'average_salary': 0.0,
      };
    }
  }

  /// Busca funcionários por departamento
  Future<List<Employee>> getEmployeesByDepartment(String department) async {
    return getEmployees(department: department);
  }

  /// Busca funcionários por status
  Future<List<Employee>> getEmployeesByStatus(EmployeeStatus status) async {
    return getEmployees(status: status);
  }

  /// Valida se um email já está em uso
  Future<bool> isEmailAvailable(String email, {String? excludeId}) async {
    try {
      final response = await _apiClient.get('${ApiConfig.employeesEndpoint}/validate-email?email=${Uri.encodeComponent(email)}${excludeId != null ? '&exclude_id=$excludeId' : ''}');
      return response['available'] ?? true;
    } catch (e) {
      // Em caso de erro, assume que está disponível
      return true;
    }
  }

  /// Valida se um documento já está em uso
  Future<bool> isDocumentAvailable(String document, {String? excludeId}) async {
    try {
      final response = await _apiClient.get('${ApiConfig.employeesEndpoint}/validate-document?document=${Uri.encodeComponent(document)}${excludeId != null ? '&exclude_id=$excludeId' : ''}');
      return response['available'] ?? true;
    } catch (e) {
      // Em caso de erro, assume que está disponível
      return true;
    }
  }

  /// Cargos padrão por departamento
  List<String> _getDefaultPositions(String department) {
    switch (department.toLowerCase()) {
      case 'tecnologia da informação':
      case 'ti':
        return [
          'Desenvolvedor Frontend',
          'Desenvolvedor Backend',
          'Desenvolvedor Full Stack',
          'Analista de Sistemas',
          'Arquiteto de Software',
          'DevOps Engineer',
          'Analista de Suporte',
          'Gerente de TI',
        ];
      case 'recursos humanos':
      case 'rh':
        return [
          'Analista de RH',
          'Especialista em Recrutamento',
          'Coordenador de RH',
          'Gerente de RH',
          'Analista de Folha de Pagamento',
          'Business Partner',
        ];
      case 'vendas':
        return [
          'Vendedor',
          'Consultor de Vendas',
          'Coordenador de Vendas',
          'Gerente de Vendas',
          'Diretor Comercial',
          'Account Manager',
        ];
      case 'marketing':
        return [
          'Analista de Marketing',
          'Designer Gráfico',
          'Social Media',
          'Coordenador de Marketing',
          'Gerente de Marketing',
          'Especialista em SEO',
        ];
      case 'operações':
        return [
          'Analista de Operações',
          'Coordenador de Operações',
          'Gerente de Operações',
          'Supervisor de Produção',
          'Analista de Processos',
        ];
      case 'financeiro':
        return [
          'Analista Financeiro',
          'Contador',
          'Coordenador Financeiro',
          'Gerente Financeiro',
          'Controller',
          'Analista de Contas a Pagar',
          'Analista de Contas a Receber',
        ];
      default:
        return [
          'Assistente',
          'Analista',
          'Coordenador',
          'Supervisor',
          'Gerente',
          'Diretor',
        ];
    }
  }
}

