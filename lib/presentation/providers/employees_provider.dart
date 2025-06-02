import 'package:flutter/foundation.dart';
import '../../core/services/employees_service.dart';
import '../../data/models/employee.dart';

class EmployeesProvider extends ChangeNotifier {
  final EmployeesService _employeesService = EmployeesService();
  
  List<Employee> _employees = [];
  List<Department> _departments = [];
  bool _isLoading = false;
  String? _error;
  Employee? _selectedEmployee;

  // Getters
  List<Employee> get employees => _employees;
  List<Department> get departments => _departments;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Employee? get selectedEmployee => _selectedEmployee;

  // Filtered employees
  List<Employee> getEmployeesByDepartment(String department) {
    return _employees.where((emp) => emp.department == department).toList();
  }

  List<Employee> getEmployeesByStatus(EmployeeStatus status) {
    return _employees.where((emp) => emp.status == status).toList();
  }

  List<Employee> getActiveEmployees() {
    return getEmployeesByStatus(EmployeeStatus.active);
  }

  List<Employee> searchEmployees(String query) {
    if (query.isEmpty) return _employees;
    
    final lowercaseQuery = query.toLowerCase();
    return _employees.where((emp) {
      return emp.name.toLowerCase().contains(lowercaseQuery) ||
             emp.email.toLowerCase().contains(lowercaseQuery) ||
             emp.department.toLowerCase().contains(lowercaseQuery) ||
             emp.position.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  Future<void> loadEmployees() async {
    _setLoading(true);
    _clearError();

    try {
      _employees = await _employeesService.getEmployees();
      notifyListeners();
    } catch (e) {
      _setError('Erro ao carregar funcionários: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadDepartments() async {
    _setLoading(true);
    _clearError();

    try {
      _departments = await _employeesService.getDepartments();
      notifyListeners();
    } catch (e) {
      _setError('Erro ao carregar departamentos: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createEmployee({
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
    _setLoading(true);
    _clearError();

    try {
      final newEmployee = await _employeesService.createEmployee(
        name: name,
        email: email,
        phone: phone,
        document: document,
        department: department,
        position: position,
        role: role,
        salary: salary,
        hireDate: hireDate,
        address: address,
      );

      _employees.insert(0, newEmployee);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateEmployee(
    String employeeId, {
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
    _setLoading(true);
    _clearError();

    try {
      final updatedEmployee = await _employeesService.updateEmployee(
        employeeId,
        name: name,
        email: email,
        phone: phone,
        document: document,
        department: department,
        position: position,
        role: role,
        status: status,
        salary: salary,
        hireDate: hireDate,
        terminationDate: terminationDate,
        address: address,
      );
      
      final index = _employees.indexWhere((emp) => emp.id == employeeId);
      if (index != -1) {
        _employees[index] = updatedEmployee;
        
        // Atualiza o funcionário selecionado se for o mesmo
        if (_selectedEmployee?.id == employeeId) {
          _selectedEmployee = updatedEmployee;
        }
        
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteEmployee(String employeeId) async {
    _setLoading(true);
    _clearError();

    try {
      await _employeesService.deleteEmployee(employeeId);
      _employees.removeWhere((emp) => emp.id == employeeId);
      
      // Limpa o funcionário selecionado se for o mesmo que foi deletado
      if (_selectedEmployee?.id == employeeId) {
        _selectedEmployee = null;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erro ao deletar funcionário: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void selectEmployee(Employee employee) {
    _selectedEmployee = employee;
    notifyListeners();
  }

  void clearSelectedEmployee() {
    _selectedEmployee = null;
    notifyListeners();
  }

  // Estatísticas
  int getTotalEmployeesCount() {
    return _employees.length;
  }

  int getActiveEmployeesCount() {
    return _employees.where((emp) => emp.status == EmployeeStatus.active).length;
  }

  int getInactiveEmployeesCount() {
    return _employees.where((emp) => emp.status == EmployeeStatus.inactive).length;
  }

  Map<String, int> getEmployeesByDepartmentCount() {
    final Map<String, int> departmentCounts = {};
    
    for (final employee in _employees) {
      departmentCounts[employee.department] = 
          (departmentCounts[employee.department] ?? 0) + 1;
    }
    
    return departmentCounts;
  }

  Map<EmployeeRole, int> getEmployeesByRoleCount() {
    final Map<EmployeeRole, int> roleCounts = {};
    
    for (final employee in _employees) {
      roleCounts[employee.role] = (roleCounts[employee.role] ?? 0) + 1;
    }
    
    return roleCounts;
  }

  double getAverageSalary() {
    if (_employees.isEmpty) return 0.0;
    
    final totalSalary = _employees.fold(0.0, (sum, emp) => sum + emp.salary);
    return totalSalary / _employees.length;
  }

  double getTotalPayroll() {
    return _employees
        .where((emp) => emp.status == EmployeeStatus.active)
        .fold(0.0, (sum, emp) => sum + emp.salary);
  }

  List<Employee> getRecentHires({int limit = 5}) {
    final sortedEmployees = List<Employee>.from(_employees);
    sortedEmployees.sort((a, b) => b.hireDate.compareTo(a.hireDate));
    return sortedEmployees.take(limit).toList();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }

  Future<void> refreshData() async {
    await Future.wait([
      loadEmployees(),
      loadDepartments(),
    ]);
  }
}

