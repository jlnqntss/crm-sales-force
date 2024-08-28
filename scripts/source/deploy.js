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

  const testRun = process.argv[2] === "--check" ? process.argv.length > 4 : process.argv.length > 3;
  const testRunLevel = 
    testRun ? 
      process.argv[2] === "--check" ? process.argv[5] : process.argv[4] 
    : null;
  
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
        target = findLastSemanticTag("rc").target;
        console.log("**********delta");
        console.log(target);
      }
      else {
        console.log("**********full deployment");
        console.log(!process.env["CI_FULL_DEPLOYMENT_DEV"]);
      }
      break;
  }

  if (!targetOrg) {
    console.log(`[Error] Deploy: No hay usuario para realizar el despliegue`);
    process.exit(1);
  }

  const deployConf = {
    targetOrg: targetOrg,
    targetCommit: target || undefined,
    checkOnly: isValidation
  };

  if(testRun) {
    deployConf["testLevel"] = testRunLevel;
  }

  deploy(deployConf);
}

return main();
