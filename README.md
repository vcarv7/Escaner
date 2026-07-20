# Escáner de Solapines

Aplicación móvil Flutter para el escaneo de Solapines (códigos de barras y QR), diseñada específicamente para la gestión de identificadores de solapines.

## Características

- Escaneo de Solapines en tiempo real
- Gestión de datos mediante archivos CSV
- Almacenamiento seguro de información
- Exportación y compartición de resultados
- Feedback visual y sonoro al escanear

## Stack Tecnológico

| Tecnología | Propósito |
|------------|-----------|
| Flutter 3.x | Framework UI multiplataforma |
| Provider | Gestión de estado |
| mobile_scanner | Escaneo de Solapines |
| excel_community | Manipulación de archivos Excel/CSV |
| flutter_secure_storage | Almacenamiento cifrado |
| audioplayers | Reproducción de sonidos |
| vibration | Feedback háptico |

## Estructura del Proyecto

```
lib/
├── main.dart                 # Punto de entrada
├── app.dart                  # Configuración global
├── core/                     # Configuración compartida
│   ├── constants/            # Constantes de la aplicación
│   ├── theme/               # Tema y estilos
│   └── utils/               # Utilidades generales
├── data/                     # Capa de datos
│   ├── datasources/         # Fuentes de datos (Local + CSV)
│   ├── models/              # Modelos de datos
│   └── repositories/        # Implementación de repositorios
├── domain/                   # Capa de dominio
│   ├── entities/           # Entidades del negocio
│   └── repositories/        # Interfaces de repositorios
├── presentation/            # Capa de presentación
│   ├── pages/              # Pantallas
│   ├── widgets/            # Widgets reutilizables
│   └── providers/          # Providers de estado
```

## Requisitos Previos

- Flutter SDK 3.x o superior
- Dart 3.x o superior
- Android SDK (para Android)
- Xcode (para iOS)

## Instalación

1. Clonar el repositorio:
   ```bash
   git clone <url-repositorio>
   cd escaner_1
   ```

2. Instalar dependencias:
   ```bash
   flutter pub get
   ```

3. Ejecutar la aplicación:
   ```bash
   flutter run
   ```

## Comandos de Desarrollo

```bash
# Ejecutar app en modo desarrollo
flutter run

# Analizar código (lint)
flutter analyze

# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release

# Actualizar dependencias
flutter pub get

# Generar icons de app
flutter pub run flutter_launcher_icons
```

## Versionado

El número de versión se define en `pubspec.yaml` con el formato `x.y.z+build`
(por ejemplo `version: 0.8.5+1`). El sufijo `+N` es el `versionCode` que exige
Play Store: debe incrementarse en cada release, si no el upload es rechazado.

## Release (firma de producción)

La app se firma con un keystore propio (no el de debug). Los secretos nunca
se suben al repositorio: `android/key.properties` y `android/keystore/` están
en `.gitignore`.

1. Generar el keystore (requiere el JDK en el PATH):
   ```bash
   keytool -genkey -v -keystore android/keystore/siga-escaner-release.keystore \
     -alias siga-escaner -keyalg RSA -keysize 2048 -validity 10000
   ```
2. Crear `android/key.properties` con:
   ```properties
   storeFile=../keystore/siga-escaner-release.keystore
   storePassword=TU_PASSWORD
   keyAlias=siga-escaner
   keyPassword=TU_PASSWORD
   ```
3. Build de release:
   ```bash
   flutter build apk --release          # APK: SIGA-Escaner-release.apk
   flutter build appbundle --release    # AAB para Google Play Store
   ```
   La configuración de firma (`signingConfigs.release`) ya está en
   `android/app/build.gradle.kts` y lee `android/key.properties`.

> Guarda el keystore en un lugar seguro. Si se pierde, no podrás actualizar la
> app en Play Store con la misma firma.

## Configuración

### Permisos requeridos (Android)

Agregar en `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.INTERNET" />
```

### Permisos requeridos (iOS)

Agregar en `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>Se requiere acceso a la cámara para escanear Solapines</string>
```

## Contribución

1. Crear una rama feature: `feature/nombre-feature`
2. Realizar los cambios y commits necesarios
3. Crear un Pull Request hacia la rama `main`
4. Ejecutar `flutter analyze` antes de commit
5. Mantener la separación de capas (UI/Datos/Dominio)

## Convenciones de Código

- **Archivos**: Kebab-case (`login_page.dart`)
- **Clases**: PascalCase (`class LoginPage`)
- **Variables/Funciones**: snake_case
- Máximo 80-100 líneas por función
- Usar `const` siempre que sea posible

## Seguridad

- No hardcodear credenciales o URLs en código
- Usar variables de entorno para secrets
- Validar datos del servidor antes de usarlos
- Usar almacenamiento cifrado para datos sensibles

## Licencia

MIT License