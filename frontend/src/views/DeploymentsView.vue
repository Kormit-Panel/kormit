<template>
  <div class="deployments-view">
    <h1>Deployment Verwaltung</h1>
    
    <div class="actions-bar">
      <button class="btn primary" @click="showCreateModal = true">
        Neues Deployment erstellen
      </button>
      <button class="btn secondary" @click="refreshDeployments">
        Aktualisieren
      </button>
    </div>
    
    <div v-if="isLoading" class="loading">Lade Deployments...</div>
    <div v-else-if="hasError" class="error-message">{{ error }}</div>
    <div v-else-if="deployments.length === 0" class="empty-state">
      Keine Deployments gefunden. Klicken Sie auf "Neues Deployment erstellen", um zu beginnen.
    </div>
    <div v-else class="deployments-list">
      <div class="deployment-card" v-for="deployment in deployments" :key="deployment.id">
        <div class="deployment-header">
          <h3>{{ deployment.name }}</h3>
          <span :class="['status-badge', deployment.status]">{{ deployment.status }}</span>
        </div>
        <div class="deployment-details">
          <div class="detail-row">
            <span class="label">ID:</span>
            <span class="value">{{ deployment.id.substring(0, 12) }}</span>
          </div>
          <div class="detail-row">
            <span class="label">Namespace:</span>
            <span class="value">{{ deployment.namespace || 'default' }}</span>
          </div>
          <div class="detail-row">
            <span class="label">Replicas:</span>
            <span class="value">{{ deployment.replicas }} / {{ deployment.desiredReplicas }}</span>
          </div>
          <div class="detail-row">
            <span class="label">Erstellt:</span>
            <span class="value">{{ formatDate(deployment.createdAt) }}</span>
          </div>
        </div>
        <div class="deployment-actions">
          <button class="btn-action" @click="scaleDeployment(deployment.id)">
            Skalieren
          </button>
          <button class="btn-action" @click="restartDeployment(deployment.id)">
            Neustart
          </button>
          <button class="btn-action" 
                  :class="{ disabled: deployment.status === 'active' }"
                  :disabled="deployment.status === 'active'"
                  @click="activateDeployment(deployment.id)">
            Aktivieren
          </button>
          <button class="btn-action" @click="deleteDeployment(deployment.id)">
            Löschen
          </button>
        </div>
      </div>
    </div>
    
    <!-- Modal für das Erstellen eines neuen Deployments -->
    <div v-if="showCreateModal" class="modal">
      <div class="modal-content">
        <div class="modal-header">
          <h2>Neues Deployment erstellen</h2>
          <button class="close-btn" @click="showCreateModal = false">&times;</button>
        </div>
        <div class="modal-body">
          <form @submit.prevent="createDeployment">
            <div class="form-group">
              <label for="name">Name</label>
              <input type="text" id="name" v-model="newDeployment.name" required>
            </div>
            <div class="form-group">
              <label for="namespace">Namespace</label>
              <input type="text" id="namespace" v-model="newDeployment.namespace" placeholder="default">
            </div>
            <div class="form-group">
              <label for="image">Container Image</label>
              <input type="text" id="image" v-model="newDeployment.image" required>
            </div>
            <div class="form-group">
              <label for="replicas">Anzahl der Replicas</label>
              <input type="number" id="replicas" v-model.number="newDeployment.replicas" min="1" required>
            </div>
            <div class="form-group">
              <label for="ports">Ports (durch Komma getrennt)</label>
              <input type="text" id="ports" v-model="newDeployment.ports" placeholder="z.B. 80, 443">
            </div>
            <div class="form-group">
              <label for="env">Umgebungsvariablen (KEY=VALUE, pro Zeile)</label>
              <textarea id="env" v-model="newDeployment.env" rows="3" placeholder="z.B. DB_HOST=localhost&#10;DB_PORT=3306"></textarea>
            </div>
            <div class="form-actions">
              <button type="button" class="btn secondary" @click="showCreateModal = false">Abbrechen</button>
              <button type="submit" class="btn primary">Erstellen</button>
            </div>
          </form>
        </div>
      </div>
    </div>
    
    <!-- Modal für das Skalieren eines Deployments -->
    <div v-if="showScaleModal" class="modal">
      <div class="modal-content">
        <div class="modal-header">
          <h2>Deployment skalieren</h2>
          <button class="close-btn" @click="showScaleModal = false">&times;</button>
        </div>
        <div class="modal-body">
          <form @submit.prevent="scaleConfirm">
            <div class="form-group">
              <label for="replicas">Anzahl der Replicas</label>
              <input type="number" id="replicas" v-model.number="scaleReplicas" min="0" required>
            </div>
            <div class="form-actions">
              <button type="button" class="btn secondary" @click="showScaleModal = false">Abbrechen</button>
              <button type="submit" class="btn primary">Skalieren</button>
            </div>
          </form>
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
const deployments = computed(() => store.deployments)

const showCreateModal = ref(false)
const showScaleModal = ref(false)
const currentDeploymentId = ref(null)
const scaleReplicas = ref(1)
const newDeployment = ref({
  name: '',
  namespace: '',
  image: '',
  replicas: 1,
  ports: '',
  env: ''
})

onMounted(() => {
  refreshDeployments()
})

async function refreshDeployments() {
  await store.fetchDeployments()
}

function scaleDeployment(id) {
  currentDeploymentId.value = id
  const deployment = deployments.value.find(d => d.id === id)
  scaleReplicas.value = deployment.desiredReplicas
  showScaleModal.value = true
}

async function scaleConfirm() {
  try {
    await axios.post(`/api/deployments/${currentDeploymentId.value}/scale`, {
      replicas: scaleReplicas.value
    })
    
    showScaleModal.value = false
    await refreshDeployments()
  } catch (error) {
    console.error('Fehler beim Skalieren des Deployments:', error)
    alert('Das Deployment konnte nicht skaliert werden: ' + error.message)
  }
}

async function restartDeployment(id) {
  if (!confirm('Sind Sie sicher, dass Sie dieses Deployment neu starten möchten?')) {
    return
  }
  
  try {
    await axios.post(`/api/deployments/${id}/restart`)
    await refreshDeployments()
  } catch (error) {
    console.error('Fehler beim Neustarten des Deployments:', error)
    alert('Das Deployment konnte nicht neu gestartet werden: ' + error.message)
  }
}

async function activateDeployment(id) {
  try {
    await axios.post(`/api/deployments/${id}/activate`)
    await refreshDeployments()
  } catch (error) {
    console.error('Fehler beim Aktivieren des Deployments:', error)
    alert('Das Deployment konnte nicht aktiviert werden: ' + error.message)
  }
}

async function deleteDeployment(id) {
  if (!confirm('Sind Sie sicher, dass Sie dieses Deployment löschen möchten?')) {
    return
  }
  
  try {
    await axios.delete(`/api/deployments/${id}`)
    await refreshDeployments()
  } catch (error) {
    console.error('Fehler beim Löschen des Deployments:', error)
    alert('Das Deployment konnte nicht gelöscht werden: ' + error.message)
  }
}

async function createDeployment() {
  try {
    const payload = {
      name: newDeployment.value.name,
      namespace: newDeployment.value.namespace || 'default',
      image: newDeployment.value.image,
      replicas: newDeployment.value.replicas,
      ports: newDeployment.value.ports ? newDeployment.value.ports.split(',').map(p => parseInt(p.trim())) : [],
      env: newDeployment.value.env ? newDeployment.value.env.split('\n').map(e => e.trim()).filter(e => e) : []
    }
    
    await axios.post('/api/deployments', payload)
    
    showCreateModal.value = false
    newDeployment.value = {
      name: '',
      namespace: '',
      image: '',
      replicas: 1,
      ports: '',
      env: ''
    }
    
    await refreshDeployments()
  } catch (error) {
    console.error('Fehler beim Erstellen des Deployments:', error)
    alert('Das Deployment konnte nicht erstellt werden: ' + error.message)
  }
}

function formatDate(timestamp) {
  return new Date(timestamp).toLocaleString('de-DE')
}
</script>

<style scoped>
.deployments-view {
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

.deployments-list {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
  gap: 1.5rem;
}

.deployment-card {
  background-color: var(--color-background-soft);
  border-radius: 8px;
  padding: 1.5rem;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.1);
}

.deployment-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
  padding-bottom: 0.5rem;
  border-bottom: 1px solid var(--color-border);
}

.deployment-header h3 {
  margin: 0;
  color: var(--color-text);
}

.status-badge {
  padding: 0.25rem 0.5rem;
  border-radius: 12px;
  font-size: 0.8rem;
  font-weight: 500;
}

.status-badge.active {
  background-color: #2ecc71;
  color: white;
}

.status-badge.failed {
  background-color: #e74c3c;
  color: white;
}

.status-badge.pending {
  background-color: #f39c12;
  color: white;
}

.deployment-details {
  margin-bottom: 1rem;
}

.detail-row {
  display: flex;
  margin-bottom: 0.5rem;
}

.detail-row .label {
  flex: 0 0 100px;
  font-weight: 500;
  color: var(--color-text-light, #666);
}

.detail-row .value {
  flex: 1;
  word-break: break-all;
}

.deployment-actions {
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