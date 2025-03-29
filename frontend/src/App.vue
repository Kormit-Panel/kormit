<template>
  <div class="app-container">
    <header>
      <div class="logo">
        <img src="./assets/logo.svg" alt="Kormit Logo">
        <h1>Kormit</h1>
      </div>
      <nav>
        <router-link to="/">Dashboard</router-link>
        <router-link to="/container">Container</router-link>
        <router-link to="/deployments">Deployments</router-link>
        <router-link to="/einstellungen">Einstellungen</router-link>
      </nav>
      <div class="user-info">
        <button class="theme-toggle" @click="toggleTheme">
          <span v-if="currentTheme === 'dark'">☀️</span>
          <span v-else>🌙</span>
        </button>
      </div>
    </header>
    
    <main>
      <div class="main-content">
        <router-view />
      </div>
    </main>
    
    <footer>
      <p>Kormit Admin Panel &copy; {{ currentYear }} | Version 1.0.0</p>
    </footer>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'

// Aktuelles Jahr für das Copyright
const currentYear = new Date().getFullYear()

// Theme-Verwaltung
const currentTheme = ref(
  localStorage.getItem('theme') || 
  (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light')
)

onMounted(() => {
  applyTheme(currentTheme.value)
})

function toggleTheme() {
  currentTheme.value = currentTheme.value === 'dark' ? 'light' : 'dark'
  applyTheme(currentTheme.value)
  localStorage.setItem('theme', currentTheme.value)
}

function applyTheme(theme) {
  if (theme === 'dark') {
    document.documentElement.classList.add('dark')
    document.documentElement.classList.remove('light')
  } else {
    document.documentElement.classList.add('light')
    document.documentElement.classList.remove('dark')
  }
}
</script>

<style>
/* Globale Styles */
:root {
  --header-height: 60px;
  --footer-height: 40px;
}

/* Container-Styles */
.app-container {
  display: flex;
  flex-direction: column;
  min-height: 100vh;
}

/* Header-Styles */
header {
  height: var(--header-height);
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 2rem;
  background-color: var(--color-background-soft);
  border-bottom: 1px solid var(--color-border);
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  z-index: 100;
}

.logo {
  display: flex;
  align-items: center;
}

.logo img {
  height: 32px;
  margin-right: 0.5rem;
}

.logo h1 {
  font-size: 1.5rem;
  font-weight: 600;
  margin: 0;
  color: var(--color-primary);
}

nav {
  display: flex;
  gap: 1.5rem;
}

nav a {
  text-decoration: none;
  color: var(--color-text);
  font-weight: 500;
  padding: 0.5rem 0;
  position: relative;
}

nav a:hover {
  color: var(--color-primary);
}

nav a.router-link-active {
  color: var(--color-primary);
}

nav a.router-link-active::after {
  content: '';
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  height: 2px;
  background-color: var(--color-primary);
}

.user-info {
  display: flex;
  align-items: center;
}

.theme-toggle {
  background: none;
  border: none;
  font-size: 1.2rem;
  cursor: pointer;
  padding: 0.5rem;
  display: flex;
  align-items: center;
  justify-content: center;
}

/* Main-Styles */
main {
  flex: 1;
  margin-top: var(--header-height);
  margin-bottom: var(--footer-height);
  overflow-y: auto;
}

.main-content {
  min-height: calc(100vh - var(--header-height) - var(--footer-height));
}

/* Footer-Styles */
footer {
  height: var(--footer-height);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0 2rem;
  background-color: var(--color-background-soft);
  border-top: 1px solid var(--color-border);
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
}

footer p {
  margin: 0;
  font-size: 0.9rem;
  color: var(--color-text-light, #666);
}

/* Responsive Styles */
@media (max-width: 768px) {
  header {
    flex-direction: column;
    height: auto;
    padding: 1rem;
  }
  
  .logo {
    margin-bottom: 1rem;
  }
  
  nav {
    width: 100%;
    justify-content: space-between;
    margin-bottom: 1rem;
  }
  
  main {
    margin-top: calc(var(--header-height) + 60px);
  }
}

@media (max-width: 480px) {
  nav {
    flex-direction: column;
    gap: 0.5rem;
    align-items: center;
  }
  
  main {
    margin-top: calc(var(--header-height) + 120px);
  }
}
</style>
