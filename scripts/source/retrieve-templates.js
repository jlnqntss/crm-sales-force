/**
 * Script de recuperación de plantillas de email clásicas.
 * Solventa el error de SFDX para gestionar metadatos de plantillas
 *
 * @author jmartinezpisson
 */

const fs = require("fs");
const { execSync } = require("child_process");

// 1 - Se eliminar los archivos temporales
fs.unlink("manifest/package_templates.xml", (err) => {
  if (err) throw err;
});

// 2 - Se recuperan las carpetas de email
const emailFolders = JSON.parse(
  execSync("sfdx force:mdapi:listmetadata --metadatatype=EmailFolder --json", {
    encoding: "utf-8"
  })
).result;

let emailTemplateNames = [];

// 3 - Se recuperan las plantillas por carpeta, y se meten los nombre de template en un array
emailFolders.forEach((folder) => {
  try {
    const emailTemplates = JSON.parse(
      execSync(
        `sfdx force:mdapi:listmetadata --metadatatype=EmailTemplate --folder=${folder.fullName} --json`,
        {
          encoding: "utf-8"
        }
      )
    ).result;

    if (emailTemplates.map) {
      emailTemplateNames = emailTemplateNames.concat(
        emailTemplates.map((template) => {
          return template.fullName;
        })
      );
    } else {
      console.log(`No templates on ${folder.fullName}`);
    }
  } catch (err) {
    console.error("Error retrieving " + folder.fullName);
    console.error(err);
  }
});

// 4 - Se genera un package con los nombre de plantilla
let package = `
<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"yes\"?>
<Package xmlns=\"http://soap.sforce.com/2006/04/metadata\">
   <types>
      <members>${emailTemplateNames.join(
        "</members>\n        <members>"
      )}</members>
      <name>EmailTemplate</name>
   </types>
   <types>
   <members>${emailFolders
     .map((folder) => {
       return folder.fullName;
     })
     .join("</members>\n        <members>")}</members>
   <name>EmailFolder</name>
</types>
</Package>`;

fs.writeFileSync("manifest/package_templates.xml", package);

// 5 - Se recuperan las plantillas usando el estándar
execSync(
  "sfdx force:source:retrieve --manifest=manifest/package_templates.xml"
);

// 6 - Se eliminan los archivos temporales
fs.unlink("manifest/package_templates.xml", (err) => {
  if (err) throw err;
});
