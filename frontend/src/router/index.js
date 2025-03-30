import { createRouter, createWebHistory } from 'vue-router'

// Lazy-loading für bessere Performance
const Dashboard = () => import('../views/Dashboard.vue')
//const ServerManagement = () => import('../views/ServerManagement.vue')
//const DockerContainers = () => import('../views/DockerContainers.vue')
//const UserAdmin = () => import('../views/UserAdmin.vue')
//const Backups = () => import('../views/Backups.vue')
//const SystemLogs = () => import('../views/SystemLogs.vue')
//const Settings = () => import('../views/Settings.vue')
//const Help = () => import('../views/Help.vue')

const routes = [
  {
    path: '/',
    name: 'Dashboard',
    component: Dashboard,
    meta: { title: 'Dashboard' }
  },
  {
    path: '/servers',
    name: 'Server Management',
    component: Dashboard,
    meta: { title: 'Server Management' }
  },
  {
    path: '/docker',
    name: 'Docker Containers',
    component: Dashboard,
    meta: { title: 'Docker Containers' }
  },
  {
    path: '/users',
    name: 'User Administration',
    component: Dashboard,
    meta: { title: 'User Administration' }
  },
  {
    path: '/backups',
    name: 'Backups',
    component: Dashboard,
    meta: { title: 'Backups' }
  },
  {
    path: '/logs',
    name: 'System Logs',
    component: Dashboard,
    meta: { title: 'System Logs' }
  },
  {
    path: '/settings',
    name: 'Settings',
    component: Dashboard,
    meta: { title: 'Settings' }
  },
  {
    path: '/help',
    name: 'Help',
    component: Dashboard,
    meta: { title: 'Help' }
  },
  // Fallback für nicht gefundene Routen
  {
    path: '/:pathMatch(.*)*',
    redirect: '/'
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

// Update document title based on route
router.beforeEach((to, from, next) => {
  document.title = `Kormit - ${to.meta.title || 'Admin Panel'}`
  next()
})

export default router