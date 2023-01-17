/**
 * Generación de releases. Basado en pipelines Zurich
 *
 * @author jmartinezpisson
 */
const GitlabAPIService = require("./GitLabAPI").default;
const { getLastSemanticTag, SemanticTag } = require("./SemanticTag");

async function main() {
  try {
    const gitLabService = new GitlabAPIService({
      baseUrl: process.env["CI_API_V4_URL"],
      projectId: process.env["CI_PROJECT_ID"],
      token: process.env["CI_GITLAB_TOKEN"]
    });

    let lastTag = getLastSemanticTag(
      await gitLabService.getTags(),
      process.env["CI_COMMIT_REF_NAME"] === "dev"
        ? /^\d*\.\d*\.\d*-rc$/
        : /^\d*\.\d*\.\d*-UAT$/
    );

    if (!lastTag) {
      console.error("No tag found");
      process.exit(1);
    }

    let { commits } = await gitLabService.compare({
      from: lastTag.target,
      to: process.env["CI_COMMIT_REF_NAME"]
    });

    console.log(new SemanticTag(lastTag).bump(commits).toString());
  } catch (error) {
    console.error(error);
    process.exit(1);
  }
}

return main();
