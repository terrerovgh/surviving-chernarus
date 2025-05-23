# Uso y Autenticación de GitHub CLI (`gh`) en la Raspberry Pi

## Introducción
GitHub CLI (`gh`) es la herramienta oficial de línea de comandos para interactuar con tu cuenta de GitHub directamente desde la terminal. En el contexto de nuestra Raspberry Pi configurada como un runner auto-alojado, `gh` se convierte en una utilidad muy poderosa.

Aunque nuestro script de despliegue (`deploy.sh`) actual no utiliza `gh` directamente para copiar los archivos del sitio, `gh` es fundamental para:
*   **Autenticar el runner con GitHub:** Facilita la configuración inicial y la interacción con la API de GitHub.
*   **Administración del Repositorio:** Permite realizar tareas como clonar repositorios, gestionar Pull Requests, issues, releases, y más, directamente desde la Raspberry Pi.
*   **Gestión de Workflows:** Se puede usar para ver el estado de los workflows, descargar artefactos manualmente si es necesario, o incluso disparar workflows.
*   **Diagnóstico y Mantenimiento:** Útil para verificar el estado de la conexión con GitHub o para realizar tareas de mantenimiento relacionadas con el repositorio o las acciones.

Esta guía te mostrará cómo instalar y autenticar `gh` para el usuario `github-runner` en tu Raspberry Pi con Arch Linux.

## Instalación de GitHub CLI (Arch Linux)
Si seguiste la guía de configuración del runner auto-alojado, `gh` ya debería estar instalado como parte de los prerrequisitos. Si no es así, o para confirmar:

1.  **Instalar `gh`:**
    Abre una terminal en tu Raspberry Pi y ejecuta:
    ```bash
    sudo pacman -S --noconfirm --needed github-cli
    ```
    *   `--noconfirm`: Evita la solicitud de confirmación.
    *   `--needed`: Solo instala si el paquete no está presente o si hay una versión más nueva disponible.

2.  **Verificar la instalación:**
    Para confirmar que `gh` está instalado y ver su versión:
    ```bash
    gh --version
    ```
    Esto debería mostrar la versión de `gh` instalada, por ejemplo: `gh version 2.XX.X (YYYY-MM-DD)`.

## Autenticación de `gh` (para el usuario `github-runner`)
La autenticación de `gh` debe realizarse con el usuario que efectivamente utilizará la herramienta. En nuestro caso, es el usuario `github-runner` que hemos creado para el servicio de GitHub Actions.

### Paso 1: Iniciar sesión como `github-runner`
Si estás operando como `root` o tu usuario personal, necesitas cambiar al usuario `github-runner` para realizar la autenticación en su contexto. La forma más limpia de hacerlo es iniciar una sesión interactiva como `github-runner`:

```bash
sudo -iu github-runner
```
*   `sudo`: Ejecuta el comando como superusuario.
*   `-i`: Simula un inicio de sesión inicial, cargando el entorno del usuario `github-runner` (incluyendo su directorio home, `$HOME`).
*   `-u github-runner`: Especifica que el comando se ejecute como el usuario `github-runner`.

Después de ejecutar este comando, tu prompt cambiará, indicando que ahora estás operando como `github-runner` (e.g., `[github-runner@hostname ~]$`).

### Paso 2: Proceso de Autenticación con `gh auth login`
Una vez que estés como el usuario `github-runner`, inicia el proceso de autenticación:

```bash
gh auth login
```

`gh` te guiará a través de una serie de preguntas:

1.  **What account do you want to log into?**
    *   Selecciona: `GitHub.com` (esta es la opción por defecto si solo trabajas con github.com).

2.  **What is your preferred protocol for Git operations?**
    *   Selecciona: `HTTPS`
    *   (Si has configurado claves SSH para el usuario `github-runner` y prefieres usarlas para operaciones `git`, podrías elegir `SSH`. Para la mayoría de los casos, `HTTPS` es más sencillo de configurar con tokens).

3.  **Authenticate Git with your GitHub credentials?**
    *   Selecciona: `Y` (Yes)
    *   Esto es muy útil porque permite que los comandos `git clone`, `git push`, `git pull`, etc., que se ejecutan sobre HTTPS utilicen el token de `gh` automáticamente, sin necesidad de configurar gestores de credenciales de Git adicionales o ingresar tu token/contraseña manualmente para cada operación Git.

4.  **How would you like to authenticate?**
    *   Selecciona: `Paste an authentication token`
    *   Esta opción es la más adecuada para entornos de servidor o runners, ya que no requiere abrir un navegador en la Raspberry Pi.

A continuación, `gh` te pedirá que pegues el token.

#### Obtener un Personal Access Token (PAT)

Para obtener el token que necesitas pegar:

1.  **Abre un navegador web** en tu computadora de escritorio o cualquier dispositivo con acceso a GitHub.
2.  **Navega a GitHub y accede a tu cuenta.**
3.  Ve a **Settings** (haz clic en tu foto de perfil en la esquina superior derecha).
4.  En el menú de la izquierda, desplázate hacia abajo y haz clic en **Developer settings**.
5.  En el menú de la izquierda de "Developer settings", haz clic en **Personal access tokens**, y luego selecciona **Tokens (classic)**.
6.  Haz clic en el botón **Generate new token** (o **Generate new token (classic)**).
7.  **Nota (Nombre del Token):** Asígnale un nombre descriptivo para que puedas identificarlo más tarde, por ejemplo: `gh-rpi-runner-surviving-chernarus`.
8.  **Expiration (Expiración):** Establece una fecha de expiración adecuada para el token. Para un runner, podrías considerar una expiración más larga, pero ten en cuenta las implicaciones de seguridad. También puedes optar por no expiración, aunque es menos seguro.
9.  **Scopes (Permisos):** Selecciona los permisos (scopes) que necesitará el token. Los scopes definen a qué puede acceder el token.
    *   Para operaciones generales de repositorio y para que el runner interactúe con el repositorio (como clonar, reportar estado, etc.), el scope `repo` es fundamental. Este scope otorga control total sobre tus repositorios (privados y públicos).
    *   Si planeas usar `gh` para gestionar workflows (e.g., `gh workflow run`), necesitarás el scope `workflow`.
    *   **Para este caso, selecciona al menos `repo`.** Lee la descripción de cada scope cuidadosamente antes de seleccionarlo.
10. Haz clic en el botón **Generate token** en la parte inferior de la página.
11. **¡IMPORTANTE! Copia el token generado inmediatamente.** GitHub solo te mostrará el token una vez. No podrás volver a verlo. Guárdalo temporalmente en un lugar seguro hasta que lo pegues en la terminal.

#### Pegar el Token en la Terminal

Vuelve a la terminal de tu Raspberry Pi (donde `gh auth login` está esperando el token) y pega el Personal Access Token que acabas de copiar. Presiona Enter.

### Paso 3: Verificar la Autenticación
Después de pegar el token, `gh` intentará autenticarse con GitHub. Si todo es correcto, deberías ver un mensaje de éxito.

Para confirmar que la autenticación ha sido exitosa y que `gh` puede acceder a tu información:

1.  **Verificar el estado de la autenticación:**
    ```bash
    gh auth status
    ```
    Deberías ver una salida similar a esta, indicando que estás logueado a `github.com` como tu usuario y qué scopes tiene el token:
    ```
    github.com
      ✓ Logged in to github.com as TuNombreDeUsuario (oauth_token)
      ✓ Git operations for github.com configured to use https protocol.
      ✓ Token: *******************
      ✓ Token scopes: 'repo', 'workflow', ...
    ```

2.  **Verificar el acceso al repositorio:**
    Intenta ver información de tu repositorio. Reemplaza `terrerovgh/surviving-chernarus` con tu nombre de usuario y repositorio si es diferente:
    ```bash
    gh repo view terrerovgh/surviving-chernarus
    ```
    Si el token tiene el scope `repo` y es válido, esto debería mostrar detalles sobre tu repositorio. Si falla, revisa los scopes de tu token o si hubo algún error al pegar el token.

## Almacenamiento Seguro del Token por `gh`
Una vez que te autenticas exitosamente, `gh` almacena el token de forma segura en un archivo de configuración dentro del directorio home del usuario que realizó la autenticación. Para el usuario `github-runner`, este archivo se encuentra en:

`~/.config/gh/hosts.yml` (que se expande a `/home/github-runner/.config/gh/hosts.yml`)

*   **No es necesario exponer el token en scripts:** Gracias a este almacenamiento, no necesitas incluir tu token directamente en scripts o variables de entorno para que `gh` funcione. `gh` lo leerá automáticamente desde este archivo.
*   **Permisos del Archivo:** `gh` establece permisos restrictivos para este archivo (generalmente `600`, es decir, solo lectura y escritura para el propietario), lo cual es bueno para la seguridad. Asegúrate de que estos permisos no se modifiquen accidentalmente para ser más permisivos.

## Uso Básico de `gh` (Ejemplos Opcionales)
Ahora que `gh` está autenticado para el usuario `github-runner`, puedes usarlo para varias tareas. Aquí algunos ejemplos básicos:

*   **Clonar un repositorio (si se quisiera hacer manualmente):**
    ```bash
    gh repo clone terrerovgh/surviving-chernarus
    ```

*   **Listar Pull Requests del repositorio:**
    ```bash
    gh pr list -R terrerovgh/surviving-chernarus
    ```
    (El flag `-R` es necesario si no estás dentro de un directorio de repositorio clonado).

*   **Listar las ejecuciones de workflows recientes:**
    ```bash
    gh run list -R terrerovgh/surviving-chernarus
    ```

*   **Ver el estado de los runners del repositorio:**
    ```bash
    gh runner list -R terrerovgh/surviving-chernarus
    ```

Estos son solo algunos ejemplos. `gh` tiene una amplia gama de comandos y subcomandos que puedes explorar con `gh --help` o `gh [comando] --help`.

Con `gh` correctamente instalado y autenticado para el usuario `github-runner`, tienes una herramienta robusta para la gestión y automatización de tareas relacionadas con GitHub en tu Raspberry Pi.
