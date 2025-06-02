# Orders App - Flutter

Uma aplicação Flutter moderna para gerenciamento de pedidos e funcionários, desenvolvida com foco em dispositivos móveis.

## 📱 Funcionalidades

### 🔐 Autenticação
- Login seguro com email e senha
- Validação de credenciais
- Persistência de sessão
- Logout automático

### 📦 Gestão de Pedidos
- **Listagem de Pedidos**: Visualize todos os pedidos com filtros por status
- **Criação de Pedidos**: Interface intuitiva para criar novos pedidos
- **Gestão de Status**: Atualize o status dos pedidos (Pendente, Confirmado, Preparando, Pronto, Entregue, Cancelado)
- **Detalhes Completos**: Visualize informações detalhadas de cada pedido
- **Busca Avançada**: Encontre pedidos por nome do cliente, ID ou telefone

### 👥 Gestão de Funcionários
- **Cadastro de Funcionários**: Formulário completo com validações
- **Listagem com Filtros**: Filtre por departamento, status e busca textual
- **Edição de Dados**: Atualize informações dos funcionários
- **Controle de Status**: Gerencie funcionários ativos, inativos e suspensos
- **Departamentos**: Organize funcionários por departamentos
- **Hierarquia de Funções**: Diferentes níveis de acesso (Admin, Gerente, Supervisor, Funcionário, Estagiário)

### 📊 Dashboard
- **Estatísticas em Tempo Real**: Visualize métricas importantes
- **Ações Rápidas**: Acesso direto às funcionalidades principais
- **Pedidos Recentes**: Acompanhe os últimos pedidos
- **Resumo Geral**: Visão consolidada do negócio

## 🛠️ Tecnologias Utilizadas

### Framework e Linguagem
- **Flutter 3.24.5**: Framework multiplataforma
- **Dart**: Linguagem de programação

### Gerenciamento de Estado
- **Provider**: Gerenciamento de estado reativo
- **ChangeNotifier**: Padrão Observer para atualizações de UI

### Navegação
- **GoRouter**: Navegação declarativa e type-safe
- **Rotas Nomeadas**: Organização clara da navegação

### Armazenamento Local
- **SharedPreferences**: Persistência de dados simples
- **Hive**: Banco de dados local NoSQL (preparado para uso)

### UI/UX
- **Material Design 3**: Design system moderno
- **Tema Customizado**: Cores e estilos consistentes
- **Responsividade**: Adaptação para diferentes tamanhos de tela
- **Animações**: Transições suaves e feedback visual

### Validação e Formulários
- **Form Validation**: Validação robusta de formulários
- **Input Formatters**: Formatação automática de campos
- **Custom Widgets**: Componentes reutilizáveis

### Utilitários
- **Intl**: Formatação de datas e moedas
- **UUID**: Geração de identificadores únicos
- **Crypto**: Criptografia para senhas

## 🏗️ Arquitetura

O projeto segue uma arquitetura limpa e organizada:

```
lib/
├── core/                    # Configurações e utilitários centrais
│   ├── config/             # Configurações de rotas
│   ├── constants/          # Constantes da aplicação
│   ├── services/           # Serviços de negócio
│   ├── theme/              # Tema e estilos
│   └── utils/              # Utilitários gerais
├── data/                   # Camada de dados
│   ├── models/             # Modelos de dados
│   ├── repositories/       # Repositórios
│   └── datasources/        # Fontes de dados
├── presentation/           # Camada de apresentação
│   ├── pages/              # Telas da aplicação
│   ├── widgets/            # Widgets reutilizáveis
│   └── providers/          # Gerenciadores de estado
└── main.dart              # Ponto de entrada da aplicação
```

## 🚀 Como Executar

### Pré-requisitos
- Flutter SDK 3.24.5 ou superior
- Dart SDK
- Android Studio / VS Code
- Emulador Android ou dispositivo físico

### Instalação

1. **Clone o repositório**
```bash
git clone https://github.com/rafaesapata/orders-app-flutter.git
cd orders-app-flutter
```

2. **Instale as dependências**
```bash
flutter pub get
```

3. **Execute a aplicação**
```bash
flutter run
```

### Contas de Teste

Para testar a aplicação, use uma das seguintes contas:

**Administrador:**
- Email: `admin@example.com`
- Senha: `admin123`

**Usuário:**
- Email: `user@example.com`
- Senha: `user123`

## 📱 Capturas de Tela

### Tela de Login
- Interface limpa e intuitiva
- Validação em tempo real
- Informações de contas de teste

### Dashboard
- Estatísticas em tempo real
- Ações rápidas
- Pedidos recentes
- Navegação por abas

### Gestão de Pedidos
- Lista com filtros avançados
- Criação de pedidos intuitiva
- Seleção de produtos
- Cálculo automático de totais

### Gestão de Funcionários
- Cadastro completo
- Filtros por departamento e status
- Edição de informações
- Controle de hierarquia

## 🔧 Configuração de Desenvolvimento

### Estrutura de Dados

A aplicação utiliza dados locais para demonstração, incluindo:
- **Produtos**: Catálogo com preços e categorias
- **Departamentos**: Estrutura organizacional
- **Funcionários**: Dados completos com hierarquia
- **Pedidos**: Histórico de transações

### Personalização

Para personalizar a aplicação:

1. **Cores e Tema**: Edite `lib/core/theme/app_theme.dart`
2. **Rotas**: Configure em `lib/core/config/app_router.dart`
3. **Modelos**: Adicione novos modelos em `lib/data/models/`
4. **Serviços**: Implemente novos serviços em `lib/core/services/`

## 🤝 Contribuição

1. Faça um fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

## 📞 Contato

Para dúvidas ou sugestões, entre em contato através do GitHub.

---

**Desenvolvido com ❤️ usando Flutter**

