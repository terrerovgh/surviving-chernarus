document.addEventListener('DOMContentLoaded', function() {
  // Añadir botón de volver arriba
  const backToTopButton = document.getElementById('back-to-top') || document.createElement('button');
  
  if (!document.getElementById('back-to-top')) {
    backToTopButton.id = 'back-to-top';
    backToTopButton.innerHTML = '↑';
    backToTopButton.setAttribute('aria-label', 'Volver arriba');
    backToTopButton.setAttribute('title', 'Volver arriba');
    document.body.appendChild(backToTopButton);
  }
  
  // Mostrar/ocultar botón de volver arriba según el scroll
  window.addEventListener('scroll', function() {
    if (window.pageYOffset > 300) {
      backToTopButton.classList.add('show');
      backToTopButton.style.display = 'flex';
    } else {
      backToTopButton.classList.remove('show');
      backToTopButton.style.display = 'none';
    }
  });
  
  // Acción del botón de volver arriba
  backToTopButton.addEventListener('click', function(e) {
    e.preventDefault();
    window.scrollTo({
      top: 0,
      behavior: 'smooth'
    });
  });
  
  // Inicializar con el botón oculto
  backToTopButton.style.display = 'none';
  
  // Generar tabla de contenidos si existe el elemento
  const tocContainer = document.getElementById('toc') || document.getElementById('toc-container');
  if (tocContainer) {
    const headings = document.querySelectorAll('main h2, main h3, main h4');
    if (headings.length > 1) {
      // Limpiar el contenedor si ya tiene contenido
      tocContainer.innerHTML = '';
      
      // Crear título solo si no existe ya
      if (!document.querySelector('.toc-title')) {
        const tocTitle = document.createElement('h2');
        tocTitle.textContent = 'Tabla de Contenidos';
        tocTitle.classList.add('toc-title');
        tocContainer.appendChild(tocTitle);
      }
      
      const tocList = document.createElement('ul');
      tocList.classList.add('toc-list');
      tocContainer.appendChild(tocList);
      
      headings.forEach(function(heading, index) {
        // Añadir ID al encabezado si no tiene uno
        if (!heading.id) {
          heading.id = 'heading-' + index + '-' + heading.textContent.toLowerCase()
            .replace(/[^\w\s]/gi, '')
            .replace(/\s+/g, '-');
        }
        
        const listItem = document.createElement('li');
        const link = document.createElement('a');
        link.href = '#' + heading.id;
        link.textContent = heading.textContent;
        
        // Añadir clase según el nivel del encabezado
        if (heading.tagName === 'H3') {
          listItem.classList.add('toc-sub-item');
          listItem.style.marginLeft = '15px';
        } else if (heading.tagName === 'H4') {
          listItem.classList.add('toc-sub-sub-item');
          listItem.style.marginLeft = '30px';
        }
        
        listItem.appendChild(link);
        tocList.appendChild(listItem);
        
        // Añadir evento de clic para desplazamiento suave
        link.addEventListener('click', function(e) {
          e.preventDefault();
          document.querySelector(this.getAttribute('href')).scrollIntoView({
            behavior: 'smooth'
          });
          // Actualizar la URL sin recargar la página
          history.pushState(null, null, this.getAttribute('href'));
        });
      });
    } else {
      tocContainer.style.display = 'none';
    }
  }
  
  // Resaltar código si hay bloques de código
  const codeBlocks = document.querySelectorAll('pre code');
  if (codeBlocks.length > 0 && typeof hljs !== 'undefined') {
    codeBlocks.forEach(function(block) {
      hljs.highlightBlock(block);
    });
  }
  
  // Añadir clases a las tablas para estilos
  const tables = document.querySelectorAll('table');
  tables.forEach(function(table) {
    table.classList.add('responsive-table');
    
    // Añadir contenedor para hacer la tabla responsive
    const wrapper = document.createElement('div');
    wrapper.classList.add('table-container');
    table.parentNode.insertBefore(wrapper, table);
    wrapper.appendChild(table);
  });
  
  // Búsqueda en la página
  const searchInput = document.getElementById('search-input');
  const searchButton = document.getElementById('search-button');
  const searchContainer = document.querySelector('.search-container');
  
  if (searchInput && searchButton) {
    // Función para realizar la búsqueda
    const performSearch = function() {
      const query = searchInput.value.trim().toLowerCase();
      if (query) {
        // Obtener la URL base del sitio desde _config.yml o usar la ruta relativa
        const baseUrl = document.querySelector('meta[name="baseurl"]')?.content || '';
        window.location.href = baseUrl + '/search?q=' + encodeURIComponent(query);
      }
    };
    
    // Evento de clic en el botón de búsqueda
    searchButton.addEventListener('click', function(e) {
      e.preventDefault();
      performSearch();
    });
    
    // Evento de tecla Enter en el campo de búsqueda
    searchInput.addEventListener('keypress', function(e) {
      if (e.key === 'Enter') {
        e.preventDefault();
        performSearch();
      }
    });
    
    // Añadir efecto de enfoque al campo de búsqueda
    searchInput.addEventListener('focus', function() {
      if (searchContainer) {
        searchContainer.classList.add('focused');
      }
    });
    
    searchInput.addEventListener('blur', function() {
      if (searchContainer) {
        searchContainer.classList.remove('focused');
      }
    });
    
    // Autoenfoque en el campo de búsqueda si está en la página de búsqueda
    if (window.location.pathname.includes('/search')) {
      searchInput.focus();
    }
  }
  
  // Añadir enlaces de anclaje a los encabezados
  const contentHeadings = document.querySelectorAll('main h2, main h3, main h4, main h5, main h6');
  contentHeadings.forEach(function(heading) {
    // Crear ID para el encabezado si no tiene uno
    if (!heading.id) {
      heading.id = heading.textContent.toLowerCase()
        .replace(/[^\w\s]/gi, '')
        .replace(/\s+/g, '-');
    }
    
    // Añadir enlace de anclaje
    const anchor = document.createElement('a');
    anchor.className = 'anchor';
    anchor.href = '#' + heading.id;
    anchor.innerHTML = '#';
    anchor.title = 'Enlace permanente a esta sección';
    heading.appendChild(anchor);
    
    // Añadir evento para copiar el enlace al portapapeles
    anchor.addEventListener('click', function(e) {
      e.preventDefault();
      const url = window.location.origin + window.location.pathname + this.getAttribute('href');
      navigator.clipboard.writeText(url).then(function() {
        // Mostrar mensaje de confirmación
        const toast = document.createElement('div');
        toast.className = 'toast';
        toast.textContent = 'Enlace copiado al portapapeles';
        document.body.appendChild(toast);
        
        // Eliminar el mensaje después de 2 segundos
        setTimeout(function() {
          toast.classList.add('hide');
          setTimeout(function() {
            document.body.removeChild(toast);
          }, 300);
        }, 2000);
        
        // Actualizar la URL sin recargar la página
        history.pushState(null, null, anchor.getAttribute('href'));
        document.querySelector(anchor.getAttribute('href')).scrollIntoView({ behavior: 'smooth' });
      });
    });
  });
  
  // Desplazamiento suave al objetivo si hay un hash en la URL
  if (window.location.hash) {
    // Esperar a que la página se cargue completamente
    setTimeout(function() {
      const target = document.querySelector(window.location.hash);
      if (target) {
        target.scrollIntoView({ behavior: 'smooth' });
        // Resaltar brevemente el elemento objetivo
        target.classList.add('highlight');
        setTimeout(function() {
          target.classList.remove('highlight');
        }, 2000);
      }
    }, 100);
  }
  
  // Mejorar la navegación del sitio
  const siteNav = document.querySelector('.site-nav');
  if (siteNav) {
    // Marcar el enlace activo en la navegación
    const currentPath = window.location.pathname;
    const navLinks = siteNav.querySelectorAll('a');
    
    navLinks.forEach(function(link) {
      const linkPath = link.getAttribute('href');
      if (currentPath === linkPath || (linkPath !== '/' && currentPath.startsWith(linkPath))) {
        link.classList.add('active');
        // Expandir el elemento padre si está en un submenú
        const parentLi = link.closest('li');
        if (parentLi) {
          parentLi.classList.add('active');
        }
      }
    });
    
    // Añadir botón de menú para móviles si no existe
    if (!document.querySelector('.menu-toggle')) {
      const menuToggle = document.createElement('button');
      menuToggle.className = 'menu-toggle';
      menuToggle.setAttribute('aria-label', 'Menú de navegación');
      menuToggle.innerHTML = '<span></span><span></span><span></span>';
      
      // Insertar antes del primer elemento de la navegación
      siteNav.insertBefore(menuToggle, siteNav.firstChild);
      
      // Alternar la clase 'active' en el menú al hacer clic
      menuToggle.addEventListener('click', function() {
        siteNav.classList.toggle('active');
      });
      
      // Cerrar el menú al hacer clic fuera de él
      document.addEventListener('click', function(e) {
        if (!siteNav.contains(e.target) && siteNav.classList.contains('active')) {
          siteNav.classList.remove('active');
        }
      });
    }
  }
});