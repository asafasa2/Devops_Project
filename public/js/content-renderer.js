/**
 * Content Rendering System for DevOps Learning Platform
 * Parses database learning content and renders it as structured HTML
 */

class ContentRenderer {
    constructor() {
        this.initializeSyntaxHighlighting();
    }

    /**
     * Initialize syntax highlighting with Prism.js
     */
    initializeSyntaxHighlighting() {
        // Load Prism.js if not already loaded
        if (typeof Prism === 'undefined') {
            const prismCSS = document.createElement('link');
            prismCSS.rel = 'stylesheet';
            prismCSS.href = 'https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/themes/prism-tomorrow.min.css';
            document.head.appendChild(prismCSS);

            const prismJS = document.createElement('script');
            prismJS.src = 'https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/prism.min.js';
            document.head.appendChild(prismJS);

            // Load additional language support
            const languages = ['yaml', 'bash', 'docker', 'javascript', 'python', 'sql'];
            languages.forEach(lang => {
                const langScript = document.createElement('script');
                langScript.src = `https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-${lang}.min.js`;
                document.head.appendChild(langScript);
            });
        }
    }

    /**
     * Render complete module content from database JSON
     * @param {Object} moduleData - Module data from database
     * @returns {string} - Rendered HTML content
     */
    renderModule(moduleData) {
        if (!moduleData || !moduleData.content_data) {
            return '<div class="error">Module content not available</div>';
        }

        let contentData;
        try {
            contentData = typeof moduleData.content_data === 'string' 
                ? JSON.parse(moduleData.content_data) 
                : moduleData.content_data;
        } catch (e) {
            console.error('Error parsing module content:', e);
            return '<div class="error">Error loading module content</div>';
        }

        let html = `
            <div class="module-content" data-module-id="${moduleData.title}">
                <div class="module-header">
                    <h1>${moduleData.title}</h1>
                    <div class="module-meta">
                        <span class="difficulty ${moduleData.difficulty_level}">${moduleData.difficulty_level}</span>
                        <span class="duration">${moduleData.estimated_duration} minutes</span>
                    </div>
                </div>
        `;

        if (contentData.sections) {
            html += '<div class="module-sections">';
            contentData.sections.forEach((section, index) => {
                html += this.renderSection(section, index);
            });
            html += '</div>';
        }

        if (contentData.objectives) {
            html += this.renderObjectives(contentData.objectives);
        }

        if (contentData.interactive_elements) {
            html += this.renderInteractiveElements(contentData.interactive_elements);
        }

        html += '</div>';
        return html;
    }

    /**
     * Render individual content section
     * @param {Object} sectionData - Section data
     * @param {number} index - Section index
     * @returns {string} - Rendered HTML
     */
    renderSection(sectionData, index) {
        let html = `
            <div class="content-section" id="section-${index}" data-section-title="${sectionData.title}">
                <h2>${sectionData.title}</h2>
                <div class="section-content">
                    <p>${sectionData.content}</p>
                </div>
        `;

        if (sectionData.key_concepts) {
            html += this.renderKeyConcepts(sectionData.key_concepts);
        }

        if (sectionData.components) {
            html += this.renderComponents(sectionData.components);
        }

        if (sectionData.code_examples) {
            html += this.renderCodeExamples(sectionData.code_examples);
        }

        if (sectionData.benefits) {
            html += this.renderList(sectionData.benefits, 'Benefits', 'benefits-list');
        }

        if (sectionData.installation_methods) {
            html += this.renderInstallationMethods(sectionData.installation_methods);
        }

        if (sectionData.command_categories) {
            html += this.renderCommandCategories(sectionData.command_categories);
        }

        html += '</div>';
        return html;
    }

    /**
     * Render code examples with syntax highlighting
     * @param {Array} codeExamples - Array of code example objects
     * @returns {string} - Rendered HTML
     */
    renderCodeExamples(codeExamples) {
        let html = '<div class="code-examples">';
        
        codeExamples.forEach((example, index) => {
            const language = this.detectLanguage(example.code);
            html += `
                <div class="code-example" id="code-example-${index}">
                    <div class="code-header">
                        <h4>${example.title}</h4>
                        ${example.description ? `<p class="code-description">${example.description}</p>` : ''}
                        <button class="copy-btn" onclick="copyToClipboard('code-${index}')">
                            📋 Copy
                        </button>
                    </div>
                    <pre><code id="code-${index}" class="language-${language}">${this.escapeHtml(example.code)}</code></pre>
                </div>
            `;
        });
        
        html += '</div>';
        return html;
    }

    /**
     * Render key concepts as a styled list
     * @param {Array} concepts - Array of concept strings
     * @returns {string} - Rendered HTML
     */
    renderKeyConcepts(concepts) {
        let html = '<div class="key-concepts"><h3>Key Concepts</h3><ul class="concepts-list">';
        concepts.forEach(concept => {
            html += `<li>${concept}</li>`;
        });
        html += '</ul></div>';
        return html;
    }

    /**
     * Render components with descriptions
     * @param {Array} components - Array of component objects
     * @returns {string} - Rendered HTML
     */
    renderComponents(components) {
        let html = '<div class="components-section"><h3>Components</h3><div class="components-grid">';
        components.forEach(component => {
            html += `
                <div class="component-card">
                    <h4>${component.name}</h4>
                    <p>${component.description}</p>
                </div>
            `;
        });
        html += '</div></div>';
        return html;
    }

    /**
     * Render installation methods
     * @param {Array} methods - Array of installation method objects
     * @returns {string} - Rendered HTML
     */
    renderInstallationMethods(methods) {
        let html = '<div class="installation-methods"><h3>Installation Methods</h3>';
        methods.forEach(method => {
            html += `
                <div class="installation-method">
                    <h4>${method.method || method.platform}</h4>
                    ${method.description ? `<p>${method.description}</p>` : ''}
                    ${method.commands ? this.renderCommandList(method.commands) : ''}
                </div>
            `;
        });
        html += '</div>';
        return html;
    }

    /**
     * Render command categories
     * @param {Array} categories - Array of command category objects
     * @returns {string} - Rendered HTML
     */
    renderCommandCategories(categories) {
        let html = '<div class="command-categories"><h3>Commands</h3>';
        categories.forEach(category => {
            html += `
                <div class="command-category">
                    <h4>${category.category}</h4>
                    <div class="commands-list">
            `;
            category.commands.forEach(cmd => {
                html += `
                    <div class="command-item">
                        <code class="command">${cmd.command}</code>
                        <span class="command-description">${cmd.description}</span>
                    </div>
                `;
            });
            html += '</div></div>';
        });
        html += '</div>';
        return html;
    }

    /**
     * Render command list
     * @param {Array} commands - Array of command strings
     * @returns {string} - Rendered HTML
     */
    renderCommandList(commands) {
        let html = '<div class="command-list">';
        commands.forEach(command => {
            html += `<code class="command-line">${command}</code>`;
        });
        html += '</div>';
        return html;
    }

    /**
     * Render objectives list
     * @param {Array} objectives - Array of objective strings
     * @returns {string} - Rendered HTML
     */
    renderObjectives(objectives) {
        return this.renderList(objectives, 'Learning Objectives', 'objectives-list');
    }

    /**
     * Render generic list with title
     * @param {Array} items - Array of items
     * @param {string} title - List title
     * @param {string} className - CSS class name
     * @returns {string} - Rendered HTML
     */
    renderList(items, title, className) {
        let html = `<div class="${className}"><h3>${title}</h3><ul>`;
        items.forEach(item => {
            html += `<li>${item}</li>`;
        });
        html += '</ul></div>';
        return html;
    }

    /**
     * Render interactive elements
     * @param {Array} elements - Array of interactive element objects
     * @returns {string} - Rendered HTML
     */
    renderInteractiveElements(elements) {
        let html = '<div class="interactive-elements">';
        elements.forEach((element, index) => {
            html += this.renderInteractiveElement(element, index);
        });
        html += '</div>';
        return html;
    }

    /**
     * Render single interactive element
     * @param {Object} elementData - Interactive element data
     * @param {number} index - Element index
     * @returns {string} - Rendered HTML
     */
    renderInteractiveElement(elementData, index) {
        switch (elementData.type) {
            case 'knowledge_check':
                return this.renderKnowledgeCheck(elementData, index);
            case 'code_exercise':
                return this.renderCodeExercise(elementData, index);
            default:
                return `<div class="interactive-element">Interactive element: ${elementData.type}</div>`;
        }
    }

    /**
     * Render knowledge check quiz
     * @param {Object} checkData - Knowledge check data
     * @param {number} index - Element index
     * @returns {string} - Rendered HTML
     */
    renderKnowledgeCheck(checkData, index) {
        let html = `
            <div class="knowledge-check" id="knowledge-check-${index}">
                <h4>Knowledge Check</h4>
                <p class="question">${checkData.question}</p>
                <div class="options">
        `;
        
        checkData.options.forEach((option, optIndex) => {
            html += `
                <label class="option">
                    <input type="radio" name="question-${index}" value="${optIndex}">
                    <span>${option}</span>
                </label>
            `;
        });
        
        html += `
                </div>
                <button class="check-answer-btn" onclick="checkAnswer(${index}, ${checkData.correct})">
                    Check Answer
                </button>
                <div class="explanation" id="explanation-${index}" style="display: none;">
                    <p><strong>Explanation:</strong> ${checkData.explanation}</p>
                </div>
            </div>
        `;
        
        return html;
    }

    /**
     * Render code exercise
     * @param {Object} exerciseData - Code exercise data
     * @param {number} index - Element index
     * @returns {string} - Rendered HTML
     */
    renderCodeExercise(exerciseData, index) {
        return `
            <div class="code-exercise" id="code-exercise-${index}">
                <h4>${exerciseData.title}</h4>
                <p>${exerciseData.description}</p>
                <div class="exercise-template">
                    <pre><code class="language-yaml">${this.escapeHtml(exerciseData.template)}</code></pre>
                </div>
                <div class="exercise-solution" style="display: none;">
                    <h5>Solution:</h5>
                    <pre><code class="language-yaml">${this.escapeHtml(exerciseData.solution)}</code></pre>
                </div>
                <button onclick="toggleSolution(${index})">Show Solution</button>
            </div>
        `;
    }

    /**
     * Detect programming language from code content
     * @param {string} code - Code content
     * @returns {string} - Detected language
     */
    detectLanguage(code) {
        if (code.includes('---') && (code.includes('name:') || code.includes('hosts:'))) return 'yaml';
        if (code.includes('docker ') || code.includes('FROM ') || code.includes('RUN ')) return 'docker';
        if (code.includes('#!/bin/bash') || code.includes('sudo ') || code.includes('apt ')) return 'bash';
        if (code.includes('kubectl ') || code.includes('apiVersion:')) return 'yaml';
        if (code.includes('def ') || code.includes('import ')) return 'python';
        if (code.includes('SELECT ') || code.includes('INSERT ')) return 'sql';
        return 'bash';
    }

    /**
     * Escape HTML characters
     * @param {string} text - Text to escape
     * @returns {string} - Escaped text
     */
    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }
}

// Global utility functions
function copyToClipboard(elementId) {
    const element = document.getElementById(elementId);
    const text = element.textContent;
    
    navigator.clipboard.writeText(text).then(() => {
        // Show feedback
        const btn = element.parentElement.querySelector('.copy-btn');
        const originalText = btn.textContent;
        btn.textContent = '✅ Copied!';
        setTimeout(() => {
            btn.textContent = originalText;
        }, 2000);
    }).catch(err => {
        console.error('Failed to copy text: ', err);
    });
}

function checkAnswer(questionIndex, correctAnswer) {
    const selectedOption = document.querySelector(`input[name="question-${questionIndex}"]:checked`);
    const explanationDiv = document.getElementById(`explanation-${questionIndex}`);
    
    if (!selectedOption) {
        alert('Please select an answer first.');
        return;
    }
    
    const selectedValue = parseInt(selectedOption.value);
    const isCorrect = selectedValue === correctAnswer;
    
    // Show explanation
    explanationDiv.style.display = 'block';
    explanationDiv.className = `explanation ${isCorrect ? 'correct' : 'incorrect'}`;
    
    // Update button
    const button = explanationDiv.previousElementSibling;
    button.textContent = isCorrect ? '✅ Correct!' : '❌ Try Again';
    button.disabled = isCorrect;
}

function toggleSolution(exerciseIndex) {
    const solutionDiv = document.querySelector(`#code-exercise-${exerciseIndex} .exercise-solution`);
    const button = solutionDiv.nextElementSibling;
    
    if (solutionDiv.style.display === 'none') {
        solutionDiv.style.display = 'block';
        button.textContent = 'Hide Solution';
    } else {
        solutionDiv.style.display = 'none';
        button.textContent = 'Show Solution';
    }
}

// Initialize content renderer when DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    window.contentRenderer = new ContentRenderer();
});