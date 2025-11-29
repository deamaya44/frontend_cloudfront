// Multi-Region Configuration with Automatic Failover
let currentApiUrl = '';
let isUsingPrimary = true;
let healthCheckInterval = null;

// DOM Elements
const apiStatus = document.getElementById('api-status');
const currentRegion = document.getElementById('current-region');
const createUserForm = document.getElementById('create-user-form');
const usersContainer = document.getElementById('users-container');
const refreshBtn = document.getElementById('refresh-btn');

// Initialize
document.addEventListener('DOMContentLoaded', async () => {
    console.log('🚀 Initializing Multi-Region Frontend...');
    
    // Set initial API URL
    await initializeApiConnection();
    
    // Start periodic health checks
    startHealthMonitoring();
    
    // Load initial data
    loadUsers();
    
    // Event listeners
    createUserForm.addEventListener('submit', handleCreateUser);
    refreshBtn.addEventListener('click', loadUsers);
});

// Initialize API Connection with failover
async function initializeApiConnection() {
    console.log('🔍 Testing API endpoints...');
    
    // Try primary first
    const primaryHealthy = await testEndpoint(CONFIG.PRIMARY_API_URL);
    if (primaryHealthy) {
        setActiveApi(CONFIG.PRIMARY_API_URL, true);
        return;
    }
    
    console.warn('⚠️ Primary API unavailable, trying secondary...');
    
    // Try secondary
    const secondaryHealthy = await testEndpoint(CONFIG.SECONDARY_API_URL);
    if (secondaryHealthy) {
        setActiveApi(CONFIG.SECONDARY_API_URL, false);
        return;
    }
    
    console.error('❌ Both APIs unavailable');
    apiStatus.textContent = '✗ All APIs Down';
    apiStatus.className = 'status error';
    currentRegion.textContent = 'N/A';
}

// Test endpoint health
async function testEndpoint(url, timeout = CONFIG.REQUEST_TIMEOUT) {
    try {
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), timeout);
        
        const response = await fetch(`${url}/health`, {
            signal: controller.signal
        });
        
        clearTimeout(timeoutId);
        
        if (response.ok) {
            const data = await response.json();
            return data.status === 'healthy';
        }
        return false;
    } catch (error) {
        console.error(`Endpoint ${url} test failed:`, error.message);
        return false;
    }
}

// Set active API
function setActiveApi(url, isPrimary) {
    currentApiUrl = url;
    isUsingPrimary = isPrimary;
    
    const region = isPrimary ? 'us-east-1 (Primary)' : 'us-west-2 (Failover)';
    const status = isPrimary ? '✓ Healthy' : '⚠ Failover Active';
    const statusClass = isPrimary ? 'healthy' : 'warning';
    
    apiStatus.textContent = status;
    apiStatus.className = `status ${statusClass}`;
    currentRegion.textContent = region;
    
    console.log(`✅ Active API: ${region} - ${url}`);
}

// Start health monitoring
function startHealthMonitoring() {
    if (healthCheckInterval) {
        clearInterval(healthCheckInterval);
    }
    
    healthCheckInterval = setInterval(async () => {
        console.log('🔍 Performing health check...');
        
        // Check current API
        const currentHealthy = await testEndpoint(currentApiUrl);
        
        if (!currentHealthy) {
            console.warn(`⚠️ Current API (${isUsingPrimary ? 'Primary' : 'Secondary'}) is down`);
            
            // Try to failover
            const alternateUrl = isUsingPrimary ? CONFIG.SECONDARY_API_URL : CONFIG.PRIMARY_API_URL;
            const alternateHealthy = await testEndpoint(alternateUrl);
            
            if (alternateHealthy) {
                console.log(`✅ Failing over to ${isUsingPrimary ? 'Secondary' : 'Primary'}`);
                setActiveApi(alternateUrl, !isUsingPrimary);
                loadUsers(); // Refresh data from new endpoint
            } else {
                apiStatus.textContent = '✗ All APIs Down';
                apiStatus.className = 'status error';
            }
        } else if (!isUsingPrimary && CONFIG.FAILOVER_ENABLED) {
            // Try to failback to primary if it's available
            const primaryHealthy = await testEndpoint(CONFIG.PRIMARY_API_URL);
            if (primaryHealthy) {
                console.log('✅ Primary API restored, failing back...');
                setActiveApi(CONFIG.PRIMARY_API_URL, true);
                loadUsers(); // Refresh data from primary
            }
        }
    }, CONFIG.HEALTH_CHECK_INTERVAL);
}

// Make API request with automatic failover
async function makeApiRequest(endpoint, options = {}) {
    let lastError = null;
    
    for (let attempt = 0; attempt <= CONFIG.MAX_RETRIES; attempt++) {
        try {
            const controller = new AbortController();
            const timeoutId = setTimeout(() => controller.abort(), CONFIG.REQUEST_TIMEOUT);
            
            const response = await fetch(`${currentApiUrl}${endpoint}`, {
                ...options,
                signal: controller.signal
            });
            
            clearTimeout(timeoutId);
            
            if (!response.ok) {
                throw new Error(`HTTP ${response.status}: ${response.statusText}`);
            }
            
            return await response.json();
        } catch (error) {
            console.error(`API request failed (attempt ${attempt + 1}/${CONFIG.MAX_RETRIES + 1}):`, error.message);
            lastError = error;
            
            // Try alternate endpoint if this is not the last attempt
            if (attempt < CONFIG.MAX_RETRIES && CONFIG.FAILOVER_ENABLED) {
                const alternateUrl = isUsingPrimary ? CONFIG.SECONDARY_API_URL : CONFIG.PRIMARY_API_URL;
                const alternateHealthy = await testEndpoint(alternateUrl);
                
                if (alternateHealthy) {
                    console.log(`🔄 Switching to ${isUsingPrimary ? 'secondary' : 'primary'} endpoint`);
                    setActiveApi(alternateUrl, !isUsingPrimary);
                }
            }
        }
    }
    
    throw lastError || new Error('Request failed after all retries');
}

// Load Users
async function loadUsers() {
    usersContainer.innerHTML = '<div class="loading">Loading users...</div>';
    
    try {
        const data = await makeApiRequest('/users');
        
        if (data.users) {
            displayUsers(data.users);
        } else {
            throw new Error('Invalid response format');
        }
    } catch (error) {
        usersContainer.innerHTML = `
            <div class="alert alert-error">
                Failed to load users: ${error.message}
                <br><small>Check console for details.</small>
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
            <button class="btn-delete" onclick="deleteUser(${user.id})" title="Delete user">
                🗑️ Delete
            </button>
        </div>
    `).join('');
    
    usersContainer.innerHTML = `<div class="users-grid">${usersHTML}</div>`;
}

// Delete User
async function deleteUser(userId) {
    if (!confirm('Are you sure you want to delete this user?')) {
        return;
    }
    
    try {
        const data = await makeApiRequest(`/users/${userId}`, {
            method: 'DELETE'
        });
        
        showAlert('User deleted successfully!', 'success');
        loadUsers(); // Refresh the list
    } catch (error) {
        showAlert(`Error deleting user: ${error.message}`, 'error');
        console.error('Delete user failed:', error);
    }
}

// Handle Create User
async function handleCreateUser(e) {
    e.preventDefault();
    
    const name = document.getElementById('name').value;
    const email = document.getElementById('email').value;
    
    try {
        const data = await makeApiRequest('/users', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ name, email })
        });
        
        if (data.user || data.message) {
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
