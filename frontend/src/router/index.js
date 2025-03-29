import { createRouter, createWebHistory } from 'vue-router' 
import HomeView from '../views/HomeView.vue' 
 
const routes = [ 
  { 
    path: '/', 
    name: 'home', 
    component: HomeView 
  }, 
  { 
    path: '/containers', 
    name: 'containers', 
    component: () => import('../views/ContainersView.vue') 
  }, 
  { 
    path: '/deployments', 
    name: 'deployments', 
    component: () => import('../views/DeploymentsView.vue') 
  } 
] 
 
const router = createRouter({ 
  history: createWebHistory(process.env.BASE_URL), 
  routes 
}) 
 
export default router 
