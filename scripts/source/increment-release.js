/**
 * Script de versionado de GitLab
 *
 * @author jmartinezpisson
 */
const GitlabAPIService = require("./GitLabAPI").default;
const standardVersion = require("standard-version");
const fs = require("fs");

return standardVersion({
  noVerify: true,
  silent: false,
  skip: {
    changelog: true,
    bump: false,
    commit: true,
    tag: true
  }
})
  .then(() => {
    const packageJson = fs.readFileSync("package.json", { encoding: "utf-8" });

    const gitLabService = new GitlabAPIService({
      baseUrl: process.env["CI_API_V4_URL"],
      projectId: process.env["CI_PROJECT_ID"],
      token: process.env["CI_GITLAB_TOKEN"]
    });

    return gitLabService
      .createCommit({
        branch: process.env["CI_BRANCH_NAME"],
        commit_message: "chore: bump package version [skip ci]",
        actions: [
          {
            action: "update",
            file_path: "package.json",
            content: packageJson
          }
        ]
      })
      .then((commitDetail) => {
        return gitLabService.createTag({
          tag_name: `${JSON.parse(packageJson).version}-UAT`,
          ref: commitDetail.id
        });
      });
  })
  .catch((err) => {
    console.error(`Error: Creating UAT Release: ${err.message || err}`);

    throw err;
  });
