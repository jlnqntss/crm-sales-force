const { readFileSync, writeFileSync } = require("fs");
const { deploy, findLastSemanticTag } = require("./util.js");

/**
 * Inicializa el package.json para implementar los scripts de release automático
 * @author jmartinezpisson
 *
 */
async function main() {
  const targetOrg =
    process.argv[2] === "--check" ? process.argv[3] : process.argv[2];
  const isValidation = process.argv[2] === "--check" ? true : false;
  const targetEnvironment =
    process.argv[2] === "--check" ? process.argv[4] : process.argv[3];

  let target;
  switch (targetEnvironment) {
    case "prod":
      if (!process.env["CI_FULL_DEPLOYMENT_PROD"]) {
        target = findLastSemanticTag().target;
      }
      break;

    case "qa":
      if (!process.env["CI_FULL_DEPLOYMENT_QA"]) {
        target = findLastSemanticTag("UAT").target;
      }
      break;

    default:
      if (!process.env["CI_FULL_DEPLOYMENT_DEV"]) {
        target = findLastSemanticTag("dev").target;
      }
      break;
  }

  if (!targetOrg) {
    console.log(`[Error] Deploy: No hay usuario para realizar el despliegue`);
    process.exit(1);
  }

  deploy({
    //targetOrg: process.argv[2], isanjose
    targetOrg: targetOrg,
    targetCommit: target || undefined,
    checkOnly: isValidation
  });
}

return main();
