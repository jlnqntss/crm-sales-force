const { readFileSync, rmdirSync, existsSync, moveSync } = require("fs-extra");
const mergedirs = require("merge-dirs").default;
const { execSync } = require("child_process");

/**
 * Convierte el proyecto SFDX al formato Metadata API, que permite hacer validación completa
 * @param {String} targetDirectory
 */
function convertSFDXProject(targetDirectory) {
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
    rmdirSync(".tmp", {
      recursive: true
    });
  });
}

module.exports = {
  convertSFDXProject
};
