# Snatch - Aplicación de Bandera para macOS

## 🎯 Descripción
Snatch es una aplicación de bandeja (shelf) para macOS que permite arrastrar y soltar archivos, carpetas, imágenes, enlaces y texto desde cualquier aplicación web o del sistema. Similar a Yoink, pero con funcionalidades adicionales y un diseño moderno.

## ✨ Características

### 🎯 Funcionalidades Principales
- **Arrastre múltiple**: Agrupa múltiples archivos en un solo elemento visual
- **Contenido web**: Convierte imágenes, enlaces y texto de páginas web en archivos locales
- **Búsqueda**: Filtra archivos en la bandeja
- **Auto-ocultación**: Se oculta automáticamente cuando no se usa
- **Indicador visual**: Muestra una pequeña pestaña cuando está oculto
- **Modo manual**: Permite mantener la bandeja visible indefinidamente
- **Atajo global**: `Cmd + Option + S` para mostrar/ocultar
- **Icono en barra de estado**: Acceso rápido desde el menú superior
- **Localización**: Se adapta al idioma del sistema (Español/Inglés)
- **Sin dock**: Solo aparece en la barra de estado

### 🎨 Interfaz
- **Tema Solarized**: Colores consistentes y elegantes
- **Iconos apilados**: Muestra hasta 3 tipos diferentes de archivos en grupos
- **Animaciones suaves**: Transiciones fluidas
- **Ventana flotante**: Siempre visible en todos los espacios de trabajo
- **Icono personalizado**: Diseño único para la aplicación

### 📁 Tipos de Contenido Soportados
- **Archivos locales**: Cualquier archivo del sistema
- **Carpetas**: Directorios completos
- **Imágenes web**: PNG, JPG, GIF, etc.
- **Enlaces**: URLs convertidas a archivos de texto
- **Texto**: Contenido de texto plano
- **HTML**: Páginas web completas

## 🚀 Instalación y Uso

### 📦 Compilar la Aplicación
```bash
# Clonar el repositorio
git clone <repository>
cd SnatchApp

# Compilar en modo release
swift build -c release

# La aplicación se encuentra en:
./SnatchApp.app
```

### 🎯 Ejecutar la Aplicación
```bash
# Ejecutar directamente
open SnatchApp.app

# O desde Finder
# Doble clic en SnatchApp.app
```

### 🛠️ Desarrollo
```bash
# Ejecutar en modo debug
swift run

# Compilar para release
swift build -c release
```

### 📋 Instrucciones de Uso

1. **Iniciar la aplicación**:
   - Doble clic en `SnatchApp.app`
   - La app aparecerá solo en la barra de estado (sin dock)

2. **Usar la bandeja**:
   - Arrastra archivos a la zona de drop
   - La bandeja se mostrará automáticamente
   - Los archivos se agruparán si son múltiples

3. **Atajos de teclado**:
   - `Cmd + Option + S`: Mostrar/ocultar bandeja
   - `Cmd + Q`: Salir de la aplicación

4. **Funciones avanzadas**:
   - **Búsqueda**: Usa el campo de búsqueda para filtrar
   - **Borrar todo**: Botón de papelera para limpiar la bandeja
   - **Modo manual**: Usa el atajo para mantener visible
   - **Arrastre hacia fuera**: Arrastra archivos desde la bandeja

### 🎛️ Controles
- **Barra de estado**: Icono en el menú superior
- **Ventana principal**: Bandera con zona de drop
- **Búsqueda**: Campo de texto para filtrar
- **Borrar**: Botón de papelera para limpiar todo

## 💻 Requisitos del Sistema
- **macOS**: 13.0 o superior
- **Arquitectura**: Apple Silicon (M1/M2) o Intel
- **Permisos**: Acceso a archivos y arrastre global
- **Espacio**: ~1MB para la aplicación

## 🔧 Características Técnicas

### 🛠️ Arquitectura
- **Lenguaje**: Swift 5.9+
- **Framework**: AppKit
- **Gestión de paquetes**: Swift Package Manager
- **Localización**: Soporte nativo para español e inglés
- **Iconos**: Formato .icns nativo de macOS

### 🎨 Temas y Estilos
- **Paleta Solarized**: Colores consistentes
- **Iconos del sistema**: Uso de iconos nativos de macOS
- **Animaciones**: Transiciones suaves con Core Animation
- **Icono personalizado**: Diseño único para la aplicación

### 📦 Estructura del Proyecto
```
SnatchApp/
├── Sources/SnatchApp/
│   ├── Controllers/
│   │   └── DragDetector.swift
│   ├── Models/
│   │   └── FileItem.swift
│   ├── Utils/
│   │   └── SolarizedTheme.swift
│   ├── Views/
│   │   ├── ShelfView.swift
│   │   └── ShelfWindow.swift
│   ├── Resources/
│   │   ├── en.lproj/
│   │   └── es.lproj/
│   └── main.swift
├── Package.swift
└── SnatchApp.app (aplicación final)
```

## 📋 Changelog

### v1.0 - Versión Actual
- ✅ **Agrupación de archivos**: Múltiples archivos = un elemento visual
- ✅ **Contenido web**: Imágenes, enlaces y texto desde páginas web
- ✅ **Búsqueda**: Filtra archivos en la bandeja
- ✅ **Auto-ocultación**: Se oculta automáticamente
- ✅ **Indicador visual**: Pequeña pestaña cuando está oculto
- ✅ **Modo manual**: Mantener visible con `Cmd + Option + S`
- ✅ **Atajo global**: `Cmd + Option + S` para mostrar/ocultar
- ✅ **Icono en barra de estado**: Menú con opciones
- ✅ **Localización**: Español/Inglés automático
- ✅ **Sin dock**: Solo aparece en la barra de estado
- ✅ **Icono personalizado**: Diseño único para la aplicación

## 📄 Licencia
Desarrollado como proyecto personal. Libre para uso y modificación.

---

**Snatch** - Tu bandeja inteligente para macOS 🚀

*Desarrollado con ❤️ en Swift para macOS* 