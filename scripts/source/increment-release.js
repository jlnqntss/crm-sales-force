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

    if (!lastTag) {
      return await gitLabService.createTag({
        tag_name:
          process.env["CI_COMMIT_REF_NAME"] === "dev"
            ? "1.0.0-rc"
            : "1.0.0-UAT",
        ref: process.env["CI_COMMIT_REF_NAME"]
      });
    }

    if (process.env["CI_COMMIT_REF_NAME"].includes(lastTag.name)) {
      console.log(`Already in version ${lastTag.name} commit. Exit`);

      process.exit(0);
    }

    let { commits } = await gitLabService.compare({
      from: lastTag.target,
      to: process.env["CI_COMMIT_REF_NAME"]
    });

    if (process.env["CI_COMMIT_REF_NAME"].includes(lastTag.name)) {
      console.log(`Already in version ${lastTag.name} commit. Exit`);

      process.exit(0);
    }

    let newTagName = new SemanticTag(lastTag).bump(commits).toString();

    if (newTagName === lastTag.name) {
      console.log(`Already in version ${lastTag.name} commit. Exit`);

      process.exit(0);
    }

    console.log(`Bumping and tagging to ${newTagName}...`);

    await gitLabService.createTag({
      tag_name: newTagName,
      ref: process.env["CI_COMMIT_REF_NAME"]
    });

    console.log(`Done.`);
  } catch (error) {
    console.error(error);
    process.exit(1);
  }
}

return main();
