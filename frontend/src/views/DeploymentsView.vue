<template>
  <div class="deployments">
    <h1>Deployment-Verwaltung</h1>
    <div class="deployment-list">
      <p>Keine Deployments verfügbar. Verbindung zum Backend wird hergestellt...</p>
    </div>
  </div>
</template>

<script>
export default {
  name: 'DeploymentsView',
  data() {
    return {
      deployments: []
    }
  },
  mounted() {
    // Hier würde die API-Abfrage für Deployments stattfinden
    console.log('Deployments-View geladen')
  }
}
</script>

<style scoped>
.deployments {
  padding: 1rem;
}
.deployment-list {
  margin-top: 1rem;
  padding: 1rem;
  background-color: #f5f5f5;
  border-radius: 4px;
}
</style> 