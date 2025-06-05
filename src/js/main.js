/**
 * Terrerov Personal Website - Main JavaScript
 * High-performance optimized code for GitHub Pages
 * @version 1.2.0
 */

// ===== PERFORMANCE UTILITIES =====

/**
 * Debounce function for performance optimization
 * @param {Function} func - Function to debounce
 * @param {number} wait - Wait time in milliseconds
 * @param {boolean} immediate - Execute immediately
 */
function debounce(func, wait, immediate) {
  let timeout;
  return function executedFunction(...args) {
    const later = () => {
      timeout = null;
      if (!immediate) func.apply(this, args);
    };
    const callNow = immediate && !timeout;
    clearTimeout(timeout);
    timeout = setTimeout(later, wait);
    if (callNow) func.apply(this, args);
  };
}

/**
 * Optimized element fitting with performance improvements
 * @param {HTMLElement} el - Element to fit
 * @param {number} padding - Padding to apply
 */
function fitElementToParent(el, padding) {
  if (!el || !el.parentNode) return;
  
  const resize = debounce(() => {
    if (typeof anime !== 'undefined') {
      anime.set(el, { scale: 1 });
      
      const pad = padding || 0;
      const parentEl = el.parentNode;
      const elOffsetWidth = el.offsetWidth - pad;
      const parentOffsetWidth = parentEl.offsetWidth;
      const ratio = parentOffsetWidth / elOffsetWidth;
      
      requestAnimationFrame(() => {
        anime.set(el, { scale: ratio });
      });
    }
  }, 100);
  
  resize();
  window.addEventListener('resize', resize, { passive: true });
}

/**
 * Intersection Observer for lazy loading animations
 */
const createIntersectionObserver = (callback, options = {}) => {
  const defaultOptions = {
    root: null,
    rootMargin: '50px',
    threshold: 0.1,
    ...options
  };
  
  return new IntersectionObserver(callback, defaultOptions);
};

// ===== ANIMATION MODULES =====

/**
 * Text Animations Module
 */
const TextAnimations = {
  /**
   * Initialize main header text animation
   */
  initHeaderAnimation() {
    if (!this.checkGSAPLibraries()) return;
    
    const splitHeader = new SplitText('.headerText', {
      type: 'chars',
      mask: 'chars'
    });
    
    const splitP = new SplitText('.p', {
      type: 'lines',
      mask: 'lines'
    });
    
    const tl = gsap.timeline({
      repeat: 12,
      repeatDelay: 1,
      yoyo: true
    });
    
    tl.from(splitHeader.chars, {
      filter: 'blur(6px)',
      y: '-15%',
      opacity: 0,
      scale: 0.95,
      duration: 1.2,
      scrambleText: {
        text: '#',
        speed: 0.15
      },
      stagger: {
        each: 0.3,
        from: 'left'
      },
      ease: 'power2.out'
    })
    .from(splitP.lines, {
      filter: 'blur(10px)',
      delay: 0.55,
      opacity: 0,
      scale: 0.95,
      y: '100%',
      duration: 0.55,
      ease: 'power1.out'
    })
    .to(splitHeader.chars, {
      opacity: 100,
      y: '0%',
      duration: 0.2
    });
  },
  
  /**
   * Initialize footer link animations
   */
  initFooterAnimations() {
    if (!this.checkGSAPLibraries()) return;
    
    const footerNavLinks = document.querySelectorAll('.footer-nav-link');
    footerNavLinks.forEach(link => {
      link.addEventListener('mouseenter', () => {
        gsap.to(link, {
          scale: 1.1,
          duration: 0.3,
          ease: 'power2.out'
        });
      });
      
      link.addEventListener('mouseleave', () => {
        gsap.to(link, {
          scale: 1,
          duration: 0.3,
          ease: 'power2.out'
        });
      });
    });
  },
  
  /**
   * Check if GSAP libraries are loaded
   */
  checkGSAPLibraries() {
    return typeof gsap !== 'undefined' && 
           typeof SplitText !== 'undefined' && 
           typeof ScrambleTextPlugin !== 'undefined';
  }
};

/**
 * GitHub Projects Module
 */
const GitHubProjects = {
  username: 'terrerovgh',
  
  /**
   * Fetch and display GitHub projects
   */
  async fetchProjects() {
    const projectsList = document.querySelector('#projects .projects-list') || 
                        document.getElementById('projects-list');
    const loadingMessage = document.querySelector('#projects .loading-projects') || 
                          document.querySelector('.loading-projects');
    
    if (!projectsList) return;
    
    try {
      const response = await fetch(
        `https://api.github.com/users/${this.username}/repos?sort=updated&per_page=5`
      );
      const repos = await response.json();
      
      // Clear loading message
      if (loadingMessage) loadingMessage.remove();
      
      // Clear existing content
      projectsList.innerHTML = '';
      
      repos.forEach((repo, index) => {
        const projectCard = this.createProjectCard(repo);
        projectsList.appendChild(projectCard);
        
        // Set initial hidden state for animation
        if (typeof gsap !== 'undefined') {
          gsap.set(projectCard, {
            opacity: 0,
            y: 30,
            scale: 0.9
          });
        }
      });
      
    } catch (error) {
      console.error('Error fetching GitHub projects:', error);
      this.handleError(projectsList, loadingMessage);
    }
  },
  
  /**
   * Create a project card element
   */
  createProjectCard(repo) {
    const projectCard = document.createElement('div');
    projectCard.className = 'project-card';
    
    projectCard.innerHTML = `
      <h3 class="project-title">${repo.name}</h3>
      <p class="project-description">${repo.description || 'No description available'}</p>
      <a href="${repo.html_url}" target="_blank" class="project-link">View on GitHub</a>
    `;
    
    this.addProjectAnimations(projectCard);
    return projectCard;
  },
  
  /**
   * Add hover animations to project cards
   */
  addProjectAnimations(projectCard) {
    if (typeof gsap === 'undefined') return;
    
    // Project title hover animation
    const projectTitle = projectCard.querySelector('.project-title');
    if (projectTitle && typeof SplitText !== 'undefined') {
      const titleText = new SplitText(projectTitle, { type: 'chars' });
      
      projectCard.addEventListener('mouseenter', () => {
        gsap.to(titleText.chars, {
          y: -3,
          duration: 0.3,
          stagger: 0.02,
          ease: 'power2.out'
        });
      });
      
      projectCard.addEventListener('mouseleave', () => {
        gsap.to(titleText.chars, {
          y: 0,
          duration: 0.3,
          stagger: 0.02,
          ease: 'power2.out'
        });
      });
    }
    
    // Project link scramble animation
    const projectLink = projectCard.querySelector('.project-link');
    if (projectLink && typeof ScrambleTextPlugin !== 'undefined') {
      projectLink.addEventListener('mouseenter', () => {
        gsap.to(projectLink, {
          duration: 0.6,
          scrambleText: {
            text: 'View on GitHub',
            chars: 'XO',
            revealDelay: 0.1,
            speed: 0.3
          },
          ease: 'none'
        });
      });
    }
  },
  
  /**
   * Handle fetch errors
   */
  handleError(projectsList, loadingMessage) {
    if (loadingMessage) {
      loadingMessage.textContent = 'Error loading projects';
    } else {
      projectsList.innerHTML = '<div class="loading-projects">Error loading projects. Please try again later.</div>';
    }
  },
  
  /**
   * Animate project cards when section opens
   */
  animateProjectCards(targetSection) {
    if (typeof gsap === 'undefined') return;
    
    setTimeout(() => {
      const projectCards = targetSection.querySelectorAll('.project-card');
      projectCards.forEach((card, index) => {
        gsap.to(card, {
          opacity: 1,
          y: 0,
          scale: 1,
          duration: 0.6,
          delay: index * 0.1,
          ease: 'power2.out'
        });
      });
    }, 500);
  }
};

/**
 * Navigation Module
 */
const Navigation = {
  /**
   * Initialize navigation functionality
   */
  init() {
    this.setupNavLinks();
    this.setupFooterLinks();
    this.setupCloseButtons();
  },
  
  /**
   * Setup main navigation links
   */
  setupNavLinks() {
    const navLinks = document.querySelectorAll('.nav-link');
    
    navLinks.forEach(link => {
      link.addEventListener('click', (e) => {
        e.preventDefault();
        const targetId = link.getAttribute('href').substring(1);
        const targetSection = document.getElementById(targetId);
        
        if (targetSection) {
          this.openSection(targetSection);
          
          // Special handling for projects section
          if (targetId === 'projects') {
            GitHubProjects.fetchProjects();
            GitHubProjects.animateProjectCards(targetSection);
          }
        }
      });
    });
  },
  
  /**
   * Setup footer navigation links
   */
  setupFooterLinks() {
    const footerNavLinks = document.querySelectorAll('.footer-nav-link');
    
    footerNavLinks.forEach(link => {
      link.addEventListener('click', (e) => {
        e.preventDefault();
        const targetId = link.getAttribute('href').substring(1);
        const targetSection = document.getElementById(targetId);
        
        if (targetSection) {
          this.openSection(targetSection);
        }
      });
    });
  },
  
  /**
   * Setup close buttons
   */
  setupCloseButtons() {
    const closeBtns = document.querySelectorAll('.close-section');
    
    closeBtns.forEach(btn => {
      btn.addEventListener('click', () => {
        const section = btn.closest('.content-section');
        this.closeSection(section);
      });
    });
  },
  
  /**
   * Open a section with animations
   */
  openSection(targetSection) {
    // Show section
    targetSection.classList.remove('hidden');
    targetSection.style.display = 'flex';
    
    if (typeof gsap === 'undefined') return;
    
    // Animate section title
    const sectionTitle = targetSection.querySelector('h2');
    if (sectionTitle && typeof SplitText !== 'undefined') {
      const titleText = new SplitText(sectionTitle, { type: 'chars' });
      
      gsap.fromTo(titleText.chars, 
        {
          opacity: 0,
          y: 20,
          scale: 0.8
        },
        {
          opacity: 1,
          y: 0,
          scale: 1,
          duration: 0.8,
          stagger: 0.05,
          ease: 'back.out(1.7)',
          onComplete: () => {
            // Subtle pulse effect
            gsap.to(titleText.chars, {
              scale: 1.05,
              duration: 0.3,
              yoyo: true,
              repeat: 1,
              ease: 'power2.inOut',
              stagger: 0.02
            });
          }
        }
      );
    }
    
    // Animate section content
    const sectionContent = targetSection.querySelector('p, .github-username, .projects-list');
    if (sectionContent) {
      gsap.fromTo(sectionContent,
        {
          opacity: 0,
          y: 30
        },
        {
          opacity: 1,
          y: 0,
          duration: 0.6,
          delay: 0.3,
          ease: 'power2.out'
        }
      );
    }
    
    // Animate section background
    gsap.fromTo(targetSection,
      {
        opacity: 0
      },
      {
        opacity: 1,
        duration: 0.4,
        ease: 'power2.out'
      }
    );
  },
  
  /**
   * Close a section with animations
   */
  closeSection(section) {
    if (typeof gsap !== 'undefined') {
      gsap.to(section, {
        opacity: 0,
        duration: 0.3,
        ease: 'power2.in',
        onComplete: () => {
          section.classList.add('hidden');
          section.style.display = 'none';
          gsap.set(section, { opacity: 1 });
        }
      });
    } else {
      section.classList.add('hidden');
      section.style.display = 'none';
    }
  }
};

/**
 * Sphere Animation Module
 */
const SphereAnimation = {
  /**
   * Initialize sphere animation
   */
  init() {
    const sphereEl = document.querySelector('.sphere-animation');
    const spherePathEls = sphereEl.querySelectorAll('.sphere path');
    const pathLength = spherePathEls.length;
    const animations = [];
    
    fitElementToParent(sphereEl);
    
    // Breath animation
    const breathAnimation = anime({
      begin: () => {
        for (let i = 0; i < pathLength; i++) {
          animations.push(anime({
            targets: spherePathEls[i],
            stroke: {
              value: ['rgba(255,75,75,1)', 'rgba(80,80,80,.35)'],
              duration: 500
            },
            translateX: [2, -4],
            translateY: [2, -4],
            easing: 'easeOutQuad',
            autoplay: false
          }));
        }
      },
      update: (ins) => {
        animations.forEach((animation, i) => {
          const percent = (1 - Math.sin((i * 0.35) + (0.0022 * ins.currentTime))) / 2;
          animation.seek(animation.duration * percent);
        });
      },
      duration: Infinity,
      autoplay: false
    });
    
    // Intro animation
    const introAnimation = anime.timeline({
      autoplay: false
    })
    .add({
      targets: spherePathEls,
      strokeDashoffset: {
        value: [anime.setDashoffset, 0],
        duration: 3900,
        easing: 'easeInOutCirc',
        delay: anime.stagger(190, { direction: 'reverse' })
      },
      duration: 2000,
      delay: anime.stagger(60, { direction: 'reverse' }),
      easing: 'linear'
    }, 0);
    
    // Shadow animation
    const shadowAnimation = anime({
      targets: '#sphereGradient',
      x1: '25%',
      x2: '25%',
      y1: '0%',
      y2: '75%',
      duration: 30000,
      easing: 'easeOutQuint',
      autoplay: false
    }, 0);
    
    // Start animations
    introAnimation.play();
    breathAnimation.play();
    shadowAnimation.play();
  }
};

// ===== MAIN INITIALIZATION =====

/**
 * Initialize the application
 */
function initApp() {
  // Check if all required libraries are loaded
  if (typeof anime === 'undefined') {
    console.warn('Anime.js not loaded yet, retrying...');
    setTimeout(initApp, 100);
    return;
  }
  
  if (typeof gsap === 'undefined') {
    console.warn('GSAP not loaded yet, retrying...');
    setTimeout(initApp, 100);
    return;
  }
  
  // Register GSAP plugins if available
  if (typeof SplitText !== 'undefined' && typeof ScrambleTextPlugin !== 'undefined') {
    gsap.registerPlugin(SplitText, ScrambleTextPlugin);
  }
  
  console.log('All libraries loaded, initializing modules...');
  
  // Initialize modules
  TextAnimations.initHeaderAnimation();
  TextAnimations.initFooterAnimations();
  Navigation.init();
  SphereAnimation.init();
}

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', initApp);

// Also try to initialize if the script loads after DOMContentLoaded
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initApp);
} else {
  initApp();
}