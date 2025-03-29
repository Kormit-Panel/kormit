import { createRouter, createWebHistory } from 'vue-router' 
import HomeView from '../views/HomeView.vue' 
 
const router = createRouter({ 
  history: createWebHistory(import.meta.env.BASE_URL), 
  routes: [ 
    { 
      path: '/', 
      name: 'home', 
      component: HomeView 
    }, 
    { 
      path: '/container', 
      name: 'container', 
      component: () => import('../views/ContainerView.vue') 
    }, 
    { 
      path: '/deployments', 
      name: 'deployments', 
      component: () => import('../views/DeploymentsView.vue') 
    }, 
    { 
      path: '/einstellungen', 
      name: 'einstellungen', 
      component: () => import('../views/EinstellungenView.vue') 
    } 
  ] 
}) 
 
export default router 
