const GitlabAPIController = require("./GitLabAPI");
const standardVersion = require("standard-version");

return standardVersion({
  noVerify: true,
  silent: false,
  skip: {
    changelog: true,
    bump: false,
    commit: false,
    tag: false
  }
})
  .then(() => {
    const changelog = fs.readFileSync("CHANGELOG.md", { encoding: "utf-8" });

    const gitLabService = new GitlabAPIController({
      baseUrl: process.env["CI_API_V4_URL"],
      projectId: process.env["CI_PROJECT_ID"],
      token: process.env["CI_GITLAB_TOKEN"]
    });

    return gitLabService
      .getChangelogWikiPage()
      .then(() => {
        gitLabService.editChangelogWikiPage(changelog);
      })
      .catch((error) => {
        gitLabService.createChangelogWikiPage(changelog);
      });
  })
  .catch((err) => {
    console.error(`standard-version failed with message: ${err.message}`);
  });
