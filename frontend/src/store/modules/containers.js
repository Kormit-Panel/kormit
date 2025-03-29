export default { 
  namespaced: true, 
  state: { 
    containers: [] 
  }, 
  getters: { 
    getContainers: state => state.containers 
  }, 
  mutations: { 
    setContainers(state, containers) { 
      state.containers = containers 
    } 
  }, 
  actions: { 
    async fetchContainers({ commit }) { 
      // Would call API to get containers 
      const containers = [ 
        { id: 'abc123', name: 'web-server', status: 'running' }, 
        { id: 'def456', name: 'database', status: 'running' } 
      ] 
      commit('setContainers', containers) 
    } 
  } 
} 
