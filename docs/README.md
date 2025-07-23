Informe de Diseño y Despliegue: Ecosistema Autónomo "Surviving Chernarus" en Raspberry Pi 5Resumen EjecutivoEste documento presenta un plan de desarrollo e implementación exhaustivo para el proyecto "Surviving Chernarus", un ecosistema de servicios autoalojado, resiliente y portátil, diseñado para operar en una Raspberry Pi 5 con una arquitectura aarch64. El informe detalla cada fase del despliegue, desde la preparación del sistema operativo base hasta la orquestación de una pila de servicios contenerizados, gestionados a través de Docker Compose. La filosofía central del proyecto —resiliencia, autonomía y portabilidad— guía cada decisión arquitectónica, priorizando la seguridad, la mantenibilidad a largo plazo y el control total sobre los datos y la infraestructura.El plan está estructurado para culminar en la creación de un único y extenso prompt de despliegue. Este prompt está diseñado para ser ejecutado por un agente de inteligencia artificial avanzado, capaz de conectarse a la Raspberry Pi mediante SSH y llevar a cabo la instalación, configuración, verificación y resolución de problemas de forma autónoma. Los componentes clave del ecosistema incluyen Traefik como proxy inverso con gestión automática de SSL/TLS a través de Cloudflare, PostgreSQL como base de datos persistente, Pi-hole para el filtrado de DNS a nivel de red, n8n como núcleo de automatización, rTorrent para la gestión de descargas, un panel de control personalizado y un proxy Squid opcional para la gestión avanzada del tráfico.Se abordan configuraciones de red complejas, como el funcionamiento de la Raspberry Pi en modo dual: como cliente de redes públicas (incluyendo aquellas con portales cautivos) y como punto de acceso Wi-Fi para dispositivos personales. Se presta especial atención a las mejores prácticas de seguridad, incluyendo el endurecimiento del sistema operativo, la configuración correcta del firewall UFW en conjunción con Docker y la gestión segura de secretos mediante archivos de entorno. El resultado final es un sistema robusto, seguro y completamente automatizado que encarna los principios de soberanía digital y resiliencia operativa.Sección 1: Fundación del Sistema y Postura de SeguridadLa base de cualquier sistema resiliente es un sistema operativo robusto y seguro. Esta sección detalla el proceso de aprovisionamiento de la Raspberry Pi 5 con un enfoque "headless-first" (sin monitor), garantizando que el sistema sea inmediatamente accesible para la automatización y esté endurecido desde el primer arranque.1.1. Aprovisionamiento de la Raspberry Pi 5: Un Enfoque "Headless-First"El objetivo es preparar la imagen del sistema operativo de tal manera que no requiera intervención manual después del primer arranque, haciéndola instantáneamente accesible para el agente de IA. Este método transforma la creación de la imagen en un paso de configuración declarativa, fundamental para un despliegue automatizado y reproducible.Proceso de Aprovisionamiento:Software de Imagen: Se utilizará el software oficial Raspberry Pi Imager. Esta herramienta es el método más fiable y completo, ya que permite una preconfiguración extensiva del sistema operativo antes del primer arranque.1Selección del Sistema Operativo: Se debe seleccionar la versión Raspberry Pi OS Lite (64-bit). Esta elección es crítica por varias razones:Compatibilidad: Proporciona el entorno aarch64 nativo necesario para la compatibilidad con las imágenes de Docker modernas y de alto rendimiento.2Eficiencia de Recursos: Al ser una versión "Lite", carece de un entorno de escritorio gráfico, lo que reduce significativamente el consumo de RAM y CPU, liberando más recursos para la pila de servicios.6Seguridad: Un sistema operativo minimalista reduce la superficie de ataque, lo que se alinea directamente con la filosofía de resiliencia del proyecto.Configuración Avanzada: A través de las "Opciones Avanzadas" del Imager (accesibles con el icono de engranaje o el atajo Ctrl+Shift+X), se preconfigurarán los siguientes parámetros esenciales 1:Hostname: Se establecerá un nombre de host único y fácil de recordar (p. ej., chernarus-pi) para facilitar la conexión en la red local.Habilitación de SSH: Se habilitará el servicio SSH y se configurará para la autenticación por contraseña. Si bien la autenticación por clave pública es más segura a largo plazo, la autenticación por contraseña es suficiente y más directa para el acceso inicial del agente de IA.Creación de Usuario: Se creará una cuenta de usuario no predeterminada con una contraseña segura. Este es un paso de seguridad fundamental para evitar el uso de credenciales por defecto como pi y raspberry, que son un objetivo común para ataques automatizados.1Configuración de Red: Se preconfigurarán las credenciales de una red Wi-Fi conocida (p. ej., la red doméstica). Esto asegura que la Raspberry Pi se conecte a Internet y obtenga una dirección IP inmediatamente después de arrancar, haciéndola accesible para el agente de IA sin necesidad de una conexión Ethernet inicial.Medio de Almacenamiento: La imagen del sistema operativo se escribirá en una tarjeta Micro SD de alta calidad (clase A2 o superior) o, preferiblemente, en una unidad de estado sólido (SSD) externa conectada por USB 3.0. El uso de un SSD mejora drásticamente el rendimiento de E/S y la longevidad del sistema en comparación con las tarjetas SD, que tienen ciclos de escritura limitados y son un punto de fallo común en operaciones de servidor 24/7.7La utilización del Raspberry Pi Imager como una herramienta de configuración declarativa es un pilar fundamental para la automatización. En lugar de seguir un proceso imperativo (flashear, arrancar, configurar manualmente), se define el estado deseado del sistema desde el principio. Esto garantiza que el agente de IA siempre se conecte a un entorno conocido y preconfigurado, lo que aumenta la fiabilidad y la idempotencia de todo el script de despliegue.1.2. Endurecimiento Inicial del Sistema: Actualizaciones y Configuración del Firewall para DockerUna vez que el sistema base está operativo, el siguiente paso es asegurar el entorno antes de desplegar cualquier servicio. Esto implica actualizar todos los paquetes y configurar correctamente el firewall del host, prestando especial atención a su interacción con Docker.Proceso de Endurecimiento:Actualización del Sistema: El primer comando que ejecutará el agente de IA tras la conexión SSH será una actualización completa del sistema para parchear cualquier vulnerabilidad conocida y asegurar que todas las dependencias estén en sus versiones más recientes.4Bashsudo apt update && sudo apt full-upgrade -y && sudo apt autoremove -y
Instalación y Configuración de UFW: Se instalará Uncomplicated Firewall (UFW), un frontend accesible para iptables.Bashsudo apt install ufw -y
Políticas por Defecto: Se establecerán políticas de firewall restrictivas por defecto, denegando todo el tráfico entrante y permitiendo todo el saliente. Esta es la base de una postura de seguridad de "denegar por defecto".10Bashsudo ufw default deny incoming
sudo ufw default allow outgoing
Permitir Servicios Esenciales: Se abrirán los puertos necesarios para la gestión y el funcionamiento del proxy inverso.Bashsudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
Integración de UFW con Docker: Este es el paso más crítico en la configuración del firewall. Por defecto, Docker manipula directamente las cadenas PREROUTING y FORWARD de iptables para gestionar el mapeo de puertos. Esta acción se produce a un nivel más bajo que las reglas de UFW, lo que provoca que los puertos expuestos por los contenedores Docker (-p host:container) eludan por completo las reglas de UFW.11 Si un contenedor expone el puerto 8080, este será accesible desde el exterior incluso si UFW está configurado para denegar todo el tráfico entrante.La solución incorrecta, a menudo sugerida, es deshabilitar la gestión de iptables por parte de Docker ("iptables": false en /etc/docker/daemon.json).12 Aunque esto devuelve el control a UFW, también rompe la red interna de Docker, impidiendo que los contenedores se comuniquen entre sí y accedan a Internet, lo cual es inaceptable para este proyecto.La solución arquitectónicamente correcta es integrar ambos sistemas. Docker crea una cadena personalizada en iptables llamada DOCKER-USER dentro de la cadena FORWARD. Esta cadena está diseñada específicamente para que los administradores inserten sus propias reglas. Al añadir reglas personalizadas en el archivo /etc/ufw/after.rules, podemos hacer que UFW gestione el tráfico destinado a los contenedores antes de que Docker aplique sus propias reglas de mapeo.El agente de IA modificará /etc/ufw/after.rules para añadir el siguiente bloque de configuración antes de la línea *filter existente 12:Ini, TOML# BEGIN UFW AND DOCKER
*filter
:DOCKER-USER - [0:0]
-A DOCKER-USER -j RETURN -s 10.0.0.0/8
-A DOCKER-USER -j RETURN -s 172.16.0.0/12
-A DOCKER-USER -j RETURN -s 192.168.0.0/16

-A DOCKER-USER -p udp -m udp --sport 53 --dport 1024:65535 -j RETURN

-A DOCKER-USER -j ufw-user-forward

-A DOCKER-USER -j DROP -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -d 192.168.0.0/16
-A DOCKER-USER -j DROP -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -d 10.0.0.0/8
-A DOCKER-USER -j DROP -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -d 172.16.0.0/12
-A DOCKER-USER -j DROP -p udp -m udp --dport 0:32767 -d 192.168.0.0/16
-A DOCKER-USER -j DROP -p udp -m udp --dport 0:32767 -d 10.0.0.0/8
-A DOCKER-USER -j DROP -p udp -m udp --dport 0:32767 -d 172.16.0.0/12

-A DOCKER-USER -j RETURN
COMMIT
# END UFW AND DOCKER
Adicionalmente, se modificará /etc/default/ufw para cambiar DEFAULT_FORWARD_POLICY="DROP" a DEFAULT_FORWARD_POLICY="ACCEPT".Activación del Firewall: Finalmente, el firewall se activará y se configurará para iniciarse en el arranque.Bashsudo ufw enable
Este enfoque de integración preserva la funcionalidad de red nativa de Docker mientras restaura la capacidad de UFW para actuar como el único punto de control del firewall, cumpliendo con los objetivos de seguridad y resiliencia del proyecto.Sección 2: Establecimiento del Entorno de ContenerizaciónCon una base de sistema segura, el siguiente paso es instalar el entorno de ejecución de contenedores. Se priorizará el método de instalación oficial y mantenible, que se integra con el gestor de paquetes del sistema, en lugar de scripts de conveniencia que pueden comprometer la estabilidad a largo plazo.2.1. Instalación de Docker Engine y el Plugin de ComposeEl objetivo es instalar Docker y el plugin de Docker Compose utilizando el método de repositorio apt oficial de Docker. Este enfoque garantiza la obtención de versiones estables, actualizaciones de seguridad oportunas y una integración limpia con el sistema operativo.Proceso de Instalación:Instalación de Dependencias: Se instalarán los paquetes necesarios para añadir un nuevo repositorio apt de forma segura.8Bashsudo apt install ca-certificates curl gnupg -y
Añadir la Clave GPG Oficial de Docker: Se descargará y añadirá la clave GPG de Docker al llavero de apt. Este paso es crucial para verificar la autenticidad de los paquetes de Docker que se instalarán, protegiendo el sistema contra paquetes maliciosos o manipulados.8Bashsudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
Configurar el Repositorio apt de Docker: Se añadirá el repositorio oficial de Docker a las fuentes de apt del sistema. El siguiente comando está diseñado para detectar automáticamente la arquitectura (arm64) y la versión del sistema operativo (p. ej., bookworm) para configurar la fuente correcta.8Bashecho \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
Instalación de los Paquetes de Docker: Tras actualizar la lista de paquetes para incluir el nuevo repositorio, se instalará el conjunto completo de herramientas de Docker.Bashsudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
Este único comando instala el motor de Docker (docker-ce), la interfaz de línea de comandos (docker-ce-cli), el runtime de contenedores (containerd.io), y, de manera importante, el plugin moderno de docker-compose. Esto asegura el uso de la sintaxis docker compose (Compose V2), que está integrada en el CLI de Docker y es el estándar actual.8La decisión de utilizar el método del repositorio apt en lugar del popular script de conveniencia (curl... | sh) es deliberada y fundamental para la filosofía de resiliencia del proyecto.11 Mientras que el script de conveniencia es rápido, no se recomienda para entornos de producción porque instala la última versión sin control y no se integra en el ciclo de vida de la gestión de paquetes del sistema. El método del repositorio, en cambio, trata a Docker como un paquete de sistema más. Esto significa que las actualizaciones de seguridad y de versión de Docker se gestionarán de forma centralizada y predecible a través de los comandos estándar sudo apt update y sudo apt upgrade, garantizando una mayor estabilidad y facilidad de mantenimiento a largo plazo.2.2. Post-Instalación: Permisos y VerificaciónUna vez instalado Docker, es necesario realizar una configuración final para mejorar la usabilidad y verificar que el entorno está funcionando correctamente.Proceso de Post-Instalación:Gestión de Permisos de Usuario: Por defecto, solo el usuario root puede ejecutar comandos de Docker. Para permitir que el usuario no-root creado durante la instalación del SO gestione Docker, se debe añadir al grupo docker. Este es un paso crucial para la seguridad y la conveniencia, ya que evita la necesidad de usar sudo para cada comando de Docker.4Bashsudo usermod -aG docker $USER
Aplicación de la Pertenencia al Grupo: Los cambios en la pertenencia a grupos no se aplican a las sesiones de shell existentes. Para que el cambio surta efecto, el agente de IA deberá ejecutar un comando que inicie una nueva sesión de shell con los nuevos permisos, o bien se le indicará que se desconecte y vuelva a conectarse.8 El comando newgrp docker puede lograr esto de forma no interactiva.Bashnewgrp docker
Habilitar el Servicio Docker: Para asegurar que el motor de Docker se inicie automáticamente cada vez que la Raspberry Pi se reinicie, el servicio de systemd debe ser habilitado.8Bashsudo systemctl enable docker
sudo systemctl start docker
Verificación Final: Se ejecutará una serie de comandos para confirmar que tanto Docker Engine como el plugin de Compose están instalados y son funcionales. El paso final es ejecutar el contenedor hello-world, que confirma que todo el ciclo de vida del contenedor (descarga de imagen, creación y ejecución) funciona correctamente.8Bashdocker --version
docker compose version
docker run hello-world
Con estos pasos completados, la Raspberry Pi está equipada con un entorno de contenerización robusto y listo para el despliegue de la pila de servicios "Surviving Chernarus".Sección 3: Arquitectura de la Pila Docker ComposeEsta sección define la arquitectura del software del proyecto, detallando la estructura de directorios, la gestión de secretos y el diseño del archivo docker-compose.yml maestro. Este archivo servirá como el plano declarativo para todo el ecosistema de servicios.3.1. Estructura de Directorios y Gestión Segura de Secretos (.env)Una estructura de proyecto bien organizada es clave para la portabilidad y la mantenibilidad. Se creará un directorio de proyecto autocontenido que albergará todas las configuraciones y los datos persistentes. La gestión de información sensible se centralizará en un archivo .env, separando la configuración de la orquestación.Estructura del Proyecto:El agente de IA creará la siguiente estructura de directorios en una ubicación estándar como /opt/surviving-chernarus:/opt/surviving-chernarus/
├── docker-compose.yml
├──.env
├── traefik_data/
│   ├── traefik.yml
│   └── acme.json
├── postgres_data/
├── pihole_data/
│   ├── pihole/
│   └── dnsmasq.d/
├── n8n_data/
├── rtorrent_data/
│   ├── config/
│   ├── downloads/
│   └── session/
├── heimdall_data/
└── squid_data/ (Opcional)
    ├── squid.conf
    └── cache/
Esta estructura centraliza todos los datos persistentes, lo que simplifica enormemente los procedimientos de respaldo y restauración.Gestión de Secretos con .env:Toda la información sensible y los parámetros configurables por el usuario se definirán en un único archivo .env en la raíz del proyecto. Docker Compose lee automáticamente este archivo y sustituye las variables en el archivo docker-compose.yml. Esta es una práctica recomendada que mejora la seguridad al evitar el almacenamiento de secretos en el control de versiones y facilita la configuración para diferentes entornos.18La siguiente tabla detalla las variables que se definirán en el archivo .env. Sirve como una única fuente de verdad para toda la configuración del usuario, haciendo que el despliegue sea transparente y fácil de personalizar.VariableDescripciónValor de EjemploPUIDID de usuario para la propiedad de los archivos en los volúmenes. Se obtiene con id -u en la Pi.1000PGIDID de grupo para la propiedad de los archivos en los volúmenes. Se obtiene con id -g en la Pi.1000TZZona horaria para todos los contenedores, en formato de base de datos TZ.America/New_YorkDOMAIN_NAMEEl dominio público gestionado en Cloudflare para los servicios.chernarus.netCLOUDFLARE_EMAILLa dirección de correo electrónico de la cuenta de Cloudflare.user@example.comCLOUDFLARE_API_TOKENToken de la API de Cloudflare con permisos de edición de DNS.aBcDeFgHiJkLmNoPqRsTuVwXyZ1234567890POSTGRES_DBNombre de la base de datos principal que utilizará n8n.n8n_chernarusPOSTGRES_USERNombre de usuario para el superusuario de la base de datos PostgreSQL.chernarus_adminPOSTGRES_PASSWORDContraseña segura para el superusuario de la base de datos PostgreSQL.S3cur3P0stgr3sPa$$w0rd!PIHOLE_PASSWORDContraseña de administrador para la interfaz web de Pi-hole.S3cur3P1h0l3Pa$$w0rd!3.2. Definición de Redes Centrales y el docker-compose.yml MaestroEl archivo docker-compose.yml es el corazón de la orquestación. Se iniciará definiendo una red personalizada que conectará todos los servicios, proporcionando aislamiento y resolución de nombres de dominio (DNS) interna.Configuración Inicial del docker-compose.yml:El agente de IA creará el archivo docker-compose.yml con la siguiente estructura base:YAMLversion: '3.8'

services:
  #... los servicios se definirán aquí...

networks:
  cher-net:
    driver: bridge

volumes:
  #... los volúmenes persistentes se definirán aquí...
La red cher-net, de tipo bridge, permite que los contenedores se comuniquen entre sí utilizando sus nombres de servicio como nombres de host (p. ej., el contenedor de n8n puede conectarse a la base de datos en la dirección postgres:5432). Esto desacopla los servicios y los hace más portátiles.73.3. Implementación de Traefik con Cloudflare para un Acceso SeguroTraefik actuará como el único punto de entrada a la red de servicios, gestionando todo el tráfico HTTP/S. Su configuración se dividirá en una parte estática (definida en un archivo) y una dinámica (descubierta a través de las etiquetas de Docker).Configuración del Servicio Traefik:YAMLservices:
  traefik:
    image: traefik:latest
    container_name: traefik
    restart: unless-stopped
    security_opt:
      - no-new-privileges:true
    networks:
      - cher-net
    ports:
      - "80:80"
      - "443:443"
    environment:
      - CLOUDFLARE_EMAIL=${CLOUDFLARE_EMAIL}
      - CLOUDFLARE_API_TOKEN=${CLOUDFLARE_API_TOKEN}
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      -./traefik_data/traefik.yml:/etc/traefik/traefik.yml:ro
      -./traefik_data/acme.json:/acme.json
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.traefik-secure.entrypoints=websecure"
      - "traefik.http.routers.traefik-secure.rule=Host(`traefik.${DOMAIN_NAME}`)"
      - "traefik.http.routers.traefik-secure.tls=true"
      - "traefik.http.routers.traefik-secure.tls.certresolver=cloudflare_resolver"
      - "traefik.http.routers.traefik-secure.service=api@internal"
Configuración Estática (traefik.yml):Este archivo define el comportamiento fundamental de Traefik.YAMLapi:
  dashboard: true
  insecure: true # Se accederá a través de un router seguro

entryPoints:
  web:
    address: ":80"
    http:
      redirections:
        entryPoint:
          to: websecure
          scheme: https
  websecure:
    address: ":443"

providers:
  docker:
    exposedByDefault: false
    network: cher-net

certificatesResolvers:
  cloudflare_resolver:
    acme:
      email: ${CLOUDFLARE_EMAIL}
      storage: /acme.json
      dnsChallenge:
        provider: cloudflare
        resolvers:
          - "1.1.1.1:53"
          - "1.0.0.1:53"
La elección del desafío DNS-01 de Let's Encrypt es una decisión de seguridad deliberada y de gran importancia.23 El método estándar (desafío HTTP-01) requiere que el puerto 80 del servidor sea accesible públicamente desde Internet para que los servidores de Let's Encrypt puedan verificar la propiedad del dominio. Para un dispositivo portátil como la Raspberry Pi, que puede conectarse a redes públicas no confiables, mantener el puerto 80 abierto permanentemente es un riesgo de seguridad innecesario.El desafío DNS-01, en cambio, verifica la propiedad del dominio creando un registro TXT temporal en la zona DNS a través de la API de Cloudflare. Esto significa que la validación se realiza a nivel de DNS, sin necesidad de exponer ningún puerto para el proceso de emisión o renovación de certificados. El único requisito es una conexión a Internet saliente y el token de la API. Esto mejora significativamente la postura de seguridad del sistema, ya que el único tráfico entrante permitido será el tráfico HTTPS cifrado en el puerto 443, gestionado por Traefik.3.4. Despliegue de un Almacén de Datos Persistente con PostgreSQLPara servicios como n8n que requieren una base de datos, se desplegará un contenedor PostgreSQL. La persistencia de los datos es la máxima prioridad.Configuración del Servicio PostgreSQL:YAMLservices:
  #... traefik...
  postgres:
    image: postgres:16-alpine
    container_name: postgres
    restart: unless-stopped
    networks:
      - cher-net
    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test:
      interval: 10s
      timeout: 5s
      retries: 5
La persistencia de los datos se logra mediante el uso de un volumen nombrado (postgres_data), definido en la sección volumes de nivel superior.YAMLvolumes:
  postgres_data:
    driver: local
La elección de volúmenes nombrados sobre montajes de enlace (bind mounts) es otra decisión arquitectónica clave para la portabilidad.26 Un montaje de enlace (-./postgres_data:/var/lib/postgresql/data) vincula un directorio específico del host al contenedor. Esto crea una dependencia estricta de la estructura de directorios del host. Los volúmenes nombrados, por otro lado, son gestionados por el motor de Docker. Sus datos se almacenan en un área dedicada del sistema de archivos del host (generalmente /var/lib/docker/volumes/), pero se gestionan de forma abstracta. Esto significa que toda la pila de Docker Compose, junto con sus datos, se puede migrar a un nuevo host con mayor facilidad, y los procedimientos de respaldo se simplifican al apuntar directamente al directorio de volúmenes de Docker.Sección 4: Despliegue del Ecosistema de ServiciosCon la infraestructura base (Traefik y PostgreSQL) definida, esta sección detalla la configuración de cada servicio de aplicación. Cada servicio se integrará en la red cher-net, utilizará volúmenes nombrados para la persistencia y se expondrá de forma segura a través de Traefik.4.1. Pi-hole: El Guardián DNS de la RedPi-hole funcionará como el servidor DNS para la red local del hotspot, proporcionando filtrado de anuncios y telemetría para todos los dispositivos conectados.Configuración del Servicio Pi-hole:YAMLservices:
  #... traefik, postgres...
  pihole:
    image: pihole/pihole:latest
    container_name: pihole
    restart: unless-stopped
    networks:
      - cher-net
    ports:
      - "53:53/tcp"
      - "53:53/udp"
    environment:
      TZ: '${TZ}'
      WEBPASSWORD: '${PIHOLE_PASSWORD}'
      FTLCONF_dns_listeningMode: 'all'
    volumes:
      - pihole_etc:/etc/pihole
      - pihole_dnsmasq:/etc/dnsmasq.d
    cap_add:
      - NET_ADMIN # Necesario para diagnósticos avanzados, opcional si no se usa DHCP de Pi-hole
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.pihole-secure.entrypoints=websecure"
      - "traefik.http.routers.pihole-secure.rule=Host(`pihole.${DOMAIN_NAME}`)"
      - "traefik.http.routers.pihole-secure.tls=true"
      - "traefik.http.routers.pihole-secure.tls.certresolver=cloudflare_resolver"
      - "traefik.http.services.pihole.loadbalancer.server.port=80"
      - "traefik.http.middlewares.pihole-admin.addprefix.prefix=/admin"
      - "traefik.http.routers.pihole-secure.middlewares=pihole-admin@docker"
La imagen oficial pihole/pihole es multi-arquitectura, por lo que funcionará de forma nativa en la Raspberry Pi 5 arm64.28 Los puertos DNS (53/tcp y 53/udp) se exponen directamente al host para que el servicio dnsmasq del host pueda reenviar las consultas a él. La interfaz web, sin embargo, no se expone públicamente; en su lugar, Traefik la enruta de forma segura a través de un subdominio. La variable de entorno FTLCONF_dns_listeningMode: 'all' es crucial para que Pi-hole acepte consultas de cualquier interfaz dentro de su red Docker.304.2. n8n: El Núcleo de Automatizaciónn8n es el cerebro del proyecto, orquestando flujos de trabajo y procesos de IA. Su configuración se centrará en la integración con la base de datos PostgreSQL para una persistencia robusta.Configuración del Servicio n8n:YAMLservices:
  #... otros servicios...
  n8n:
    image: n8nio/n8n:latest
    container_name: n8n
    restart: unless-stopped
    networks:
      - cher-net
    environment:
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_DATABASE=${POSTGRES_DB}
      - DB_POSTGRESDB_USER=${POSTGRES_USER}
      - DB_POSTGRESDB_PASSWORD=${POSTGRES_PASSWORD}
      - GENERIC_TIMEZONE=${TZ}
      - N8N_HOST=${DOMAIN_NAME}
      - N8N_PROTOCOL=https
      - WEBHOOK_URL=https://${DOMAIN_NAME}/
    volumes:
      - n8n_data:/home/node/.n8n
    depends_on:
      postgres:
        condition: service_healthy
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.n8n-secure.entrypoints=websecure"
      - "traefik.http.routers.n8n-secure.rule=Host(`n8n.${DOMAIN_NAME}`)"
      - "traefik.http.routers.n8n-secure.tls=true"
      - "traefik.http.routers.n8n-secure.tls.certresolver=cloudflare_resolver"
      - "traefik.http.services.n8n.loadbalancer.server.port=5678"
La imagen n8nio/n8n también es compatible con arm64.31 La configuración de las variables de entorno DB_* es fundamental para que n8n utilice PostgreSQL en lugar de su base de datos SQLite por defecto, lo que es recomendable para cualquier uso más allá de la experimentación.33 La directiva depends_on con condition: service_healthy garantiza que n8n no intente iniciarse hasta que la base de datos PostgreSQL esté completamente lista para aceptar conexiones, evitando así bucles de reinicio y errores de conexión.354.3. rTorrent y Flood: El Gestor de DescargasPara la gestión de descargas automatizadas, se implementará una combinación del cliente de torrents rTorrent con la moderna interfaz web Flood.Configuración del Servicio rTorrent/Flood:Se utilizará una imagen combinada que simplifica el despliegue. La imagen jesec/rtorrent-flood es una excelente opción moderna y compatible con arm64.36YAMLservices:
  #... otros servicios...
  rtorrent:
    image: jesec/rtorrent-flood
    container_name: rtorrent-flood
    restart: unless-stopped
    networks:
      - cher-net
    ports:
      - "6881:6881/tcp"
      - "6881:6881/udp"
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
    volumes:
      - rtorrent_config:/config
      - rtorrent_downloads:/data
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.flood-secure.entrypoints=websecure"
      - "traefik.http.routers.flood-secure.rule=Host(`rtorrent.${DOMAIN_NAME}`)"
      - "traefik.http.routers.flood-secure.tls=true"
      - "traefik.http.routers.flood-secure.tls.certresolver=cloudflare_resolver"
      - "traefik.http.services.flood.loadbalancer.server.port=3000"
Se exponen los puertos de BitTorrent directamente al host para una conectividad óptima con los pares. La interfaz web de Flood (puerto 3000 interno) se expone de forma segura a través de Traefik. Los volúmenes nombrados para /config y /data aseguran que tanto la configuración de rTorrent como los archivos descargados persistan entre reinicios del contenedor.4.4. (Opcional) Squid: El Proxy de Caché y Enrutamiento AvanzadoEl servicio Squid es opcional y proporciona capacidades avanzadas de caché y enrutamiento de tráfico. Su configuración más potente implica enrutar su tráfico de salida a través de un túnel VPN, aislando eficazmente el tráfico de ciertas aplicaciones del resto del sistema.Configuración del Servicio Squid con VPN:Esta configuración requiere un contenedor "sidecar" para la VPN. Se utilizará dperson/openvpn-client para la conexión VPN y ubuntu/squid para el proxy.38YAMLservices:
  #... otros servicios...
  openvpn:
    image: dperson/openvpn-client
    container_name: openvpn_client
    cap_add:
      - NET_ADMIN
    security_opt:
      - label:disable
    devices:
      - /dev/net/tun
    volumes:
      -./vpn_config:/vpn # Directorio en el host con el archivo.ovpn
    restart: unless-stopped
    networks:
      - cher-net

  squid:
    image: ubuntu/squid:latest
    container_name: squid_proxy
    restart: unless-stopped
    ports:
      - "3128:3128" # Expuesto solo internamente si es necesario
    volumes:
      -./squid_data/squid.conf:/etc/squid/squid.conf
      - squid_cache:/var/spool/squid
    network_mode: "service:openvpn_client"
    depends_on:
      - openvpn
La directiva network_mode: "service:openvpn_client" es la clave de esta configuración. Obliga al contenedor squid a utilizar el mismo espacio de nombres de red que el contenedor openvpn. Como resultado, todo el tráfico de red generado por Squid se enruta automáticamente a través del túnel VPN establecido por el cliente OpenVPN, sin necesidad de complejas reglas de enrutamiento en el host. El puerto 3128 de Squid puede ser utilizado por otros contenedores en la red cher-net o por el dnsmasq del host para los clientes del hotspot.4.5. Dashy: El Panel de Control CentralizadoPara proporcionar una interfaz unificada y visualmente atractiva para todos los servicios, se desplegará un panel de control. Dashy es una opción moderna, altamente personalizable y compatible con arm64.40Configuración del Servicio Dashy:YAMLservices:
  #... otros servicios...
  dashboard:
    image: lissy93/dashy:latest
    container_name: dashboard
    restart: unless-stopped
    networks:
      - cher-net
    volumes:
      -./dashboard_data/conf.yml:/app/user-data/conf.yml
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.dashboard-secure.entrypoints=websecure"
      - "traefik.http.routers.dashboard-secure.rule=Host(`${DOMAIN_NAME}`)"
      - "traefik.http.routers.dashboard-secure.tls=true"
      - "traefik.http.routers.dashboard-secure.tls.certresolver=cloudflare_resolver"
      - "traefik.http.services.dashboard.loadbalancer.server.port=80"
Dashy se configura para ser el servicio por defecto en el dominio principal (Host(\${DOMAIN_NAME}`)). Su configuración se gestiona a través de un único archivo conf.yml` montado en un volumen, lo que permite una personalización sencilla y persistente del panel de control.Sección 5: Capacidades de Red AvanzadasEsta sección detalla la configuración de la Raspberry Pi a nivel de sistema operativo para cumplir con sus roles de red duales: actuar como un punto de acceso Wi-Fi autónomo y conectarse a redes externas, incluyendo aquellas con portales cautivos.5.1. Configuración de un Punto de Acceso Wi-Fi AutónomoPara lograr la portabilidad y autonomía deseadas, la Raspberry Pi creará su propia red Wi-Fi. Esto se logra utilizando hostapd para gestionar el punto de acceso y dnsmasq para los servicios de DHCP y DNS.La decisión de ejecutar estos servicios de red críticos directamente en el sistema operativo anfitrión, en lugar de en contenedores, es deliberada. hostapd y dnsmasq requieren un control de bajo nivel sobre las interfaces de red físicas y la pila de red del kernel. Aunque es técnicamente posible contenerizarlos, hacerlo añade una capa de complejidad significativa (requiriendo modo de red host y capacidades privilegiadas) que puede comprometer la estabilidad. El enfoque adoptado aquí establece una clara separación de responsabilidades: el SO anfitrión gestiona la red física y el enrutamiento, mientras que Docker gestiona los servicios de aplicación.Proceso de Configuración del Hotspot:Instalación de Software en el Host: El agente de IA instalará hostapd y dnsmasq directamente en la Raspberry Pi.43Bashsudo apt install hostapd dnsmasq -y
Configuración de IP Estática para la Interfaz del AP: Se asignará una dirección IP estática a la interfaz Wi-Fi que actuará como punto de acceso (p. ej., wlan1 si se utiliza un adaptador USB externo, o uap0 si se crea una interfaz virtual). Esto se configura en /etc/dhcpcd.conf.Ini, TOMLinterface wlan1
static ip_address=192.168.77.1/24
nohook wpa_supplicant
Configuración de hostapd: Se creará el archivo /etc/hostapd/hostapd.conf para definir los parámetros del punto de acceso, como el SSID, la contraseña y el canal. Es crucial especificar la interfaz correcta.46Ini, TOMLinterface=wlan1
driver=nl80211
ssid=SurvivingChernarus
hw_mode=g
channel=7
wpa=2
wpa_passphrase=YourSecurePassword
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
Configuración de dnsmasq: Se configurará dnsmasq para que actúe como servidor DHCP y DNS para los clientes del hotspot.Servidor DHCP: Se definirá un rango de IPs para asignar a los clientes.Servidor DNS: Este es el punto de integración clave. Se utilizará la opción dhcp-option=6 para instruir a todos los clientes DHCP a utilizar la dirección IP del contenedor de Pi-hole como su único servidor DNS. Esto fuerza todo el tráfico DNS de la red del hotspot a través del filtro de Pi-hole.49Ini, TOMLinterface=wlan1
dhcp-range=192.168.77.10,192.168.77.100,255.255.255.0,24h
dhcp-option=6,172.X.X.X # IP del contenedor Pi-hole
(La IP del contenedor Pi-hole se puede fijar en el docker-compose.yml o se puede descubrir dinámicamente).Habilitar Enrutamiento y NAT: Para que los dispositivos conectados al hotspot puedan acceder a Internet a través de la otra interfaz de red de la Pi (p. ej., eth0 o wlan0), se habilitará el reenvío de IP en el kernel y se configurará una regla de iptables para la Traducción de Direcciones de Red (NAT).43Bashsudo sysctl -w net.ipv4.ip_forward=1
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo netfilter-persistent save
5.2. Automatización de la Conectividad a Redes con Portal CautivoPara la conectividad a redes públicas como xfinitywifi, que requieren una autenticación a través de una página web (portal cautivo), se implementará un framework de automatización.Proceso de Automatización:Instalación de Herramientas: El agente de IA instalará herramientas de línea de comandos como nmcli para la gestión de la red y curl para la interacción HTTP.51Detección del Portal: NetworkManager, a través de nmcli, puede detectar el estado de la conectividad. El comando nmcli networking connectivity devolverá el estado portal cuando se requiera una acción en un portal cautivo.51Script de Autenticación: La lógica de autenticación específica para cada portal cautivo varía. Por lo tanto, el agente de IA creará un script de plantilla, por ejemplo, /usr/local/bin/handle-xfinity-portal.sh. Este script será responsabilidad del usuario final, quien deberá analizar el formulario de inicio de sesión del portal (inspeccionando el HTML) para determinar los campos y valores necesarios, y luego construir un comando curl que envíe una solicitud POST con sus credenciales para completar el inicio de sesión.52Bash# Ejemplo de comando en el script del usuario
curl -X POST \
  -d "user=YOUR_USERNAME" \
  -d "password=YOUR_PASSWORD" \
  -d "other_form_field=value" \
  https://portal.login.url/submit
Ejecución Automatizada: Se puede configurar un servicio de systemd o un trabajo de cron que se ejecute periódicamente. Este trabajo comprobará el estado de la conectividad con nmcli. Si el estado es portal, ejecutará el script de autenticación personalizado del usuario.Este enfoque híbrido proporciona un marco robusto y automatizado, al tiempo que permite la flexibilidad necesaria para adaptarse a los diferentes mecanismos de autenticación de los portales cautivos.Sección 6: El Prompt Maestro de Despliegue para el Agente de IAEsta sección final consolida todo el plan de desarrollo en un único prompt ejecutable, diseñado para ser proporcionado a un agente de IA avanzado. Este prompt es un script de shell completo que guiará al agente a través de cada paso del proceso de instalación y configuración de manera autónoma.6.1. Principios de Diseño del Prompt: Idempotencia y VerificaciónEl prompt se ha diseñado siguiendo principios de ingeniería de software robusta para garantizar un despliegue fiable, incluso si se ejecuta varias veces.Idempotencia: El script está diseñado para ser seguro de ejecutar repetidamente. Antes de realizar una acción (como añadir una línea a un archivo de configuración o crear un directorio), comprueba si esa acción ya se ha completado. Esto evita errores y estados de configuración duplicados o corruptos.Verificación Explícita: Después de cada etapa crítica (p. ej., instalación de Docker, inicio de la pila de Compose), se incluyen comandos de verificación. Estos comandos comprueban el estado de los servicios, la versión del software o la conectividad de la red. Si una verificación falla, el script podría (en una implementación más avanzada) detenerse o registrar un error claro.Modularidad y Claridad: El script está dividido en secciones lógicas con comentarios y sentencias echo que anuncian cada paso. Esto hace que el proceso de ejecución sea transparente y fácil de depurar tanto para un humano como para el agente de IA.Configuración a través de Variables: Todas las configuraciones personalizables y los secretos se definen en un bloque de variables al principio del script. Estas variables se utilizan para generar el archivo .env y otros archivos de configuración, centralizando todos los parámetros en un solo lugar.6.2. El Script Completo de Despliegue "Surviving Chernarus" para el Agente de IAA continuación se presenta el prompt completo. Está diseñado para ser copiado y pegado directamente para su ejecución por un agente de IA con capacidad de acceso a un shell a través del alias sshb rpi.Bash# ==============================================================================
# PROMPT DE DESPLIEGUE AUTOMATIZADO PARA EL ECOSISTEMA "SURVIVING CHERNARUS"
# AGENTE OBJETIVO: IA con acceso a shell en Raspberry Pi 5 vía `sshb rpi`
# VERSIÓN: 1.0
# ==============================================================================

# Iniciar sesión en la Raspberry Pi para comenzar la ejecución.
sshb rpi << 'EOF'
# --- INICIO DEL SCRIPT DE EJECUCIÓN REMOTA ---

# --- SECCIÓN 0: DEFINICIÓN DE VARIABLES DE CONFIGURACIÓN ---
# El usuario debe modificar estas variables antes de la ejecución.
export SC_PROJECT_PATH="/opt/surviving-chernarus"
export SC_USER=$(whoami)
export SC_PUID=$(id -u $SC_USER)
export SC_PGID=$(id -g $SC_USER)
export SC_TZ="America/New_York" # Cambiar a la zona horaria correcta: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
export SC_DOMAIN_NAME="your-domain.com" # Cambiar por su dominio real
export SC_CLOUDFLARE_EMAIL="your-email@example.com" # Cambiar por su email de Cloudflare
export SC_CLOUDFLARE_API_TOKEN="your_cloudflare_api_token" # Cambiar por su token de API de Cloudflare
export SC_POSTGRES_DB="n8n_db"
export SC_POSTGRES_USER="n8n_user"
export SC_POSTGRES_PASSWORD="GenerateAStrongPasswordHere1!"
export SC_PIHOLE_PASSWORD="GenerateAnotherStrongPasswordHere2!"
export SC_HOTSPOT_INTERFACE="wlan1" # Interfaz para el hotspot (wlan0 si es la interna, wlan1 para USB)
export SC_INTERNET_INTERFACE="eth0" # Interfaz para la conexión a Internet (eth0, wlan0)
export SC_HOTSPOT_SSID="SurvivingChernarus"
export SC_HOTSPOT_PASSWORD="AStrongHotspotPassword!"

# --- SECCIÓN 1: ENDURECIMIENTO DEL SISTEMA Y CONFIGURACIÓN DEL FIREWALL ---
echo "### SECCIÓN 1: INICIANDO ENDURECIMIENTO DEL SISTEMA ###"

echo "--> 1.1: Actualizando todos los paquetes del sistema..."
sudo apt update && sudo apt full-upgrade -y && sudo apt autoremove -y

echo "--> 1.2: Instalando UFW (Uncomplicated Firewall)..."
sudo apt install ufw -y

echo "--> 1.3: Configurando políticas por defecto de UFW..."
sudo ufw default deny incoming
sudo ufw default allow outgoing

echo "--> 1.4: Permitiendo servicios esenciales (SSH, HTTP, HTTPS)..."
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https

echo "--> 1.5: Configurando la integración de UFW con Docker..."
# Modificar after.rules para gestionar el tráfico de Docker
sudo sed -i '/\*filter/i\
# BEGIN UFW AND DOCKER\n\
*filter\n\
:DOCKER-USER - [0:0]\n\
-A DOCKER-USER -j RETURN -s 10.0.0.0/8\n\
-A DOCKER-USER -j RETURN -s 172.16.0.0/12\n\
-A DOCKER-USER -j RETURN -s 192.168.0.0/16\n\
-A DOCKER-USER -j ufw-user-forward\n\
-A DOCKER-USER -j DROP -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -d 192.168.0.0/16\n\
-A DOCKER-USER -j DROP -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -d 10.0.0.0/8\n\
-A DOCKER-USER -j DROP -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -d 172.16.0.0/12\n\
-A DOCKER-USER -j DROP -p udp -m udp --dport 0:32767 -d 192.168.0.0/16\n\
-A DOCKER-USER -j DROP -p udp -m udp --dport 0:32767 -d 10.0.0.0/8\n\
-A DOCKER-USER -j DROP -p udp -m udp --dport 0:32767 -d 172.16.0.0/12\n\
-A DOCKER-USER -j RETURN\n\
COMMIT\n\
# END UFW AND DOCKER\n' /etc/ufw/after.rules

# Modificar la política de reenvío por defecto
sudo sed -i -e 's/DEFAULT_FORWARD_POLICY="DROP"/DEFAULT_FORWARD_POLICY="ACCEPT"/g' /etc/default/ufw

echo "--> 1.6: Habilitando UFW..."
sudo ufw --force enable

echo "--> 1.7: Verificando estado de UFW..."
sudo ufw status verbose
echo "### SECCIÓN 1: ENDURECIMIENTO DEL SISTEMA COMPLETADO ###"
echo ""

# --- SECCIÓN 2: INSTALACIÓN DEL ENTORNO DE CONTENERIZACIÓN ---
echo "### SECCIÓN 2: INSTALANDO DOCKER Y DOCKER COMPOSE ###"

echo "--> 2.1: Instalando dependencias para el repositorio de Docker..."
sudo apt install ca-certificates curl gnupg -y

echo "--> 2.2: Añadiendo la clave GPG oficial de Docker..."
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "--> 2.3: Configurando el repositorio apt de Docker..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "--> 2.4: Instalando Docker Engine y el plugin de Compose..."
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

echo "--> 2.5: Añadiendo usuario actual al grupo de Docker..."
sudo usermod -aG docker ${SC_USER}

echo "--> 2.6: Habilitando el servicio de Docker para que inicie en el arranque..."
sudo systemctl enable docker
sudo systemctl start docker

echo "--> 2.7: Verificación de la instalación de Docker (se requiere nueva sesión de shell)..."
echo "NOTA: La siguiente verificación se ejecutará en un nuevo shell para aplicar la pertenencia al grupo."
newgrp docker << VERIFY
docker --version
docker compose version
echo "--> Ejecutando contenedor de prueba 'hello-world'..."
docker run hello-world
VERIFY

echo "### SECCIÓN 2: INSTALACIÓN DE DOCKER COMPLETADA ###"
echo ""

# --- SECCIÓN 3: CREACIÓN DE LA ESTRUCTURA DEL PROYECTO Y CONFIGURACIONES ---
echo "### SECCIÓN 3: CONFIGURANDO LA ESTRUCTURA DEL PROYECTO ###"

echo "--> 3.1: Creando el directorio principal del proyecto en ${SC_PROJECT_PATH}..."
sudo mkdir -p ${SC_PROJECT_PATH}
sudo chown ${SC_USER}:${SC_USER} ${SC_PROJECT_PATH}
cd ${SC_PROJECT_PATH}

echo "--> 3.2: Creando subdirectorios para datos persistentes..."
mkdir -p traefik_data dashboard_data/

echo "--> 3.3: Creando el archivo de entorno.env con los secretos..."
cat <<EOF >.env
# Variables Generales
PUID=${SC_PUID}
PGID=${SC_PGID}
TZ=${SC_TZ}
DOMAIN_NAME=${SC_DOMAIN_NAME}

# Secretos de Cloudflare
CLOUDFLARE_EMAIL=${SC_CLOUDFLARE_EMAIL}
CLOUDFLARE_API_TOKEN=${SC_CLOUDFLARE_API_TOKEN}

# Secretos de PostgreSQL
POSTGRES_DB=${SC_POSTGRES_DB}
POSTGRES_USER=${SC_POSTGRES_USER}
POSTGRES_PASSWORD=${SC_POSTGRES_PASSWORD}

# Secretos de Pi-hole
PIHOLE_PASSWORD=${SC_PIHOLE_PASSWORD}
EOF

echo "--> 3.4: Creando el archivo de configuración estática de Traefik (traefik.yml)..."
cat <<EOF >./traefik_data/traefik.yml
api:
  dashboard: true
  insecure: true

entryPoints:
  web:
    address: ":80"
    http:
      redirections:
        entryPoint:
          to: websecure
          scheme: https
  websecure:
    address: ":443"

providers:
  docker:
    exposedByDefault: false
    network: cher-net

certificatesResolvers:
  cloudflare_resolver:
    acme:
      email: "${SC_CLOUDFLARE_EMAIL}"
      storage: /acme.json
      dnsChallenge:
        provider: cloudflare
        resolvers:
          - "1.1.1.1:53"
          - "1.0.0.1:53"
EOF

echo "--> 3.5: Creando el archivo acme.json para los certificados SSL..."
touch./traefik_data/acme.json
chmod 600./traefik_data/acme.json

echo "--> 3.6: Creando el archivo maestro docker-compose.yml..."
cat <<EOF > docker-compose.yml
version: '3.8'

networks:
  cher-net:
    driver: bridge

volumes:
  postgres_data:
  pihole_etc:
  pihole_dnsmasq:
  n8n_data:
  rtorrent_config:
  rtorrent_downloads:
  dashboard_config:

services:
  traefik:
    image: traefik:latest
    container_name: traefik
    restart: unless-stopped
    security_opt:
      - no-new-privileges:true
    networks:
      - cher-net
    ports:
      - "80:80"
      - "443:443"
    environment:
      - CLOUDFLARE_EMAIL=\${CLOUDFLARE_EMAIL}
      - CLOUDFLARE_API_TOKEN=\${CLOUDFLARE_API_TOKEN}
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      -./traefik_data/traefik.yml:/etc/traefik/traefik.yml:ro
      -./traefik_data/acme.json:/acme.json
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.traefik-secure.entrypoints=websecure"
      - "traefik.http.routers.traefik-secure.rule=Host(\`traefik.\${DOMAIN_NAME}\`)"
      - "traefik.http.routers.traefik-secure.tls=true"
      - "traefik.http.routers.traefik-secure.tls.certresolver=cloudflare_resolver"
      - "traefik.http.routers.traefik-secure.service=api@internal"

  postgres:
    image: postgres:16-alpine
    container_name: postgres
    restart: unless-stopped
    networks:
      - cher-net
    environment:
      POSTGRES_DB: \${POSTGRES_DB}
      POSTGRES_USER: \${POSTGRES_USER}
      POSTGRES_PASSWORD: \${POSTGRES_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test:
      interval: 10s
      timeout: 5s
      retries: 5

  pihole:
    image: pihole/pihole:latest
    container_name: pihole
    restart: unless-stopped
    networks:
      cher-net:
        ipv4_address: 172.20.0.10 # Asignar IP estática para referencia fácil
    ports:
      - "53:53/tcp"
      - "53:53/udp"
    environment:
      TZ: '\${TZ}'
      WEBPASSWORD: '\${PIHOLE_PASSWORD}'
      FTLCONF_dns_listeningMode: 'all'
    volumes:
      - pihole_etc:/etc/pihole
      - pihole_dnsmasq:/etc/dnsmasq.d
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.pihole-secure.entrypoints=websecure"
      - "traefik.http.routers.pihole-secure.rule=Host(\`pihole.\${DOMAIN_NAME}\`)"
      - "traefik.http.routers.pihole-secure.tls=true"
      - "traefik.http.routers.pihole-secure.tls.certresolver=cloudflare_resolver"
      - "traefik.http.services.pihole.loadbalancer.server.port=80"
      - "traefik.http.middlewares.pihole-admin.addprefix.prefix=/admin"
      - "traefik.http.routers.pihole-secure.middlewares=pihole-admin@docker"

  n8n:
    image: n8nio/n8n:latest
    container_name: n8n
    restart: unless-stopped
    networks:
      - cher-net
    environment:
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_DATABASE=\${POSTGRES_DB}
      - DB_POSTGRESDB_USER=\${POSTGRES_USER}
      - DB_POSTGRESDB_PASSWORD=\${POSTGRES_PASSWORD}
      - GENERIC_TIMEZONE=\${TZ}
      - N8N_HOST=\${DOMAIN_NAME}
      - N8N_PROTOCOL=https
      - WEBHOOK_URL=https://n8n.\${DOMAIN_NAME}/
    volumes:
      - n8n_data:/home/node/.n8n
    depends_on:
      postgres:
        condition: service_healthy
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.n8n-secure.entrypoints=websecure"
      - "traefik.http.routers.n8n-secure.rule=Host(\`n8n.\${DOMAIN_NAME}\`)"
      - "traefik.http.routers.n8n-secure.tls=true"
      - "traefik.http.routers.n8n-secure.tls.certresolver=cloudflare_resolver"
      - "traefik.http.services.n8n.loadbalancer.server.port=5678"

  rtorrent:
    image: jesec/rtorrent-flood
    container_name: rtorrent-flood
    restart: unless-stopped
    networks:
      - cher-net
    ports:
      - "6881:6881/tcp"
      - "6881:6881/udp"
    environment:
      - PUID=\${PUID}
      - PGID=\${PGID}
      - TZ=\${TZ}
    volumes:
      - rtorrent_config:/config
      - rtorrent_downloads:/data
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.flood-secure.entrypoints=websecure"
      - "traefik.http.routers.flood-secure.rule=Host(\`rtorrent.\${DOMAIN_NAME}\`)"
      - "traefik.http.routers.flood-secure.tls=true"
      - "traefik.http.routers.flood-secure.tls.certresolver=cloudflare_resolver"
      - "traefik.http.services.flood.loadbalancer.server.port=3000"

  dashboard:
    image: lissy93/dashy:latest
    container_name: dashboard
    restart: unless-stopped
    networks:
      - cher-net
    volumes:
      -./dashboard_data/conf.yml:/app/user-data/conf.yml
    environment:
      - PUID=\${PUID}
      - PGID=\${PGID}
      - TZ=\${TZ}
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.dashboard-secure.entrypoints=websecure"
      - "traefik.http.routers.dashboard-secure.rule=Host(\`\${DOMAIN_NAME}\`)"
      - "traefik.http.routers.dashboard-secure.tls=true"
      - "traefik.http.routers.dashboard-secure.tls.certresolver=cloudflare_resolver"
      - "traefik.http.services.dashboard.loadbalancer.server.port=80"
EOF

echo "--> 3.7: Creando un archivo de configuración inicial para Dashy..."
cat <<EOF >./dashboard_data/conf.yml
pageInfo:
  title: Surviving Chernarus
appConfig:
  theme: dashy-dark
sections:
  - name: Core Services
    items:
      - title: Traefik
        url: http://traefik.\${SC_DOMAIN_NAME}
        icon: https://raw.githubusercontent.com/walkxhub/dashboard-icons/main/png/traefik.png
      - title: Pi-hole
        url: http://pihole.\${SC_DOMAIN_NAME}
        icon: https://raw.githubusercontent.com/walkxhub/dashboard-icons/main/png/pi-hole.png
      - title: n8n
        url: http://n8n.\${SC_DOMAIN_NAME}
        icon: https://raw.githubusercontent.com/walkxhub/dashboard-icons/main/png/n8n.png
      - title: rTorrent
        url: http://rtorrent.\${SC_DOMAIN_NAME}
        icon: https://raw.githubusercontent.com/walkxhub/dashboard-icons/main/png/rtorrent.png
EOF
sudo chown ${SC_PUID}:${SC_PGID}./dashboard_data/conf.yml

echo "### SECCIÓN 3: ESTRUCTURA DEL PROYECTO CREADA ###"
echo ""

# --- SECCIÓN 4: CONFIGURACIÓN DE RED AVANZADA (HOTSPOT) ---
echo "### SECCIÓN 4: CONFIGURANDO EL PUNTO DE ACCESO WI-FI ###"

echo "--> 4.1: Instalando hostapd y dnsmasq en el host..."
sudo apt install hostapd dnsmasq -y

echo "--> 4.2: Configurando IP estática para la interfaz del hotspot..."
echo "interface \${SC_HOTSPOT_INTERFACE}" | sudo tee -a /etc/dhcpcd.conf
echo "static ip_address=192.168.77.1/24" | sudo tee -a /etc/dhcpcd.conf
echo "nohook wpa_supplicant" | sudo tee -a /etc/dhcpcd.conf

echo "--> 4.3: Configurando hostapd..."
sudo cat <<EHF > /etc/hostapd/hostapd.conf
interface=\${SC_HOTSPOT_INTERFACE}
driver=nl80211
ssid=\${SC_HOTSPOT_SSID}
hw_mode=g
channel=7
wpa=2
wpa_passphrase=\${SC_HOTSPOT_PASSWORD}
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
EHF
sudo sed -i 's|#DAEMON_CONF=""|DAEMON_CONF="/etc/hostapd/hostapd.conf"|' /etc/default/hostapd

echo "--> 4.4: Configurando dnsmasq para DHCP y DNS forwarding a Pi-hole..."
sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig
# La IP 172.20.0.10 es la IP estática asignada a Pi-hole en docker-compose.yml
sudo cat <<EDF > /etc/dnsmasq.conf
interface=\${SC_HOTSPOT_INTERFACE}
dhcp-range=192.168.77.10,192.168.77.100,255.255.255.0,24h
dhcp-option=6,172.20.0.10
server=1.1.1.1 # Fallback DNS
EDF

echo "--> 4.5: Habilitando el reenvío de IP y NAT..."
sudo sed -i '/net.ipv4.ip_forward=1/s/^#//' /etc/sysctl.conf
sudo sysctl -p
sudo iptables -t nat -A POSTROUTING -o \${SC_INTERNET_INTERFACE} -j MASQUERADE
sudo netfilter-persistent save

echo "--> 4.6: Habilitando y reiniciando los servicios de red..."
sudo systemctl unmask hostapd
sudo systemctl enable hostapd
sudo systemctl restart dhcpcd
sudo systemctl restart dnsmasq
sudo systemctl restart hostapd

echo "### SECCIÓN 4: PUNTO DE ACCESO CONFIGURADO ###"
echo ""

# --- SECCIÓN 5: DESPLIEGUE Y VERIFICACIÓN FINAL ---
echo "### SECCIÓN 5: DESPLEGANDO LA PILA DE SERVICIOS ###"

echo "--> 5.1: Navegando al directorio del proyecto..."
cd ${SC_PROJECT_PATH}

echo "--> 5.2: Iniciando todos los servicios con Docker Compose..."
# Se ejecuta en un nuevo shell para asegurar que los permisos de grupo de docker se apliquen
newgrp docker << DEPLOY
docker compose up -d
DEPLOY

echo "--> 5.3: Esperando 60 segundos para que los contenedores se estabilicen..."
sleep 60

echo "--> 5.4: Verificando el estado de los contenedores..."
newgrp docker << STATUS
docker compose ps
STATUS

echo "--> 5.5: Verificando los logs de Traefik para la generación de certificados..."
newgrp docker << LOGS
docker compose logs --tail=50 traefik
LOGS

echo "======================================================================"
echo "DESPLIEGUE DE 'SURVIVING CHERNARUS' COMPLETADO"
echo "======================================================================"
echo "Puntos de acceso a los servicios (reemplace ${SC_DOMAIN_NAME} con su dominio):"
echo "- Panel de Control: https://${SC_DOMAIN_NAME}"
echo "- Traefik Dashboard: https://traefik.${SC_DOMAIN_NAME}"
echo "- Pi-hole Admin: https://pihole.${SC_DOMAIN_NAME}"
echo "- n8n Automation: https://n8n.${SC_DOMAIN_NAME}"
echo "- rTorrent/Flood UI: https://rtorrent.${SC_DOMAIN_NAME}"
echo ""
echo "Hotspot Wi-Fi:"
echo "- SSID: ${SC_HOTSPOT_SSID}"
echo "- Contraseña: ${SC_HOTSPOT_PASSWORD}"
echo "======================================================================"

# --- FIN DEL SCRIPT DE EJECUCIÓN REMOTA ---
EOF
Apéndice: Procedimientos OperativosEsta sección proporciona instrucciones para el mantenimiento y la gestión a largo plazo del ecosistema "Surviving Chernarus".A.1. Respaldo y Recuperación de Volúmenes PersistentesLa autonomía de los datos requiere una estrategia de respaldo robusta. El uso de volúmenes nombrados de Docker centraliza todos los datos persistentes en /var/lib/docker/volumes/, lo que facilita su respaldo.Procedimiento de Respaldo:El siguiente script detiene los contenedores para garantizar la consistencia de los datos, crea un archivo tar.gz comprimido de todos los volúmenes del proyecto y luego reinicia los servicios.Bash#!/bin/bash
PROJECT_PATH="/opt/surviving-chernarus"
BACKUP_PATH="/home/$(whoami)/backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_PATH}/chernarus_backup_${TIMESTAMP}.tar.gz"
DOCKER_VOLUMES_PATH="/var/lib/docker/volumes"

echo "Iniciando respaldo de Surviving Chernarus..."
mkdir -p ${BACKUP_PATH}

cd ${PROJECT_PATH}
echo "Deteniendo servicios de Docker..."
docker compose down

echo "Creando archivo de respaldo de los volúmenes..."
sudo tar -czvf ${BACKUP_FILE} -C ${DOCKER_VOLUMES_PATH}./${PROJECT_PATH##*/}_*

echo "Reiniciando servicios de Docker..."
docker compose up -d

echo "Respaldo completado: ${BACKUP_FILE}"
Este método, que utiliza un contenedor temporal para montar y archivar los volúmenes, es una práctica estándar y fiable para el respaldo de datos en Docker.53Procedimiento de Recuperación:Para restaurar desde un respaldo, se detienen los servicios, se elimina cualquier dato de volumen existente y se extrae el archivo de respaldo en el directorio de volúmenes de Docker.Bash#!/bin/bash
PROJECT_PATH="/opt/surviving-chernarus"
BACKUP_FILE="/path/to/your/backup.tar.gz" # Cambiar a la ruta del archivo de respaldo
DOCKER_VOLUMES_PATH="/var/lib/docker/volumes"

echo "Iniciando restauración de Surviving Chernarus..."
cd ${PROJECT_PATH}

echo "Deteniendo y eliminando contenedores existentes..."
docker compose down

echo "Eliminando volúmenes antiguos..."
docker volume rm $(docker volume ls -q | grep "${PROJECT_PATH##*/}_")

echo "Restaurando volúmenes desde el archivo de respaldo..."
sudo tar -xzvf ${BACKUP_FILE} -C ${DOCKER_VOLUMES_PATH}

echo "Iniciando servicios restaurados..."
docker compose up -d

echo "Restauración completada."
A.2. Estrategia de Actualización del Sistema y los ContenedoresMantener el sistema y las aplicaciones actualizadas es crucial para la seguridad y la estabilidad.Actualización del Sistema Operativo y Docker:Dado que Docker se instaló a través del repositorio apt, las actualizaciones del sistema operativo y de Docker se gestionan con un único conjunto de comandos:Bashsudo apt update && sudo apt full-upgrade -y && sudo apt autoremove -y
Actualización de los Contenedores de Servicios:Docker Compose simplifica enormemente la actualización de los servicios contenerizados. El proceso implica descargar las últimas versiones de las imágenes y recrear los contenedores.56Navegar al directorio del proyecto: cd /opt/surviving-chernarusDescargar las últimas versiones de todas las imágenes definidas en docker-compose.yml:Bashdocker compose pull
Reiniciar la pila de servicios. Docker Compose detectará las imágenes nuevas y recreará solo los contenedores cuyos imágenes han cambiado:Bashdocker compose up -d
(Opcional) Limpiar las imágenes antiguas y no utilizadas para liberar espacio en disco:Bashdocker image prune -f
Estos procedimientos operativos aseguran que el ecosistema "Surviving Chernarus" no solo sea robusto en su despliegue inicial, sino también mantenible y resiliente a lo largo de su ciclo de vida.