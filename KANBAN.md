# Tablero Kanban del Proyecto "Surviving Chernarus"

Este tablero sigue la metodología Kanban para visualizar el flujo de trabajo y el estado actual del proyecto.

---

###  colonne: Backlog ➔ To Do ➔ In Progress ➔ Done

---

### 📥 Backlog

*   **Observabilidad:** Configurar pila de monitoreo (Prometheus, Grafana).
*   **Servicio de Red:** Desplegar `Berezino_Checkpoint` (Squid Proxy con SSL Bumping).
*   **Observabilidad:** Configurar recolección centralizada de logs (Vector/Fluentd).
*   **Interfaz:** Crear layouts de `Stalker's Hideout` (Tmux).

---

### 📝 To Do

*   `Fase 6: Crear y desplegar workflow de n8n.`
*   `Fase 6: Guiar en la configuración de credenciales y activación.`

---

### ⚙️ In Progress

*   `Fase 6: Configurar entorno de n8n para Gemini.`

---

### ✅ Done

*   **Planificación:** Planificar y documentar la Fase 6.
*   **Fase 5: Integración de CI/CD y Despliegue Automatizado**
    *   Configurar repositorio Git y flujo de CI/CD con GitHub Actions.
    *   Implementar runner auto-alojado en la Raspberry Pi.
    *   Configurar sistema de DNS Dinámico (DDNS) para el runner.
*   **Fase 4: Activación del Perímetro Defensivo**
    *   Configurar Hotspot Wi-Fi (hostapd, dnsmasq).
    *   Habilitar Enrutamiento y NAT con iptables.
*   **Fase 3: Control de la Red**
    *   Desplegar `StarySobor_RadioPost` (Pi-hole).
*   **Fase 2: El Centro de Mando**
    *   Crear `docker-compose.yml` para la pila de servicios principal.
*   **Fase 1: Configuración del Anfitrión**
    *   Preparación del sistema, red, almacenamiento y Docker.
*   **Fase 0: Planificación y Documentación**
    *   Crear `README.md` y documentos de planificación.
    *   Implementar tablero Kanban.
