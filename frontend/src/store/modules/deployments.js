export default { 
  namespaced: true, 
  state: { 
    deployments: [] 
  }, 
  getters: { 
    getDeployments: state => state.deployments 
  }, 
  mutations: { 
    setDeployments(state, deployments) { 
      state.deployments = deployments 
    } 
  }, 
  actions: { 
    async fetchDeployments({ commit }) { 
      // Would call API to get deployments 
      const deployments = [ 
        { id: 'deploy1', name: 'web-app', status: 'success' }, 
        { id: 'deploy2', name: 'api', status: 'running' } 
      ] 
      commit('setDeployments', deployments) 
    } 
  } 
} 
