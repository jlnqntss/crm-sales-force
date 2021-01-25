const {
  mkdirSync,
  rmdirSync,
  readdirSync,
  renameSync,
  moveSync
} = require("fs-extra");
const { exec, execSync } = require("child_process");
const { argv } = require("process");
const { convertSFDXProject } = require("./convertSFDXProject");

/**
 * Valida un despliegue a un entorno a la org indicada como parámetro
 * f.e: node scripts/source/unit-deploy-to-dir  zurich_prod 0 C:/TEMP/
 *
 * f.npm (package.json): npm run deploy:dir zurichKlincT 0 C:/TEMP/ deploy
 *
 *   opcional
 *    - que hacer
 *      0: crear deploy y lanzarlo a salesforce CON --checkonly
 *      1: solo crear deploy
 *      2: solo lanzar a salesforce CON --checkonly
 *      3: solo lanzar SIN --checkonly
 *    - directorio destino donde hacer todo
 *    - directorio destino del deploy
 *
 */
async function main() {
  try {
    // Comprobar argumentos

    // instancia Salesforce
    let username = argv[2];
    if (typeof username === "undefined") {
      throw new Error("Tienes que especificar una instancia de Salesforce");
    }
    console.log("username [" + username + "]");

    // Que hacer
    let whatToExecute = argv[3];
    if (typeof whatToExecute === "undefined") {
      whatToExecute = 1;
    }
    console.log("whatToExecute [" + whatToExecute + "]");

    // Directorio destino
    let dir = argv[4];
    if (typeof dir == "undefined") {
      dir = "./";
    }
    if (dir.slice(-1) !== "/") {
      dir += "/";
    }
    console.log("dir [" + dir + "]");
    // deplory dir destino
    let deployTarget = argv[5];
    if (typeof deployTarget == "undefined") {
      deployTarget = "deploy";
    }

    // Configurar directorios de destino a partir de los argumentos
    let deployDir = dir + deployTarget;
    let tmpDir = dir + "tmp";
    let tmpProfile = dir + "profiles";
    console.log("deployDir [" + deployDir + "]");
    console.log("tmpDir [" + tmpDir + "]");
    console.log("tmpProfile [" + tmpProfile + "]");
    let checkOnly = "--checkonly";
    if (whatToExecute == 3) {
      checkOnly = "";
    }
    console.log("checkOnly [" + checkOnly + "]");

    // Ejecucion
    if (whatToExecute == 0 || whatToExecute == 1) {
      console.log(
        "------------------------------------------------------------------ Convirtiendo proyecto SFDX..."
      );
      // 1.1 - Crea una carpeta temporal deploy y profile
      mkdirSync(`${deployDir}`, { recursive: true });
      // 1.2 - Convierte el proyecto a formato Metadata API y  valida contra el entorno
      convertSFDXProject(`${deployDir}`, `${tmpDir}`);

      // 2.1 - Crear carpeta profiles
      mkdirSync(`${tmpProfile}`, { recursive: true });

      // 2.2 - Reconcilia los perfiles con el entorno a validar y lo deja en la carpta de profiles
      console.log(
        "------------------------------------------------------------------ Reconciliando perfiles..."
      );
      execSync(
        `sfdx sfpowerkit:source:profile:reconcile -u ${username} -d "${tmpProfile}"`,
        {
          stdio: "inherit"
        }
      );

      console.log(
        "------------------------------------------------------------------ Renombrando perfiles y copiando a deploy..."
      );
      // 2.3 - Renombra los perfiles para quitarles el -meta.xml
      await readdirSync(`${tmpProfile}`).forEach((file) => {
        const cleanString = require("text-cleaner");
        let new_file = cleanString(file).remove("-meta.xml").valueOf();
        console.log(file + " -> " + new_file);
        renameSync(
          `${tmpProfile}/` + file,
          `${tmpProfile}/` + new_file,
          (err) => {
            if (err) throw err;
            console.log(error);
          }
        );
        moveSync(
          `${tmpProfile}/` + new_file,
          `${deployDir}/profiles/` + new_file,
          {
            overwrite: true
          }
        );
      });
      await rmdirSync(`${tmpProfile}`, { recursive: true });
    }

    if (whatToExecute == 0 || whatToExecute == 2 || whatToExecute == 3) {
      console.log(
        "------------------------------------------------------------------ Lanzando DEPLOY => " +
          `${username}`
      );
      exec(`sfdx force:org:open -u ${username}`, { stdio: "inherit" });

      // DEPLOY
      // 4 - Valida contra el entorno --checkonly
      await exec(
        `sfdx force:mdapi:deploy --deploydir "${deployDir}" ${checkOnly} --testlevel RunLocalTests --targetusername ${username} --wait 10`,
        {
          stdio: "inherit"
        }
      );
    }
  } catch (error) {
    console.error(error);
  } finally {
    //rmdirSync(`${deployDir}`, { recursive: true });
  }
}

return main();
