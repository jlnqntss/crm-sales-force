/**
 * Script de versionado de GitLab
 *
 * @author jmartinezpisson
 */

const { execSync } = require("child_process");

// 1 - Se lanza Standard-Version
execSync("npx standard-version");

// 2 - Se realiza el push al repo
execSync("git push -o ci.skip");
