const { convertSFDXProject } = require("./convertSFDXProject");
const { argv, exit } = require("process");

/**
 * Convierte el proyecto a la carpeta pasada por parámetro
 * f.e: node scripts/source/convert-sfdx-project deploy
 *
 */
async function main() {
  try {
    let dir = argv[2];
    let tmpDir = "./tmp";

    convertSFDXProject(dir, `${tmpDir}`);
  } catch (error) {
    console.error(error);
    exit(1);
  }
}

return main();
