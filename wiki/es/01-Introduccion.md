# Introducción al Proyecto Escrowed Kathy

## ¿Qué es Escrowed Kathy?
Escrowed Kathy es un sistema diseñado para implementar un punto de acceso Wi-Fi con portal cautivo y análisis/filtrado de tráfico mediante un proxy. El objetivo principal es crear una red controlada donde los usuarios deben interactuar con un portal antes de obtener acceso completo a Internet, permitiendo además la gestión y monitorización del tráfico. Utiliza componentes como `hostapd` para la creación del hotspot, un servidor web para servir el portal cautivo, y `Squid` para la funcionalidad de proxy.

## Propósito de esta Wiki
Esta wiki proporciona una guía detallada paso a paso para instalar, configurar y poner en marcha el proyecto Escrowed Kathy en una Raspberry Pi 5 utilizando el sistema operativo Arch Linux. Cada sección está diseñada para llevarte a través de los componentes necesarios del proyecto.

## Requisitos
*   **Hardware:** Raspberry Pi 5
*   **Sistema Operativo:** Arch Linux ARM

## ¿Qué lograrás con esta guía?
Al finalizar esta guía, tendrás un sistema Escrowed Kathy completamente funcional en tu Raspberry Pi 5. Este sistema será capaz de:
*   Ofrecer un hotspot Wi-Fi personalizado.
*   Redirigir a los usuarios conectados a un portal cautivo para autenticación o visualización de términos y condiciones.
*   Gestionar y filtrar el tráfico de red de los usuarios conectados a través de un servidor proxy.
*   Proporcionar una base para futuras personalizaciones y extensiones del proyecto.
