# Guía de Contribución

## ¡Gracias por tu interés en contribuir a Surviving Chernarus!

Este documento proporciona directrices para contribuir al proyecto Surviving Chernarus. Seguir estas pautas ayuda a mantener la calidad del código y facilita la revisión e integración de tus contribuciones.

## Cómo Contribuir

### 1. Configuración del Entorno de Desarrollo

1. **Clonar el repositorio**

   ```bash
   git clone https://github.com/tuusuario/surviving-chernarus.git
   cd surviving-chernarus
   ```

2. **Configurar el entorno local**

   ```bash
   # Crear un archivo .env local para desarrollo
   cp .env.example .env
   # Editar el archivo .env con tus configuraciones locales
   nano .env
   ```

3. **Instalar dependencias**

   El proyecto utiliza principalmente Docker, así que asegúrate de tener instalado:
   - Docker
   - Docker Compose

### 2. Flujo de Trabajo de Desarrollo

1. **Crear una rama para tu contribución**

   ```bash
   git checkout -b feature/nombre-de-tu-caracteristica
   # o
   git checkout -b fix/nombre-de-tu-correccion
   ```

2. **Realizar cambios**

   Desarrolla tu característica o corrección siguiendo las convenciones de código del proyecto.

3. **Probar tus cambios**

   ```bash
   # Ejecutar el script de despliegue en modo de prueba
   ./deploy.sh --test
   ```

4. **Confirmar tus cambios**

   ```bash
   git add .
   git commit -m "Descripción clara de los cambios realizados"
   ```

5. **Enviar tus cambios**

   ```bash
   git push origin feature/nombre-de-tu-caracteristica
   ```

6. **Crear un Pull Request**

   Visita el repositorio en GitHub y crea un Pull Request desde tu rama a la rama principal.

### 3. Directrices de Código

#### Estilo de Código

- **Bash**: Sigue las [directrices de estilo de Google para Bash](https://google.github.io/styleguide/shellguide.html)
- **Docker**: Sigue las [mejores prácticas de Docker](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- **Markdown**: Utiliza [CommonMark](https://commonmark.org/) para la documentación

#### Convenciones de Nomenclatura

- **Variables**: Utiliza `MAYUSCULAS_CON_GUIONES_BAJOS` para variables de entorno y `minusculas_con_guiones_bajos` para variables locales
- **Funciones**: Utiliza `minusculas_con_guiones_bajos` para nombres de funciones
- **Archivos**: Utiliza `minusculas-con-guiones` para nombres de archivos

#### Documentación

- Documenta todas las funciones con comentarios que expliquen su propósito, parámetros y valores de retorno
- Mantén actualizada la documentación cuando realices cambios en el código
- Añade ejemplos de uso cuando sea apropiado

### 4. Informar Problemas

Si encuentras un error o tienes una sugerencia de mejora, por favor crea un issue en GitHub:

1. Utiliza un título claro y descriptivo
2. Describe detalladamente el problema o sugerencia
3. Incluye pasos para reproducir el problema si es aplicable
4. Añade capturas de pantalla si es posible
5. Menciona tu entorno (sistema operativo, versión de Docker, etc.)

### 5. Revisión de Código

Todos los Pull Requests serán revisados por los mantenedores del proyecto. Para facilitar la revisión:

- Mantén los cambios enfocados y específicos
- Explica claramente el propósito y la implementación de tus cambios
- Responde a los comentarios y preguntas de manera oportuna
- Realiza los cambios solicitados durante la revisión

### 6. Pruebas

- Añade pruebas para nuevas características cuando sea posible
- Asegúrate de que todas las pruebas existentes pasen antes de enviar tu Pull Request
- Considera casos extremos y escenarios de error

## Estructura del Proyecto

```
/
├── deploy.sh                # Script principal de despliegue
├── .env                     # Variables de entorno (no incluido en el repositorio)
├── .env.example             # Ejemplo de archivo de variables de entorno
├── docs/                    # Documentación
│   ├── index.md             # Página principal de la documentación
│   ├── installation.md      # Guía de instalación
│   ├── configuration.md     # Guía de configuración
│   ├── daily-usage.md       # Guía de uso diario
│   ├── maintenance.md       # Guía de mantenimiento
│   ├── troubleshooting.md   # Guía de solución de problemas
│   ├── advanced-usage.md    # Guía de uso avanzado
│   ├── reference.md         # Referencia técnica
│   └── contributing.md      # Guía de contribución
└── README.md                # Descripción general del proyecto
```

## Convenciones de Commit

Utilizamos [Conventional Commits](https://www.conventionalcommits.org/) para los mensajes de commit:

- `feat:` para nuevas características
- `fix:` para correcciones de errores
- `docs:` para cambios en la documentación
- `style:` para cambios que no afectan el significado del código
- `refactor:` para cambios de código que no corrigen errores ni añaden características
- `perf:` para cambios que mejoran el rendimiento
- `test:` para añadir o corregir pruebas
- `chore:` para cambios en el proceso de construcción o herramientas auxiliares

Ejemplos:

```
feat: añadir soporte para VPN
fix: corregir problema de conexión en Pi-hole
docs: actualizar guía de instalación
refactor: reorganizar funciones en deploy.sh
```

## Licencia

Al contribuir a este proyecto, aceptas que tus contribuciones estarán bajo la misma licencia que el proyecto (ver archivo LICENSE).

## Código de Conducta

### Nuestro Compromiso

Nos comprometemos a crear un entorno amigable, seguro y acogedor para todos, independientemente de su experiencia, identidad y expresión de género, orientación sexual, discapacidad, apariencia personal, tamaño corporal, raza, etnia, edad, religión, nacionalidad u otra característica similar.

### Nuestros Estándares

Comportamientos que contribuyen a crear un entorno positivo:

- Usar lenguaje acogedor e inclusivo
- Respetar diferentes puntos de vista y experiencias
- Aceptar con gracia las críticas constructivas
- Centrarse en lo que es mejor para la comunidad
- Mostrar empatía hacia otros miembros de la comunidad

Comportamientos inaceptables:

- Uso de lenguaje o imágenes sexualizadas
- Trolling, comentarios insultantes/despectivos, y ataques personales o políticos
- Acoso público o privado
- Publicar información privada de otros sin permiso explícito
- Otras conductas que razonablemente podrían considerarse inapropiadas en un entorno profesional

### Responsabilidades de los Mantenedores

Los mantenedores del proyecto son responsables de aclarar los estándares de comportamiento aceptable y se espera que tomen medidas correctivas apropiadas y justas en respuesta a cualquier comportamiento inaceptable.

### Alcance

Este Código de Conducta aplica tanto en espacios del proyecto como en espacios públicos cuando un individuo representa al proyecto o su comunidad.

### Aplicación

Los casos de comportamiento abusivo, acosador o inaceptable pueden ser reportados contactando al equipo del proyecto en [correo@ejemplo.com]. Todas las quejas serán revisadas e investigadas y resultarán en una respuesta que se considere necesaria y apropiada a las circunstancias.

## Contacto

Si tienes preguntas sobre cómo contribuir, no dudes en contactar a los mantenedores del proyecto:

- [Nombre del Mantenedor](mailto:correo@ejemplo.com)
- [Canal de Discord](https://discord.gg/tucanal)

¡Gracias por contribuir a Surviving Chernarus! Tu ayuda es fundamental para mejorar este proyecto y hacerlo más útil para todos.