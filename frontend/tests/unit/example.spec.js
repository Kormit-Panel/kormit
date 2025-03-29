import { shallowMount } from '@vue/test-utils'
import { createStore } from 'vuex'

// Ein einfacher Test, der immer bestehen wird
describe('Example Component Test', () => {
  it('passes a basic test', () => {
    expect(true).toBe(true)
  })

  it('can mount a component with store', () => {
    // Mock eines leeren Stores
    const store = createStore({
      state() {
        return {
          count: 0
        }
      },
      mutations: {
        increment(state) {
          state.count++
        }
      }
    })

    // Einfaches Komponenten-Setup
    const Component = {
      template: '<div>{{ count }}</div>',
      computed: {
        count() {
          return this.$store.state.count
        }
      }
    }

    // Komponente mit Store mounten
    const wrapper = shallowMount(Component, {
      global: {
        plugins: [store]
      }
    })

    expect(wrapper.text()).toContain('0')
  })
}) 