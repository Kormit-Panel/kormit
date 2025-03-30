<template>
  <div class="dashboard-container">
    <!-- Übersichtskarten-Bereich -->
    <div class="dashboard-grid">
      <!-- Container Karte -->
      <div class="dashboard-card">
        <div class="card-header">
          <h2>Containers</h2>
        </div>
        <div class="card-content">
          <!-- Container Status Liste -->
          <div class="container-list">
            <div class="container-item">
              <span class="container-name">web-app</span>
              <span class="container-status running">Running</span>
            </div>
            
            <div class="container-item">
              <span class="container-name">api-server</span>
              <span class="container-status running">Running</span>
            </div>
            
            <div class="container-item">
              <span class="container-name">db</span>
              <span class="container-status exited">Exited</span>
            </div>
            
            <div class="container-item">
              <span class="container-name">cache</span>
              <span class="container-status exited">Exited</span>
            </div>
          </div>
        </div>
      </div>
      
      <!-- Konfiguration Karte -->
      <div class="dashboard-card">
        <div class="card-header">
          <h2>Configuration</h2>
        </div>
        <div class="card-content">
          <!-- Konfigurations-Tabelle -->
          <div class="config-list">
            <div class="config-item">
              <span class="config-key">SERVER_PORT</span>
              <span class="config-value">8080</span>
            </div>
            
            <div class="config-item">
              <span class="config-key">DEBUG_MODE</span>
              <span class="config-value">false</span>
            </div>
            
            <div class="config-item">
              <span class="config-key">DATABASE_URL</span>
              <span class="config-value truncate">postgres://user:pass@db:5432/kormit</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    
    <div class="dashboard-grid">
      <!-- Deployments Karte -->
      <div class="dashboard-card">
        <div class="card-header">
          <h2>Deployments</h2>
        </div>
        <div class="card-content">
          <!-- Deployments Liste -->
          <div class="deployment-list">
            <div class="deployment-item">
              <div class="deployment-info">
                <span class="deployment-name">Add new feature</span>
                <span class="deployment-branch">main</span>
              </div>
              <div class="deployment-meta">
                <span class="deployment-status">
                  <span class="status-dot active"></span> main
                </span>
              </div>
            </div>
            
            <div class="deployment-item">
              <div class="deployment-info">
                <span class="deployment-name">Hotfix</span>
                <span class="deployment-branch">main</span>
              </div>
              <div class="deployment-meta">
                <span class="deployment-status">
                  <span class="status-dot active"></span> 5 hours ago
                </span>
              </div>
            </div>
            
            <div class="deployment-item">
              <div class="deployment-info">
                <span class="deployment-name">Initial commit</span>
                <span class="deployment-branch">develop</span>
              </div>
              <div class="deployment-meta">
                <span class="deployment-status">
                  <span class="status-dot"></span> 1 day ago
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
      
      <!-- Analytics Karte -->
      <div class="dashboard-card">
        <div class="card-header">
          <h2>Analytics</h2>
        </div>
        <div class="card-content">
          <div class="analytics-chart">
            <!-- SVG Chart -->
            <svg viewBox="0 0 300 150" class="chart">
              <!-- Y-Axis Labels -->
              <text x="10" y="20" class="chart-label">100</text>
              <text x="10" y="50" class="chart-label">75</text>
              <text x="10" y="80" class="chart-label">50</text>
              <text x="10" y="110" class="chart-label">25</text>
              <text x="10" y="140" class="chart-label">0</text>
              
              <!-- Background Grid Lines -->
              <line x1="30" y1="20" x2="290" y2="20" class="grid-line" />
              <line x1="30" y1="50" x2="290" y2="50" class="grid-line" />
              <line x1="30" y1="80" x2="290" y2="80" class="grid-line" />
              <line x1="30" y1="110" x2="290" y2="110" class="grid-line" />
              <line x1="30" y1="140" x2="290" y2="140" class="grid-line" />
              
              <!-- Data Points -->
              <polyline
                class="chart-line"
                points="50,125 100,60 150,80 200,35 250,10"
                fill="none"
              />
              
              <!-- Data Dots -->
              <circle cx="50" cy="125" r="4" class="chart-dot" />
              <circle cx="100" cy="60" r="4" class="chart-dot" />
              <circle cx="150" cy="80" r="4" class="chart-dot" />
              <circle cx="200" cy="35" r="4" class="chart-dot" />
              <circle cx="250" cy="10" r="4" class="chart-dot" />
            </svg>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
// Komponenten-Logik kann hier hinzugefügt werden
</script>

<style scoped>
/* Dashboard Styles */
.dashboard-container {
  display: flex;
  flex-direction: column;
  gap: 2rem;
}

.dashboard-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(450px, 1fr));
  gap: 2rem;
  margin-bottom: 2rem;
}

/* Cards */
.dashboard-card {
  background-color: var(--color-surface);
  border-radius: var(--border-radius-lg);
  overflow: hidden;
  box-shadow: var(--shadow-md);
  transition: transform 0.3s, box-shadow 0.3s;
  position: relative;
}

.dashboard-card:hover {
  transform: translateY(-5px);
  box-shadow: var(--shadow-lg);
}

.card-header {
  padding: 1.5rem;
  border-bottom: 1px solid var(--color-border);
}

.card-header h2 {
  font-size: 1.25rem;
  font-weight: 600;
  color: var(--color-text);
  margin: 0;
}

.card-content {
  padding: 1.5rem;
}

/* Container List */
.container-list {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.container-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.75rem 1rem;
  background-color: rgba(14, 165, 233, 0.05);
  border-radius: var(--border-radius-lg);
  transition: transform 0.2s;
}

.container-item:hover {
  transform: scale(1.02);
}

.container-name {
  font-weight: 500;
}

.container-status {
  padding: 0.35rem 0.75rem;
  border-radius: var(--border-radius-full);
  font-size: 0.85rem;
  font-weight: 500;
}

.container-status.running {
  background-color: rgba(16, 185, 129, 0.2);
  color: var(--color-success);
}

.container-status.exited {
  background-color: rgba(239, 68, 68, 0.2);
  color: var(--color-danger);
}

/* Config List */
.config-list {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.config-item {
  display: flex;
  justify-content: space-between;
  padding: 0.75rem 1rem;
  background-color: rgba(14, 165, 233, 0.05);
  border-radius: var(--border-radius-lg);
  transition: transform 0.2s;
}

.config-item:hover {
  transform: scale(1.02);
}

.config-key {
  font-weight: 500;
}

.config-value {
  max-width: 200px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

/* Deployment List */
.deployment-list {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.deployment-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.75rem 1rem;
  background-color: rgba(14, 165, 233, 0.05);
  border-radius: var(--border-radius-lg);
  transition: transform 0.2s;
}

.deployment-item:hover {
  transform: scale(1.02);
}

.deployment-info {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.deployment-name {
  font-weight: 500;
}

.deployment-branch {
  font-size: 0.85rem;
  color: var(--color-text-muted);
}

.deployment-meta {
  font-size: 0.85rem;
}

.deployment-status {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.status-dot {
  display: inline-block;
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background-color: var(--color-text-muted);
}

.status-dot.active {
  background-color: var(--color-primary);
  box-shadow: 0 0 0 2px rgba(14, 165, 233, 0.3);
}

/* Analytics Chart */
.analytics-chart {
  height: 180px;
}

.chart {
  width: 100%;
  height: 100%;
}

.chart-label {
  font-size: 10px;
  fill: var(--color-text-muted);
}

.grid-line {
  stroke: var(--color-border);
  stroke-width: 1;
  stroke-dasharray: 4;
}

.chart-line {
  stroke: var(--color-primary);
  stroke-width: 3;
  stroke-linecap: round;
  stroke-linejoin: round;
}

.chart-dot {
  fill: var(--color-primary);
  stroke: white;
  stroke-width: 2;
}

/* Utilities */
.truncate {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

/* Responsive Adjustments */
@media (max-width: 768px) {
  .dashboard-grid {
    grid-template-columns: 1fr;
    gap: 1.5rem;
  }
}
</style>