# InnoGarage Mobile — Arquitectura

## 1. ¿Qué es InnoGarage Mobile?

Es una app Flutter para clientes del taller mecánico InnoGarage. Permite:
- Registrarse como cliente
- Iniciar sesión
- Consultar el estado de sus órdenes y cotizaciones

Consume la API REST del backend Spring Boot (`Back-end-inno/SENA-INNO_GARAGE-BACK`).

---

## 2. Stack tecnológico

| Capa          | Tecnología                              |
| ------------- | --------------------------------------- |
| Lenguaje      | Dart 3.x                                |
| Framework     | Flutter                                 |
| Estado        | Riverpod (v2.6)                         |
| HTTP          | Dio (v5.7)                              |
| Navegación    | GoRouter (v14.8)                        |
| Token seguro  | flutter_secure_storage (v9.2)           |
| Build runner  | build_runner + riverpod_generator       |

---

## 3. Estructura de carpetas

```
flutter-inno/
├── pubspec.yaml                     # Dependencias del proyecto
├── spec-architecture.md             # Este documento
├── lib/
│   ├── main.dart                    # Punto de entrada: ProviderScope + MaterialApp.router
│   ├── app/
│   │   └── router.dart              # Configuración de GoRouter con las rutas
│   ├── core/                        # Capa compartida (no depende de features)
│   │   ├── config/
│   │   │   └── app_config.dart      # Constantes: baseUrl, timeouts
│   │   ├── network/
│   │   │   ├── api_client.dart      # Cliente Dio con interceptors
│   │   │   └── providers.dart       # Providers globales: secureStorage, apiClient
│   │   └── storage/
│   │       └── secure_storage_service.dart  # Guarda/lee/elimina tokens JWT
│   └── features/                    # Feature-first: cada feature es autocontenida
│       ├── auth/                    # Autenticación (login + registro)
│       │   ├── auth.dart            # Barrel export (exporta todo lo público)
│       │   ├── data/
│       │   │   └── auth_repository.dart    # Llamadas HTTP: /auth/login, /auth/registro
│       │   └── presentation/
│       │       ├── providers/
│       │       │   └── auth_provider.dart  # Provider de authRepository
│       │       └── pages/
│       │           ├── login_page.dart     # Pantalla de inicio de sesión
│       │           └── register_page.dart  # Pantalla de registro
│       └── dashboard/               # Panel principal del cliente
│           ├── dashboard.dart       # Barrel export
│           ├── data/
│           │   └── dashboard_repository.dart  # Llamada HTTP: /dashboard/cliente/{doc}
│           └── presentation/
│               ├── providers/
│               │   └── dashboard_provider.dart  # Provider del dashboard
│               └── pages/
│                   └── dashboard_page.dart     # Pantalla principal post-login
├── android/     # Generado por flutter create
├── ios/         # Generado por flutter create
├── web/         # Generado por flutter create
├── test/
│   └── widget_test.dart
└── ...
```

### Principio: Feature-first

Cada feature (`auth/`, `dashboard/`) contiene todo lo que necesita:
- `data/` → repositorios (llamadas HTTP)
- `presentation/providers/` → providers Riverpod
- `presentation/pages/` → pantallas (Widgets)
- `feature.dart` → barrel que exporta todo para que otras features puedan importarlo limpio

La capa `core/` tiene lo compartido (config, red, storage) y **no depende de ninguna feature**.

---

## 4. Flujo de datos

```
[UI] ←→ [Provider (Riverpod)] ←→ [Repository] ←→ [ApiClient (Dio)] ←→ [Backend Spring Boot]
                                    ↑
                              [SecureStorage]
                            (guarda tokens JWT)
```

1. El usuario interactúa con la UI (ej: login)
2. El Provider llama al Repository
3. El Repository usa ApiClient para hacer la petición HTTP
4. ApiClient agrega automáticamente el header `Authorization: Bearer <token>` (si existe)
5. El backend responde y el Provider actualiza el estado
6. La UI se reconstruye automáticamente

---

## 5. Conexión con el backend

### URL base

`http://localhost:8080/api` (definida en `lib/core/config/app_config.dart`)

### Endpoints que consumirá la app

| Método | Endpoint                      | Uso                        |
| ------ | ----------------------------- | -------------------------- |
| POST   | `/api/auth/login`             | Iniciar sesión             |
| POST   | `/api/auth/registro`          | Registrar cliente          |
| POST   | `/api/auth/refresh`           | Renovar access token       |
| GET    | `/api/dashboard/cliente/{id}` | Datos del dashboard        |
| GET    | `/api/ordenes`                | Listar órdenes del cliente |

### Autenticación

1. Login → backend devuelve `{ accessToken, refreshToken, tipo: "Bearer" }`
2. accessToken se guarda en flutter_secure_storage
3. Cada petición lleva `Authorization: Bearer <accessToken>` (el interceptor de Dio lo agrega automáticamente)
4. Si el backend responde 401 → se limpian los tokens y se redirige al login

---

## 6. Dependencias (pubspec.yaml)

| Paquete                   | Versión | Propósito                           |
| ------------------------- | ------- | ----------------------------------- |
| flutter_riverpod          | ^2.6.1  | Proveedor de estado                 |
| riverpod_annotation       | ^2.6.1  | Anotaciones para riverpod_generator |
| go_router                 | ^14.6.2 | Navegación declarativa              |
| dio                       | ^5.7.0  | Cliente HTTP con interceptors       |
| flutter_secure_storage    | ^9.2.4  | Almacenamiento seguro de tokens     |
| equatable                 | ^2.0.7  | Comparación de objetos              |

---

## 7. Cambios realizados hasta ahora

### Creación del proyecto
- `flutter create --project-name flutter_inno .` → generó android/, ios/, web/, etc.
- `flutter pub get` → descargó todas las dependencias

### Archivos creados manualmente

| Archivo                                    | Propósito                                                        |
| ------------------------------------------ | ---------------------------------------------------------------- |
| `lib/main.dart`                            | ProviderScope + InnoGarageApp con GoRouter                       |
| `lib/app/router.dart`                      | Rutas /login, /register, /dashboard                              |
| `lib/core/config/app_config.dart`          | Base URL y timeouts                                              |
| `lib/core/network/api_client.dart`         | Cliente Dio con interceptores (Auth + Error)                     |
| `lib/core/network/providers.dart`          | Providers de SecureStorageService y ApiClient                    |
| `lib/core/storage/secure_storage_service.dart` | CRUD de tokens JWT                                           |
| `lib/features/auth/auth.dart`              | Barrel export                                                    |
| `lib/features/auth/data/auth_repository.dart`   | login() y register()                                        |
| `lib/features/auth/presentation/providers/auth_provider.dart` | Provider del repositorio auth |
| `lib/features/auth/presentation/pages/login_page.dart`    | Placeholder login                                     |
| `lib/features/auth/presentation/pages/register_page.dart` | Placeholder register                                  |
| `lib/features/dashboard/dashboard.dart`    | Barrel export                                                    |
| `lib/features/dashboard/data/dashboard_repository.dart` | getClienteDashboard()                               |
| `lib/features/dashboard/presentation/providers/dashboard_provider.dart` | Provider del dashboard     |
| `lib/features/dashboard/presentation/pages/dashboard_page.dart` | Placeholder dashboard                              |

### Correcciones posteriores
- Se movió `apiClientProvider` de `auth_provider.dart` a `core/network/providers.dart` para que cualquier feature pueda usarlo
- Se actualizó `widget_test.dart` para que use `InnoGarageApp` en vez de `MyApp`

---

## 8. Pendientes / Próximos pasos

- [ ] Implementar UI real de LoginPage con formularios y validación
- [ ] Implementar UI real de RegisterPage con formularios y validación
- [ ] Implementar UI real de DashboardPage mostrando órdenes del cliente
- [ ] Manejar refresh token automático en ApiClient (cuando el access token expire)
- [ ] Manejo de sesión: redirigir a login si no hay token, a dashboard si sí hay
- [ ] Conectar con el backend real (ajustar base URL en producción)
