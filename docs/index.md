---
layout: default
title: Inicio
---

# Surviving Chernarus Wiki

Bienvenido a la documentación oficial del proyecto **Surviving Chernarus**, un ecosistema de servicios auto-hospedados diseñado para proporcionar herramientas digitales esenciales en entornos con conectividad limitada o intermitente.

<div class="search-container">
  <form action="{{ site.baseurl }}/search" method="get">
    <input type="text" id="search-box" name="q" placeholder="Buscar en la documentación...">
    <button type="submit">Buscar</button>
  </form>
</div>

## ¿Qué es Surviving Chernarus?

Surviving Chernarus es un proyecto que combina hardware y software para crear un sistema resiliente de servicios digitales que pueden funcionar en condiciones adversas. Inspirado en el videojuego DayZ (ambientado en la ficticia región post-soviética de Chernarus), este proyecto está diseñado para:

- Proporcionar servicios esenciales cuando la infraestructura convencional no está disponible
- Funcionar con recursos limitados (como una Raspberry Pi)
- Adaptarse a diferentes escenarios de conectividad
- Ser fácil de desplegar y mantener

## Componentes Principales

El ecosistema incluye los siguientes servicios:

<div class="card-container">
  <div class="card">
    <div class="card-icon">🌐</div>
    <div class="card-content">
      <h3>Traefik</h3>
      <p>Proxy inverso y balanceador de carga que gestiona el acceso a todos los servicios.</p>
    </div>
  </div>
  
  <div class="card">
    <div class="card-icon">🛡️</div>
    <div class="card-content">
      <h3>Pi-hole</h3>
      <p>Bloqueador de anuncios a nivel de red y servidor DNS local.</p>
    </div>
  </div>
  
  <div class="card">
    <div class="card-icon">⚙️</div>
    <div class="card-content">
      <h3>n8n</h3>
      <p>Plataforma de automatización para crear flujos de trabajo personalizados.</p>
    </div>
  </div>
  
  <div class="card">
    <div class="card-icon">🗃️</div>
    <div class="card-content">
      <h3>PostgreSQL</h3>
      <p>Sistema de gestión de bases de datos relacional.</p>
    </div>
  </div>
  
  <div class="card">
    <div class="card-icon">📥</div>
    <div class="card-content">
      <h3>rTorrent</h3>
      <p>Cliente BitTorrent para compartir y descargar archivos.</p>
    </div>
  </div>
  
  <div class="card">
    <div class="card-icon">📶</div>
    <div class="card-content">
      <h3>Punto de Acceso Wi-Fi</h3>
      <p>Crea una red local para conectar dispositivos al sistema.</p>
    </div>
  </div>
</div>

## Casos de Uso

Surviving Chernarus es ideal para:

- **Viajeros y nómadas digitales**: Mantén tus servicios esenciales mientras te desplazas.
- **Áreas con infraestructura limitada**: Proporciona servicios digitales en zonas rurales o remotas.
- **Preparación para emergencias**: Ten un sistema de respaldo listo para situaciones donde la infraestructura convencional falla.
- **Entusiastas de la privacidad**: Controla tus propios datos y servicios sin depender de proveedores externos.
- **Proyectos educativos**: Aprende sobre sistemas Linux, Docker, redes y servicios auto-hospedados.

## Comenzando

Para empezar con Surviving Chernarus, sigue nuestra [guía de instalación]({{ site.baseurl }}/installation) que te guiará a través del proceso de configuración del hardware y software necesarios.

## Explorar la Documentación

<div class="navigation-grid">
  <a href="{{ site.baseurl }}/installation" class="nav-item">
    <div class="nav-icon">📥</div>
    <div class="nav-title">Instalación</div>
  </a>
  
  <a href="{{ site.baseurl }}/configuration" class="nav-item">
    <div class="nav-icon">⚙️</div>
    <div class="nav-title">Configuración</div>
  </a>
  
  <a href="{{ site.baseurl }}/daily-usage" class="nav-item">
    <div class="nav-icon">📱</div>
    <div class="nav-title">Uso Diario</div>
  </a>
  
  <a href="{{ site.baseurl }}/maintenance" class="nav-item">
    <div class="nav-icon">🔧</div>
    <div class="nav-title">Mantenimiento</div>
  </a>
  
  <a href="{{ site.baseurl }}/troubleshooting" class="nav-item">
    <div class="nav-icon">🔍</div>
    <div class="nav-title">Solución de Problemas</div>
  </a>
  
  <a href="{{ site.baseurl }}/advanced-usage" class="nav-item">
    <div class="nav-icon">🚀</div>
    <div class="nav-title">Uso Avanzado</div>
  </a>
  
  <a href="{{ site.baseurl }}/reference" class="nav-item">
    <div class="nav-icon">📚</div>
    <div class="nav-title">Referencia</div>
  </a>
  
  <a href="{{ site.baseurl }}/contributing" class="nav-item">
    <div class="nav-icon">👥</div>
    <div class="nav-title">Contribuir</div>
  </a>
</div>

<style>
  .search-container {
    margin: 2rem 0;
    text-align: center;
  }
  
  .search-container input {
    padding: 10px;
    width: 60%;
    border: 1px solid #ddd;
    border-radius: 4px 0 0 4px;
    font-size: 16px;
  }
  
  .search-container button {
    padding: 10px 15px;
    background: #157878;
    color: white;
    border: none;
    border-radius: 0 4px 4px 0;
    cursor: pointer;
    font-size: 16px;
  }
  
  .search-container button:hover {
    background: #106868;
  }
  
  .card-container {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
    gap: 20px;
    margin: 2rem 0;
  }
  
  .card {
    background: #fff;
    border-radius: 8px;
    box-shadow: 0 2px 10px rgba(0,0,0,0.1);
    overflow: hidden;
    transition: transform 0.3s ease, box-shadow 0.3s ease;
    display: flex;
    flex-direction: column;
  }
  
  .card:hover {
    transform: translateY(-5px);
    box-shadow: 0 5px 15px rgba(0,0,0,0.15);
  }
  
  .card-icon {
    font-size: 2.5rem;
    padding: 1rem;
    text-align: center;
    background: #f8f9fa;
  }
  
  .card-content {
    padding: 1rem;
  }
  
  .card-content h3 {
    margin-top: 0;
    color: #157878;
  }
  
  .navigation-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(150px, 1fr));
    gap: 15px;
    margin: 2rem 0;
  }
  
  .nav-item {
    display: flex;
    flex-direction: column;
    align-items: center;
    padding: 1rem;
    background: #f8f9fa;
    border-radius: 8px;
    text-decoration: none;
    color: #333;
    transition: transform 0.2s ease, background-color 0.2s ease;
  }
  
  .nav-item:hover {
    background: #e9ecef;
    transform: translateY(-3px);
  }
  
  .nav-icon {
    font-size: 2rem;
    margin-bottom: 0.5rem;
  }
  
  .nav-title {
    font-weight: bold;
    text-align: center;
  }
  
  @media (max-width: 768px) {
    .card-container {
      grid-template-columns: 1fr;
    }
    
    .navigation-grid {
      grid-template-columns: repeat(2, 1fr);
    }
    
    .search-container input {
      width: 70%;
    }
  }
</style>