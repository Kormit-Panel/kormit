import { createApp } from 'vue'
import App from './App.vue'
import router from './router'

// Erstelle die Vue-Anwendung
const app = createApp(App)

// Router hinzufügen
app.use(router)

// Anwendung mounten
app.mount('#app')