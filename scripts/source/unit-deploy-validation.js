const { mkdirSync, rmdirSync } = require("fs-extra");
const { execSync } = require("child_process");
const { argv } = require("process");
const { convertSFDXProject } = require("./convertSFDXProject");

/**
 * Valida un despliegue a un entorno a la org indicada como parámetro
 * f.e: node scripts/source/unit-deploy-validation  zurich_prod
 *
 */
async function main() {
  try {
    let username = argv[2];
    let tmpDir = "./tmp";

    // 1 - Crea una carpeta temporal deploy
    mkdirSync("deploy", { recursive: true });

    // 2 - Reconcilia los perfiles con el entorno a validar
    execSync(`sfp profile:reconcile --targetorg ${username}`, {
      stdio: "inherit"
    });

    // 3 - Convierte el proyecto a formato Metadata API y  valida contra el entorno
    convertSFDXProject("deploy", `${tmpDir}`);

    // 4 - Deshace los cambios de los perfiles
    execSync(`git reset --hard`, {
      stdio: "inherit"
    });

    // 5 - Valida contra el entorno
    execSync(
      `sf project deploy start --metadata-dir deploy --test-level RunLocalTests --target-org ${username} --verbose --dry-run --wait 10 --json`,
      {
        stdio: "inherit"
      }
    );
  } catch (error) {
    console.error(error);
  } finally {
    rmdirSync("deploy", { recursive: true });
  }
}

return main();
