<template>
  <main>
    <div class="dashboard">
      <h1>Kormit Admin Dashboard</h1>
      
      <div class="status-overview">
        <div class="status-card">
          <h2>Container</h2>
          <div class="status-count">{{ containerCount }}</div>
          <div class="status-actions">
            <router-link to="/container" class="btn">Verwalten</router-link>
          </div>
        </div>
        
        <div class="status-card">
          <h2>Deployments</h2>
          <div class="status-count">{{ deploymentCount }}</div>
          <div class="status-actions">
            <router-link to="/deployments" class="btn">Verwalten</router-link>
          </div>
        </div>
      </div>
      
      <div class="recent-activity">
        <h2>Neueste Aktivitäten</h2>
        <div v-if="isLoading" class="loading">Lade Daten...</div>
        <div v-else-if="hasError" class="error">{{ error }}</div>
        <div v-else-if="recentActivities.length === 0" class="no-data">Keine Aktivitäten gefunden</div>
        <ul v-else class="activity-list">
          <li v-for="activity in recentActivities" :key="activity.id" class="activity-item">
            <span class="activity-time">{{ formatTime(activity.timestamp) }}</span>
            <span class="activity-description">{{ activity.description }}</span>
          </li>
        </ul>
      </div>
    </div>
  </main>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useAppStore } from '../stores'

const store = useAppStore()
const recentActivities = ref([])

const containerCount = computed(() => store.containers.length)
const deploymentCount = computed(() => store.deployments.length)
const isLoading = computed(() => store.isLoading)
const hasError = computed(() => store.hasError)
const error = computed(() => store.error)

onMounted(async () => {
  await store.fetchContainers()
  await store.fetchDeployments()
  // Hier könnten wir noch die letzten Aktivitäten laden
  // Dies ist ein Platzhalter für die Demo
  recentActivities.value = [
    { id: 1, timestamp: new Date(Date.now() - 3600000), description: 'Container "web-server" gestartet' },
    { id: 2, timestamp: new Date(Date.now() - 7200000), description: 'Deployment "frontend-app" aktualisiert' },
    { id: 3, timestamp: new Date(Date.now() - 86400000), description: 'Neuer Container "database" erstellt' }
  ]
})

function formatTime(timestamp) {
  return new Intl.DateTimeFormat('de-DE', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  }).format(timestamp)
}
</script>

<style scoped>
.dashboard {
  padding: 2rem;
}

h1 {
  margin-bottom: 2rem;
  color: var(--color-primary);
}

.status-overview {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 1.5rem;
  margin-bottom: 2rem;
}

.status-card {
  background-color: var(--color-background-soft);
  border-radius: 8px;
  padding: 1.5rem;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.1);
}

.status-count {
  font-size: 2.5rem;
  font-weight: bold;
  margin: 1rem 0;
  color: var(--color-primary);
}

.status-actions {
  margin-top: 1rem;
}

.btn {
  display: inline-block;
  background-color: var(--color-primary);
  color: white;
  padding: 0.5rem 1rem;
  border-radius: 4px;
  text-decoration: none;
  font-weight: 500;
  transition: background-color 0.3s;
}

.btn:hover {
  background-color: var(--color-primary-dark, #3a9776);
}

.recent-activity {
  background-color: var(--color-background-soft);
  border-radius: 8px;
  padding: 1.5rem;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.1);
}

.activity-list {
  list-style: none;
  padding: 0;
}

.activity-item {
  padding: 0.8rem 0;
  border-bottom: 1px solid var(--color-border);
  display: flex;
  flex-direction: column;
}

.activity-time {
  font-size: 0.85rem;
  color: var(--color-text-light, #666);
  margin-bottom: 0.25rem;
}

.loading, .error, .no-data {
  padding: 1rem;
  text-align: center;
  color: var(--color-text-light, #666);
}

.error {
  color: #e74c3c;
}
</style>
