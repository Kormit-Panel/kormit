<template>
  <div class="containers">
    <h1>Container-Verwaltung</h1>
    <div class="container-list">
      <p>Keine Container verfügbar. Verbindung zum Backend wird hergestellt...</p>
    </div>
  </div>
</template>

<script>
export default {
  name: 'ContainersView',
  data() {
    return {
      containers: []
    }
  },
  mounted() {
    // Hier würde die API-Abfrage für Container stattfinden
    console.log('Container-View geladen')
  }
}
</script>

<style scoped>
.containers {
  padding: 1rem;
}
.container-list {
  margin-top: 1rem;
  padding: 1rem;
  background-color: #f5f5f5;
  border-radius: 4px;
}
</style> 