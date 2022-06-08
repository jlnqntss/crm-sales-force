const { readFileSync, writeFileSync } = require("fs");
const { authenticate } = require("./util.js");

/**
 * Inicializa el package.json para implementar los scripts de release automático
 * @author jmartinezpisson
 *
 */
async function main() {
  console.log(process.argv);

  authenticate({
    authUrl: process.argv[2],
    alias: process.argv[3]
  });
}

return main();
