// Configuration - loaded from config.js
let API_URL = '';

// DOM Elements
const apiStatus = document.getElementById('api-status');
const createUserForm = document.getElementById('create-user-form');
const usersContainer = document.getElementById('users-container');
const refreshBtn = document.getElementById('refresh-btn');

// Initialize
document.addEventListener('DOMContentLoaded', async () => {
    // Load configuration
    await loadConfig();
    
    checkApiHealth();
    loadUsers();
    
    createUserForm.addEventListener('submit', handleCreateUser);
    refreshBtn.addEventListener('click', loadUsers);
});

// Load Configuration
async function loadConfig() {
    try {
        const response = await fetch('config.js');
        const configText = await response.text();
        // Extract API_URL from config.js
        const match = configText.match(/API_URL\s*=\s*['"]([^'"]+)['"]/);
        if (match && match[1]) {
            API_URL = match[1];
            console.log('API URL loaded:', API_URL);
        } else {
            throw new Error('Could not parse API_URL from config');
        }
    } catch (error) {
        console.error('Failed to load config:', error);
        // Fallback to environment variable or default
        API_URL = window.CONFIG?.API_URL || '';
    }
}

// Check API Health
async function checkApiHealth() {
    try {
        const response = await fetch(`${API_URL}/health`);
        const data = await response.json();
        
        if (response.ok && data.status === 'healthy') {
            apiStatus.textContent = '✓ Healthy';
            apiStatus.classList.add('healthy');
        } else {
            throw new Error('API unhealthy');
        }
    } catch (error) {
        apiStatus.textContent = '✗ Error';
        apiStatus.classList.add('error');
        console.error('Health check failed:', error);
    }
}

// Load Users
async function loadUsers() {
    usersContainer.innerHTML = '<div class="loading">Loading users...</div>';
    
    try {
        const response = await fetch(`${API_URL}/users`);
        const data = await response.json();
        
        if (response.ok && data.users) {
            displayUsers(data.users);
        } else {
            throw new Error('Failed to load users');
        }
    } catch (error) {
        usersContainer.innerHTML = `
            <div class="alert alert-error">
                Failed to load users. Please check your API configuration.
            </div>
        `;
        console.error('Load users failed:', error);
    }
}

// Display Users
function displayUsers(users) {
    if (users.length === 0) {
        usersContainer.innerHTML = `
            <div class="loading">No users found. Create one to get started!</div>
        `;
        return;
    }
    
    const usersHTML = users.map(user => `
        <div class="user-card">
            <h3>${escapeHtml(user.name)}</h3>
            <p><strong>Email:</strong> ${escapeHtml(user.email)}</p>
            <p class="user-id"><strong>ID:</strong> ${user.id}</p>
            <p class="user-date"><strong>Created:</strong> ${formatDate(user.created_at)}</p>
        </div>
    `).join('');
    
    usersContainer.innerHTML = `<div class="users-grid">${usersHTML}</div>`;
}

// Handle Create User
async function handleCreateUser(e) {
    e.preventDefault();
    
    const name = document.getElementById('name').value;
    const email = document.getElementById('email').value;
    
    try {
        const response = await fetch(`${API_URL}/users`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ name, email })
        });
        
        const data = await response.json();
        
        if (response.ok) {
            showAlert('User created successfully!', 'success');
            createUserForm.reset();
            loadUsers();
        } else {
            throw new Error(data.error || 'Failed to create user');
        }
    } catch (error) {
        showAlert(`Error: ${error.message}`, 'error');
        console.error('Create user failed:', error);
    }
}

// Show Alert
function showAlert(message, type) {
    const alertDiv = document.createElement('div');
    alertDiv.className = `alert alert-${type}`;
    alertDiv.textContent = message;
    
    const form = document.getElementById('create-user-form');
    form.parentNode.insertBefore(alertDiv, form);
    
    setTimeout(() => {
        alertDiv.remove();
    }, 5000);
}

// Utility Functions
function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

function formatDate(dateString) {
    const date = new Date(dateString);
    return date.toLocaleString('en-US', {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    });
}
