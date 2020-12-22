# Zurich OCS

## Referencia DevOps

La metodología DevOps aplicada en el proyecto, junto con la referencia de entornos y workflows a aplicar en el proyecto se encuentra recogida en los enlaces siguientes

1. [Estructura de proyecto](https://zurichspain.atlassian.net/wiki/spaces/OCS/pages/606404711/Organizaci%2Bn%2Bde%2Bproyecto%2BSalesforce)
2. [Pipeline de entornos](https://zurichspain.atlassian.net/wiki/spaces/OCS/pages/607682565/Pipeline+de+entornos)
3. [Estrategia de versionado](https://zurichspain.atlassian.net/wiki/spaces/OCS/pages/609058817/Estrategia+de+versionado)

## Configuración Pipelines CI/CD

### Entornos

El pipeline de entornos recogido en [Pipeline de entornos](https://zurichspain.atlassian.net/wiki/spaces/OCS/pages/607682565/Pipeline+de+entornos) se configura a nivel de CI mediante el uso de variables

- STAGING_SANDBOX_AUTH_URL: URL de autenticación SFDX para el entorno SF Staging
- QA_SANDBOX_AUTH_URL: URL de autenticación SFDX para el entorno SF QA
- DEVHUB_AUTH_URL: URL de autenticación SFDX para el DevHub/Producción de Zurich

### Personalización del proceso

Las siguientes variables CI/CD permiten modificar el comportamiento de los pipeline:

| Nombre        | Descripción                                 | Valores Posibles |
| ------------- | ------------------------------------------- | :--------------: |
| TEST_DISABLED | Deshabilita tests preliminares/post-staging |       0/1        |
| ALLOW_FAILURE | Permite que las etapas de testing fallen    |       0/1        |

## Organización proyecto

El código del proyecto se distribuye por las siguientes carpetas

| Nombre           | Descripción                                                                                                                                             |
| ---------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| zurich-base      | Paquete base de la instancia de Zurich. Contiene el código base del proyecto incluyendo el modelo de datos y código compartido por el resto de paquetes |
| zurich-base-iam  | Paquete que contiene la integración con el IAM de Zurich                                                                                                |
| zurich-klinc-app | Paquete que contiene las apps de Klinc y su configuración                                                                                               |
| zurich-ocs-app   | Paquete que contiene las apps de uso general de Zurich One Customer Service y su configuración                                                          |

Se valorará en futuros sprints realizar una de las acciones siguientes:

- División adicional del core en cuatro paquetes:

| Nombre                 | Descripción                                                                                                |
| ---------------------- | ---------------------------------------------------------------------------------------------------------- |
| zurich-base-objects    | Modelo de datos compartido por todas las aplicaciones                                                      |
| zurich-base-code       | Desarrollos y arquitectura compartida por todas las aplicaciones, como el Logger o la factoría de triggers |
| zurich-base-ui         | Estilos, páginas y aplicaciones compartidas por todos los paquetes                                         |
| zurich-base-unpackaged | Metadatos sin consolidar en paquete y que requieren de despliegue manual                                   |
| zurich-base-settings   | Datos, como registros y usuarios, que serán tratados a través de automatización CI                         |

- Estructuración de paquetes en carpetas

| Nombre | Descripción                     |
| ------ | ------------------------------- |
| main   | Metadatos generales del paquete |
| test   | Tests Apex y LWC                |
