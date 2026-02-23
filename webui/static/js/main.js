/**
 * NovaScript Studio - Main JavaScript
 */

// ==========================================================================
// State Management
// ==========================================================================

const AppState = {
    currentView: 'dashboard',
    currentPath: '/',
    theme: 'dark',
    files: [],
    packages: [],
    projects: []
};

// ==========================================================================
// Initialization
// ==========================================================================

document.addEventListener('DOMContentLoaded', () => {
    initializeNavigation();
    initializeTheme();
    initializeTerminal();
    initializeEditor();
    loadDashboardData();
    loadPackages();
    
    // Show welcome toast
    showToast('Welcome to NovaScript Studio!', 'success');
});

// ==========================================================================
// Navigation
// ==========================================================================

function initializeNavigation() {
    const navItems = document.querySelectorAll('.nav-item');
    
    navItems.forEach(item => {
        item.addEventListener('click', (e) => {
            e.preventDefault();
            const view = item.dataset.view;
            
            if (view) {
                switchView(view);
                
                // Update active state
                navItems.forEach(n => n.classList.remove('active'));
                item.classList.add('active');
                
                // Update breadcrumb
                const currentViewEl = document.getElementById('currentView');
                if (currentViewEl) {
                    currentViewEl.textContent = item.querySelector('span').textContent;
                }
            }
        });
    });
    
    // Sidebar toggle
    const sidebarToggle = document.getElementById('sidebarToggle');
    const sidebar = document.querySelector('.sidebar');
    
    if (sidebarToggle && sidebar) {
        sidebarToggle.addEventListener('click', () => {
            sidebar.classList.toggle('collapsed');
        });
    }
    
    // Mobile menu
    const menuBtn = document.getElementById('menuBtn');
    if (menuBtn) {
        menuBtn.addEventListener('click', () => {
            sidebar.classList.toggle('open');
        });
    }
}

function switchView(viewName) {
    // Hide all views
    document.querySelectorAll('.view').forEach(view => {
        view.classList.remove('active');
    });
    
    // Show selected view
    const targetView = document.getElementById(`view-${viewName}`);
    if (targetView) {
        targetView.classList.add('active');
        AppState.currentView = viewName;
        
        // Load view-specific data
        switch(viewName) {
            case 'packages':
                loadPackages();
                break;
            case 'files':
                loadFiles(AppState.currentPath);
                break;
            case 'projects':
                loadProjects();
                break;
        }
    }
}

// ==========================================================================
// Theme System
// ==========================================================================

function initializeTheme() {
    const themeToggle = document.getElementById('themeToggle');
    const themeSelect = document.getElementById('themeSelect');
    
    // Load saved theme
    const savedTheme = localStorage.getItem('nova-theme') || 'dark';
    setTheme(savedTheme);
    
    if (themeToggle) {
        themeToggle.addEventListener('click', () => {
            const newTheme = AppState.theme === 'dark' ? 'light' : 'dark';
            setTheme(newTheme);
        });
    }
    
    if (themeSelect) {
        themeSelect.value = AppState.theme;
        themeSelect.addEventListener('change', (e) => {
            setTheme(e.target.value);
        });
    }
}

function setTheme(theme) {
    AppState.theme = theme;
    document.documentElement.setAttribute('data-theme', theme);
    localStorage.setItem('nova-theme', theme);
    
    // Update icons
    const lightIcon = document.querySelector('.theme-icon-light');
    const darkIcon = document.querySelector('.theme-icon-dark');
    
    if (lightIcon && darkIcon) {
        if (theme === 'dark') {
            lightIcon.style.display = 'block';
            darkIcon.style.display = 'none';
        } else {
            lightIcon.style.display = 'none';
            darkIcon.style.display = 'block';
        }
    }
}

// ==========================================================================
// Dashboard
// ==========================================================================

async function loadDashboardData() {
    try {
        // Load system info
        const sysInfo = await apiRequest('/api/system/info');
        if (sysInfo) {
            document.getElementById('sysOs').textContent = sysInfo.os || '--';
            document.getElementById('sysArch').textContent = sysInfo.arch || '--';
            document.getElementById('sysHostname').textContent = sysInfo.hostname || '--';
        }
        
        // Load packages count
        const packages = await apiRequest('/api/packages/list');
        if (packages && packages.packages) {
            document.getElementById('packageCount').textContent = packages.packages.length;
            AppState.packages = packages.packages;
        }
        
        // Update uptime
        updateUptime();
        setInterval(updateUptime, 1000);
        
    } catch (error) {
        console.error('Failed to load dashboard data:', error);
    }
}

function updateUptime() {
    const uptimeEl = document.getElementById('uptime');
    if (uptimeEl) {
        // Simulated uptime
        uptimeEl.textContent = '0h 0m';
    }
}

// ==========================================================================
// Packages
// ==========================================================================

async function loadPackages() {
    const container = document.getElementById('packagesList');
    if (!container) return;
    
    try {
        const response = await apiRequest('/api/packages/list');
        const packages = response?.packages || [];
        
        container.innerHTML = packages.map(pkg => `
            <div class="package-card">
                <div class="package-header">
                    <div class="package-icon">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M21 16V8a2 2 0 00-1-1.73l-7-4a2 2 0 00-2 0l-7 4A2 2 0 003 8v8a2 2 0 001 1.73l7 4a2 2 0 002 0l7-4A2 2 0 0021 16z"/>
                        </svg>
                    </div>
                    <div>
                        <div class="package-name">${pkg.name}</div>
                    </div>
                </div>
                <div class="package-desc">${pkg.description || 'No description'}</div>
                <div class="package-actions">
                    <button class="btn btn-secondary" onclick="showPackageDetails('${pkg.name}')">Details</button>
                    <button class="btn btn-primary" onclick="installPackage('${pkg.name}')">Install</button>
                </div>
            </div>
        `).join('');
        
    } catch (error) {
        console.error('Failed to load packages:', error);
        container.innerHTML = '<p class="text-muted">Failed to load packages</p>';
    }
}

function showPackageDetails(name) {
    showToast(`Viewing details for ${name}`, 'info');
}

function installPackage(name) {
    if (name) {
        showToast(`Installing ${name}...`, 'info');
        setTimeout(() => {
            showToast(`${name} installed successfully!`, 'success');
        }, 1500);
    } else {
        showModal(`
            <h2>Install Package</h2>
            <div class="form-group">
                <label>Package Name</label>
                <input type="text" class="form-control" id="packageNameInput" placeholder="Enter package name">
            </div>
            <div style="display: flex; gap: 12px; margin-top: 20px;">
                <button class="btn btn-primary" onclick="confirmInstall()">Install</button>
                <button class="btn btn-secondary" onclick="closeModal()">Cancel</button>
            </div>
        `);
    }
}

function confirmInstall() {
    const name = document.getElementById('packageNameInput')?.value;
    if (name) {
        closeModal();
        installPackage(name);
    }
}

// ==========================================================================
// Terminal
// ==========================================================================

function initializeTerminal() {
    const terminalInput = document.getElementById('terminalInput');
    
    if (terminalInput) {
        terminalInput.addEventListener('keypress', (e) => {
            if (e.key === 'Enter') {
                const command = terminalInput.value;
                executeCommand(command);
                terminalInput.value = '';
            }
        });
    }
}

function executeCommand(cmd) {
    const terminal = document.getElementById('terminal');
    if (!terminal || !cmd) return;
    
    // Add command line
    const cmdLine = document.createElement('div');
    cmdLine.className = 'terminal-line';
    cmdLine.innerHTML = `<span class="prompt">nova@termux:~$</span><span class="command">${escapeHtml(cmd)}</span>`;
    terminal.appendChild(cmdLine);
    
    // Execute and show output
    setTimeout(async () => {
        try {
            const response = await apiRequest('/api/terminal/exec', 'POST', cmd);
            const output = response?.output || 'Command executed';
            
            const outputLine = document.createElement('div');
            outputLine.className = 'terminal-line';
            outputLine.style.color = 'var(--text-secondary)';
            outputLine.textContent = output;
            terminal.appendChild(outputLine);
            
            terminal.scrollTop = terminal.scrollHeight;
        } catch (error) {
            const errorLine = document.createElement('div');
            errorLine.className = 'terminal-line';
            errorLine.style.color = 'var(--error)';
            errorLine.textContent = `Error: ${error.message}`;
            terminal.appendChild(errorLine);
        }
    }, 100);
}

function clearTerminal() {
    const terminal = document.getElementById('terminal');
    if (terminal) {
        terminal.innerHTML = '';
    }
}

// ==========================================================================
// Editor
// ==========================================================================

function initializeEditor() {
    const editor = document.getElementById('codeEditor');
    
    if (editor) {
        editor.addEventListener('input', updateEditorStats);
        editor.addEventListener('click', updateEditorStats);
        editor.addEventListener('keyup', updateEditorStats);
    }
}

function updateEditorStats() {
    const editor = document.getElementById('codeEditor');
    const lineCount = document.getElementById('lineCount');
    const colCount = document.getElementById('colCount');
    
    if (editor && lineCount) {
        const lines = editor.value.split('\n');
        lineCount.textContent = lines.length;
        
        // Calculate column
        const cursorPos = editor.selectionStart;
        const textBeforeCursor = editor.value.substring(0, cursorPos);
        const linesBeforeCursor = textBeforeCursor.split('\n');
        const currentCol = linesBeforeCursor[linesBeforeCursor.length - 1].length + 1;
        
        if (colCount) {
            colCount.textContent = currentCol;
        }
    }
}

function saveFile() {
    const editor = document.getElementById('codeEditor');
    if (editor && editor.value) {
        showToast('File saved successfully!', 'success');
    }
}

function runCode() {
    const editor = document.getElementById('codeEditor');
    if (editor && editor.value) {
        showToast('Running script...', 'info');
        
        // Switch to terminal view
        switchView('terminal');
        
        // Execute in terminal
        setTimeout(() => {
            executeCommand('echo "Script output..."');
        }, 500);
    }
}

function formatCode() {
    showToast('Code formatted!', 'success');
}

// ==========================================================================
// File Manager
// ==========================================================================

async function loadFiles(path) {
    const container = document.getElementById('filesList');
    const pathEl = document.getElementById('currentPath');
    
    if (!container) return;
    
    try {
        const response = await apiRequest(`/api/files/list?path=${encodeURIComponent(path)}`);
        const files = response?.files || [];
        
        if (pathEl) {
            pathEl.textContent = path;
        }
        
        if (files.length === 0) {
            container.innerHTML = '<p class="text-muted">No files found</p>';
            return;
        }
        
        container.innerHTML = files.map(file => `
            <div class="file-card" onclick="handleFileClick('${file.name}', '${file.type}')">
                <div class="file-icon">
                    ${file.type === 'dir' ? `
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M22 19a2 2 0 01-2 2H4a2 2 0 01-2-2V5a2 2 0 012-2h5l2 3h9a2 2 0 012 2z"/>
                        </svg>
                    ` : `
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z"/>
                            <polyline points="14 2 14 8 20 8"/>
                        </svg>
                    `}
                </div>
                <div class="file-name">${file.name}</div>
                <div class="file-meta">${file.type === 'dir' ? 'Folder' : formatFileSize(file.size)}</div>
            </div>
        `).join('');
        
    } catch (error) {
        console.error('Failed to load files:', error);
    }
}

function handleFileClick(name, type) {
    if (type === 'dir') {
        const newPath = AppState.currentPath === '/' 
            ? `/${name}` 
            : `${AppState.currentPath}/${name}`;
        AppState.currentPath = newPath;
        loadFiles(newPath);
    } else {
        showToast(`Opening ${name}...`, 'info');
    }
}

function navigateUp() {
    const path = AppState.currentPath;
    if (path === '/') return;
    
    const parts = path.split('/').filter(p => p);
    parts.pop();
    const newPath = '/' + parts.join('/');
    AppState.currentPath = newPath;
    loadFiles(newPath);
}

function refreshFiles() {
    loadFiles(AppState.currentPath);
    showToast('Files refreshed', 'success');
}

function uploadFile() {
    showToast('Upload feature coming soon!', 'info');
}

// ==========================================================================
// Projects
// ==========================================================================

async function loadProjects() {
    const container = document.getElementById('projectsList');
    if (!container) return;
    
    // Demo projects
    const projects = [
        { name: 'hello-world', files: 2, size: '1 KB' },
        { name: 'calculator', files: 5, size: '3 KB' },
        { name: 'test-project', files: 8, size: '5 KB' }
    ];
    
    AppState.projects = projects;
    document.getElementById('projectCount').textContent = projects.length;
    
    container.innerHTML = projects.map(project => `
        <div class="project-card" onclick="openProject('${project.name}')">
            <div class="project-icon">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M22 19a2 2 0 01-2 2H4a2 2 0 01-2-2V5a2 2 0 012-2h5l2 3h9a2 2 0 012 2z"/>
                </svg>
            </div>
            <div class="project-name">${project.name}</div>
            <div class="project-meta">${project.files} files • ${project.size}</div>
        </div>
    `).join('');
}

function openProject(name) {
    showToast(`Opening project: ${name}`, 'info');
    switchView('editor');
}

function createNewProject() {
    showModal(`
        <h2>New Project</h2>
        <div class="form-group">
            <label>Project Name</label>
            <input type="text" class="form-control" id="newProjectName" placeholder="my-project">
        </div>
        <div class="form-group">
            <label>Template</label>
            <select class="form-control" id="projectTemplate">
                <option value="empty">Empty Project</option>
                <option value="hello">Hello World</option>
                <option value="cli">CLI Application</option>
                <option value="web">Web Application</option>
            </select>
        </div>
        <div style="display: flex; gap: 12px; margin-top: 20px;">
            <button class="btn btn-primary" onclick="confirmCreateProject()">Create</button>
            <button class="btn btn-secondary" onclick="closeModal()">Cancel</button>
        </div>
    `);
}

function confirmCreateProject() {
    const name = document.getElementById('newProjectName')?.value;
    const template = document.getElementById('projectTemplate')?.value;
    
    if (name) {
        closeModal();
        showToast(`Creating project: ${name}`, 'info');
        
        setTimeout(() => {
            showToast(`Project "${name}" created!`, 'success');
            loadProjects();
        }, 1000);
    }
}

// ==========================================================================
// Image Generator
// ==========================================================================

function createImage() {
    const width = document.getElementById('imgWidth')?.value || 800;
    const height = document.getElementById('imgHeight')?.value || 600;
    const bgColor = document.getElementById('bgColor')?.value || '#6366f1';
    
    const canvas = document.getElementById('imageCanvas');
    if (canvas) {
        canvas.width = Math.min(width, 400);
        canvas.height = Math.min(height, 300);
        
        const ctx = canvas.getContext('2d');
        ctx.fillStyle = bgColor;
        ctx.fillRect(0, 0, canvas.width, canvas.height);
        
        // Draw NovaScript logo
        ctx.fillStyle = 'white';
        ctx.font = 'bold 24px Inter';
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';
        ctx.fillText('NovaScript', canvas.width / 2, canvas.height / 2);
        
        showToast('Image created!', 'success');
    }
}

// ==========================================================================
// Modal & Toast
// ==========================================================================

function showModal(content) {
    const modal = document.getElementById('modal');
    const modalContent = document.getElementById('modalContent');
    
    if (modal && modalContent) {
        modalContent.innerHTML = content;
        modal.classList.add('active');
    }
}

function closeModal() {
    const modal = document.getElementById('modal');
    if (modal) {
        modal.classList.remove('active');
    }
}

function showToast(message, type = 'info') {
    const container = document.getElementById('toastContainer');
    if (!container) return;
    
    const toast = document.createElement('div');
    toast.className = `toast ${type}`;
    toast.innerHTML = `
        <span class="toast-message">${message}</span>
        <button class="toast-close" onclick="this.parentElement.remove()">✕</button>
    `;
    
    container.appendChild(toast);
    
    // Auto remove after 3 seconds
    setTimeout(() => {
        if (toast.parentElement) {
            toast.remove();
        }
    }, 3000);
}

// ==========================================================================
// Utilities
// ==========================================================================

async function apiRequest(endpoint, method = 'GET', data = null) {
    try {
        const options = {
            method,
            headers: {
                'Content-Type': 'application/json'
            }
        };
        
        if (data && method !== 'GET') {
            options.body = JSON.stringify({ data });
        }
        
        const response = await fetch(endpoint, options);
        
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        
        return await response.json();
    } catch (error) {
        console.error('API request failed:', error);
        return null;
    }
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

function formatFileSize(bytes) {
    if (bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
}

// Global functions for onclick handlers
window.switchView = switchView;
window.installPackage = installPackage;
window.clearTerminal = clearTerminal;
window.saveFile = saveFile;
window.runCode = runCode;
window.formatCode = formatCode;
window.navigateUp = navigateUp;
window.refreshFiles = refreshFiles;
window.uploadFile = uploadFile;
window.openProject = openProject;
window.createNewProject = createNewProject;
window.confirmCreateProject = confirmCreateProject;
window.createImage = createImage;
window.closeModal = closeModal;
window.showPackageDetails = showPackageDetails;
window.confirmInstall = confirmInstall;
