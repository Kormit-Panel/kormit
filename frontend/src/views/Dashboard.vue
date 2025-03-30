<template>
    <transition-group name="fade" tag="div" class="dashboard-grid">
      <!-- System Status -->
      <div class="card" key="status">
        <div class="card-header">
          <h3>System Status</h3>
          <i class="material-icons card-icon">health_and_safety</i>
        </div>
        <div class="card-content">
          <div class="status-indicator">
            <div class="status-badge online">Online</div>
            <div class="uptime">Uptime: 14 Tage, 6 Stunden</div>
          </div>
          <div class="system-metrics">
            <div class="metric">
              <div class="metric-name">CPU</div>
              <div class="progress-bar">
                <div class="progress" :style="{ width: '32%' }"></div>
              </div>
              <div class="metric-value">32%</div>
            </div>
            <div class="metric">
              <div class="metric-name">RAM</div>
              <div class="progress-bar">
                <div class="progress" :style="{ width: '45%' }"></div>
              </div>
              <div class="metric-value">45%</div>
            </div>
            <div class="metric">
              <div class="metric-name">Disk</div>
              <div class="progress-bar">
                <div class="progress" :style="{ width: '68%' }"></div>
              </div>
              <div class="metric-value">68%</div>
            </div>
          </div>
        </div>
      </div>
  
      <!-- Server Stats -->
      <div class="card" key="servers">
        <div class="card-header">
          <h3>Server</h3>
          <i class="material-icons card-icon">dns</i>
        </div>
        <div class="card-content">
          <div class="stat-value">8/10</div>
          <div class="stat-change positive">
            <i class="material-icons">check_circle</i>Alle funktionsfähig
          </div>
        </div>
      </div>
  
      <!-- Docker Stats -->
      <div class="card" key="containers">
        <div class="card-header">
          <h3>Docker Container</h3>
          <i class="material-icons card-icon">storage</i>
        </div>
        <div class="card-content">
          <div class="stat-value">24/26</div>
          <div class="stat-change negative">
            <i class="material-icons">error</i>2 benötigen Aufmerksamkeit
          </div>
        </div>
      </div>
  
      <!-- Backup Stats -->
      <div class="card" key="backups">
        <div class="card-header">
          <h3>Backups</h3>
          <i class="material-icons card-icon">backup</i>
        </div>
        <div class="card-content">
          <div class="stat-value">100%</div>
          <div class="stat-change positive">
            <i class="material-icons">schedule</i>Letztes: Heute, 03:00
          </div>
        </div>
      </div>
  
      <!-- Resource Monitoring Chart -->
      <div class="card wide" key="resource-chart">
        <div class="card-header">
          <h3>Ressourcen Übersicht</h3>
          <div class="card-actions">
            <select class="time-select">
              <option>Letzte 24 Stunden</option>
              <option>Letzte Woche</option>
              <option>Letzter Monat</option>
            </select>
            <button class="icon-button small">
              <i class="material-icons">more_vert</i>
            </button>
          </div>
        </div>
        <div class="card-content chart-container">
          <div class="chart-placeholder">
            <div class="chart-bars">
              <div class="chart-bar" v-for="i in 24" :key="i" 
                  :style="{ height: Math.floor(30 + Math.random() * 50) + '%' }">
                <span class="chart-tooltip">{{ Math.floor(30 + Math.random() * 50) }}%</span>
              </div>
            </div>
            <div class="chart-labels">
              <span v-for="i in 12" :key="i">{{ (i*2) }}:00</span>
            </div>
          </div>
          <div class="chart-legend">
            <div class="legend-item">
              <div class="legend-color cpu"></div>
              <div>CPU Auslastung</div>
            </div>
            <div class="legend-item">
              <div class="legend-color ram"></div>
              <div>Speichernutzung</div>
            </div>
            <div class="legend-item">
              <div class="legend-color network"></div>
              <div>Netzwerk Traffic</div>
            </div>
          </div>
        </div>
      </div>
  
      <!-- Recent Alerts -->
      <div class="card" key="alerts">
        <div class="card-header">
          <h3>Aktuelle Warnungen</h3>
          <button class="icon-button small">
            <i class="material-icons">notifications_none</i>
          </button>
        </div>
        <div class="card-content">
          <ul class="alert-list">
            <li class="alert-item warning">
              <div class="alert-icon">
                <i class="material-icons">warning</i>
              </div>
              <div class="alert-details">
                <div class="alert-text">Container 'app_db' hohe CPU Auslastung</div>
                <div class="alert-time">Vor 15 Minuten</div>
              </div>
              <button class="icon-button small">
                <i class="material-icons">chevron_right</i>
              </button>
            </li>
            <li class="alert-item error">
              <div class="alert-icon">
                <i class="material-icons">error</i>
              </div>
              <div class="alert-details">
                <div class="alert-text">Container 'prometheus' gestoppt</div>
                <div class="alert-time">Vor 42 Minuten</div>
              </div>
              <button class="icon-button small">
                <i class="material-icons">chevron_right</i>
              </button>
            </li>
            <li class="alert-item info">
              <div class="alert-icon">
                <i class="material-icons">info</i>
              </div>
              <div class="alert-details">
                <div class="alert-text">Update für Kormit verfügbar (v1.0.1)</div>
                <div class="alert-time">Vor 2 Stunden</div>
              </div>
              <button class="icon-button small">
                <i class="material-icons">chevron_right</i>
              </button>
            </li>
          </ul>
          <button class="btn-text">Alle Warnungen anzeigen</button>
        </div>
      </div>
  
      <!-- Quick Actions -->
      <div class="card" key="actions">
        <div class="card-header">
          <h3>Schnellaktionen</h3>
        </div>
        <div class="card-content">
          <div class="action-grid">
            <button class="action-button">
              <i class="material-icons">add</i>
              <span>Server hinzufügen</span>
            </button>
            <button class="action-button">
              <i class="material-icons">play_arrow</i>
              <span>Starten</span>
            </button>
            <button class="action-button">
              <i class="material-icons">stop</i>
              <span>Stoppen</span>
            </button>
            <button class="action-button">
              <i class="material-icons">restart_alt</i>
              <span>Neustarten</span>
            </button>
            <button class="action-button">
              <i class="material-icons">backup</i>
              <span>Backup</span>
            </button>
            <button class="action-button">
              <i class="material-icons">terminal</i>
              <span>Konsole</span>
            </button>
          </div>
        </div>
      </div>
    </transition-group>
  </template>
  
  <script>
  export default {
    name: 'Dashboard',
    data() {
      return {
        // Dashboard data would be here, connected to backend API
      }
    },
    mounted() {
      // Here you would fetch data from your API
    },
    methods: {
      // Methods for dashboard functionality
    }
  }
  </script>
  
  <style scoped>
  /* Dashboard specific styles */
  .status-indicator {
    display: flex;
    align-items: center;
    margin-bottom: 16px;
  }
  
  .status-badge {
    padding: 4px 8px;
    border-radius: 4px;
    font-size: 14px;
    font-weight: 500;
    margin-right: 12px;
  }
  
  .status-badge.online {
    background-color: rgba(76, 175, 80, 0.2);
    color: #4CAF50;
  }
  
  .status-badge.warning {
    background-color: rgba(255, 152, 0, 0.2);
    color: #FF9800;
  }
  
  .status-badge.offline {
    background-color: rgba(244, 67, 54, 0.2);
    color: #F44336;
  }
  
  .uptime {
    font-size: 14px;
    color: var(--text-secondary);
  }
  
  .system-metrics {
    margin-top: 16px;
  }
  
  .metric {
    display: flex;
    align-items: center;
    margin-bottom: 8px;
  }
  
  .metric-name {
    width: 50px;
    font-size: 14px;
    color: var(--text-secondary);
  }
  
  .progress-bar {
    flex: 1;
    height: 8px;
    background-color: rgba(255, 255, 255, 0.1);
    border-radius: 4px;
    margin: 0 12px;
    overflow: hidden;
  }
  
  .light-mode .progress-bar {
    background-color: rgba(0, 0, 0, 0.1);
  }
  
  .progress {
    height: 100%;
    background-color: var(--primary-color);
    border-radius: 4px;
  }
  
  .metric-value {
    width: 40px;
    font-size: 14px;
    text-align: right;
  }
  
  .chart-placeholder {
    display: flex;
    flex-direction: column;
    height: 100%;
  }
  
  .chart-bars {
    display: flex;
    align-items: flex-end;
    justify-content: space-between;
    height: 240px;
    padding-top: 20px;
  }
  
  .chart-bar {
    width: 3.5%;
    background-color: var(--primary-color);
    border-radius: 4px 4px 0 0;
    position: relative;
  }
  
  .chart-bar:hover .chart-tooltip {
    opacity: 1;
  }
  
  .chart-tooltip {
    position: absolute;
    top: -25px;
    left: 50%;
    transform: translateX(-50%);
    background-color: var(--surface-color);
    color: var(--text-color);
    padding: 2px 6px;
    border-radius: 4px;
    font-size: 12px;
    opacity: 0;
    transition: opacity 0.2s ease;
  }
  
  .chart-labels {
    display: flex;
    justify-content: space-between;
    margin-top: 8px;
    padding: 0 1.5%;
  }
  
  .chart-labels span {
    font-size: 12px;
    color: var(--text-secondary);
  }
  
  .chart-legend {
    display: flex;
    justify-content: center;
    margin-top: 16px;
    gap: 24px;
  }
  
  .legend-item {
    display: flex;
    align-items: center;
  }
  
  .legend-color {
    width: 16px;
    height: 16px;
    border-radius: 4px;
    margin-right: 8px;
  }
  
  .legend-color.cpu {
    background-color: var(--primary-color);
  }
  
  .legend-color.ram {
    background-color: var(--warning-color);
  }
  
  .legend-color.network {
    background-color: var(--success-color);
  }
  
  .time-select {
    background-color: rgba(255, 255, 255, 0.05);
    color: var(--text-color);
    border: 1px solid var(--border-color);
    border-radius: 4px;
    padding: 4px 8px;
    font-size: 14px;
  }
  
  .light-mode .time-select {
    background-color: rgba(0, 0, 0, 0.05);
  }
  
  .alert-list {
    list-style: none;
  }
  
  .alert-item {
    display: flex;
    align-items: center;
    padding: 12px 0;
    border-bottom: 1px solid var(--border-color);
  }
  
  .alert-item:last-child {
    border-bottom: none;
  }
  
  .alert-icon {
    width: 40px;
    height: 40px;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    margin-right: 12px;
  }
  
  .alert-item.warning .alert-icon {
    background-color: rgba(255, 193, 7, 0.1);
    color: var(--warning-color);
  }
  
  .alert-item.error .alert-icon {
    background-color: rgba(244, 67, 54, 0.1);
    color: var(--error-color);
  }
  
  .alert-item.info .alert-icon {
    background-color: rgba(33, 150, 243, 0.1);
    color: var(--primary-light);
  }
  
  .alert-details {
    flex: 1;
  }
  
  .alert-text {
    font-weight: 500;
  }
  
  .alert-time {
    font-size: 12px;
    color: var(--text-secondary);
  }
  
  .btn-text {
    background: transparent;
    border: none;
    color: var(--primary-light);
    cursor: pointer;
    padding: 8px 0;
    margin-top: 8px;
    font-size: 14px;
    width: 100%;
    text-align: center;
  }
  
  .btn-text:hover {
    text-decoration: underline;
  }
  
  .action-grid {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 12px;
  }
  
  .action-button {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    background-color: rgba(33, 150, 243, 0.1);
    border: none;
    border-radius: 8px;
    padding: 12px;
    color: var(--text-color);
    cursor: pointer;
    transition: background-color var(--transition-speed) ease;
  }
  
  .action-button:hover {
    background-color: rgba(33, 150, 243, 0.2);
  }
  
  .action-button i {
    margin-bottom: 8px;
    color: var(--primary-light);
  }
  
  .action-button span {
    font-size: 12px;
  }
  
  @media (max-width: 768px) {
    .action-grid {
      grid-template-columns: repeat(2, 1fr);
    }
  }
  </style>