/**
 * Main JavaScript file for terrerov.com
 * Handles animations, navigation, and interactive elements
 */

// Debug: Check if script is loading
console.log('🔄 [MAIN.JS] Script started loading...');

// ===== PERFORMANCE UTILITIES =====

// Performance utilities
function debounce(func, wait) {
  let timeout;
  return function executedFunction(...args) {
    const later = () => {
      clearTimeout(timeout);
      func(...args);
    };
    clearTimeout(timeout);
    timeout = setTimeout(later, wait);
  };
}

// Fit element to parent using anime.js
function fitElementToParent(el, parent) {
  if (!el || !parent || typeof anime === 'undefined') return;
  
  const parentRect = parent.getBoundingClientRect();
  const elRect = el.getBoundingClientRect();
  const scale = Math.min(parentRect.width / elRect.width, parentRect.height / elRect.height);
  
  anime({
    targets: el,
    scale: scale * 0.95,
    duration: 800,
    easing: 'easeOutQuart'
  });
}

// ===== INTERSECTION OBSERVER =====

function createIntersectionObserver() {
  const options = {
    threshold: 0.1,
    rootMargin: '0px 0px -50px 0px'
  };
  
  return new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        entry.target.classList.add('visible');
      }
    });
  }, options);
}

// ===== TEXT ANIMATIONS =====

const TextAnimations = {
  init() {
    console.log('🔄 [TEXT] Initializing text animations...');
    
    try {
      this.animateHeaderText();
      this.animateSubText();
      console.log('✅ [TEXT] Text animations initialized successfully');
    } catch (error) {
      console.error('❌ [TEXT] Error initializing text animations:', error);
    }
  },
  
  animateHeaderText() {
    const headerText = document.querySelector('.headerText');
    if (!headerText) {
      console.warn('⚠️ [TEXT] .headerText element not found');
      return;
    }
    
    // Simple GSAP animation without SplitText
    gsap.set(headerText, { opacity: 0, y: 50 });
    
    gsap.to(headerText, {
      opacity: 1,
      y: 0,
      duration: 1.2,
      ease: 'back.out(1.7)',
      delay: 0.5
    });
  },
  
  animateSubText() {
    const subText = document.querySelector('.p');
    if (!subText) {
      console.warn('⚠️ [TEXT] .p element not found');
      return;
    }
    
    gsap.set(subText, { opacity: 0, y: 30 });
    
    gsap.to(subText, {
      opacity: 1,
      y: 0,
      duration: 1,
      ease: 'power2.out',
      delay: 1.2
    });
  }
};

// ===== NAVIGATION =====

const Navigation = {
  init() {
    console.log('🔄 [NAV] Initializing navigation...');
    
    try {
      this.setupEventListeners();
      this.setupModalHandlers();
      console.log('✅ [NAV] Navigation initialized successfully');
    } catch (error) {
      console.error('❌ [NAV] Error initializing navigation:', error);
    }
  },
  
  setupEventListeners() {
    // Add navigation event listeners here
    const navLinks = document.querySelectorAll('nav a, .nav-link');
    navLinks.forEach(link => {
      link.addEventListener('click', this.handleNavClick.bind(this));
    });
  },
  
  setupModalHandlers() {
    // Add modal handlers here
    const modals = document.querySelectorAll('.content-section');
    modals.forEach(modal => {
      const closeBtn = modal.querySelector('.close-btn');
      if (closeBtn) {
        closeBtn.addEventListener('click', () => this.closeSection(modal.id));
      }
    });
  },
  
  handleNavClick(e) {
    e.preventDefault();
    const target = e.target.getAttribute('href') || e.target.getAttribute('data-section');
    if (target) {
      this.openSection(target.replace('#', ''));
    }
  },
  
  openSection(sectionId) {
    const section = document.getElementById(sectionId);
    if (section) {
      section.classList.remove('hidden');
      section.classList.add('active');
    }
  },
  
  closeSection(sectionId) {
    const section = document.getElementById(sectionId);
    if (section) {
      section.classList.add('hidden');
      section.classList.remove('active');
    }
  }
};

// ===== SPHERE ANIMATION =====

const SphereAnimation = {
  init() {
    console.log('🔄 [SPHERE] Initializing sphere animation...');
    
    if (typeof anime === 'undefined') {
      console.error('❌ [SPHERE] anime.js not available');
      return;
    }
    
    try {
      const sphereEl = document.querySelector('.sphere-animation');
      console.log('🔄 [SPHERE] Sphere element:', sphereEl ? '✅ Found' : '❌ Missing');
      
      if (!sphereEl) {
        console.error('❌ [SPHERE] .sphere-animation element not found in DOM');
        return;
      }
      
      const paths = sphereEl.querySelectorAll('path');
      console.log('🔄 [SPHERE] Found', paths.length, 'paths');
      
      if (paths.length === 0) {
        console.error('❌ [SPHERE] No paths found in sphere element');
        return;
      }
      
      // Fit sphere to container
      const container = sphereEl.parentElement;
      if (container) {
        fitElementToParent(sphereEl, container);
      }
      
      this.createAnimations(sphereEl, paths);
      console.log('✅ [SPHERE] Sphere animation initialized successfully');
      
    } catch (error) {
      console.error('❌ [SPHERE] Error initializing sphere animation:', error);
    }
  },
  
  createAnimations(sphereEl, paths) {
    // Breathing animation
    try {
      const breathAnimation = anime({
        targets: paths,
        strokeDasharray: function() {
          return [anime.random(50, 200), anime.random(0, 100)];
        },
        strokeDashoffset: function() {
          return anime.random(-200, 200);
        },
        translateX: function() {
          return anime.random(-10, 10);
        },
        translateY: function() {
          return anime.random(-10, 10);
        },
        duration: 4000,
        easing: 'easeInOutSine',
        direction: 'alternate',
        loop: true,
        autoplay: false
      });
      
      breathAnimation.play();
      console.log('✅ [SPHERE] Breath animation started');
    } catch (error) {
      console.error('❌ [SPHERE] Error creating breath animation:', error);
    }
    
    // Intro animation
    try {
      const introAnimation = anime({
        targets: paths,
        strokeDashoffset: [anime.setDashoffset, 0],
        duration: 2000,
        delay: anime.stagger(100),
        easing: 'easeInOutQuart',
        autoplay: false
      });
      
      introAnimation.play();
      console.log('✅ [SPHERE] Intro animation started');
    } catch (error) {
      console.error('❌ [SPHERE] Error creating intro animation:', error);
    }
    
    // Shadow animation
    try {
      const shadowGradient = document.querySelector('#sphereGradient');
      if (shadowGradient) {
        const shadowAnimation = anime({
          targets: shadowGradient,
          opacity: [0, 0.8, 0],
          duration: 3000,
          easing: 'easeInOutSine',
          direction: 'alternate',
          loop: true,
          autoplay: false
        });
        
        shadowAnimation.play();
        console.log('✅ [SPHERE] Shadow animation started');
      }
    } catch (error) {
      console.error('❌ [SPHERE] Error creating shadow animation:', error);
    }
  }
};

// ===== MAIN INITIALIZATION =====

function initApp() {
  console.log('🚀 [INIT] Starting application initialization...');
  
  // Check for required libraries
  console.log('🔄 [INIT] Checking libraries:');
  console.log('  - anime.js:', typeof anime !== 'undefined' ? '✅ Loaded' : '❌ Missing');
  console.log('  - gsap.js:', typeof gsap !== 'undefined' ? '✅ Loaded' : '❌ Missing');
  
  // Check for key DOM elements
  console.log('🔄 [INIT] Checking DOM elements:');
  console.log('  - .sphere-animation:', document.querySelector('.sphere-animation') ? '✅ Found' : '❌ Missing');
  console.log('  - .headerText:', document.querySelector('.headerText') ? '✅ Found' : '❌ Missing');
  
  // Initialize modules
  try {
    console.log('🔄 [INIT] Initializing modules...');
    
    TextAnimations.init();
    Navigation.init();
    SphereAnimation.init();
    
    console.log('🎉 [INIT] Application initialized successfully!');
  } catch (error) {
    console.error('❌ [INIT] Error during initialization:', error);
  }
}

// ===== DOM READY HANDLER =====

// Initialize when DOM is ready
console.log('🔄 [MAIN.JS] Setting up DOM ready listener...');
console.log('🔄 [MAIN.JS] Document ready state:', document.readyState);

if (document.readyState === 'loading') {
  console.log('🔄 [MAIN.JS] DOM still loading, adding event listener...');
  document.addEventListener('DOMContentLoaded', function() {
    console.log('🔄 [MAIN.JS] DOMContentLoaded event fired!');
    initApp();
  });
} else {
  // DOM already loaded
  console.log('🔄 [MAIN.JS] DOM already loaded, calling initApp with timeout...');
  setTimeout(initApp, 100);
}