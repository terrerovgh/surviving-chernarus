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

*   `Fase 5: Crear script de backup.`
*   `Fase 5: Crear y configurar workflow de n8n.`

---

### ⚙️ In Progress

*   `Fase 5: Instalar y configurar rclone.`

---

### ✅ Done

*   **Planificación:** Planificar y documentar la Fase 5.
*   **Fase 4: Activación del Perímetro Defensivo**
    *   Configurar Hotspot Wi-Fi (hostapd, dnsmasq).
    *   Habilitar Enrutamiento y NAT con iptables.
*   **Fase 3: Control de la Red**
    *   Desplegar `StarySobor_RadioPost` (Pi-hole).
*   **Fase 2: El Centro de Mando**
    *   Crear `docker-compose.yml` para la pila de servicios principal.
    *   Crear archivo `.env` y `.gitignore`.
    *   Crear estructura de configuración para `CoastalHighway_Router` (Traefik).
    *   Desplegar y verificar la pila de servicios.
*   **Fase 1: Configuración del Anfitrión**
    *   Actualizar y asegurar el sistema anfitrión.
    *   Instalar herramientas esenciales.
    *   Configurar red estática y SSH seguro.
    *   Configurar disco duro externo para almacenamiento persistente.
    *   Instalar y configurar Docker.
    *   Configurar firewall `ufw`.
*   **Fase 0: Planificación y Documentación**
    *   Crear `README.md` y documentos de planificación.
    *   Implementar tablero Kanban.