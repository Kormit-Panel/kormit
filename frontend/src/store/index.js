import { createStore } from 'vuex' 
import containers from './modules/containers' 
import deployments from './modules/deployments' 
 
export default createStore({ 
  state: { 
    user: null 
  }, 
  getters: { 
    isAuthenticated: state => state.user 
  }, 
  mutations: { 
    setUser(state, user) { 
      state.user = user 
    } 
  }, 
  actions: { 
    login({ commit }, credentials) { 
      // Would call API to authenticate 
      commit('setUser', { username: credentials.username }) 
    }, 
    logout({ commit }) { 
      commit('setUser', null) 
    } 
  }, 
  modules: { 
    containers, 
    deployments 
  } 
}) 
