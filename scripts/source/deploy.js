const { readFileSync, writeFileSync } = require("fs");
const { deploy, findLastSemanticTag } = require("./util.js");

/**
 * Inicializa el package.json para implementar los scripts de release automático
 * @author jmartinezpisson
 *
 */
async function main() {
  const isValidation = process.argv[2] === "--check";
  const targetOrg = isValidation ? process.argv[3] : process.argv[2];
  const targetEnvironment = isValidation ? process.argv[4] : process.argv[3];
  const testRun = isValidation
    ? process.argv.length > 4
    : process.argv.length > 3;
  let testRunLevel =
    isValidation && testRun ? process.argv[5] : process.argv[4];

  let target;
  switch (targetEnvironment) {
    case "prod":
      if (process.env["CI_FULL_DEPLOYMENT_PROD"] === "true") {
        target = findLastSemanticTag().target;
      }
      break;

    case "qa":
      if (process.env["CI_FULL_DEPLOYMENT_QA"] === "true") {
        target = findLastSemanticTag("UAT").target;
      }
      break;

    default:
      if (process.env["CI_FULL_DEPLOYMENT_DEV"] === "true") {
        target = await findLastSemanticTag("rc").target;
        console.log(
          "[DEBUG] Deploy: Last commit in dev branch: " +
            (await findLastSemanticTag("rc").target)
        );
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

  if (testRun) {
    deployConf["testLevel"] = testRunLevel;
  }

  deploy(deployConf);
}

return main();
