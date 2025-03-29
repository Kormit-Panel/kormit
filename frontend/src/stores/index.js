import { defineStore } from 'pinia'
import axios from 'axios'

export const useAppStore = defineStore('app', {
  state: () => ({
    containers: [],
    deployments: [],
    isLoading: false,
    error: null
  }),
  
  getters: {
    getContainers: (state) => state.containers,
    getDeployments: (state) => state.deployments,
    hasError: (state) => state.error !== null
  },
  
  actions: {
    async fetchContainers() {
      this.isLoading = true
      this.error = null
      
      try {
        const response = await axios.get('/api/containers')
        this.containers = response.data
      } catch (error) {
        this.error = 'Fehler beim Laden der Container: ' + error.message
        console.error('Fehler beim Laden der Container:', error)
      } finally {
        this.isLoading = false
      }
    },
    
    async fetchDeployments() {
      this.isLoading = true
      this.error = null
      
      try {
        const response = await axios.get('/api/deployments')
        this.deployments = response.data
      } catch (error) {
        this.error = 'Fehler beim Laden der Deployments: ' + error.message
        console.error('Fehler beim Laden der Deployments:', error)
      } finally {
        this.isLoading = false
      }
    }
  }
}) 