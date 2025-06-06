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
    
    // Increase the opacity for a brief moment
    gsap.to(glitchOverlay, {
        opacity: 0.15,
        duration: 0.1,
        ease: 'power1.inOut',
        onComplete: () => {
            // Add some random transform distortion
            gsap.to(glitchOverlay, {
                skewX: `${(Math.random() - 0.5) * 10}deg`,
                skewY: `${(Math.random() - 0.5) * 5}deg`,
                x: `${(Math.random() - 0.5) * 10}px`,
                y: `${(Math.random() - 0.5) * 10}px`,
                duration: 0.1
            });
            
            // Return to normal
            gsap.to(glitchOverlay, {
                opacity: 0.03,
                skewX: '0deg',
                skewY: '0deg',
                x: 0,
                y: 0,
                duration: 0.3,
                delay: 0.1
            });
        }
    });
    
    // Also add a brief glitch to the terminal text
    const terminalTexts = document.querySelectorAll('.terminal-line, .menu-text, .modal-title');
    terminalTexts.forEach(text => {
        if (Math.random() > 0.7) { // Only affect some elements
            gsap.to(text, {
                skewX: `${(Math.random() - 0.5) * 20}deg`,
                color: 'rgba(0, 255, 120, 0.9)',
                textShadow: '0 0 5px rgba(0, 255, 120, 0.8)',
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