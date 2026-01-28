/**
 * Navigation System for DevOps Learning Platform
 * Handles table of contents, breadcrumbs, progress tracking, and section navigation
 */

class NavigationSystem {
    constructor() {
        this.currentModule = null;
        this.currentSection = 0;
        this.progress = this.loadProgress();
        this.initializeNavigation();
    }

    /**
     * Initialize navigation system
     */
    initializeNavigation() {
        this.createNavigationContainer();
        this.bindEvents();
    }

    /**
     * Create navigation container structure
     */
    createNavigationContainer() {
        // Create navigation sidebar
        const navSidebar = document.createElement('div');
        navSidebar.id = 'navigation-sidebar';
        navSidebar.className = 'navigation-sidebar';
        navSidebar.innerHTML = `
            <div class="nav-header">
                <h3>Contents</h3>
                <button id="nav-toggle" class="nav-toggle">☰</button>
            </div>
            <div id="table-of-contents" class="table-of-contents"></div>
            <div id="progress-indicator" class="progress-indicator">
                <div class="progress-bar">
                    <div class="progress-fill" style="width: 0%"></div>
                </div>
                <span class="progress-text">0% Complete</span>
            </div>
        `;

        // Create breadcrumb navigation
        const breadcrumbNav = document.createElement('nav');
        breadcrumbNav.id = 'breadcrumb-navigation';
        breadcrumbNav.className = 'breadcrumb-navigation';
        breadcrumbNav.innerHTML = '<ol class="breadcrumb"></ol>';

        // Create section navigation
        const sectionNav = document.createElement('div');
        sectionNav.id = 'section-navigation';
        sectionNav.className = 'section-navigation';
        sectionNav.innerHTML = `
            <button id="prev-section" class="nav-btn prev-btn" disabled>
                ← Previous
            </button>
            <button id="next-section" class="nav-btn next-btn">
                Next →
            </button>
        `;

        // Insert navigation elements
        document.body.insertBefore(navSidebar, document.body.firstChild);
        
        const container = document.querySelector('.container') || document.body;
        container.insertBefore(breadcrumbNav, container.firstChild);
        container.appendChild(sectionNav);
    }

    /**
     * Generate table of contents from module content
     * @param {Object} moduleData - Module data with sections
     */
    generateTOC(moduleData) {
        this.currentModule = moduleData;
        const tocContainer = document.getElementById('table-of-contents');
        
        if (!moduleData || !moduleData.content_data) {
            tocContainer.innerHTML = '<p class="toc-error">No content available</p>';
            return;
        }

        let contentData;
        try {
            contentData = typeof moduleData.content_data === 'string' 
                ? JSON.parse(moduleData.content_data) 
                : moduleData.content_data;
        } catch (e) {
            tocContainer.innerHTML = '<p class="toc-error">Error loading content</p>';
            return;
        }

        let tocHTML = '<ul class="toc-list">';
        
        if (contentData.sections) {
            contentData.sections.forEach((section, index) => {
                const isCompleted = this.isSectionCompleted(moduleData.title, index);
                const isActive = index === this.currentSection;
                
                tocHTML += `
                    <li class="toc-item ${isCompleted ? 'completed' : ''} ${isActive ? 'active' : ''}">
                        <a href="#section-${index}" class="toc-link" data-section="${index}">
                            <span class="toc-number">${index + 1}</span>
                            <span class="toc-title">${section.title}</span>
                            <span class="toc-status">${isCompleted ? '✓' : ''}</span>
                        </a>
                    </li>
                `;
            });
        }

        // Add assessments and interactive elements to TOC
        if (contentData.interactive_elements) {
            tocHTML += '<li class="toc-separator">Interactive Elements</li>';
            contentData.interactive_elements.forEach((element, index) => {
                tocHTML += `
                    <li class="toc-item interactive">
                        <a href="#interactive-${index}" class="toc-link">
                            <span class="toc-icon">🎯</span>
                            <span class="toc-title">${element.type === 'knowledge_check' ? 'Knowledge Check' : 'Exercise'}</span>
                        </a>
                    </li>
                `;
            });
        }

        tocHTML += '</ul>';
        tocContainer.innerHTML = tocHTML;

        this.updateProgress();
    }

    /**
     * Update breadcrumb navigation
     * @param {Array} breadcrumbs - Array of breadcrumb objects
     */
    showBreadcrumbs(breadcrumbs) {
        const breadcrumbContainer = document.querySelector('.breadcrumb');
        
        let breadcrumbHTML = '';
        breadcrumbs.forEach((crumb, index) => {
            const isLast = index === breadcrumbs.length - 1;
            breadcrumbHTML += `
                <li class="breadcrumb-item ${isLast ? 'active' : ''}">
                    ${isLast ? crumb.title : `<a href="${crumb.url}">${crumb.title}</a>`}
                </li>
            `;
        });
        
        breadcrumbContainer.innerHTML = breadcrumbHTML;
    }

    /**
     * Navigate to specific section
     * @param {number} sectionIndex - Section index to navigate to
     */
    navigateToSection(sectionIndex) {
        if (!this.currentModule) return;

        const sections = document.querySelectorAll('.content-section');
        if (sectionIndex < 0 || sectionIndex >= sections.length) return;

        // Update current section
        this.currentSection = sectionIndex;

        // Scroll to section
        const targetSection = document.getElementById(`section-${sectionIndex}`);
        if (targetSection) {
            targetSection.scrollIntoView({ behavior: 'smooth', block: 'start' });
        }

        // Update TOC active state
        this.updateTOCActiveState();

        // Update section navigation buttons
        this.updateSectionNavigation();

        // Mark section as viewed
        this.markSectionViewed(this.currentModule.title, sectionIndex);
    }

    /**
     * Update TOC active state
     */
    updateTOCActiveState() {
        const tocItems = document.querySelectorAll('.toc-item');
        tocItems.forEach((item, index) => {
            item.classList.toggle('active', index === this.currentSection);
        });
    }

    /**
     * Update section navigation buttons
     */
    updateSectionNavigation() {
        const prevBtn = document.getElementById('prev-section');
        const nextBtn = document.getElementById('next-section');
        
        if (!this.currentModule) return;

        let contentData;
        try {
            contentData = typeof this.currentModule.content_data === 'string' 
                ? JSON.parse(this.currentModule.content_data) 
                : this.currentModule.content_data;
        } catch (e) {
            return;
        }

        const totalSections = contentData.sections ? contentData.sections.length : 0;

        // Update previous button
        prevBtn.disabled = this.currentSection <= 0;
        
        // Update next button
        nextBtn.disabled = this.currentSection >= totalSections - 1;

        // Update button text with section titles
        if (this.currentSection > 0 && contentData.sections) {
            prevBtn.innerHTML = `← ${contentData.sections[this.currentSection - 1].title}`;
        } else {
            prevBtn.innerHTML = '← Previous';
        }

        if (this.currentSection < totalSections - 1 && contentData.sections) {
            nextBtn.innerHTML = `${contentData.sections[this.currentSection + 1].title} →`;
        } else {
            nextBtn.innerHTML = 'Next →';
        }
    }

    /**
     * Mark section as completed
     * @param {string} moduleId - Module identifier
     * @param {number} sectionIndex - Section index
     */
    markSectionCompleted(moduleId, sectionIndex) {
        if (!this.progress[moduleId]) {
            this.progress[moduleId] = { completed: [], viewed: [] };
        }
        
        if (!this.progress[moduleId].completed.includes(sectionIndex)) {
            this.progress[moduleId].completed.push(sectionIndex);
            this.saveProgress();
            this.updateProgress();
            this.updateTOCCompletedState();
        }
    }

    /**
     * Mark section as viewed
     * @param {string} moduleId - Module identifier
     * @param {number} sectionIndex - Section index
     */
    markSectionViewed(moduleId, sectionIndex) {
        if (!this.progress[moduleId]) {
            this.progress[moduleId] = { completed: [], viewed: [] };
        }
        
        if (!this.progress[moduleId].viewed.includes(sectionIndex)) {
            this.progress[moduleId].viewed.push(sectionIndex);
            this.saveProgress();
        }
    }

    /**
     * Check if section is completed
     * @param {string} moduleId - Module identifier
     * @param {number} sectionIndex - Section index
     * @returns {boolean} - Whether section is completed
     */
    isSectionCompleted(moduleId, sectionIndex) {
        return this.progress[moduleId] && 
               this.progress[moduleId].completed.includes(sectionIndex);
    }

    /**
     * Update progress indicator
     */
    updateProgress() {
        if (!this.currentModule) return;

        let contentData;
        try {
            contentData = typeof this.currentModule.content_data === 'string' 
                ? JSON.parse(this.currentModule.content_data) 
                : this.currentModule.content_data;
        } catch (e) {
            return;
        }

        const totalSections = contentData.sections ? contentData.sections.length : 0;
        const completedSections = this.progress[this.currentModule.title] 
            ? this.progress[this.currentModule.title].completed.length 
            : 0;

        const progressPercentage = totalSections > 0 
            ? Math.round((completedSections / totalSections) * 100) 
            : 0;

        // Update progress bar
        const progressFill = document.querySelector('.progress-fill');
        const progressText = document.querySelector('.progress-text');
        
        if (progressFill) {
            progressFill.style.width = `${progressPercentage}%`;
        }
        
        if (progressText) {
            progressText.textContent = `${progressPercentage}% Complete (${completedSections}/${totalSections})`;
        }
    }

    /**
     * Update TOC completed state
     */
    updateTOCCompletedState() {
        const tocItems = document.querySelectorAll('.toc-item');
        tocItems.forEach((item, index) => {
            const isCompleted = this.isSectionCompleted(this.currentModule.title, index);
            item.classList.toggle('completed', isCompleted);
            
            const statusSpan = item.querySelector('.toc-status');
            if (statusSpan) {
                statusSpan.textContent = isCompleted ? '✓' : '';
            }
        });
    }

    /**
     * Bind navigation events
     */
    bindEvents() {
        // TOC navigation
        document.addEventListener('click', (e) => {
            if (e.target.closest('.toc-link')) {
                e.preventDefault();
                const sectionIndex = parseInt(e.target.closest('.toc-link').dataset.section);
                if (!isNaN(sectionIndex)) {
                    this.navigateToSection(sectionIndex);
                }
            }
        });

        // Section navigation buttons
        document.addEventListener('click', (e) => {
            if (e.target.id === 'prev-section') {
                this.navigateToSection(this.currentSection - 1);
            } else if (e.target.id === 'next-section') {
                this.navigateToSection(this.currentSection + 1);
            }
        });

        // Navigation toggle
        document.addEventListener('click', (e) => {
            if (e.target.id === 'nav-toggle') {
                const sidebar = document.getElementById('navigation-sidebar');
                sidebar.classList.toggle('collapsed');
            }
        });

        // Keyboard navigation
        document.addEventListener('keydown', (e) => {
            if (e.ctrlKey || e.metaKey) {
                switch (e.key) {
                    case 'ArrowLeft':
                        e.preventDefault();
                        this.navigateToSection(this.currentSection - 1);
                        break;
                    case 'ArrowRight':
                        e.preventDefault();
                        this.navigateToSection(this.currentSection + 1);
                        break;
                }
            }
        });

        // Scroll-based section detection
        let scrollTimeout;
        window.addEventListener('scroll', () => {
            clearTimeout(scrollTimeout);
            scrollTimeout = setTimeout(() => {
                this.detectCurrentSection();
            }, 100);
        });

        // Mark sections as completed when scrolled through
        this.setupIntersectionObserver();
    }

    /**
     * Detect current section based on scroll position
     */
    detectCurrentSection() {
        const sections = document.querySelectorAll('.content-section');
        const scrollPosition = window.scrollY + window.innerHeight / 3;

        sections.forEach((section, index) => {
            const sectionTop = section.offsetTop;
            const sectionBottom = sectionTop + section.offsetHeight;

            if (scrollPosition >= sectionTop && scrollPosition < sectionBottom) {
                if (this.currentSection !== index) {
                    this.currentSection = index;
                    this.updateTOCActiveState();
                    this.updateSectionNavigation();
                }
            }
        });
    }

    /**
     * Setup intersection observer for automatic completion tracking
     */
    setupIntersectionObserver() {
        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting && entry.intersectionRatio > 0.7) {
                    const sectionElement = entry.target;
                    const sectionIndex = parseInt(sectionElement.id.replace('section-', ''));
                    
                    if (!isNaN(sectionIndex) && this.currentModule) {
                        // Mark as viewed immediately
                        this.markSectionViewed(this.currentModule.title, sectionIndex);
                        
                        // Mark as completed after 3 seconds of viewing
                        setTimeout(() => {
                            if (entry.isIntersecting) {
                                this.markSectionCompleted(this.currentModule.title, sectionIndex);
                            }
                        }, 3000);
                    }
                }
            });
        }, {
            threshold: [0.7],
            rootMargin: '-50px 0px -50px 0px'
        });

        // Observe all content sections
        document.querySelectorAll('.content-section').forEach(section => {
            observer.observe(section);
        });
    }

    /**
     * Load progress from localStorage
     * @returns {Object} - Progress data
     */
    loadProgress() {
        try {
            const saved = localStorage.getItem('devops-learning-progress');
            return saved ? JSON.parse(saved) : {};
        } catch (e) {
            console.error('Error loading progress:', e);
            return {};
        }
    }

    /**
     * Save progress to localStorage
     */
    saveProgress() {
        try {
            localStorage.setItem('devops-learning-progress', JSON.stringify(this.progress));
        } catch (e) {
            console.error('Error saving progress:', e);
        }
    }

    /**
     * Get module progress statistics
     * @param {string} moduleId - Module identifier
     * @returns {Object} - Progress statistics
     */
    getModuleProgress(moduleId) {
        const moduleProgress = this.progress[moduleId] || { completed: [], viewed: [] };
        return {
            completed: moduleProgress.completed.length,
            viewed: moduleProgress.viewed.length,
            completedSections: moduleProgress.completed,
            viewedSections: moduleProgress.viewed
        };
    }

    /**
     * Reset module progress
     * @param {string} moduleId - Module identifier
     */
    resetModuleProgress(moduleId) {
        if (this.progress[moduleId]) {
            delete this.progress[moduleId];
            this.saveProgress();
            this.updateProgress();
            this.updateTOCCompletedState();
        }
    }
}

// Initialize navigation system when DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    window.navigationSystem = new NavigationSystem();
});