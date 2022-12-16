/**
 * Genera una nueva versión del proyecto, entendiendo como tal crear un tag sobre un commit con una número de versión semántica.
 * Se diferencia entre:
 * - Release-Candidates (versiones con las que es posible iniciar un proceso de release)
 * - Versiones de UAT/QA (versiones desplegadas en UAT para su validación en dichos entornos)
 * - Versiones de Producción (versión finalmente desplegada en producción una vez se ha finalizado el proceso de release)
 *
 * @author jmartinezpisson
 */
const GitlabAPIService = require("./GitLabAPI").default;
const { getLastSemanticTag, SemanticTag } = require("./SemanticTag");

async function findLastSemanticTag(tagSuffix) {
  const gitLabService = new GitlabAPIService({
    baseUrl: process.env["CI_API_V4_URL"],
    projectId: process.env["CI_PROJECT_ID"],
    token: process.env["CI_GITLAB_TOKEN"]
  });

  // 1 - Se obtienen las etiquetas de la referencia
  let currentBranchTags = await gitLabService.getTags();

  // 2 - Se busca as través de expresión regular la etiqueta de versionado semántico con el sufijo de tipo
  let tagToSearch = new RegExp(`^\d*\.\d*\.\d*-${tagSuffix}`);
  let lastTag = getLastSemanticTag(currentBranchTags, tagToSearch);

  // 3 - Si no existe tag, se genera la inicial
  if (!lastTag) {
    return await gitLabService.createTag({
      tag_name: "1.0.0-" + tagSuffix,
      ref: process.env["CI_COMMIT_REF_NAME"]
    });
  }
}

/**
 * Script autoejecutado de node sobre una rama de Gitlab.
 *
 * @returns {}
 */
async function main() {
  const versionTagSuffix =
    process.env["CI_COMMIT_REF_NAME"] === "dev" ? "rc" : "UAT";

  try {
    // 1 - Se busca la última tag de versión de la rama sobre la que se ejecuta el pipeline
    let lastTag = await findLastSemanticTag(versionTagSuffix);

    // 2 - Se realiza una comparativa entre la rama y la etiqueta para obtener los commits que se han incluido
    const gitLabService = new GitlabAPIService({
      baseUrl: process.env["CI_API_V4_URL"],
      projectId: process.env["CI_PROJECT_ID"],
      token: process.env["CI_GITLAB_TOKEN"]
    });

    let { commits } = await gitLabService.compare({
      from: lastTag.target,
      to: process.env["CI_COMMIT_REF_NAME"]
    });

    // 3 - Se genera la nueva etiqueta en base a los cambios introducidos
    let newTagName = new SemanticTag(lastTag).bump(commits).toString();

    // 4 - Si el último commit ya está etiquetado, o no se han producido cambios
    if (
      process.env["CI_COMMIT_REF_NAME"].includes(lastTag.name) ||
      newTagName === lastTag.name
    ) {
      console.log(
        `[Info] La rama ya está en la versión ${lastTag.name}. Finalizando`
      );

      process.exit(0);
    }

    console.log(`[Info] Subiendo versión y etiquetando como ${newTagName}...`);

    await gitLabService.createTag({
      tag_name: newTagName,
      ref: process.env["CI_COMMIT_REF_NAME"]
    });
  } catch (error) {
    console.error("[Error] No se ha podido generar la etiqueta");
    console.error(error);
    process.exit(1);
  }
}

return main();
