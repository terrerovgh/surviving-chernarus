# Wiki de Surviving Chernarus

Este directorio contiene la documentación completa del proyecto Surviving Chernarus, organizada como una wiki que se puede visualizar en GitHub Pages.

## Estructura de la Wiki

La wiki está organizada en varias secciones principales:

- **Inicio**: Introducción general al proyecto
- **Instalación**: Guía paso a paso para instalar el sistema
- **Configuración**: Detalles sobre cómo configurar los diferentes servicios
- **Uso Diario**: Instrucciones para el uso cotidiano del sistema
- **Mantenimiento**: Guía para mantener y actualizar el sistema
- **Solución de Problemas**: Ayuda para resolver problemas comunes
- **Uso Avanzado**: Funcionalidades y configuraciones avanzadas
- **Referencia**: Documentación técnica detallada
- **Contribuir**: Guía para contribuir al proyecto

## Visualización Local

Para visualizar la wiki localmente:

1. Asegúrate de tener Ruby y Bundler instalados
2. Ejecuta `bundle install` para instalar las dependencias
3. Ejecuta `bundle exec jekyll serve` para iniciar el servidor local
4. Abre `http://localhost:4000` en tu navegador

## Contribuir a la Documentación

Para contribuir a la documentación:

1. Crea una rama para tus cambios: `git checkout -b docs/tu-mejora`
2. Realiza tus cambios en los archivos Markdown correspondientes
3. Verifica tus cambios localmente usando Jekyll
4. Envía un Pull Request con tus cambios

## Convenciones de Formato

- Utiliza Markdown para todo el contenido
- Sigue las convenciones de CommonMark
- Usa encabezados jerárquicos (# para título principal, ## para secciones, etc.)
- Incluye ejemplos de código cuando sea relevante
- Mantén un tono claro y conciso

## Estructura de Archivos

```
/docs/
├── _config.yml           # Configuración de Jekyll
├── _layouts/             # Plantillas de diseño
├── _includes/            # Componentes reutilizables
├── assets/               # Recursos estáticos (CSS, JS, imágenes)
├── index.md              # Página principal
├── installation.md       # Guía de instalación
├── configuration.md      # Guía de configuración
├── daily-usage.md        # Guía de uso diario
├── maintenance.md        # Guía de mantenimiento
├── troubleshooting.md    # Guía de solución de problemas
├── advanced-usage.md     # Guía de uso avanzado
├── reference.md          # Referencia técnica
├── contributing.md       # Guía de contribución
├── search.md             # Página de búsqueda
└── CNAME                 # Configuración de dominio personalizado
```

## Dominio Personalizado

La wiki está configurada para usar el dominio personalizado `wiki.terrerov.com`. La configuración se encuentra en el archivo `CNAME`.

## Temas y Personalización

La wiki utiliza el tema Cayman de GitHub Pages con personalizaciones adicionales en los archivos CSS y las plantillas de diseño.