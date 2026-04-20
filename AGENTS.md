# Escáner App

Aplicación móvil Flutter para escaneo de códigos de barras y QR.

## Stack Tecnológico

| Tecnología | Propósito |
|------------|-----------|
| Flutter 3.x | Framework UI |
| Provider | Gestión de estado |
| go_router | Navegación |
| Supabase | Backend (Auth + DB) |
| mobile_scanner | Escaneo de códigos |

## Estructura del Proyecto

```
lib/
├── main.dart              # Punto de entrada
├── app.dart               # Configuración global
├── core/                  # Configuración compartida
│   ├── constants/         # Constantes de la app
│   ├── theme/             # Tema y estilos
│   └── utils/             # Utilidades generales
├── data/                  # Capa de datos
│   ├── datasources/       # Fuentes de datos (Supabase)
│   ├── models/            # Modelos de datos
│   └── repositories/      # Implementación de repositorios
├── domain/                # Capa de dominio
│   ├── entities/          # Entidades del negocio
│   └── repositories/      # Interfaces de repositorios
├── presentation/          # Capa de presentación
│   ├── pages/             # Pantallas
│   ├── widgets/           # Widgets reutilizables
│   └── providers/          # Providers de estado
└── injection.dart         # Inyección de dependencias
```

## Convenciones de Código

### Nombrado de Archivos

- **Kebab-case**: `login_page.dart`, `scan_button.dart`
- **Snake_case**: Variables, funciones

### Nombrado de Clases

- **PascalCase**: `class LoginPage extends StatelessWidget`
- **CamelCase**: `class ScanResult`

### Reglas Generales

- Máximo 80-100 líneas por función
- Preferir funciones puras
- Inmutabilidad donde sea posible
- Usar `const` siempre que sea posible

## Reglas de Contribución

1. Crear feature branch: `feature/nombre-feature`
2. Crear PR para merges a `main`
3. Ejecutar `flutter analyze` antes de commit
4. Mantener separaciones de capas (UI/Datos/Dominio)
5. No hardcodear credenciales

## Comandos de Desarrollo

```bash
# Ejecutar app
flutter run

# Analizar código
flutter analyze

# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release

# Actualizar dependencias
flutter pub get
```

## Seguridad

- No exponer credenciales de Supabase en código
- Usar variables de entorno para secrets
- Validar datos del servidor
- Implementar autenticación con Supabase Auth

## Recursos

- [Documentación Flutter](https://docs.flutter.dev)
- [Provider Flutter](https://pub.dev/packages/provider)
- [Supabase Flutter](https://supabase.com/docs/guides/flutter)
