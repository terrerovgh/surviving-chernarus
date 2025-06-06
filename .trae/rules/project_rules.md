# Project Rules for Trae AI IDE: Surviving Chernarus

## I. Project Vision & Thematic Core:

1.  **Core Concept:** "Surviving Chernarus" is a personal life methodology and integrated digital ecosystem. It functions as a second brain, AI personal coach/assistant (Jarvis-style), and a "Life RPG" for Operator Terrerov.
2.  **Key Principles:** Contextual Awareness, Extreme Gamification, Intelligent Automation, Holistic Optimization, Constant Adaptation, Thematic Immersion.
3.  **Thematic Language:**
    * Consistently use "Surviving Chernarus" lore and terminology (e.g., "Beacon", "Colectivo", "Operador", "misión", "suministros", "puesto avanzado", "yermo", "protocolo").
    * AI-generated content (code comments, documentation, commit messages, Radio Chernarus scripts) should reflect this theme.

## II. Technical Stack & Architecture:

1.  **Primary Hosts:**
    * `rpi` (Raspberry Pi 5, `192.168.0.2`): K3s Master, lightweight services, n8n orchestration, `hostapd`, `iptables`, Bluetooth audio output for Radio Chernarus.
    * `lenlab` (Laptop Lenovo, `192.168.0.3`): K3s Worker, heavier services (PostgreSQL, IA models, rtorrent, complex n8n nodes, K8s workloads).
2.  **Core Technologies:**
    * **Orchestration:** Kubernetes (K3s). Manifiestos in `kubernetes/`.
    * **Automatization:** n8n. Flows exported to `n8n_flows/`.
    * **Database:** PostgreSQL with PostGIS (on `lenlab` via K8s) for contextual data, gamification, maps.
    * **Web Interface/Dashboard:** Hugo (`radio.terrerov.com`, deployed via GitHub Actions from `hugo_site/`) and `sch` TUI (Textual).
    * **Radio:** Icecast/Liquidsoap (K8s), n8n for content, IA for DJ persona/scripts, NotebookLM for podcast research.
    * **Personal Assistance:** Integration with Google Suite (Calendar, Tasks, Gmail, Drive, Docs) via n8n.
    * **Security:** HashiCorp Vault (future) or K8s Secrets, mTLS with custom CAs, NIDS (future), `Guardián del Perímetro` module.
    * **Networking (RPi):** `hostapd`, `iptables`/`nftables`, Pi-hole (K8s), Squid (K8s on `lenlab`).
    * **IoT Integration:** Alexa (via n8n and custom API interaction).
3.  **AI Integration:**
    * Utilize AI (GPT, Claude, local models on `lenlab` via K8s) for:
        * Contextual understanding and task planning (n8n).
        * Content generation (Radio Chernarus, podcasts, thematic descriptions).
        * Log analysis and security alerts.
        * Code assistance, debugging, and documentation (Trae AI).
    * Prompts should be designed to elicit thematic and contextually relevant responses.

## III. AI-Assisted Development Guidelines (Trae AI):

1.  **Contextual Prompts:**
    * When requesting code or solutions, always provide relevant context using `#File`, `#Folder`, `#Workspace`, or by selecting code.
    * Mention the target host (`rpi` or `lenlab`) if relevant for resource constraints or specific configurations.
    * Refer to existing modules or `project_rules.md` if applicable (e.g., "Generate a K8s manifest for a new service, following the structure in `kubernetes/apps/` and our `project_rules.md` for PostgreSQL access via K8s Secrets").
2.  **Code Generation for "Surviving Chernarus":**
    * **Python (n8n custom nodes, scripts):** Follow PEP 8. Include thematic comments. Ensure error handling.
    * **Kubernetes Manifests (YAML):** Generate clean, well-commented manifests. Prioritize security best practices (e.g., least privilege, resource limits). Use K8s Secrets for sensitive data.
    * **Hugo (HTML, JS, CSS, Markdown):** Generate responsive and accessible frontend code. Markdown content should be easily parsable by Hugo and thematically rich.
    * **n8n Flows (Conceptual/JSON):** If asked to design an n8n flow, describe the nodes, connections, and logic. If possible, generate the JSON structure (understanding this is complex for AI).
3.  **Gamification Logic:**
    * When generating code or logic related to gamification (Puntos de Supervivencia, XP, misiones, recompensas), ensure it interacts correctly with the PostgreSQL database schema (to be defined).
    * Suggestions for new gamification mechanics should be thematically consistent.
4.  **Security Module (`Guardián del Perímetro`):**
    * When generating scripts or n8n flows for security monitoring, log analysis, or vulnerability scanning:
        * Prioritize accuracy and minimize false positives.
        * Suggest secure ways to handle alerts and potential remediation actions.
        * Refer to the project's `SECURITY.md` and `14-Gestion-Secretos.md`.

## IV. Documentation & Knowledge Management:

1.  **Wiki:** The GitHub Wiki is the primary source of detailed documentation. AI can assist in drafting or summarizing sections for the wiki.
2.  **Code Comments:** All non-trivial code should be commented. Thematic comments are encouraged.
3.  **Commit Messages:** Should be descriptive and can be thematic.
4.  **NotebookLM:** Used for podcast research and deep knowledge exploration. AI can help summarize NotebookLM outputs for other uses.

*This project is a personal journey of learning and extreme-customization. AI assistance should empower this journey, respecting the project's unique vision and technical landscape.*