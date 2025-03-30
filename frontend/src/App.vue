<template>
  <div class="app" :class="{ 'light-mode': !darkMode }">
    <!-- Sidebar -->
    <div class="sidebar" :class="{ 'collapsed': sidebarCollapsed }">
      <div class="logo-container">
        <div class="logo" v-if="!sidebarCollapsed">
          <img src="./assets/logo.png" alt="Kormit Logo" class="logo-img" />
          <span>Kormit</span>
        </div>
        <button class="toggle-sidebar" @click="toggleSidebar">
          <i class="material-icons">{{ sidebarCollapsed ? 'menu' : 'menu_open' }}</i>
        </button>
      </div>
      <nav class="nav-menu">
        <router-link to="/" class="nav-item" title="Dashboard">
          <i class="material-icons">dashboard</i>
          <span v-if="!sidebarCollapsed">Dashboard</span>
        </router-link>
        <router-link to="/servers" class="nav-item" title="Server Management">
          <i class="material-icons">dns</i>
          <span v-if="!sidebarCollapsed">Server Management</span>
        </router-link>
        <router-link to="/docker" class="nav-item" title="Docker Containers">
          <i class="material-icons">storage</i>
          <span v-if="!sidebarCollapsed">Docker Containers</span>
        </router-link>
        <router-link to="/users" class="nav-item" title="User Administration">
          <i class="material-icons">people</i>
          <span v-if="!sidebarCollapsed">User Administration</span>
        </router-link>
        <router-link to="/backups" class="nav-item" title="Backups">
          <i class="material-icons">backup</i>
          <span v-if="!sidebarCollapsed">Backups</span>
        </router-link>
        <router-link to="/logs" class="nav-item" title="System Logs">
          <i class="material-icons">receipt_long</i>
          <span v-if="!sidebarCollapsed">System Logs</span>
        </router-link>
        <router-link to="/settings" class="nav-item" title="Settings">
          <i class="material-icons">settings</i>
          <span v-if="!sidebarCollapsed">Settings</span>
        </router-link>
      </nav>
      <div class="sidebar-footer">
        <router-link to="/help" class="nav-item" title="Help">
          <i class="material-icons">help</i>
          <span v-if="!sidebarCollapsed">Help</span>
        </router-link>
        <div class="app-version" v-if="!sidebarCollapsed">
          <span>Version 1.0.0</span>
        </div>
      </div>
    </div>

    <!-- Main Content -->
    <div class="main-content">
      <!-- Top Navigation Bar -->
      <header class="top-bar">
        <div class="page-title">
          <h1>{{ currentRouteName }}</h1>
        </div>
        <div class="top-bar-actions">
          <div class="search-container">
            <i class="material-icons">search</i>
            <input type="text" placeholder="Suchen..." class="search-input" />
          </div>
          <button class="icon-button" title="Notifications">
            <i class="material-icons">notifications</i>
            <span class="badge">3</span>
          </button>
          <button class="icon-button" @click="toggleDarkMode" title="Theme wechseln">
            <i class="material-icons">{{ darkMode ? 'light_mode' : 'dark_mode' }}</i>
          </button>
          <div class="user-profile">
            <img src="https://via.placeholder.com/36" alt="Profile" class="avatar" />
            <span class="username" v-if="!isMobile">Admin</span>
          </div>
        </div>
      </header>

      <!-- Router View for Dynamic Content -->
      <main class="dashboard-container">
        <transition name="fade" mode="out-in">
          <router-view />
        </transition>
      </main>

      <!-- Footer -->
      <footer class="footer">
        <p>&copy; 2025 Kormit Panel. <a href="https://github.com/Kormit-Panel/kormit" target="_blank">MIT License</a></p>
      </footer>
    </div>
  </div>
</template>

<script>
export default {
  name: 'App',
  data() {
    return {
      darkMode: true,
      sidebarCollapsed: false,
      isMobile: false,
    };
  },
  computed: {
    currentRouteName() {
      const routeName = this.$route.name;
      return routeName ? routeName : 'Dashboard';
    }
  },
  watch: {
    $route() {
      // Auto collapse sidebar on mobile when route changes
      if (this.isMobile) {
        this.sidebarCollapsed = true;
      }
      // Scroll to top when route changes
      window.scrollTo(0, 0);
    }
  },
  mounted() {
    // Check if mobile on mount
    this.checkIfMobile();
    // Add event listener for resize
    window.addEventListener('resize', this.checkIfMobile);
  },
  beforeUnmount() {
    // Remove event listener on component destroy
    window.removeEventListener('resize', this.checkIfMobile);
  },
  methods: {
    toggleDarkMode() {
      this.darkMode = !this.darkMode;
      // Save preference to localStorage
      localStorage.setItem('darkMode', this.darkMode);
    },
    toggleSidebar() {
      this.sidebarCollapsed = !this.sidebarCollapsed;
    },
    checkIfMobile() {
      this.isMobile = window.innerWidth < 768;
      // Auto-collapse sidebar on mobile
      if (this.isMobile && !this.sidebarCollapsed) {
        this.sidebarCollapsed = true;
      }
    }
  },
  created() {
    // Load dark mode preference from localStorage
    const savedDarkMode = localStorage.getItem('darkMode');
    if (savedDarkMode !== null) {
      this.darkMode = savedDarkMode === 'true';
    }
  }
};
</script>

<style>
/* Import Google Material Icons */
@import url('https://fonts.googleapis.com/icon?family=Material+Icons');
@import url('https://fonts.googleapis.com/css2?family=Roboto:wght@300;400;500;700&display=swap');

/* CSS Variables for theming */
:root {
  /* Dark Mode - Default */
  --primary-color: #1976D2;
  --primary-dark: #0D47A1;
  --primary-light: #64B5F6;
  --accent-color: #2196F3;
  --text-color: #FFFFFF;
  --text-secondary: #B0BEC5;
  --background-color: #121212;
  --surface-color: #1E1E1E;
  --card-color: #252525;
  --border-color: #333333;
  --success-color: #4CAF50;
  --error-color: #F44336;
  --warning-color: #FFC107;
  --shadow-color: rgba(0, 0, 0, 0.2);
  
  /* Animation Duration */
  --transition-speed: 0.3s;
}

/* Light Mode Variables */
.light-mode {
  --primary-color: #1976D2;
  --primary-dark: #0D47A1;
  --primary-light: #64B5F6;
  --accent-color: #2196F3;
  --text-color: #212121;
  --text-secondary: #757575;
  --background-color: #F5F5F5;
  --surface-color: #FFFFFF;
  --card-color: #FFFFFF;
  --border-color: #E0E0E0;
  --shadow-color: rgba(0, 0, 0, 0.1);
}

/* Global Reset */
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: 'Roboto', sans-serif;
  font-size: 16px;
  line-height: 1.5;
  color: var(--text-color);
  background-color: var(--background-color);
  transition: background-color var(--transition-speed) ease;
}

/* App Container */
.app {
  display: flex;
  height: 100vh;
  overflow: hidden;
  background-color: var(--background-color);
  color: var(--text-color);
  transition: background-color var(--transition-speed) ease, color var(--transition-speed) ease;
}

/* Sidebar Styles */
.sidebar {
  width: 240px;
  height: 100%;
  background-color: var(--surface-color);
  border-right: 1px solid var(--border-color);
  display: flex;
  flex-direction: column;
  transition: width var(--transition-speed) ease, transform var(--transition-speed) ease;
  z-index: 10;
}

.sidebar.collapsed {
  width: 60px;
}

.logo-container {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px;
  height: 64px;
  border-bottom: 1px solid var(--border-color);
}

.logo {
  display: flex;
  align-items: center;
  font-size: 20px;
  font-weight: 700;
  color: var(--primary-light);
}

.logo-img {
  height: 28px;
  margin-right: 10px;
}

.toggle-sidebar {
  background: transparent;
  border: none;
  color: var(--text-color);
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 8px;
  border-radius: 50%;
  transition: background-color var(--transition-speed) ease;
}

.toggle-sidebar:hover {
  background-color: rgba(255, 255, 255, 0.1);
}

.nav-menu {
  flex: 1;
  padding: 16px 0;
  overflow-y: auto;
}

.nav-item {
  display: flex;
  align-items: center;
  padding: 12px 16px;
  color: var(--text-secondary);
  text-decoration: none;
  border-radius: 8px;
  margin: 4px 8px;
  transition: background-color var(--transition-speed) ease, color var(--transition-speed) ease;
}

.nav-item:hover, .nav-item.router-link-active {
  background-color: rgba(33, 150, 243, 0.1);
  color: var(--primary-light);
}

.nav-item i {
  margin-right: 16px;
}

.sidebar.collapsed .nav-item {
  justify-content: center;
  padding: 12px 0;
}

.sidebar.collapsed .nav-item i {
  margin-right: 0;
}

.sidebar-footer {
  padding: 16px 0;
  border-top: 1px solid var(--border-color);
}

.app-version {
  text-align: center;
  padding: 10px 0;
  font-size: 12px;
  color: var(--text-secondary);
}

/* Main Content Styles */
.main-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  overflow-x: hidden;
}

/* Top Bar Styles */
.top-bar {
  height: 64px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 24px;
  background-color: var(--surface-color);
  border-bottom: 1px solid var(--border-color);
}

.page-title h1 {
  font-size: 20px;
  font-weight: 500;
}

.top-bar-actions {
  display: flex;
  align-items: center;
  gap: 16px;
}

.search-container {
  display: flex;
  align-items: center;
  background-color: rgba(255, 255, 255, 0.05);
  border-radius: 20px;
  padding: 0 16px;
  height: 40px;
  transition: background-color var(--transition-speed) ease;
}

.light-mode .search-container {
  background-color: rgba(0, 0, 0, 0.05);
}

.search-container i {
  margin-right: 8px;
  color: var(--text-secondary);
}

.search-input {
  background: transparent;
  border: none;
  color: var(--text-color);
  outline: none;
  width: 200px;
}

.search-input::placeholder {
  color: var(--text-secondary);
}

.icon-button {
  background: transparent;
  border: none;
  color: var(--text-color);
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 40px;
  height: 40px;
  border-radius: 50%;
  position: relative;
  transition: background-color var(--transition-speed) ease;
}

.icon-button:hover {
  background-color: rgba(255, 255, 255, 0.05);
}

.light-mode .icon-button:hover {
  background-color: rgba(0, 0, 0, 0.05);
}

.icon-button.small {
  width: 32px;
  height: 32px;
}

.badge {
  position: absolute;
  top: 0;
  right: 0;
  background-color: var(--error-color);
  color: white;
  font-size: 10px;
  font-weight: 700;
  width: 16px;
  height: 16px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
}

.user-profile {
  display: flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
  padding: 4px;
  border-radius: 24px;
  transition: background-color var(--transition-speed) ease;
}

.user-profile:hover {
  background-color: rgba(255, 255, 255, 0.05);
}

.light-mode .user-profile:hover {
  background-color: rgba(0, 0, 0, 0.05);
}

.avatar {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  object-fit: cover;
}

.username {
  font-weight: 500;
}

/* Dashboard Container Styles */
.dashboard-container {
  flex: 1;
  padding: 24px;
  overflow-y: auto;
  background-color: var(--background-color);
}

.dashboard-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 24px;
}

/* Card Styles */
.card {
  background-color: var(--card-color);
  border-radius: 12px;
  box-shadow: 0 2px 4px var(--shadow-color);
  overflow: hidden;
  transition: transform var(--transition-speed) ease, box-shadow var(--transition-speed) ease;
}

.card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 8px var(--shadow-color);
}

.card.wide {
  grid-column: span 2;
}

.card-header {
  padding: 16px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  border-bottom: 1px solid var(--border-color);
}

.card-header h3 {
  font-size: 16px;
  font-weight: 500;
}

.card-icon {
  color: var(--primary-light);
}

.card-actions {
  display: flex;
  align-items: center;
  gap: 8px;
}

.card-content {
  padding: 16px;
}

/* Button Styles */
.btn {
  background-color: var(--primary-color);
  color: white;
  border: none;
  padding: 8px 16px;
  border-radius: 20px;
  font-size: 14px;
  cursor: pointer;
  transition: background-color var(--transition-speed) ease;
}

.btn:hover {
  background-color: var(--primary-dark);
}

.btn-outline {
  background: transparent;
  border: 1px solid var(--primary-light);
  color: var(--primary-light);
  padding: 6px 12px;
  border-radius: 20px;
  font-size: 14px;
  cursor: pointer;
  transition: background-color var(--transition-speed) ease, color var(--transition-speed) ease;
}

.btn-outline:hover {
  background-color: var(--primary-light);
  color: white;
}

/* Footer Styles */
.footer {
  padding: 16px 24px;
  background-color: var(--surface-color);
  border-top: 1px solid var(--border-color);
  font-size: 14px;
  color: var(--text-secondary);
  text-align: center;
}

.footer a {
  color: var(--primary-light);
  text-decoration: none;
}

.footer a:hover {
  text-decoration: underline;
}

/* Animations */
.fade-enter-active, .fade-leave-active {
  transition: opacity var(--transition-speed) ease, transform var(--transition-speed) ease;
}

.fade-enter-from, .fade-leave-to {
  opacity: 0;
  transform: translateY(10px);
}

/* Responsive Styles */
@media (max-width: 1024px) {
  .dashboard-grid {
    grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
  }
  
  .card.wide {
    grid-column: auto;
  }
  
  .search-container {
    display: none;
  }
}

@media (max-width: 768px) {
  .sidebar {
    position: fixed;
    transform: translateX(0);
  }
  
  .sidebar.collapsed {
    transform: translateX(-100%);
    width: 240px;
  }
  
  .toggle-sidebar {
    position: fixed;
    top: 12px;
    left: 12px;
    z-index: 20;
    background-color: var(--surface-color);
    box-shadow: 0 2px 4px var(--shadow-color);
  }
  
  .top-bar {
    padding-left: 64px;
  }
}

@media (max-width: 480px) {
  .top-bar {
    padding: 0 16px 0 64px;
  }
  
  .dashboard-container {
    padding: 16px;
  }
}
</style>