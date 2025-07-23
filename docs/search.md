---
layout: default
title: Búsqueda
---

# Resultados de Búsqueda

<div class="search-results">
  <p id="search-query-display">Buscando: <strong id="search-query"></strong></p>
  <div id="search-results-container">
    <p class="search-status">Buscando resultados para "<span id="search-query-text"></span>"...</p>
    <div id="search-results" class="search-results-list"></div>
  </div>
</div>

<script>
  document.addEventListener('DOMContentLoaded', function() {
    // Obtener la consulta de búsqueda de la URL
    const urlParams = new URLSearchParams(window.location.search);
    const query = urlParams.get('q');
    
    // Mostrar la consulta
    document.getElementById('search-query').textContent = query || 'No se especificó consulta';
    document.getElementById('search-query-text').textContent = query || 'No se especificó consulta';
    
    // Actualizar el título de la página con la consulta
    document.title = `Búsqueda: ${query || 'consulta vacía'} - Surviving Chernarus`;
    
    if (!query || query.length < 2) {
      document.getElementById('search-results-container').innerHTML = '<p class="search-error">Por favor, ingresa una consulta de búsqueda más específica (mínimo 2 caracteres).</p>';
      return;
    }
    
    // Páginas a buscar (esto es una implementación simple, en un sitio real usarías un índice de búsqueda)
    const pages = [
      { url: '/', title: 'Inicio', weight: 10 },
      { url: '/installation', title: 'Instalación', weight: 8 },
      { url: '/configuration', title: 'Configuración', weight: 8 },
      { url: '/daily-usage', title: 'Uso Diario', weight: 9 },
      { url: '/maintenance', title: 'Mantenimiento', weight: 7 },
      { url: '/troubleshooting', title: 'Solución de Problemas', weight: 9 },
      { url: '/advanced-usage', title: 'Uso Avanzado', weight: 6 },
      { url: '/reference', title: 'Referencia', weight: 5 },
      { url: '/contributing', title: 'Contribuir', weight: 4 }
    ];
    
    // Si estamos en la página de inicio, usar su contenido directamente
    if (window.location.pathname === '/' || window.location.pathname === '/index.html') {
      const homePageIndex = pages.findIndex(p => p.url === '/');
      if (homePageIndex !== -1) {
        pages[homePageIndex].content = document.querySelector('main').textContent;
      }
    }
    
    // Función para cargar el contenido de una página
    async function loadPageContent(page) {
      if (page.content) return page.content;
      
      try {
        const response = await fetch(`{{ site.baseurl }}${page.url}`);
        if (!response.ok) {
          throw new Error(`Error HTTP: ${response.status}`);
        }
        
        const html = await response.text();
        const parser = new DOMParser();
        const doc = parser.parseFromString(html, 'text/html');
        
        // Intentar obtener el contenido principal
        const mainContent = doc.querySelector('main');
        if (mainContent) {
          // Eliminar elementos que no queremos incluir en la búsqueda
          const elementsToRemove = mainContent.querySelectorAll('script, style, .toc, .search-container');
          elementsToRemove.forEach(el => el.remove());
          
          return mainContent.textContent;
        } else {
          // Fallback si no hay elemento main
          return doc.body.textContent;
        }
      } catch (error) {
        console.error(`Error loading content for ${page.url}:`, error);
        return '';
      }
    }
    
    // Función para buscar en el contenido
    function searchInContent(content, query) {
      if (!content) return null;
      
      const lowerContent = content.toLowerCase();
      const lowerQuery = query.toLowerCase();
      
      // Calcular la relevancia basada en el número de coincidencias
      const matches = lowerContent.split(lowerQuery).length - 1;
      if (matches <= 0) return null;
      
      // Encontrar la primera coincidencia para el extracto
      const index = lowerContent.indexOf(lowerQuery);
      let start = Math.max(0, index - 100);
      let end = Math.min(content.length, index + query.length + 100);
      
      // Ajustar para no cortar palabras
      while (start > 0 && !/\s/.test(content[start])) {
        start--;
      }
      
      while (end < content.length && !/\s/.test(content[end])) {
        end++;
      }
      
      let excerpt = content.substring(start, end).trim();
      
      // Añadir elipsis si es necesario
      if (start > 0) excerpt = '...' + excerpt;
      if (end < content.length) excerpt = excerpt + '...';
      
      // Escapar caracteres HTML para evitar inyección
      excerpt = excerpt
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#039;');
      
      // Resaltar la consulta en el extracto (después de escapar HTML)
      const safeQuery = query
        .replace(/[.*+?^${}()|[\]\\]/g, '\\$&') // Escapar caracteres especiales de regex
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#039;');
      
      const regex = new RegExp(`(${safeQuery})`, 'gi');
      excerpt = excerpt.replace(regex, '<mark>$1</mark>');
      
      return {
        excerpt,
        relevance: matches
      };
    }
    
    // Realizar la búsqueda
    async function performSearch() {
      const resultsContainer = document.getElementById('search-results');
      const statusElement = document.querySelector('.search-status');
      
      statusElement.textContent = `Buscando "${query}" en ${pages.length} páginas...`;
      
      const results = [];
      let pagesSearched = 0;
      let totalMatches = 0;
      
      // Crear un array de promesas para buscar en todas las páginas en paralelo
      const searchPromises = pages.map(async (page) => {
        try {
          const content = await loadPageContent(page);
          const searchResult = searchInContent(content, query);
          
          pagesSearched++;
          statusElement.textContent = `Buscando... (${pagesSearched}/${pages.length} páginas)`;
          
          if (searchResult) {
            totalMatches += searchResult.relevance;
            results.push({
              title: page.title,
              url: page.url,
              excerpt: searchResult.excerpt,
              relevance: searchResult.relevance * page.weight // Multiplicar por el peso de la página
            });
          }
        } catch (error) {
          console.error(`Error searching in ${page.url}:`, error);
        }
      });
      
      // Esperar a que todas las búsquedas terminen
      await Promise.all(searchPromises);
      
      // Ordenar resultados por relevancia (de mayor a menor)
      results.sort((a, b) => b.relevance - a.relevance);
      
      // Mostrar resultados
      if (results.length > 0) {
        statusElement.textContent = `Se encontraron ${results.length} resultados para "${query}" (${totalMatches} coincidencias totales)`;
        
        let html = '<ul class="search-results-list">';
        
        results.forEach(result => {
          html += `
            <li class="search-result">
              <h3 class="result-title">
                <a href="{{ site.baseurl }}${result.url}">${result.title}</a>
                <span class="result-relevance" title="Relevancia: ${result.relevance.toFixed(1)}">
                  ${Array(Math.min(5, Math.ceil(result.relevance / 2))).fill('★').join('')}
                </span>
              </h3>
              <p class="result-url">{{ site.baseurl }}${result.url}</p>
              <p class="result-excerpt">${result.excerpt}</p>
            </li>
          `;
        });
        
        html += '</ul>';
        resultsContainer.innerHTML = html;
      } else {
        statusElement.textContent = `No se encontraron resultados para "${query}"`;
        resultsContainer.innerHTML = `
          <div class="no-results">
            <p>No se encontraron páginas que coincidan con tu búsqueda.</p>
            <p>Sugerencias:</p>
            <ul>
              <li>Verifica que todas las palabras estén escritas correctamente.</li>
              <li>Prueba con palabras clave diferentes.</li>
              <li>Prueba con palabras más generales.</li>
              <li>Prueba con menos palabras.</li>
            </ul>
          </div>
        `;
      }
    }
    
    // Iniciar la búsqueda
    performSearch();
  });
</script>

<style>
  /* Estilos para el contenedor de búsqueda */
  .search-container {
    max-width: 800px;
    margin: 0 auto;
  }
  
  .search-status {
    margin: 1rem 0;
    padding: 0.5rem 1rem;
    background-color: var(--card-background);
    border-radius: 8px;
    font-size: 0.9rem;
    color: var(--text-color-secondary);
  }
  
  /* Estilos para la lista de resultados */
  .search-results-list {
    list-style: none;
    padding: 0;
    margin: 1.5rem 0;
  }
  
  /* Estilos para cada resultado individual */
  .search-result {
    margin-bottom: 1.5rem;
    padding: 1rem 1.5rem;
    border-radius: 8px;
    background-color: var(--card-background);
    box-shadow: 0 2px 5px rgba(0, 0, 0, 0.05);
    transition: transform 0.2s ease, box-shadow 0.2s ease;
  }
  
  .search-result:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
  }
  
  /* Título del resultado */
  .result-title {
    margin-top: 0;
    margin-bottom: 0.5rem;
    display: flex;
    justify-content: space-between;
    align-items: center;
  }
  
  .result-title a {
    color: var(--primary-color);
    text-decoration: none;
    font-weight: 600;
  }
  
  .result-title a:hover {
    text-decoration: underline;
  }
  
  /* Estrellas de relevancia */
  .result-relevance {
    font-size: 0.8rem;
    color: #ffa41b;
    letter-spacing: -1px;
  }
  
  /* URL del resultado */
  .result-url {
    margin: 0.3rem 0 0.8rem;
    font-size: 0.8rem;
    color: var(--text-color-secondary);
    font-family: monospace;
  }
  
  /* Extracto del resultado */
  .result-excerpt {
    margin: 0.5rem 0 0;
    line-height: 1.5;
    color: var(--text-color);
    font-size: 0.95rem;
  }
  
  /* Texto resaltado */
  mark {
    background-color: rgba(var(--primary-color-rgb), 0.2);
    color: inherit;
    padding: 0 2px;
    border-radius: 2px;
    font-weight: 600;
  }
  
  /* Mensaje de no resultados */
  .no-results {
    padding: 1.5rem;
    background-color: var(--card-background);
    border-radius: 8px;
    border-left: 4px solid var(--primary-color);
  }
  
  .no-results p:first-child {
    font-weight: 600;
    margin-top: 0;
  }
  
  .no-results ul {
    margin-bottom: 0;
    padding-left: 1.5rem;
  }
  
  /* Mensaje de error */
  .search-error {
    padding: 1rem;
    background-color: #fff5f5;
    border-left: 4px solid #e53e3e;
    border-radius: 4px;
    color: #c53030;
  }
  
  /* Animación de carga */
  @keyframes pulse {
    0% { opacity: 0.6; }
    50% { opacity: 1; }
    100% { opacity: 0.6; }
  }
  
  .loading-message {
    animation: pulse 1.5s infinite;
  }
</style>