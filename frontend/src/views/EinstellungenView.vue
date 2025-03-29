<template>
  <div class="settings-view">
    <h1>Einstellungen</h1>
    
    <div class="settings-container">
      <div v-if="isLoading" class="loading">Lade Einstellungen...</div>
      <div v-else-if="hasError" class="error-message">{{ error }}</div>
      <div v-else class="settings-form">
        <form @submit.prevent="saveSettings">
          <div class="settings-section">
            <h2>Allgemeine Einstellungen</h2>
            <div class="form-group">
              <label for="app-name">Anwendungsname</label>
              <input type="text" id="app-name" v-model="settings.appName">
            </div>
            <div class="form-group">
              <label for="default-namespace">Standard-Namespace</label>
              <input type="text" id="default-namespace" v-model="settings.defaultNamespace">
            </div>
          </div>
          
          <div class="settings-section">
            <h2>API-Verbindung</h2>
            <div class="form-group">
              <label for="api-url">API URL</label>
              <input type="text" id="api-url" v-model="settings.apiUrl">
            </div>
            <div class="form-group">
              <label for="api-timeout">API-Timeout (Sekunden)</label>
              <input type="number" id="api-timeout" v-model.number="settings.apiTimeout" min="1">
            </div>
          </div>
          
          <div class="settings-section">
            <h2>Benachrichtigungen</h2>
            <div class="form-group checkbox">
              <input type="checkbox" id="enable-notifications" v-model="settings.enableNotifications">
              <label for="enable-notifications">Benachrichtigungen aktivieren</label>
            </div>
            <div class="form-group" v-if="settings.enableNotifications">
              <label for="notification-email">E-Mail-Adresse</label>
              <input type="email" id="notification-email" v-model="settings.notificationEmail">
            </div>
            <div class="form-group checkbox" v-if="settings.enableNotifications">
              <input type="checkbox" id="notify-on-error" v-model="settings.notifyOnError">
              <label for="notify-on-error">Bei Fehlern benachrichtigen</label>
            </div>
            <div class="form-group checkbox" v-if="settings.enableNotifications">
              <input type="checkbox" id="notify-on-deployment" v-model="settings.notifyOnDeployment">
              <label for="notify-on-deployment">Bei Deployments benachrichtigen</label>
            </div>
          </div>
          
          <div class="settings-section">
            <h2>Anzeige</h2>
            <div class="form-group">
              <label for="theme">Design</label>
              <select id="theme" v-model="settings.theme">
                <option value="system">Systemeinstellung</option>
                <option value="light">Hell</option>
                <option value="dark">Dunkel</option>
              </select>
            </div>
            <div class="form-group">
              <label for="items-per-page">Elemente pro Seite</label>
              <select id="items-per-page" v-model.number="settings.itemsPerPage">
                <option value="10">10</option>
                <option value="20">20</option>
                <option value="50">50</option>
                <option value="100">100</option>
              </select>
            </div>
          </div>
          
          <div class="form-actions">
            <button type="button" class="btn secondary" @click="resetSettings">Zurücksetzen</button>
            <button type="submit" class="btn primary">Speichern</button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import axios from 'axios'

const isLoading = ref(false)
const hasError = ref(false)
const error = ref(null)
const originalSettings = ref({})

// Standard-Einstellungen
const defaultSettings = {
  appName: 'Kormit Admin',
  defaultNamespace: 'default',
  apiUrl: 'http://localhost:8080',
  apiTimeout: 30,
  enableNotifications: false,
  notificationEmail: '',
  notifyOnError: true,
  notifyOnDeployment: false,
  theme: 'system',
  itemsPerPage: 20
}

const settings = ref({...defaultSettings})

onMounted(async () => {
  await loadSettings()
})

async function loadSettings() {
  isLoading.value = true
  hasError.value = false
  error.value = null
  
  try {
    // Versuch, Einstellungen vom Server zu laden
    const response = await axios.get('/api/settings')
    
    // Server-Einstellungen mit Standardwerten zusammenführen
    const loadedSettings = {
      ...defaultSettings,
      ...response.data
    }
    
    settings.value = loadedSettings
    originalSettings.value = JSON.parse(JSON.stringify(loadedSettings))
    
    // Theme anwenden
    applyTheme(settings.value.theme)
  } catch (err) {
    console.error('Fehler beim Laden der Einstellungen:', err)
    
    // Wenn der Server keine Einstellungen bereitstellt, verwende die Standard-Einstellungen
    if (err.response && err.response.status === 404) {
      settings.value = {...defaultSettings}
      originalSettings.value = {...defaultSettings}
    } else {
      hasError.value = true
      error.value = 'Einstellungen konnten nicht geladen werden: ' + err.message
    }
  } finally {
    isLoading.value = false
  }
}

async function saveSettings() {
  isLoading.value = true
  hasError.value = false
  error.value = null
  
  try {
    await axios.post('/api/settings', settings.value)
    originalSettings.value = JSON.parse(JSON.stringify(settings.value))
    applyTheme(settings.value.theme)
    alert('Einstellungen wurden erfolgreich gespeichert.')
  } catch (err) {
    console.error('Fehler beim Speichern der Einstellungen:', err)
    hasError.value = true
    error.value = 'Einstellungen konnten nicht gespeichert werden: ' + err.message
  } finally {
    isLoading.value = false
  }
}

function resetSettings() {
  if (confirm('Möchten Sie wirklich alle Einstellungen auf die Standardwerte zurücksetzen?')) {
    settings.value = {...defaultSettings}
  }
}

function applyTheme(theme) {
  if (theme === 'system') {
    // Entferne explizite Klassen und lasse das System entscheiden
    document.documentElement.classList.remove('dark', 'light')
  } else {
    // Setze das Theme explizit
    document.documentElement.classList.remove('dark', 'light')
    document.documentElement.classList.add(theme)
  }
}
</script>

<style scoped>
.settings-view {
  padding: 2rem;
}

h1 {
  margin-bottom: 2rem;
  color: var(--color-primary);
}

h2 {
  margin-top: 0;
  margin-bottom: 1.5rem;
  color: var(--color-text);
  font-size: 1.5rem;
}

.settings-container {
  max-width: 800px;
  margin: 0 auto;
}

.loading, .error-message {
  padding: 2rem;
  text-align: center;
  background-color: var(--color-background-soft);
  border-radius: 8px;
  margin-bottom: 2rem;
}

.error-message {
  color: #e74c3c;
}

.settings-form {
  background-color: var(--color-background-soft);
  border-radius: 8px;
  padding: 2rem;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.1);
}

.settings-section {
  margin-bottom: 2.5rem;
  padding-bottom: 2rem;
  border-bottom: 1px solid var(--color-border);
}

.settings-section:last-of-type {
  border-bottom: none;
  margin-bottom: 1.5rem;
  padding-bottom: 0;
}

.form-group {
  margin-bottom: 1.5rem;
}

.form-group label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: 500;
}

.form-group.checkbox {
  display: flex;
  align-items: center;
}

.form-group.checkbox label {
  margin-bottom: 0;
  margin-left: 0.5rem;
}

.form-group input[type="text"],
.form-group input[type="email"],
.form-group input[type="number"],
.form-group select {
  width: 100%;
  padding: 0.6rem;
  border: 1px solid var(--color-border);
  border-radius: 4px;
  background-color: var(--color-background);
  color: var(--color-text);
}

.form-group select {
  appearance: none;
  background-image: url("data:image/svg+xml;charset=utf-8,%3Csvg xmlns='http://www.w3.org/2000/svg' width='16' height='16' viewBox='0 0 24 24' fill='none' stroke='%23999' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpath d='M6 9l6 6 6-6'/%3E%3C/svg%3E");
  background-repeat: no-repeat;
  background-position: right 0.7rem center;
  background-size: 1em;
  padding-right: 2.5rem;
}

.form-actions {
  display: flex;
  justify-content: flex-end;
  gap: 1rem;
  margin-top: 2rem;
}

.btn {
  padding: 0.6rem 1.2rem;
  border-radius: 4px;
  font-weight: 500;
  cursor: pointer;
  border: none;
  transition: background-color 0.3s;
}

.btn.primary {
  background-color: var(--color-primary);
  color: white;
}

.btn.primary:hover {
  background-color: var(--color-primary-dark, #3a9776);
}

.btn.secondary {
  background-color: #e0e0e0;
  color: #333;
}

.btn.secondary:hover {
  background-color: #c0c0c0;
}
</style>