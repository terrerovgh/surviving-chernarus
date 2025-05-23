# Wiki del Proyecto "Chernarus Beacon" (antes Escrowed Kathy)

¡Bienvenido/a a la wiki del proyecto "Chernarus Beacon"!

Este proyecto tiene como objetivo configurar una Raspberry Pi 5 como un hotspot Wi-Fi avanzado y seguro. Incluye funcionalidades como un portal cautivo para la distribución de certificados, un proxy Squid para filtrado de contenido e inspección SSL, y Pi-hole para bloqueo de anuncios y DNS.

Esta wiki proporciona una guía detallada para la configuración, despliegue y mantenimiento de todos los componentes del proyecto.

## Secciones Principales de la Wiki

*   **[[01-Introduccion]]**: Visión general del proyecto, objetivos y arquitectura.
*   **[[02-Preparar-Raspberry-Pi-5]]**: Pasos iniciales para preparar tu Raspberry Pi 5.
*   **[[03-Instalar-Arch-Linux]]**: Guía para instalar Arch Linux en la Raspberry Pi 5.
*   **[[04-Configuracion-Red-Basica]]**: Configuración de la conectividad de red básica de la Raspberry Pi.
*   **[[05-Instalacion-Dependencias-Proyecto]]**: Instalación de software esencial como Git, Docker y Docker Compose.
*   **[[06-Configurar-Hotspot]]**: Configuración del punto de acceso Wi-Fi (`hostapd`) y el servidor DHCP.
*   **[[07-Configurar-Portal-Cautivo]]**: Despliegue del portal cautivo (`Chernarus_Entrypoint` con Nginx).
*   **[[08-Configurar-Squid-Proxy]]**: Despliegue del proxy Squid (`Berezino_Checkpoint`).
*   **[[09-Configurar-Redireccion-Trafico]]**: Configuración de `iptables` para NAT y redirección de tráfico al portal y al proxy.
*   **[[10-Arranque-y-Pruebas]]**: Guía para iniciar todos los servicios y realizar pruebas de funcionamiento.
*   **[[11-Solucion-Problemas]]**: Consejos para diagnosticar y solucionar problemas comunes.
*   **[[12-Configuracion-Runner-Autoalojado]]**: (Si aplica) Configuración de un runner auto-alojado de GitHub Actions en la Raspberry Pi.
*   **[[13-GitHub-CLI-Autenticacion]]**: (Si aplica) Autenticación de la CLI de GitHub en la Raspberry Pi.
*   **[[14-Gestion-Secretos]]**: Gestión de contraseñas, tokens y otros secretos del proyecto. **¡Lectura obligatoria!**
*   **[[CI-CD-Guia-Hugo-RPi]]**: (Si aplica) Guía para CI/CD usando Hugo en la Raspberry Pi.

## Documentación Adicional Importante

Asegúrate de revisar también los siguientes documentos en el repositorio principal:

*   **`README.md`**: Instrucciones principales de inicio rápido y resumen del proyecto.
*   **`SECURITY.md`**: **Guía de Mejores Prácticas de Seguridad. ¡Lectura obligatoria!**
*   `GUIDANCE_AND_EXPLANATIONS.md`: Explicaciones detalladas sobre decisiones de diseño y configuraciones.
*   `squid_Berezino_Checkpoint/README_SQUID.md`: Detalles específicos sobre la configuración avanzada de Squid y la gestión de certificados CA.
*   `captive_portal_Chernarus_Entrypoint/README_PORTAL.md`: Detalles sobre la configuración y personalización del portal cautivo.

---
Utiliza el sidebar (menú lateral) para navegar fácilmente entre las páginas de esta wiki.
