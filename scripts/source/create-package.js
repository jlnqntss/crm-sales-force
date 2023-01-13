const {
    mkdirSync,
    rmdirSync,
    readdirSync,
    renameSync,
    moveSync,
    copySync
  } = require("fs-extra");
  const { exec, execSync } = require("child_process");
  const { argv } = require("process");
const fs = require('fs');

function main() {
    console.log('Parametros:')

    // Directorio de trabajo
    let tmpDir = argv[2];
    if (typeof tmpDir == "undefined")  throw new Error("Tienes que especificar un directorio de trabajo. Ej. C:/Temp/Packages/");
    if (tmpDir.slice(-1) !== "/") tmpDir += "/";
    console.log("\ttmpDir [" + tmpDir + "]");

    // Nombre del paquete
    let packageName = argv[3];
    if (typeof packageName == "undefined")  throw new Error("Tienes que especificar un nombre de paquete. Ej. TarificaV1");
    console.log("\tpackageName [" + packageName + "]");
    
    // Que hacer
    let accion = argv[4];
    if (typeof accion === "undefined") throw new Error("Tienes que especificar una accion 0:crear paquete / 1:hacer deploy");
    console.log("\taccion [" + accion + "]");

    let commitId;
    let username;
    if( accion == 0 ) {
        // Commit id
        commitId = argv[5];
        if (typeof commitId === "undefined") commitId = '';
        console.log("\tcommitId [" + commitId + "]");
    } else {
        // Instancia de Salesforce
        username = argv[5];
        if (typeof username === "undefined") throw new Error("Tienes que especificar una instancia de Salesforce");
        console.log("\tusername [" + username + "]");
    }


    // Si lanzar con pruebas
    let checkOnly = "--checkonly";

    // Directorio del paquete
    let packageDir = tmpDir + packageName;
    mkdirSync(`${packageDir}`, { recursive: true });
    
    if( accion == 0 ) {
        console.log('------------------------------------------------------------------ Obteniendo cambios de git');
        // Cambios activos ahora mismo
        let gitCommand = `git ls-files --other --modified --exclude-standard`;
        // Cambios por commits
        if( commitId !== '' ) {
            gitCommand = `git diff-tree --no-commit-id --name-only -r ${commitId}`;   
        }
        let gitCambios = execSync(gitCommand).toString();

        crearPackage(gitCambios, packageDir, packageName);

    } else if( accion == 1 ) {
        console.log('------------------------------------------------------------------ Lanzando RECONCILE => ' + username);
        if (fs.existsSync(`${packageDir}/${packageName}.profiles`)) {
            let perfiles = fs.readFileSync(`${packageDir}/${packageName}.profiles`).toString().split(',');
            console.log(perfiles);
            sobreescribirPefiles(packageDir, packageName, perfiles, username);
        } else {
            copySync(`${packageDir}/${packageName}.zip`,`${packageDir}/${packageName}.${username}.zip`, {overwrite: true});
        }
    } else if( accion == 2 ) {
        console.log('------------------------------------------------------------------ Lanzando DEPLOY => ' + username);
        exec(
            `sfdx force:mdapi:deploy -s -f "${packageDir}/${packageName}.${username}.zip" ${checkOnly} --testlevel RunLocalTests --targetusername ${username} --wait 10`,
            {
              stdio: "inherit"
            }
        );
    } else if( accion == 3 ) {
        console.log("------------------------------------------------------------------ Reconciliando perfiles => " + username);
        execSync(
            `sfdx sfpowerkit:source:profile:reconcile -u ${username} -d "${packageDir}/tmpprofiles2"`,
            {
              stdio: "inherit"
            }
          );
    }
}

function sobreescribirPefiles(packageDir, packageName, perfiles, username) {
    console.log('Sobreescribiendo pefiles...');
    
    console.log("\tReconciliando perfiles => " + username);
    let listaPerfiles = perfiles.join(',');
    execSync(`sfdx sfpowerkit:source:profile:reconcile -u ${username} -n "${listaPerfiles}" -d "${packageDir}/tmpprofiles"`, {stdio: "inherit"});

    console.log('\tDescomprimiendo zip...');
    execSync(`unzip -o -d "${packageDir}/tmppackage" "${packageDir}/${packageName}.zip`);

    console.log('\tCopiando perfiles...');
    perfiles.forEach(perfil => {
        copySync(`${packageDir}/tmpprofiles/${perfil}.profile-meta.xml`,`${packageDir}/tmppackage/profiles/${perfil}.profile`, {overwrite: true});
    });
    
    console.log('\tComprmiento zip...');
    execSync(`zip -r ${packageName}.zip *`, {
        cwd: `${packageDir}/tmppackage`
    });
    console.log('\tCopiando paquete al directorio raiz...');
    copySync(`${packageDir}/tmppackage/${packageName}.zip`,`${packageDir}/${packageName}.${username}.zip`, {overwrite: true});

    rmdirSync(`${packageDir}/tmppackage`, { recursive: true });
    rmdirSync(`${packageDir}/tmpprofiles`, { recursive: true });
}

function crearPackage(gitCambios, packageDir, packageName) {
    let dirEntries = gitCambios.split('\n');

    // Generar package.xml
    console.log('Generando package.xml .......');

    // 1. Por cada linea del git se mira si es un perfil
    let lista = [];
    for(let i = 0; i < dirEntries.length; i++ ) {
        let linea = dirEntries[i];

        if( linea !== '') {
            if( !linea.includes('/profiles/') ) lista.push(linea);
        }
    }
    // 2. se crea un string separado por coma
    let listado = lista.join(',');
    // console.log(listado);
    // 3. se convierte a formato metadatos
    execSync(`sfdx force:source:convert -r ./ -d ${packageDir}/${packageName} -p "${listado}"`);
    
    console.log('\tComprmiento package en zip...');
    execSync(`zip -r ${packageName}.zip *`, {
        cwd: `${packageDir}/${packageName}`
    });
    moveSync(`${packageDir}/${packageName}/${packageName}.zip`,`${packageDir}/${packageName}.zip`, {overwrite: true});
}

return main();