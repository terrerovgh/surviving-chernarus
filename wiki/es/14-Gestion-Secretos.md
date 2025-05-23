# Gestión de Secretos del Proyecto

La gestión segura de "secretos" es un aspecto crítico de cualquier sistema, incluyendo este proyecto de hotspot en la Raspberry Pi. Los secretos son credenciales sensibles como contraseñas, claves API y tokens de acceso. Un manejo inadecuado puede comprometer la seguridad y funcionalidad del sistema.

Este documento cubre dos categorías principales de secretos:
1.  **Secretos Operacionales del Hotspot:** Credenciales necesarias para el funcionamiento diario y la seguridad del hotspot.
2.  **Secretos para Desarrollo y CI/CD (GitHub PATs):** Tokens de acceso personal utilizados para la integración continua y el despliegue.

## Secretos Operacionales del Hotspot

Estos secretos son fundamentales para la seguridad y el correcto funcionamiento de los servicios del hotspot. Es crucial configurarlos correctamente y protegerlos.

### Contraseña del Wi-Fi (WPA Passphrase)

La contraseña de tu red Wi-Fi (`rpi`) es el primer nivel de defensa para el acceso a la red.

*   **Configuración:** Se define en el archivo `hotspot_config/hostapd.conf`.
*   **Valor Actual (Placeholder):** La configuración inicial proporcionada en el repositorio utiliza un placeholder:
    `wpa_passphrase=CHANGEME_SET_YOUR_WPA_PASSPHRASE`
*   **Acción Requerida:** **Debes cambiar este placeholder por una contraseña fuerte y única.**
    Busca la siguiente sección en `hotspot_config/hostapd.conf` y modifica la línea `wpa_passphrase`:
    ```
    # En hotspot_config/hostapd.conf:
    # ...
    # ======================================================================
    # IMPORTANT: YOU MUST CHANGE THIS PASSWORD TO A STRONG, UNIQUE VALUE!
    # THIS IS A PLACEHOLDER. YOU MUST CHANGE IT FOR SECURITY.
    # ======================================================================
    wpa_passphrase=CHANGEME_SET_YOUR_WPA_PASSPHRASE 
    # Cambiar por algo como: wpa_passphrase=MiClaveWiFiSuperSegura123!
    ```
*   **Recomendaciones:**
    *   Utiliza una contraseña larga (mínimo 12-16 caracteres).
    *   Combina letras mayúsculas, minúsculas, números y símbolos.
    *   Evita palabras comunes o información personal fácil de adivinar.
    *   Consulta la sección "Important: Initial Security Setup" en el `README.md` principal o el archivo `SECURITY.md` para más consejos sobre la creación de contraseñas seguras.

### Contraseña de Administrador de Pi-hole

La interfaz de administración web de Pi-hole permite controlar el bloqueo de DNS y ver estadísticas. Protegerla con una contraseña robusta es esencial.

*   **Configuración:** La contraseña del administrador de Pi-hole se establece mediante la variable de entorno `PIHOLE_WEBPASSWORD`.
*   **Método:** Esta variable se gestiona a través de un archivo `.env` ubicado en el directorio raíz del proyecto (el mismo directorio que contiene `docker-compose.yml`).
*   **Instrucciones:**
    Crear o editar un archivo llamado `.env` en el directorio raíz del proyecto y añadir la siguiente línea, reemplazando el valor de ejemplo con una contraseña fuerte:
    ```env
    PIHOLE_WEBPASSWORD=tu_contraseña_muy_segura_aqui
    ```
*   **Funcionamiento:** `docker-compose` carga automáticamente este archivo `.env` al iniciar los servicios (ejecutando `docker-compose up`), configurando así la contraseña para el contenedor de Pi-hole.
*   **Importancia:** Sin una contraseña fuerte, cualquier usuario en la red podría acceder a la configuración de Pi-hole y potencialmente deshabilitar el filtrado de DNS o redirigir el tráfico.
*   **Recomendaciones:**
    *   Utiliza una contraseña diferente a la del Wi-Fi.
    *   Sigue las pautas generales para contraseñas seguras (longitud, complejidad).
    *   Consulta el archivo `SECURITY.md` para obtener consejos generales sobre la fortaleza de las contraseñas.

## Secretos para Desarrollo y CI/CD (GitHub PATs)

### Introducción a PATs
En este proyecto, los Personal Access Tokens (PATs) de GitHub son el principal tipo de secreto que manejamos para el desarrollo y la integración continua. Consideraremos dos contextos principales donde estos secretos se utilizan y configuran:

1.  **Secretos en GitHub Actions (Nivel de Repositorio):** Para información sensible que los flujos de trabajo (workflows) podrían necesitar si interactúan con servicios externos o la API de GitHub desde los runners alojados por GitHub.
2.  **Secretos en la Raspberry Pi (Nivel de Runner Auto-Alojado):** Específicamente, el PAT utilizado para autenticar la herramienta `gh` (GitHub CLI) con el usuario `github-runner`.

### Secretos en GitHub Actions

#### ¿Cuándo se usan?
Los secretos de GitHub Actions se utilizan para almacenar información sensible que tu flujo de trabajo (definido en el archivo `.github/workflows/main.yml`) necesita para ejecutarse. Algunos ejemplos comunes incluyen:

*   Claves API para servicios de terceros (e.g., servicios de notificación, plataformas en la nube).
*   Tokens de acceso para registros de Docker.
*   **Personal Access Tokens (PATs) de GitHub:** Si un paso de tu workflow que se ejecuta en un runner alojado por GitHub (no en tu Raspberry Pi) necesitara realizar llamadas a la API de GitHub con privilegios específicos (por ejemplo, para crear un issue, modificar un release, etc.).

El `GITHUB_TOKEN` que GitHub proporciona automáticamente a cada workflow tiene permisos limitados al repositorio donde se ejecuta. Si necesitas más permisos o interactuar con otros repositorios, un PAT configurado como secreto sería necesario.

#### Cómo configurarlos:
Para configurar un secreto a nivel de repositorio:

1.  Navega a tu repositorio en GitHub: `https://github.com/terrerovgh/surviving-chernarus`
2.  Haz clic en la pestaña **Settings** (Configuración).
3.  En el menú de la izquierda, bajo la sección "Security", haz clic en **Secrets and variables**, y luego en **Actions**.
4.  En la pestaña "Secrets", haz clic en el botón **New repository secret**.
5.  **Name (Nombre del secreto):**
    *   Elige un nombre descriptivo para tu secreto, por ejemplo, `GH_PAT_FOR_WORKFLOW`.
    *   Los nombres de los secretos son sensibles a mayúsculas y minúsculas y solo pueden contener caracteres alfanuméricos y guiones bajos.
6.  **Value (Valor):**
    *   Pega el valor del secreto (e.g., el Personal Access Token `ghp_...`).
    *   **Importante:** Una vez guardado, no podrás volver a ver el valor del secreto desde la interfaz de GitHub, solo podrás actualizarlo o eliminarlo.
7.  Haz clic en **Add secret**.

Una vez guardado, el secreto está disponible para ser utilizado en tus workflows. Se accede a él usando la sintaxis `${{ secrets.NOMBRE_DEL_SECRETO }}`.

**Ejemplo de uso en un workflow (hipotético):**
```yaml
name: Ejemplo Workflow con Secreto
on: [push]
jobs:
  usar_secreto:
    runs-on: ubuntu-latest
    steps:
      - name: Realizar accion con PAT
        run: |
          echo "Llamando a una API con el PAT..."
          curl -H "Authorization: token ${{ secrets.GH_PAT_FOR_WORKFLOW }}" https://api.github.com/user
```

#### Nota sobre el workflow actual:
En nuestro flujo de trabajo actual (`.github/workflows/main.yml`), el PAT que se utiliza para la autenticación de `gh` en la Raspberry Pi **no se gestiona como un secreto de GitHub Actions**. En su lugar, se configura directamente en la Raspberry Pi usando `gh auth login` para el usuario `github-runner`. Esto se debe a que la autenticación es persistente en la Pi para ese usuario específico.

Si el workflow en sí (la parte que se ejecuta en `ubuntu-latest` antes del despliegue) necesitara interactuar con la API de GitHub por alguna razón, entonces sí usaríamos un secreto de GitHub Actions como se describió arriba.

### Secretos en la Raspberry Pi (Autenticación de `gh`)

El principal secreto que manejamos en la Raspberry Pi es el Personal Access Token utilizado para autenticar la herramienta `gh` (GitHub CLI). Esta autenticación permite al usuario `github-runner` interactuar con GitHub para tareas como clonar el repositorio, verificar el estado, etc. (aunque nuestro `deploy.sh` actual no usa `gh`).

#### Método Principal (`gh auth login`):
Como se detalla en la guía `13-GitHub-CLI-Autenticacion.md`:

1.  **Proceso:** El método preferido es iniciar sesión como el usuario `github-runner` (`sudo -iu github-runner`) y luego ejecutar `gh auth login`.
2.  **Almacenamiento Seguro:** `gh` almacena el token de forma segura en un archivo de configuración dentro del directorio home del usuario: `/home/github-runner/.config/gh/hosts.yml`. Este archivo tiene permisos restrictivos (normalmente `600`), lo que significa que solo el usuario `github-runner` puede leerlo o escribirlo.
3.  **Ventajas:**
    *   El token no se expone directamente en scripts.
    *   No se guarda en el historial de comandos de bash de forma persistente (solo durante el momento de pegarlo).
    *   `gh` maneja el uso del token de forma transparente.

#### Alternativas (Menos recomendadas para `gh`, pero informativas):
Aunque `gh auth login` es el método ideal para autenticar `gh`, es útil conocer otras formas en que los secretos (como los PATs) podrían manejarse si fueran necesarios para otros scripts o herramientas que no tienen un mecanismo de autenticación tan robusto.

*   **Variables de Entorno:**
    Si un script diferente a `gh` (por ejemplo, un script que usa `curl` para interactuar directamente con la API de GitHub, o `git clone` con HTTPS sin la ayuda de `gh`) necesitara un PAT, se podría configurar como una variable de entorno para el usuario `github-runner`.
    *   **Ejemplo:**
        Se podría añadir la siguiente línea al archivo `~/.bashrc` (o `~/.profile`) del usuario `github-runner`:
        ```bash
        export GITHUB_TOKEN="ghp_tuPATaqui12345"
        ```
        Luego, el script podría acceder a esta variable (`echo $GITHUB_TOKEN`).
    *   **Precauciones:**
        *   **Seguridad:** Este método es menos seguro. Si otros usuarios pueden leer el archivo `.bashrc` del usuario `github-runner`, o si las variables de entorno se registran en logs, el token podría quedar expuesto.
        *   **Permisos:** El archivo `~/.bashrc` debería tener permisos restrictivos (e.g., `chmod 600 /home/github-runner/.bashrc`).
        *   **Activación:** Las variables en `.bashrc` se cargan al iniciar una sesión de shell interactiva. Para servicios o scripts no interactivos, `.profile` o configuraciones específicas del servicio podrían ser más apropiadas.

*   **Archivos de Configuración Protegidos:**
    Un PAT podría guardarse en un archivo dedicado, y los scripts podrían leerlo desde allí.
    *   **Ejemplo:**
        Guardar el token en `/home/github-runner/.mi_pat_secreto`.
        ```bash
        echo "ghp_tuPATaqui12345" > /home/github-runner/.mi_pat_secreto
        sudo chown github-runner:github-runner /home/github-runner/.mi_pat_secreto
        sudo chmod 600 /home/github-runner/.mi_pat_secreto
        ```
        Un script luego leería este archivo: `TOKEN=$(cat /home/github-runner/.mi_pat_secreto)`.
    *   **Precauciones:** Similar a las variables de entorno, la seguridad depende de los permisos del archivo y de cómo se accede a él.

**Conclusión para este proyecto:**
Para la autenticación de `gh` en la Raspberry Pi con el usuario `github-runner`, el método `gh auth login` es el más seguro y recomendado, y hace innecesarias estas alternativas para ese propósito específico.

### Buenas Prácticas para Personal Access Tokens (PATs)

Independientemente de dónde o cómo uses los PATs, seguir estas buenas prácticas es crucial para la seguridad:

1.  **Principio de Menor Privilegio:**
    *   Crea PATs solo con los **scopes (permisos) estrictamente necesarios** para la tarea que realizarán. No otorgues permisos de `admin:org` si solo necesitas leer repositorios.
    *   Para el runner de GitHub Actions en la Raspberry Pi y el uso de `gh`, el scope `repo` (control total de repositorios privados) suele ser el más común. Si solo necesitas acceder a repositorios públicos, el scope `public_repo` podría ser suficiente. Si necesitas gestionar workflows vía API, añade el scope `workflow`.

2.  **Expiración:**
    *   **Establece siempre una fecha de expiración** para tus PATs. GitHub permite tokens que no expiran, pero esta es una práctica menos segura.
    *   Cuanto más corta sea la vida útil de un token, menor será la ventana de oportunidad si se compromete.
    *   Recuerda renovar los tokens antes de que expiren para evitar interrupciones del servicio.

3.  **No Incrustar Tokens en el Código:**
    *   **Nunca guardes PATs directamente en tu código fuente**, scripts, archivos de configuración no protegidos, o cualquier archivo que se suba a un repositorio Git (incluso si el repositorio es privado).

4.  **Revocación Inmediata:**
    *   Si sospechas que un PAT ha sido comprometido o expuesto, **revócalo inmediatamente**.
    *   Puedes hacerlo desde la página de configuración de "Personal access tokens" en "Developer settings" en GitHub.

5.  **Nombres Descriptivos:**
    *   Cuando generes un PAT, asígnale un **nombre descriptivo** que te ayude a recordar dónde se utiliza y para qué propósito. Esto facilita la auditoría y la gestión de tus tokens. (e.g., "rpi-surviving-chernarus-runner-gh-auth").

6.  **Auditoría Regular:**
    *   Revisa periódicamente los PATs que has creado. Elimina aquellos que ya no sean necesarios.

Siguiendo estas pautas, puedes reducir significativamente el riesgo asociado con el uso de Personal Access Tokens y mantener un entorno de CI/CD más seguro.
