const { readFileSync, writeFileSync } = require("fs");
const { deploy, findLastSemanticTag } = require("./util.js");

/**
 * Inicializa el package.json para implementar los scripts de release automático
 * @author jmartinezpisson
 *
 */
async function main() {
  const isValidation = process.argv.includes("--check");

  const argOffset = isValidation ? 1 : 0;
  const targetOrg = process.argv[2 + argOffset];
  const targetEnvironment = process.argv[3 + argOffset];
  
  const testRun = process.argv.length > (3 + argOffset);
  const testRunLevel = testRun ? process.argv[4 + argOffset] : undefined;

  let target;
  switch (targetEnvironment) {
    case "prod":
      if (process.env["CI_FULL_DEPLOYMENT_PROD"] === "true") { 
        let tag = await findLastSemanticTag();
        target = tag.target;
      }
      break;

    case "qa":
      if (process.env["CI_FULL_DEPLOYMENT_QA"] === "true") {  
        let tag = await findLastSemanticTag("UAT", 1);
        target = tag.target;
      }
      break;

    default:
      if (process.env["CI_FULL_DEPLOYMENT_DEV"] === "true") {
        let tag = await findLastSemanticTag("rc");
        target = tag.target;
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

return (async () => {
  await main();
})().catch(e => {
  console.error(e);
});
