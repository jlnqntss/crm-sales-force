/**
 * Generación de releases. Basado en pipelines Zurich
 *
 * @author jmartinezpisson
 */
const GitlabAPIService = require("./GitLabAPI").default;

async function main() {
  const gitLabService = new GitlabAPIService({
    baseUrl: process.env["CI_API_V4_URL"],
    projectId: process.env["CI_PROJECT_ID"],
    token: process.env["CI_GITLAB_TOKEN"]
  });
  let isRelease = false,
    isDev = false;
  let tag = await gitLabService.getTag(process.env["CI_COMMIT_TAG"]);

  await gitLabService.getTagBranchRefs(tag.target).forEach((ref) => {
    if (ref.name === "dev") {
      isDev = true;
    }
    if (ref.includes("release")) {
      isRelease = true;
    }
  });

  if (!isRelease && isDev) {
    console.log("Commit is in dev branch");
    await gitLabService.createBranch({
      ref: tag.target,
      branch: `release/${tag.split("-")[0]}`
    });
  } else {
    console.log('Commit is not in branch "dev". Aborting...');
  }
}

return main();
