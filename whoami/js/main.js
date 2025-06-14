// Wait for DOM to be fully loaded
document.addEventListener('DOMContentLoaded', () => {
    // Initialize GSAP
    gsap.registerPlugin();
    
    // Terminal typing effect
    initTypingEffect();
    
    // Initialize menu interactions
    initMenuInteractions();
    
    // Add random glitch effects
    initGlitchEffects();
    
    // Add cursor blink to terminal lines
    initCursorBlink();
});

// Function to initialize typing effect
function initTypingEffect() {
    // The typing animation is handled by CSS
    // This function can be extended for more complex typing animations
    
    // Add a small delay before showing the response
    setTimeout(() => {
        document.querySelector('.terminal-line.response').style.opacity = '1';
    }, 2000);
}

// Function to initialize menu interactions
function initMenuInteractions() {
    // Get all menu items
    const menuItems = document.querySelectorAll('.menu-item');
    const modals = document.querySelectorAll('.modal');
    const closeButtons = document.querySelectorAll('.modal-close');
    
    // Add click event to each menu item
    menuItems.forEach(item => {
        item.addEventListener('click', () => {
            const target = item.getAttribute('data-target');
            const modal = document.getElementById(`${target}-modal`);
            
            if (modal) {
                // Open modal with GSAP animation
                openModal(modal);
            }
        });
    });
    
    // Add click event to close buttons
    closeButtons.forEach(button => {
        button.addEventListener('click', () => {
            const modalId = button.getAttribute('data-modal');
            const modal = document.getElementById(`${modalId}-modal`);
            
            if (modal) {
                // Close modal with GSAP animation
                closeModal(modal);
            }
        });
    });
    
    // Close modal when clicking outside
    modals.forEach(modal => {
        modal.addEventListener('click', (e) => {
            if (e.target === modal) {
                closeModal(modal);
            }
        });
    });
}

// Function to open modal with GSAP animation
function openModal(modal) {
    // First make the modal visible
    modal.style.display = 'block';
    
    // Create a timeline for the animation
    const tl = gsap.timeline();
    
    // Animate the modal background
    tl.to(modal, {
        opacity: 1,
        duration: 0.3,
        ease: 'power2.inOut'
    });
    
    // Animate the modal content
    tl.to(modal.querySelector('.modal-content'), {
        opacity: 1,
        y: 0,
        duration: 0.4,
        ease: 'back.out(1.7)'
    }, '-=0.1');
    
    // Add active class for CSS transitions
    modal.classList.add('active');
    
    // Add terminal typing effect to the command in the modal
    const command = modal.querySelector('.command');
    if (command && !command.classList.contains('typing-animation')) {
        command.classList.add('typing-animation');
        setTimeout(() => {
            command.classList.remove('typing-animation');
        }, 2000);
    }
    
    // Add glitch effect when opening
    addGlitchEffect();
}

// Function to close modal with GSAP animation
function closeModal(modal) {
    // Create a timeline for the animation
    const tl = gsap.timeline({
        onComplete: () => {
            modal.style.display = 'none';
            modal.classList.remove('active');
        }
    });
    
    // Animate the modal content
    tl.to(modal.querySelector('.modal-content'), {
        opacity: 0,
        y: -20,
        duration: 0.3,
        ease: 'power2.in'
    });
    
    // Animate the modal background
    tl.to(modal, {
        opacity: 0,
        duration: 0.2,
        ease: 'power2.in'
    }, '-=0.1');
    
    // Add glitch effect when closing
    addGlitchEffect();
}

// Function to initialize glitch effects
function initGlitchEffects() {
    // Add random glitch effects periodically
    setInterval(() => {
        if (Math.random() > 0.7) { // 30% chance to trigger a glitch
            addGlitchEffect();
        }
    }, 5000);
}

// Function to add a temporary glitch effect
function addGlitchEffect() {
    const glitchOverlay = document.querySelector('.glitch-overlay');
    
    // Increase the opacity for a brief moment, but keep it subtle
    gsap.to(glitchOverlay, {
        opacity: 0.08, // Reduced from 0.15 for a more subtle effect
        duration: 0.1,
        ease: 'power1.inOut',
        onComplete: () => {
            // Add some random transform distortion
            gsap.to(glitchOverlay, {
                skewX: `${(Math.random() - 0.5) * 5}deg`, // Reduced from 10 for subtlety
                skewY: `${(Math.random() - 0.5) * 3}deg`, // Reduced from 5 for subtlety
                x: `${(Math.random() - 0.5) * 5}px`, // Reduced from 10 for subtlety
                y: `${(Math.random() - 0.5) * 5}px`, // Reduced from 10 for subtlety
                duration: 0.1
            });
            
            // Return to normal
            gsap.to(glitchOverlay, {
                opacity: 0.02, // Reduced for a more subtle baseline effect
                skewX: '0deg',
                skewY: '0deg',
                x: 0,
                y: 0,
                duration: 0.3,
                delay: 0.1
            });
        }
    });
    
    // Also add a brief glitch to the terminal text, but more refined
    const terminalTexts = document.querySelectorAll('.terminal-line, .menu-text, .modal-title');
    terminalTexts.forEach(text => {
        if (Math.random() > 0.8) { // Reduced frequency (from 0.7) for more selective effects
            gsap.to(text, {
                skewX: `${(Math.random() - 0.5) * 10}deg`, // Reduced from 20 for subtlety
                color: 'rgba(88, 166, 255, 0.9)', // Updated to match new accent color
                textShadow: '0 0 5px rgba(88, 166, 255, 0.6)', // Updated to match new accent color
                duration: 0.1,
                onComplete: () => {
                    gsap.to(text, {
                        skewX: '0deg',
                        color: '',
                        textShadow: '',
                        duration: 0.3
                    });
                }
            });
        }
    });
}

// Function to initialize cursor blink
function initCursorBlink() {
    // The cursor blink is handled by CSS
    // This function can be extended for more complex cursor animations
}

// Add some terminal-like interactions
document.addEventListener('keydown', (e) => {
    // Only respond to keydown events when no modal is open
    const activeModal = document.querySelector('.modal.active');
    if (!activeModal) {
        // Get the last terminal line with cursor
        const lastLine = document.querySelector('.terminal-output .terminal-line:last-child');
        const cursor = lastLine.querySelector('.cursor');
        
        if (cursor) {
            // If Enter key is pressed
            if (e.key === 'Enter') {
                // Create a new command line
                const newLine = document.createElement('div');
                newLine.className = 'terminal-line';
                newLine.innerHTML = `
                    <span class="prompt">terrerov@chernarus:~$</span>
                    <span class="cursor">_</span>
                `;
                
                // Replace cursor with empty command
                cursor.parentNode.innerHTML = `
                    <span class="prompt">terrerov@chernarus:~$</span>
                    <span class="command"></span>
                `;
                
                // Add the new line
                document.querySelector('.terminal-output').appendChild(newLine);
                
                // Add glitch effect
                addGlitchEffect();
            }
        }
    }
});

// Debounce function for performance optimization
function debounce(func, wait = 20, immediate = false) {
    let timeout;
    return function() {
        const context = this, args = arguments;
        const later = function() {
            timeout = null;
            if (!immediate) func.apply(context, args);
        };
        const callNow = immediate && !timeout;
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
        if (callNow) func.apply(context, args);
    };
}

// Lazy load modals for better performance
function initLazyLoadModals() {
    const menuItems = document.querySelectorAll('.menu-item');
    
    menuItems.forEach(item => {
        const target = item.getAttribute('data-target');
        const modalId = `${target}-modal`;
        
        // Only initialize the modal content when it's first opened
        item.addEventListener('click', function initModal() {
            const modal = document.getElementById(modalId);
            
            if (modal) {
                // Initialize any heavy content or animations here
                if (target === 'projects') {
                    // Add hover effects to project items
                    const projectItems = modal.querySelectorAll('.project-item');
                    projectItems.forEach(project => {
                        project.addEventListener('mouseenter', () => {
                            gsap.to(project, {
                                backgroundColor: 'rgba(255, 255, 255, 0.05)',
                                borderLeftColor: 'var(--accent-color)',
                                x: 2,
                                duration: 0.2
                            });
                        });
                        
                        project.addEventListener('mouseleave', () => {
                            gsap.to(project, {
                                backgroundColor: 'transparent',
                                borderLeftColor: 'transparent',
                                x: 0,
                                duration: 0.2
                            });
                        });
                    });
                }
                
                // Remove this initialization listener after first use
                this.removeEventListener('click', initModal);
            }
        });
    });
}

// Improve accessibility with keyboard navigation
function initKeyboardNavigation() {
    // Handle ESC key to close modals
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') {
            const activeModal = document.querySelector('.modal.active');
            if (activeModal) {
                closeModal(activeModal);
            }
        }
    });
    
    // Add focus trap inside modals for accessibility
    const modals = document.querySelectorAll('.modal');
    modals.forEach(modal => {
        const focusableElements = modal.querySelectorAll('button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])');
        const firstFocusable = focusableElements[0];
        const lastFocusable = focusableElements[focusableElements.length - 1];
        
        modal.addEventListener('keydown', (e) => {
            if (e.key === 'Tab') {
                // If shift + tab and on first element, go to last
                if (e.shiftKey && document.activeElement === firstFocusable) {
                    e.preventDefault();
                    lastFocusable.focus();
                }
                // If tab and on last element, go to first
                else if (!e.shiftKey && document.activeElement === lastFocusable) {
                    e.preventDefault();
                    firstFocusable.focus();
                }
            }
        });
    });
}

// Initialize performance optimizations
document.addEventListener('DOMContentLoaded', () => {
    // Initialize lazy loading for modals
    initLazyLoadModals();
    
    // Initialize keyboard navigation
    initKeyboardNavigation();
    
    // Use debounce for scroll events
    window.addEventListener('scroll', debounce(() => {
        // Handle any scroll-based effects here
        addGlitchEffect();
    }, 50));
});