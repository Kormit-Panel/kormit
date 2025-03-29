<template>
  <div class="container-view">
    <h1>Container Verwaltung</h1>
    
    <div class="actions-bar">
      <button class="btn primary" @click="showCreateModal = true">
        Neuen Container erstellen
      </button>
      <button class="btn secondary" @click="refreshContainers">
        Aktualisieren
      </button>
    </div>
    
    <div v-if="isLoading" class="loading">Lade Container...</div>
    <div v-else-if="hasError" class="error-message">{{ error }}</div>
    <div v-else-if="containers.length === 0" class="empty-state">
      Keine Container gefunden. Klicken Sie auf "Neuen Container erstellen", um zu beginnen.
    </div>
    <div v-else class="container-list">
      <div class="container-card" v-for="container in containers" :key="container.id">
        <div class="container-header">
          <h3>{{ container.name }}</h3>
          <span :class="['status-badge', container.status]">{{ container.status }}</span>
        </div>
        <div class="container-details">
          <div class="detail-row">
            <span class="label">ID:</span>
            <span class="value">{{ container.id.substring(0, 12) }}</span>
          </div>
          <div class="detail-row">
            <span class="label">Image:</span>
            <span class="value">{{ container.image }}</span>
          </div>
          <div class="detail-row">
            <span class="label">Ports:</span>
            <span class="value">{{ formatPorts(container.ports) }}</span>
          </div>
          <div class="detail-row">
            <span class="label">Erstellt:</span>
            <span class="value">{{ formatDate(container.created) }}</span>
          </div>
        </div>
        <div class="container-actions">
          <button class="btn-action" 
                  :class="{ disabled: container.status === 'running' }" 
                  :disabled="container.status === 'running'"
                  @click="startContainer(container.id)">
            Start
          </button>
          <button class="btn-action" 
                  :class="{ disabled: container.status !== 'running' }"
                  :disabled="container.status !== 'running'"
                  @click="stopContainer(container.id)">
            Stop
          </button>
          <button class="btn-action" 
                  :class="{ disabled: container.status === 'running' }"
                  :disabled="container.status === 'running'"
                  @click="removeContainer(container.id)">
            Löschen
          </button>
          <button class="btn-action" @click="showLogs(container.id)">
            Logs
          </button>
        </div>
      </div>
    </div>
    
    <!-- Modal für das Erstellen eines neuen Containers -->
    <div v-if="showCreateModal" class="modal">
      <div class="modal-content">
        <div class="modal-header">
          <h2>Neuen Container erstellen</h2>
          <button class="close-btn" @click="showCreateModal = false">&times;</button>
        </div>
        <div class="modal-body">
          <form @submit.prevent="createContainer">
            <div class="form-group">
              <label for="name">Name</label>
              <input type="text" id="name" v-model="newContainer.name" required>
            </div>
            <div class="form-group">
              <label for="image">Image</label>
              <input type="text" id="image" v-model="newContainer.image" required>
            </div>
            <div class="form-group">
              <label for="ports">Ports (host:container, durch Komma getrennt)</label>
              <input type="text" id="ports" v-model="newContainer.ports" placeholder="z.B. 8080:80, 3306:3306">
            </div>
            <div class="form-group">
              <label for="env">Umgebungsvariablen (KEY=VALUE, pro Zeile)</label>
              <textarea id="env" v-model="newContainer.env" rows="3" placeholder="z.B. DB_HOST=localhost&#10;DB_PORT=3306"></textarea>
            </div>
            <div class="form-group">
              <label for="volumes">Volumes (host:container, durch Komma getrennt)</label>
              <input type="text" id="volumes" v-model="newContainer.volumes" placeholder="z.B. ./data:/app/data">
            </div>
            <div class="form-actions">
              <button type="button" class="btn secondary" @click="showCreateModal = false">Abbrechen</button>
              <button type="submit" class="btn primary">Erstellen</button>
            </div>
          </form>
        </div>
      </div>
    </div>
    
    <!-- Modal für Container-Logs -->
    <div v-if="showLogsModal" class="modal">
      <div class="modal-content logs-modal">
        <div class="modal-header">
          <h2>Container Logs</h2>
          <button class="close-btn" @click="showLogsModal = false">&times;</button>
        </div>
        <div class="modal-body">
          <div class="logs-container">
            <pre>{{ containerLogs }}</pre>
          </div>
        </div>
        <div class="modal-footer">
          <button class="btn secondary" @click="showLogsModal = false">Schließen</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useAppStore } from '../stores'
import axios from 'axios'

const store = useAppStore()
const isLoading = computed(() => store.isLoading)
const hasError = computed(() => store.hasError)
const error = computed(() => store.error)
const containers = computed(() => store.containers)

const showCreateModal = ref(false)
const showLogsModal = ref(false)
const containerLogs = ref('')
const newContainer = ref({
  name: '',
  image: '',
  ports: '',
  env: '',
  volumes: ''
})

onMounted(() => {
  refreshContainers()
})

async function refreshContainers() {
  await store.fetchContainers()
}

async function startContainer(id) {
  try {
    await axios.post(`/api/containers/${id}/start`)
    await refreshContainers()
  } catch (error) {
    console.error('Fehler beim Starten des Containers:', error)
    alert('Der Container konnte nicht gestartet werden: ' + error.message)
  }
}

async function stopContainer(id) {
  try {
    await axios.post(`/api/containers/${id}/stop`)
    await refreshContainers()
  } catch (error) {
    console.error('Fehler beim Stoppen des Containers:', error)
    alert('Der Container konnte nicht gestoppt werden: ' + error.message)
  }
}

async function removeContainer(id) {
  if (!confirm('Sind Sie sicher, dass Sie diesen Container löschen möchten?')) {
    return
  }
  
  try {
    await axios.delete(`/api/containers/${id}`)
    await refreshContainers()
  } catch (error) {
    console.error('Fehler beim Löschen des Containers:', error)
    alert('Der Container konnte nicht gelöscht werden: ' + error.message)
  }
}

async function showLogs(id) {
  try {
    containerLogs.value = 'Lade Logs...'
    showLogsModal.value = true
    
    const response = await axios.get(`/api/containers/${id}/logs`)
    containerLogs.value = response.data
  } catch (error) {
    console.error('Fehler beim Laden der Container-Logs:', error)
    containerLogs.value = 'Fehler beim Laden der Logs: ' + error.message
  }
}

async function createContainer() {
  try {
    const payload = {
      name: newContainer.value.name,
      image: newContainer.value.image,
      ports: newContainer.value.ports ? newContainer.value.ports.split(',').map(p => p.trim()) : [],
      env: newContainer.value.env ? newContainer.value.env.split('\n').map(e => e.trim()).filter(e => e) : [],
      volumes: newContainer.value.volumes ? newContainer.value.volumes.split(',').map(v => v.trim()) : []
    }
    
    await axios.post('/api/containers', payload)
    
    showCreateModal.value = false
    newContainer.value = {
      name: '',
      image: '',
      ports: '',
      env: '',
      volumes: ''
    }
    
    await refreshContainers()
  } catch (error) {
    console.error('Fehler beim Erstellen des Containers:', error)
    alert('Der Container konnte nicht erstellt werden: ' + error.message)
  }
}

function formatPorts(ports) {
  if (!ports || ports.length === 0) {
    return '-'
  }
  return ports.join(', ')
}

function formatDate(timestamp) {
  return new Date(timestamp).toLocaleString('de-DE')
}
</script>

<style scoped>
.container-view {
  padding: 2rem;
}

h1 {
  margin-bottom: 2rem;
  color: var(--color-primary);
}

.actions-bar {
  display: flex;
  gap: 1rem;
  margin-bottom: 2rem;
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

.loading, .error-message, .empty-state {
  padding: 2rem;
  text-align: center;
  background-color: var(--color-background-soft);
  border-radius: 8px;
  margin-bottom: 2rem;
}

.error-message {
  color: #e74c3c;
}

.container-list {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
  gap: 1.5rem;
}

.container-card {
  background-color: var(--color-background-soft);
  border-radius: 8px;
  padding: 1.5rem;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.1);
}

.container-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
  padding-bottom: 0.5rem;
  border-bottom: 1px solid var(--color-border);
}

.container-header h3 {
  margin: 0;
  color: var(--color-text);
}

.status-badge {
  padding: 0.25rem 0.5rem;
  border-radius: 12px;
  font-size: 0.8rem;
  font-weight: 500;
}

.status-badge.running {
  background-color: #2ecc71;
  color: white;
}

.status-badge.stopped {
  background-color: #e74c3c;
  color: white;
}

.status-badge.paused {
  background-color: #f39c12;
  color: white;
}

.container-details {
  margin-bottom: 1rem;
}

.detail-row {
  display: flex;
  margin-bottom: 0.5rem;
}

.detail-row .label {
  flex: 0 0 80px;
  font-weight: 500;
  color: var(--color-text-light, #666);
}

.detail-row .value {
  flex: 1;
  word-break: break-all;
}

.container-actions {
  display: flex;
  gap: 0.5rem;
  margin-top: 1rem;
  flex-wrap: wrap;
}

.btn-action {
  padding: 0.4rem 0.8rem;
  border-radius: 4px;
  font-size: 0.9rem;
  background-color: #f0f0f0;
  border: 1px solid #ddd;
  cursor: pointer;
  transition: background-color 0.3s;
}

.btn-action:hover:not(.disabled) {
  background-color: #e0e0e0;
}

.btn-action.disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.modal {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: rgba(0, 0, 0, 0.5);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 1000;
}

.modal-content {
  background-color: var(--color-background);
  border-radius: 8px;
  width: 600px;
  max-width: 90%;
  max-height: 90vh;
  display: flex;
  flex-direction: column;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.2);
}

.logs-modal {
  width: 800px;
  height: 600px;
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1.5rem;
  border-bottom: 1px solid var(--color-border);
}

.modal-header h2 {
  margin: 0;
  color: var(--color-text);
}

.close-btn {
  background: none;
  border: none;
  font-size: 1.5rem;
  cursor: pointer;
  color: var(--color-text-light, #666);
}

.modal-body {
  padding: 1.5rem;
  overflow-y: auto;
  flex: 1;
}

.logs-container {
  background-color: #1e1e1e;
  color: #f0f0f0;
  padding: 1rem;
  border-radius: 4px;
  font-family: monospace;
  height: 100%;
  overflow: auto;
}

.logs-container pre {
  margin: 0;
  white-space: pre-wrap;
  word-break: break-all;
}

.modal-footer {
  padding: 1rem 1.5rem;
  display: flex;
  justify-content: flex-end;
  border-top: 1px solid var(--color-border);
}

.form-group {
  margin-bottom: 1.5rem;
}

.form-group label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: 500;
}

.form-group input,
.form-group textarea {
  width: 100%;
  padding: 0.6rem;
  border: 1px solid var(--color-border);
  border-radius: 4px;
  background-color: var(--color-background);
  color: var(--color-text);
}

.form-actions {
  display: flex;
  justify-content: flex-end;
  gap: 1rem;
  margin-top: 1.5rem;
}
</style> 