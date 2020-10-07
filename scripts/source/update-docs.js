/**
 * Script de generación y push de documentación en GitLab
 *
 * @author jmartinezpisson
 */

const COMMIT_MSG = "actualizada documentación";
const { execSync } = require("child_process");

// 1 - Se lanza el plugin de documentación
execSync("sfdx nts1:docs:generate --format=asciidoc");

// 2 - Se lanza un commit y un update al proceso
execSync(
  `git add docs/* && git commit -m "docs: ${COMMIT_MSG}" && git push -o ci.skip`
);
