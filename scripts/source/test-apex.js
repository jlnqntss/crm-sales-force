const { runOrgTests } = require("./util.js");

/**
 * Ejecuta los tests de la Org configurada por defecto en SFDX
 * @author jmartinezpisson
 *
 */
async function main() {
  runOrgTests();
}

return main();
