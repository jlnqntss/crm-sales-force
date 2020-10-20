/**
 * Script de versionado de GitLab
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
    let { commits } = await gitLabService.compare({
      from: lastTag.target,
      to: process.env["CI_COMMIT_REF_NAME"]
    });

    await gitLabService.createTag({
      tag_name: new SemanticTag(lastTag).bump(commits).toString(),
      ref: process.env["CI_COMMIT_REF_NAME"]
    });
  } catch (error) {
    console.error(error);
    process.exit(1);
  }
}

return main();
