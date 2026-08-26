# Sistema de Gestión de eCheqs - Frontend

Frontend desarrollado con Flutter para el Sistema de Gestión de eCheqs.

La aplicación consume una API REST desarrollada con Spring Boot y utiliza autenticación JWT.

## Tecnologías

- Flutter
- Dart
- HTTP
- SharedPreferences
- JWT
- Material Design

## Funcionalidades

- Login
- Registro de clientes
- Persistencia de sesión
- Control de expiración del JWT
- Navegación según rol
- Gestión de bancos
- Gestión de cuentas
- Gestión de Cuenta Banco
- Gestión de Cuentas Corrientes
- Solicitudes de eCheqs
- Aprobaciones y rechazos
- Notificaciones
- Auditoría
- Administración de usuarios y roles
- Visualización de errores y validaciones provenientes del backend

## Roles

### ADMIN
Acceso administrativo completo a los módulos del sistema.

### OPERADOR
Acceso operativo a clientes, cuentas, solicitudes, aprobaciones y rechazos.

### CLIENTE
Visualiza y administra únicamente sus propios datos y solicitudes.

### AUDITOR
Acceso global de solo lectura.


## Conexión con el backend

Por defecto, la aplicación consume la API REST en:
http://localhost:8080/api

El backend puede ejecutarse localmente o mediante Docker.

## Ejecución

Instalar dependencias:
flutter pub get

Ejecutar en Chrome:
flutter run -d chrome

Verificar el proyecto:
flutter analyze

## Sesión y seguridad

La aplicación almacena localmente la información de sesión mediante SharedPreferences.
Antes de realizar peticiones protegidas se verifica la vigencia del JWT.
Si el token expira, la sesión se elimina y el usuario es redirigido al login.
Un error HTTP 403 no cierra la sesión, ya que representa falta de permisos y no expiración del token.

## Manejo de errores

Los mensajes enviados por el backend se muestran al usuario.
Las validaciones de campos también muestran los mensajes específicos devueltos por la API.

## Flujo principal

1. El usuario inicia sesión.
2. El dashboard se adapta al rol autenticado.
3. El CLIENTE administra únicamente sus propios datos.
4. ADMIN y OPERADOR gestionan solicitudes y estados.
5. AUDITOR dispone de acceso global de solo lectura.
6. Las aprobaciones y rechazos generan auditoría y notificaciones.

## Estado del proyecto

Las funcionalidades principales fueron implementadas y validadas con los roles ADMIN, OPERADOR, CLIENTE y AUDITOR.

La integración Flutter + Spring Boot + MySQL también fue validada ejecutando el backend y la base de datos mediante Docker.
