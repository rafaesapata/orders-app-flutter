enum EmployeeStatus {
  active('active', 'Ativo'),
  inactive('inactive', 'Inativo'),
  suspended('suspended', 'Suspenso');

  const EmployeeStatus(this.value, this.label);
  final String value;
  final String label;

  static EmployeeStatus fromValue(String value) {
    return EmployeeStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => EmployeeStatus.active,
    );
  }
}

enum EmployeeRole {
  admin('admin', 'Administrador'),
  manager('manager', 'Gerente'),
  supervisor('supervisor', 'Supervisor'),
  employee('employee', 'Funcionário'),
  intern('intern', 'Estagiário');

  const EmployeeRole(this.value, this.label);
  final String value;
  final String label;

  static EmployeeRole fromValue(String value) {
    return EmployeeRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => EmployeeRole.employee,
    );
  }
}

class Employee {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? document; // CPF
  final String department;
  final String position;
  final EmployeeRole role;
  final EmployeeStatus status;
  final double salary;
  final DateTime hireDate;
  final DateTime? terminationDate;
  final String? address;
  final String? avatar;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Employee({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.document,
    required this.department,
    required this.position,
    required this.role,
    this.status = EmployeeStatus.active,
    required this.salary,
    required this.hireDate,
    this.terminationDate,
    this.address,
    this.avatar,
    required this.createdAt,
    this.updatedAt,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      document: json['document'] as String?,
      department: json['department'] as String,
      position: json['position'] as String,
      role: EmployeeRole.fromValue(json['role'] as String),
      status: EmployeeStatus.fromValue(json['status'] as String),
      salary: (json['salary'] as num).toDouble(),
      hireDate: DateTime.parse(json['hireDate'] as String),
      terminationDate: json['terminationDate'] != null 
          ? DateTime.parse(json['terminationDate'] as String)
          : null,
      address: json['address'] as String?,
      avatar: json['avatar'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'document': document,
      'department': department,
      'position': position,
      'role': role.value,
      'status': status.value,
      'salary': salary,
      'hireDate': hireDate.toIso8601String(),
      'terminationDate': terminationDate?.toIso8601String(),
      'address': address,
      'avatar': avatar,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Employee copyWith({
    String? id,
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
    String? avatar,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      document: document ?? this.document,
      department: department ?? this.department,
      position: position ?? this.position,
      role: role ?? this.role,
      status: status ?? this.status,
      salary: salary ?? this.salary,
      hireDate: hireDate ?? this.hireDate,
      terminationDate: terminationDate ?? this.terminationDate,
      address: address ?? this.address,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Employee && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Employee(id: $id, name: $name, department: $department, role: ${role.label})';
  }
}

class Department {
  final String id;
  final String name;
  final String description;
  final String? managerId;
  final String? managerName;
  final int employeeCount;
  final DateTime createdAt;

  const Department({
    required this.id,
    required this.name,
    required this.description,
    this.managerId,
    this.managerName,
    this.employeeCount = 0,
    required this.createdAt,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      managerId: json['managerId'] as String?,
      managerName: json['managerName'] as String?,
      employeeCount: json['employeeCount'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'managerId': managerId,
      'managerName': managerName,
      'employeeCount': employeeCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

