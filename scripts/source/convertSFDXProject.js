const { readFileSync, rmdirSync, existsSync, moveSync } = require("fs-extra");
const mergedirs = require("merge-dirs").default;
const { execSync } = require("child_process");

/**
 * Convierte el proyecto SFDX al formato Metadata API, que permite hacer validación completa
 * @param {String} targetDirectory
 */
function convertSFDXProject(targetDirectory, tmpDirectory) {
  const sfdxProject = JSON.parse(
    readFileSync("sfdx-project.json", { encoding: "utf-8" })
  );

  console.log("Converting project...");

  sfdxProject.packageDirectories.forEach((dir) => {
    console.log(`Converting package ${dir.path}...`);
    execSync(
      `sfdx force:source:convert -r "${dir.path}" -d "${tmpDirectory}/${dir.path}"`
    );

    if (existsSync(`${targetDirectory}/package.xml`)) {
      console.log("Merging package.xml");
      execSync(
        `sfdx sfpowerkit:project:manifest:merge -p "${tmpDirectory}/${dir.path}/package.xml,${targetDirectory}/package.xml" -d "${tmpDirectory}"`,
        {
          stdio: "inherit"
        }
      );
      console.log("Copying package.xml");
      moveSync(`${tmpDirectory}/package.xml`, `${tmpDirectory}/${dir.path}/package.xml`, {
        overwrite: true
      });
    }

    mergedirs(`${tmpDirectory}/${dir.path}`, `${targetDirectory}`, "overwrite");
    rmdirSync(`${tmpDirectory}`, {
      recursive: true
    });
  });
}

module.exports = {
  convertSFDXProject
};
