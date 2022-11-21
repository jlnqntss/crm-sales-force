/**
 * Script de formateo automático de clases y triggers Apex a través de Uncrustify
 *
 * @author jmartinezpisson
 */

const fs = require("fs");
const { execSync } = require("child_process");

// 1 - Se obtiene un listado de clases y triggers Apex modificados
let files = execSync("git diff --cached --name-only --diff-filter=ACM", {
  encoding: "utf-8"
})
  .split("\n")
  .filter((filepath) => {
    return filepath.endsWith(".cls") || filepath.endsWith(".trigger");
  });

// 2 - Se lanza la ejecución de uncrustify
files.forEach((filepath) => {
  try {
    execSync(
      `uncrustify -l JAVA -c "config/apex-uncrustify.cfg" --replace --no-backup ${filepath}`,
      {
        encoding: "utf-8",
        shell: false
      }
    );

    execSync(`git add ${filepath}`, {
      encoding: "utf-8"
    });
  } catch (error) {
    console.error(error);
  }
});
