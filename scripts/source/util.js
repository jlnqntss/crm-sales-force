const fs = require("fs");
const { execSync } = require("child_process");
const FindFolder = require("node-find-folder");
const GitlabAPIService = require("./GitLabAPI").default;
const { getLastSemanticTag, SemanticTag } = require("./SemanticTag");

function executeBash(command, options = {}) {
  console.log();
  return execSync(command, {
    encoding: "utf8",
    ...options
  });
}

function executeSfdxCommand(bash, options = {}) {
  var sfdxCommand = bash;
  var sfdxJsonResult, sfdxResult;

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
    throw `${sfdxResult.name}: ${sfdxResult.message}`;
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
      `sfdx force:config:get defaultusername --json`
    );

    return configGetResult[0].value;
  } catch (error) {
    throw "[Error] Obtención de usuario SFDX: No se ha podido recuperar el usuario de la org objetivo de SFDX";
  }
}

/**
 * Obtiene el nombre de usuario/org configurado por defecto
 */
function setTargetSfdxOrgUsername(username) {
  try {
    console.log(`[Info] Configurando usuario SFDX`);
    executeSfdxCommand(`sfdx force:config:set defaultusername=${username}`);
    console.log(
      `[Info] Configurando usuario SFDX: Configurado ${username} como usuario SFDX`
    );
  } catch (error) {
    throw `[Error] Configurando usuario SFDX: No se ha podido establecer ${username} como la org objetivo de SFDX`;
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
    `sfdx force:auth:sfdxurl:store --sfdxurlfile authInfo.txt --setalias ${sfdxAuthInfo.alias}`
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
  executeBash(`sfdx scanner:run -t force-app`);
}

function runOrgTests() {
  executeBash(
    `sfdx force:apex:test:run --codecoverage --resultformat junit --wait 10 --outputdir ./tests/apex`
  );
}

function runLocalTests() {
  executeBash(`sfdx-lwc-jest --skipApiVersionCheck --coverage`);
}

function generateSfdxDelta(targetCommit) {
  if (!fs.existsSync(".deploy")) {
    fs.mkdirSync(".deploy");
  }

  let result = JSON.parse(
    executeSfdxCommand(
      `sfdx sgd:source:delta --from ${targetCommit} -o .deploy`,
      { skipJsonParsing: true }
    )
  );

  if (!result.success) {
    console.error(`[Error] Ejecución de comando SFDX: ${result.error}`);
    console.error(
      `[Command] sfdx sgd:source:delta --from ${targetCommit} -o .deploy`
    );

    throw `SFDX Delta: ${result.error}`;
  }
}

function deploy(deployConfig) {
  let deployOptions = ["--wait 0"];

  // 1 - Reconciliación de perfiles
  console.log(
    `[Info] Deploy: Reconciliando perfiles con usuario ${deployConfig.targetOrg}...`
  );
  executeSfdxCommand(
    `sfdx sfpowerkit:source:profile:reconcile -u ${deployConfig.targetOrg}`,
    {
      stdio: "inherit",
      skipJsonParsing: true
    }
  );

  // 2 - Tipo de despliegue: Si es modalidad de despliegue diferencial, se ejecuta un delta de despliegue comparando contra la rama destino
  if (deployConfig.targetCommit) {
    console.log(
      `[Info] Deploy: Modalidad de despliegue diferencial. Generando delta...`
    );
    generateSfdxDelta(deployConfig.targetCommit);
    deployOptions.push(
      "--manifest .deploy/package/package.xml --postdestructivechanges .deploy/destructiveChanges/destructiveChanges.xml"
    );
  } else {
    console.log(`[Info] Deploy: Modalidad de despliegue completo`);
    // En caso contrario, se hace un despliegue completo
    deployOptions.push("--sourcepath force-app");
  }

  // 3 - Se añade la ejecución de tests
  if (deployConfig.testLevel) {
    console.log(
      `[Info] Deploy: Se ejecutarán los tests en modo ${deployConfig.testLevel}`
    );
    deployOptions.push(`--testlevel ${deployConfig.testLevel}`);

    if (deployConfig.testLevel === "RunSpecifiedTests") {
      console.log(
        `[Info] Deploy: Se ejecutarán las siguientes clases de Test ${deployConfig.testClasses.join(
          ","
        )}`
      );
      deployOptions.push(`--runtests "${deployConfig.testClasses.join(",")}"`);
    }
  }

  // 4 - Se identifica si es una validación
  if (deployConfig.checkOnly) {
    console.log(`[Info] Deploy: Se ejecutará una validación`);
    deployOptions.push("--checkonly");
  }

  // 6 - Se ejecuta el despliegue, dependiendo de si se lanza validación o no
  console.log(`[Info] Deploy: Encolando despliegue...`);
  let deployResult = executeSfdxCommand(
    `sfdx force:source:deploy ${deployOptions.join(" ")}`
  );

  // 7 - Se guarda el Id. para lanzar posteriormente el Quick Deploy, si aplica

  // 8 - Mostrando informe de despliegue
  console.log(`[Info] Deploy: Validando resultados del despliegue...`);
  console.log(`[Info] Deploy: Id Despliegue: ${deployResult.id}`);
  executeSfdxCommand(
    `sfdx force:source:deploy:report --jobid ${deployResult.id} --wait ${
      deployConfig.timeout ? deployConfig.timeout : 60
    }`,
    {
      skipJsonParsing: true,
      stdio: "inherit"
    }
  );

  console.log(
    `[Info] Deploy: Recuperando detalle del despliegue ${deployResult.id}`
  );

  let deployReport = executeSfdxCommand(
    `sfdx force:source:deploy:report --jobid ${deployResult.id}`
  );

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
    `^\d*\.\d*\.\d*${targetSuffix ? "-" + targetSuffix : ""}`
  );
  let lastTag = getLastSemanticTag(currentBranchTags, tagToSearch);

  // 3 - Si no existe tag, se genera la inicial
  if (!lastTag) {
    return await gitLabService.createTag({
      tag_name: `1.0.0${targetSuffix ? targetSuffix + "" : ""}`,
      ref: process.env["CI_COMMIT_REF_NAME"]
    });
  }
}

module.exports = {
  authenticate,
  deploy,
  runScan,
  runLocalTests,
  runOrgTests,
  findLastSemanticTag
};
