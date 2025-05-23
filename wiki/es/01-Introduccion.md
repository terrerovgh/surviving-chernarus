# Introducción al Proyecto "Chernarus Beacon"

## ¿Qué es "Chernarus Beacon"?
"Chernarus Beacon" (anteriormente conocido como Escrowed Kathy) es un sistema diseñado para implementar un punto de acceso Wi-Fi avanzado y seguro en una Raspberry Pi 5. Incluye funcionalidades como un portal cautivo para la distribución de certificados, un proxy Squid para filtrado de contenido e inspección SSL, Pi-hole para bloqueo de anuncios y DNS, y un servidor DHCP dedicado. El objetivo principal es crear una red controlada donde los usuarios interactúan con un portal antes de obtener acceso completo a Internet, permitiendo además la gestión y monitorización del tráfico.

## Propósito de esta Wiki
Esta wiki proporciona una guía detallada paso a paso para instalar, configurar y poner en marcha el proyecto "Chernarus Beacon" en una Raspberry Pi 5 utilizando el sistema operativo Arch Linux. Cada sección está diseñada para llevarte a través de los componentes necesarios del proyecto.

**Es fundamental leer las guías de seguridad:**
*   Consulta la página `[[14-Gestion-Secretos]]` para la gestión de contraseñas y tokens.
*   Revisa el archivo `SECURITY.md` en la raíz del repositorio para conocer las mejores prácticas de seguridad del proyecto.

## Requisitos
*   **Hardware:** Raspberry Pi 5
*   **Sistema Operativo:** Arch Linux ARM

## ¿Qué lograrás con esta guía?
Al finalizar esta guía, tendrás un sistema "Chernarus Beacon" completamente funcional en tu Raspberry Pi 5. Este sistema será capaz de:
*   Ofrecer un hotspot Wi-Fi personalizado (`rpi` SSID).
*   Redirigir a los usuarios conectados a un portal cautivo (`Chernarus_Entrypoint`) para la aceptación de términos y la descarga del certificado CA.
*   Filtrar y cachear el tráfico web a través de un proxy Squid (`Berezino_Checkpoint`) con capacidad de inspección SSL.
*   Bloquear anuncios y rastreadores a nivel de DNS con Pi-hole (`Pihole_DNS_Filter`).
*   Asignar direcciones IP de forma dinámica mediante un servidor DHCP dedicado (`Hotspot_DHCP_Server`).
*   Proporcionar una base para futuras personalizaciones y extensiones del proyecto.
