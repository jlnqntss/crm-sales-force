const GitlabAPIService = require("./GitLabAPI");
const standardVersion = require("standard-version");
const fs = require("fs");

return standardVersion({
  noVerify: true,
  silent: false,
  skip: {
    changelog: false,
    bump: true,
    commit: true,
    tag: true
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
