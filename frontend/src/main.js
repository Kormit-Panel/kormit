import { createApp } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'
import router from './router'
import axios from 'axios'

// CSS-Imports können direkt in die main.js importiert werden
import './assets/main.css'

// Axios Konfiguration
axios.defaults.baseURL = import.meta.env.VITE_API_URL || 'http://localhost:8080'
axios.defaults.headers.common['Content-Type'] = 'application/json'

const app = createApp(App)

app.use(createPinia())
app.use(router)

app.mount('#app') 
