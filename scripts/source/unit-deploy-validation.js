const {
  readFileSync,
  mkdirSync,
  rmdirSync,
  existsSync,
  moveSync
} = require("fs-extra");
const mergedirs = require("merge-dirs").default;
const { execSync } = require("child_process");
const { argv } = require("process");

/**
 * Convierte el proyecto SFDX al formato Metadata API, que permite hacer validación completa
 * @param {String} targetDirectory
 */
function convert_sfdx_project(targetDirectory) {
  const sfdxProject = JSON.parse(
    readFileSync("sfdx-project.json", { encoding: "utf-8" })
  );

  console.log("Converting project...");

  sfdxProject.packageDirectories.forEach((dir) => {
    console.log(`Converting package ${dir.path}...`);
    execSync(
      `sfdx force:source:convert -r "${dir.path}" -d ".tmp/${dir.path}"`
    );

    if (existsSync(`${targetDirectory}/package.xml`)) {
      console.log("Merging package.xml");
      execSync(
        `sfdx sfpowerkit:project:manifest:merge -p ".tmp/${dir.path}/package.xml,${targetDirectory}/package.xml" -d ".tmp"`,
        {
          stdio: "inherit"
        }
      );
      console.log("Copying package.xml");
      moveSync(`.tmp/package.xml`, `.tmp/${dir.path}/package.xml`, {
        overwrite: true
      });
    }

    mergedirs(`.tmp/${dir.path}`, `${targetDirectory}`, "overwrite");
    rmdirSync(".tmp");
  });
}

/**
 * Valida un despliegue a un entorno a la org indicada como parámetro
 * f.e: node scripts/source/unit-deploy-validation  zurich_prod
 *
 */
async function main() {
  try {
    let username = argv[2];

    // 1 - Crea una carpeta temporal deploy
    mkdirSync("deploy", { recursive: true });

    // 2 - Reconcilia los perfiles con el entorno a validar
    execSync(`sfdx sfpowerkit:source:profile:reconcile -u ${username}`, {
      stdio: "inherit"
    });

    // 3 - Convierte el proyecto a formato Metadata API y  valida contra el entorno
    convert_sfdx_project("deploy");

    // 4 - Deshace los cambios de los perfiles
    execSync(`git reset --hard`, {
      stdio: "inherit"
    });

    // 5 - Valida contra el entorno
    execSync(
      `sfdx force:mdapi:deploy --deploydir deploy --testlevel RunLocalTests --targetusername ${username} --verbose -c --wait 10 --json`,
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
