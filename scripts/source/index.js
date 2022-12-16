const { readFileSync, writeFileSync } = require("fs");
const SCRIPTS_DIR = process.env["CI_SCRIPTS_DIR"] + "/scripts/source";

const scripts = {
  "release:authenticate": `node ${SCRIPTS_DIR}/authenticate.js`,
  "release:scan": `node ${SCRIPTS_DIR}/scan.js`,
  "release:test:lwc": `node ${SCRIPTS_DIR}/test-lwc.js`,
  "release:test:apex": `node ${SCRIPTS_DIR}/test-apex.js`,
  "release:validate": `node ${SCRIPTS_DIR}/deploy.js --check`,
  "release:deploy": `node ${SCRIPTS_DIR}/deploy.js`,
  "release:changelog": `node ${SCRIPTS_DIR}/changelog.js`,
  "release:tag:version": `node ${SCRIPTS_DIR}/tag-version.js`,
  "release:start": `node ${SCRIPTS_DIR}/create-release.js`,
  "release:finish": `node ${SCRIPTS_DIR}/finish-release.js`
};
/**
 * Inicializa el package.json para implementar los scripts de release automático
 * @author jmartinezpisson
 */
async function main() {
  try {
    console.log("[Info] Leyendo package.json");
    const packageJson = JSON.parse(
      readFileSync("package.json", { encoding: "utf-8" })
    );

    console.log("[Info] Inicializando scripts");

    if (!packageJson.scripts) {
      packageJson.scripts = {};
    }

    // Script release
    for (let scriptName in scripts) {
      if (!packageJson.scripts[scriptName]) {
        packageJson.scripts[scriptName] = scripts[scriptName];
      }
    }

    writeFileSync("package.json", JSON.stringify(packageJson), {
      encoding: "utf-8"
    });
  } catch (error) {
    console.log("[Error] Error inicializando scripts");
    console.log(error);
  }
}

return main();
