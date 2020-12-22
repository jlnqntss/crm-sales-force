/**
 * Finalización de release. Basado en pipelines Zurich
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
  let tag = await gitLabService.getTag(process.env["CI_COMMIT_TAG"]);
  let refs = await gitLabService.getTagBranchRefs(tag.target);
  let isRelease = false;

  refs.forEach((ref) => {
    if (ref.name.includes("release")) {
      isRelease = true;
    }
  });

  if (isRelease) {
    console.log("Commit is in release branch");
    let { iid } = await gitLabService.createMergeRequest({
      title: `Merge branch release/${tag.name.split("-")[0]} to master`,
      source_branch: `release/${tag.name.split("-")[0]}`,
      target_branch: "master"
    });

    await gitLabService.acceptMergeRequest(iid, {
      squash: true,
      should_remove_source_branch: true
    });
  } else {
    console.log('Commit is not in branch "release". Aborting...');
  }
}

return main();
