const { defineConfig } = require('cypress');

module.exports = defineConfig({
  e2e: {
    baseUrl: 'http://127.0.0.1:18000',
    specPattern: 'cypress/e2e/**/*.cy.js',
    supportFile: false,
  },
  video: false,
  screenshotOnRunFailure: true,
  reporter: 'junit',
  reporterOptions: {
    mochaFile: 'reports/junit/results-[hash].xml',
    toConsole: true,
  },
});
