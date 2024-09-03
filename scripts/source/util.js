const fs = require("fs");
const { execSync } = require("child_process");
const FindFolder = require("node-find-folder");
const GitlabAPIService = require("./GitLabAPI").default;
const { getLastSemanticTag, SemanticTag } = require("./SemanticTag");


/**
 * Ejecuta un comando del SF Cli y muestra el resultado en pantalla
 * @param {string} command
 * @returns {void}
 */
function executeSfCliCommand(command) {
  return executeSfdxCommand(command, {
    skipJsonParsing: true,
    stdio: 'inherit'
  });
}

/**
 * Ejecuta un comando de SFDX y parsea el resultado como un JSON
 * @param {string} command
 * @returns {SfdxResult}
 */
function executeSfCliScriptableCommand(command) {
  return executeSfdxCommand(command, {
    skipJsonParsing: false,
    encoding: 'utf8',
    stdio: []
  });
}

/**
 * Ejecuta un comando de Bash con las opciones indicadas
 *
 * @author jmartinezpisson
 * @param {String} command
 * @param {ExecSyncOptionsWithStringEncoding} options Opciones de ejecució
 * @param {String} sfdxAuthInfo.alias Alias de la org
 */
function executeBash(command, options = {}) {
  return execSync(command, {
    encoding: "utf8",
    shell: false,
    maxBuffer: 2048 * 2048,
    ...options
  });
}


/**
 * Ejecuta un comando de Bash con las opciones indicadas
 *
 * @author jmartinezpisson
 * @param {String} command
 * @param {ExecSyncOptionsWithStringEncoding} options Opciones de ejecució
 * @param {String} sfdxAuthInfo.alias Alias de la org
 */
function executeSfdxCommand(bash, options = {}) {
  let sfdxCommand = bash;
  let sfdxJsonResult, sfdxResult;

  if (!sfdxCommand.includes("--json") && !options.skipJsonParsing) {
    sfdxCommand += " --json";
  }

  try {
    console.log(`[Command] ${sfdxCommand}`);
    sfdxJsonResult = executeBash(sfdxCommand, {
      stdio: options.stdio
    });

  } catch (bashError) {
    sfdxJsonResult = bashError.stdout;
  }

  if (options.skipJsonParsing) {
    return sfdxJsonResult;
  }

  try {
    sfdxResult = JSON.parse(sfdxJsonResult);
  } catch (error) {
    console.error(`[Error] Ejecución de comando SFDX: Parseo de resultado`);
    console.error(`[Error] Result: ${sfdxJsonResult}`);
    console.error(`[Error] ${error.message}`);
    sfdxResult = {};
  }

  if (sfdxResult.status !== 0 || sfdxResult.status === undefined) {
    console.error(
      `[Error] Ejecución de comando SFDX: ${sfdxResult.commandName}`
    );
    console.error(`[Error] ${sfdxResult.name}: ${sfdxResult.message}`);
    console.error(`[StackTrace] ${sfdxResult.stack}`);
    throw new Error(`${sfdxResult.name}: ${sfdxResult.message}`);
  }

  return sfdxResult.result;
}

/**
 * Obtiene la definición del proyecto SFDX
 */
function getSfdxProjectDefinition() {
  try {
    return JSON.parse(
      fs.readFileSync("sfdx-project.json", { encoding: "UTF-8" })
    );
  } catch (error) {
    console.error(`[Error] Parseo de definición de proyecto SFDX`);
    console.error(`[Message] ${error.message}`);
    console.error(`[StackTrace] ${error.stackTrace}`);
    throw error;
  }
}

/**
 * Obtiene el nombre de usuario/org configurado por defecto
 */
function getTargetSfdxOrgUsername() {
  try {
    console.log(`[Info] Obtención de usuario SFDX`);

    let configGetResult = executeSfdxCommand(
      `sf config set defaultusername --json`
    );

    return configGetResult[0].value;
  } catch (error) {
    throw new Error(
      "[Error] Obtención de usuario SFDX: No se ha podido recuperar el usuario de la org objetivo de SFDX"
    );
  }
}

/**
 * Obtiene el nombre de usuario/org configurado por defecto
 */
function setTargetSfdxOrgUsername(username) {
  try {
    console.log(`[Info] Configurando usuario SFDX`);
    executeSfdxCommand(`sf config set defaultusername=${username}`);
    console.log(
      `[Info] Configurando usuario SFDX: Configurado ${username} como usuario SFDX`
    );
  } catch (error) {
    throw new Error(
      `[Error] Configurando usuario SFDX: No se ha podido establecer ${username} como la org objetivo de SFDX`
    );
  }
}

/**
 *
 * @param {SFDXAuthInfo} sfdxAuthInfo
 * @param {String} sfdxAuthInfo.authUrl URL de autenticación SFDX
 * @param {String} sfdxAuthInfo.alias Alias de la org
 */
function authenticate(sfdxAuthInfo) {
  console.log(`[Info] Autenticando URL SFDX ${sfdxAuthInfo.authUrl}`);
  fs.writeFileSync("authInfo.txt", sfdxAuthInfo.authUrl);
  executeSfdxCommand(
    `sf org login sfdx-url --sfdx-url-file authInfo.txt --alias ${sfdxAuthInfo.alias}`
  );
  console.log(
    `[Info] Autenticando URL SFDX: Autenticación de ${sfdxAuthInfo.alias} realizada`
  );
  setTargetSfdxOrgUsername(sfdxAuthInfo.alias);
}

/**
 * Identifica si deberían ejecutarse los tests locales, validando que exista una carpeta __tests__ que los contenga
 */
function shouldRunLocalTests() {
  let findFolderResult = new FindFolder(`__tests__`);

  return findFolderResult.length > 0 ? true : false;
}

/**
 * Identifica si deberían ejecutarse los tests locales, validando que exista una carpeta __tests__ que los contenga
 */
function shouldLintLWC() {
  let findFolderResult = new FindFolder(`lwc`);

  return findFolderResult.length > 0 ? true : false;
}

/**
 * Identifica si deberían ejecutarse los tests locales, validando que exista una carpeta __tests__ que los contenga
 */
function shouldLintAura() {
  let findFolderResult = new FindFolder(`aura`);

  return findFolderResult.length > 0 ? true : false;
}

function runScan() {
  executeBash(`sf scanner run --target force-app`);
}

function runOrgTests() {
  executeBash(
    `sf apex run test --code-coverage --result-format junit --wait 10 --output-dir ./tests/apex`
  );
}

function runLocalTests() {
  if (!shouldRunLocalTests()) {
    console.log("[Info] No hay tests JavaScript para ejecutar");
  }

  executeBash(`sfdx-lwc-jest --skipApiVersionCheck --coverage`);
}

function generateSfdxDelta(targetCommit) {
  if (!fs.existsSync(".deploy")) {
    fs.mkdirSync(".deploy");
  }

  let result_string = executeBash(
    `sf sgd source delta --from ${targetCommit} --output .deploy`,
    {skipJsonParsing: true}
  );
  console.log('Result string ' + result_string);
  let result = JSON.parse(
    result_string
  );
  console.log('Result ' + result);
  if (!result.success) {
    console.error(`[Error] Ejecución de comando SFDX: ${result.error}`);
    console.error(
      `[Command] sf sgd source delta --from ${targetCommit} --output .deploy`
    );

    throw new Error(`SFDX Delta: ${result.error}`);
  }
}

function deploy(deployConfig) {
  let deployOptions = ["--wait 180", "--ignore-conflicts"];

  // 1 - Reconciliación de perfiles
  console.log(
    `[Info] Deploy: Reconciliando perfiles con usuario ${deployConfig.targetOrg}...`
  );
  executeSfdxCommand(
    `sfp profile:reconcile --targetorg ${deployConfig.targetOrg}`,
    {
      stdio: "inherit",
      skipJsonParsing: true
    }
  );

  // 2 - Tipo de despliegue: Si es modalidad de despliegue diferencial, se ejecuta un delta de despliegue comparando contra la rama destino
  deployConfig.targetCommit = 'b339be89d1619aed5dfe30b62e9cdaa9c39ecfa2'; //  debug
  if (deployConfig.targetCommit) {
    console.log(
      `[Info] Deploy: Modalidad de despliegue diferencial. Generando delta...`
    );
    generateSfdxDelta(deployConfig.targetCommit);
    deployOptions.push(
      "--manifest .deploy/package/package.xml --post-destructive-changes .deploy/destructiveChanges/destructiveChanges.xml"
    );
  } else {
    console.log(`[Info] Deploy: Modalidad de despliegue completo`);
    // En caso contrario, se hace un despliegue completo
    deployOptions.push("--source-dir force-app");
  }

  // 3 - Se añade la ejecución de tests
  if (deployConfig.testLevel) {
    console.log(
      `[Info] Deploy: Se ejecutarán los tests en modo ${deployConfig.testLevel}`
    );
    deployOptions.push(`--test-level ${deployConfig.testLevel}`);

    if (deployConfig.testLevel === "RunSpecifiedTests") {
      console.log(
        `[Info] Deploy: Se ejecutarán las siguientes clases de Test ${deployConfig.testClasses.join(
          ","
        )}`
      );
      deployOptions.push(`--tests "${deployConfig.testClasses.join(" ")}"`);
    }
  }

  // 4 - Se identifica si es una validación
  if (deployConfig.checkOnly) {
    console.log(`[Info] Deploy: Se ejecutará una validación`);
    deployOptions.push("--dry-run");
  }

  // 6 - Se ejecuta el despliegue, dependiendo de si se lanza validación o no
  console.log(`[Info] Deploy: Encolando despliegue...`);
  let result = executeSfdxCommand(
    `sf project deploy start ${deployOptions.join(" ")}`, 
    {
      skipJsonParsing: false,
      stdio: [],
    }
  );
  console.log('Parseando resultado...');
  let deployJob = JSON.parse(result);
  //console.log(deployJob);
  const deployResult = deployJob.result;

  // 7 - Se guarda el Id. para lanzar posteriormente el Quick Deploy, si aplica

  // 8 - Mostrando informe de despliegue
  console.log(`[Info] Deploy: Validando resultados del despliegue...`);
  console.log(`[Info] Deploy: Id Despliegue: ${deployResult.id}`);

  executeSfCliCommand(
    `sf project deploy report --job-id ${deployResult.id} --wait ${deployConfig.timeout ? deployConfig.timeout : 60
    }`
  );

  console.log(
    `[Info] Deploy: Recuperando detalle del despliegue ${deployResult.id}`
  );

  let deployReport = executeSfCliScriptableCommand(`sf project deploy report --job-id ${deployResult.id} --json`);

  fs.writeFileSync("results.json", JSON.stringify(deployReport));
}

async function findLastSemanticTag(targetSuffix) {
  const gitLabService = new GitlabAPIService({
    baseUrl: process.env["CI_API_V4_URL"],
    projectId: process.env["CI_PROJECT_ID"],
    token: process.env["CI_GITLAB_TOKEN"]
  });

  // 1 - Se obtienen las etiquetas de la referencia
  let currentBranchTags = await gitLabService.getTags();

  // 2 - Se define la expresión regular de búsqueda
  // 2 - Se busca a través de expresión regular la etiqueta de versionado semántico con el sufijo de tipo
  let tagToSearch = new RegExp(
    `^\\d*\.\\d*\.\\d*${targetSuffix ? "-" + targetSuffix : ""}`
  );
  let lastTag = getLastSemanticTag(currentBranchTags, tagToSearch);

  // 3 - Si no existe tag, se genera la inicial
  if (!lastTag) {
    return gitLabService.createTag({
      tag_name: `1.0.0${targetSuffix ? "-" + targetSuffix : ""}`,
      ref: process.env["CI_COMMIT_REF_NAME"]
    });
  }
  return lastTag;
}

module.exports = {
  authenticate,
  deploy,
  runScan,
  runLocalTests,
  runOrgTests,
  findLastSemanticTag
};
