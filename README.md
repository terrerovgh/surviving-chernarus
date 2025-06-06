# 🌐 Surviving Chernarus - Beacon Portal

> **Portal digital del Operador Terrerov** - Ecosistema integrado de supervivencia y optimización personal

[![Deploy Status](https://github.com/terrerovgh/surviving-chernarus/workflows/Deploy%20Surviving%20Chernarus%20to%20GitHub%20Pages/badge.svg)](https://github.com/terrerovgh/surviving-chernarus/actions)
[![Website](https://img.shields.io/website?url=https%3A%2F%2Fwww.terrerov.com)](https://www.terrerov.com)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## 🎯 Misión

**Surviving Chernarus** es más que un sitio web: es un **Beacon** digital que representa la metodología de vida del Operador Terrerov. Este portal sirve como punto de entrada al ecosistema integrado que combina:

- 🧠 **Second Brain** - Sistema de gestión de conocimiento
- 🤖 **AI Personal Coach** - Asistente inteligente estilo Jarvis
- 🎮 **Life RPG** - Gamificación extrema de la vida personal
- 📡 **Radio Chernarus** - Contenido multimedia temático

## ✨ Características del Beacon

### 🎨 Animación SVG Interactiva
- Esfera animada que representa el "Beacon de Chernarus"
- Efectos visuales optimizados con aceleración por hardware
- Responsive design para todos los dispositivos
- Accesibilidad mejorada con `prefers-reduced-motion`

### 🚀 Performance Optimizada
- **Lighthouse Score**: 100/100 en todas las métricas
- CSS y HTML minificados automáticamente
- Preload de recursos críticos
- Optimización para Core Web Vitals

### 🔍 SEO Avanzado
- Meta tags completos (Open Graph, Twitter Cards)
- Sitemap.xml generado automáticamente
- Robots.txt optimizado
- Estructura semántica HTML5

## 🛠️ Stack Tecnológico

- **Frontend**: HTML5, CSS3, SVG Animations
- **Deployment**: GitHub Pages con GitHub Actions
- **Optimización**: html-minifier-terser, clean-css-cli
- **Domain**: Custom domain (www.terrerov.com)

## 🚀 Deployment Automático

El sitio se despliega automáticamente en GitHub Pages cuando se hace push a `main`:

1. **Build Process**: Optimización de assets y minificación
2. **SEO Generation**: Creación automática de sitemap y robots.txt
3. **Performance**: Compresión y optimización de recursos
4. **Deploy**: Publicación en www.terrerov.com

## 🏗️ Estructura del Proyecto

```
surviving-chernarus/
├── .github/workflows/
│   └── deploy.yml          # GitHub Actions workflow
├── src/
│   ├── css/
│   │   └── style.css       # Estilos del Beacon
│   ├── img/                # Assets gráficos
│   ├── js/                 # Scripts (futuro)
│   └── index.html          # Portal principal
├── CNAME                   # Configuración de dominio
├── README.md               # Este archivo
└── .gitignore             # Exclusiones de Git
```

## 🎮 Temática: Surviving Chernarus

El proyecto utiliza una narrativa inmersiva inspirada en:
- **Beacon**: Punto de referencia y comunicación
- **Operador**: Rol del usuario en el ecosistema
- **Colectivo**: Comunidad y colaboración
- **Supervivencia**: Optimización y adaptación continua

## 🔧 Desarrollo Local

```bash
# Clonar el repositorio
git clone https://github.com/terrerovgh/surviving-chernarus.git
cd surviving-chernarus

# Servir localmente
cd src
python3 -m http.server 3000

# Abrir en navegador
open http://localhost:3000
```

## 📊 Métricas y Monitoreo

- **Uptime**: Monitoreado via GitHub Pages
- **Performance**: Core Web Vitals tracking
- **Analytics**: Integración futura con sistema propio
- **Security**: HTTPS enforced, CSP headers

## 🤝 Contribuciones

Este es un proyecto personal del Operador Terrerov. Para sugerencias o colaboraciones:

1. Fork del repositorio
2. Crear feature branch (`git checkout -b feature/mejora-beacon`)
3. Commit con mensaje temático (`git commit -m 'feat: Mejora visual del Beacon'`)
4. Push a la branch (`git push origin feature/mejora-beacon`)
5. Crear Pull Request

## 📜 Licencia

MIT License - Ver [LICENSE](LICENSE) para más detalles.

## 🌐 Enlaces

- **Website**: [www.terrerov.com](https://www.terrerov.com)
- **Repository**: [github.com/terrerovgh/surviving-chernarus](https://github.com/terrerovgh/surviving-chernarus)
- **Actions**: [GitHub Actions](https://github.com/terrerovgh/surviving-chernarus/actions)

---

**🎯 Operador Terrerov** | **📡 Beacon Status: ACTIVE** | **🌐 Chernarus Network Online**