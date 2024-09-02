const { readFileSync, writeFileSync } = require("fs");
const { deploy, findLastSemanticTag } = require("./util.js");

/**
 * Inicializa el package.json para implementar los scripts de release automático
 * @author jmartinezpisson
 *
 */
async function main() {
  let lastTag = {
    name: "1.3609.1-rc",
    message: "",
    target: "b339be89d1619aed5dfe30b62e9cdaa9c39ecfa2",
    commit: {
      id: "b339be89d1619aed5dfe30b62e9cdaa9c39ecfa2",
      short_id: "b339be89",
      created_at: "2024-08-29T09:01:08.000+00:00",
      parent_ids: [
        "4cd1298cf1b1c48608dce46ee5fbd83e703cae38",
        "12a366def3dda9c79bab43d7265258995165eacc"
      ],
      title:
        "Merge branch 'fix-cv-2620-datos-insuficientes-erroneos' into 'dev'",
      message:
        "Merge branch 'fix-cv-2620-datos-insuficientes-erroneos' into 'dev'\n\nFix cv 2620 datos insuficientes erroneos\n\nSee merge request zurich-es/application/one-customer-service/crm-sales-force!3373",
      author_name: "Jon Ander San Juan Lago",
      author_email: "jonander.sanjuanlago@zurich.com",
      authored_date: "2024-08-29T09:01:08.000+00:00",
      committer_name: "Jon Ander San Juan Lago",
      committer_email: "jonander.sanjuanlago@zurich.com",
      committed_date: "2024-08-29T09:01:08.000+00:00",
      trailers: {},
      extended_trailers: {},
      web_url:
        "https://gitlab.com/zurich-es/application/one-customer-service/crm-sales-force/-/commit/b339be89d1619aed5dfe30b62e9cdaa9c39ecfa2"
    },
    release: null,
    protected: true,
    created_at: null
  };

  const targetOrg =
    process.argv[2] === "--check" ? process.argv[3] : process.argv[2];
  const isValidation = process.argv[2] === "--check" ? true : false;
  const targetEnvironment =
    process.argv[2] === "--check" ? process.argv[4] : process.argv[3];

  const testRun =
    process.argv[2] === "--check"
      ? process.argv.length > 4
      : process.argv.length > 3;
  const testRunLevel = testRun
    ? process.argv[2] === "--check"
      ? process.argv[5]
      : process.argv[4]
    : null;

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
        // target = findLastSemanticTag("rc").target;
        target = lastTag.target;
        console.log("**********delta");
        console.log(target);
      } else {
        console.log("**********full deployment");
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
