module.exports = {
  preset: '@vue/cli-plugin-unit-jest',
  testMatch: [
    '**/tests/unit/**/*.spec.[jt]s?(x)',
    '**/__tests__/*.[jt]s?(x)'
  ],
  transform: {
    '^.+\\.vue$': 'vue-jest'
  },
  testEnvironment: 'jsdom',
  // Wichtig: Mit --passWithNoTests werden die Tests auch bestanden, wenn keine vorhanden sind
  passWithNoTests: true
} 